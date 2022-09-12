package com.portl.admin.models.songkick

import play.api.libs.json._

/*
{
"lng": -97.6114237,
"displayName": "Tony's Pizza Event Center",
"lat": 38.8402805,
"id": 3696709
}

{
"displayName": "Afrodesia Studios",
"id": 3741609
}

{
"displayName": "Unknown venue"
},

NOTE: Songkick venues come with a MetroArea that is NOT necessarily the venue's city (e.g., Eugene venues are in the
Salem metro area). To construct a PORTL venue, we use the city/state/country from the event.location instead.


List venues without ids grouped by metro area name with count of distinct locations
db.events.aggregate([
  {$match: {'venue.id': null}},
  {$project: {metroName: '$venue.metroArea.displayName', loc: ['$venue.lng', '$venue.lat']}},
  {$group: {_id: '$metroName', locs: {$addToSet: '$loc'}}},
  {$project: {locCount: {$size: '$locs'}, locs: 1}},
  {$sort: {locCount: -1}}
])

Unknown Venue - Los Angeles has 100 events, 21 distinct lat/lng pairs. 35 have null lat/lng.
There is some overlap with multiple events at the same lat/lng.


Are documents with the same lat/lng always the same?
db.events.aggregate([
  {$match: {'venue.id': null}},
  {$project: {loc: ['$venue.lng', '$venue.lat'], venue: 1}},
  {$group: {_id: '$loc', docs: {$addToSet: '$venue'}}},
  {$project: {docCount: {$size: '$docs'}, docs: 1}},
  {$sort: {docCount: -1}}
])
Looks like yes, except key order.
 */
case class SourceVenue(
    lng: Option[Double],
    displayName: String,
    lat: Option[Double],
    id: Option[Int], // NOTE: all venues without ids have displayName "Unknown venue"
    metroArea: MetroArea,
    uri: Option[String]
)

object SourceVenue {
  implicit val format: OFormat[SourceVenue] = Json.format[SourceVenue]
}
