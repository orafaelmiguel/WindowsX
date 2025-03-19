Write-Output "Adjust virtual memory..."

# in mb
$minPagingFile = 1024 
$maxPagingFile = 4096 

$regKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
Set-ItemProperty -Path $regKey -Name "PagingFiles" -Value "C:\pagefile.sys $minPagingFile $maxPagingFile"

Write-Output "Virtual memory checked."
