const express = require('express');
const { authMiddleware } = require('../middleware/authMiddleware');
const { listUsers } = require('../services/userService');
const {
  ChatError,
  createGroup,
  getDirectConversation,
  getGroupMessages,
  getUserGroups,
  saveDirectMessage,
  saveGroupMessage,
} = require('../services/chatService');
const { announceGroup, groupRoom } = require('../sockets/groupEvents');
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

  router.post('/direct/:userId/messages', asyncRoute(async (req, res) => {
    const { text } = req.body;
    if (!text || !text.trim()) {
      throw new ChatError('Message text is required.');
    }

    const message = await saveDirectMessage(
      req.user.id,
      req.params.userId,
      text
    );

    io.to(req.params.userId).emit('direct:message', message);
    io.to(req.user.id).emit('direct:message', message);
    res.status(201).json({ message });
  }));

  router.get('/groups', asyncRoute(async (req, res) => {
    res.json({ groups: await getUserGroups(req.user.id) });
  }));

  router.post('/groups', asyncRoute(async (req, res) => {
    const { name, memberIds = [] } = req.body;
    const group = await createGroup(req.user.id, name || '', memberIds);

    announceGroup(io, group);
    res.status(201).json({ group });
  }));

  router.get('/groups/:groupId/messages', asyncRoute(async (req, res) => {
    const messages = await getGroupMessages(
      req.params.groupId,
      req.user.id
    );
    res.json({ messages });
  }));

  router.post('/groups/:groupId/messages', asyncRoute(async (req, res) => {
    const { text } = req.body;
    if (!text || !text.trim()) {
      throw new ChatError('Message text is required.');
    }

    const message = await saveGroupMessage(
      req.user.id,
      req.params.groupId,
      text
    );

    io.to(groupRoom(req.params.groupId)).emit('group:message', message);
    res.status(201).json({ message });
  }));

  return router;
}

module.exports = chatRoutes;
