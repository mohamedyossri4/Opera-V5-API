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
            SELECT
                nam.first
                || ' '
                || nam.last AS guestname,
                nam.name_id
            FROM
                reservation_name res,
                name             nam
            WHERE
                    res.name_id = nam.name_id
                AND res.confirmation_no = :name_id
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
 * Update guest information by confirmation number
 * @param {object} req - Express request object
 * @param {object} res - Express response object
 */
async function updateGuest(req, res) {
    const { confirmationNo } = req.params;
    const { first_name, last_name, address, doc_type, doc_number } = req.body;

    // Validate confirmationNo is numeric
    if (!confirmationNo || isNaN(confirmationNo)) {
        return res.status(400).json({
            error: 'Bad Request',
            message: 'confirmationNo must be a valid numeric value',
        });
    }

    // Check if at least one field is provided for update
    if (!first_name && !last_name && !address && !doc_type && !doc_number) {
        return res.status(400).json({
            error: 'Bad Request',
            message: 'At least one field must be provided for update (first_name, last_name, address, doc_type, doc_number)',
        });
    }

    let connection;
    try {
        // Get a connection for transaction handling
        connection = await db.getConnection();

        // First, get the NAME_ID from the confirmation number
        const getNameIdSql = `
            SELECT NAME_ID
            FROM RESERVATION_NAME
            WHERE CONFIRMATION_NO = :confirmation_no
            AND ROWNUM = 1
        `;

        const nameIdResult = await connection.execute(
            getNameIdSql,
            { confirmation_no: parseInt(confirmationNo) },
            { autoCommit: false }
        );

        // Check if the confirmation number exists
        if (nameIdResult.rows.length === 0) {
            await connection.rollback();
            return res.status(404).json({
                error: 'Not Found',
                message: `Guest with confirmation number ${confirmationNo} not found`,
            });
        }

        const nameId = nameIdResult.rows[0].NAME_ID;
        const updatedFields = [];

        // Update NAME table fields (first_name, last_name, doc_type, doc_number)
        const nameUpdateFields = [];
        const nameBindParams = { name_id: nameId };

        if (first_name !== undefined && first_name !== null) {
            nameUpdateFields.push('FIRST = :first_name');
            nameBindParams.first_name = first_name.toString().trim();
            updatedFields.push('first_name');
        }

        if (last_name !== undefined && last_name !== null) {
            nameUpdateFields.push('LAST = :last_name');
            nameBindParams.last_name = last_name.toString().trim();
            updatedFields.push('last_name');
        }

        if (doc_type !== undefined && doc_type !== null) {
            nameUpdateFields.push('ID_TYPE = :doc_type');
            nameBindParams.doc_type = doc_type.toString().trim();
            updatedFields.push('doc_type');
        }

        if (doc_number !== undefined && doc_number !== null) {
            nameUpdateFields.push('ID_NUMBER = :doc_number');
            nameBindParams.doc_number = doc_number.toString().trim();
            updatedFields.push('doc_number');
        }

        // Execute NAME table update if there are fields to update
        if (nameUpdateFields.length > 0) {
            const nameSql = `
                UPDATE NAME
                SET ${nameUpdateFields.join(', ')}
                WHERE NAME_ID = :name_id
            `;

            await connection.execute(nameSql, nameBindParams, { autoCommit: false });
        }

        // Handle address update in NAME_ADDRESS_E table
        if (address !== undefined && address !== null) {
            // Check if a record exists in NAME_ADDRESS_E for this NAME_ID
            const checkAddressSql = `
                SELECT COUNT(*) as CNT
                FROM NAME_ADDRESS_E
                WHERE NAME_ID = :name_id
            `;

            const addressCheckResult = await connection.execute(
                checkAddressSql,
                { name_id: nameId },
                { autoCommit: false }
            );

            const addressExists = addressCheckResult.rows[0].CNT > 0;

            if (addressExists) {
                // Update existing address record
                const updateAddressSql = `
                    UPDATE NAME_ADDRESS_E
                    SET ADDRESS1 = :address
                    WHERE NAME_ID = :name_id
                    AND ROWNUM = 1
                `;

                await connection.execute(
                    updateAddressSql,
                    { name_id: nameId, address: address.toString().trim() },
                    { autoCommit: false }
                );

                updatedFields.push('address');
            } else {
                // No address record exists, skip updating
                console.log(`No address record found in NAME_ADDRESS_E for NAME_ID ${nameId}`);
            }
        }

        // Commit the transaction
        await connection.commit();

        // Return success response
        res.status(200).json({
            confirmationNo: parseInt(confirmationNo),
            nameId: nameId,
            updatedFields: updatedFields,
            message: 'Guest information updated successfully',
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
