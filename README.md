


# Instructions 
1) open a powershell (click windows button and write powershell)

2) Copy and paste the below comamnds to make a profile
``` ps1
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted
new-item -path $profile -itemtype file -force
notepad $profile
```
