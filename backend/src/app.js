const express = require('express');
const app = express();
const cookieParser = require('cookie-parser')
const path = require('path');


app.use(cookieParser())
app.use(express.json());



const usersRouter = require('./routes/users');
const exerciseRouter = require('./routes/exercises');
const subExercisesRouter = require('./routes/subExercises');
const completedExercisesRouter = require('./routes/completed_exercises');
const authRouter = require('./routes/auth');
const cors = require('cors')
const requireAuth = require('./middleware/requireAuth')





app.use(express.static(path.join(__dirname, "../../frontend/public")));
app.use('/assets', express.static(path.join(__dirname, "../../frontend/assets")));

app.use(cors())
app.use('/users', requireAuth, usersRouter);
app.use('/exercises', exerciseRouter);
app.use('/sub-exercises', subExercisesRouter);
app.use('/completed-exercises', requireAuth, completedExercisesRouter);
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
