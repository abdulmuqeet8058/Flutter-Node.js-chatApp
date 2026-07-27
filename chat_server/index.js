const { connectToDatabase } = require('./src/config/db');
const { createServer } = require('./src/server');
const { port } = require('./src/config/env');

async function start() {
  await connectToDatabase();

  const { httpServer } = createServer();
  httpServer.listen(port, () => {
    console.log(`Chat server is running at http://localhost:${port}`);
  });
}

start().catch((error) => {
  console.error('Failed to start server:', error.message);
  process.exit(1);
});
