
## Overview

We fetch all event data from ticketmaster by consuming their "feed" api. The app is currently built against the
[V1 api](https://developer.ticketmaster.com/products-and-docs/apis/discovery-feed/v1/).
[V2](https://developer.ticketmaster.com/products-and-docs/apis/discovery-feed/) is slated to become available 5/1/2018.

## V1 Feed API

    http://app.ticketmaster.com/dc/feeds/v1/events.json

This endpoint accepts a countryCode parameter in the querystring, which expects a 2-character code and defaults to "US".
It returns a single gzipped JSON file containing all events with that country code. Its structure is like this:

    {"events":[ ... ]}

Each object in the events array is a v1 event with this structure:

    {
      "eventId" : "G5diZsSggivjL",
      "legacyEventId" : "3B00533D15B0171F",
      "primaryEventUrl" : "http://www.ticketmaster.com/event/3B00533D15B0171F",
      "resaleEventUrl" : null,
      "eventName" : "St. John's v. Molloy",
      "eventInfo" : null,
      "eventNotes" : null,
      "eventStatus" : "onsale",
      "eventImageUrl" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_TABLET_LANDSCAPE_LARGE_16_9.jpg",
      "eventStartDateTime" : "2017-11-20T23:30:00Z",
      "eventStartLocalTime" : "18:30",
      "eventStartLocalDate" : "2017-11-20",
      "eventEndDateTime" : null,
      "venue" : {
        "venueName" : "Carnesecca Arena",
        "venueId" : "KovZpZAEAdFA",
        "legacyVenueId" : "483475",
        "venueUrl" : "http://www.ticketmaster.com/venue/483475",
        "venueTimezone" : "America/New_York",
        "venueZipCode" : "11439",
        "venueLatitude" : 40.72397929,
        "venueLongitude" : -73.79468334,
        "venueStreet" : "8000 Utopia Parkway",
        "venueCity" : "Queens",
        "venueStateCode" : "NY",
        "venueCountryCode" : "US"
      },
      "attractions" : [ {
        "attraction" : {
          "attractionUrl" : "http://www.ticketmaster.com/artist/844662",
          "attractionId" : "K8vZ9171LkV",
          "legacyAttractionId" : "844662",
          "attractionName" : "St. John's Red Storm Men's Basketball",
          "attractionImageUrl" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_TABLET_LANDSCAPE_LARGE_16_9.jpg",
          "images" : [ {
            "image" : {
              "ratio" : "16_9",
              "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_RECOMENDATION_16_9.jpg",
              "width" : 100,
              "height" : 56,
              "fallback" : false
            }
          }, {
            "image" : {
              "ratio" : "16_9",
              "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_RETINA_PORTRAIT_16_9.jpg",
              "width" : 640,
              "height" : 360,
              "fallback" : true
            }
          }, {
            "image" : {
              "ratio" : "16_9",
              "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_TABLET_LANDSCAPE_LARGE_16_9.jpg",
              "width" : 2048,
              "height" : 1152,
              "fallback" : false
            }
          }, {
            "image" : {
              "ratio" : "4_3",
              "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_CUSTOM.jpg",
              "width" : 305,
              "height" : 225,
              "fallback" : false
            }
          }, {
            "image" : {
              "ratio" : "16_9",
              "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_TABLET_LANDSCAPE_LARGE_16_9.jpg",
              "width" : 2048,
              "height" : 1152,
              "fallback" : true
            }
          }, {
            "image" : {
              "ratio" : "16_9",
              "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_RETINA_PORTRAIT_16_9.jpg",
              "width" : 640,
              "height" : 360,
              "fallback" : false
            }
          }, {
            "image" : {
              "ratio" : "3_2",
              "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_RETINA_PORTRAIT_3_2.jpg",
              "width" : 640,
              "height" : 427,
              "fallback" : false
            }
          }, {
            "image" : {
              "ratio" : "3_2",
              "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_ARTIST_PAGE_3_2.jpg",
              "width" : 305,
              "height" : 203,
              "fallback" : false
            }
          }, {
            "image" : {
              "ratio" : "16_9",
              "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_EVENT_DETAIL_PAGE_16_9.jpg",
              "width" : 205,
              "height" : 115,
              "fallback" : true
            }
          }, {
            "image" : {
              "ratio" : "16_9",
              "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_RETINA_LANDSCAPE_16_9.jpg",
              "width" : 1136,
              "height" : 639,
              "fallback" : true
            }
          }, {
            "image" : {
              "ratio" : "3_2",
              "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_RETINA_PORTRAIT_3_2.jpg",
              "width" : 640,
              "height" : 427,
              "fallback" : true
            }
          }, {
            "image" : {
              "ratio" : "16_9",
              "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_RECOMENDATION_16_9.jpg",
              "width" : 100,
              "height" : 56,
              "fallback" : true
            }
          }, {
            "image" : {
              "ratio" : "3_2",
              "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_TABLET_LANDSCAPE_3_2.jpg",
              "width" : 1024,
              "height" : 683,
              "fallback" : true
            }
          }, {
            "image" : {
              "ratio" : "3_2",
              "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_ARTIST_PAGE_3_2.jpg",
              "width" : 305,
              "height" : 203,
              "fallback" : true
           }
          }, {
            "image" : {
              "ratio" : "16_9",
              "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_TABLET_LANDSCAPE_16_9.jpg",
              "width" : 1024,
              "height" : 576,
              "fallback" : true
            }
          }, {
            "image" : {
              "ratio" : "16_9",
              "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_EVENT_DETAIL_PAGE_16_9.jpg",
              "width" : 205,
              "height" : 115,
              "fallback" : false
            }
          }, {
            "image" : {
              "ratio" : "16_9",
              "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_TABLET_LANDSCAPE_16_9.jpg",
              "width" : 1024,
              "height" : 576,
              "fallback" : false
            }
          }, {
            "image" : {
              "ratio" : "4_3",
              "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_CUSTOM.jpg",
              "width" : 305,
              "height" : 225,
              "fallback" : true
            }
          }, {
            "image" : {
              "ratio" : "16_9",
              "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_RETINA_LANDSCAPE_16_9.jpg",
              "width" : 1136,
              "height" : 639,
              "fallback" : false
            }
          }, {
            "image" : {
              "ratio" : "3_2",
              "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_TABLET_LANDSCAPE_3_2.jpg",
              "width" : 1024,
              "height" : 683,
              "fallback" : false
            }
          } ]
        "classificationSegmentId" : "KZFzniwnSyZfZ7v7na",
        "classificationSegment" : "Arts & Theatre",
        "classificationGenreId" : "KnvZfZ7v7nl",
        "classificationGenre" : "Fine Art",
        "classificationSubGenreId" : "KZazBEonSMnZfZ7v7ld",
        "classificationSubGenre" : "Fine Art",
        "classificationTypeId" : "KZAyXgnZfZ7v7lt",
        "classificationType" : "Event Style",
        "classificationSubTypeId" : "KZFzBErXgnZfZ7vA6I",
        "classificationSubType" : "Exhibit"
        }
      } ],
      "images" : [ {
        "image" : {
          "ratio" : "16_9",
          "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_RECOMENDATION_16_9.jpg",
          "width" : 100,
          "height" : 56,
          "fallback" : false
        }
      }, {
        "image" : {
          "ratio" : "16_9",
          "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_RETINA_PORTRAIT_16_9.jpg",
          "width" : 640,
          "height" : 360,
          "fallback" : true
        }
      }, {
        "image" : {
          "ratio" : "16_9",
          "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_TABLET_LANDSCAPE_LARGE_16_9.jpg",
          "width" : 2048,
          "height" : 1152,
          "fallback" : false
        }
      }, {
        "image" : {
          "ratio" : "4_3",
          "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_CUSTOM.jpg",
          "width" : 305,
          "height" : 225,
          "fallback" : false
        }
      }, {
        "image" : {
          "ratio" : "16_9",
          "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_TABLET_LANDSCAPE_LARGE_16_9.jpg",
          "width" : 2048,
          "height" : 1152,
          "fallback" : true
        }
      }, {
        "image" : {
          "ratio" : "16_9",
          "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_RETINA_PORTRAIT_16_9.jpg",
          "width" : 640,
          "height" : 360,
          "fallback" : false
        }
      }, {
        "image" : {
          "ratio" : "3_2",
          "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_RETINA_PORTRAIT_3_2.jpg",
          "width" : 640,
          "height" : 427,
          "fallback" : false
        }
      }, {
        "image" : {
          "ratio" : "3_2",
          "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_ARTIST_PAGE_3_2.jpg",
          "width" : 305,
          "height" : 203,
          "fallback" : false
        }
      }, {
        "image" : {
          "ratio" : "16_9",
          "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_EVENT_DETAIL_PAGE_16_9.jpg",
          "width" : 205,
          "height" : 115,
          "fallback" : true
        }
      }, {
        "image" : {
          "ratio" : "16_9",
          "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_RETINA_LANDSCAPE_16_9.jpg",
          "width" : 1136,
          "height" : 639,
          "fallback" : true
        }
      }, {
        "image" : {
          "ratio" : "16_9",
          "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_RECOMENDATION_16_9.jpg",
          "width" : 100,
          "height" : 56,
          "fallback" : true
        }
      }, {
        "image" : {
          "ratio" : "3_2",
          "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_RETINA_PORTRAIT_3_2.jpg",
          "width" : 640,
          "height" : 427,
          "fallback" : true
        }
      }, {
        "image" : {
          "ratio" : "3_2",
          "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_TABLET_LANDSCAPE_3_2.jpg",
          "width" : 1024,
          "height" : 683,
          "fallback" : true
        }
      }, {
        "image" : {
          "ratio" : "3_2",
          "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_ARTIST_PAGE_3_2.jpg",
          "width" : 305,
          "height" : 203,
          "fallback" : true
        }
      }, {
        "image" : {
          "ratio" : "16_9",
          "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_TABLET_LANDSCAPE_16_9.jpg",
          "width" : 1024,
          "height" : 576,
          "fallback" : true
        }
      }, {
        "image" : {
          "ratio" : "16_9",
          "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_EVENT_DETAIL_PAGE_16_9.jpg",
          "width" : 205,
          "height" : 115,
          "fallback" : false
        }
      }, {
        "image" : {
          "ratio" : "16_9",
          "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_TABLET_LANDSCAPE_16_9.jpg",
          "width" : 1024,
          "height" : 576,
          "fallback" : false
        }
      }, {
        "image" : {
          "ratio" : "4_3",
          "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_CUSTOM.jpg",
          "width" : 305,
          "height" : 225,
          "fallback" : true
        }
      }, {
        "image" : {
          "ratio" : "16_9",
          "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_RETINA_LANDSCAPE_16_9.jpg",
          "width" : 1136,
          "height" : 639,
          "fallback" : false
        }
      }, {
        "image" : {
          "ratio" : "3_2",
          "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_TABLET_LANDSCAPE_3_2.jpg",
          "width" : 1024,
          "height" : 683,
          "fallback" : false
        }
      } ],
      "minPrice" : "25.00",
      "maxPrice" : "35.00",
      "currency" : "USD",
      "onsaleStartDateTime" : "2017-10-09T14:00:00Z",
      "onsaleEndDateTime" : "2017-11-20T23:30:00Z",
      "classificationSegment" : "Sports",
      "classificationGenre" : "Basketball",
      "classificationSubGenre" : "College",
      "presaleName" : null,
      "presaleDateTimeRange" : null,
      "presales" : [ ],
      "source" : "ticketmaster",
      "classificationType" : "Group",
      "classificationSubType" : "Team"
    }
    
## V2 Feed API

The v2 api introduces an endpoint that lists the available countries and some metadata about their feed files.

    https://app.ticketmaster.com/discovery-feed/v2/events?apikey={apikey}
    
    {
        "countries": {
            "GB": {
                "csv": {
                    "compressed_md5_checksum": "81646a7364950775039f694b1ddd6c8a",
                    "compressed_size_bytes": 235745605,
                    "country_code": "GB",
                    "format": "csv",
                    "last_updated": "2018-04-04T19:22:12-07:00",
                    "num_events": 5710,
                    "uri": "https://feeds.ticketmaster.com/public/content/2018-04-03/fd73c66a-03e6-4f05-98ea-3b035f3a12fe/events-GB.csv.gz"
                },
                "json": {
                    "compressed_md5_checksum": "fa2fb061a510589bd86340eb68885042",
                    "compressed_size_bytes": 23784073201,
                    "country_code": "GB",
                    "format": "json",
                    "last_updated": "2018-04-04T19:22:14-07:00",
                    "num_events": 5710,
                    "uri": "https://feeds.ticketmaster.com/public/content/2018-04-03/fd73c66a-03e6-4f05-98ea-3b035f3a12fe/events-GB.json.gz"
                },
                "xml": {
                    "compressed_md5_checksum": "5a64a261a8633663a83818a266c3d4b5",
                    "compressed_size_bytes": 52307300414,
                    "country_code": "GB",
                    "format": "xml",
                    "last_updated": "2018-04-04T19:23:41-07:00",
                    "num_events": 5710,
                    "uri": "https://feeds.ticketmaster.com/public/content/2018-04-03/fd73c66a-03e6-4f05-98ea-3b035f3a12fe/events-GB.xml.gz"
                }
            },
            "US": {
                "csv": {
                    "compressed_md5_checksum": "d4f05dc25e50e2dbc71559141985951a",
                    "compressed_size_bytes": 5310932002,
                    "country_code": "US",
                    "format": "csv",
                    "last_updated": "2018-04-04T19:20:30-07:00",
                    "num_events": 12005,
                    "uri": "https://feeds.ticketmaster.com/public/content/2018-04-03/fd73c66a-03e6-4f05-98ea-3b035f3a12fe/events-US.csv.gz"
                },
                "json": {
                    "compressed_md5_checksum": "f4e9c612815ce89e20cbe2ae51069635",
                    "compressed_size_bytes": 39574789083,
                    "format": "json",
                    "last_updated": "2018-04-04T19:21:22-07:00",
                    "num_events": 12005,
                    "uri": "https://feeds.ticketmaster.com/public/content/2018-04-03/fd73c66a-03e6-4f05-98ea-3b035f3a12fe/events-US.json.gz"
                },
                "xml": {
                    "compressed_md5_checksum": "c3fdda22de4b12b33f6aff705b0f2a74",
                    "compressed_size_bytes": 73572338891,
                    "country_code": "US",
                    "format": "xml",
                    "last_updated": "2018-04-04T19:22:01-07:00",
                    "num_events": 12005,
                    "uri": "https://feeds.ticketmaster.com/public/content/2018-04-03/fd73c66a-03e6-4f05-98ea-3b035f3a12fe/events-US.xml.gz"
                }
            }
        }
    }
    
Following that call, we can then request the actual feed file:

    https://feeds.ticketmaster.com/public/content/2018-04-03/fd73c66a-03e6-4f05-98ea-3b035f3a12fe/events-GB.csv.gz

This also gives us the opportunity to test the last_updated date and avoid requesting the same feed again. The contents
of the feed file are the same as in the V1 api:

    {
      "eventId" : "G5diZsSggivjL",
      "legacyEventId" : "3B00533D15B0171F",
      "primaryEventUrl" : "http://www.ticketmaster.com/event/3B00533D15B0171F",
      "resaleEventUrl" : null,
      "eventName" : "St. John's v. Molloy",
      "eventInfo" : null,
      "eventNotes" : null,
      "eventStatus" : "onsale",
      "eventImageUrl" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_TABLET_LANDSCAPE_LARGE_16_9.jpg",
      "eventStartDateTime" : "2017-11-20T23:30:00Z",
      "eventStartLocalTime" : "18:30",
      "eventStartLocalDate" : "2017-11-20",
      "eventEndDateTime" : null,
      "venue" : {
        "venueName" : "Carnesecca Arena",
        "venueId" : "KovZpZAEAdFA",
        "legacyVenueId" : "483475",
        "venueUrl" : "http://www.ticketmaster.com/venue/483475",
        "venueTimezone" : "America/New_York",
        "venueZipCode" : "11439",
        "venueLatitude" : 40.72397929,
        "venueLongitude" : -73.79468334,
        "venueStreet" : "8000 Utopia Parkway",
        "venueCity" : "Queens",
        "venueStateCode" : "NY",
        "venueCountryCode" : "US"
      },
      "attractions" : [ {
        "attraction" : {
          "attractionUrl" : "http://www.ticketmaster.com/artist/844662",
          "attractionId" : "K8vZ9171LkV",
          "legacyAttractionId" : "844662",
          "attractionName" : "St. John's Red Storm Men's Basketball",
          "attractionImageUrl" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_TABLET_LANDSCAPE_LARGE_16_9.jpg",
          "images" : [ {
            "image" : {
              "ratio" : "16_9",
              "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_RECOMENDATION_16_9.jpg",
              "width" : 100,
              "height" : 56,
              "fallback" : false
            }
          }, {
            "image" : {
              "ratio" : "16_9",
              "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_RETINA_PORTRAIT_16_9.jpg",
              "width" : 640,
              "height" : 360,
              "fallback" : true
            }
          }, {
            "image" : {
              "ratio" : "16_9",
              "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_TABLET_LANDSCAPE_LARGE_16_9.jpg",
              "width" : 2048,
              "height" : 1152,
              "fallback" : false
            }
          }, {
            "image" : {
              "ratio" : "4_3",
              "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_CUSTOM.jpg",
              "width" : 305,
              "height" : 225,
              "fallback" : false
            }
          }, {
            "image" : {
              "ratio" : "16_9",
              "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_TABLET_LANDSCAPE_LARGE_16_9.jpg",
              "width" : 2048,
              "height" : 1152,
              "fallback" : true
            }
          }, {
            "image" : {
              "ratio" : "16_9",
              "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_RETINA_PORTRAIT_16_9.jpg",
              "width" : 640,
              "height" : 360,
              "fallback" : false
            }
          }, {
            "image" : {
              "ratio" : "3_2",
              "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_RETINA_PORTRAIT_3_2.jpg",
              "width" : 640,
              "height" : 427,
              "fallback" : false
            }
          }, {
            "image" : {
              "ratio" : "3_2",
              "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_ARTIST_PAGE_3_2.jpg",
              "width" : 305,
              "height" : 203,
              "fallback" : false
            }
          }, {
            "image" : {
              "ratio" : "16_9",
              "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_EVENT_DETAIL_PAGE_16_9.jpg",
              "width" : 205,
              "height" : 115,
              "fallback" : true
            }
          }, {
            "image" : {
              "ratio" : "16_9",
              "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_RETINA_LANDSCAPE_16_9.jpg",
              "width" : 1136,
              "height" : 639,
              "fallback" : true
            }
          }, {
            "image" : {
              "ratio" : "3_2",
              "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_RETINA_PORTRAIT_3_2.jpg",
              "width" : 640,
              "height" : 427,
              "fallback" : true
            }
          }, {
            "image" : {
              "ratio" : "16_9",
              "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_RECOMENDATION_16_9.jpg",
              "width" : 100,
              "height" : 56,
              "fallback" : true
            }
          }, {
            "image" : {
              "ratio" : "3_2",
              "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_TABLET_LANDSCAPE_3_2.jpg",
              "width" : 1024,
              "height" : 683,
              "fallback" : true
            }
          }, {
            "image" : {
              "ratio" : "3_2",
              "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_ARTIST_PAGE_3_2.jpg",
              "width" : 305,
              "height" : 203,
              "fallback" : true
           }
          }, {
            "image" : {
              "ratio" : "16_9",
              "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_TABLET_LANDSCAPE_16_9.jpg",
              "width" : 1024,
              "height" : 576,
              "fallback" : true
            }
          }, {
            "image" : {
              "ratio" : "16_9",
              "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_EVENT_DETAIL_PAGE_16_9.jpg",
              "width" : 205,
              "height" : 115,
              "fallback" : false
            }
          }, {
            "image" : {
              "ratio" : "16_9",
              "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_TABLET_LANDSCAPE_16_9.jpg",
              "width" : 1024,
              "height" : 576,
              "fallback" : false
            }
          }, {
            "image" : {
              "ratio" : "4_3",
              "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_CUSTOM.jpg",
              "width" : 305,
              "height" : 225,
              "fallback" : true
            }
          }, {
            "image" : {
              "ratio" : "16_9",
              "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_RETINA_LANDSCAPE_16_9.jpg",
              "width" : 1136,
              "height" : 639,
              "fallback" : false
            }
          }, {
            "image" : {
              "ratio" : "3_2",
              "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_TABLET_LANDSCAPE_3_2.jpg",
              "width" : 1024,
              "height" : 683,
              "fallback" : false
            }
          } ]
        "classificationSegmentId" : "KZFzniwnSyZfZ7v7na",
        "classificationSegment" : "Arts & Theatre",
        "classificationGenreId" : "KnvZfZ7v7nl",
        "classificationGenre" : "Fine Art",
        "classificationSubGenreId" : "KZazBEonSMnZfZ7v7ld",
        "classificationSubGenre" : "Fine Art",
        "classificationTypeId" : "KZAyXgnZfZ7v7lt",
        "classificationType" : "Event Style",
        "classificationSubTypeId" : "KZFzBErXgnZfZ7vA6I",
        "classificationSubType" : "Exhibit"
        }
      } ],
      "images" : [ {
        "image" : {
          "ratio" : "16_9",
          "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_RECOMENDATION_16_9.jpg",
          "width" : 100,
          "height" : 56,
          "fallback" : false
        }
      }, {
        "image" : {
          "ratio" : "16_9",
          "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_RETINA_PORTRAIT_16_9.jpg",
          "width" : 640,
          "height" : 360,
          "fallback" : true
        }
      }, {
        "image" : {
          "ratio" : "16_9",
          "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_TABLET_LANDSCAPE_LARGE_16_9.jpg",
          "width" : 2048,
          "height" : 1152,
          "fallback" : false
        }
      }, {
        "image" : {
          "ratio" : "4_3",
          "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_CUSTOM.jpg",
          "width" : 305,
          "height" : 225,
          "fallback" : false
        }
      }, {
        "image" : {
          "ratio" : "16_9",
          "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_TABLET_LANDSCAPE_LARGE_16_9.jpg",
          "width" : 2048,
          "height" : 1152,
          "fallback" : true
        }
      }, {
        "image" : {
          "ratio" : "16_9",
          "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_RETINA_PORTRAIT_16_9.jpg",
          "width" : 640,
          "height" : 360,
          "fallback" : false
        }
      }, {
        "image" : {
          "ratio" : "3_2",
          "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_RETINA_PORTRAIT_3_2.jpg",
          "width" : 640,
          "height" : 427,
          "fallback" : false
        }
      }, {
        "image" : {
          "ratio" : "3_2",
          "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_ARTIST_PAGE_3_2.jpg",
          "width" : 305,
          "height" : 203,
          "fallback" : false
        }
      }, {
        "image" : {
          "ratio" : "16_9",
          "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_EVENT_DETAIL_PAGE_16_9.jpg",
          "width" : 205,
          "height" : 115,
          "fallback" : true
        }
      }, {
        "image" : {
          "ratio" : "16_9",
          "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_RETINA_LANDSCAPE_16_9.jpg",
          "width" : 1136,
          "height" : 639,
          "fallback" : true
        }
      }, {
        "image" : {
          "ratio" : "16_9",
          "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_RECOMENDATION_16_9.jpg",
          "width" : 100,
          "height" : 56,
          "fallback" : true
        }
      }, {
        "image" : {
          "ratio" : "3_2",
          "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_RETINA_PORTRAIT_3_2.jpg",
          "width" : 640,
          "height" : 427,
          "fallback" : true
        }
      }, {
        "image" : {
          "ratio" : "3_2",
          "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_TABLET_LANDSCAPE_3_2.jpg",
          "width" : 1024,
          "height" : 683,
          "fallback" : true
        }
      }, {
        "image" : {
          "ratio" : "3_2",
          "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_ARTIST_PAGE_3_2.jpg",
          "width" : 305,
          "height" : 203,
          "fallback" : true
        }
      }, {
        "image" : {
          "ratio" : "16_9",
          "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_TABLET_LANDSCAPE_16_9.jpg",
          "width" : 1024,
          "height" : 576,
          "fallback" : true
        }
      }, {
        "image" : {
          "ratio" : "16_9",
          "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_EVENT_DETAIL_PAGE_16_9.jpg",
          "width" : 205,
          "height" : 115,
          "fallback" : false
        }
      }, {
        "image" : {
          "ratio" : "16_9",
          "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_TABLET_LANDSCAPE_16_9.jpg",
          "width" : 1024,
          "height" : 576,
          "fallback" : false
        }
      }, {
        "image" : {
          "ratio" : "4_3",
          "url" : "https://s1.ticketm.net/dam/c/8d5/f95bdd17-1d94-4e98-9295-641e4db558d5_105621_CUSTOM.jpg",
          "width" : 305,
          "height" : 225,
          "fallback" : true
        }
      }, {
        "image" : {
          "ratio" : "16_9",
          "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_RETINA_LANDSCAPE_16_9.jpg",
          "width" : 1136,
          "height" : 639,
          "fallback" : false
        }
      }, {
        "image" : {
          "ratio" : "3_2",
          "url" : "https://s1.ticketm.net/dam/a/ace/4173edef-6e4b-4677-8b45-d4fde6549ace_48141_TABLET_LANDSCAPE_3_2.jpg",
          "width" : 1024,
          "height" : 683,
          "fallback" : false
        }
      } ],
      "minPrice" : "25.00",
      "maxPrice" : "35.00",
      "currency" : "USD",
      "onsaleStartDateTime" : "2017-10-09T14:00:00Z",
      "onsaleEndDateTime" : "2017-11-20T23:30:00Z",
      "classificationSegment" : "Sports",
      "classificationGenre" : "Basketball",
      "classificationSubGenre" : "College",
      "presaleName" : null,
      "presaleDateTimeRange" : null,
      "presales" : [ ],
      "source" : "ticketmaster",
      "classificationType" : "Group",
      "classificationSubType" : "Team"
    }

## Datetime Handling

Ticketmaster provides event times in a few ways.

1. eventStartDateTime is an ISO-8601 datetime in UTC
2. eventStartLocalDate is "2018-05-03"
3. eventStartLocalTime is "18:30"
