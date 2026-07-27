const http = require('http');
const cors = require('cors');
const express = require('express');
const { Server } = require('socket.io');

const authRoutes = require('./routes/authRoutes');
const chatRoutes = require('./routes/chatRoutes');
const { registerSocketHandlers } = require('./sockets/chatSocket');
const { authenticateSocket } = require('./sockets/socketAuth');

function createServer() {
  const app = express();
  const httpServer = http.createServer(app);
  const io = new Server(httpServer, {
    cors: {
      origin: '*',
    },
  });

  app.use(cors());
  app.use(express.json());

  app.get('/', (req, res) => {
    res.json({
      name: 'Ping Chat API',

    });
  });

  app.get('/api/health', (req, res) => {
    res.json({ status: 'ok' });
  });

  app.use('/api/auth', authRoutes);
  app.use('/api/chat', chatRoutes(io));

  app.use((error, req, res, next) => {
    console.error(error);
    res.status(500).json({ message: 'Something went wrong on the server.' });
  });

  io.use(authenticateSocket);
  io.on('connection', (socket) => {
    registerSocketHandlers(io, socket);
  });

  return { app, httpServer, io };
}

module.exports = { createServer };
