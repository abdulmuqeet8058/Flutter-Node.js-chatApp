const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');
const User = require('../models/User');

function toPublicUser(doc) {
  return {
    id: doc._id.toString(),
    username: doc.username,
    createdAt: doc.createdAt ? doc.createdAt.toISOString() : null,
  };
}

async function registerUser(username, password) {
  const cleanUsername = username.trim().toLowerCase();
  const existingUser = await User.findOne({ username: cleanUsername });

  if (existingUser) {
    throw new Error('Username is already taken.');
  }

  const passwordHash = await bcrypt.hash(password, 10);

  try {
    const user = await User.create({ username: cleanUsername, passwordHash });
    return toPublicUser(user);
  } catch (error) {
    if (error.code === 11000) {
      throw new Error('Username is already taken.');
    }
    throw error;
  }
}

async function loginUser(username, password) {
  const cleanUsername = username.trim().toLowerCase();
  const user = await User.findOne({ username: cleanUsername });

  if (!user) {
    throw new Error('Invalid username or password.');
  }

  const passwordMatches = await bcrypt.compare(password, user.passwordHash);

  if (!passwordMatches) {
    throw new Error('Invalid username or password.');
  }

  return toPublicUser(user);
}

async function findUserById(userId) {
  if (!mongoose.isValidObjectId(userId)) {
    return null;
  }

  const user = await User.findById(userId);
  return user ? toPublicUser(user) : null;
}

async function listUsers() {
  const users = await User.find().sort({ createdAt: 1 });
  return users.map(toPublicUser);
}

module.exports = {
  registerUser,
  loginUser,
  findUserById,
  listUsers,
};
