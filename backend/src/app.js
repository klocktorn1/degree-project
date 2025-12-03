const express = require('express');
const app = express();




const usersRouter = require('./routes/users');
const exerciseRouter = require('./routes/exercises');
const exerciseResultsRouter = require('./routes/exercise_results');

app.use(express.json());

app.use('/users', usersRouter);
app.use('/exercises', exerciseRouter);
app.use('/exercise_results', exerciseResultsRouter);

module.exports = app;
