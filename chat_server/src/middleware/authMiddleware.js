const { verifyToken } = require('../services/tokenService');
const { findUserById } = require('../services/userService');

async function authMiddleware(req, res, next) {
  const header = req.headers.authorization;
  const token = header && header.startsWith('Bearer ') ? header.slice(7) : null;

  if (!token) {
    return res.status(401).json({ message: 'Missing auth token.' });
  }

  try {
    const payload = verifyToken(token);
    const user = await findUserById(payload.id);

    if (!user) {
      return res.status(401).json({ message: 'User no longer exists.' });
    }

    req.user = user;
    return next();
  } catch (error) {
    return res.status(401).json({ message: 'Invalid or expired auth token.' });
  }
}

module.exports = { authMiddleware };
