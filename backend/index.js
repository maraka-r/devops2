const express = require('express');
const app = express();
const port = process.env.PORT || 8000;

// Exemple d'endpoint principal
app.get('/', (req, res) => {
  res.send('Hello Backend depuis Express!');
});

// ✅ Endpoint /health pour les checks LB
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

app.listen(port, () => {
  console.log(`Backend listening on http://localhost:${port}`);
});
