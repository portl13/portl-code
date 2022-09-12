package com.portl.admin.models.eventbrite

import ai.x.play.json.Jsonx
import com.portl.admin.models.internal
import com.portl.admin.models.internal.MapsToPortlEntity
import play.api.libs.json._
import com.portl.commons.models.EventCategory._
import com.portl.commons.models.{EventCategory, EventSource, SourceIdentifier}
import org.joda.time

case class Event(
    name: RichText,
    description: RichText,
    id: String,
    url: String,
    //vanity_url: Option[String],
    start: DateTime,
    end: Option[DateTime],
    //created: String,
    //changed: String,
    //capacity: Int,
    //capacity_is_custom: Boolean,
    //status: String,
    //currency: String,
    //listed: Boolean,
    //shareable: Boolean,
    //online_event: Boolean,
    //tx_time_limit: Option[Int],
    //hide_start_date: Option[Boolean],
    //hide_end_date: Option[Boolean],
    //locale: String,
    //is_locked: Boolean,
    //privacy_setting: String,
    //is_series: Boolean,
    //is_series_parent: Boolean,
    //is_reserved_seating: Boolean,
    //source: Option[String],
    //is_free: Boolean,
    //version: String,
    //logo_id: Option[String],
    //organizer_id: String,
    //venue_id: String,
    category_id: Option[String],
    subcategory_id: Option[String],
    //format_id: Option[String],
    //resource_uri: String,
    logo: Option[Logo],
    venue: Venue,
    //category: Option[Category]
) extends MapsToPortlEntity[internal.Event] {
  override def toPortl: internal.Event = {
    internal.Event(
      SourceIdentifier(EventSource.Eventbrite, id),
      name,
      logo.map(_.url),
      description,
      time.DateTime.parse(start.utc),
      end.map(d => time.DateTime.parse(d.utc)),
      start.timezone,
      Seq(this.eventCategory),
      this.venue.toPortl,
      None,
      Some(url),
      Some(url), // TODO: Change this?
      time.DateTime.parse(start.local).toString(internal.Event.localDateFormat)
    )
  }

  def eventCategory: EventCategory = {
    subcategory_id.orNull match {
      case "8019" => return Yoga
      case "5001" => return Theatre
      case _      =>
    }

    category_id.orNull match {
      case "103" => Music
      case "115" => Family // NOTE: EB lists this as "Family & Education"
      case "108" => Sports
      case "101" => Business
      case "110" => Food
      case "104" => Film
      case "106" => Fashion
      case "113" => Community
      case "102" => Science
      case "109" => Travel
      case _     =>
        // TODO: Log here about this category and subcategory
        Other
    }
  }
}

object Event {
  // NOTE: Jsonx is used here due to the limit of 22 parameters for a case class
  implicit val eventFormat: OFormat[Event] = Jsonx.formatCaseClass[Event]
}
