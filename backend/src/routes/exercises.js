const express = require('express');
const router = express.Router();
const validateExercise = require('../middleware/validateExercise');
const { getAllExercises, getExerciseById, createExercise, deleteExercise } = require('../controllers/exercisesController');

// Routes
router.get('/', getAllExercises);
router.get('/:id', getExerciseById)
router.post('/', validateExercise, createExercise);
router.delete('/:id', deleteExercise);

module.exports = router;
