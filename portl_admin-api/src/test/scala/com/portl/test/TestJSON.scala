package com.portl.test

object TestJSON {
  val eventbriteEvent =
    """
      |{
      |	"name" : {
      |		"text" : "FREE WORKSHOP IN DALLAS!  How To Start Or Run A Small Business",
      |		"html" : "FREE WORKSHOP IN DALLAS!  How To Start Or Run A Small Business"
      |	},
      |	"description" : {
      |		"text" : "FREE 2 HOUR SMALL BUSINESS WORKSHOP\nIn cooperation with the Texas Wesleyan University ... ",
      |		"html" : "<H2><SPAN>FREE 2 HOUR </SPAN><SPAN>SMALL BUSINESS WORKSHOP</SPAN></H2> ... "
      |	},
      |	"id" : "45560436492",
      |	"url" : "https://www.eventbrite.com/e/free-workshop-in-dallas-how-to-start-or-run-a-small-business-tickets-45560436492",
      |	"start" : {
      |		"timezone" : "America/Chicago",
      |		"local" : "2018-07-21T09:30:00",
      |		"utc" : "2018-07-21T14:30:00Z"
      |	},
      |	"end" : {
      |		"timezone" : "America/Chicago",
      |		"local" : "2018-07-21T11:30:00",
      |		"utc" : "2018-07-21T16:30:00Z"
      |	},
      |	"organization_id" : "254337293156",
      |	"created" : "2018-04-26T16:28:10Z",
      |	"changed" : "2018-04-26T17:06:10Z",
      |	"capacity" : 100,
      |	"capacity_is_custom" : false,
      |	"status" : "live",
      |	"currency" : "USD",
      |	"listed" : true,
      |	"shareable" : true,
      |	"online_event" : false,
      |	"tx_time_limit" : 480,
      |	"hide_start_date" : false,
      |	"hide_end_date" : false,
      |	"locale" : "en_US",
      |	"is_locked" : false,
      |	"privacy_setting" : "unlocked",
      |	"is_series" : true,
      |	"is_series_parent" : false,
      |	"is_reserved_seating" : false,
      |	"source" : "create_2.0",
      |	"is_free" : true,
      |	"version" : "3.0.0",
      |	"logo_id" : "44082356",
      |	"organizer_id" : "17254295485",
      |	"venue_id" : "24484452",
      |	"category_id" : "101",
      |	"subcategory_id" : "1001",
      |	"format_id" : "9",
      |	"resource_uri" : "https://www.eventbriteapi.com/v3/events/45560436492/",
      |	"series_id" : "45560266985",
      |	"category" : {
      |		"resource_uri" : "https://www.eventbriteapi.com/v3/categories/101/",
      |		"id" : "101",
      |		"name" : "Business & Professional",
      |		"name_localized" : "Business & Professional",
      |		"short_name" : "Business",
      |		"short_name_localized" : "Business"
      |	},
      |	"logo" : {
      |		"crop_mask" : {
      |			"top_left" : {
      |				"x" : 0,
      |				"y" : 0
      |			},
      |			"width" : 2160,
      |			"height" : 1080
      |		},
      |		"original" : {
      |			"url" : "https://img.evbuc.com/https%3A%2F%2Fcdn.evbuc.com%2Fimages%2F44082356%2F254337293156%2F1%2Foriginal.jpg?auto=compress&s=249a377c3af6bb821c1ac31b0d40a87d",
      |			"width" : 2160,
      |			"height" : 1080
      |		},
      |		"id" : "44082356",
      |		"url" : "https://img.evbuc.com/https%3A%2F%2Fcdn.evbuc.com%2Fimages%2F44082356%2F254337293156%2F1%2Foriginal.jpg?h=200&w=450&auto=compress&rect=0%2C0%2C2160%2C1080&s=0e697425e8e97975457a19f7d967e0fe",
      |		"aspect_ratio" : "2",
      |		"edge_color" : "#ccbac0",
      |		"edge_color_set" : true
      |	},
      |	"venue" : {
      |		"address" : {
      |			"address_1" : "2727 N. Stemmons Freeway",
      |			"address_2" : null,
      |			"city" : "Dallas",
      |			"region" : "TX",
      |			"postal_code" : "75207",
      |			"country" : "US",
      |			"latitude" : "32.8077698",
      |			"longitude" : "-96.84485719999998",
      |			"localized_address_display" : "2727 N. Stemmons Freeway, Dallas, TX 75207",
      |			"localized_area_display" : "Dallas, TX",
      |			"localized_multi_line_address_display" : [
      |				"2727 N. Stemmons Freeway",
      |				"Dallas, TX 75207"
      |			]
      |		},
      |		"resource_uri" : "https://www.eventbriteapi.com/v3/venues/24484452/",
      |		"id" : "24484452",
      |		"age_restriction" : null,
      |		"capacity" : null,
      |		"name" : "Embassy Suites - Dallas Market Center",
      |		"latitude" : "32.8077698",
      |		"longitude" : "-96.84485719999998"
      |	}
      |}
    """.stripMargin

