const mysql = require('mysql2/promise');
const fs = require('fs');
require('dotenv').config();

const connection = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT || 3306,
  waitForConnections: true,
  connectionLimit: 5,
  queueLimit: 0,
  ssl: {
    rejectUnauthorized: true,
    ca: fs.readFileSync(__dirname + '/ca.pem'), // download from Aiven dashboard
  }
});

module.exports = connection;
