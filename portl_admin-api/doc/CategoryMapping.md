# Category Mapping

This document describes how events from various data sources are mapped to PORTL categories.

## Eventbrite

Eventbrite classifies events with categories and subcategories. As of this writing, they define 197 subcategories across
21 categories. We map only two subcategories:

Yoga in the Sports & Fitness category is mapped to "Yoga".
Theatre in the Performing & Visual Arts category is mapped to "Theatre".

If the event doesn't match one of those subcategories, we then map based on its category:

Eventbrite subcategory|Eventbrite category        |PORTL category
----------------------|---------------------------|--------------
Yoga                  |Sports & Fitness           |Yoga
Theatre               |Performing & Visual Arts   |Theatre
-                     |Music                      |Music
-                     |Family & Education         |Family
-                     |Sports & Fitness           |Sports
-                     |Business & Professional    |Business
-                     |Food & Drink               |Food
-                     |Film, Media & Entertainment|Film
-                     |Fashion & Beauty           |Fashion
-                     |Community & Culture        |Community
-                     |Science & Technology       |Science
-                     |Travel & Outdoor           |Travel

Note that Eventbrite categories have `name`, `name_localized`, `short_name`, and `short_name_localized` values in
addition to an `id` and `resource_uri`. We map based on the `id` value, and the `name` is shown in the above table.

## Meetup

All events are categorized as "Community".

## Songkick

Songkick events have a `type` of either "Festival" or "Concert". We map as follows:

Songkick type|PORTL category
-------------|--------------
Festival     |Community
Concert      |Music

## Ticketfly

Ticketfly doesn't explicitly mark its events with a type. If an event's title contains "comedy", "sports", or "film"
(case insensitive), we use the corresponding PORTL category. All others are mapped to Music.

Ticketfly title contains (case insensitive)|PORTL category
-------------------------------------------|--------------
comedy                                     |Comedy
sports                                     |Sports
film                                       |Film
-                                          |Music

## Ticketmaster

Ticketmaster events are categorized in three levels of detail. A `classificationSegment` is a primary genre for an
entity (Music, Sports, Arts, etc). A `classificationGenre` is a secondary genre to further describe an entity (Rock,
Classical, Animation, etc). A `classificationSubGenre` is a tertiary genre for additional detail when describing an
entity (Alternative Rock, Ambient Pop, etc). Most events have all three values, with the broader classifications being
more common than the more specific ones.

We map Ticketmaster events to all categories where any "match string" contains any of the event's classification values
(case insensitive).

Match strings                                   |PORTL category
------------------------------------------------|--------------
music, music_event, conference, concert         | Music
family, home                                    | Family
sports, fitness                                 | Sports
business, workshop, work                        | Business
theater, theatre, perform                       | Theatre
comedy                                          | Comedy
food, drink                                     | Food
film, movie, entertainment                      | Film
yoga, health                                    | Yoga
fashion, beauty                                 | Fashion
other, nightlife, party, festival               | Community
science, technology, technique                  | Science
travel, outdoor                                 | Travel
museum                                          | Museum
