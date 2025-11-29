/**
 * Oracle Database Connection Pool Manager
 * Handles connection pooling for Oracle Opera Hospitality v5 database
 */

const oracledb = require('oracledb');

// Enable auto-commit for single operations (can be overridden per query)
oracledb.autoCommit = false;

// Configure Oracle client to return results as objects with column names
oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;

let pool = null;

/**
 * Initialize the Oracle connection pool
 * @returns {Promise<void>}
 */
async function initialize() {
  try {
    console.log('Initializing Oracle connection pool...');

    // Enable Thick mode for Oracle 11g support
    try {
      oracledb.initOracleClient({ libDir: process.env.LD_LIBRARY_PATH });
      console.log('Oracle Client initialized (Thick mode enabled)');
    } catch (err) {
      console.warn('Oracle Client initialization skipped (already initialized or not found):', err.message);
    }

    pool = await oracledb.createPool({
      user: process.env.ORACLE_USER,
      password: process.env.ORACLE_PASSWORD,
      connectString: `${process.env.ORACLE_HOST}:${process.env.ORACLE_PORT}/${process.env.ORACLE_SERVICE_NAME}`,
      poolMin: parseInt(process.env.ORACLE_POOL_MIN) || 2,
      poolMax: parseInt(process.env.ORACLE_POOL_MAX) || 10,
      poolIncrement: parseInt(process.env.ORACLE_POOL_INCREMENT) || 2,
      poolTimeout: 60, // Timeout for idle connections (seconds)
      queueTimeout: 60000, // Timeout for connection requests (milliseconds)
    });

    console.log('Oracle connection pool initialized successfully');
  } catch (err) {
    console.error('Failed to initialize Oracle connection pool:', err.message);
    throw err;
  }
}

/**
 * Get a connection from the pool
 * @returns {Promise<oracledb.Connection>}
 */
async function getConnection() {
  if (!pool) {
    throw new Error('Connection pool not initialized. Call initialize() first.');
  }
  return await pool.getConnection();
}

/**
 * Close the connection pool gracefully
 * @returns {Promise<void>}
 */
async function close() {
  if (pool) {
    try {
      console.log('Closing Oracle connection pool...');
      await pool.close(10); // Wait up to 10 seconds for connections to close
      pool = null;
      console.log('Oracle connection pool closed successfully');
    } catch (err) {
      console.error('Error closing Oracle connection pool:', err.message);
      throw err;
    }
  }
}

/**
 * Execute a query with bind parameters
 * @param {string} sql - SQL query string
 * @param {object|array} binds - Bind parameters
 * @param {object} options - Query options
 * @returns {Promise<object>} Query result
 */
async function execute(sql, binds = {}, options = {}) {
  let connection;
  try {
    connection = await getConnection();
    const result = await connection.execute(sql, binds, options);
    return result;
  } finally {
    if (connection) {
      try {
        await connection.close();
      } catch (err) {
        console.error('Error closing connection:', err.message);
      }
    }
  }
}

module.exports = {
  initialize,
  close,
  execute,
  getConnection,
};
