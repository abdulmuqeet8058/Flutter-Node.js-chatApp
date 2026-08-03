const mongoose = require('mongoose');
const DirectMessage = require('../models/DirectMessage');
const Group = require('../models/Group');
const GroupMessage = require('../models/GroupMessage');
const User = require('../models/User');
const { findUserById } = require('./userService');

class ChatError extends Error {
  constructor(message, statusCode = 400) {
    super(message);
    this.statusCode = statusCode;
  }
}

function toPublicDirectMessage(doc) {
  return {
    id: doc._id.toString(),
    senderId: doc.senderId.toString(),
    receiverId: doc.receiverId.toString(),
    text: doc.text,
    createdAt: doc.createdAt ? doc.createdAt.toISOString() : null,
  };
}

function toPublicGroupMessage(doc) {
  return {
    id: doc._id.toString(),
    senderId: doc.senderId.toString(),
    groupId: doc.groupId.toString(),
    text: doc.text,
    createdAt: doc.createdAt ? doc.createdAt.toISOString() : null,
  };
}

function toPublicGroup(doc) {
  return {
    id: doc._id.toString(),
    name: doc.name,
    ownerId: doc.ownerId.toString(),
    memberIds: doc.memberIds.map((id) => id.toString()),
    createdAt: doc.createdAt ? doc.createdAt.toISOString() : null,
  };
}

function cleanMessageText(text) {
  const value = text.trim();
  if (value.length > 2000) {
    throw new ChatError('Messages cannot be longer than 2000 characters.');
  }
  return value;
}

async function saveDirectMessage(senderId, receiverId, text) {
  const messageText = cleanMessageText(text);

  if (!(await findUserById(receiverId))) {
    throw new ChatError('Receiver was not found.', 404);
  }

  const message = await DirectMessage.create({
    senderId,
    receiverId,
    text: messageText,
  });

  return toPublicDirectMessage(message);
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

  return messages.map(toPublicDirectMessage);
}

async function createGroup(ownerId, name, memberIds) {
  if (typeof name !== 'string' || !Array.isArray(memberIds)) {
    throw new ChatError('Group name and members are required.');
  }

  const groupName = name.trim();
  if (!groupName || groupName.length > 80) {
    throw new ChatError('Group name must be between 1 and 80 characters.');
  }

  const requestedMembers = [...new Set(memberIds.map(String))]
    .filter((id) => id !== ownerId.toString());

  if (requestedMembers.length === 0) {
    throw new ChatError('Choose at least one other group member.');
  }

  if (requestedMembers.some((id) => !mongoose.isValidObjectId(id))) {
    throw new ChatError('One or more selected members are invalid.');
  }

  const memberCount = await User.countDocuments({
    _id: { $in: requestedMembers },
  });

  if (memberCount !== requestedMembers.length) {
    throw new ChatError('One or more selected members were not found.', 404);
  }

  const group = await Group.create({
    name: groupName,
    ownerId,
    memberIds: [ownerId, ...requestedMembers],
  });

  return toPublicGroup(group);
}

async function getUserGroups(userId) {
  const groups = await Group.find({ memberIds: userId }).sort({ updatedAt: -1 });
  return groups.map(toPublicGroup);
}

async function findGroupForMember(groupId, userId) {
  if (!mongoose.isValidObjectId(groupId)) {
    throw new ChatError('Group was not found.', 404);
  }

  const group = await Group.findById(groupId);
  if (!group) {
    throw new ChatError('Group was not found.', 404);
  }

  const isMember = group.memberIds.some(
    (memberId) => memberId.toString() === userId.toString()
  );

  if (!isMember) {
    throw new ChatError('You are not a member of this group.', 403);
  }

  return group;
}

async function getGroupMessages(groupId, userId) {
  await findGroupForMember(groupId, userId);
  const messages = await GroupMessage.find({ groupId }).sort({ createdAt: 1 });
  return messages.map(toPublicGroupMessage);
}

async function saveGroupMessage(senderId, groupId, text) {
  const messageText = cleanMessageText(text);
  await findGroupForMember(groupId, senderId);

  const message = await GroupMessage.create({
    senderId,
    groupId,
    text: messageText,
  });

  await Group.findByIdAndUpdate(groupId, { updatedAt: new Date() });
  return toPublicGroupMessage(message);
}

module.exports = {
  ChatError,
  createGroup,
  getDirectConversation,
  getGroupMessages,
  getUserGroups,
  saveDirectMessage,
  saveGroupMessage,
};
