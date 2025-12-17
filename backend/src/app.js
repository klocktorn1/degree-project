const express = require('express');
const app = express();
const cookieParser = require('cookie-parser')
const path = require('path');


app.use(cookieParser())
app.use(express.json());



const usersRouter = require('./routes/users');
const exerciseRouter = require('./routes/exercises');
const exerciseResultsRouter = require('./routes/exercise_results');
const authRouter = require('./routes/auth');
const requireAuth = require('./middleware/requireAuth')





app.use(express.static(path.join(__dirname, "../../frontend/public")));


app.use('/users', requireAuth, usersRouter);
app.use('/exercises', exerciseRouter);
app.use('/exercise_results', requireAuth, exerciseResultsRouter);
app.use('/auth', authRouter);

app.get(/.*/, (req, res) => {
    res.sendFile(
        path.join(__dirname, "../../frontend/public/index.html")
    );
});

app.use((req, res, next) => {
    res.status(404).json({ error: 'Endpoint Not Found' });
});

app.use((err, req, res, next) => {
    console.error(err)
    res.status(500).json({ error: 'Something went wrong! Could be something with payload?' });
});



module.exports = app;
