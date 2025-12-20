 $guestAccount = Get-ADUser -Identity "Guest" -ErrorAction Stop
 Disable-ADAccount -Identity $guestAccount.SamAccountName