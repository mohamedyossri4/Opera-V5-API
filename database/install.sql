-- ============================================================================
-- Opera V5 API - Database Installation Script
-- ============================================================================
-- This script creates the necessary tables for API audit logging and license management
-- Run this script as the OPERA user or a user with appropriate privileges
-- ============================================================================

-- ============================================================================
-- 1. API Request Audit Log Table
-- ============================================================================
-- This table stores all API requests and responses for audit purposes

CREATE TABLE API_REQUEST_LOG (
    LOG_ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    REQUEST_TIMESTAMP TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    REQUEST_METHOD VARCHAR2(10) NOT NULL,
    REQUEST_PATH VARCHAR2(500) NOT NULL,
    REQUEST_HEADERS CLOB,
    REQUEST_BODY CLOB,
    RESPONSE_STATUS NUMBER,
    RESPONSE_BODY CLOB,
    RESPONSE_TIMESTAMP TIMESTAMP,
    DURATION_MS NUMBER,
    CLIENT_IP VARCHAR2(50),
    USER_AGENT VARCHAR2(500),
    LICENSE_KEY VARCHAR2(100),
    CONFIRMATION_NO NUMBER,
    ERROR_MESSAGE VARCHAR2(4000)
);

-- Create indexes for better query performance
CREATE INDEX IDX_REQUEST_LOG_TIMESTAMP ON API_REQUEST_LOG(REQUEST_TIMESTAMP);
CREATE INDEX IDX_REQUEST_LOG_PATH ON API_REQUEST_LOG(REQUEST_PATH);
CREATE INDEX IDX_REQUEST_LOG_LICENSE ON API_REQUEST_LOG(LICENSE_KEY);
CREATE INDEX IDX_REQUEST_LOG_CONFIRM ON API_REQUEST_LOG(CONFIRMATION_NO);

COMMENT ON TABLE API_REQUEST_LOG IS 'Audit log for all API requests and responses';
COMMENT ON COLUMN API_REQUEST_LOG.LOG_ID IS 'Unique identifier for each log entry';
COMMENT ON COLUMN API_REQUEST_LOG.REQUEST_TIMESTAMP IS 'When the request was received';
COMMENT ON COLUMN API_REQUEST_LOG.REQUEST_METHOD IS 'HTTP method (GET, PUT, POST, DELETE)';
COMMENT ON COLUMN API_REQUEST_LOG.REQUEST_PATH IS 'API endpoint path';
COMMENT ON COLUMN API_REQUEST_LOG.REQUEST_HEADERS IS 'JSON string of request headers';
COMMENT ON COLUMN API_REQUEST_LOG.REQUEST_BODY IS 'JSON string of request body';
COMMENT ON COLUMN API_REQUEST_LOG.RESPONSE_STATUS IS 'HTTP response status code';
COMMENT ON COLUMN API_REQUEST_LOG.RESPONSE_BODY IS 'JSON string of response body';
COMMENT ON COLUMN API_REQUEST_LOG.RESPONSE_TIMESTAMP IS 'When the response was sent';
COMMENT ON COLUMN API_REQUEST_LOG.DURATION_MS IS 'Request processing time in milliseconds';
COMMENT ON COLUMN API_REQUEST_LOG.CLIENT_IP IS 'Client IP address';
COMMENT ON COLUMN API_REQUEST_LOG.USER_AGENT IS 'Client user agent string';
COMMENT ON COLUMN API_REQUEST_LOG.LICENSE_KEY IS 'License key used for the request';
COMMENT ON COLUMN API_REQUEST_LOG.CONFIRMATION_NO IS 'Confirmation number from request if applicable';
COMMENT ON COLUMN API_REQUEST_LOG.ERROR_MESSAGE IS 'Error message if request failed';

-- ============================================================================
-- 2. API License Management Table
-- ============================================================================
-- This table manages API access licenses

CREATE TABLE API_LICENSE (
    LICENSE_ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    LICENSE_KEY VARCHAR2(100) UNIQUE NOT NULL,
    LICENSE_NAME VARCHAR2(200) NOT NULL,
    DESCRIPTION VARCHAR2(500),
    IS_ACTIVE NUMBER(1) DEFAULT 1 NOT NULL,
    CREATED_DATE TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    EXPIRY_DATE TIMESTAMP,
    MAX_REQUESTS_PER_DAY NUMBER,
    ALLOWED_IPS CLOB,
    CONTACT_EMAIL VARCHAR2(200),
    CONTACT_PHONE VARCHAR2(50),
    LAST_USED_DATE TIMESTAMP,
    TOTAL_REQUESTS NUMBER DEFAULT 0,
    NOTES VARCHAR2(1000)
);

