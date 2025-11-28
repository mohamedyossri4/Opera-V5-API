const db = require('./src/db/oracleClient');
require('dotenv').config();

async function checkTables() {
    try {
        await db.initialize();
        console.log('Connected to database.');

        // Check API_LICENSE
        try {
            const licenseResult = await db.execute('SELECT COUNT(*) as CNT FROM API_LICENSE');
            console.log('API_LICENSE exists. Count:', licenseResult.rows[0].CNT);
        } catch (err) {
            console.error('Error accessing API_LICENSE:', err.message);
        }

        // Check for recent logs
        try {
            console.log('Checking for recent logs...');
            const recentLogs = await db.execute(
                `SELECT LOG_ID, REQUEST_PATH, RESPONSE_STATUS, REQUEST_TIMESTAMP 
                 FROM API_REQUEST_LOG 
                 ORDER BY LOG_ID DESC 
                 FETCH FIRST 5 ROWS ONLY`
            );
            console.log('Recent logs:', recentLogs.rows);
        } catch (err) {
            console.error('Error accessing API_REQUEST_LOG:', err.message);
        }

        // List all tables for current user
        try {
            const tablesResult = await db.execute("SELECT TABLE_NAME FROM USER_TABLES WHERE TABLE_NAME LIKE 'API_%'");
            console.log('Tables found in USER_TABLES:', tablesResult.rows);
        } catch (err) {
            console.error('Error listing tables:', err.message);
        }

    } catch (err) {
        console.error('Database connection failed:', err.message);
    } finally {
        await db.close();
    }
}

checkTables();
