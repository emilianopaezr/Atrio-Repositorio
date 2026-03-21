$baseUrl = "https://atrioappcloude-atrioappcloude.2rfeor.easypanel.host/rest/v1"
$serviceKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJzZXJ2aWNlX3JvbGUiLAogICAgImlzcyI6ICJzdXBhYmFzZS1kZW1vIiwKICAgICJpYXQiOiAxNjQxNzY5MjAwLAogICAgImV4cCI6IDE3OTk1MzU2MDAKfQ.DaYlNEoUrrEn2Ig7tqibS-PHK5vgusbcbo7X36XVt4Q"

$headers = @{
    "apikey" = $serviceKey
    "Authorization" = "Bearer $serviceKey"
    "Content-Type" = "application/json"
    "Prefer" = "return=representation"
}

# Update Loft Industrial: 2 reviews (5+4)/2 = 4.5
$body1 = '{"rating": 4.5, "review_count": 2}'
Invoke-RestMethod -Uri "$baseUrl/listings?id=eq.acc668ed-ff97-4bd8-88a0-aa4d9f9a2e95" -Headers $headers -Method Patch -Body $body1
Write-Host "Loft: 4.5 (2 reviews)"

# Update Villa Piscina: 1 review = 4.0
$body2 = '{"rating": 4.0, "review_count": 1}'
Invoke-RestMethod -Uri "$baseUrl/listings?id=eq.34adcddb-33d6-4ac2-884e-3b22afeefc0b" -Headers $headers -Method Patch -Body $body2
Write-Host "Villa: 4.0 (1 review)"

# Update Tour Gastro: 1 review = 5.0
$body3 = '{"rating": 5.0, "review_count": 1}'
Invoke-RestMethod -Uri "$baseUrl/listings?id=eq.4f2aae6a-1796-4119-ad31-a54c2c8e8a15" -Headers $headers -Method Patch -Body $body3
Write-Host "Tour: 5.0 (1 review)"

Write-Host "Done!"
