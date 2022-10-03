$ComputerName = $env:COMPUTERNAME
If (($ComputerName.SubString(7) -eq "D") -or ($ComputerName.SubString(7) -eq "E")) {$Type = "DE"}
    elseif (($ComputerName.SubString(7) -eq "M") -or ($ComputerName.SubString(7) -eq "N")) {$Type = "MN"}
    elseif ($ComputerName.SubString(7) -eq "K") {$Type = "K"}
    elseif ($ComputerName.SubString(7) -eq "L") {$Type = "L"}
Write-Host "Type:  $Type"


# # Set TimeZone
# $TimeZone = Read-host “Enter the Time Zone (Eastern, Central, Mountain, Pacific)”
# Set-TimeZone -Id "$TimeZone Standard Time"
# $TZ = Get-TimeZone
# Write-Host "TimeZone: $TZ"


# Configure Drives
#Add-content $logfile -value "Creating volumes..."
$offline_disks = Get-Disk | Where-Object PartitionStyle -eq 'raw' | Sort-Object Number
Start-Sleep -Seconds 10
$offline_disks | Set-Disk -IsOffline $false
Start-Sleep -Seconds 10
$offline_disks | Set-Disk -IsReadonly $false
Start-Sleep -Seconds 10
#if we're running on something older than 2016, we use older cmdlets and MBR partitions
#disk "0" will be C drive, so start at disk 1
$disk_number = 1
If ($Type -eq "DE") {
    foreach ($disk in $offline_disks) {
        switch ($disk_number)
        {
            1 {$Label = "Data"}
            2 {$Label = "ISP"}
        }
        Initialize-Disk -UniqueId $disk.UniqueId -PartitionStyle MBR
        $next_available_drive_letter = get-wmiobject win32_logicaldisk | select -expand DeviceID -Last 1 |
            % { [char]([int][char]$_[0]  + 1) + $_[1] }
        New-Partition -DiskNumber $disk_number -UseMaximumSize
        Add-PartitionAccessPath -DiskNumber $disk_number -PartitionNumber 1 -AccessPath $next_available_drive_letter
        #technically, block size should vary with drive size, but only for drives larger than 16 terabytes
        #https://support.microsoft.com/en-us/help/140365/default-cluster-size-for-ntfs-fat-and-exfat
        Get-Partition -Disknumber $disk_number -PartitionNumber 1 | Format-Volume -FileSystem NTFS -NewFileSystemLabel $Label -AllocationUnitSize 4096 -Confirm:$false
        If ($Label -eq "Data") {Get-Partition -Disknumber $disk_number | Set-Partition -NewDriveLetter E}
        If ($Label -eq "ISP") {Get-Partition -Disknumber $disk_number | Set-Partition -NewDriveLetter K}
        $disk_number++
        Start-Sleep -Seconds 1
        }
    }   
    elseif ($Type -eq "MN") {
        foreach ($disk in $offline_disks) {
            switch ($disk_number)
            {
                1 {$Label = "Data"}
                2 {$Label = "TempDB"}
                3 {$Label = "DB_Data"}
                4 {$Label = "Logs"}
                5 {$Label = "Backups"}
                6 {$Label = "ISP"}
            }
            Initialize-Disk -UniqueId $disk.UniqueId -PartitionStyle MBR
            $next_available_drive_letter = get-wmiobject win32_logicaldisk | select -expand DeviceID -Last 1 |
                % { [char]([int][char]$_[0]  + 1) + $_[1] }
            New-Partition -DiskNumber $disk_number -UseMaximumSize
            Add-PartitionAccessPath -DiskNumber $disk_number -PartitionNumber 1 -AccessPath $next_available_drive_letter
            #technically, block size should vary with drive size, but only for drives larger than 16 terabytes
            #https://support.microsoft.com/en-us/help/140365/default-cluster-size-for-ntfs-fat-and-exfat
            Get-Partition -Disknumber $disk_number -PartitionNumber 1 | Format-Volume -FileSystem NTFS -NewFileSystemLabel $Label -AllocationUnitSize 4096 -Confirm:$false
            If ($Label -eq "ISP") {Get-Partition -Disknumber $disk_number | Set-Partition -NewDriveLetter K}
            $disk_number++
            Start-Sleep -Seconds 1
        }
    }
    elseif (($Type -eq "K") -or ($Type -eq "L")) {
        foreach ($disk in $offline_disks) {
            switch ($disk_number)
            {
                1 {$Label = "Data"}
                2 {$Label = "Disk F"}
           }
            Initialize-Disk -UniqueId $disk.UniqueId -PartitionStyle MBR
            $next_available_drive_letter = get-wmiobject win32_logicaldisk | select -expand DeviceID -Last 1 |
                % { [char]([int][char]$_[0]  + 1) + $_[1] }
            New-Partition -DiskNumber $disk_number -UseMaximumSize
            Add-PartitionAccessPath -DiskNumber $disk_number -PartitionNumber 1 -AccessPath $next_available_drive_letter
            #technically, block size should vary with drive size, but only for drives larger than 16 terabytes
            #https://support.microsoft.com/en-us/help/140365/default-cluster-size-for-ntfs-fat-and-exfat
            Get-Partition -Disknumber $disk_number -PartitionNumber 1 | Format-Volume -FileSystem NTFS -NewFileSystemLabel $Label -AllocationUnitSize 4096 -Confirm:$false
            If ($Label -eq "Disk F") {Get-Partition -Disknumber $disk_number | Set-Partition -NewDriveLetter F}
            $disk_number++
            Start-Sleep -Seconds 1
        }
    }   
