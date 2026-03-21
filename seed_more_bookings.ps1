$baseUrl = "https://atrioappcloude-atrioappcloude.2rfeor.easypanel.host/rest/v1"
$serviceKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJzZXJ2aWNlX3JvbGUiLAogICAgImlzcyI6ICJzdXBhYmFzZS1kZW1vIiwKICAgICJpYXQiOiAxNjQxNzY5MjAwLAogICAgImV4cCI6IDE3OTk1MzU2MDAKfQ.DaYlNEoUrrEn2Ig7tqibS-PHK5vgusbcbo7X36XVt4Q"

$headers = @{
    "apikey" = $serviceKey
    "Authorization" = "Bearer $serviceKey"
    "Content-Type" = "application/json"
    "Prefer" = "return=representation"
}

$guestId = "98e8b712-ae4d-446e-9c50-bf621a1efe75"
$hostId = "053c11bd-9fd7-484e-bb30-d75532d4db54"

$now = Get-Date
$tomorrow = $now.AddDays(1).ToString("yyyy-MM-ddTHH:mm:ssZ")
$in3days = $now.AddDays(3).ToString("yyyy-MM-ddTHH:mm:ssZ")
$in6days = $now.AddDays(6).ToString("yyyy-MM-ddTHH:mm:ssZ")
$twoDaysAgo = $now.AddDays(-2).ToString("yyyy-MM-ddTHH:mm:ssZ")
$yesterday = $now.AddDays(-1).ToString("yyyy-MM-ddTHH:mm:ssZ")
$in2days = $now.AddDays(2).ToString("yyyy-MM-ddTHH:mm:ssZ")
$twoWeeksAgo = $now.AddDays(-14).ToString("yyyy-MM-ddTHH:mm:ssZ")
$oneWeekAgo = $now.AddDays(-7).ToString("yyyy-MM-ddTHH:mm:ssZ")
$dayAfterTomorrow = $now.AddDays(2).ToString("yyyy-MM-ddTHH:mm:ssZ")

$listing1 = "acc668ed-ff97-4bd8-88a0-aa4d9f9a2e95"
$listing2 = "34adcddb-33d6-4ac2-884e-3b22afeefc0b"
$listing3 = "4f2aae6a-1796-4119-ad31-a54c2c8e8a15"
$listing4 = "110db16f-cc1d-4240-a189-8be288e127c0"
$listing5 = "29b61469-2d17-4697-a008-465ff2ce6c47"

$bookings = @(
    @{
        guest_id = $guestId; host_id = $hostId; listing_id = $listing1
        check_in = $tomorrow; check_out = $dayAfterTomorrow
        guests_count = 2; base_total = 370; cleaning_fee = 25; service_fee = 44.40; total = 439.40
        status = "confirmed"; payment_status = "paid"; special_requests = "Llegamos tarde, despues de las 18h"
    },
    @{
        guest_id = $guestId; host_id = $hostId; listing_id = $listing2
        check_in = $in3days; check_out = $in6days
        guests_count = 4; base_total = 1350; cleaning_fee = 50; service_fee = 162; total = 1562
        status = "pending"; payment_status = "pending"; special_requests = "Celebracion de cumpleanos"
    },
    @{
        guest_id = $guestId; host_id = $hostId; listing_id = $listing3
        check_in = $twoWeeksAgo; check_out = $oneWeekAgo
        guests_count = 2; base_total = 190; cleaning_fee = 0; service_fee = 22.80; total = 212.80
        status = "completed"; payment_status = "paid"
    },
    @{
        guest_id = $guestId; host_id = $hostId; listing_id = $listing4
        check_in = $twoDaysAgo; check_out = $yesterday
        guests_count = 1; base_total = 150; cleaning_fee = 0; service_fee = 18; total = 168
        status = "cancelled"; payment_status = "refunded"; special_requests = "Cambio de planes"
    },
    @{
        guest_id = $guestId; host_id = $hostId; listing_id = $listing5
        check_in = $yesterday; check_out = $in2days
        guests_count = 3; base_total = 660; cleaning_fee = 30; service_fee = 79.20; total = 769.20
        status = "active"; payment_status = "paid"; special_requests = "Evento corporativo privado"
    }
)

Write-Host "=== Inserting 5 bookings ==="
$count = 0
foreach ($b in $bookings) {
    $count++
    $body = $b | ConvertTo-Json -Compress
    Write-Host "`nBooking $count : status=$($b.status)"
    try {
        $resp = Invoke-RestMethod -Uri "$baseUrl/bookings" -Headers $headers -Method Post -Body $body
        Write-Host "  OK: id=$($resp.id)"
    } catch {
        try {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $errBody = $reader.ReadToEnd()
            Write-Host "  FAIL: $errBody"
        } catch {
            Write-Host "  FAIL: $_"
        }
    }
}

Write-Host "`n=== Verify ==="
try {
    $all = Invoke-RestMethod -Uri "$baseUrl/bookings?guest_id=eq.$guestId&select=id,status,total" -Headers $headers -Method Get
    Write-Host "Total: $($all.Count)"
    foreach ($bk in $all) {
        Write-Host "  $($bk.id) | $($bk.status) | `$$($bk.total)"
    }
} catch {
    Write-Host "Verify failed: $_"
}