  val meetupEvent =
    """
      |{
      |  "utc_offset" : -18000000,
      |  "duration" : 18000000,
      |  "name" : "New Year's Day Hot Soup Ride",
      |  "description" : "<p>Tue January 1, 2019 - NEW YEAR'S DAY HO</p> <p>Level B-: 14mph, 54 miles. Meet at Upper Dublin High School. The ride leaves at 9:30 am. Special route from Upper Dublin High School to the Wegman's Food Court in Collegeville. Outbound via Blue Bell, East Norriton, and Eagleville, return via Oaks, Schuylkill River Trail, Norristown Farm Park, and Ambler. On the outbound, we have a quick rest stop for bathroom &amp; snack at a Wawa in East Norriton at mile 16. Indoor lunch stop at Wegman's is at mile 30. Most of the climbing is before the lunch stop. Total elevation gain is 2845 feet. The return includes a 5-mile stretch on the flat SRT. No one dropped, but we will try to maintain the advertised pace. SHORT-CUT OPTIONS AVAILABLE: Depending on the weather and riders' preferences, we can shave off some miles. Cue sheets will be available. The on-line route map is <a href=\"http://ridewithgps.com/routes/11594874\" class=\"linkified\">http://ridewithgps.com/routes/11594874</a>. It is optional, but you may preregister until Monday, December 31, 2018 at 11:59 pm.<br/>Leader: Linda McGrane, [masked],[masked]</p> ",
      |  "maybe_rsvp_count" : 0,
      |  "event_url" : "https://www.meetup.com/Delaware-Valley-Bicycle-Club-Greater-Philly-Area/events/257663398/",
      |  "payment_required" : "0",
      |  "rsvp_limit" : 0,
      |  "venue_visibility" : "public",
      |  "mtime" : 1546278199603,
      |  "id" : "257663398",
      |  "status" : "upcoming",
      |  "time" : 1546353000000,
      |  "yes_rsvp_count" : 0,
      |  "visibility" : "public",
      |  "group" : {
      |    "city" : "Swarthmore",
      |    "name" : "Delaware Valley Bicycle Club - Greater Philly Area",
      |    "state" : "PA",
      |    "urlname" : "Delaware-Valley-Bicycle-Club-Greater-Philly-Area",
      |    "group_lat" : 39.9,
      |    "country" : "us",
      |    "id" : 18561512,
      |    "join_mode" : "open",
      |    "category" : {
      |      "name" : "outdoors/adventure",
      |      "id" : 23,
      |      "shortname" : "outdoors-adventure"
      |    },
      |    "group_lon" : -75.34
      |  },
      |  "venue" : {
      |    "city" : "Fort Washington",
      |    "name" : "Upper Dublin High School",
      |    "zip" : "19034",
      |    "country" : "US",
      |    "lon" : -75.199501,
      |    "address_1" : "800 Loch Alsh Avenue",
      |    "lat" : 40.153233
      |  }
      |}
    """.stripMargin

