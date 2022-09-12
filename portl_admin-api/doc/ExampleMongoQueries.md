

## Mark duplicate venues for deletion

After the first round of aggregation with deduplication logic, duplicate venues all share the same externalId.

First, group by externalId and collect the matching venue ids. We only care about groups with more than one venue.

    db.venues.aggregate([
      {$group: {_id: '$externalId', venueIds: {$addToSet: '$_id'}, venueCount: {$sum: 1}}},
      {$match: {venueCount: {$gt: 1}}},
      {$out: 'tempVenueGroups'}
    ]);

For each group, mark all but one for deletion.

    var now = NumberLong(new Date().getTime());
    db.tempVenueGroups.find().forEach(function(g) {
      db.venues.updateMany({_id: {$in: g.ids.slice(1)}}, {$set: {markedForDeletion: now}});
    });

Sanity checks:

For every venue marked, there should be exactly one unmarked venue with the same externalId.

    db.venues.find({markedForDeletion: {$exists: true}}, {externalId: 1})
      .map(function(v) {return v.externalId})
      .forEach(function(id) {
        assert(db.venues.find({externalId: id, markedForDeletion: null}).count() == 1)
      })

Checking all of them might take a while, so maybe check a few random ones instead:

    var markedVenueId = db.venues.aggregate([
      {$match: {markedForDeletion: {$exists: true}}},
      {$sample: {size: 1}}
    ]).map(function(v) {
      return v.externalId
    })[0]
    assert(db.venues.find({externalId: markedVenueId, markedForDeletion: null}).count() == 1)



## Find duplicate events by externalId

    db.events.aggregate([
      {$group: {_id: {sourceType: '$externalId.sourceType', identifierOnSource: '$externalId.identifierOnSource'}, count: {$sum: 1}}},
      {$match: {count: {$gt: 1}}},
      {$sort: {count: -1}},
      {$limit: 5},
    ])

## Add externalIdSet to everything

    // OK to set this to empty array. These will be found with the first "duplicate" search and updated to include the
    // correct externalId in the externalIdSet.
    db.events.updateMany(
        {externalIdSet: {$exists: false}},
        {$set: {externalIdSet: []}}
    )
    db.events.updateMany(
        {artist: {$ne: null}, 'artist.externalIdSet': {$exists: false}},
        {$set: {'artist.externalIdSet': []}}
    )
    db.events.updateMany(
        {'venue.externalIdSet': {$exists: false}},
        {$set: {'venue.externalIdSet': []}}
    )
    db.artists.updateMany(
        {externalIdSet: {$exists: false}},
        {$set: {externalIdSet: []}}
    )
    db.venues.updateMany(
        {externalIdSet: {$exists: false}},
        {$set: {externalIdSet: []}}
    )

## Find the overlap

The whole superset is probably too much information
For each number of services, how many overlap by that number? (5, 4, 3, 2, 1)
For each pair of services, how many overlap?
For each service, how many are unique to that service?

    // Distinct source types for each document, descending on number of source types
    // { "_id" : ObjectId("5afcc357190e9f6d28388c73"), "sourceTypes" : [ 1, 3, 6 ], "count" : 3 }
    db.venues.aggregate([
        {$project: {sourceTypes: {$setUnion: ['$externalIdSet.sourceType']}}},
        {$addFields: {count: {$size: '$sourceTypes'}}},
        {$match: {count: {$gt: 1}}},
        {$sort: {count: -1}},
        {$limit: 10},
    ])

    // Count of entities per distinct set of source types
    // { "_id" : [ 1, 3, 6 ], "sourceTypeCount" : 3, "count" : 42 }
    db.venues.aggregate([
        {$project: {sourceTypes: {$setUnion: ['$externalIdSet.sourceType']}}},
        {$addFields: {sourceTypeCount: {$size: '$sourceTypes'}}},
        {$group: {_id: '$sourceTypes', sourceTypeCount: {$first: '$sourceTypeCount'}, count: {$sum: 1}}},
        {$sort: {sourceTypeCount: -1}},
    ])

## Export songkick artist ids

    db.events.aggregate([
        {$unwind: '$performance'},
        {$project: {_id: 0, artistId: '$performance.artist.id'}},
        {$group: {_id: '$artistId', count: {$sum: 1}}},
        {$out: 'temp_artist_ids'}
    ])
    mongoexport --uri mongodb://localhost/songkick --collection temp_artist_ids --fields _id --type csv -o songkick-artist-ids.csv
