package com.portl.admin.streams

import java.io.{InputStream, PushbackInputStream}
import java.nio.charset.{Charset, StandardCharsets}
import java.util.zip.GZIPInputStream

import akka.stream.Materializer
import akka.stream.scaladsl.{Source, StreamConverters}
import akka.util.ByteString
import com.fasterxml.jackson.core.io.JsonEOFException
import jawn.{AsyncParser, ParseException}
import jawn.support.play.Parser
import jawn.support.play.Parser._
import org.slf4j.LoggerFactory
import play.api.libs.json.{JsObject, JsValue, Json}
import enumeratum.{Enum, EnumEntry}

sealed abstract class ParserState extends EnumEntry

object ParserState extends Enum[ParserState] {
  val values = findValues
  case object New extends ParserState
  case object ReadyToStream extends ParserState
  case object Streaming extends ParserState
  case object DoneStreaming extends ParserState
  case object UsedUp extends ParserState
}

case class JSONFeed(source: Source[ByteString, _],
                    streamField: String,
                    encoding: Charset = StandardCharsets.UTF_8,
                    bufferSize: Int = 8192)(implicit materializer: Materializer) {
  // TODO : hard to debug when streamField key is wrong
  // TODO : improve to support multiple streamFields?
  private val log = LoggerFactory.getLogger(getClass)
  private val streamFieldRE = s"""(?s)(.*)"$streamField":(.*)""".r
  private val objectStartRE = """(?s)^(\{.*),?""".r

  // Limitations:
  // This is designed for the simple object responses we're getting from TM and SK feed endpoints. Something like:
  // {foo: 1, bar: 2, events: [ <long array of event objects> ]}
  // The streamField is located by regex - if it appears nested in some object that appears ahead of the actual target
  // streamField, that will throw us off.
  // If there are multiple huge arrays or huge objects, this probably won't work.
  // If streamField does not appear in the content, something bad will happen.
  // If streamField appears inside an array, it will stackOverflow.

  // Does the work of stream parsing the streamField.
  private val parser = Parser.async(AsyncParser.UnwrapArray)

  // Store what we've read so far from the underlying content stream.
  private var partialContent: Option[String] = None

  // Queue of values parsed from stream but not yet returned from `nextEvent()`.
  private var values: Seq[JsValue] = Seq()

  // Internal state determines how `nextEvent()` behaves.
  private var finishedStream = false
  private var state: ParserState = ParserState.New

  // Hold the underlying content.
  private val bytes = new Array[Byte](bufferSize)
  private val stream: InputStream = decompressStream(source.runWith(StreamConverters.asInputStream()))

  private def nextString(maxLength: Option[Int] = None): Option[String] = {
    val length = maxLength.getOrElse(bufferSize)
    val count = stream.read(bytes, 0, length)
    if (count > -1) {
      Some(new String(bytes, 0, count, encoding))
    } else {
      None
    }
  }

  private def decompressStream(input: InputStream): InputStream = {
    val pb = new PushbackInputStream(input, 2)
    //we need a pushbackstream to look ahead
    val signature = new Array[Byte](2)
    val len = pb.read(signature) //read the signature
    pb.unread(signature, 0, len) //push back the signature to the stream

    if (signature(0) == 0x1f.toByte && signature(1) == 0x8b.toByte) { //check if matches standard gzip magic number
      new GZIPInputStream(pb)
    } else pb
  }

  private def parseBeforeStreamField(content: String): JsObject = {
    // {"foo":"bar","baz": "quux", "some": 2,
    // {"foo":"bar","baz": {"quux":"oof", "some": 2,
    // {
    content match {
      case objectStartRE(v) =>
        val input = s"$v}"
        try {
          Json.parse(input).validate[JsObject].getOrElse(JsObject.empty)
        } catch {
          case _: JsonEOFException => parseBeforeStreamField(input)
        }
      case _ => JsObject.empty
    }
  }

  /**
    * Feed some more content into the parser.
    *
    * Feeds the content into the underlying parser. Handles recovery when the content extends past the events array.
    *
    * Returns the return value from the underlying parser call, plus any leftover content that was not ingested.
    *
    * If the returned string is not empty, we've gone past the end of the streamField array and this should not be
    * called again.
    */
  private def feedParser(content: String, depth: Int = 0): Seq[JsValue] = {
    val eofRE = """expected eof got (.).*""".r

    content
      .split("(?<=])")
      .map { c =>
        val parseResult = parser.absorb(c)
        parseResult match {
          case Right(js: Seq[JsValue]) =>
            Right(js)
          case Left(e: ParseException) =>
            e.msg match {
              case eofRE(_) =>
                // TODO : To support `valuesAfterStreamField`, hold onto the remaining contents at this point.
                finishedStream = true
                Right(Seq.empty[JsValue])
              case _ => throw e
            }
        }
      }
      .flatMap(_.value)
  }

  private def nextEvent(): Option[JsValue] = {
    if (state != ParserState.Streaming) throw new IllegalStateException(state.toString)
    values match {
      case result +: tail =>
        // If we have values in the queue, return one.
        values = tail
        Some(result)
      case _ =>
        if (finishedStream) {
          state = ParserState.DoneStreaming
          None
        } else {
          // Otherwise, process some more of the stream.
          partialContent match {
            case Some(read) =>
              // If we have some buffered content, send that through the parser and refill the buffer.
              val parseResult = feedParser(read)
              partialContent = nextString()
              parseResult match {
                case js: Seq[JsValue] if js.isEmpty =>
                  nextEvent()
                case js: Seq[JsValue] =>
                  values = js.tail
                  Some(js.head)
              }
            case None =>
              // We begin with some content in the buffer and refill each time we consume. If it's empty, we're done.
              state = ParserState.DoneStreaming
              None
          }
        }
    }
  }

  /**
    * Get a JsObject representing all content before the streamField in the json stream.
    *
    * Call this method first after constructing this object.
    *
    * @return JsObject
    */
  def valuesBeforeStreamField(): JsObject = {
    if (state != ParserState.New) throw new IllegalStateException(state.toString)
    val nextContent = nextString()
    partialContent = (partialContent, nextContent) match {
      case (None, None) => None
      case _            => Some(Seq(partialContent, nextContent).flatten.mkString(""))
    }
    partialContent match {
      case None => throw new IllegalStateException("empty input")
      case Some(c) =>
        c match {
          case streamFieldRE(before, after) =>
            state = ParserState.ReadyToStream
            partialContent = Some(after)
            parseBeforeStreamField(before)
          case _ => valuesBeforeStreamField()
        }
    }
  }

  /**
    * Get a source of the JsValues in the streamField array.
    *
    * Call this method after `valuesBeforeStreamField`.
    *
    * @return akka.stream.scaladsl.Source
    */
  def streamFieldContents(): Source[JsValue, _] = {
    if (state != ParserState.ReadyToStream) throw new IllegalStateException(state.toString)
    state = ParserState.Streaming
    Source.repeat(Unit).map(_ => nextEvent()).takeWhile(_.isDefined).map(_.get)
  }

  /**
    * Not Implemented
    *
    * Get a JsObject representing all content after the streamField in the json stream.
    *
    * Call this method after consuming the stream returned by `streamFieldContents`.
    *
    * @return JsObject
    */
  def valuesAfterStreamField(): JsObject = {
    if (state != ParserState.DoneStreaming) throw new IllegalStateException(state.toString)

    nextString() match {
      case None =>
        // Done consuming stream. Parse remaining content.
        // This can be tricky because the streamField may have been nested within a child object. If so, we've forgotten
        // the key path above it. For example:
        // {"a": true, "streamField": [<long>], "b": false}
        // {"a": true, "nest": {"streamField": [<long>], "b": false}}
        // {"a": true, "nest": {"streamField": [<long>]}, "b": false}
        // If the remaining content is `}, "b": false}`, we should probably return {"b": false}. If the remaining
        // content is `}, "b": false}}` though, we probably want to return {"?": {"b": false}} so the caller can merge
        // it with whatever was previously returned by `valuesBeforeStreamField`. We don't know the value of "?".
        //
        // A nice API for streaming object parsing might actually be to always track a current keypath, and yield
        // values along with their corresponding paths and types. Using the second example above, we might yield
        //  (None, Object, {"a": true, "nest": {}})
        //  ("nest.streamField", Array, Seq(<some objs>))
        //  ("nest.streamField", Array, Seq(<some objs>))
        //  ("nest.b", Value, false)
        // Just musings, not fully fleshed out.
        //
        // For now, this feature actually isn't required.
        ???
      case Some(nextContent) =>
        // Still getting content. Chew stream until empty.
        partialContent = Some(partialContent.getOrElse("") + nextContent)
        valuesAfterStreamField()
    }
  }
}
