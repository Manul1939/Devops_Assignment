const express = require("express");

const app = express();
const port = process.env.PORT || 3000;
const tenant = process.env.TENANT_NAME || "unknown-tenant";

app.get("/", (_req, res) => {
  res.json({
    message: "Hello from Node.js tenant app",
    tenant,
    timestamp: new Date().toISOString()
  });
});

app.get("/healthz", (_req, res) => {
  res.status(200).send("ok");
});

app.get("/readyz", (_req, res) => {
  res.status(200).send("ready");
});

app.listen(port, () => {
  // Keep startup log concise for container logs.
  console.log(`Node tenant app listening on ${port} for ${tenant}`);
});
