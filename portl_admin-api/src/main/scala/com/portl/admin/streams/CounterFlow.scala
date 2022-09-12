package com.portl.admin.streams

import java.util.concurrent.atomic.AtomicLong

import akka.stream.scaladsl.Flow
import akka.stream.{Attributes, FlowShape, Inlet, Outlet}
import akka.stream.stage.{GraphStageLogic, GraphStageWithMaterializedValue, InHandler, OutHandler}

// https://fatihcataltepe.github.io/akka-streams-counter-example/

trait Counter {
  def get: Long
  def reset()
}

final class CounterFlow[A] private () extends GraphStageWithMaterializedValue[FlowShape[A, A], Counter] {

  val in = Inlet[A]("Map.in")
  val out = Outlet[A]("Map.out")

  override val shape = FlowShape.of(in, out)

  override def createLogicAndMaterializedValue(attr: Attributes): (GraphStageLogic, Counter) = {
    val internalCounter = new AtomicLong(0)

    val logic = new GraphStageLogic(shape) {
      setHandler(in, new InHandler {
        override def onPush(): Unit = {
          internalCounter.incrementAndGet()
          push(out, grab(in))
        }
      })
      setHandler(out, new OutHandler {
        override def onPull(): Unit = {
          pull(in)
        }
      })
    }

    val counter = new Counter {
      override def get: Long = internalCounter.get()
      override def reset() = internalCounter.lazySet(0)
    }

    (logic, counter)
  }
}

object CounterFlow {
  def apply[T]: Flow[T, T, Counter] = {
    Flow.fromGraph(new CounterFlow[T]())
  }
}
