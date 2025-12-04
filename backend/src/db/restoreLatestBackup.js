const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const backupFolder = path.join(__dirname, 'backups');

// Get the latest backup file based on modified time
const files = fs.readdirSync(backupFolder)
  .filter(f => f.endsWith('.sql'))
  .map(f => ({ name: f, time: fs.statSync(path.join(backupFolder, f)).mtime.getTime() }))
  .sort((a, b) => b.time - a.time);

if (files.length === 0) {
  console.error('No SQL backup files found.');
  process.exit(1);
}

const latestBackup = path.join(backupFolder, files[0].name);
console.log(`Restoring from latest backup: ${latestBackup}`);

// Construct the MySQL command
const command = `mysql -h ${process.env.DB_HOST} -P ${process.env.DB_PORT} -u ${process.env.DB_USER} -p${process.env.DB_PASSWORD} ${process.env.DB_NAME} < "${latestBackup}"`;

exec(command, (error, stdout, stderr) => {
  if (error) {
    console.error(`Error restoring backup: ${error.message}`);
    return;
  }
  if (stderr) {
    console.error(`MySQL stderr: ${stderr}`);
    return;
  }
  console.log('Database restored successfully.');
});