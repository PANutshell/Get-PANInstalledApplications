# Get-PANInstalledApplications
Get the contents of uninstall keys in the registry and out gridview

## Description
Firstly I want to mention, *DO NOT* use 'Get-WmiObject -Class Win32_Product' derived queries. Here is a good summary why:
https://sdmsoftware.com/wmi/why-win32_product-is-bad-news/
Based on: http://support.microsoft.com/kb/974524

So here I have an overly complicated script to pull the infomation from the registry keys 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' and 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'. This can be simplified if you simply wish to get the content as is:

    @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"; "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*") | Foreach-Object {
        Get-ItemProperty $_ | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
    } | Format-Table –AutoSize
    
While this will be fine for most items it can result in blanks if those properties are not populated

    DisplayName                           DisplayVersion   Publisher                  InstallDate
    -----------                           --------------   ---------                  -----------

                                          13.0.1708.0      Microsoft Corporation      20170207   
                                          13.1.4001.0      Microsoft Corporation      20170510   
                                          
So I have added an additional name field which will be populated from other properties that are available

    Name                                      DisplayVersion   Publisher                  InstallDate
    ----                                      --------------   ---------                  -----------
    Connection Manager                                                                                                                              
    Microsoft SQL Server 2016 (64-bit)        13.0.1708.0      Microsoft Corporation      20170207   
    Microsoft SQL Server 2016 (64-bit)        13.1.4001.0      Microsoft Corporation      20170510   

This is derrived from:

    Select-Object @{label='Name';expression={$(
        if ($key.DisplayName){$key.DisplayName}                 #Default to DisplayName
        elseif ($key.ParentDisplayName){$key.ParentDisplayName} #If this is an update or addon to an existing product. e.g. Office
        elseif ($key."(Default)") {$key."(Default)"}            #Used by things like update KB numbers
        else {$key.PSChildName}                                 #Last resort, use the key name itself
    )}}
    
The script is set to sort by the custom Name field and Out-GridView. Simply change the last line to get the result you want.

    $Array | Sort-Object Name | Out-GridView                            #This is what the script will currently do. Sort name and show all fields in a grid view
    $Array | Format-Table Name, DisplayVersion, Publisher, InstallDate  #This reflects the example above
    $Array | Export-CSV "C:\Temp\InstalledApps.csv" -NoTypeInformation  #Export all fields to a CSV file.
    
### Full Script

    $UninstallKeys = @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"; "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")
    $Array = @()
    foreach ($UninstallKey in $UninstallKeys) {
        $Architecture = if ($UninstallKey -match 'WOW6432Node') {"x86"} else {"x64"}
        $Keys = Get-ItemProperty -Path $UninstallKey | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, PSChildName, PSPath, ParentDisplayName
        foreach ($key in $Keys) {
            $key = $key | Select-Object `
                @{label='Name';expression={$(
                    if ($key.DisplayName){$key.DisplayName}                 #Default to DisplayName
                    elseif ($key.ParentDisplayName){$key.ParentDisplayName} #If this is an update or addon to an existing product. e.g. Office
                    elseif ($key."(Default)") {$key."(Default)"}            #Used by things like update KB numbers
                    else {$key.PSChildName}                                 #Last resort, use the key name itself
                ).TrimStart(' ')}}, `
                DisplayVersion, `
                Publisher, `
                InstallDate, `
                @{label='Architecture';expression={$Architecture}}, `
                PSChildName, `
                @{label='RegPath';expression={
                    $key.PSPath.TrimStart('Microsoft.PowerShell.Core\Registry::')
                }}, `
                ParentDisplayName, `
                DisplayName
            $Array += $key
        }
    }
    $Array | Sort-Object Name | Out-GridView
