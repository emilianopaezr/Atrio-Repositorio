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

$listing1 = "acc668ed-ff97-4bd8-88a0-aa4d9f9a2e95"
$listing2 = "34adcddb-33d6-4ac2-884e-3b22afeefc0b"
$listing3 = "4f2aae6a-1796-4119-ad31-a54c2c8e8a15"

$reviews = @(
    @{
        listing_id = $listing1; reviewer_id = $guestId; host_id = $hostId
        rating = 5; comment = "Increible espacio! El loft es aun mejor en persona. Muy limpio y el anfitrion super atento."
    },
    @{
        listing_id = $listing2; reviewer_id = $guestId; host_id = $hostId
        rating = 4; comment = "La villa es hermosa y la piscina espectacular. Solo desearIa que el WiFi fuera mas rapido."
        host_reply = "Gracias por tu resena! Ya estamos mejorando la conexion WiFi."
    },
    @{
        listing_id = $listing3; reviewer_id = $guestId; host_id = $hostId
        rating = 5; comment = "El tour gastronomico fue una experiencia unica. Los lugares que visitamos eran autenticos y la comida deliciosa."
    },
    @{
        listing_id = $listing1; reviewer_id = $hostId; host_id = $hostId
        rating = 4; comment = "Muy buen loft para sesiones de fotos. Buena iluminacion natural."
    }
)

Write-Host "=== Inserting reviews ==="
$count = 0
foreach ($r in $reviews) {
    $count++
    $body = $r | ConvertTo-Json -Compress
    try {
        $resp = Invoke-RestMethod -Uri "$baseUrl/reviews" -Headers $headers -Method Post -Body $body
        Write-Host "  $count OK: rating=$($r.rating) for listing=$($r.listing_id)"
    } catch {
        try {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $errBody = $reader.ReadToEnd()
            Write-Host "  $count FAIL: $errBody"
        } catch {
            Write-Host "  $count FAIL: $_"
        }
    }
}
Write-Host "Done!"
