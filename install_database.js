const db = require('./src/db/oracleClient');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

async function installDatabase() {
    let connection;
    try {
        await db.initialize();
        console.log('Connected to database.');

        connection = await db.getConnection();

        // Read the SQL file
        const sqlFile = path.join(__dirname, 'database', 'install.sql');
        const sqlContent = fs.readFileSync(sqlFile, 'utf8');

        // Split by semicolons
        const rawStatements = sqlContent.split(';');

        const statements = rawStatements
            .map(s => {
                // Remove comment lines and trim
                return s.split('\n')
                    .filter(line => !line.trim().startsWith('--'))
                    .join('\n')
                    .trim();
            })
            .filter(s => s.length > 0 && !s.match(/^SELECT.*FROM DUAL/i));

        console.log(`\nExecuting ${statements.length} SQL statements...\n`);

        for (let i = 0; i < statements.length; i++) {
            const stmt = statements[i];

            // Skip comments and empty lines
            if (stmt.startsWith('--') || stmt.trim().length === 0) {
                continue;
            }

            // Handle CREATE TABLE
            if (stmt.toUpperCase().includes('CREATE TABLE')) {
                const tableName = stmt.match(/CREATE TABLE\s+(\w+)/i)?.[1];
                console.log(`Creating table: ${tableName}...`);
                try {
                    await connection.execute(stmt, {}, { autoCommit: false });
                    console.log(`✓ Table ${tableName} created successfully`);
                } catch (err) {
                    if (err.message.includes('ORA-00955')) {
                        console.log(`⚠ Table ${tableName} already exists, skipping`);
                    } else {
                        throw err;
                    }
                }
            }
            // Handle CREATE INDEX
            else if (stmt.toUpperCase().includes('CREATE INDEX')) {
                const indexName = stmt.match(/CREATE INDEX\s+(\w+)/i)?.[1];
                console.log(`Creating index: ${indexName}...`);
                try {
                    await connection.execute(stmt, {}, { autoCommit: false });
                    console.log(`✓ Index ${indexName} created successfully`);
                } catch (err) {
                    if (err.message.includes('ORA-00955') || err.message.includes('ORA-01408')) {
                        console.log(`⚠ Index ${indexName} already exists, skipping`);
                    } else {
                        throw err;
                    }
                }
            }
            // Handle COMMENT
            else if (stmt.toUpperCase().includes('COMMENT ON')) {
                // Skip comments silently
                await connection.execute(stmt, {}, { autoCommit: false });
            }
            // Handle INSERT
            else if (stmt.toUpperCase().includes('INSERT INTO')) {
                console.log(`Inserting sample data...`);
                try {
                    await connection.execute(stmt, {}, { autoCommit: false });
                    console.log(`✓ Sample data inserted`);
                } catch (err) {
                    if (err.message.includes('ORA-00001')) {
                        console.log(`⚠ Sample data already exists, skipping`);
                    } else {
                        throw err;
                    }
                }
            }
            // Handle CREATE VIEW
            else if (stmt.toUpperCase().includes('CREATE OR REPLACE VIEW')) {
                const viewName = stmt.match(/CREATE OR REPLACE VIEW\s+(\w+)/i)?.[1];
                console.log(`Creating view: ${viewName}...`);
                await connection.execute(stmt, {}, { autoCommit: false });
                console.log(`✓ View ${viewName} created successfully`);
            }
            // Handle COMMIT
            else if (stmt.toUpperCase().trim() === 'COMMIT') {
                await connection.commit();
                console.log(`✓ Changes committed`);
            }
        }

        // Final commit
        await connection.commit();
        console.log('\n✓ Database installation completed successfully!\n');

        // Verify installation
        console.log('Verifying installation...');
        const licenseCheck = await connection.execute('SELECT COUNT(*) as CNT FROM API_LICENSE');
        console.log(`✓ API_LICENSE table exists with ${licenseCheck.rows[0].CNT} records`);

        const logCheck = await connection.execute('SELECT COUNT(*) as CNT FROM API_REQUEST_LOG');
        console.log(`✓ API_REQUEST_LOG table exists with ${logCheck.rows[0].CNT} records`);

        // Show license keys
        const licenses = await connection.execute('SELECT LICENSE_KEY, LICENSE_NAME, IS_ACTIVE FROM API_LICENSE');
        console.log('\nLicense keys created:');
        licenses.rows.forEach(row => {
            console.log(`  - ${row.LICENSE_KEY} (${row.LICENSE_NAME}) - Active: ${row.IS_ACTIVE === 1 ? 'Yes' : 'No'}`);
        });

    } catch (err) {
        console.error('\n✗ Installation failed:', err.message);
        if (connection) {
            await connection.rollback();
        }
        process.exit(1);
    } finally {
        if (connection) {
            await connection.close();
        }
        await db.close();
    }
}

installDatabase();
