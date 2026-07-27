const { verifyToken } = require('../services/tokenService');
const { findUserById } = require('../services/userService');

async function authenticateSocket(socket, next) {
  const token = socket.handshake.auth && socket.handshake.auth.token;

  if (!token) {
    return next(new Error('Missing auth token.'));
  }

  try {
    const payload = verifyToken(token);
    const user = await findUserById(payload.id);

    if (!user) {
      return next(new Error('User no longer exists.'));
    }

    socket.user = user;
    return next();
  } catch (error) {
    return next(new Error('Invalid or expired auth token.'));
  }
}

module.exports = { authenticateSocket };
