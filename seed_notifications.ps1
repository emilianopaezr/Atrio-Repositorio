$baseUrl = "https://atrioappcloude-atrioappcloude.2rfeor.easypanel.host/rest/v1"
$serviceKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJzZXJ2aWNlX3JvbGUiLAogICAgImlzcyI6ICJzdXBhYmFzZS1kZW1vIiwKICAgICJpYXQiOiAxNjQxNzY5MjAwLAogICAgImV4cCI6IDE3OTk1MzU2MDAKfQ.DaYlNEoUrrEn2Ig7tqibS-PHK5vgusbcbo7X36XVt4Q"

$headers = @{
    "apikey" = $serviceKey
    "Authorization" = "Bearer $serviceKey"
    "Content-Type" = "application/json"
    "Prefer" = "return=representation"
}

$guestId = "98e8b712-ae4d-446e-9c50-bf621a1efe75"
$now = Get-Date

$notifications = @(
    @{
        user_id = $guestId
        type = "booking"
        title = "Reserva confirmada"
        body = "Tu reserva en Loft Industrial Premium ha sido confirmada para manana"
        is_read = $false
        created_at = $now.AddHours(-2).ToString("yyyy-MM-ddTHH:mm:ssZ")
    },
    @{
        user_id = $guestId
        type = "message"
        title = "Nuevo mensaje"
        body = "Carlos te ha enviado un mensaje sobre tu reserva"
        is_read = $false
        created_at = $now.AddHours(-5).ToString("yyyy-MM-ddTHH:mm:ssZ")
    },
    @{
        user_id = $guestId
        type = "payment"
        title = "Pago procesado"
        body = "Se ha procesado el pago de $439.40 para tu reserva"
        is_read = $true
        created_at = $now.AddDays(-1).ToString("yyyy-MM-ddTHH:mm:ssZ")
    },
    @{
        user_id = $guestId
        type = "review"
        title = "Deja tu resena"
        body = "Como fue tu experiencia en Tour Gastronómico Santiago? Deja tu opinion"
        is_read = $false
        created_at = $now.AddDays(-1).ToString("yyyy-MM-ddTHH:mm:ssZ")
    },
    @{
        user_id = $guestId
        type = "system"
        title = "Bienvenido a ATRIO"
        body = "Tu cuenta ha sido verificada exitosamente. Explora los mejores espacios y experiencias"
        is_read = $true
        created_at = $now.AddDays(-7).ToString("yyyy-MM-ddTHH:mm:ssZ")
    },
    @{
        user_id = $guestId
        type = "booking"
        title = "Reserva pendiente"
        body = "Tu solicitud para Villa con Piscina Infinita esta pendiente de aprobacion"
        is_read = $false
        created_at = $now.AddHours(-8).ToString("yyyy-MM-ddTHH:mm:ssZ")
    }
)

Write-Host "=== Inserting notifications ==="
$count = 0
foreach ($n in $notifications) {
    $count++
    $body = $n | ConvertTo-Json -Compress
    try {
        $resp = Invoke-RestMethod -Uri "$baseUrl/notifications" -Headers $headers -Method Post -Body $body
        Write-Host "  $count OK: $($n.type) - $($n.title)"
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
