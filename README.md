# KsLogging
This is a Powershell Module used for logging within scripts.

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
