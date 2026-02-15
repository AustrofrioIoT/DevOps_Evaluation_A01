const express = require('express');
const serverlessExpress = require('@vendia/serverless-express');
const db = require('./db');

const app = express();
app.use(express.json());

// Init DB: Asegurar tabla 'users'
const initDB = async () => {
    try {
        await db.query(`
            CREATE TABLE IF NOT EXISTS users (
                id SERIAL PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                email VARCHAR(100) UNIQUE NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        `);
        console.log('Tabla "users" lista.');
    } catch (err) {
        console.error('Error inicializando DB:', err.message);
    }
};

// Endpoints

// 1. Ruta Raíz
app.get('/', (req, res) => {
    res.send('<h1>API de Usuarios - Jelou</h1><p>Endpoints: /users, /health</p>');
});

// Health
app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// POST /users
app.post('/users', async (req, res) => {
    const { name, email } = req.body;
    if (!name || !email) return res.status(400).json({ error: 'Nombre y email son requeridos' });

    try {
        const result = await db.query(
            'INSERT INTO users (name, email) VALUES ($1, $2) RETURNING *',
            [name, email]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// GET /users/:id
app.get('/users/:id', async (req, res) => {
    try {
        const result = await db.query('SELECT * FROM users WHERE id = $1', [req.params.id]);
        if (result.rows.length === 0) return res.status(404).json({ error: 'Usuario no encontrado' });
        res.json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// PUT /users/:id
app.put('/users/:id', async (req, res) => {
    const { name, email } = req.body;
    try {
        const result = await db.query(
            'UPDATE users SET name = $1, email = $2 WHERE id = $3 RETURNING *',
            [name, email, req.params.id]
        );
        if (result.rows.length === 0) return res.status(404).json({ error: 'Usuario no encontrado' });
        res.json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// DELETE /users/:id
app.delete('/users/:id', async (req, res) => {
    try {
        const result = await db.query('DELETE FROM users WHERE id = $1 RETURNING *', [req.params.id]);
        if (result.rows.length === 0) return res.status(404).json({ error: 'Usuario no encontrado' });
        res.json({ message: 'Usuario eliminado correctamente' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Wrapper para Lambda que inicializa la DB antes de cada ejecución (o reuse)
const handler = serverlessExpress({ app });

exports.handler = async (event, context) => {
    await initDB();
    return handler(event, context);
};

// local
if (require.main === module) {
    const port = process.env.PORT || 3000;
    app.listen(port, async () => {
        await initDB();
        console.log(`Servidor en http://localhost:${port}`);
    });
}
