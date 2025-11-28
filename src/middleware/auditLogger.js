/**
 * Audit Logging Middleware
 * Logs all API requests and responses to the database
 */

const db = require('../db/oracleClient');

/**
 * Middleware to log API requests and responses
 */
function auditLogger(req, res, next) {
    const startTime = Date.now();

    // Capture request data
    const requestData = {
        method: req.method,
        path: req.path,
        headers: JSON.stringify(req.headers),
        body: req.body ? JSON.stringify(req.body) : null,
        clientIp: req.ip || req.connection.remoteAddress,
        userAgent: req.get('user-agent'),
        licenseKey: req.get('x-api-key'),
        confirmationNo: req.params.confirmationNo || req.params.nameId || null,
        timestamp: new Date(),
    };

    // Store original methods
    const originalSend = res.send;
    const originalJson = res.json;

    let responseBody = null;

    // Override res.json to capture response
    res.json = function (data) {
        responseBody = data;
        return originalJson.call(this, data);
    };

    // Override res.send to capture response
    res.send = function (data) {
        if (!responseBody) {
            responseBody = data;
        }
        return originalSend.call(this, data);
    };

    // Log after response is sent
    res.on('finish', async () => {
        const duration = Date.now() - startTime;

        try {
            const sql = `
                INSERT INTO API_REQUEST_LOG (
                    REQUEST_METHOD,
                    REQUEST_PATH,
                    REQUEST_HEADERS,
                    REQUEST_BODY,
                    RESPONSE_STATUS,
                    RESPONSE_BODY,
                    RESPONSE_TIMESTAMP,
                    DURATION_MS,
                    CLIENT_IP,
                    USER_AGENT,
                    LICENSE_KEY,
                    CONFIRMATION_NO,
                    ERROR_MESSAGE
                ) VALUES (
                    :method,
                    :path,
                    :headers,
                    :body,
                    :status,
                    :response_body,
                    CURRENT_TIMESTAMP,
                    :duration,
                    :client_ip,
                    :user_agent,
                    :license_key,
                    :confirmation_no,
                    :error_message
                )
            `;

            const params = {
                method: requestData.method,
                path: requestData.path,
                headers: requestData.headers,
                body: requestData.body,
                status: res.statusCode,
                response_body: responseBody ? JSON.stringify(responseBody) : null,
                duration: duration,
                client_ip: requestData.clientIp,
                user_agent: requestData.userAgent,
                license_key: requestData.licenseKey,
                confirmation_no: requestData.confirmationNo ? parseInt(requestData.confirmationNo) : null,
                error_message: res.statusCode >= 400 && responseBody?.message ? responseBody.message : null,
            };

            // Execute insert asynchronously (don't block the response)
            await db.execute(sql, params, { autoCommit: true });
        } catch (err) {
            console.error('Error logging request to database:', err.message);
            // Don't propagate error - logging failure shouldn't affect API response
        }
    });

    next();
}

module.exports = auditLogger;
