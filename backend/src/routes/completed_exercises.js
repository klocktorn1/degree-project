const express = require('express');
const router = express.Router();
const { getAllCompletedExercisesByUserId, getCompletedExercise, createCompletedExercises, deleteCompletedExercise } = require('../controllers/completedExercisesController');
const validateCompletedExercises = require('../middleware/validateCompletedExercises');


router.get('/', getAllCompletedExercisesByUserId);
router.get('/get-completed', getCompletedExercise);
router.post('/', createCompletedExercises);
router.delete('/:id', deleteCompletedExercise);
module.exports = router;
