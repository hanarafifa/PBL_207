# =============================================
# Script Monitoring Keamanan Server
# =============================================

# Konfigurasi Telegram
$token = "8953641318:AAG179D0m9hLzpi57usSeT5rod5ndkiL5EU"
$chatId = "8767538342"

# Fungsi kirim pesan ke Telegram
function KirimTelegram($pesan) {
    $url = "https://api.telegram.org/bot$token/sendMessage"
    $body = @{
        chat_id = $chatId
        text = $pesan
        parse_mode = "Markdown"
    }
    Invoke-RestMethod -Uri $url -Method Post -Body $body
}

# =============================================
# 1. CEK LOGIN GAGAL
# =============================================
$loginGagal = Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    Id = 4625
    StartTime = (Get-Date).AddMinutes(-5)
} -ErrorAction SilentlyContinue

if ($loginGagal.Count -ge 3) {
    $pesan = "🚨 *ALERT - SecureNet Server*`n"
    $pesan += "━━━━━━━━━━━━━━━━━━━━`n"
    $pesan += "⚠️ *Login GAGAL terdeteksi!*`n"
    $pesan += "🔢 Jumlah percobaan: $($loginGagal.Count)x`n"
    $pesan += "🕐 Waktu: $(Get-Date -Format 'dd/MM/yyyy HH:mm')`n"
    $pesan += "━━━━━━━━━━━━━━━━━━━━"
    KirimTelegram $pesan
}

# =============================================
# 2. CEK LAYANAN BERBAHAYA
# =============================================
$layananBerbahaya = @("RemoteRegistry", "TlntSvr", "telnet")

foreach ($layanan in $layananBerbahaya) {
    $status = Get-Service -Name $layanan -ErrorAction SilentlyContinue
    if ($status.Status -eq "Running") {
        $pesan = "🚨 *ALERT - SecureNet Server*`n"
        $pesan += "━━━━━━━━━━━━━━━━━━━━`n"
        $pesan += "⚠️ *Layanan berbahaya aktif!*`n"
        $pesan += "🔧 Layanan: $layanan`n"
        $pesan += "🕐 Waktu: $(Get-Date -Format 'dd/MM/yyyy HH:mm')`n"
        $pesan += "━━━━━━━━━━━━━━━━━━━━"
        KirimTelegram $pesan
        Stop-Service -Name $layanan -Force
    }
}

# =============================================
# 3. CEK CPU & RAM
# =============================================
$cpu = (Get-WmiObject Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
$ram = (Get-WmiObject Win32_OperatingSystem)
$ramPakai = [math]::Round((($ram.TotalVisibleMemorySize - $ram.FreePhysicalMemory) / $ram.TotalVisibleMemorySize) * 100, 2)

if ($cpu -gt 80 -or $ramPakai -gt 80) {
    $pesan = "🚨 *ALERT - SecureNet Server*`n"
    $pesan += "━━━━━━━━━━━━━━━━━━━━`n"
    $pesan += "⚠️ *Penggunaan resource tinggi!*`n"
    $pesan += "💻 CPU: $cpu%`n"
    $pesan += "🧠 RAM: $ramPakai%`n"
    $pesan += "🕐 Waktu: $(Get-Date -Format 'dd/MM/yyyy HH:mm')`n"
    $pesan += "━━━━━━━━━━━━━━━━━━━━"
    KirimTelegram $pesan
}