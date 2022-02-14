
#This file is dot sourced by Invoke-SoftwareInstall.ps1. It contains functions used by other scripts.

#Create a class to easily keep return results from the Pre and post Install scripts consistent
Class ScriptResult {

    [string]$Description #Describe the purpose of this script

	[ValidateSet("SUCCESS","ERROR","UNSPECIFIED")]
	[string]$Result

	[string]$ResultDetails

	[bool]$ContinueOnError

    ScriptResult() {
		$this.Description = "Unspecified"
		$this.Result = "UNSPECIFIED"
		$this.ResultDetails = "Unspecified"
		$this.ContinueOnError = $false
    }

    ScriptResult([string]$Description, [string]$Result, [string]$ResultDetails, [bool]$ContinueOnError) {
        $this.Description = $Description
		$this.Result = $Result
		$this.ResultDetails = $ResultDetails
		$this.ContinueOnError = $ContinueOnError
    }
}

#Class to handle the results of the install script
Class InstallResult {
	[String]$Description

	[String]$ReturnCode

	[String]$ExecutionDetails

	InstallResult() {
		$this.Description = "Unspecified"
		$this.ReturnCode = "Unspecified"
		$this.ExecutionDetails = "Unspecified"
	}

	InstallResult([string]$Description, [string]$ReturnCode, [string]$ExecutionDetails) {
		$this.Description = $Description
		$this.ReturnCode = $ReturnCode
		$this.ExecutionDetails = $ExecutionDetails
	}
}


<#
.DESCRIPTION
Writes log file entries including a time stamp and information level on each line. Plays well with cmtrace.exe.

.PARAMETER Message
The text of the log entry

.PARAMETER LogLevel
Information - Write an informational line to the log and write-verbose
Warning - Write a warning line to the log and write-warning
Error - Write an error message to the log and write-error

.PARAMETER Path
File path to write to. It will be created if it doesn't exist and appended otherwise.

.PARAMETER BackupPath
Optionally specify a backup path to write log files to in case the one specified by -Path does not exist or isn't writeable.
Defaults to $env:temp, which should almost always be writeable.

.EXAMPLE
Write-LogFile -Message "This is a test log entry" -Path 'C:\windows\temp\logtest.log' -loglevel Information
#>
function Write-LogFile
{

	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory = $true,ValueFromPipelineByPropertyName = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$Message,

		[Parameter(Mandatory = $false)]
		[ValidateSet("Error", "Warning", "Information")]
		[string]$LogLevel = "Information",

		[Parameter(Mandatory = $True)]
		[string]$Path,

		[Parameter(Mandatory=$false)]
		[string]$BackupPath = "$($env:temp)"
	)

	#Get a pretty date string
	$FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

	# Write message to error, warning, or verbose pipeline and specify $LevelText
	switch ($LogLevel)
	{
		'Error' {
			Write-Error $Message
			$LevelText = 'ERROR:'
		}
		'Warning' {
			Write-Warning $Message
			$LevelText = 'WARNING:'
		}
		'Information' {
			Write-Verbose $Message
			$LevelText = 'INFORMATION:'
		}
	}

	Try {
		"$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append
	} catch {

		$BackupFile = "$BackupPath\$(Split-path -path $path -leaf)"
		Write-Warning "$Path is not writeable. Using $BackupFile"
		"$FormattedDate $LevelText $Message" | Out-File -FilePath $BackupFile -Append
	}


}


<#
.DESCRIPTION Launches a process and monitors it until the process ends. Returns the exit code.

.PARAMETER Filename
Name of the file that will be executed. Include the path to the file (c:\windows\system32\notepad.exe) if it is not in a location specified by $env:path.

.PARAMETER WorkingDirectory
Optionally specify a working directory for the process.

.PARAMETER Arguments
Any arguments that need to be passed to the executable.

.PARAMETER UpdateSeconds
Interval for writing status updates to the log file. One line will be written indicating the status of the running process every time this interval is reached.

.PARAMETER logfile
Path to the log file that will be used for status updates.

.EXAMPLE
Start-InstallWrapperProcess -Filename "C:\windows\system32\notepad.exe"
#>
Function Start-InstallWrapperProcess {
	Param (
		# Name of the file that will be executed. Include the path to the file (c:\windows\system32\notepad.exe) if it is not in a location specified by $env:path.
		[Parameter(Mandatory=$true)]
		[String]
		$Filename,

        # Working directory for the file to be executed
		[Parameter(Mandatory=$false)]
		[String]
		$WorkingDirectory,

		# Arguments to pass to the command being executed
		[Parameter(Mandatory=$False)]
		[String]
		$arguments = "",

		#Interval for writing status updates to the log file. A value of '60' means that every 60 seconds a line will be written to the file indicating that the process is running
		[Parameter(Mandatory=$false)]
		[Int]
		$UpdateSeconds = 300,

		# Log file to be used. This should be the same as the file used everywhere else.
		[Parameter(Mandatory=$true)]
		[String]
		$logfile
	)

	$processinfo = New-Object System.Diagnostics.ProcessStartInfo
	$processinfo.FileName = $filename
    $processinfo.WorkingDirectory = $WorkingDirectory
	$processinfo.RedirectStandardError = $true
	$processinfo.RedirectStandardOutput = $true
	$processinfo.UseShellExecute = $false
	$processinfo.Arguments = $arguments
	$processinfo.LoadUserProfile = $false
	$processinfo.CreateNoWindow = $true

	Write-LogFile -Message "Executing: $($processinfo.filename) `n   Arguments: $($processinfo.arguments) `n   WorkingDirectory: $($processInfo.WorkingDirectory)" -LogLevel Information -Path $logfile

	$currentprocess = New-Object System.Diagnostics.Process
	$currentprocess.StartInfo = $processinfo
	$currentprocess.Start() | out-null

    Write-LogFile -Message "Process Started with ID $($currentprocess.ID)" -LogLevel Information -Path $logfile
    Write-LogFile -Message "     Process Modules: `n$($currentprocess.Modules)" -LogLevel Information -Path $logfile


	$ExecutionTime = 0

	#Loop until the process finishes. Write to the log file every 60 seconds.
	$SleepSeconds = 1
	while ($currentprocess.hasexited -eq $false) {
			Start-sleep -Seconds $SleepSeconds
			$ExecutionTime = $ExecutionTime + $SleepSeconds
			if (($ExecutionTime % $UpdateSeconds) -eq 0) {
				Write-LogFile -Message "$($processinfo.filename) has been running for $($ExecutionTime) seconds." -LogLevel Information -Path $logfile

				if ($currentprocess.responding -eq $false) {
					Write-logfile -Message "     Process is not responding." -LogLevel Warning -Path $logfile
				}
			}
	}

	#exit
	Write-Logfile -message "Process Exited on $($currentprocess.ExitTime) with Exit Code $($currentprocess.ExitCode)" -LogLevel Information -Path $logfile

	$exitdata = [PSCustomObject]@{
		ExitCode = $Currentprocess.ExitCode
		ExecutionTime = $ExecutionTime
	}

	Return $exitdata
}