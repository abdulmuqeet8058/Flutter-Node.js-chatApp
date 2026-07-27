const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    username: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
      minlength: 3,
      maxlength: 30,
      match: /^[a-z0-9_]+$/,
    },
    passwordHash: {
      type: String,
      required: true,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('User', userSchema);
