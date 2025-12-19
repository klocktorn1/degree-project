const express = require('express');
const router = express.Router();
const { getAllSubExercises, getSubExercisesByExerciseId, getSubExerciseById} = require('../controllers/subExercisesController');

// Routes
router.get('/', getAllSubExercises);
router.get('/exercise-id/:id', getSubExercisesByExerciseId);
router.get('/:id', getSubExerciseById)

module.exports = router;
