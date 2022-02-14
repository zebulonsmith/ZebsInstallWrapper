<#
.DESCRIPTION
There should only be one .ps1 script in this directory and it should be named 'Install-Software.ps1'
This script should perform a software installation and return an instance of the [InstallResult] class that is defined in SoftwareInstall-HelperFunctions.ps1

.PARAMETER logfile
The log file to write output to. This is automatically populated by Invoke-SoftwareInstall.ps1

.EXAMPLE
This script should be launched from Invoke-SoftwareInstall.ps1, not ran on its own.

#>

Param (
    [Parameter(mandatory=$true)]
    [STRING]$logfile #Passed to this script by Invoke-SoftwareInstall.ps1
)

<#Create an instance of the InstallResult class. This section shouldn't be changed#>
#region DefineClass
Try {
    Write-LogFile -LogLevel Information -Path $logfile -Message "Creating InstallResult Object"
    $InstallResult = [InstallResult]::new()
} Catch {

    Write-LogFile -LogLevel Error -Path $logfile -Message "Unable to initialize an instance of the InstallResult class. $($_.exception.message)"
    Throw "$_.Exception.Message"
}



#endregion

<#
Place code here to install the software.
It's best to capture the return code of the installer when possible so that it can be returned to the ConfigMgr client
The example below can be modified, or replaced with any other code.
The only requirement is that an [InstallResult] object is returned.
#>

#region Installation

$MSIFile = "SomeFile.msi"
$args = "/i $MSIFile /qn"


<#
Start-InstallWrapperProcess is defined in SoftwareInstall-HelperFunctions.ps1
The following parameters should be passed:
Filename - The executable that will perform the software install. This example uses msiexec.exe, it could also be a setup.exe or similar
WorkingDirectory - The working directory for the installer executable
Arguments - Any command line arguments to pass to the installer

The object returned contains the following:
ExitCode - The exit code returned by the invoked process
ExecutionTime - Time in seconds that the process ran for

#>
$process = Start-Installwrapperprocess -Filename "$($env:windir)\system32\msiexec.exe" -WorkingDirectory $PSScriptRoot -arguments $args -logfile $logfile

#endregion


#This script must return an instance of [InstallResult]. It can be populated at any point, but should look something like the following
$InstallResult.description = "Installing Software." #Optional description. Will be passed to the log file.
$InstallResult.ExecutionDetails = "Installation completed in $executiontime seconds." #Any additional details that should be logged
$installResult.ReturnCode = $process.exitcode #The exit code to be returned. In this example, it is the exit code provided by msiexec.exe

Return $InstallResult