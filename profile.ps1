# Function to provide a list of available functions/methods living on the $profile


function list {
  Write-Host "Here is the list of available functions in your profile ... "
  # Get the profile path
  $ProfilePath = $PROFILE



  # Get functions defined in the profile
  Get-ChildItem Function: | Where-Object { $_.ScriptBlock.File -eq $ProfilePath } | Select-Object Name, @{Name="Definition"; Expression={$_.ScriptBlock}}
}
