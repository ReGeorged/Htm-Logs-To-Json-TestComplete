# Htm-Logs-To-Json-TestComplete

## To get usable log summary format such as JSON we can make TestComplete & TestExecute generate htm report and the convert it to json format using powershell script above

#### To read how to generate htm report for tests read TestCompletes Original Documentation


### A root directory will be generated with a new directory for each TestCase that was run during execution
### Each of these sub directorys will have <b> _TestLog.js </b> file in them 
### from each of these files the powershell script extract necessary info about test cases (currently extracts from one of them)
### this is how the origianlly genrated sumamry directory looks like
![generated run summary as htm - directory structure](screenshots/Original%20Genrated%20run%20summary%20report.png)

## Here is how json output looks like with original report for comparison
![JsonLog](screenshots/TestComplete%20suite%20log%20with%20json%20by%20side%20.png)


## To get JSON logs: Download ConvertLogsToJson.ps1 And Run: 

``` powershell
 .\ConvertLogsToJson.ps1 -f "C:\your\path\to\log\directory" -o "C:\your\path\for\exampleOutput\"
```
## you can run this command with -d flag to delete original log files after converting them to json
``` powershell
 .\ConvertLogsToJson.ps1 -f "C:\your\path\to\log\directory\" -o "C:\your\path\for\exampleOutput\ -d"
```
# And Thats it !
