package com.portl.test

import com.portl.admin.models.internal
import com.portl.commons
import com.portl.commons.models
import com.portl.commons.models.{Address, EventSource, Location, MarkupText, MarkupType, SourceIdentifier}
import com.portl.commons.models.base.MongoObjectId
import org.joda.time.{DateTime, DateTimeZone}

/**
  * Helpers for creating objects for use in test cases.
  * @author Kahli Burke
  */
object TestObjects {

  def artist() = {
    internal.Artist(
      SourceIdentifier(EventSource.Eventbrite, MongoObjectId.generate.toString),
      "Test Artist",
      Some("https://artist.com/"),
      "https://images.com/image.png",
      Some(MarkupText("This is a description of a performer", MarkupType.PlainText))
    )
  }

  def storedArtist() = {
    val id = SourceIdentifier(EventSource.Eventbrite, MongoObjectId.generate.toString)
    commons.models.StoredArtist(
      MongoObjectId.generate,
      id,
      Set(id),
      "Test Artist",
      Some("https://artist.com/"),
      "https://images.com/image.png",
      Some(MarkupText("This is a description of a performer", MarkupType.PlainText)),
      None
    )
  }

  def venue() = {
    internal.Venue(
      SourceIdentifier(EventSource.Eventbrite, MongoObjectId.generate.toString),
      Some("A Venue"),
      Location(-123.45, 45.67),
      Address(Some("The Address"), None, None, None, None, None),
      Some("https://example.com")
    )
  }

  def storedVenue() = {
    val id = SourceIdentifier(EventSource.Eventbrite, MongoObjectId.generate.toString)
    commons.models.StoredVenue(
      MongoObjectId.generate,
      id,
      Set(id),
      Some("A Venue"),
      Location(-123.45, 45.67),
      Address(Some("The Address"), None, None, None, None, None),
      Some("https://example.com"),
      None
    )
  }

  def event() = {
    val start = DateTime.now(DateTimeZone.UTC)
    internal.Event(
      SourceIdentifier(EventSource.Eventbrite, MongoObjectId.generate.toString),
      "Sample Event",
      None,
      Some(
        MarkupText(
          "Some descriptive iosEvent text here",
          MarkupType.PlainText
        )),
      start,
      None,
      "America/Los_Angeles",
      Seq(),
      venue(),
      Some(artist()),
      Some("http://example.com/events/this-iosEvent/"),
      Some("http://example.com/tickets/buy/this-iosEvent"),
      start.toString(internal.Event.localDateFormat)
    )
  }

  def storedEvent() = {
    val start = DateTime.now(DateTimeZone.UTC)
    val id = SourceIdentifier(EventSource.Eventbrite, MongoObjectId.generate.toString)
    commons.models.StoredEvent(
      MongoObjectId.generate,
      id,
      Set(id),
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
      start.toString(internal.Event.localDateFormat),
      None
    )
  }
}

object PresetLocations {
  val eugene = models.Location(-123.1001726, 44.0484724)
  val concentricSky = Location(-123.092592, 44.048362)
  val eugenePublicLibrary = Location(-123.0949563, 44.0485283)
  val portland = models.Location(-122.7945061, 45.5435634)
  val seattle = models.Location(-122.4821482, 47.6131746)
  val sanfrancisco = models.Location(-122.5076402, 37.757815)
}
