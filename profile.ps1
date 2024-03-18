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

