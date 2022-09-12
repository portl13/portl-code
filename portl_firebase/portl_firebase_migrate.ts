import { DataModelV1 } from "./data_model/model_1"
import { DataModelV1_2 } from "./data_model/model1_2"

var admin = require("firebase-admin")

let model_version_from = process.env.FROM_MODEL
let model_version_to = process.env.TO_MODEL
let firebase_service_account = require(process.env.PRODUCTION ? 
  "./service_account/portl-fe374-firebase-adminsdk-dmu9u-a05ebaac6a.json" : "./service_account/portl-dev-1d042-firebase-adminsdk-zodob-15e4ff44de.json")
let firebase_database_url = process.env.PRODUCTION ? 
  "https://portl-fe374.firebaseio.com/" : 
  "https://portl-dev-1d042.firebaseio.com"

if (model_version_from != undefined && model_version_to != undefined) {
  if (+model_version_to == (+model_version_from + 1)) {
    admin.initializeApp({
      credential: admin.credential.cert(firebase_service_account),
      databaseURL: firebase_database_url
    });
    
    var db = admin.database();
    var ref = db.ref("/");

    ref.once("value", function (snapshot: any) {
      let data = snapshot.val() as DataModelV1;
      
      if (data.schema.version == +model_version_from! && +model_version_from! == 1 && +model_version_to! == 2) {

        let new_data = new DataModelV1_2(data.device, data.event, data.friend, data.message, data.notification, data.profile, data.room, data.shared_event)

        ref.set(JSON.parse(JSON.stringify(new_data)))
          .then(function() {
            // todo: catch error and use non-zero exit code
            process.exit(0)
          })
        console.log("=== WRITING DATA TO FIREBASE DATABASE ===")

      } else {
        throw new Error("No migration configured for supplied model versions FROM:" + model_version_from + " TO:" + model_version_to + ".")
      }
    })
  } else {
    throw new Error("Incorrect model versions were provided for migration.")
    process.exit(1)
  }
} else {
  throw new Error("No model versions provided form migration.")
  process.exit(1)
}
