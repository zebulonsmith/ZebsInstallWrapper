<#
.DESCRIPTION 
The scripts in the EvalScripts directory can be used to ensure that a condition exists, uninstall old versions of software, verify that a device is healthy, etc.
They should all return an instance of the [PreInstallResult] class defined in SoftwareInstallHelperFunctions.ps1.
THis example checks to see if $env:windir exists.

.PARAMETER logfile
The log file to write output to. This is automatically populated by Invoke-SoftwareInstall.ps1

.EXAMPLE
This script should be launched from Invoke-SoftwareInstall.ps1, not ran on its own.
#>

Param (
    [Parameter(mandatory=$true)]
    [STRING]$logfile
)


<#Create an instance of the ScriptResult class. This section shouldn't be changed#>
#region DefineClass
Try {
    Write-LogFile -LogLevel Information -Path $logfile -Message "Creating ScriptResult Object"
    $PreInstallResult = [ScriptResult]::new()
} Catch {

    Write-LogFile -LogLevel Error -Path $logfile -Message "Unable to initialize an instance of the ScriptResult class. $($_.exception.message)"
    Throw "$_.Exception.Message"
}
#endregion

<# Change the code in the region below to test for the desired condition. In this example, we're checking to see if $env:windir exists.#>
#region CustomCode
Write-Logfile -loglevel Information -path $logfile "Evaluating the existence of $($env:windir)"
Try {
    Write-LogFile -LogLevel Information -Path $logfile -Message "Looking for existence of $($env:windir)"
    $WindirExists = (Test-Path $env:windir)
} Catch {#We failed to test whether or not the dir exists, so return with a failure
    Write-LogFile -LogLevel Warning -Path $logfile -Message "Failed with $($_.Exception.Message)"
    $result = "ERROR"
    $resultDetails = "Unable to determine if $($env:windir) exists."
}

if ( $WindirExists ) {#The directory exists, return a success
    Write-LogFile -LogLevel Information -Path $logfile -Message "Condition evaluated True."
    $result = "SUCCESS"
    $resultDetails = "$($env:windir) exists."
} else {#The directory does not exist, return a failure
    Write-LogFile -LogLevel Information -Path $logfile -Message "Condition evaluated False."
    $result = "ERROR"
    $resultDetails = "$($env:windir) does not exist."
}
#endregion



#Always be sure to return an object with the results in it. Edit the values of these variables as needed.
#This section should look relatively similar in every PreInstall script.
#region ReturnResults
$PreInstallResult.Description = "Evaluate whether or not $($env:windir) exists" #Describe what we're doing here
$PreInstallResult.ResultDetails = $resultDetails #TS Variable will be created using this name. It can be used later in the Task Sequence to decide whether or not to take an action.
$PreInstallResult.Result = $result #SUCCESS or ERROR
$PreInstallResult.ContinueOnError = $false #Set to $true if the Invoke-SoftwareInstall script should continue if this script fails.


#Finalize the log file and return the PreInstallResult to Invoke-SoftwareInstall.ps1
Write-LogFile -LogLevel Information -Path $logfile -Message "Returning with:`n   Description = '$($PreInstallREsult.Description)`n   ResultDetails = '$($PreInstallResult.ResultDetails)`n   Result = $($PreInstallResult.Result) ContinueOnError = $($PreInstallResult.ContinueOnError)"

return $PreInstallResult
#endregion