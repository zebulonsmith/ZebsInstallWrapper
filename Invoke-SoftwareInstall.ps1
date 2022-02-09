
Param (
    # Name of the app we're installing. Stick to characters that are legal for a filename.
    [Parameter(Mandatory=$true)]
    [string]
    $ApplicationName
)

#dotsource SoftwareInstall-HelperFunctions.ps1. We do it this way so that all of the PreInstallScripts have access to the Write-LogFile function and EvalResult class.
#There are other ways to do it, but this method requires less understanding of powershell and ensures that this script does not require modifications.
Try {
	. "$psscriptroot\SoftwareInstall-HelperFunctions.ps1"
} Catch {
    Write-Error "Failed to dotsource '$psscriptroot\SoftwareInstall-HelperFunctions.ps1'. $_.Exception.Message"
	Throw $_
}

#set file path. Use the ccm log dir by default, fall back to windir\temp if it doesn't exist. 
if ( (Test-path "$($env:windir)\ccm\logs") -eq $true) {
    $dirLogs = "$($env:windir)\ccm\logs"
    Write-Verbose "Directory $dirLogs exists."
} else {
    Write-Warning "$($env:windir)\ccm\logs does not exist. Using $($env:temp) instead."
	$dirLogs = "$($env:temp)"	
}

$SanitizedAppName = $ApplicationName.split([System.IO.Path]::GetInvalidFileNameChars()) -join ''

$logname = "script_Install_$($SanitizedAppName)_$(get-date -f yyyy-MM-dd_hh.mm.ss).log"

#Make sure we can write to the log file. Default to $env:temp if we can't.
#I should write a function to wrap this and recurse into it or something, but I'm a lazybutt and this is good enough.
Try {
    $logfile = "$dirLogs\$logname"
    "Beginning Operation" | out-file -FilePath $logfile
    Write-Verbose "Log file $logfile is writeable."
} catch {
    $logfile = "$($env:temp)\$logname"
    Write-Warning "Unable to write to $dirLogs\$logname. Switching to $logfile"
    "Unable to write to $dirLogs\$logname. Switching to $logfile" | out-file -FilePath $logfile
}

#Make sure that the installation script exists. We do this before processing the PreInstall scripts so that we can error out early if there's a problem.
$InstallScriptDir = "$PSScriptRoot\InstallScript"
$InstallScript = "Install-Software.ps1"
$InstallScriptPath = "$InstallScriptDir\$InstallScript"

If (Test-path -path $InstallScriptPath) {
    Write-LogFile -LogLevel Information -Message "Found install script at $InstallScriptPath." -Path $logfile
} else {
    $msg = "$InstallScriptPath does not exist. Exiting"
    Write-Logfile -LogLevel Error -Message $msg -Path $logfile
    throw [System.IO.FileNotFoundException]::New($msg)
}


#enumerate each script in the PreInstallScripts directory
Write-LogFile -Message "Enumerating PreInstallScripts directory" -LogLevel Information -Path $logfile

if ( (test-path "$psscriptroot\PreInstallScripts") -eq $false) {
    $msg = "$psscriptroot\PreInstallScripts' doesn't exist."
    Write-LogFile -Message $msg -LogLevel Warning -Path $logfile
    throw [System.IO.FileNotFoundException]::New($msg)
} 

$PreInstallScripts = Get-childitem "*.ps1" -path "$psscriptroot\PreInstallScripts" -Recurse

#Write some useful log data
if ($PreInstallScripts.count -eq 0) {
    Write-LogFile -Message "No scripts found" -LogLevel Warning -Path $logfile
}
Foreach ($Script in $PreInstallScripts) {
    Write-LogFile "     Located $($script.fullname)" -LogLevel Information -Path $logfile
}

