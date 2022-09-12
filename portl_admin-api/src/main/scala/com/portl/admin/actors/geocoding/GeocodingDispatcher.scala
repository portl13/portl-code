package com.portl.admin.actors.geocoding

import akka.actor.{Actor, ActorLogging, ActorRef, PoisonPill}
import com.portl.admin.models.internal.Venue

object GeocodingDispatcher {
  sealed trait Direction
  case object Forward extends Direction
  case object Reverse extends Direction

}

class GeocodingDispatcher[R](throttler: ActorRef, direction: GeocodingDispatcher.Direction) extends Actor with ActorLogging {
  import GeocodingDispatcher._

  var replyTo: Option[ActorRef] = None

  def request(v: Venue): Geocoder.Message = direction match {
    case Forward =>
      Geocoder.ForwardGeocodeRequest(self, v)
    case Reverse =>
      Geocoder.ReverseGeocodeRequest(self, v)
  }

  override def receive: Receive = {
    case v: Venue =>
      replyTo = Some(sender)
      throttler ! request(v)
    case result: Option[R] =>
      replyTo.foreach(_ ! result)
      self ! PoisonPill
  }
}
