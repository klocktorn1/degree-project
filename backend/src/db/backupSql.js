const { exec } = require('child_process');
require('dotenv').config();
const path = require('path');

const backupFolder = path.join(__dirname, 'backups'); // folder to save dumps
const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
const backupFile = path.join(backupFolder, `myapp_db_${timestamp}.sql`);

const command = `mysqldump -h ${process.env.DB_HOST} -P ${process.env.DB_PORT} -u ${process.env.DB_USER} -p${process.env.DB_PASSWORD} ${process.env.DB_NAME} > "${backupFile}"`;

exec(command, (error, stdout, stderr) => {
  if (error) {
    console.error(`Error creating backup: ${error.message}`);
    return;
  }
  if (stderr) {
    console.error(`mysqldump stderr: ${stderr}`);
    return;
  }
  console.log(`Backup created successfully: ${backupFile}`);
});
