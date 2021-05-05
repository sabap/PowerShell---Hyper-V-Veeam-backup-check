$WorkingDirectory = "C:\TEMP" # Network or Local directory where temp files will be placed
$EmailFromAddress = "NoReply@sgmc.org" # This is the FROM address that will appear in the email.
# -------- RECIPIENT CHOICES --------------
$EmailRecipients = (Get-ADGroupMember "SCRIPTSendMail_VeeamHyperVMissingBackup" | Get-ADUser -Properties EmailAddress | Select-Object -Expand EmailAddress) # This is the AD Security group to wich the members will be sent the report.
#$EmailRecipients = "Recipient@mail.com","AnotherRecipient@mail.com" # Use this variable instead of AD Group for hard-coded recipients
# -----------------------------------------
$EmailSubject = "Hyper-V / Veeam Backup Check" # This is the email SUBJECT.
$EmailSMTPServer = "relay.sgmc.org"  # This is the SMTP server for the email function.
$SCVMMServerName = "SG-SCVMM01.sgmc.org" # FQDN of SCVMM Server
$VeeamServerName = "SG-VEEAM-01.sgmc.org" # FQDN of Veeam Backup and Replication Server
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