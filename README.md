# PowerShell---Hyper-V-Veeam-backup-check
Email Admins a list of Hyper-V servers that are not part of any Veeam backup job.

This script will query your SCVMM Server for a list of all VMs and your Veeam Backup & Replications server for a list of all machines in all backup jobs.  These two lists will be compared and a report containing Hyper-V machines that DO NOT belong to a backup job will be sent to you via email.

**Prerequisites:**
1. SMTP relay server address
2. Veeam Backup and Replication console installed on the machine running the script (for the Veeam PSSnap-in)
3. SCVMM Manager installed on the machine running the script (For the SCVMM Snap-in)
4. Active Directory PowerShell module (If you want to use a security group for the email recipients)
   
**SETUP**
Modify the following lines:
```
1. $WorkingDirectory = "C:\TEMP" # Network or Local directory where temp files will be placed
2. $EmailFromAddress = "NoReply@YOURDOMAIN.COM" # This is the FROM address that will appear in the email.
4. $EmailRecipients = (Get-ADGroupMember "NAME OF THE AD GROUP CONTAINING THE RECIPIENTS" | Get-ADUser -Properties EmailAddress | Select-Object -Expand EmailAddress) # This is the AD Security group to wich the members will be sent the report.
5. #$EmailRecipients = "Recipient@YOURDOMAIN.COM","AnotherRecipient@YOURDOMAIN.COM" # Use this variable instead of AD Group above for hard-coded recipients. Remember to comment out the one above this line.
7. $EmailSubject = "Hyper-V / Veeam Backup Check" # This is the email SUBJECT.
8. $EmailSMTPServer = "YOUR-RELAY-SERVER-ADDRESS"  # This is the SMTP server for the email function. (Example: smpt-relay.gmail.com)
9. $SCVMMServerName = "YOUR-SCVMM-SERVER-FQDN" # FQDN of SCVMM Server (Example: MyScvmm.Mydomain.local)
10. $VeeamServerName = "YOUR-VEEAM-SERVER-FQDN" # FQDN of Veeam Backup and Replication Server (Example: MyVeeam.Mydomain.local)
```

**SCHEDULED TASK CONFIGURATION**</br>
1. Schedule a task on a Windows Server or Workstation with PowerShell, VeeamConsole and SCVMM Management Console.
(NOTE: This machine needs the ActiveDirectory PowerShell module, as noted in prerequisite #4, above)
2. Run the task as a user that has R/W permissions on the direcory in line 1 of the setup section and "Domain Admin" permissions.
3. Create a Scheduled task that runs daily (or weekly, depening of your needs).
4. The action should be:  C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
5. The command line argument should be:  -File \\\PATH-TO-POWERSHELL-FILE\PowerShell_HyperV-VeeamBackupJobs.ps1

You are now done!</br>
You can test the script by manually running the scheduled task.  You should receive an email (if you are in the recipient security group).

**TROUBLESHOOTING**</br>
If you are not recieving an email after manually running the scheduled task or if the task indicates a failure, you can open the script in the PowerShell ISE and run it from there.
That will give you any error codes that may arise.

**COMMON ERRORS**</br>
SMTP relay server misconfiguration.</br>
Network share or local permissions.</br>
Shecduled Task Run-As user is not a "Domain Admin".</br>
The "ActiveDirectory" PowerShell module is not installed on the task server.
