param(
    [Parameter(Mandatory=$true)]
    [string]$ScriptPath
)

$outputFile = "$env:TEMP\script_output.txt"

Write-Output "Iniciando execução do script: $ScriptPath"
Write-Output "Arquivo de saída: $outputFile"

try {
    if (-not (Test-Path $ScriptPath)) {
        throw "Arquivo não encontrado: $ScriptPath"
    }

    # admin
    $process = Start-Process powershell.exe -Verb RunAs -ArgumentList @(
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
            }
        }"
    ) -PassThru -Wait
    if (Test-Path $outputFile) {
        Write-Output "Conteúdo do arquivo de saída:"
        Get-Content $outputFile
        Remove-Item $outputFile
    } else {
        Write-Output "Nenhuma saída foi gerada pelo script."
    }
} catch {
    Write-Error "Erro ao executar o script: $_"
    Write-Output "SCRIPT_FAILED"
} 