  val songkickEvent =
    """
      |{
      |	"displayName" : "Ethan Ash at Private Show (August 10, 2018)",
      |	"popularity" : 0.000608,
      |	"location" : {
      |		"city" : "Fredericton, NB, Canada",
      |		"lat" : 45.9635895,
      |		"lng" : -66.6431151
      |	},
      |	"uri" : "http://www.songkick.com/concerts/34614994-ethan-ash-at-private-show",
      |	"id" : 34614994,
      |	"status" : "ok",
      |	"publicationTime" : "2018-07-13T09:56:37+0100",
      |	"type" : "Concert",
      |	"start" : {
      |		"datetime" : null,
      |		"time" : null,
      |		"date" : "2018-08-10"
      |	},
      |	"ageRestriction" : null,
      |	"performance" : [
      |		{
      |			"displayName" : "Ethan Ash",
      |			"billingIndex" : 1,
      |			"id" : 66387359,
      |			"artist" : {
      |				"displayName" : "Ethan Ash",
      |				"identifier" : [
      |					{
      |						"href" : "http://api.songkick.com/api/3.0/artists/mbid:439f8ac7-c848-49eb-967c-1c680305ef70.json",
      |						"mbid" : "439f8ac7-c848-49eb-967c-1c680305ef70"
      |					}
      |				],
      |				"uri" : "http://www.songkick.com/artists/3176961-ethan-ash",
      |				"id" : 3176961
      |			},
      |			"billing" : "headline"
      |		}
      |	],
      |	"venue" : {
      |		"displayName" : "Private Show",
      |		"lng" : -66.6431151,
      |		"uri" : "http://www.songkick.com/venues/3587799-private-show",
      |		"metroArea" : {
      |			"displayName" : "Fredericton",
      |			"state" : {
      |				"displayName" : "NB"
      |			},
      |			"uri" : "http://www.songkick.com/metro_areas/27363-canada-fredericton",
      |			"country" : {
      |				"displayName" : "Canada"
      |			},
      |			"id" : 27363
      |		},
      |		"id" : 3587799,
      |		"lat" : 45.9635895
      |	}
      |}
    """.stripMargin

  val ticketflyEvent =
    """
      |{
      |	"venue" : {
      |		"id" : 9199,
      |		"name" : "The Civic Theatre",
      |		"timeZone" : "America/Chicago",
      |		"address1" : "510 O'Keefe Ave",
      |		"address2" : "",
      |		"city" : "New Orleans",
      |		"stateProvince" : "LA",
      |		"postalCode" : "70113",
      |		"country" : "usa",
      |		"url" : "http://www.civicnola.com",
      |		"lat" : "29.942227",
      |		"lng" : "-90.081685"
      |	},
      |	"id" : 1724216,
      |	"name" : "Public Image LTD",
      |	"image" : [ ],
      |	"startDate" : "2018-10-09 20:00:00",
      |	"endDate" : null,
      |	"additionalInfo" : "<p>General Admission (access to standing room floor and seated balconies): $35 Advance | $40 Day of Show</p> \n<p>Premium Loge: $50 Advance | $55 Day of Show</p>",
      |	"showTypeCode" : null,
      |	"showType" : "",
      |	"ticketPurchaseUrl" : "https://www.ticketfly.com/purchase/event/1724216/tfly?utm_medium=api",
      |	"ticketPrice" : "$35 Advance | $40 Day of Show",
      |	"facebookEventId" : 497226444041888,
      |	"headliners" : [
      |		{
      |			"id" : 2162779,
      |			"name" : "Public Image LTD",
      |			"startTime" : null,
      |			"image" : {
      |				"original" : {
      |					"path" : "https://image-ticketfly.imgix.net/00/02/93/19/28-og.jpg?w=600&h=900",
      |					"width" : 600,
      |					"height" : 900
      |				},
      |				"xlarge" : {
      |					"path" : "https://image-ticketfly.imgix.net/00/02/93/19/28-og.jpg?w=500&h=750",
      |					"width" : 500,
      |					"height" : 750
      |				},
      |				"large" : {
      |					"path" : "https://image-ticketfly.imgix.net/00/02/93/19/28-og.jpg?w=300&h=450",
      |					"width" : 300,
      |					"height" : 450
      |				},
      |				"medium" : {
      |					"path" : "https://image-ticketfly.imgix.net/00/02/93/19/28-og.jpg?w=200&h=300",
      |					"width" : 200,
      |					"height" : 300
      |				},
      |				"small" : {
      |					"path" : "https://image-ticketfly.imgix.net/00/02/93/19/28-og.jpg?w=100&h=150",
      |					"width" : 100,
      |					"height" : 150
      |				},
      |				"xlarge1" : {
      |					"path" : "https://image-ticketfly.imgix.net/00/02/93/19/28-og.jpg?w=500&h=334&fit=crop&crop=top",
      |					"width" : 500,
      |					"height" : 334
      |				},
      |				"large1" : {
      |					"path" : "https://image-ticketfly.imgix.net/00/02/93/19/28-og.jpg?w=300&h=200&fit=crop&crop=top",
      |					"width" : 300,
      |					"height" : 200
      |				},
      |				"medium1" : {
      |					"path" : "https://image-ticketfly.imgix.net/00/02/93/19/28-og.jpg?w=200&h=133&fit=crop&crop=top",
      |					"width" : 200,
      |					"height" : 133
      |				},
      |				"small1" : {
      |					"path" : "https://image-ticketfly.imgix.net/00/02/93/19/28-og.jpg?w=100&h=67&fit=crop&crop=top",
      |					"width" : 100,
      |					"height" : 67
      |				},
      |				"square" : {
      |					"path" : "https://image-ticketfly.imgix.net/00/02/93/19/28-og.jpg?w=100&h=100&fit=crop&crop=top",
      |					"width" : 100,
      |					"height" : 100
      |				},
      |				"squareSmall" : {
      |					"path" : "https://image-ticketfly.imgix.net/00/02/93/19/28-og.jpg?w=60&h=60&fit=crop&crop=top",
      |					"width" : 60,
      |					"height" : 60
      |				}
      |			},
      |			"urlAudio" : "",
      |			"urlPurchaseMusic" : "",
      |			"urlOfficialWebsite" : "http://www.pilofficial.com/",
      |			"urlMySpace" : "",
      |			"urlFacebook" : "https://www.facebook.com/pilofficial/",
      |			"urlTwitter" : ""
      |		}
      |	],
      |	"urlEventDetailsUrl" : "http://www.civicnola.com/event/1724216?utm_medium=api"
      |}
    """.stripMargin

