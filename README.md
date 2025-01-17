# KsLogging
This is a Powershell Module used for logging within scripts.

If you are planning to use Powershell 7 and the event log functionality import the following module into your script before you import the KsLogging module:

```
Import-Module Microsoft.PowerShell.Management -UseWindowsPowerShell
```

This will import in the necessary New-EventLog and Write-EventLog commands that are needed for the KsLogging module to work properly.

# Functions
## Event Log Functions
### Start-AppEventLog
```
Start-AppEventLog -EventSource "MyScript"
```
### Write-AppEventLog
```
Write-AppEventLog "This is a log message!" -EntryType "Warning" -EventID 4100
```
## Log File Functions
### Start-Log
```
Start-Log -LogPath "C:\Temp" -LogFileName "Log"
```
### Write-Log
```
Write-Log "This is a log message!" -EntryType "Warning"
```
## Both Log File and Event Log Functions
### Start-LogAndAppEventLog
```
Start-LogAndAppEventLog -LogPath "C:\Temp" -LogFileNameAndEventSource "MyScript"
```
### Write-LogAndAppEventLog
```
Write-LogAndAppEventLog "This is a log message!" -EntryType "Warning"
```
