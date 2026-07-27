const {
  addConnection,
  removeConnection,
  onlineUserIds,
} = require('../store/presenceStore');
const { saveDirectMessage } = require('../services/chatService');

function broadcastPresence(io) {
  io.emit('users:online', onlineUserIds());
}

function registerSocketHandlers(io, socket) {
  const user = socket.user;

  addConnection(user.id, socket.id);
  socket.join(user.id);
  broadcastPresence(io);

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

  socket.on('disconnect', () => {
    removeConnection(user.id, socket.id);
    broadcastPresence(io);
  });
}

module.exports = { registerSocketHandlers };
