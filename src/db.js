const { Pool } = require('pg');

const dbHost = process.env.DB_HOST ? process.env.DB_HOST.split(':')[0] : 'db';

const pool = new Pool({
    host: dbHost,
    user: process.env.DB_USER || 'dbadmin',
    password: process.env.DB_PASSWORD,
    database: 'appdb',
    port: 5432,
    ssl: {
        rejectUnauthorized: false // Requerido para RDS
    }
});

module.exports = {
    query: (text, params) => pool.query(text, params),
};
