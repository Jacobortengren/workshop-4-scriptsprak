### Del A #####################################################################################
###############################################################################################
### Task 1: Lista alla konfigurationsfiler #####################################################
###############################################################################################

# Basdatum
$now = Get-Date "2024-10-14"

# Huvudfolder där alla config-filer finns
$rootPath = ".\network_configs"

Write-Host "--- FILE INVENTORY --------------------"
Write-Host "Listing all .conf, .rules, and .log files in $rootPath..."
Write-Host ""

# Hämta alla .conf, .rules och .log filer
$allFiles = Get-ChildItem -Path $rootPath -Recurse -File |
Where-Object { $_.Extension -in ".conf", ".rules", ".log" } |
Select-Object Name,
@{Name = "Size (KB)"; Expression = { [math]::Round($_.Length / 1KB, 2) } },
@{Name = "Last Modified"; Expression = { $_.LastWriteTime } }

# Visar filerna i tabell
$allFiles | Format-Table -AutoSize

###############################################################################################
### Task 2: Hitta nyligen ändrade filer #######################################################
###############################################################################################

# Datum 7 dagar innan basdatum
$weekAgo = $now.AddDays(-7)

Write-Host ""
Write-Host "--- RECENTLY MODIFIED FILES --------------------"
Write-Host "Showing files modified between $($weekAgo.ToShortDateString()) and $($now.ToShortDateString())"
Write-Host ""

# Filtrera filer som ändrats de senaste 7 dagarna
$recentFiles = Get-ChildItem -Path $rootPath -Recurse -File |
Where-Object { $_.LastWriteTime -ge $weekAgo } |
Select-Object Name,
@{Name = "Last Modified"; Expression = { $_.LastWriteTime } },
@{Name = "Size (KB)"; Expression = { [math]::Round($_.Length / 1KB, 2) } } |
Sort-Object "Last Modified" -Descending

$recentFiles | Format-Table -AutoSize

###############################################################################################
### Task 3: Gruppera filer efter typ ###########################################################
###############################################################################################

# Hämtar alla filer för gruppering
$allFiles = Get-ChildItem -Path $rootPath -Recurse -File

# Grupperar efter fil / storlek
$fileGroups = $allFiles |
Group-Object -Property Extension |
Select-Object @{Name = "Extension"; Expression = { $_.Name } },
@{Name = "Count"; Expression = { $_.Count } },
@{Name = "TotalSize(KB)"; Expression = { [math]::Round(($_.Group | Measure-Object Length -Sum).Sum / 1KB, 2) } }

Write-Host ""
Write-Host "--- FILES GROUPED BY TYPE --------------------"
Write-Host ""
$fileGroups | Format-Table -AutoSize

###############################################################################################
### Task 4: Identifiera stora loggfiler ########################################################
###############################################################################################

# Lista de 5 största loggfilerna
$topLogFiles = Get-ChildItem -Path $rootPath -Recurse -File -Include *.log |
Sort-Object Length -Descending |
Select-Object -First 5 Name,
@{Name = "Size (MB)"; Expression = { [math]::Round($_.Length / 1MB, 2) } }

Write-Host "--- TOP 5 LARGEST LOG FILES --------------------"
$topLogFiles | Format-Table -AutoSize

### Del B #####################################################################################
###############################################################################################
### Task 5: Sök efter IP-adresser #############################################################
###############################################################################################

# visa alla .conf-filer
$configFiles = Get-ChildItem -Path $rootPath -Recurse -Include *.conf -File

# alla IP-adresser
$ipAddresses = @()
foreach ($file in $configFiles) {
    $matches = Select-String -Path $file.FullName -Pattern "\b\d{1,3}(\.\d{1,3}){3}\b" -AllMatches
    foreach ($match in $matches.Matches) {
        $ipAddresses += $match.Value
    }
}

# Lista unika IP-adresser
$uniqueIPs = $ipAddresses | Sort-Object -Unique

Write-Host ""
Write-Host "--- UNIQUE IP ADDRESSES FOUND --------------------"
$uniqueIPs | ForEach-Object { Write-Host $_ }

###############################################################################################
### Task 6: Hitta säkerhetsproblem i loggar ###################################################
###############################################################################################

$logPath = ".\network_configs\logs"
$patterns = @("ERROR", "FAILED", "DENIED")
$logFiles = Get-ChildItem -Path $logPath -Recurse -Include *.log -File

Write-Host ""
Write-Host "--- SECURITY WARNINGS PER LOG FILE --------------------"
Write-Host ""

# Räkna antal varningar/errors
foreach ($file in $logFiles) {
    $counts = @{}
    foreach ($pattern in $patterns) {
        $matchCount = (Select-String -Path $file.FullName -Pattern $pattern).Count
        $counts[$pattern] = $matchCount
    }
    
    Write-Host "File: $($file.Name)"
    foreach ($pattern in $patterns) {
        Write-Host "    $pattern : $($counts[$pattern])"
    }
    Write-Host ""
}

###############################################################################################
### Task 7: Exportera fil-inventering #########################################################
###############################################################################################

# Filtyper att inkludera
$fileTypes = "*.conf", "*.rules", "*.log"

# Hämta alla filer
$configFiles = Get-ChildItem -Path $rootPath -Recurse -Include $fileTypes -File |
Select-Object Name,
@{Name = "FullPath"; Expression = { $_.FullName } },
@{Name = "Size (KB)"; Expression = { [math]::Round($_.Length / 1KB, 2) } },
@{Name = "Last Modified"; Expression = { $_.LastWriteTime } }

# Exportera till CSV
$configFiles | Export-Csv -Path ".\config_inventory.csv" -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "Config inventory exported to config_inventory.csv"
