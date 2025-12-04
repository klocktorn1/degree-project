const express = require('express');
const app = express();
const cookieParser = require('cookie-parser')



const usersRouter = require('./routes/users');
const exerciseRouter = require('./routes/exercises');
const exerciseResultsRouter = require('./routes/exercise_results');
const authRouter = require('./routes/auth');
const requireAuth = require('./middleware/requireAuth')



app.use(cookieParser())
app.use(express.json());

app.use('/users', requireAuth, usersRouter);
app.use('/exercises', exerciseRouter);
app.use('/exercise_results', requireAuth, exerciseResultsRouter);
app.use('/auth', authRouter);

app.use((req, res, next) => {
    res.status(404).json({ error: 'Not Found' });
});

app.use((err, req, res, next) => {
    console.error(err)
    res.status(500).json({ error: 'Something went wrong! Could be something with payload?' });
});

module.exports = app;
