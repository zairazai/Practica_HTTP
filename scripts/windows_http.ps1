
# Servicios: IIS, Apache y Nginx
# Puertos:
# IIS     -> 8084
# Apache  -> 8085
# Nginx   -> 8086
# ==========================================================

$ErrorActionPreference = "Stop"

# config
$IISPath = "C:\sitio_iis"
$ApachePath = "C:\Apache24"
$NginxPath = "C:\nginx\nginx-1.30.0\nginx-1.30.0"

$IISPort = 8084
$ApachePort = 8085
$NginxPort = 8086

# ---------- Funciones ----------
function Mostrar {
    param([string]$Mensaje)
    Write-Host "[INFO] $Mensaje"
}

function Crear-ReglaFirewall {
    param(
        [string]$Nombre,
        [int]$Puerto
    )

    $regla = Get-NetFirewallRule -DisplayName $Nombre -ErrorAction SilentlyContinue

    if (-not $regla) {
        New-NetFirewallRule `
            -DisplayName $Nombre `
            -Direction Inbound `
            -Protocol TCP `
            -LocalPort $Puerto `
            -Action Allow | Out-Null

        Mostrar "Regla de firewall creada: $Nombre"
    }
    else {
        Mostrar "Regla de firewall ya existente: $Nombre"
    }
}

function Probar-Puerto {
    param([int]$Puerto)

    $resultado = netstat -ano | Select-String ":$Puerto"

    if ($resultado) {
        Write-Host "[OK] Puerto $Puerto activo"
    }
    else {
        Write-Host "[WARN] Puerto $Puerto no aparece activo"
    }
}

# IIS
Mostrar "Verificando IIS..."

$feature = Get-WindowsFeature -Name Web-Server

if (-not $feature.Installed) {
    Install-WindowsFeature -Name Web-Server -IncludeManagementTools | Out-Null
    Mostrar "IIS instalado correctamente"
}
else {
    Mostrar "IIS ya estaba instalado"
}

Import-Module WebAdministration

if (-not (Test-Path $IISPath)) {
    New-Item -Path $IISPath -ItemType Directory | Out-Null
}

Set-Content -Path "$IISPath\index.html" -Value "<h1>IIS funcionando en puerto $IISPort</h1>"

$sitioIIS = Get-Website -Name "IIS_8084" -ErrorAction SilentlyContinue

if (-not $sitioIIS) {
    New-Website -Name "IIS_8084" -Port $IISPort -PhysicalPath $IISPath | Out-Null
    Mostrar "Sitio IIS creado en puerto $IISPort"
}
else {
    Mostrar "Sitio IIS ya existente"
}

Crear-ReglaFirewall -Nombre "IIS 8084" -Puerto $IISPort

# Apache 
Mostrar "Verificando Apache..."

if (Test-Path "$ApachePath\conf\httpd.conf") {

    $httpdConf = "$ApachePath\conf\httpd.conf"
    $contenido = Get-Content $httpdConf -Raw

    $contenido = $contenido -replace "Listen\s+\d+", "Listen $ApachePort"
    $contenido = $contenido -replace "#?ServerName\s+.*:\d+", "ServerName localhost:$ApachePort"

    Set-Content -Path $httpdConf -Value $contenido

    Crear-ReglaFirewall -Nombre "Apache 8085" -Puerto $ApachePort

    $apacheActivo = netstat -ano | Select-String ":$ApachePort"

    if (-not $apacheActivo) {
        Start-Process -FilePath "$ApachePath\bin\httpd.exe" -WorkingDirectory "$ApachePath\bin"
        Mostrar "Apache iniciado en puerto $ApachePort"
    }
    else {
        Mostrar "Apache ya estaba activo en puerto $ApachePort"
    }
}
else {
    Write-Host "[WARN] No se encontró Apache en $ApachePath"
}

# Nginx 
Mostrar "Verificando Nginx..."

if (Test-Path "$NginxPath\conf\nginx.conf") {

    $nginxConf = "$NginxPath\conf\nginx.conf"
    $contenido = Get-Content $nginxConf -Raw

    $contenido = $contenido -replace "listen\s+\d+;", "listen $NginxPort;"

    Set-Content -Path $nginxConf -Value $contenido

    Crear-ReglaFirewall -Nombre "NGINX 8086" -Puerto $NginxPort

    $nginxActivo = tasklist | Select-String "nginx.exe"

    if (-not $nginxActivo) {
        Start-Process -FilePath "$NginxPath\nginx.exe" -WorkingDirectory $NginxPath
        Mostrar "Nginx iniciado en puerto $NginxPort"
    }
    else {
        Mostrar "Nginx ya estaba activo"
    }
}
else {
    Write-Host "[WARN] No se encontró Nginx en $NginxPath"
}

# verificacion
Mostrar "Validando puertos..."

Probar-Puerto -Puerto $IISPort
Probar-Puerto -Puerto $ApachePort
Probar-Puerto -Puerto $NginxPort

Mostrar "Proceso finalizado"