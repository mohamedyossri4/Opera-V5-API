/**
 * License Validation Middleware
 * Validates API license keys and enforces access control
 */

const db = require('../db/oracleClient');

/**
 * Middleware to validate license key
 * License key should be provided in the 'x-api-key' header
 */
async function validateLicense(req, res, next) {
    // Skip license check for health endpoint
    if (req.path === '/health') {
        return next();
    }

    const licenseKey = req.get('x-api-key');

    if (!licenseKey) {
        return res.status(401).json({
            error: 'Unauthorized',
            message: 'API key is required. Please provide x-api-key header.',
        });
    }

    try {
        // Query to validate license
        const sql = `
            SELECT 
                LICENSE_ID,
                LICENSE_KEY,
                LICENSE_NAME,
                IS_ACTIVE,
                EXPIRY_DATE,
                MAX_REQUESTS_PER_DAY,
                ALLOWED_IPS
            FROM API_LICENSE
            WHERE LICENSE_KEY = :license_key
        `;

        const result = await db.execute(sql, { license_key: licenseKey });

        // Check if license exists
        if (result.rows.length === 0) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'Invalid API key.',
            });
        }

        const license = result.rows[0];

        // Check if license is active
        if (license.IS_ACTIVE !== 1) {
            return res.status(403).json({
                error: 'Forbidden',
                message: 'API key is inactive. Please contact administrator.',
            });
        }

        // Check if license has expired
        if (license.EXPIRY_DATE && new Date(license.EXPIRY_DATE) < new Date()) {
            return res.status(403).json({
                error: 'Forbidden',
                message: 'API key has expired. Please renew your license.',
            });
        }

        // Check IP restrictions if specified
        if (license.ALLOWED_IPS) {
            const allowedIps = JSON.parse(license.ALLOWED_IPS);
            const clientIp = req.ip || req.connection.remoteAddress;

            if (allowedIps.length > 0 && !allowedIps.includes(clientIp)) {
                return res.status(403).json({
                    error: 'Forbidden',
                    message: 'API key is not authorized from this IP address.',
                });
            }
        }

        // Check daily request limit
        if (license.MAX_REQUESTS_PER_DAY) {
            const checkLimitSql = `
                SELECT COUNT(*) as REQUEST_COUNT
                FROM API_REQUEST_LOG
                WHERE LICENSE_KEY = :license_key
                AND TRUNC(REQUEST_TIMESTAMP) = TRUNC(SYSDATE)
            `;

            const limitResult = await db.execute(checkLimitSql, { license_key: licenseKey });
            const requestCount = limitResult.rows[0].REQUEST_COUNT;

            if (requestCount >= license.MAX_REQUESTS_PER_DAY) {
                return res.status(429).json({
                    error: 'Too Many Requests',
                    message: `Daily request limit of ${license.MAX_REQUESTS_PER_DAY} has been reached.`,
                });
            }
        }

        // Attach license info to request object for later use
        req.license = license;

        // Update last used date (async, don't wait)
        const updateSql = `
            UPDATE API_LICENSE
            SET LAST_USED_DATE = CURRENT_TIMESTAMP,
                TOTAL_REQUESTS = TOTAL_REQUESTS + 1
            WHERE LICENSE_KEY = :license_key
        `;
        db.execute(updateSql, { license_key: licenseKey }, { autoCommit: true }).catch(err => {
            console.error('Error updating license usage:', err.message);
        });

        next();
    } catch (err) {
        console.error('License validation error:', err.message);
        return res.status(500).json({
            error: 'Internal Server Error',
            message: 'Error validating API key.',
        });
    }
}

module.exports = validateLicense;
