# API Testing Script for PowerShell
# This script tests all API endpoints with various scenarios

$BASE_URL = "http://localhost:3000"
$LICENSE_KEY = "demo-license-key-12345678"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Opera V5 API - Comprehensive Test Suite" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$global:TestsPassed = 0
$global:TestsFailed = 0

function Test-Endpoint {
    param(
        [string]$TestName,
        [string]$Method = "GET",
        [string]$Url,
        [hashtable]$Headers = @{},
        [string]$Body = $null,
        [int[]]$ExpectedStatus
    )
    
    Write-Host "$TestName" -ForegroundColor Yellow
    Write-Host ("-" * 60)
    
    try {
        $params = @{
            Uri = $Url
            Method = $Method
            Headers = $Headers
            UseBasicParsing = $true
        }
        
        if ($Body) {
            $params.Body = $Body
            $params.ContentType = "application/json"
        }
        
        try {
            $response = Invoke-WebRequest @params -ErrorAction Stop
            $statusCode = $response.StatusCode
            $responseBody = $response.Content
        }
        catch {
            if ($_.Exception.Response) {
                $statusCode = $_.Exception.Response.StatusCode.value__
                
                # Try to read response stream
                $stream = $_.Exception.Response.GetResponseStream()
                if ($stream) {
                    $reader = New-Object System.IO.StreamReader($stream)
                    $responseBody = $reader.ReadToEnd()
                    $reader.Close()
                } else {
                    $responseBody = $_.ErrorDetails.Message
                }
            } else {
                $statusCode = 0
                $responseBody = $_.Exception.Message
            }
        }
        
        if ($ExpectedStatus -contains $statusCode) {
            Write-Host "PASS: Got expected status $statusCode" -ForegroundColor Green
            $global:TestsPassed++
        }
        else {
            Write-Host "FAIL: Expected $($ExpectedStatus -join ' or '), got $statusCode" -ForegroundColor Red
            $global:TestsFailed++
        }
        
        Write-Host "Response: $responseBody"
        Write-Host ""
    }
    catch {
        Write-Host "FAIL: Error making request - $_" -ForegroundColor Red
        $global:TestsFailed++
        Write-Host ""
    }
}

# Test 1: Health Check
Test-Endpoint -TestName "1. Testing Health Endpoint" -Url "$BASE_URL/health" -ExpectedStatus @(200)

# Test 2: GET Guest Without API Key
Test-Endpoint -TestName "2. Testing GET Guest Without API Key" -Url "$BASE_URL/api/guests/12345" -ExpectedStatus @(401)

# Test 3: GET Guest With Invalid API Key
Test-Endpoint -TestName "3. Testing GET Guest With Invalid API Key" -Url "$BASE_URL/api/guests/12345" -Headers @{"x-api-key" = "invalid-key"} -ExpectedStatus @(401)

# Test 4: GET Guest With Valid API Key
Test-Endpoint -TestName "4. Testing GET Guest With Valid API Key" -Url "$BASE_URL/api/guests/12345" -Headers @{"x-api-key" = $LICENSE_KEY} -ExpectedStatus @(200, 404, 500)

# Test 5: GET Guest With Invalid nameId Format
Test-Endpoint -TestName "5. Testing GET Guest With Invalid nameId Format" -Url "$BASE_URL/api/guests/abc" -Headers @{"x-api-key" = $LICENSE_KEY} -ExpectedStatus @(400)

# Test 6: PUT Guest Update Without API Key
Test-Endpoint -TestName "6. Testing PUT Guest Update Without API Key" -Method "PUT" -Url "$BASE_URL/api/guests/12345" -Body '{"first_name":"Test"}' -ExpectedStatus @(401)

# Test 7: PUT Guest Update With Valid API Key
$updateBody = @{
    first_name = "Jane"
    last_name = "Smith"
    address = "123 Main Street"
    doc_type = "PASSPORT"
    doc_number = "AB123456"
} | ConvertTo-Json -Compress

Test-Endpoint -TestName "7. Testing PUT Guest Update With Valid API Key" -Method "PUT" -Url "$BASE_URL/api/guests/12345" -Headers @{"x-api-key" = $LICENSE_KEY} -Body $updateBody -ExpectedStatus @(200, 404, 500)

# Test 8: PUT Guest Update With No Fields
Test-Endpoint -TestName "8. Testing PUT Guest Update With No Fields" -Method "PUT" -Url "$BASE_URL/api/guests/12345" -Headers @{"x-api-key" = $LICENSE_KEY} -Body '{}' -ExpectedStatus @(400)

# Test 9: PUT Guest Update With Invalid confirmationNo
Test-Endpoint -TestName "9. Testing PUT Guest Update With Invalid confirmationNo" -Method "PUT" -Url "$BASE_URL/api/guests/abc" -Headers @{"x-api-key" = $LICENSE_KEY} -Body '{"first_name":"Test"}' -ExpectedStatus @(400)

# Test 10: Non-Existent Route
Test-Endpoint -TestName "10. Testing Non-Existent Route" -Url "$BASE_URL/api/nonexistent" -Headers @{"x-api-key" = $LICENSE_KEY} -ExpectedStatus @(404)

# Summary
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Tests Passed: $global:TestsPassed" -ForegroundColor Green
Write-Host "Tests Failed: $global:TestsFailed" -ForegroundColor Red
Write-Host ""

if ($global:TestsFailed -eq 0) {
    Write-Host "All tests passed!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "Some tests failed. Please review the output above." -ForegroundColor Red
    exit 1
}
