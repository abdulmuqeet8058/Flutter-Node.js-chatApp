const connections = new Map();

function addConnection(userId, socketId) {
  const sockets = connections.get(userId) || new Set();
  sockets.add(socketId);
  connections.set(userId, sockets);
}

function removeConnection(userId, socketId) {
  const sockets = connections.get(userId);
  if (!sockets) return;

  sockets.delete(socketId);
  if (sockets.size === 0) {
    connections.delete(userId);
  }
}

function isOnline(userId) {
  return connections.has(userId);
}

function onlineUserIds() {
  return [...connections.keys()];
}

module.exports = { addConnection, removeConnection, isOnline, onlineUserIds };
