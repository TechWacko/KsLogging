<#
.SYNOPSIS
    A module used for logging within scripts
.DESCRIPTION
	A module that allow you to perfom various log tasks
.NOTES
	Author:       Kurt Marvin
	
	Changelog:
	   1.0        Initial release
#>

#############################################################
# Import Modules                                            #
#############################################################

#############################################################
# Variables                                                 #
#############################################################
$global:EventSource
$global:EventLog

$global:LogPath
$global:LogFileName
$global:LogFilePath

#############################################################
# Functions                                                 #
#############################################################
function Start-AppEventLog {
    <#
    .SYNOPSIS
        Initilizes the AppEventLog
    .DESCRIPTION
        Initilizes the AppEventLog
    .PARAMETER EventSource
        The event log source. This is used for organizing all these events to a single event source for easy filtering.
    .PARAMETER EventLog
        The event log to store the event into. This is typically "Application".
    #>
    Param(
        [Parameter(ValueFromPipeline=$true)]
        [string]$EventSource,
        [string]$EventLog = "Application"
    )

    # Configure the event source name to what is provided or use the script name.
    $global:EventSource = $EventSource
    
    # Create the event source if it doesn't exist
    if (!(Get-EventLog -LogName Application -Source $global:EventSource -ErrorAction SilentlyContinue -Newest 1)) {
        New-EventLog -LogName Application -Source $global:EventSource
        Write-EventLog -LogName $global:EventLog -Source $global:EventSource -EventId 4100 -EntryType 'Information' -Message "Beginning the log!"
        Write-Verbose "Created a new log event source called $global:EventSource within the $global:EventLog Eventlog"
    }
}

function Write-AppEventLog {
    <#
    .SYNOPSIS
        Writes event log entries
    .DESCRIPTION
        This function will create an event source if missing, and will create event log entries
        within it based on the passed data.
    .PARAMETER Message
        The message to be written in the event.
    .PARAMETER EntryType
        The type of of event written. Information, Warning, or Error.
    .PARAMETER EventID
        The id number for the event.
    #>
    Param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string] $Message,

        [Parameter()]
        [ValidateSet('Information','Warning','Error')]
        [string] $EntryType = "Information",
        [int]    $EventID
    )

    if (!$EventID) {
        switch ($EntryType) {
            "Information" {
                $EventID = 4100
            }
            "Warning" {
                $EventID = 4101
            }
            "Error" {
                $EventID = 4102
            }
        }
    }

    Write-EventLog -LogName $global:EventLog -Source $global:EventSource -Id $EventID -EntryType $EntryType -Message $Message
    
    switch ($EntryType) {
        Warning { Write-Warning $Message }
        Error   { Write-Error $Message }
        Information { Write-Information $Message }
        Default { Write-Verbose $Message }
    }
}

function Start-Log {
    <#
    .SYNOPSIS
        Starts the log file
    .DESCRIPTION
        This function creates the log file. By default the log file will be based on the script name.
        Also, the log 
    .PARAMETER LogPath
        The path to the log folder. If this is specified it will override a specified LogFolder name.
    .PARAMETER LogFileName
        The name of the file to create for the log file. If not, specified the name of the script will be used.
    .PARAMETER LogFolder
        The folder where the log files are stored
    #>
    Param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$LogPath,
        [Parameter(Mandatory=$true)]
        [string]$LogFileName
    )

    $global:LogPath = $LogPath
    $global:LogFileName = $LogFileName + ".log"

    $global:LogFilePath = Join-Path $global:LogPath $global:LogFileName
    
    # Create the log folder if it doesn't exist
    if (!(Test-Path $global:LogPath)) {
        New-Item -Path $global:LogPath -ItemType "directory"
    }
}

function Write-Log {
    <#
    .SYNOPSIS
        Writes a message to the log file
    .DESCRIPTION
        This function writes a message to the log file with the specified message level
    .PARAMETER Message
        The message to add to the log file
    .PARAMETER EntryType
        The criticality level of the message. Information, Verbose, Warning, Error
    #>
    Param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Message,
        [ValidateSet('Information','Warning','Error','Verbose')]
        [string]$EntryType = "Information"
    )

    $output = (Get-Date).ToString("dd-MMM-yyyy HH:mm:ss") + " | " + $EntryType + " | " + $Message

    Add-Content -Path $global:LogFilePath -Value $output
    
    switch ($EntryType) {
        Warning { Write-Warning $Message }
        Error   { Write-Error $Message }
        Information { Write-Information $Message }
        Default { Write-Verbose $Message }
    }
}

function Start-LogAndAppEventLog {
    <#
    .SYNOPSIS
        Initilizes the Log file and the AppEventLog using all default values
    .DESCRIPTION
        Initilizes the Log file and the AppEventLog using all default values
    #>
    Param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$LogPath,
        [Parameter(Mandatory=$true)]
        [string]$LogFileNameAndEventSource
    )
    Start-Log -LogPath $LogPath -LogFileName $LogFileNameAndEventSource
    Start-AppEventLog -EventSource $LogFileNameAndEventSource
}

function Write-LogAndAppEventLog {
    <#
    .SYNOPSIS
        Writes a message to the log and event log
    .DESCRIPTION
        This function writes a message to the log file and the event log. If you need more functionality
        use the direct Write-AppEventLog or Write-Log functions.
    .PARAMETER Message
        The message to add to the log file
    .PARAMETER EntryType
        The criticality level of the message. Information, Verbose, Warning, Error
    #>
    Param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Message,
        [ValidateSet('Information','Warning','Error','Verbose')]
        [string]$EntryType = "Information"
    )

    Write-Log -Message $Message -EntryType $EntryType

    if ($EntryType -eq "Verbose") { $EntryType = 'Information' }
    Write-AppEventLog -Message $Message -EntryType $EntryType

    switch ($EntryType) {
        Warning { Write-Warning $Message }
        Error   { Write-Error $Message }
        Information { Write-Information $Message }
        Default { Write-Verbose $Message }
    }
}
