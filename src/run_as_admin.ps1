param(
    [Parameter(Mandatory=$true)]
    [string]$ScriptPath,
    
    [Parameter(Mandatory=$false)]
    [string]$ScriptParams = ""
)

$outputFile = "$env:TEMP\script_output.txt"
$lockFile = "$env:TEMP\script_running.lock"

# Verifica se já existe um script rodando nos últimos 5 segundos
if (Test-Path $lockFile) {
    $lockFileTime = Get-Item $lockFile | Select-Object -ExpandProperty LastWriteTime
    $timeDiff = (Get-Date) - $lockFileTime
    
    if ($timeDiff.TotalSeconds -lt 5) {
        Write-Output "Outra instância do script está rodando ou foi executada há menos de 5 segundos. Aguarde."
        exit 0
    }
}

# Cria arquivo de bloqueio
Set-Content -Path $lockFile -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Write-Output "Verifying script: $ScriptPath"
if (-not (Test-Path $ScriptPath)) {
    Write-Error "File not found: $ScriptPath"
    Remove-Item $lockFile -Force -ErrorAction SilentlyContinue
    exit 1
}

# Construir o comando do script com parâmetros, se houver
$scriptCommand = "`"$ScriptPath`""
if ($ScriptParams) {
    Write-Output "Script parameters: $ScriptParams"
    $scriptCommand += " $ScriptParams"
}

# Limpa o arquivo de saída anterior se existir
if (Test-Path $outputFile) {
    try {
        Remove-Item $outputFile -Force -ErrorAction Stop
    } catch {
        Write-Output "Aviso: Não foi possível remover o arquivo de saída anterior. Tentando usar um novo arquivo."
        $outputFile = "$env:TEMP\script_output_$(Get-Date -Format 'yyyyMMddHHmmss').txt"
    }
}

Write-Output "Running script with administrator privileges..."
Start-Process powershell.exe -Verb RunAs -ArgumentList @(
    '-NoProfile',
    '-WindowStyle', 'Hidden',
    '-ExecutionPolicy', 'Bypass',
    '-Command', "& {
        try {
            Write-Output 'Starting script execution...'
            & { & $scriptCommand } *>&1 | Out-File -FilePath '$outputFile' -Append
            Write-Output 'SCRIPT_COMPLETED'
        } catch {
            Write-Error `$_.Exception.Message
            Write-Output 'SCRIPT_FAILED'
            exit 1
        }
    }"
) -Wait

if (Test-Path $outputFile) {
    Get-Content $outputFile
    try {
        Remove-Item $outputFile -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Output "Aviso: Não foi possível remover o arquivo de saída. Será removido automaticamente depois."
    }
} else {
    Write-Output "No output was generated by the script."
}

# Remove arquivo de bloqueio
Remove-Item $lockFile -Force -ErrorAction SilentlyContinue 