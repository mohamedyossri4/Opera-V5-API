# Database Setup Guide

## Installation

This guide explains how to set up the audit logging and license management tables in your Oracle database.

### Prerequisites

- Access to Oracle SQL*Plus, SQL Developer, or similar tool
- Database user with CREATE TABLE privileges
- Connected to the Opera database

### Step 1: Run the Installation Script

1. Open SQL*Plus or your preferred Oracle SQL tool
2. Connect to your Opera database as the `opera` user (or appropriate user)
3. Navigate to the `database` directory
4. Run the installation script:

```sql
@install.sql
```

Or copy and paste the contents of `install.sql` into your SQL tool.

### Step 2: Verify Installation

Check that the tables were created successfully:

```sql
-- Check tables
SELECT table_name FROM user_tables WHERE table_name LIKE 'API_%';

-- Verify sample license was inserted
SELECT LICENSE_KEY, LICENSE_NAME, IS_ACTIVE FROM API_LICENSE;
```

You should see:
- `API_REQUEST_LOG`
- `API_LICENSE`
- One sample license record with key: `demo-license-key-12345678`

## Tables Created

### API_REQUEST_LOG
Stores all API requests and responses for audit purposes.

**Key Columns:**
- `LOG_ID` - Unique identifier (auto-generated)
- `REQUEST_METHOD` - HTTP method (GET, PUT, etc.)
- `REQUEST_PATH` - API endpoint path
- `REQUEST_HEADERS` - JSON of request headers
- `REQUEST_BODY` - JSON of request body
- `RESPONSE_STATUS` - HTTP status code
- `RESPONSE_BODY` - JSON of response
- `DURATION_MS` - Processing time
- `LICENSE_KEY` - API key used
- `CONFIRMATION_NO` - Guest confirmation number if applicable

### API_LICENSE
Manages API access licenses.

**Key Columns:**
- `LICENSE_ID` - Unique identifier (auto-generated)
- `LICENSE_KEY` - Unique API key
- `LICENSE_NAME` - Descriptive name
- `IS_ACTIVE` - 1=Active, 0=Inactive
- `EXPIRY_DATE` - License expiration (NULL = never expires)
- `MAX_REQUESTS_PER_DAY` - Daily request limit (NULL = unlimited)
- `ALLOWED_IPS` - JSON array of allowed IPs (NULL = any IP)
- `TOTAL_REQUESTS` - Cumulative request count

## Managing Licenses

### Create a New License

```sql
INSERT INTO API_LICENSE (
    LICENSE_KEY,
    LICENSE_NAME,
    DESCRIPTION,
    IS_ACTIVE,
    EXPIRY_DATE,
    MAX_REQUESTS_PER_DAY,
    CONTACT_EMAIL
) VALUES (
    'your-unique-license-key-here',  -- Use UUID or strong random string
    'Production API License',
    'License for production application',
    1,                                -- 1 = Active
    TO_DATE('2026-12-31', 'YYYY-MM-DD'),  -- Expires Dec 31, 2026
    10000,                            -- Max 10,000 requests per day
    'contact@example.com'
);
COMMIT;
```

### Deactivate a License

```sql
UPDATE API_LICENSE
SET IS_ACTIVE = 0
WHERE LICENSE_KEY = 'your-license-key-here';
COMMIT;
```

### View License Usage Statistics

```sql
SELECT * FROM V_LICENSE_USAGE_STATS;
```

### View Recent API Requests for a License

```sql
SELECT 
    REQUEST_TIMESTAMP,
    REQUEST_METHOD,
    REQUEST_PATH,
    RESPONSE_STATUS,
    DURATION_MS
FROM API_REQUEST_LOG
WHERE LICENSE_KEY = 'your-license-key-here'
ORDER BY REQUEST_TIMESTAMP DESC
FETCH FIRST 20 ROWS ONLY;
```

## API Usage

### Using the API Key

All API requests (except `/health`) require an API key in the header:

```bash
curl -H "x-api-key: demo-license-key-12345678" \
     http://localhost:3000/api/guests/23990
```

### Error Responses

**401 Unauthorized** - Missing or invalid API key
```json
{
  "error": "Unauthorized",
  "message": "Invalid API key."
}
```

**403 Forbidden** - Inactive or expired license
```json
{
  "error": "Forbidden",
  "message": "API key has expired. Please renew your license."
}
```

**429 Too Many Requests** - Daily limit reached
```json
{
  "error": "Too Many Requests",
  "message": "Daily request limit of 1000 has been reached."
}
```

## Monitoring

### Check API Request Logs

```sql
-- Today's requests
SELECT 
    COUNT(*) as TOTAL_REQUESTS,
    SUM(CASE WHEN RESPONSE_STATUS >= 200 AND RESPONSE_STATUS < 300 THEN 1 ELSE 0 END) as SUCCESSFUL,
    SUM(CASE WHEN RESPONSE_STATUS >= 400 THEN 1 ELSE 0 END) as ERRORS,
    AVG(DURATION_MS) as AVG_DURATION_MS
FROM API_REQUEST_LOG
WHERE TRUNC(REQUEST_TIMESTAMP) = TRUNC(SYSDATE);
```

### Top Error Endpoints

```sql
SELECT 
    REQUEST_PATH,
    RESPONSE_STATUS,
    COUNT(*) as ERROR_COUNT
FROM API_REQUEST_LOG
WHERE RESPONSE_STATUS >= 400
  AND TRUNC(REQUEST_TIMESTAMP) = TRUNC(SYSDATE)
GROUP BY REQUEST_PATH, RESPONSE_STATUS
ORDER BY ERROR_COUNT DESC;
```

## Cleanup (Optional)

To remove old logs (keep last 90 days):

```sql
DELETE FROM API_REQUEST_LOG
WHERE REQUEST_TIMESTAMP < SYSDATE - 90;
COMMIT;
```
