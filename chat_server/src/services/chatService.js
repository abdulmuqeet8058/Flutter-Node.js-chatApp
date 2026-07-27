const mongoose = require('mongoose');
const DirectMessage = require('../models/DirectMessage');
const { findUserById } = require('./userService');

function toPublicMessage(doc) {
  return {
    id: doc._id.toString(),
    senderId: doc.senderId.toString(),
    receiverId: doc.receiverId.toString(),
    text: doc.text,
    createdAt: doc.createdAt ? doc.createdAt.toISOString() : null,
  };
}

async function saveDirectMessage(senderId, receiverId, text) {
  const messageText = text.trim();
  if (messageText.length > 2000) {
    throw new Error('Messages cannot be longer than 2000 characters.');
  }

  if (!(await findUserById(receiverId))) {
    throw new Error('Receiver was not found.');
  }

  const message = await DirectMessage.create({
    senderId,
    receiverId,
    text: messageText,
  });

  return toPublicMessage(message);
}

async function getDirectConversation(userId, otherUserId) {
  if (!mongoose.isValidObjectId(otherUserId)) {
    return [];
  }

  const messages = await DirectMessage.find({
    $or: [
      { senderId: userId, receiverId: otherUserId },
      { senderId: otherUserId, receiverId: userId },
    ],
  }).sort({ createdAt: 1 });

  return messages.map(toPublicMessage);
}

module.exports = { saveDirectMessage, getDirectConversation };
