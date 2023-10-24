

function TestIIS
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$id,

        [Parameter(Mandatory=$true, Position=1)]
        [string]$result
    )

    if ($env:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
        if ($myInvocation.Line) {
            &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
        }else{
            &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -file "$($myInvocation.InvocationName)" $args
        }
    exit $lastexitcode
    }

    WriteResult $id 1 $result ""

}

function GetAppPath
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$id,

        [Parameter(Mandatory=$true, Position=1)]
        [string]$siteName,

        [Parameter(Mandatory=$true, Position=2)]
        [string]$appName
    )

    try
        {
            
            if ($env:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
				if ($myInvocation.Line) {
					&"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
				}else{
					&"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -file "$($myInvocation.InvocationName)" $args
				}
			exit $lastexitcode
			}
            
            $appPath = ""
            $allApps = Get-WebApplication -Site $siteName

            foreach ($currentApp in $allApps) { 
                if ($currentApp.path -eq "/$appName") {
                    $appPath = $currentApp.path
                    break
                }   
            }

            if ($appPath -ne "") {
                WriteResult $id 1 $appPath ""
            }else{
                WriteResult $id 0 "" "Can't find an app $appName"
            }
        }
    catch
        {
            WriteResult $id 0 "" "Something threw an exception"
        }
}

function AddAppToIIS
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$id,

        [Parameter(Mandatory=$true, Position=1)]
        [string]$siteName,

        [Parameter(Mandatory=$true, Position=2)]
        [string]$poolName,

        [Parameter(Mandatory=$true, Position=3)]
        [string]$appName,

        [Parameter(Mandatory=$true, Position=4)]
        [string]$physicalPath
    )

    try
        {
			
			if ($env:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
				if ($myInvocation.Line) {
					&"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
				}else{
					&"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -file "$($myInvocation.InvocationName)" $args
				}
			exit $lastexitcode
			}
			
            $sm = Get-IISServerManager

            <# Проверка наличия приложения#>
            $site = $sm.Sites[$siteName]
            $app = $site.Applications["/$appName"]

            if ($null -eq $app) {
             
                 <# Проверка/создание пула #>
                $appPool = $sm.ApplicationPools[$poolName]
                if ($null -eq $appPool) {
                    $appPool = $sm.ApplicationPools.Add($poolName)
                } else {
                    <# Проверка количества приложений в пуле #>
                    $appsInPull = 0
                    $allApps = Get-WebApplication -Site $siteName
                    foreach ($currentApp in $allApps) {
                        if ($currentApp.applicationPool -eq $poolName) {
                            $appsInPull = $appsInPull + 1
                        }
                    }
                    if ($appsInPull -ge 10) {
                        $lastSymbol =  $PoolName[$PoolName.Length - 1].ToString()
                        $devideSymbol =  $PoolName[$PoolName.Length - 2].ToString()
                        
                        if ($devideSymbol -eq "-") {
                            $newNumber = [int]$lastSymbol + 1
                            $newPoolName = $PoolName.Replace($lastSymbol, $newNumber.ToString())
                        } else {
                            $newPoolName = $PoolName + "-1"   
                        }
                        
                        $appPool = $sm.ApplicationPools[$newPoolName]
                        if ($null -eq $appPool) {
                            $appPool = $sm.ApplicationPools.Add($newPoolName)
                        }
                        $poolName =  $newPoolName

                    }
                }
                
                $app = $site.Applications.Add("/$appName", $physicalPath)
                $app.ApplicationPoolName = $poolName

                $sm.CommitChanges()

                WriteResult $id 1 $poolName ""
                
            } else {
                WriteResult $id 0 "" "App $appName is already exist"    
            }   
           
        }
    catch
        {
            WriteResult $id 0 "" "$PSItem"
        }
}

function RemoveAppFromIIS
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$id,

        [Parameter(Mandatory=$true, Position=1)]
        [string]$siteName,

        [Parameter(Mandatory=$true, Position=2)]
        [string]$appName
    )

    try
        {

            if ($env:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
				if ($myInvocation.Line) {
					&"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
				}else{
					&"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -file "$($myInvocation.InvocationName)" $args
				}
			exit $lastexitcode
			}

            $sm = Get-IISServerManager

            <# Проверка наличия приложения#>
            $site = $sm.Sites[$siteName]
            $app = $site.Applications["/$appName"]

            if ($null -eq $app) {
                WriteResult $id 1 "" "App $appName not found"
            } else {
                Remove-WebApplication -Name $appName -Site $siteName
                WriteResult $id 1 "" ""
            }
        }
    catch
        {
            WriteResult $id 0 "" "$PSItem"
        }
}


function WriteResult {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$id,

        [Parameter(Mandatory=$true, Position=1)]
        [bool]$success,

        [Parameter(Mandatory=$false, Position=2)]
        [string]$result,

        [Parameter(Mandatory=$false, Position=3)]
        [string]$error
    )
    
    if (Test-Path -Path "$PSScriptRoot\data.json") {
        $jsonObject = Get-Content -Raw -Path "$PSScriptRoot\data.json" | ConvertFrom-Json
        foreach ($item in $jsonObject.data) {
            if ($item.id -eq $id) {
                $item.success =  $success
                $item.result =  $result
                $item.error =  $error
                $jsonFileDataToWrite = $jsonObject | ConvertTo-Json
                $jsonFileDataToWrite | Out-File "$PSScriptRoot\data.json"
                break
            }   
        }
    }
}