<#
.SYNOPSIS
    A module used for logging within scripts
.DESCRIPTION
	A module that allow you to perfom various log tasks
.NOTES
	Author:       Kurt Marvin
	
	Changelog:
       0.3      Updated eventlog creation to use, eventcreate.exe instead of the built-in powershell modules due to
                these command lets being discontinued or unusable. Also, updated error checking.
       0.2      Updated bug when creating a new app event log where the global event log variable was not being set.
                Also, added whatif:$false to commands so that if whatifpreference is set it will not affect logging.
       0.1      Initial release
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
        [ValidateSet('Application','System')]
        [string]$EventLog = "Application"
    )

    # Configure the event source name and event log to what is provided or use the script name.
    $global:EventSource = $EventSource
    $global:EventLog    = $EventLog

    # Check if event source already exists, and if so update it so eventcreate can write to it
    $path = "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\$($EventLog)\$($EventSource)"

    $eventSourceRegKey  = Get-Item -Path $path -ErrorAction SilentlyContinue
    $eventSourceRegProp = Get-ItemProperty -Path $path -Name "CustomSource" -ErrorAction SilentlyContinue

    # If the CustomSource regkey doesn't exist, create it so eventcreate.exe can be used on this event log source
    if ($eventSourceRegKey -and !$eventSourceRegProp) {
        $prop = New-ItemProperty -Path $path -Name CustomSource -PropertyType DWORD -Value 1
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
        The id number for the event. Must be between 1 - 1000.
    #>
    Param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string] $Message,

        [Parameter()]
        [ValidateSet('Information','Warning','Error')]
        [string] $EntryType = "Information",
        [ValidateRange(1, 1000)]
        [int]    $EventID
    )
    # Check if Start-AppEventLog has been called and if not throw error
    if ($global:EventSource) {
        # Set EventID to defaults if not specified
        if (!$EventID) {
            switch ($EntryType) {
                "Information" {
                    $EventID = 100
                }
                "Warning" {
                    $EventID = 101
                }
                "Error" {
                    $EventID = 102
                }
            }
        }
    
        # Create the event
        $response = (eventcreate.exe /L $global:EventLog /T $EntryType /SO $global:EventSource /ID $EventID /D $Message) | Out-String
        
        if (!$response.Contains("SUCCESS")) {
            throw "There was an error in creating an event log entry."
        }
        
        # Write message to standard output based on type
        switch ($EntryType) {
            Warning { Write-Warning $Message }
            Error   { Write-Error $Message }
            Information { Write-Information $Message }
            Default { Write-Verbose $Message }
        }
    } else {
        throw "No EventSource specified. Please call Start-AppEventLog or Start-LogAndAppEventLog prior to Write-AppEventLog."
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
        New-Item -Path $global:LogPath -ItemType "directory" -WhatIf:$false
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

    # Check if Start-Log has been called and if not throw error
    if ($global:LogFilePath) {
        $output = (Get-Date).ToString("dd-MMM-yyyy HH:mm:ss") + " | " + $EntryType + " | " + $Message

        Add-Content -Path $global:LogFilePath -Value $output -WhatIf:$false
        
        switch ($EntryType) {
            Warning { Write-Warning $Message }
            Error   { Write-Error $Message }
            Information { Write-Information $Message }
            Default { Write-Verbose $Message }
        }
    } else {
        throw "No LogFilePath specified. Please call Start-Log or Start-LogAndAppEventLog prior to Write-Log."
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
