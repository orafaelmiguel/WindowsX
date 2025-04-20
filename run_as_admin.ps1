param(
    [Parameter(Mandatory=$true)]
    [string]$ScriptPath
)

$outputFile = "$env:TEMP\script_output.txt"

if (-not (Test-Path $ScriptPath)) {
    throw "Arquivo não encontrado: $ScriptPath"
}

Start-Process powershell.exe -Verb RunAs -ArgumentList @(
    '-NoProfile',
    '-WindowStyle', 'Hidden',
    '-ExecutionPolicy', 'Bypass',
    '-Command', "& {
        try {
            & '$ScriptPath' *>&1 | Out-File -FilePath '$outputFile' -Append
            Write-Output 'SCRIPT_COMPLETED'
        } catch {
            Write-Error `$_.Exception.Message
            Write-Output 'SCRIPT_FAILED'
        }
    }"
) -Wait

if (Test-Path $outputFile) {
    Get-Content $outputFile
    Remove-Item $outputFile
} else {
    Write-Output "Nenhuma saída foi gerada pelo script."
} 