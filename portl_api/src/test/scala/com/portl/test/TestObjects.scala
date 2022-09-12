package com.portl.test

import com.portl.commons.models._
import com.portl.commons.models.base.MongoObjectId
import org.joda.time.{DateTime, DateTimeZone}

/**
  * Helpers for creating objects for use in test cases.
  * @author Kahli Burke
  */
object TestObjects {

  def storedArtist() = {
    val sourceId = SourceIdentifier(EventSource.Eventbrite, MongoObjectId.generate.toString)
    StoredArtist(
      MongoObjectId.generate,
      sourceId,
      Set(sourceId),
      "Test Artist",
      Some("https://artist.com/"),
      "https://images.com/image.png",
      Some(MarkupText("This is a description of a performer", MarkupType.PlainText)),
      None
    )
  }

  def storedVenue() = {
    val sourceId = SourceIdentifier(EventSource.Eventbrite, MongoObjectId.generate.toString)
    StoredVenue(
      MongoObjectId.generate,
      sourceId,
      Set(sourceId),
      Some("A Venue"),
      Location(-123.45, 45.67),
      Address(Some("The Address"), None, None, None, None, None),
      Some("https://example.com"),
      None
    )
  }

  def storedEvent() = {
    val start = DateTime.now(DateTimeZone.UTC)
    val sourceId = SourceIdentifier(EventSource.Eventbrite, MongoObjectId.generate.toString)
    StoredEvent(
      MongoObjectId.generate,
      sourceId,
      Set(sourceId),
      "Sample Event",
      None,
      Some(
        MarkupText(
          "Some descriptive iosEvent text here",
          MarkupType.PlainText
        )),
      start,
      None,
      Seq(),
      storedVenue(),
      Some(storedArtist()),
      Some("http://example.com/events/this-iosEvent/"),
      Some("http://example.com/tickets/buy/this-iosEvent"),
      None,
      start.toString("yyyy-MM-dd"),
      None
    )
  }
}
