package com.portl.admin

import akka.actor.ActorSystem

import scala.concurrent.duration.FiniteDuration

package object streams {
  def doWhile(fn: => Unit, predicate: => Boolean, period: FiniteDuration)(implicit sys: ActorSystem) {
    if (predicate) {
      fn
      sys.scheduler.scheduleOnce(period)(doWhile(fn, predicate, period))(sys.dispatcher)
    }
  }
}
