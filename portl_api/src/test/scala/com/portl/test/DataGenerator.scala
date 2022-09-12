package com.portl.test

import com.portl.commons
import com.portl.commons.models.base.MongoObjectId
import org.joda.time.DateTime

import scala.util.Random

trait DataGenerator {
  object presetLocations {
    val eugene = commons.models.Location(-123.1001726, 44.0484724)
    val portland = commons.models.Location(-122.7945061, 45.5435634)
    val seattle = commons.models.Location(-122.4821482, 47.6131746)
    val sanfrancisco = commons.models.Location(-122.5076402, 37.757815)
  }

  def randomString: String = Random.alphanumeric.take(10).mkString

  def randomIdentifier: commons.models.SourceIdentifier =
    commons.models.SourceIdentifier(
      commons.models.EventSource.values(Random.nextInt(commons.models.EventSource.values.length)),
      randomString
    )

  def createEventAt(location: commons.models.Location, startTime: DateTime): commons.models.StoredEvent = {
    val sourceId = randomIdentifier
    val venueId = randomIdentifier
    commons.models.StoredEvent(
      MongoObjectId.generate,
      sourceId,
      Set(sourceId),
      randomString,
      None,
      None,
      startTime,
      None,
      Seq(),
      commons.models.StoredVenue(
        MongoObjectId.generate,
        venueId,
        Set(venueId),
        Some(randomString),
        location,
        commons.models.Address(None, None, None, None, None, None),
        None,
        None
      ),
      None,
      None,
      None,
      None,
      startTime.toString("yyyy-MM-dd"),
      None
    )
  }
}
