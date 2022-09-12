package com.portl.commons.futures

import scala.concurrent.{ExecutionContext, Future}

/**
  * Utilities for Futures.
  * @author Kahli Burke
  */
object FutureHelpers {
  def executeSequentially[Input, Output](items: Iterable[Input])(
      fn: Input => Future[Output])(
      implicit ec: ExecutionContext): Future[List[Output]] = {
    var fAccum = Future[List[Output]] { Nil }
    for (item <- items) {
      fAccum = fAccum flatMap { results =>
        fn(item) map { result =>
          result :: results
        }
      }
    }
    fAccum map (_.reverse)
  }

  def traverseOption[T, O](opt: Option[O])(f: O => Future[T])(
      implicit executionContext: ExecutionContext): Future[Option[T]] = {
    opt match {
      case Some(o) => f(o) map (Some(_))
      case None    => Future.successful(None)
    }
  }

  def traverseOptionFlat[T, O](opt: Option[O])(f: O => Future[Option[T]])(
      implicit executionContext: ExecutionContext): Future[Option[T]] =
    traverseOption(opt)(f)(executionContext).map(_.flatten)
}
