"use strict";
const _ = GLOBAL._ = require('lodash');
require('coffee-script');
require('coffee-script/register');

const program = require('commander');
program
  .option('--mainMongoConnUrl <string>', 'Main MongoDB connection URL (with write access)')
  .option('--levelSessionMongoConnUrl <string>', 'LevelSession MongoDB connection URL (with write access)')
  .option('--dryRun', 'Prevent actual removal of users')
  .parse(process.argv)

const config = require('../../server_config');
config.mongo.level_session_replica_string = program.levelSessionMongoConnUrl

const mongoose = require('mongoose');
const Promise = require('bluebird');
const co = require('co');
const User = require('../../server/models/User')
const LevelSession = require('../../server/models/LevelSession')

console.log("Started script");
co(function*(){
  "use strict";
  yield mongoose.connect(program.mainMongoConnUrl);
  const connection = mongoose.connection;

  console.log("Counting old users...");
  const numOldUsers = yield User.count({
    anonymous: true,
    dateCreated: {
      $lt: new Date(new Date() - 1000*60*60*24*90)
    }
  })
  const batchSize = 1000;
  const numBatches = Math.ceil(numOldUsers / batchSize);
  console.log(`Found ${numOldUsers} old users to delete (${numBatches} batches of ${batchSize})`);
  
  for(var batchNumber = 0; batchNumber < numBatches; batchNumber++) {
    const oldUsers = yield User.find({
      anonymous: true,
      dateCreated: {
        $lt: new Date(new Date() - 1000*60*60*24*90)
      }
    }).skip(batchNumber * batchSize).limit(batchSize);
    console.log("Batch", batchNumber, "has", oldUsers.length, "users to delete");
    
    const oldUserIds = oldUsers.map((user)=>{return "" + user._id});
    
    const levelSessions = yield LevelSession.find({
      creator: {$in: oldUserIds}
    })
    console.log("found", levelSessions.length, "level sessions");
    
    if(!program.dryRun) {
      console.log("Removing users!");
      yield LevelSession.remove({
        creator: {$in: oldUserIds}
      })
      yield User.remove({
        _id: {$in: oldUserIds.map((_id) => { return mongoose.Types.ObjectId(_id) })}
      })
    }
  }
}).then(function(){
  console.log("Done");
  process.exit()
}).catch(function(err){
  console.log(err.stack || err);
})
