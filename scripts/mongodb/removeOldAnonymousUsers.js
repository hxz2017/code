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
const Grid = require('gridfs-stream')

console.log("Started script");
co(function*(){
  "use strict";
  yield mongoose.connect(program.mainMongoConnUrl);
  const connection = mongoose.connection;
  Grid.gfs = Grid(mongoose.connection.db, mongoose.mongo)

  console.log("Counting old users...");
  // const numOldUsers = yield User.count({
  //   anonymous: true,
  //   dateCreated: {
  //     $lt: new Date(new Date() - 1000*60*60*24*90)
  //   }
  // })
  const numOldUsers = 18176411;
  const batchSize = 100000;
  const numBatches = Math.ceil(numOldUsers / batchSize);
  console.log(`Found ${numOldUsers} old users to delete (${numBatches} batches of ${batchSize})`);
  
  var totalLevelSessions = 0;
  var totalMedia = 0;
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
    totalLevelSessions += levelSessions.length;
    console.log(`found ${levelSessions.length} level sessions (${totalLevelSessions} total)`);
    
    Grid.gfs.collection('media').find({ "metadata.creator": {$in: oldUserIds} }, (err, media) => {
      co(function*(){
        media = yield media.toArray();
        console.log(`found ${media.length} media chunks`);
        totalMedia += media.length;
        console.log(media);
      })
    });
    
    console.log(`Found ${totalMedia} media chunks so far.`);
    
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
