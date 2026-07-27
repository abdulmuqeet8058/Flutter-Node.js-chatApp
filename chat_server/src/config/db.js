const mongoose = require('mongoose');
const { mongoUri } = require('./env');

async function connectToDatabase() {
  mongoose.set('bufferCommands', false);

  await mongoose.connect(mongoUri, {
    serverSelectionTimeoutMS: 10000,
  });

  console.log(`Connected to MongoDB: ${mongoose.connection.name}`);
  return mongoose.connection;
}

module.exports = { connectToDatabase };
