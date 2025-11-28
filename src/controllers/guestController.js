/**
 * Guest Controller
 * Handles business logic for guest-related operations
 */

const db = require('../db/oracleClient');

/**
 * Get guest information by NAME_ID
 * @param {object} req - Express request object
 * @param {object} res - Express response object
 */
async function getGuest(req, res) {
    const { nameId } = req.params;

    // Validate nameId is numeric
    if (!nameId || isNaN(nameId)) {
        return res.status(400).json({
            error: 'Bad Request',
            message: 'nameId must be a valid numeric value',
        });
    }

    try {
        // SQL query to retrieve guest name by NAME_ID
        const sql = `
      SELECT GUESTNAME
      FROM NAMES
      WHERE NAME_ID = :name_id
    `;

        const result = await db.execute(sql, { name_id: parseInt(nameId) });

        // Check if guest was found
        if (result.rows.length === 0) {
            return res.status(404).json({
                error: 'Not Found',
                message: `Guest with nameId ${nameId} not found`,
            });
        }

        // Return guest information
        res.status(200).json({
            nameId: parseInt(nameId),
            guestName: result.rows[0].GUESTNAME,
        });
    } catch (err) {
        console.error('Database error in getGuest:', err.message);
        res.status(500).json({
            error: 'Internal Server Error',
            message: 'An error occurred while retrieving guest information',
        });
    }
}

/**
 * Update guest name by NAME_ID
 * @param {object} req - Express request object
 * @param {object} res - Express response object
 */
async function updateGuest(req, res) {
    const { nameId } = req.params;
    const { guestName } = req.body;

    // Validate nameId is numeric
    if (!nameId || isNaN(nameId)) {
        return res.status(400).json({
            error: 'Bad Request',
            message: 'nameId must be a valid numeric value',
        });
    }

    // Validate guestName is a non-empty string
    if (!guestName || typeof guestName !== 'string' || guestName.trim() === '') {
        return res.status(400).json({
            error: 'Bad Request',
            message: 'guestName must be a non-empty string',
        });
    }

    let connection;
    try {
        // Get a connection for transaction handling
        connection = await db.getConnection();

        // SQL query to update guest name
        const sql = `
      UPDATE NAMES
      SET GUESTNAME = :api_guestname
      WHERE NAME_ID = :api_name_id
    `;

        const result = await connection.execute(
            sql,
            {
                api_guestname: guestName.trim(),
                api_name_id: parseInt(nameId),
            },
            { autoCommit: false } // Don't auto-commit, we'll commit manually
        );

        // Check if any rows were updated
        if (result.rowsAffected === 0) {
            await connection.rollback();
            return res.status(404).json({
                error: 'Not Found',
                message: `Guest with nameId ${nameId} not found`,
            });
        }

        // Commit the transaction
        await connection.commit();

        // Return success response
        res.status(200).json({
            nameId: parseInt(nameId),
            guestName: guestName.trim(),
            message: 'Guest name updated successfully',
        });
    } catch (err) {
        // Rollback on error
        if (connection) {
            try {
                await connection.rollback();
            } catch (rollbackErr) {
                console.error('Error rolling back transaction:', rollbackErr.message);
            }
        }

        console.error('Database error in updateGuest:', err.message);
        res.status(500).json({
            error: 'Internal Server Error',
            message: 'An error occurred while updating guest information',
        });
    } finally {
        // Close the connection
        if (connection) {
            try {
                await connection.close();
            } catch (closeErr) {
                console.error('Error closing connection:', closeErr.message);
            }
        }
    }
}

module.exports = {
    getGuest,
    updateGuest,
};
