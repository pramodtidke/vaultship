const http = require("http");

const PORT = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
  if (req.url === "/health") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ status: "ok", version: process.env.APP_VERSION || "local" }));
    return;
  }
  res.writeHead(200, { "Content-Type": "text/plain" });
  res.end("VaultShip is running\n");
});

server.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
