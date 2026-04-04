const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    console.log('URI from Env:', process.env.MONGODB_URI ? 'FOUND' : 'MISSING');
    console.log('Connecting to:', process.env.MONGODB_URI?.includes('@') ? 'ATLAS' : 'LOCAL');
    const conn = await mongoose.connect(process.env.MONGODB_URI);
    console.log(`MongoDB Connected: ${conn.connection.host}`);
    
    // Auto-cleanup for the old 'id' unique index in tiers collection
    try {
      const db = conn.connection.db;
      const collections = await db.listCollections({ name: 'tiers' }).toArray();
      if (collections.length > 0) {
        const indexes = await db.collection('tiers').indexes();
        const hasIdIndex = indexes.some(idx => idx.name === 'id_1');
        if (hasIdIndex) {
          await db.collection('tiers').dropIndex('id_1');
          console.log('Successfully dropped unique index on "id" in tiers collection.');
        }
      }
    } catch (indexErr) {
      // Ignore if index doesn't exist
      console.log('Note: Could not drop index (might not exist):', indexErr.message);
    }
  } catch (err) {
    console.error(`Error: ${err.message}`);
    process.exit(1);
  }
};

module.exports = connectDB;
