require('dotenv').config();

module.exports = {
  port: process.env.PORT || 3000,
  jwtSecret: process.env.JWT_SECRET || 'learning-secret-change-me',
  mongoUri: process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/ping_chat',
};
