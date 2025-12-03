const express = require('express');
const router = express.Router();
const { getAllExerciseResults, getExerciseResultsById, createExerciseResults } = require('../controllers/exerciseResultsController');
const validateExerciseResults = require('../middleware/validateExerciseResults');


router.get('/', getAllExerciseResults);
router.get('/:id', getExerciseResultsById);
router.post('/', validateExerciseResults, createExerciseResults);
module.exports = router;
