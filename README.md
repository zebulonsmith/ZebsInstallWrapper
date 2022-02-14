# ZebsInstallWrapper

A PowerShell wrapper meant to facilitate complicated software installations

The intention of this script package is to create a simple way to manage complex tasks sometimes associated with deploying a Windows application.

It allows an administrator to define processes that run before and after the installation and monitor progress

## Process Flow

*   An Installation is started via the execution of Invoke-SoftwareInstall.ps1
*   The SoftwareInstall-HelperFunctions.ps1 script is dotsourced and provides Class Definitions and Helper Functions used throughout the process
*   Scripts in the PreInstallScripts directory are enumerated and executed. 
*   Install-Software.ps1 executes to perform the software installation.
*   Scripts in the PostInstall directory are enumerated and executed.
*   The script exits using the return code from the software installation performed in Install-Software.ps1

Notes: If a pre or post install script fails, the process can be ended or allowed to continue based on preference.   
 

### Using the Script Package

#### Guidelines:

*   Do not edit Invoke-SoftwareInstall.ps1 or SoftwareInstall-HelperFunctions.ps1
*   Do not rename InstallScript\\Install-Software.ps1
*   Any number of pre and post install scripts may be used. They're executed in alphabetical order according to the filename. 
*   You'll need a basic understanding of PowerShell, but example scripts are included to help. 
*   A log file will be saved automatically. You can add additional content to the log using the write-logfile function that is defined in SoftwareInstall-HelperFunctions.ps1

#### Helper Functions

Two helper functions are defined in the SoftwareInstall-HelperFunctions.ps1 and are used throughout the PreInstall/Install/PostInstall process.

*   Write-LogFile - Used to write progress to a log file that can be referenced later for troubleshooting
*   Start-InstallWrapperProcess - A wrapper for launching and monitoring executables. It will follow an execution and return its exit code back to the script. 

#### Creating Pre and Post Install Scripts:

These scripts can be built any way you choose, though it is highly recommended to use the provided examples as a starting point. The scripts must return an instance of the ScriptResult class defined in SoftwareInstall-HelperFunctions.ps1. 

An instance of the class can be created as follows:

```powershell
$PreInstallResult = [ScriptResult]::new()
```

The class defines four properties.

*   ContinueOnError (Bool) - If set to "True," the install process will continue if an error is encountered during the execution of the PreInstall script. Note that you'll need to write clean code and catch any errors in order for this to work. 
*   Description - Information about the operation being performed by the script. Optional, but anything added here will be included in the output log.
*   ResultDetails - An optional description providing info about the Result. Will be written to the log file. This property is useful to provide additional troubleshooting info when there is a failure.
*   Result - If set to "SUCCESS," the script assumes that the operation succeeded. Any other value is considered a failure and the script will exit, returning whatever error is defined in this parameter as the exit code.

#### Editing the Install-Software.ps1 Script

The Install-Software.ps1 script can be configured in any way desired but must return an instance of the InstallResult class as defined in SoftwareInstall-HelperFunctions.ps1. 

```powershell
$InstallResult = [InstallResult]::new()
```

The class defines the following properties:

*   Description - Optional description. Will be passed to the log file.
*   ExecutionDetails - Optional details about the execution to pass to the log file. 
*   ReturnCode - Typically, this should be the installer's exit code. It will be returned by the script at the end and passed to whatever process launches it. (Config Manager, for example).

It is recommended to use the included example as a starting point, editing the installer executable, arguments, and working directory as needed. The provided Start-InstallWrapperProcess function will manage the installation process. It will periodically write to the log file, monitor execution time, and make sure that the script does not exit prematurely when the process completes. Its use is not strictly necessary but highly recommended. 

### Executing the Installation

Once the scripts have been written, execute the installation with the Invoke-SoftwareInstall.ps1 script as follows:

```batchfile
powershell.exe -file .\Invoke-SoftwareInstall.ps1 -ApplicationName Test
```

The ApplicationName parameter will be used to name the log file but is unimportant otherwise. 

### TL;DR

*   Don't edit Invoke-SoftwareInstall.ps1 or SoftwareInstall-Helperfunctions.ps1. Don't rename Install-Software.ps1
*   Use the provided examples.
*   Add any number of pre and post install scripts in their respective directories. 
*   Edit Install-Software.ps1 to point at your installer and add necessary arguments.
*   Call Invoke-SoftwareInstall.ps1 -ApplicationName SomeNameHere to kick off the process
