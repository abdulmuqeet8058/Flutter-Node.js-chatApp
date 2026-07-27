const express = require('express');
const { authMiddleware } = require('../middleware/authMiddleware');
const { createToken } = require('../services/tokenService');
const { registerUser, loginUser } = require('../services/userService');

const router = express.Router();

router.post('/register', async (req, res) => {
  const { username, password } = req.body;

  if (!username || !/^[a-zA-Z0-9_]{3,30}$/.test(username.trim())) {
    return res.status(400).json({
      message: 'Username must be 3–30 characters and use only letters, numbers, or underscores.',
    });
  }

  if (!password || password.length < 4) {
    return res.status(400).json({
      message: 'Password must be at least 4 characters.',
    });
  }

  try {
    const user = await registerUser(username, password);
    const token = createToken(user);
    return res.status(201).json({ user, token });
  } catch (error) {
    return res.status(400).json({ message: error.message });
  }
});

router.post('/login', async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ message: 'Username and password are required.' });
  }

  try {
    const user = await loginUser(username, password);
    const token = createToken(user);
    return res.json({ user, token });
  } catch (error) {
    return res.status(401).json({ message: error.message });
  }
});

router.get('/me', authMiddleware, (req, res) => {
  res.json({ user: req.user });
});

router.post('/logout', authMiddleware, (req, res) => {
  res.json({ message: 'Logged out successfully.' });
});

module.exports = router;
