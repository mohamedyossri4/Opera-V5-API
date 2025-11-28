# Quick Fix Guide - API Key Validation Error

## Problem
API returns: `{"error":"Internal Server Error","message":"Error validating API key."}`

## Root Cause
Database tables `API_LICENSE` and `API_REQUEST_LOG` do not exist.

## Solution (3 Steps)

### 1. Run Database Installation Script

Connect to your Oracle Opera database and run:

```sql
@d:\Yousri\OPERA_V5_API\database\install.sql
```

This creates:
- `API_LICENSE` table (for API keys)
- `API_REQUEST_LOG` table (for audit logging)
- Demo license key: `demo-license-key-12345678`

### 2. Restart Docker Container

```powershell
cd d:\Yousri\OPERA_V5_API
docker-compose restart backend
```

### 3. Test the API

```powershell
# Test with valid license key
Invoke-RestMethod -Uri "http://localhost:3000/api/guests/12345" `
    -Headers @{"x-api-key"="demo-license-key-12345678"}
```

## Verify Installation

Check tables exist:
```sql
SELECT table_name FROM user_tables WHERE table_name LIKE 'API_%';
```

Check license key:
```sql
SELECT license_key, license_name, is_active FROM API_LICENSE;
```

## Full Test Suite

Run comprehensive tests:
```powershell
.\test_api.ps1
```

---

**See [walkthrough.md](file:///C:/Users/Yousri/.gemini/antigravity/brain/5b459aed-4a76-4cd7-bf3c-3a00727298ce/walkthrough.md) for detailed troubleshooting guide.**
