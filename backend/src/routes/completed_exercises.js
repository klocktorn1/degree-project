const express = require('express');
const router = express.Router();
const { getAllCompletedExercises, getCompletedExercise, createCompletedExercises, deleteCompletedExercise } = require('../controllers/completedExercisesController');
const validateCompletedExercises = require('../middleware/validateCompletedExercises');


router.get('/', getAllCompletedExercises);
router.get('/get-completed', getCompletedExercise);
router.post('/', validateCompletedExercises, createCompletedExercises);
router.delete('/:id', deleteCompletedExercise);
module.exports = router;
