
// usage: mongo <connection uri> 01-addExternalIdSet.js
// note: connection uri should include the portl database (portl_staging, etc)

function addExternalIdSet(collectionName) {
  print('addExternalIdSet ' + collectionName);
  var collection = db[collectionName];
  var totalCount = collection.find({$or: [{externalIdSet: null}, {externalIdSet: []}]}).count();
  var completedCount = 0;
  collection.find({$or: [{externalIdSet: null}, {externalIdSet: []}]}).forEach(function(obj) {
    if (completedCount % 10000 === 0) {
      print( (completedCount / totalCount * 100) + '%');
    }
    completedCount += 1;
    collection.update({_id: obj._id}, {$set: {externalIdSet: [obj.externalId]}});
  });
  print('addExternalIdSet ' + collectionName + ' done');
}

addExternalIdSet('events');
addExternalIdSet('venues');
addExternalIdSet('artists');