#Execute each preinstall script
Write-logfile - -LogLevel Information -Message "Executing PreInstall scripts." -Path $logfile
Foreach ($Script in $PreInstallScripts) {
    Write-LogFile -LogLevel Information -Path $logfile -Message "Executing $($script.fullname)"
    Write-LogFile -LogLevel Information -Path $logfile -Message "`n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    Try {
        $thisPreInstall = & $script.FullName -logfile $logfile
        Write-LogFile -LogLevel Information -Message "Script $($script.fullname) to $($thisPreInstall.Description) finished with $($thisPreInstall.Result)" -Path $logfile
    } Catch { #Fail if the script cannot be executed
        Write-LogFile -LogLevel Error -Message "Failed to execute script $($script.FullName) with $($_.Exception.Message)" -Path $logfile
        Throw $_
    }

    
    #If the script returns an error, continue as needed or throw an error.
    if ($thisPreInstall.Result -ne "SUCCESS") {
        if ($thisPreInstall.ContinueOnError -eq $true) {
            Write-LogFile -LogLevel Warning "PreInstallContinueOnError = $($thisPreInstall.ContinueOnError). Will continue." -path $logfile
        } else {
            Write-LogFile -LogLevel Error -Message "Script $($script.FullName) returned $($thisPreInstall.Result). Reason: $($thisPreInstall.ResultDetails)" -path $logfile
            Throw $thisPreInstall.Result
        }
    } 
        
    
    Write-LogFile -LogLevel Information -Path $logfile -Message "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`n"

}

#Execute the Installation Script
Write-LogFile -LogLevel Information -Message "Beginning Installation" -Path $logfile
Write-LogFile -LogLevel Information -Message "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" -Path $logfile

Write-LogFile -LogLevel Information -Message "Executing $InstallScriptPath" -path $logfile
Try {
    $thisInstall = & $InstallScriptPath -logfile $logfile
    Write-LogFile -LogLevel Information -Message "Script $($InstallScriptPath) to $($thisInstall.Description) finished with return code $($thisInstall.Returncode). `n $($thisInstall.ExecutionDetails)" -Path $logfile
} Catch { #Fail if the script cannot be executed
    Write-LogFile -LogLevel Error -Message "Failed to execute script $($InstallScriptPath) with $($_.Exception.Message)" -Path $logfile
    Throw $_
}

#Exit the script with the return code from Install-Software.ps1
Write-LogFile -LogLevel Information -Message "Exiting script with code $($thisinstall.ReturnCode)" -path $logfile



$PostInstallScripts = Get-childitem "*.ps1" -path "$psscriptroot\PostInstallScripts" -Recurse

#Write some useful log data
if ($PostInstallScripts.count -eq 0) {
    Write-LogFile -Message "No scripts found" -LogLevel Warning -Path $logfile
}
Foreach ($Script in $PostInstallScripts) {
    Write-LogFile "     Located $($script.fullname)" -LogLevel Information -Path $logfile
}

#Execute each Postinstall script
Write-logfile - -LogLevel Information -Message "Executing PostInstall scripts." -Path $logfile
Foreach ($Script in $PostInstallScripts) {
    Write-LogFile -LogLevel Information -Path $logfile -Message "Executing $($script.fullname)"
    Write-LogFile -LogLevel Information -Path $logfile -Message "`n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    Try {
        $thisPostInstall = & $script.FullName -logfile $logfile
        Write-LogFile -LogLevel Information -Message "Script $($script.fullname) to $($thisPostInstall.Description) finished with $($thisPostInstall.Result)" -Path $logfile
    } Catch { #Fail if the script cannot be executed
        Write-LogFile -LogLevel Error -Message "Failed to execute script $($script.FullName) with $($_.Exception.Message)" -Path $logfile
        Throw $_
    }

    
    #If the script returns an error, continue as needed or throw an error.
    if ($thisPostInstall.Result -ne "SUCCESS") {
        if ($thisPostInstall.ContinueOnError -eq $true) {
            Write-LogFile -LogLevel Warning "PostInstallContinueOnError = $($thisPostInstall.ContinueOnError). Will continue." -path $logfile
        } else {
            Write-LogFile -LogLevel Error -Message "Script $($script.FullName) returned $($thisPostInstall.Result). Reason: $($thisPostInstall.ResultDetails)" -path $logfile
            Throw $thisPostInstall.Result
        }
    } 
            
    Write-LogFile -LogLevel Information -Path $logfile -Message "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`n"

}




Exit $thisInstall.ReturnCode