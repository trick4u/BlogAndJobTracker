const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());
app.use(cors()); // Enable CORS

const pool = new Pool({
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: process.env.DB_DATABASE,
});

// API Endpoints for Posts
app.get('/posts', async (req, res) => {
    try {
        const { tag } = req.query;
        let query = 'SELECT p.*, ARRAY(SELECT text FROM comments c WHERE c.post_id = p.id) AS comments FROM posts p';
        const values = [];
        if (tag) {
            query += ' WHERE $1::jsonb @> ANY(tags)';
            values.push(JSON.stringify(tag));
        }
        query += ' ORDER BY date DESC';
        const result = await pool.query(query, values);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error', details: err.message });
    }
});

app.post('/posts', async (req, res) => {
    const { title, content, tags } = req.body;
    try {
        if (!title || !content) {
            return res.status(400).json({ error: 'Title and content are required' });
        }
        const tagsJson = tags ? JSON.stringify(tags) : '[]';
        const result = await pool.query(
            'INSERT INTO posts (title, content, tags) VALUES ($1, $2, $3::jsonb) RETURNING *',
            [title, content, tagsJson]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error', details: err.message });
    }
});

app.post('/comments', async (req, res) => {
    const { post_id, text } = req.body;
    try {
        if (!post_id || !text) {
            return res.status(400).json({ error: 'Post ID and text are required' });
        }
        const result = await pool.query(
            'INSERT INTO comments (post_id, text) VALUES ($1, $2) RETURNING *',
            [post_id, text]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error', details: err.message });
    }
});

// API Endpoints for Applications
app.get('/applications', async (req, res) => {
    try {
        const { status } = req.query;
        let query = 'SELECT * FROM applications';
        const values = [];
        if (status) {
            query += ' WHERE status = $1';
            values.push(status);
        }
        query += ' ORDER BY apply_date DESC';
        const result = await pool.query(query, values);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error', details: err.message });
    }
});

app.post('/applications', async (req, res) => {
    const { company, position, status, apply_date, follow_up } = req.body;
    try {
        if (!company || !position || !status || !apply_date) {
            return res.status(400).json({ error: 'Company, position, status, and apply date are required' });
        }
        const result = await pool.query(
            'INSERT INTO applications (company, position, status, apply_date, follow_up) VALUES ($1, $2, $3, $4, $5) RETURNING *',
            [company, position, status, apply_date, follow_up || null]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error', details: err.message });
    }
});

app.put('/applications/:id', async (req, res) => {
    const { id } = req.params;
    const { company, position, status, apply_date, follow_up } = req.body;
    try {
        const result = await pool.query(
            'UPDATE applications SET company = $1, position = $2, status = $3, apply_date = $4, follow_up = $5 WHERE id = $6 RETURNING *',
            [company, position, status, apply_date, follow_up || null, id]
        );
        if (result.rowCount === 0) return res.status(404).send('Application not found');
        res.json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error', details: err.message });
    }
});

app.delete('/applications/:id', async (req, res) => {
    const { id } = req.params;
    try {
        const result = await pool.query('DELETE FROM applications WHERE id = $1', [id]);
        if (result.rowCount === 0) return res.status(404).send('Application not found');
        res.status(204).send();
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error', details: err.message });
    }
});

app.listen(port, () => {
    console.log(`Server running on port ${port}`);
});