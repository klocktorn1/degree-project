const express = require('express');
const app = express();
const cookieParser = require('cookie-parser')
const cors = require('cors');


app.use(cookieParser())
app.use(express.json());
app.use(cors({
    origin: 'http://localhost:8000',
    credentials: true,
}));



const usersRouter = require('./routes/users');
const exerciseRouter = require('./routes/exercises');
const exerciseResultsRouter = require('./routes/exercise_results');
const authRouter = require('./routes/auth');
const requireAuth = require('./middleware/requireAuth')





app.use('/users', requireAuth, usersRouter);
app.use('/exercises', exerciseRouter);
app.use('/exercise_results', requireAuth, exerciseResultsRouter);
app.use('/auth', authRouter);

app.use((req, res, next) => {
    res.status(404).json({ error: 'Endpoint Not Found' });
});

app.use((err, req, res, next) => {
    console.error(err)
    res.status(500).json({ error: 'Something went wrong! Could be something with payload?' });
});

module.exports = app;
