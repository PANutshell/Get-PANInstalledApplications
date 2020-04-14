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
