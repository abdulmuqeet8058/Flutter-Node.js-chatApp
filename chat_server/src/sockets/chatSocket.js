const {
  createGroup,
  getUserGroups,
  saveDirectMessage,
  saveGroupMessage,
} = require('../services/chatService');
const {
  addConnection,
  removeConnection,
  onlineUserIds,
} = require('../store/presenceStore');
const { announceGroup, groupRoom } = require('./groupEvents');

function broadcastPresence(io) {
  io.emit('users:online', onlineUserIds());
}

function registerSocketHandlers(io, socket) {
  const user = socket.user;

  addConnection(user.id, socket.id);
  socket.join(user.id);
  broadcastPresence(io);

  socket.on('disconnect', () => {
    removeConnection(user.id, socket.id);
    broadcastPresence(io);
  });

  const groupsReady = getUserGroups(user.id).then((groups) => {
    groups.forEach((group) => socket.join(groupRoom(group.id)));
  });

  socket.on('direct:send', async ({ receiverId, text } = {}) => {
    if (!receiverId || !text || !text.trim()) return;

    try {
      const message = await saveDirectMessage(user.id, receiverId, text);
      io.to(receiverId).emit('direct:message', message);
      socket.emit('direct:message', message);
    } catch (error) {
      socket.emit('chat:error', { message: error.message });
    }
  });

  socket.on('group:create', async ({ name, memberIds = [] } = {}, callback) => {
    try {
      const group = await createGroup(user.id, name || '', memberIds);
      announceGroup(io, group);
      if (typeof callback === 'function') {
        callback({ ok: true, group });
      }
    } catch (error) {
      if (typeof callback === 'function') {
        callback({ ok: false, message: error.message });
      }
      socket.emit('chat:error', { message: error.message });
    }
  });

  socket.on('group:send', async ({ groupId, text } = {}) => {
    if (!groupId || !text || !text.trim()) return;

    try {
      await groupsReady;
      const message = await saveGroupMessage(user.id, groupId, text);
      io.to(groupRoom(groupId)).emit('group:message', message);
    } catch (error) {
      socket.emit('chat:error', { message: error.message });
    }
  });

  return groupsReady;
}

module.exports = { registerSocketHandlers };
