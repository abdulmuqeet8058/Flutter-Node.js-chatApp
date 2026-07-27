const express = require('express');
const { authMiddleware } = require('../middleware/authMiddleware');
const { listUsers } = require('../services/userService');
const { getDirectConversation, saveDirectMessage } = require('../services/chatService');
const { isOnline } = require('../store/presenceStore');

const asyncRoute = (handler) => (req, res, next) => {
  Promise.resolve(handler(req, res, next)).catch(next);
};

function chatRoutes(io) {
  const router = express.Router();

  router.use(authMiddleware);

  router.get('/users', asyncRoute(async (req, res) => {
    const users = (await listUsers()).map((user) => ({
      ...user,
      online: isOnline(user.id),
    }));

    res.json({ users });
  }));

  router.get('/direct/:userId/messages', asyncRoute(async (req, res) => {
    const messages = await getDirectConversation(req.user.id, req.params.userId);
    res.json({ messages });
  }));

  router.post('/direct/:userId/messages', async (req, res) => {
    const { text } = req.body;

    if (!text || !text.trim()) {
      return res.status(400).json({ message: 'Message text is required.' });
    }

    try {
      const message = await saveDirectMessage(req.user.id, req.params.userId, text);
      io.to(req.params.userId).emit('direct:message', message);
      io.to(req.user.id).emit('direct:message', message);
      return res.status(201).json({ message });
    } catch (error) {
      return res.status(400).json({ message: error.message });
    }
  });

  return router;
}

module.exports = chatRoutes;
