const express = require("express");
const app = express();
const PORT = process.env.PORT || 3000;

app.get("/", (req, res) => {
  res.send("Hello World from Backend API 🚀");
});

// endpoint healthcheck (utile pour le load balancer et Prometheus)
app.get("/health", (req, res) => {
  res.json({ status: "ok" });
});

app.listen(PORT, () => {
  console.log(`Backend API running on port ${PORT}`);
});
