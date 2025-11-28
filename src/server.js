/**
 * Main Server File
 * Express.js server for Oracle Opera Hospitality v5 API
 */

require('dotenv').config();
const express = require('express');
const db = require('./db/oracleClient');
const guestRoutes = require('./routes/guestRoutes');
const licenseValidator = require('./middleware/licenseValidator');
const auditLogger = require('./middleware/auditLogger');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware to parse JSON request bodies
app.use(express.json());

// Audit logging middleware - logs all requests/responses
app.use(auditLogger);

// License validation middleware - validates API keys
app.use(licenseValidator);

// Request logging middleware
app.use((req, res, next) => {
    const start = Date.now();

    // Log request
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);

    // Log response when finished
    res.on('finish', () => {
        const duration = Date.now() - start;
        console.log(
            `[${new Date().toISOString()}] ${req.method} ${req.url} - ${res.statusCode} (${duration}ms)`
        );
    });

    next();
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'ok' });
});

// Guest API routes
app.use('/api/guests', guestRoutes);

// 404 handler for undefined routes
app.use((req, res) => {
    res.status(404).json({
        error: 'Not Found',
        message: `Route ${req.method} ${req.url} not found`,
    });
});

// Global error handler
app.use((err, req, res, next) => {
    console.error('Unhandled error:', err);
    res.status(500).json({
        error: 'Internal Server Error',
        message: 'An unexpected error occurred',
    });
});

// Initialize database and start server
async function startServer() {
    try {
        // Initialize Oracle connection pool
        await db.initialize();

        // Start Express server
        const server = app.listen(PORT, () => {
            console.log(`Server running on port ${PORT}`);
            console.log(`Health check: http://localhost:${PORT}/health`);
            console.log(`API endpoint: http://localhost:${PORT}/api/guests`);
        });

        // Graceful shutdown handler
        const shutdown = async (signal) => {
            console.log(`\n${signal} received. Starting graceful shutdown...`);

            // Stop accepting new connections
            server.close(async () => {
                console.log('HTTP server closed');

                // Close database connection pool
                await db.close();

                console.log('Graceful shutdown completed');
                process.exit(0);
            });

            // Force shutdown after 30 seconds
            setTimeout(() => {
                console.error('Could not close connections in time, forcefully shutting down');
                process.exit(1);
            }, 30000);
        };

        // Listen for termination signals
        process.on('SIGTERM', () => shutdown('SIGTERM'));
        process.on('SIGINT', () => shutdown('SIGINT'));

    } catch (err) {
        console.error('Failed to start server:', err.message);
        process.exit(1);
    }
}

// Start the server
startServer();
