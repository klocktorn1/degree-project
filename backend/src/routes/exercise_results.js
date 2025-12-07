const express = require('express');
const router = express.Router();
const { getAllExerciseResults, getExerciseResultsById, createExerciseResults, deleteExerciseResults } = require('../controllers/exerciseResultsController');
const validateExerciseResults = require('../middleware/validateExerciseResults');


router.get('/', getAllExerciseResults);
router.get('/:id', getExerciseResultsById);
router.post('/', validateExerciseResults, createExerciseResults);
router.delete('/:id', deleteExerciseResults);
module.exports = router;
