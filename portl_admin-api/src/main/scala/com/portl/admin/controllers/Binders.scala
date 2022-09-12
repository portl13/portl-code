package com.portl.admin.controllers
import com.portl.commons.models.EventSource
import play.api.mvc.PathBindable

object Binders {
  implicit def eventSourcePathBinder(implicit stringBinder: PathBindable[String]): PathBindable[EventSource] =
    new PathBindable[EventSource] {
      import EventSource._
      val pairs = Seq(
        "ps" -> PortlServer,
        "bt" -> Bandsintown,
        "eb" -> Eventbrite,
        "mu" -> Meetup,
        "sk" -> Songkick,
        "tf" -> Ticketfly,
        "tm" -> Ticketmaster
      )
      val map: Map[String, EventSource] = pairs.toMap
      val reverseMap: Map[EventSource, String] = pairs.map(_.swap).toMap

      override def bind(key: String, value: String): Either[String, EventSource] = {
        for {
          str <- stringBinder.bind(key, value).right
          eventSource <- map.get(str).toRight(s"EventSource not supported: $str").right
        } yield eventSource
      }
      override def unbind(key: String, eventSource: EventSource): String = {
        reverseMap(eventSource)
      }
    }
}
