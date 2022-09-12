package com.portl.admin.actors

import com.portl.commons.models.EventSource

object SharedMessages {
  // messages
  case object Start
  case object Stop
  case object QueryStatus

  final case class Start(eventSource: EventSource)
  final case class Stop(eventSource: EventSource)
  final case class QueryStatus(eventSource: EventSource)

  final case class QueryNextTrigger(eventSource: EventSource)

  // KillSwitch poison pill
  case object IntentionallyStoppedException extends Exception
}
