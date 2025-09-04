import React, { useEffect, useState } from "react";

function App() {
  const [apiMessage, setApiMessage] = useState("Chargement...");

  useEffect(() => {
    fetch("http://localhost:8000/api/hello") // fonctionne avec le proxy en local
      .then((res) => {
        if (!res.ok) throw new Error("Réponse réseau non OK");
        return res.json();
      })
      .then((data) => setApiMessage(data.message))
      .catch((err) => {
        console.error("Erreur API :", err);
        setApiMessage("Erreur lors de la récupération du message backend ❌");
      });
  }, []);

  return (
    <div style={{ textAlign: "center", marginTop: 50 }}>
      <h1>Hello World React!</h1>
      <p>Projet React dockerisé 🚀</p>
      <hr style={{ width: "50%" }} />
      <p><strong>Message du backend :</strong> {apiMessage}</p>
    </div>
  );
}

export default App;
