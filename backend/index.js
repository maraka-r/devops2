const express = require('express');
const cors = require('cors');

const app = express();

app.use(cors());

app.get('/api/hello', (req, res) => {
  res.json({ message: "Bienvenue sur l’API backend 🚀" });
});

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => {
  console.log(`✅ Backend API is running at http://localhost:${PORT}`);
});
