# Function to provide a list of available functions/methods living on the $profile


function list {
  Write-Host "Here is the list of available functions in your profile ... "
  # Get the profile path
  $ProfilePath = $PROFILE



  # Get functions defined in the profile
  Get-ChildItem Function: | Where-Object { $_.ScriptBlock.File -eq $ProfilePath } | Select-Object Name, @{Name="Definition"; Expression={$_.ScriptBlock}}
}



# Run a list of powershell line commands in parallel using your system config / get live updates on the status!
function run {
    param (
        [string] $BatchFile
    )
    # Read the batch file and store commands in an array
    $Commands = Get-Content -Path $BatchFile

    # Determine the number of CPU cores
    $NCore = (Get-WmiObject Win32_Processor).NumberOfCores -1 
	Write-Host "using " $NCore " Cores to process"

    # Define a script block to execute each command
    $ScriptBlock = {
        param($Command)
        Invoke-Expression $Command
    }

    # Run commands in parallel
    for ($i = 0; $i -lt $Commands.Count; $i += $NCore) {
        $Jobs = @()
        for ($j = $i; $j -lt ($i + $NCore) -and $j -lt $Commands.Count; $j++) {
            $Job = Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Commands[$j] -Name "HAWC2"
            $Jobs += $Job
        }

        # Monitor job status
        while ($Jobs.Count -gt 0) {
            $CompletedJobs = $Jobs | Where-Object { $_.State -eq "Completed" }
            $CompletedJobs | ForEach-Object {
                $Job = $_
                $Jobs.Remove($Job)
                $Job | Receive-Job -Wait -AutoRemoveJob
            }

            # Report job status
            Write-Host "`nRunning jobs: $($Jobs.Count)"
            Start-Sleep -Seconds 10
        }
    }
}

# Open up a new console from the existing one 
function new {
	start-process powershell -WorkingDirectory .
}

# Find a specific filemname pattern in a directory
function find {
    param(
        [string]$FolderPath,
        [string]$Pattern
    )

    # Check if the folder path exists
    if (-not (Test-Path -Path $FolderPath -PathType Container)) {
        Write-Host "Folder path '$FolderPath' does not exist."
        return
    }

    # Find files recursively and filter based on pattern
    $files = Get-ChildItem -Path $FolderPath -Recurse -File | Where-Object { $_.Name -like $Pattern }

    # Output the matching files
    if ($files.Count -gt 0) {
        Write-Host "Matching files found in '$FolderPath':" -ForegroundColor Green
        foreach ($file in $files) {
            Write-Host $file.FullName
        }
    } else {
        Write-Host "No matching files found in '$FolderPath'." -ForegroundColor Yellow
    }
}

# search through bing and list the first 10 search results 
function search {
    param (
        [Parameter(Mandatory = $true)]
        [string]$query,
        
        [int]$count = 10  # Number of search results to retrieve
    )

     $urlEncodedQuery = [uri]::EscapeDataString($query)
     $url = "https://www.bing.com/search?q=$urlEncodedQuery"

     $response = Invoke-WebRequest -Uri $url -UseBasicParsing
     $htmlContent = $response.Content

     # Extract search results using regular expressions
     $regex = '<h2.*?>(.*?)<\/h2>'
     $matches_arr = [regex]::Matches($htmlContent, $regex)
     # Output search results
     $resultCount = 10#[Math]::Min($count, $matches_arr.Count)
	 if ($matches_arr.Count -lt $resultCount){$resultCount=$matches_arr.Count}
		
     for ($i = 0; $i -lt $resultCount; $i++) {
         $htmlString = $matches_arr[$i].Groups[1].Value
		 
		 # Regular expression pattern to extract the link text and URL
		 $pattern = '<a\s+[^>]*?href="([^"]*)"[^>]*?>(.*?)<\/a>'
		 # Extract link text and URL using regex
		if ($htmlString -match $pattern) {
			$linkURL = $matches[1]
			$linkText = $matches[2]
			
			
			# Display the link neatly
			Write-Host "$($i + 1).`nLink Text:`t$linkText`nLink URL:`t$linkURL`n"
		} else {
			Write-Host "No link found."
		}
     }
 }

# Find a keywork in a directory full of excel files 

function find_file {
    param (
        [string]$PathToFolder,   # Path to the folder containing Excel files
        [string]$Keyword         # Keyword to search for in the Excel files
    )

    # Get all the Excel files in the folder
    $excelFiles = Get-ChildItem -Path $PathToFolder -Filter *.csv

    # Loop through each Excel file and check for the keyword
    foreach ($file in $excelFiles) {
        $filePath = Join-Path $PathToFolder $file.Name
        
        # Load Excel COM object
        $excel = New-Object -ComObject Excel.Application
        $excel.Visible = $false
        $excel.DisplayAlerts = $false
        
        # Open the workbook
        $workbook = $excel.Workbooks.Open($filePath)
        
        # Loop through each worksheet in the workbook
        $found = $false
        foreach ($sheet in $workbook.Sheets) {
            $usedRange = $sheet.UsedRange.Value2
            
            # Search for the keyword in the used range of the worksheet
            foreach ($row in $usedRange) {
                if ($row -contains $Keyword) {
                    Write-Output "Found '$Keyword' in file: $file.Name"
                    $found = $true
                    break
                }
            }
            
            if ($found) {
                break
            }
        }
        
        # Close the workbook
        $workbook.Close($false)
        $excel.Quit()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
        
        if ($found) {
            return $file.Name  # Return the file name if found
        }
    }

    Write-Output "No files contain the keyword '$Keyword'."
    return $null
}
