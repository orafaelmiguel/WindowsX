param(
    [Parameter(Mandatory=$true)]
    [string]$ScriptPath
)

$outputFile = "$env:TEMP\script_output.txt"

Write-Output "Verificando script: $ScriptPath"
if (-not (Test-Path $ScriptPath)) {
    Write-Error "Arquivo não encontrado: $ScriptPath"
    exit 1
}

Write-Output "Executando script com privilégios de administrador..."
Start-Process powershell.exe -Verb RunAs -ArgumentList @(
    '-NoProfile',
    '-WindowStyle', 'Hidden',
    '-ExecutionPolicy', 'Bypass',
    '-Command', "& {
        try {
            Write-Output 'Iniciando execução do script...'
            & '$ScriptPath' *>&1 | Out-File -FilePath '$outputFile' -Append
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
    Remove-Item $outputFile
} else {
    Write-Output "Nenhuma saída foi gerada pelo script."
} 