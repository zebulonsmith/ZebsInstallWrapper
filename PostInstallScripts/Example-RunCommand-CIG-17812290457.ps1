<#
.DESCRIPTION 
The scripts in the EvalScripts directory can be used to ensure that a condition exists, uninstall old versions of software, verify that a device is healthy, etc.
They should all return an instance of the [InstallResult] class defined in SoftwareInstallHelperFunctions.ps1.
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


<#Create an instance of the scriptResult class. This section shouldn't be changed#>
#region DefineClass
Try {
    Write-LogFile -LogLevel Information -Path $logfile -Message "Creating PostInstallResult Object"
    $PostInstallResult = [criptResult]::new()
} Catch {
    
    Write-LogFile -LogLevel Error -Path $logfile -Message "Unable to initialize an instance of the PreInstallResult class. $($_.exception.message)"
    Throw "$_.Exception.Message"
}
#endregion

$File = "SomeFile.exe"
$WorkingDir = "C:\Program Files\SoftwareThatNeedsLicensed\"
$args = "/activate /licensekey:whoopdydoodahnobodylikesthese"

Try {
$exitcode = Start-Installwrapperprocess -Filename $SomeFile -WorkingDirectory $WorkingDir -arguments $args -logfile $logfile

#Always be sure to return an object with the results in it. Edit the values of these variables as needed.
#This section should look relatively similar in every PreInstall script.
#region ReturnResults
$PostInstallResult.Description = "Evaluate whether or not $($env:windir) exists" #Describe what we're doing here
$PostInstallResult.ResultDetails = $exitcode #TS Variable will be created using this name. It can be used later in the Task Sequence to decide whether or not to take an action.
$PostInstallResult.Result = $exitcode #SUCCESS or ERROR
$PostInstallResult.ContinueOnError = $false #Set to $true if the Invoke-SoftwareInstall script should continue if this script fails.


#Finalize the log file and return the PostInstallResult to Invoke-SoftwareInstall.ps1
Write-LogFile -LogLevel Information -Path $logfile -Message "Returning with:`n   Description = '$($PostInstallREsult.Description)`n   ResultDetails = '$($PostInstallResult.ResultDetails)`n   Result = $($PostInstallResult.Result) ContinueOnError = $($PostInstallResult.ContinueOnError)"

return $PostInstallResult
#endregion