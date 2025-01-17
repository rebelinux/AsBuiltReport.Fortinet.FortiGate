
function Get-AbrFgtForticare {
    <#
    .SYNOPSIS
        Used by As Built Report to returns FortiCare settings.
    .DESCRIPTION
        Documents the configuration of Fortinet FortiGate in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.1.0
        Author:         Alexis La Goutte
        Twitter:        @alagoutte
        Github:         alagoutte
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Fortinet.FortiGate
    #>
    [CmdletBinding()]
    param (

    )

    begin {
        Write-PScriboMessage "Discovering FortiCare settings information from $System."
    }

    process {

        $Forticare = (Get-FGTMonitorLicenseStatus).forticare

        if ($Forticare -and $InfoLevel.Forticare -ge 1) {
            Section -Style Heading2 'FortiCare' {
                Paragraph "The following section details FortiCare settings configured on FortiGate."
                BlankLine

                $OutObj = @()

                $Serial = $DefaultFGTConnection.serial

                $OutObj = [pscustomobject]@{
                    "Model"   = $Model
                    "Serial"  = $Serial
                    "Status"  = $Forticare.status
                    "Account" = $Forticare.account.ToLower()
                    "Company" = $Forticare.company
                }

                $TableParams = @{
                    Name         = "FortiCare"
                    List         = $true
                    ColumnWidths = 50, 50
                }

                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }

                $OutObj | Table @TableParams

                Paragraph "The following section details support settings configured on FortiGate."
                BlankLine
                $ExpiresHW = (($Forticare | Select-Object -ExpandProperty support).hardware).expires
                $SupportHW = [pscustomobject]@{
                    "Type"            = "Hardware"
                    "Level"           = $Forticare.support.hardware.support_level
                    "Status"          = $Forticare.support.hardware.status
                    "Expiration Date" = (Get-Date 01.01.1970) + ([System.TimeSpan]::fromseconds($ExpiresHW)) | Get-Date -Format dd/MM/yyyy
                }
                $ExpiresEn = (($Forticare | Select-Object -ExpandProperty support).enhanced).expires
                $SupportEn = [pscustomobject]@{
                    "Type"            = "Enhanced"
                    "Level"           = $Forticare.support.enhanced.support_level
                    "Status"          = $Forticare.support.enhanced.status
                    "Expiration Date" = (Get-Date 01.01.1970) + ([System.TimeSpan]::fromseconds($ExpiresEn)) | Get-Date -Format dd/MM/yyyy
                }

                $TableParams = @{
                    Name         = "Support"
                    List         = $false
                    ColumnWidths = 25, 25, 25, 25
                }

                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }

                $Support = @()
                $Support += $SupportHW
                $Support += $SupportEn
                $Support | Table @TableParams
            }

        }

        $firmware = Get-FGTMonitorSystemFirmware
        try {
            $firmware_upgrade_paths = Get-FGTMonitorSystemFirmware -upgrade_paths
        }
        catch {
            $firmware_upgrade_paths = $null
        }


        if ($firmware -and $firmware_upgrade_paths -and $InfoLevel.Forticare -ge 1) {
            Paragraph "The following section details firmware information on FortiGate."
            BlankLine

            $FortiOS = $firmware.current
            $CurrentVersion = [version]"$($firmware.current.major).$($firmware.current.minor).$($firmware.current.patch)"

            $FullUpdate = $firmware.available | Select-Object version -First 1
            if ($FullUpdate) {

                $FullUpdateVersion = [version]"$(($firmware.available | Select-Object -First 1).major).$(($firmware.available | Select-Object -First 1).minor).$(($firmware.available | Select-Object -First 1).patch)"

                #Same (or greater) version, No Update Available
                if ($CurrentVersion -ge $FullUpdateVersion) {
                    $tab_upgradePath = [pscustomobject]@{
                        "Installed"    = $($FortiOS.version)
                        "Update"       = "No Update Available"
                        "Upgrade Path" = "N/A"
                    }
                }
                else {
                    <# Search only last firmware on the same Branch
                $BranchUpdate = $firmware.available | Where-Object { $_.major -eq $CurrentVersion.Major -and $_.minor -eq $CurrentVersion.Minor } | Select-Object version -First 1
                if ($CurrentVersion -lt $BranchUpdateVersion) {
                    $upgradePath = "v$($CurrentVersion.Major).$($CurrentVersion.Minor).$($CurrentVersion.Build)"
                    $major = $CurrentVersion.Major
                    $minor = $CurrentVersion.Minor
                    $patch = $CurrentVersion.Build
                    Do {
                        $nextFirmware = $firmware_upgrade_paths | Where-Object { $_.from.major -eq $major -and $_.from.minor -eq $minor -and $_.from.patch -eq $patch -and $_.to.major -eq $BranchUpdateVersion.Major -and $_.to.minor -eq $BranchUpdateVersion.Minor } | Select-Object -First 1
                        $major = $nextFirmware.to.major
                        $minor = $nextFirmware.to.minor
                        $patch = $nextFirmware.to.patch
                        $upgradePath = $upgradePath + " -> v$($major).$($minor).$($patch)"
                    }Until($major -eq $BranchUpdateVersion.Major -and $minor -eq $BranchUpdateVersion.Minor -and $patch -eq $BranchUpdateVersion.Build)
                    $tab_upgradePath = [pscustomobject]@{
                        "Installed"    = $($FortiOS.version)
                        "Update"       = $($BranchUpdate.version)
                        "Upgrade Path" = $upgradePath
                    }
                }
                #>
                    $BranchUpdateVersion = [version]"$(($firmware.available | Where-Object { $_.major -eq $CurrentVersion.Major -and $_.minor -eq $CurrentVersion.Minor } | Select-Object -First 1).major).$(($firmware.available | Where-Object { $_.major -eq $CurrentVersion.Major -and $_.minor -eq $CurrentVersion.Minor } | Select-Object -First 1).minor).$(($firmware.available | Where-Object { $_.major -eq $CurrentVersion.Major -and $_.minor -eq $CurrentVersion.Minor } | Select-Object -First 1).patch)"
                    if (($CurrentVersion -lt $FullUpdateVersion) -and ($BranchUpdateVersion -ne $FullUpdateVersion)) {
                        $upgradePath = "v$($CurrentVersion.Major).$($CurrentVersion.Minor).$($CurrentVersion.Build)"
                        $major = $CurrentVersion.Major
                        $minor = $CurrentVersion.Minor
                        $patch = $CurrentVersion.Build
                        Do {
                            $nextFirmware = $firmware_upgrade_paths | Where-Object { $_.from.major -eq $major -and $_.from.minor -eq $minor -and $_.from.patch -eq $patch } | Select-Object -First 1
                            $major = $nextFirmware.to.major
                            $minor = $nextFirmware.to.minor
                            $patch = $nextFirmware.to.patch
                            $upgradePath = $upgradePath + " -> v$($major).$($minor).$($patch)"
                        }Until($major -eq $FullUpdateVersion.Major -and $minor -eq $FullUpdateVersion.Minor -and $patch -eq $FullUpdateVersion.Build)
                        $tab_upgradePath = [pscustomobject]@{
                            "Installed"    = $($FortiOS.version)
                            "Update"       = $($FullUpdate.version)
                            "Upgrade Path" = $upgradePath
                        }
                    }
                }
            }
            else {

                #No $firmware.available info (no FortiCare/FortiGuard ?)
                $tab_upgradePath = [pscustomobject]@{
                    "Installed"    = $($FortiOS.version)
                    "Update"       = "N/A"
                    "Upgrade Path" = "N/A"
                }
            }

            $TableParams = @{
                Name         = "Firmware"
                List         = $true
                ColumnWidths = 50, 50
            }

            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }

            $tab_upgradePath | Table @TableParams
        }

    }

    end {

    }

}