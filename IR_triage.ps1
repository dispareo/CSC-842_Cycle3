<#
.DESCRIPTION
    This is a powershell script that provides basic IR capabilities through different channels. Make sure you run as admin
.EXAMPLE
    C:\PS> 
    .\Quickhits -last30 #Grabs logs from the last 30 days
    .\Quickhits -all #Grabs logs from all time - or, more likely, whenever you ran out of mem and they rolled over
    .\Quickhits -dates #Grabs logs from a specific date range that was a pain to figure out, even though the solution was simpler than I thought it would be

.NOTES
    Must be run as admin
#>

param (
    [switch]$all,    # Switch for all logs
    [switch]$dates,  # Switch for specific dates
    [switch]$last30  # Switch for last 30 days
)

# Check for admin privileges - borrowed from script from last cycle
$CurrentWindowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$CurrentWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($CurrentWindowsIdentity)
if ($CurrentWindowsPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Ok, cool, looks like you're running as administrator" -ForegroundColor Green
} else {
    Write-Warning "[!] This is awkward, but you don't have permission. You need admin to do this stuff"
    exit 1
}


#I went back and forth about the dates to determine whether I should write a single function that accepted input as the dates, or 3 different functions
#That were more or less recycled, but I only really had to mess with using inputs as dates once, rather than a single loop that took the params and 
#passed them into date fuinctions. Programmatically, it **probably?** makes more sense to do a single loop/function using the switches to define the dates
#But I'm not really strong enough in powershell to mess with all of that - so, 3 functions which are mostly copy-pastas of each other 
#will have to suffice. Maybe I will go back and tackle this one day. Probably not, but that's something I like to tell myself so I don't just close the door
#On not being a good programmer, even if I'm not a software dev by any means.