  val ticketmasterEvent =
    """
      |{
      |	"classificationGenre" : "Miscellaneous",
      |	"eventStartLocalDate" : "2019-03-08",
      |	"eventInfo" : null,
      |	"eventName" : "Tom Papa",
      |	"classificationSubGenreId" : "KZazBEonSMnZfZ7vF1k",
      |	"source" : "TMR",
      |	"classificationSegment" : "Arts & Theatre",
      |	"eventNotes" : null,
      |	"eventStartLocalTime" : "20:00",
      |	"classificationSubGenre" : "Miscellaneous",
      |	"primaryEventUrl" : "http://www.ticketsnow.com/InventoryBrowse/TicketList.aspx?PID=2382476",
      |	"classificationTypeId" : null,
      |	"eventStartDateTime" : "2019-03-09T02:00:00Z",
      |	"classificationSegmentId" : "KZFzniwnSyZfZ7v7na",
      |	"eventImageUrl" : "",
      |	"presales" : [ ],
      |	"onsaleStartDateTime" : "1900-01-01T06:00:00Z",
      |	"eventId" : "Z7r9jZ1AeCeoU",
      |	"legacyEventId" : null,
      |	"classificationSubType" : null,
      |	"eventStatus" : "rescheduled",
      |	"classificationGenreId" : "KnvZfZ7v7le",
      |	"resaleEventUrl" : null,
      |	"presaleDateTimeRange" : null,
      |	"eventEndDateTime" : null,
      |	"promoters" : [ ],
      |	"maxPrice" : null,
      |	"currency" : null,
      |	"classificationSubTypeId" : null,
      |	"onsaleEndDateTime" : "2019-03-09T02:00:00Z",
      |	"attractions" : [
      |		{
      |			"attraction" : {
      |				"classificationGenre" : "Miscellaneous",
      |				"attractionImageUrl" : "https://s1.ticketm.net/dam/c/24c/899de986-3c0e-4028-aa73-ea977a0db24c_124741_TABLET_LANDSCAPE_LARGE_16_9.jpg",
      |				"classificationSubGenreId" : "KZazBEonSMnZfZ7vF1k",
      |				"classificationSegment" : "Arts & Theatre",
      |				"legacyAttractionId" : null,
      |				"classificationSubGenre" : "Miscellaneous",
      |				"classificationTypeId" : null,
      |				"classificationSegmentId" : "KZFzniwnSyZfZ7v7na",
      |				"attractionUrl" : null,
      |				"classificationSubType" : null,
      |				"attractionName" : "Tom Papa",
      |				"classificationGenreId" : "KnvZfZ7v7le",
      |				"classificationSubTypeId" : null,
      |				"attractionId" : "Z7r9jZaAOP",
      |				"images" : [ ],
      |				"classificationType" : null
      |			}
      |		}
      |	],
      |	"images" : [ ],
      |	"presaleName" : null,
      |	"classificationType" : null,
      |	"minPrice" : null,
      |	"venue" : {
      |		"venueLongitude" : -96.8507,
      |		"venueCountryCode" : "US",
      |		"venueStreet" : "314 Broadway N",
      |		"venueCity" : "Fargo",
      |		"venueZipCode" : "58102",
      |		"venueId" : "Z6r9jZkA7e",
      |		"venueUrl" : null,
      |		"venueLatitude" : 46.9259,
      |		"venueName" : "Fargo Theatre",
      |		"venueTimezone" : "America/Chicago",
      |		"legacyVenueId" : null,
      |		"venueStateCode" : "ND"
      |	}
      |}
    """.stripMargin

