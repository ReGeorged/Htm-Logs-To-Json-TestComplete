param (
    [string]$f,
    [string]$o,
    [switch]$d
)

# Function to parse JavaScript content and extract JSON data
function Parse-JSContent {
    param (
        [string]$jsContent
    )

    # Extract JSON content from the JavaScript function call
    $jsonPattern = '_json_loaded\("_TestLog.js",(.*)\)'
    if ($jsContent -match $jsonPattern) {
        $jsonContent = $matches[1]
        $jsonContent = $jsonContent.TrimEnd(')')  # Remove trailing parenthesis
        return $jsonContent
    } else {
        throw "Failed to extract JSON content from the JavaScript file."
    }
}

# Function to parse test cases and logs from JSON content
function Parse-TestCases {
    param (
        [string]$jsonContent
    )

    $data = $jsonContent | ConvertFrom-Json
    $testCases = @()
    $currentTestCase = $null

    foreach ($item in $data.items) {
        if ($item.Message -match "^Test case: (.+)") {
            if ($currentTestCase -ne $null) {
                # Add end time for the previous test case
                $currentTestCase.EndTime = $item.Time.text
                $testCases += $currentTestCase
            }
            $testCaseName = $matches[1]
            $currentTestCase = @{
                "TestCase" = $testCaseName
                "Logs" = @()
                "StartTime" = $item.Time.text
                "EndTime" = ""
                "Status" = $item.TypeDescription
                "ErrorScreenshot" = $false
                "ErrorScreenshotPath" = ""
                "Details" = ""
                "CallStack" = @()
            }
        } elseif ($currentTestCase -ne $null) {
            $logEntry = @{
                "Message" = $item.Message
                "Time" = $item.Time.text
                "Status" = $item.TypeDescription
                "Details" = ""
                "CallStack" = @()
            }
            if ($item.HasPicture -and $item.Picture.Count -gt 0) {
                $logEntry.ErrorScreenshot = $true
                $logEntry.ErrorScreenshotPath = $item.Picture[0].filename
                $currentTestCase.ErrorScreenshot = $true
                $currentTestCase.ErrorScreenshotPath = $item.Picture[0].filename
            }
            if ($item.Details.text) {
                $logEntry.Details = $item.Details.text
                $currentTestCase.Details = $item.Details.text
            }
            if ($item.CallStack.items.Count -gt 0) {
                $callStack = @()
                foreach ($callStackItem in $item.CallStack.items) {
                    $callStack += @{
                        "Type" = $callStackItem.Type
                        "Test" = $callStackItem.Test
                        "UnitName" = $callStackItem.UnitName
                        "LineNo" = $callStackItem.LineNo
                    }
                }
                $logEntry.CallStack = $callStack
                $currentTestCase.CallStack = $callStack
            }
            $currentTestCase.Logs += $logEntry
        }
    }

    if ($currentTestCase -ne $null) {
        # Add end time for the last test case
        $currentTestCase.EndTime = $data.items[-1].Time.text
        $testCases += $currentTestCase
    }

    return $testCases
}

# Main script execution
$testLogFiles = Get-ChildItem -Path $f -Filter _TestLog.js -Recurse

foreach ($file in $testLogFiles) {
    $jsContent = Get-Content -Path $file.FullName -Raw
    $jsonContent = Parse-JSContent -jsContent $jsContent
    $testCases = Parse-TestCases -jsonContent $jsonContent
    $jsonOutput = $testCases | ConvertTo-Json -Depth 10

    # Get the parent directory name to use as the output file name
    $parentDirName = (Get-Item $file.DirectoryName).Name
    $outputFilePath = Join-Path -Path $o -ChildPath "$parentDirName.json"

    # Ensure the output directory exists
    if (-not (Test-Path -Path $o)) {
        New-Item -ItemType Directory -Path $o | Out-Null
    }

    # Save JSON output to file
    $jsonOutput | Out-File -FilePath $outputFilePath -Encoding UTF8

    # Delete the original _TestLog.js file if the d flag is set
    if ($d) {
        Remove-Item -Path $file.FullName -Force
    }
}