function Get-Last30Days {
    $StartDate = (Get-Date).AddDays(-30)
    $EndDate = Get-Date
    Write-Host "[!] Grabbing logs from the last 30 days, from $StartDate to $EndDate" -ForegroundColor Green
    try {
        Write-Host "[!][!] Remember that not all logons that appear here are ACTUAL log ins. This is just a place to get started of where attempts occurred" -ForegroundColor Red
        Write-Host "[*] Grabbing logs for the specified dates" -ForegroundColor Green

        
        Write-Host "[*] These are the 'interactive' logins for that time period." -ForegroundColor Green
        #Get-winevent -FilterHashtable @{logname='security'; id=4624} | where {$_.properties[8].value -eq 2} | Where-Object { $_.TimeCreated -ge $startTime -and $_.TimeCreated -le $endTime }
        Get-winevent -FilterHashtable @{logname='security'; id=4624;StartTime=$StartDate;EndTime=$EndDate} | where {$_.properties[8].value -eq 2}
        Write-Host "[*] These are the 'network-based' logins for that time period." -ForegroundColor Green 
        Get-winevent -FilterHashtable @{logname='security'; id=4624;StartTime=$StartDate;EndTime=$EndDate} | where {$_.properties[8].value -eq 3}
        Write-Host "[*] These are the 'Network Clear Text' logins for that time period." -ForegroundColor Green
        Get-winevent -FilterHashtable @{logname='security'; id=4624;StartTime=$StartDate;EndTime=$EndDate} | where {$_.properties[8].value -eq 8}
        Write-Host "[*] These are the 'Remote Interactive' logins for that time period." -ForegroundColor Green
        Get-winevent -FilterHashtable @{logname='security'; id=4624;StartTime=$StartDate;EndTime=$EndDate} | where {$_.properties[8].value -eq 10}
        
        Write-Host "[*] Here are the RDP logs for that time period. Make sure you cross reference them" -ForegroundColor Green
        Get-WinEvent -FilterHashtable @{logname='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational';StartTime=$StartDate;EndTime=$EndDate}
        Get-WinEvent -FilterHashtable @{logname='Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational';StartTime=$StartDate;EndTime=$EndDate}

        Write-Host "[*] Here are the SSH logs for that time period. Make sure you cross reference them" -ForegroundColor Green
        Get-WinEvent -LogName OpenSSH/Operational
        Write-Host "[*] Here are the Application logs for that time period. No idea what  you'll fiond there, but hopefully something" -ForegroundColor Green
        Get-WinEvent -FilterHashtable @{logname='Application';Level={0..3};StartTime=$StartDate;EndTime=$EndDate}
    }
    catch {
        Write-Host "Something went wrong: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Get-AllLogs {
    Write-Host "[!] Grabbing logs since all time (or, more likely, whenever you ran out of mem and they rolled over).`n[!][!] This is prolly going to be a lot of output`n" -ForegroundColor Green
    try {
        Write-Host "[!][!] Remember that not all logons that appear here are ACTUAL log ins. This is just a place to get started of where attempts occurred`n" -ForegroundColor Red
        Write-Host "[*] Grabbing logs for the specified dates" -ForegroundColor Green

        
        Write-Host "[*] These are the 'interactive' logins for that time period." -ForegroundColor Green
        #Get-winevent -FilterHashtable @{logname='security'; id=4624} | where {$_.properties[8].value -eq 2} | Where-Object { $_.TimeCreated -ge $startTime -and $_.TimeCreated -le $endTime }
        Get-winevent -FilterHashtable @{logname='security'; id=4624} | where {$_.properties[8].value -eq 2}
        Write-Host "[*] These are the 'network-based' logins for that time period." -ForegroundColor Green 
        Get-winevent -FilterHashtable @{logname='security'; id=4624} | where {$_.properties[8].value -eq 3}
        Write-Host "[*] These are the 'Network Clear Text' logins for that time period." -ForegroundColor Green
        Get-winevent -FilterHashtable @{logname='security'; id=4624} | where {$_.properties[8].value -eq 8}
        Write-Host "[*] These are the 'Remote Interactive' logins for that time period." -ForegroundColor Green
        Get-winevent -FilterHashtable @{logname='security'; id=4624} | where {$_.properties[8].value -eq 10}
        
        Write-Host "[*] Here are the RDP logs for that time period. Make sure you cross reference them" -ForegroundColor Green
        Get-WinEvent -FilterHashtable @{logname='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'}
        Get-WinEvent -FilterHashtable @{logname='Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational'}

        Write-Host "[*] Here are the SSH logs for that time period. Make sure you cross reference them" -ForegroundColor Green
        Get-WinEvent -LogName OpenSSH/Operational
        Write-Host "[*] Here are the Application logs for that time period. No idea what  you'll fiond there, but hopefully something" -ForegroundColor Green
        Get-WinEvent -FilterHashtable @{logname='Application';Level={0..3}}
    }   

    catch {
        Write-Host "Something went wrong: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Get-DateRangeLogs {
    Write-Host "[!][!] Important [!][!]`ne
[!] Anytime you are collecting older logs, it is possible (likely?) that the space has run out and has been overwritten by new events.`n
[!] If you are hunting for older stuff and do not have an EDR, SIEM, or security stack, don't get your hopes up`n`n" -ForegroundColor Green
    #I've had enough PS this semester. Going back to bash/python next cycle :-D
    try {
        $StartDate = Get-Date (Read-Host -Prompt 'Enter the *first* date you want to grab logs from, using the format (MM/dd/yyyy HH:mm:ss), e.g. 06/01/2025 00:00:00. If you dont enter the hour and minute, it will default to midnight.`n')
       }
    catch {
        Write-Host "Something broke, probably the date format. Please try again." -ForegroundColor Red
        exit 1
    }
   
    try {
        $EndDate = Get-Date (Read-Host -Prompt 'Enter the end date (MM/dd/yyyy HH:mm:ss), e.g. 06/08/2025 23:59:59. If you dont enter the hour and minute, it will default to midnight.`n') 
            # Sanity check to make sure the start date is before the end date
        }
    catch {
        Write-Host "Something broke, probably the date format. Try again." -ForegroundColor Red
        }

    if ($EndDate -lt $StartDate) {
                Write-Host "[!][!][!] I think you have your dates backwards. Try again?" -ForegroundColor Red
                exit 1
            }
    
    try {
        
        Write-Host "[!][!] Remember that not all logons that appear here are ACTUAL log ins. This is just a place to get started of where attempts occurred`n" -ForegroundColor Red
        Write-Host "[*] Grabbing logs for the specified dates" -ForegroundColor Green

        
        Write-Host "[*] These are the 'interactive' logins for that time period." -ForegroundColor Green
        #Get-winevent -FilterHashtable @{logname='security'; id=4624} | where {$_.properties[8].value -eq 2} | Where-Object { $_.TimeCreated -ge $startTime -and $_.TimeCreated -le $endTime }
        Get-winevent -FilterHashtable @{logname='security'; id=4624;StartTime=$StartDate;EndTime=$EndDate} | where {$_.properties[8].value -eq 2}
        Write-Host "[*] These are the 'network-based' logins for that time period." -ForegroundColor Green 
        Get-winevent -FilterHashtable @{logname='security'; id=4624;StartTime=$StartDate;EndTime=$EndDate} | where {$_.properties[8].value -eq 3}
        Write-Host "[*] These are the 'Network Clear Text' logins for that time period." -ForegroundColor Green
        Get-winevent -FilterHashtable @{logname='security'; id=4624;StartTime=$StartDate;EndTime=$EndDate} | where {$_.properties[8].value -eq 8}
        Write-Host "[*] These are the 'Remote Interactive' logins for that time period." -ForegroundColor Green
        Get-winevent -FilterHashtable @{logname='security'; id=4624;StartTime=$StartDate;EndTime=$EndDate} | where {$_.properties[8].value -eq 10}
        
        Write-Host "[*] Here are the RDP logs for that time period. Make sure you cross reference them" -ForegroundColor Green
        Get-WinEvent -FilterHashtable @{logname='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational';StartTime=$StartDate;EndTime=$EndDate}
        Get-WinEvent -FilterHashtable @{logname='Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational';StartTime=$StartDate;EndTime=$EndDate}

        Write-Host "[*] Here are the SSH logs for that time period. Make sure you cross reference them" -ForegroundColor Green
        Get-WinEvent -LogName OpenSSH/Operational
        Write-Host "[*] Here are the Application logs for that time period. No idea what  you'll fiond there, but hopefully something" -ForegroundColor Green
        Get-WinEvent -FilterHashtable @{logname='Application';Level={0..3};StartTime=$StartDate;EndTime=$EndDate}


    }
    catch {
        Write-Host "Something went wrong: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Process the switches
switch ($true) {
    # If the user wants the last 30 days of logs
    $last30 { Get-Last30Days; break }

    # If the user wants to grab all logs
    $all { Get-AllLogs; break }

    # If the user wants to grab specific dates
    $dates { Get-DateRangeLogs; break }
} 
