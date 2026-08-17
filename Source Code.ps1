$ErrorActionPreference = "Stop"

try {
    [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
    [Console]::InputEncoding  = New-Object System.Text.UTF8Encoding($false)

    if ($PSVersionTable.PSVersion.Major -lt 7) {
        cmd /c chcp 65001 > $null
    }
}
catch {
}

function Show-Banner {

    Write-Host "Created by robby5pryk-sudo" -ForegroundColor Cyan
    Write-Host "Visit on github" -ForegroundColor Cyan

    Write-Host ""
}

try {

    $AppDir = Join-Path $env:APPDATA "LuaObfuscatorTool"
    $ApiKeyFile = Join-Path $AppDir "apikey.txt"

    if (-not (Test-Path -LiteralPath $AppDir)) {
        New-Item -ItemType Directory -Force -Path $AppDir | Out-Null
    }

    function Get-Or-Input-ApiKey {

        $SavedApiKey = $null

        if (Test-Path -LiteralPath $ApiKeyFile -PathType Leaf) {

            try {
                $SavedApiKey = [System.IO.File]::ReadAllText(
                    $ApiKeyFile,
                    [System.Text.Encoding]::UTF8
                ).Trim()
            }
            catch {
                $SavedApiKey = $null
            }
        }

        if (-not [string]::IsNullOrWhiteSpace($SavedApiKey)) {

            while ($true) {

                Clear-Host
                Show-Banner

                Write-Host "============================================================" -ForegroundColor DarkCyan
                Write-Host "                       API KEY" -ForegroundColor DarkCyan
                Write-Host "============================================================" -ForegroundColor DarkCyan
                Write-Host ""

                Write-Host "[INFO] Ditemukan API Key tersimpan di sistem." -ForegroundColor Green

                $maskLen = [Math]::Min(6, $SavedApiKey.Length)

                if ($maskLen -gt 0) {
                    Write-Host "Key saat ini : $($SavedApiKey.Substring(0, $maskLen))..." -ForegroundColor DarkGray
                }

                Write-Host ""
                Write-Host "[1] Gunakan API Key tersimpan" -ForegroundColor White
                Write-Host "[2] Masukkan API Key baru" -ForegroundColor White
                Write-Host ""

                $Choice = Read-Host "Pilih opsi (1/2)"

                if ($Choice -eq "1") {
                    return $SavedApiKey
                }

                if ($Choice -eq "2") {
                    break
                }

                Write-Host ""
                Write-Host "[ERROR] Pilihan tidak valid." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }

        while ($true) {

            Clear-Host
            Show-Banner

            Write-Host "============================================================" -ForegroundColor DarkCyan
            Write-Host "                     INPUT API KEY" -ForegroundColor DarkCyan
            Write-Host "============================================================" -ForegroundColor DarkCyan
            Write-Host ""

            Write-Host "[API] Masukkan API Key LuaObfuscator:" -ForegroundColor Yellow
            Write-Host ""

            $NewApiKey = Read-Host "API Key"

            if ([string]::IsNullOrWhiteSpace($NewApiKey)) {

                Write-Host ""
                Write-Host "[ERROR] API Key tidak boleh kosong." -ForegroundColor Red
                Start-Sleep -Seconds 2

                continue
            }

            $NewApiKey = $NewApiKey.Trim()

            try {

                [System.IO.File]::WriteAllText(
                    $ApiKeyFile,
                    $NewApiKey,
                    [System.Text.UTF8Encoding]::new($false)
                )

                Write-Host ""
                Write-Host "[OK] API Key berhasil disimpan." -ForegroundColor Green
                Start-Sleep -Seconds 1

            }
            catch {

                Write-Host ""
                Write-Host "[WARNING] Tidak dapat menyimpan API Key." -ForegroundColor Yellow
                Write-Host $_.Exception.Message -ForegroundColor Yellow
                Start-Sleep -Seconds 2
            }

            return $NewApiKey
        }
    }

    $ApiKey = Get-Or-Input-ApiKey

    $NewScriptUrl = "https://api.luaobfuscator.com/v1/obfuscator/newscript"
    $ObfuscateUrl = "https://api.luaobfuscator.com/v1/obfuscator/obfuscate"

    while ($true) {

        Clear-Host
        Show-Banner

        Write-Host "============================================================" -ForegroundColor DarkCyan
        Write-Host "                         FILE LUA" -ForegroundColor DarkCyan
        Write-Host "============================================================" -ForegroundColor DarkCyan
        Write-Host ""

        Write-Host "Ketik GANTI untuk mengganti API Key." -ForegroundColor DarkGray
        Write-Host "Ketik EXIT untuk keluar." -ForegroundColor DarkGray
        Write-Host ""

        $LuaFile = Read-Host "Masukkan path file Lua"

        if ($LuaFile.Trim().ToUpper() -eq "EXIT") {

            Write-Host ""
            Write-Host "Keluar dari program." -ForegroundColor Cyan
            break
        }

        if ($LuaFile.Trim().ToUpper() -eq "GANTI") {

            $ApiKey = Get-Or-Input-ApiKey

            continue
        }

        if ([string]::IsNullOrWhiteSpace($LuaFile)) {

            Write-Host ""
            Write-Host "[ERROR] Path file kosong." -ForegroundColor Red
            Start-Sleep -Seconds 2

            continue
        }

        $LuaFile = $LuaFile.Trim().Trim('"')

        if (-not (Test-Path -LiteralPath $LuaFile -PathType Leaf)) {

            Write-Host ""
            Write-Host "[ERROR] File tidak ditemukan:" -ForegroundColor Red
            Write-Host $LuaFile -ForegroundColor Yellow
            Write-Host ""

            Read-Host "Tekan ENTER untuk mengulang"

            continue
        }

        $InputPath = (Resolve-Path -LiteralPath $LuaFile).Path

        $Extension = [System.IO.Path]::GetExtension($InputPath)

        if ($Extension.ToLower() -ne ".lua") {

            Write-Host ""
            Write-Host "[WARNING] File bukan .lua." -ForegroundColor Yellow
            Write-Host "Tetap mencoba memproses..." -ForegroundColor Yellow
        }

        Write-Host ""
        Write-Host "[1/4] Membaca file Lua..." -ForegroundColor Yellow

        try {

            $LuaCode = [System.IO.File]::ReadAllText(
                $InputPath,
                [System.Text.Encoding]::UTF8
            )

        }
        catch {

            Write-Host ""
            Write-Host "[ERROR] Tidak bisa membaca file." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            Write-Host ""

            Read-Host "Tekan ENTER untuk mengulang"

            continue
        }

        if ([string]::IsNullOrWhiteSpace($LuaCode)) {

            Write-Host ""
            Write-Host "[ERROR] File Lua kosong." -ForegroundColor Red
            Write-Host ""

            Read-Host "Tekan ENTER untuk mengulang"

            continue
        }

        Write-Host "[OK] File berhasil dibaca." -ForegroundColor Green
        Write-Host "[INFO] $($LuaCode.Length) karakter" -ForegroundColor DarkGray

        Write-Host ""
        Write-Host "[2/4] Membuat session LuaObfuscator..." -ForegroundColor Yellow

        $NewScriptHeaders = @{
            "apikey" = $ApiKey
        }

        try {

            $Response = Invoke-RestMethod `
                -Uri $NewScriptUrl `
                -Method POST `
                -Headers $NewScriptHeaders `
                -ContentType "application/json" `
                -Body $LuaCode

        }
        catch {

            Write-Host ""
            Write-Host "============================================================" -ForegroundColor Red
            Write-Host "                    NEW SCRIPT ERROR" -ForegroundColor Red
            Write-Host "============================================================" -ForegroundColor Red
            Write-Host ""

            Write-Host $_.Exception.Message -ForegroundColor Red

            if ($_.ErrorDetails.Message) {

                Write-Host ""
                Write-Host "SERVER RESPONSE:" -ForegroundColor Yellow
                Write-Host $_.ErrorDetails.Message -ForegroundColor White
            }

            Write-Host ""

            Read-Host "Tekan ENTER untuk mengulang"

            continue
        }

        if ($null -eq $Response) {

            Write-Host ""
            Write-Host "[ERROR] Response server kosong." -ForegroundColor Red
            Write-Host ""

            Read-Host "Tekan ENTER untuk mengulang"

            continue
        }

        if ($Response.message) {

            Write-Host ""
            Write-Host "[SERVER] $($Response.message)" -ForegroundColor Red
            Write-Host ""

            Read-Host "Tekan ENTER untuk mengulang"

            continue
        }

        $SessionId = $Response.sessionId

        if ([string]::IsNullOrWhiteSpace($SessionId)) {

            Write-Host ""
            Write-Host "[ERROR] sessionId tidak ditemukan." -ForegroundColor Red
            Write-Host ""

            Write-Host "Response server:" -ForegroundColor Yellow

            $Response |
                ConvertTo-Json -Depth 20 |
                Write-Host

            Write-Host ""

            Read-Host "Tekan ENTER untuk mengulang"

            continue
        }

        Write-Host "[OK] Session berhasil dibuat." -ForegroundColor Green

        $ConfigObject = @{
            MinifiyAll = $true
            Virtualize = $true
        }

        $Config = $ConfigObject | ConvertTo-Json -Depth 20

        Write-Host ""
        Write-Host "[3/4] Menjalankan obfuscation..." -ForegroundColor Yellow
        Write-Host "[INFO] Tunggu..." -ForegroundColor DarkGray

        $ObfuscateHeaders = @{
            "apikey"    = $ApiKey
            "sessionId" = $SessionId
        }

        try {

            $Result = Invoke-RestMethod `
                -Uri $ObfuscateUrl `
                -Method POST `
                -Headers $ObfuscateHeaders `
                -ContentType "application/json" `
                -Body $Config

        }
        catch {

            Write-Host ""
            Write-Host "============================================================" -ForegroundColor Red
            Write-Host "                    OBFUSCATION ERROR" -ForegroundColor Red
            Write-Host "============================================================" -ForegroundColor Red
            Write-Host ""

            Write-Host $_.Exception.Message -ForegroundColor Red

            if ($_.ErrorDetails.Message) {

                Write-Host ""
                Write-Host "LUAOBFUSCATOR RESPONSE:" -ForegroundColor Yellow
                Write-Host $_.ErrorDetails.Message -ForegroundColor White
            }

            Write-Host ""

            Read-Host "Tekan ENTER untuk mengulang"

            continue
        }

        if ($null -eq $Result) {

            Write-Host ""
            Write-Host "[ERROR] Response obfuscation kosong." -ForegroundColor Red
            Write-Host ""

            Read-Host "Tekan ENTER untuk mengulang"

            continue
        }

        if ($Result.message) {

            Write-Host ""
            Write-Host "[SERVER] $($Result.message)" -ForegroundColor Yellow
        }

        $ObfuscatedCode = $Result.code

        if ([string]::IsNullOrWhiteSpace($ObfuscatedCode)) {

            Write-Host ""
            Write-Host "[ERROR] Server tidak mengembalikan code obfuscated." -ForegroundColor Red
            Write-Host ""

            Write-Host "FULL RESPONSE:" -ForegroundColor Yellow

            $Result |
                ConvertTo-Json -Depth 20 |
                Write-Host

            Write-Host ""

            Read-Host "Tekan ENTER untuk mengulang"

            continue
        }

        Write-Host "[OK] Obfuscation berhasil." -ForegroundColor Green

        $Directory = Split-Path -Parent $InputPath

        $BaseName = [System.IO.Path]::GetFileNameWithoutExtension(
            $InputPath
        )

        $OutputPath = Join-Path `
            $Directory `
            ($BaseName + "_obfuscated.lua")

        Write-Host ""
        Write-Host "[4/4] Menyimpan file..." -ForegroundColor Yellow

        try {

            [System.IO.File]::WriteAllText(
                $OutputPath,
                $ObfuscatedCode,
                [System.Text.UTF8Encoding]::new($false)
            )

        }
        catch {

            Write-Host ""
            Write-Host "[ERROR] Gagal menyimpan file." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            Write-Host ""

            Read-Host "Tekan ENTER untuk mengulang"

            continue
        }

        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Green
        Write-Host "                 OBFUSCATION BERHASIL" -ForegroundColor Green
        Write-Host "============================================================" -ForegroundColor Green
        Write-Host ""

        Write-Host "[INPUT]" -ForegroundColor White
        Write-Host $InputPath -ForegroundColor DarkGray

        Write-Host ""
        Write-Host "[OUTPUT]" -ForegroundColor White
        Write-Host $OutputPath -ForegroundColor Cyan

        Write-Host ""
        Write-Host "[INFO] Ukuran asli      : $($LuaCode.Length) karakter" -ForegroundColor DarkGray
        Write-Host "[INFO] Ukuran obfuscated: $($ObfuscatedCode.Length) karakter" -ForegroundColor DarkGray

        Write-Host ""
        Write-Host "Proses selesai." -ForegroundColor Green
        Write-Host ""

        Start-Sleep -Seconds 2
    }
}
catch {

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host "                   FATAL ERROR" -ForegroundColor Red
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host ""

    Write-Host $_.Exception.Message -ForegroundColor Red

    Write-Host ""
    Read-Host "Tekan ENTER untuk keluar"
}