const express = require('express');
const app = express();
const usersRouter = require('./routes/users');

// Middleware
app.use(express.json());

// Routes
app.use('/users', usersRouter);

module.exports = app;
