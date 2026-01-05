const db = require('./connection');

async function test() {
  try {
    const [rows] = await db.query('SELECT * FROM exercises');
    console.log('Exercises:', rows);
  } catch (err) {
    console.error('DB error:', err);
  }
}

test();
