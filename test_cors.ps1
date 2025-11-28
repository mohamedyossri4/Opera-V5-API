# CORS Testing Script
# Verifies that CORS headers are correctly returned for allowed origins

$BASE_URL = "http://localhost:3000"
$ALLOWED_ORIGIN = "http://10.0.10.31"
$DISALLOWED_ORIGIN = "http://example.com"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "CORS Configuration Test Suite" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$global:TestsPassed = 0
$global:TestsFailed = 0

function Test-Cors {
    param(
        [string]$TestName,
        [string]$Origin,
        [bool]$ShouldAllow
    )
    
    Write-Host "$TestName" -ForegroundColor Yellow
    Write-Host "Origin: $Origin"
    
    try {
        $params = @{
            Uri = "$BASE_URL/health"
            Method = "OPTIONS"
            Headers = @{
                "Origin" = $Origin
                "Access-Control-Request-Method" = "GET"
            }
        }
        
        $response = Invoke-WebRequest @params -ErrorAction SilentlyContinue
        
        # Check Access-Control-Allow-Origin header
        $allowOrigin = $response.Headers["Access-Control-Allow-Origin"]
        
        if ($ShouldAllow) {
            if ($allowOrigin -eq "*") {
                Write-Host "PASS: Allowed (Wildcard)" -ForegroundColor Green
                $global:TestsPassed++
            }
            elseif ($allowOrigin -eq $Origin) {
                Write-Host "PASS: Allowed ($allowOrigin)" -ForegroundColor Green
                $global:TestsPassed++
            }
            else {
                Write-Host "FAIL: Expected allow, got '$allowOrigin'" -ForegroundColor Red
                $global:TestsFailed++
            }
        }
        else {
            if ($allowOrigin) {
                Write-Host "FAIL: Expected block, got allowed ($allowOrigin)" -ForegroundColor Red
                $global:TestsFailed++
            }
            else {
                Write-Host "PASS: Blocked (No header returned)" -ForegroundColor Green
                $global:TestsPassed++
            }
        }
    }
    catch {
        if (-not $ShouldAllow) {
            Write-Host "PASS: Blocked (Request failed as expected)" -ForegroundColor Green
            $global:TestsPassed++
        } else {
            Write-Host "Error: $_" -ForegroundColor Red
            $global:TestsFailed++
        }
    }
    Write-Host ""
}

# Test 1: Allowed Origin (10.0.10.31)
Test-Cors -TestName "1. Testing Allowed Origin (10.0.10.31)" -Origin $ALLOWED_ORIGIN -ShouldAllow $true

# Test 2: Allowed Origin (Localhost)
Test-Cors -TestName "2. Testing Allowed Origin (Localhost)" -Origin "http://localhost:3000" -ShouldAllow $true

# Test 3: Disallowed Origin
Test-Cors -TestName "3. Testing Disallowed Origin" -Origin $DISALLOWED_ORIGIN -ShouldAllow $false

# Summary
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "Tests Passed: $global:TestsPassed" -ForegroundColor Green
Write-Host "Tests Failed: $global:TestsFailed" -ForegroundColor Red

if ($global:TestsFailed -eq 0) {
    exit 0
} else {
    exit 1
}
