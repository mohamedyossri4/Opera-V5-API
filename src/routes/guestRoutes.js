/**
 * Guest Routes
 * Defines API endpoints for guest operations
 */

const express = require('express');
const router = express.Router();
const guestController = require('../controllers/guestController');

/**
 * GET /api/guests/:nameId
 * Retrieve guest information by NAME_ID
 */
router.get('/:nameId', guestController.getGuest);

/**
 * PUT /api/guests/:confirmationNo
 * Update guest information by confirmation number
 */
router.put('/:confirmationNo', guestController.updateGuest);

module.exports = router;