  val portlAdminEvent =
    """
      |{
      |    "artistId": "5bd177c3-2294-a3f2-5e24-263b601a6b51",
      |    "categories": [
      |        "Music"
      |    ],
      |    "category": "Music",
      |    "description": "",
      |    "endDateTime": 1540406700000,
      |    "id": "78fe5378-b7d5-a790-9c91-63718facb7e5",
      |    "imageUrl": "",
      |    "startDateTime": 1540404900000,
      |    "timezone": "America/Los_Angeles",
      |    "ticketPurchaseUrl": "",
      |    "title": "Rockin' Show",
      |    "url": "",
      |    "venueId": "181040a3-e7cb-3f6e-777d-767c4ea0b834"
      |}
    """.stripMargin

  val portlAdminVenue =
    """
      |{
      |    "id": "181040a3-e7cb-3f6e-777d-767c4ea0b834",
      |    "location": {
      |        "lat": 44.05,
      |        "lng": -123.56
      |    },
      |    "address": {
      |        "street": "1045 Willamette St.",
      |        "street2": "Sweet Suite",
      |        "city": "Eugene",
      |        "state": "Oregon",
      |        "country": "United States",
      |        "zipCode": "97401"
      |    },
      |    "name": "Austin Lally",
      |    "url": "https://concentricsky.com"
      |}
    """.stripMargin

  val portlAdminArtist =
    """
      |{
      |    "description": "Some heavy stuff...",
      |    "id": "5bd177c3-2294-a3f2-5e24-263b601a6b51",
      |    "imageUrl": "https://images.google.com/deathbloom.png",
      |    "name": "Deathbloom",
      |    "url": "https://deathbloom.myspace.com"
      |}
    """.stripMargin

  val bandsintownArtist =
    """
      |{
      |	"thumb_url" : "https://s3.amazonaws.com/bit-photos/thumb/8554397.jpeg",
      |	"mbid" : "",
      |	"facebook_page_url" : "https://www.facebook.com/killymusic/",
      |	"image_url" : "https://s3.amazonaws.com/bit-photos/large/8554397.jpeg",
      |	"name" : "Killy",
      |	"id" : "2217649",
      |	"tracker_count" : 8359,
      |	"upcoming_event_count" : 3,
      |	"url" : "https://www.bandsintown.com/a/2217649?came_from=267&app_id=e7fbdfa5dcc08b782cb50042ed870f1c"
      |}
    """.stripMargin

  val bandsintownEvent =
    """
    |{
    |	"offers" : [
    |		{
    |			"type" : "Tickets",
    |			"url" : "https://www.bandsintown.com/t/1012682766?app_id=e7fbdfa5dcc08b782cb50042ed870f1c&came_from=267&utm_medium=api&utm_source=public_api&utm_campaign=ticket",
    |			"status" : "available"
    |		}
    |	],
    |	"venue" : {
    |		"name" : "Soho Studios",
    |		"country" : "United States",
    |		"region" : "FL",
    |		"city" : "Miami",
    |		"latitude" : "25.7969332",
    |		"longitude" : "-80.1969133"
    |	},
    |	"datetime" : "2018-12-07T21:00:00",
    |	"on_sale_datetime" : "",
    |	"description" : "JUICE WRLD at Soho Studios",
    |	"lineup" : [
    |		"Killy"
    |	],
    |	"id" : "1012682766",
    |	"artist_id" : "2217649",
    |	"url" : "https://www.bandsintown.com/e/1012682766?app_id=e7fbdfa5dcc08b782cb50042ed870f1c&came_from=267&utm_medium=api&utm_source=public_api&utm_campaign=event"
    |}
  """.stripMargin

  val bandsintownArtistDescription =
    """
      |{
      |	"artistId" : "2217649",
      |	"text" : "This is a cool artist!"
      |}
    """.stripMargin
}
