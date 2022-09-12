/**
 * Creates indexes according to a proprietary json schema.
 *
 * This should be run as a mongodb script after setting `schemaPath` to the absolute path of the
 * desired json schema file. For example,
 *
 *   mongo --eval "const schemaPath = '$(realpath src/main/resources/schema.json)'" src/scripts/createSchema.js
 *
 * Note: The adjacent file createSchema.sh points to this project's schema.json and handles passing the correct
 * parameters to mongo.
 *
 * Schema format:
 *
{
  "databases": [
    {
      "name": "portl",
      "collections": [
        {
          "name": "artists",
          "indexes": [
            {
              "keys": {
                "externalId.sourceType": 1,
                "externalId.identifierOnSource": 1
              },
              "options": {
                "unique": true
              }
            },
            ...
          ]
        },
        ...
      ]
    },
    ...
  ]
}
 */

// Caller must set schemaPath when calling this script. See above.
const schema = JSON.parse(cat(schemaPath)),
    connection = new Mongo();

schema.databases.forEach(dbData => {
    print("database: ", dbData.name);
    const db = connection.getDB(dbData.name);
    dbData.collections.forEach(collectionData => {
        print("creating", collectionData.name);
        db.runCommand({create: collectionData.name});
        const collection = db[collectionData.name];
        collectionData.indexes.forEach(index => {
            print("creating index on", collectionData.name);
            printjson(index);
            const options = Object.assign({background: true}, index.options);
            const result = collection.createIndex(index.keys, options);
            if (!result.ok) {
                throw new Error(result.errmsg);
            }
        });
    });
});
