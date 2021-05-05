$WorkingDirectory = "C:\TEMP" # Network or Local directory where temp files will be placed
$EmailFromAddress = "NoReply@YOURDOMAIN.COM" # This is the FROM address that will appear in the email.
# -------- RECIPIENT CHOICES --------------
$EmailRecipients = (Get-ADGroupMember "NAME OF THE AD GROUP CONTAINING THE RECIPIENTS" | Get-ADUser -Properties EmailAddress | Select-Object -Expand EmailAddress) # This is the AD Security group to wich the members will be sent the report.
#$EmailRecipients = "Recipient@YOURDOMAIN.COM","AnotherRecipient@YOURDOMAIN.COM" # Use this variable instead of AD Group above for hard-coded recipients. Remember to comment out the one above this line.
# -----------------------------------------
$EmailSubject = "Hyper-V / Veeam Backup Check" # This is the email SUBJECT.
$EmailSMTPServer = "YOUR-RELAY-SERVER-ADDRESS"  # This is the SMTP server for the email function. (Example: smpt-relay.gmail.com)
$SCVMMServerName = "YOUR-SCVMM-SERVER-FQDN" # FQDN of SCVMM Server (Example: MyScvmm.Mydomain.local)
$VeeamServerName = "YOUR-VEEAM-SERVER-FQDN" # FQDN of Veeam Backup and Replication Server (Example: MyVeeam.Mydomain.local)
# ------------------- END OF CUSTOM VARIABLES -------------------------------------------
$VeeamFile = "$WorkingDirectory\VeeamServers.txt"
$ServerNoBackupList = "$WorkingDirectory\NoBackupList.txt"
$SCVMMFile = "$WorkingDirectory\ScvmmServers.csv"
Add-PSSnapIn veeampssnapin
Connect-VBRServer -Server $VeeamServerName
Foreach ($Job in Get-VBRJob)
{
$Job |Select-Object @{Name="Objectsinjob";Expression={$_.GetObjectsInJob().name}} | Select-Object -expandproperty Objectsinjob | Out-File -FilePath $VeeamFile -Append
}
Disconnect-VBRServer
$VeeamServers = Get-Content -Path $VeeamFile
Get-SCVirtualMachine -VMMServer $SCVMMServerName | Select-Object Name | Export-CSV -Path $SCVMMFile -NoTypeInformation
$SCVMMServers = Import-CSV -Path $SCVMMFile | Select-Object Name
ForEach ($Server in $SCVMMServers)
    {    
    IF ($VeeamServers -contains $Server.Name){}
    Else {
        $Content = $Server.Name + "</br>"
        Add-Content -Path $ServerNoBackupList -Value $Content        
        }
    }
Remove-Item -Path $VeeamFile,$SCVMMFile
# ------------------- EMAIL SETTINGS ----------------------------
$NoBackupList = Get-Content -Path $ServerNoBackupList
$mailBody = 
@"
Hello I.T. Folks,</br>
For your records, here is a list of Hyper-V Servers that <b>DO NOT</b> have a Veeam backup job.</br>
<hr>
$NoBackupList
<hr>
Best Regards,</br>
<i>Script written by: Matt Elsberry</i></br>
This script was executed from <b>$env:computername</b> by <b>$env:UserName</b></br>
"@
Send-MailMessage -Body $mailBody -BodyAsHtml `
-From $EmailFromAddress -To $EmailRecipients `
-Subject $EmailSubject -Encoding $([System.Text.Encoding]::UTF8) `
-SmtpServer $EmailSMTPServer
Remove-Item -Path $ServerNoBackupList