package com.portl.admin.models.ticketfly.remote

import play.api.libs.json.{Format, JsObject, Json}

/*
{
  "status": "ok",
  "pageNum": 1,
  "totalPages": 33,
  "maxResults": 1000,
  "totalResults": 32197,
  "title": "Ticketfly Upcoming Events",
  "link": "http://www.ticketfly.com/api/events/upcoming.json",
  "currPage": "http://www.ticketfly.com/api/events/upcoming.json?orgId=1&fieldGroup=light",
  "prevPage": "",
  "nextPage": "http://www.ticketfly.com/api/events/upcoming.json?orgId=1&fieldGroup=light&pageNum=2",
  "org": {
    "id": 1,
    "name": "Root",
    "timeZone": "America/New_York",
    "promoter": false,
    "orgConfigEvent": {
      "enableCustomDomain": false,
      "customDomain": null
    }
  },
  "events": [ ... ]
}

{
  "title": "Ticketfly Request Failed",
  "status": "error",
  "link": "http://www.ticketfly.com/api/events/upcoming.json",
  "code": 1,
  "codeError": "invalid org id: [10101]"
}

{
  "status": "ok",
  "pageNum": 1,
  "totalPages": 1,
  "maxResults": 1000,
  "totalResults": 0,
  "title": "HeadCount Upcoming Events",
  "link": "http://www.ticketfly.com/api/events/upcoming.json",
  "currPage": "http://www.ticketfly.com/api/events/upcoming.json?orgId=1001&fieldGroup=light",
  "prevPage": "",
  "nextPage": "",
  "org": {
    "id": 1001,
    "name": "HeadCount",
    "timeZone": "America/New_York",
    "promoter": false,
    "orgConfigEvent": {
      "enableCustomDomain": false,
      "customDomain": null
    }
  },
  "events": []


  Note:
  Requesting pageNum <= 0 results in a response for pageNum: 1.
  Requesting pageNum > totalPages results in an empty events list, but otherwise works.

}

 */

case class SearchResult(
    status: String,
    pageNum: Int,
    totalPages: Int,
    maxResults: Int,
    totalResults: Int,
    // title: String,
    // link: String,
    // currPage: String,
    // prevPage: String,
    // nextPage: String,
    // org: JsObject,
    events: List[JsObject]
)

object SearchResult {
  implicit val format: Format[SearchResult] = Json.format[SearchResult]
}
