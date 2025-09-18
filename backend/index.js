const express = require("express");
const app = express();
const port = 8000;

app.get("/", (req, res) => {
  res.send("Hello Backend depuis Express + Docker v2");
});

app.listen(port, () => {
  console.log(`Backend listening on http://localhost:${port}`);
});
