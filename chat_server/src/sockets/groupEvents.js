function groupRoom(groupId) {
  return `group:${groupId}`;
}

function announceGroup(io, group) {
  const room = groupRoom(group.id);

  group.memberIds.forEach((memberId) => {
    io.in(memberId).socketsJoin(room);
  });

  io.to(room).emit('group:created', group);
}

module.exports = { announceGroup, groupRoom };
