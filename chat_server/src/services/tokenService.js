const jwt = require('jsonwebtoken');
const { jwtSecret } = require('../config/env');

function createToken(user) {
  return jwt.sign(
    {
      id: user.id,
      username: user.username,
    },
    jwtSecret,
    { expiresIn: '1d' }
  );
}

function verifyToken(token) {
  return jwt.verify(token, jwtSecret);
}

module.exports = {
  createToken,
  verifyToken,
};
