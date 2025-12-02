const express = require ('express');
const sqlite3 = require('sqlite3').verbose();

const app = express();
const PORT = 3000;


app.use(express.json());

const db = new sqlite3.Database('../db/users.db', (err) => {
    if (err) {
        console.error("Could not connect to database ", err);
    } else {
        console.log('Connected to SQLite database users.db')
    }
});