-- Create indexes
CREATE INDEX IDX_LICENSE_ACTIVE ON API_LICENSE(IS_ACTIVE);
CREATE INDEX IDX_LICENSE_EXPIRY ON API_LICENSE(EXPIRY_DATE);

COMMENT ON TABLE API_LICENSE IS 'License keys for API access control';
COMMENT ON COLUMN API_LICENSE.LICENSE_ID IS 'Unique identifier for each license';
COMMENT ON COLUMN API_LICENSE.LICENSE_KEY IS 'Unique license key (UUID format)';
COMMENT ON COLUMN API_LICENSE.LICENSE_NAME IS 'Descriptive name for the license holder';
COMMENT ON COLUMN API_LICENSE.DESCRIPTION IS 'Purpose or description of this license';
COMMENT ON COLUMN API_LICENSE.IS_ACTIVE IS '1 = Active, 0 = Inactive';
COMMENT ON COLUMN API_LICENSE.CREATED_DATE IS 'When the license was created';
COMMENT ON COLUMN API_LICENSE.EXPIRY_DATE IS 'When the license expires (NULL = never expires)';
COMMENT ON COLUMN API_LICENSE.MAX_REQUESTS_PER_DAY IS 'Maximum requests allowed per day (NULL = unlimited)';
COMMENT ON COLUMN API_LICENSE.ALLOWED_IPS IS 'JSON array of allowed IP addresses (NULL = any IP)';
COMMENT ON COLUMN API_LICENSE.CONTACT_EMAIL IS 'Contact email for license holder';
COMMENT ON COLUMN API_LICENSE.CONTACT_PHONE IS 'Contact phone for license holder';
COMMENT ON COLUMN API_LICENSE.LAST_USED_DATE IS 'Last time this license was used';
COMMENT ON COLUMN API_LICENSE.TOTAL_REQUESTS IS 'Total number of requests made with this license';
COMMENT ON COLUMN API_LICENSE.NOTES IS 'Additional notes about this license';

-- ============================================================================
-- 3. Insert Sample License Key
-- ============================================================================
-- Create a default license key for testing

INSERT INTO API_LICENSE (
    LICENSE_KEY,
    LICENSE_NAME,
    DESCRIPTION,
    IS_ACTIVE,
    CONTACT_EMAIL
) VALUES (
    'demo-license-key-12345678',
    'Demo License',
    'Default license for testing and development',
    1,
    'admin@example.com'
);

COMMIT;

-- ============================================================================
-- 4. View for License Usage Statistics
-- ============================================================================

CREATE OR REPLACE VIEW V_LICENSE_USAGE_STATS AS
SELECT 
    l.LICENSE_KEY,
    l.LICENSE_NAME,
    l.IS_ACTIVE,
    l.EXPIRY_DATE,
    l.MAX_REQUESTS_PER_DAY,
    l.TOTAL_REQUESTS,
    l.LAST_USED_DATE,
    COUNT(r.LOG_ID) AS REQUESTS_TODAY,
    CASE 
        WHEN l.MAX_REQUESTS_PER_DAY IS NOT NULL 
        THEN l.MAX_REQUESTS_PER_DAY - COUNT(r.LOG_ID)
        ELSE 999999
    END AS REMAINING_REQUESTS_TODAY
FROM API_LICENSE l
LEFT JOIN API_REQUEST_LOG r 
    ON l.LICENSE_KEY = r.LICENSE_KEY 
    AND TRUNC(r.REQUEST_TIMESTAMP) = TRUNC(SYSDATE)
GROUP BY 
    l.LICENSE_KEY,
    l.LICENSE_NAME,
    l.IS_ACTIVE,
    l.EXPIRY_DATE,
    l.MAX_REQUESTS_PER_DAY,
    l.TOTAL_REQUESTS,
    l.LAST_USED_DATE;

COMMENT ON TABLE V_LICENSE_USAGE_STATS IS 'Real-time view of license usage statistics';

-- ============================================================================
-- Installation Complete
-- ============================================================================

SELECT 'Installation completed successfully!' AS STATUS FROM DUAL;
SELECT 'Total licenses created: ' || COUNT(*) AS INFO FROM API_LICENSE;
