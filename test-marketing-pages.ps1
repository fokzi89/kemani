$routes = @("/", "/about", "/blog", "/contact", "/cookies", "/features", "/help", "/medic", "/pos-admin", "/pricing", "/privacy", "/terms", "/use-cases")
$results = @()

foreach ($route in $routes) {
    try {
        $url = "http://localhost:5173$route"
        $request = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10
        $statusCode = $request.StatusCode
        $content = $request.Content
        
        $title = "No Title"
        if ($content -match "(?i)<title[^>]*>\s*(.*?)\s*</title>") {
            $title = $Matches[1]
        }
        
        $results += "✅ $( $route.PadRight(12) ) - Status: $statusCode - Title: $title"
    } catch {
        $errMsg = $_.Exception.Message
        $results += "❌ $( $route.PadRight(12) ) - Error: $errMsg"
    }
}

Write-Output ""
Write-Output "--- FULL RESULTS ---"
$results | ForEach-Object { Write-Output $_ }
