package com.portl.test

import com.portl.commons.models._
import play.api.libs.json._

class PortlSerializersSpec extends PortlBaseTest {

  "Portl model serializers" should {
    "serialize EventCategories" in {
      for {
        c <- EventCategory.values
      } yield c.mustBe(an[EventCategory])

      for {
        c <- EventCategory.values
      } yield Json.toJson(c).as[String] mustEqual c.toString

      Json.toJson(EventCategory.Music).as[String] mustEqual "Music"
    }

    "parse EventCategories" in {
      for {
        (s, c) <- EventCategory.namesToValuesMap
      } yield Json.parse(s""" "$s" """).as[EventCategory] mustBe c

      Json.parse("\"Music\"").as[EventCategory] mustBe EventCategory.Music
    }

    "serialize MarkupTypes" in {
      for {
        m <- MarkupType.values
      } yield Json.toJson(m).as[String] mustEqual m.toString
      succeed
    }

    "parse MarkupTypes" in {
      for {
        (s, m) <- MarkupType.namesToValuesMap
      } yield Json.parse(s""" "$s" """).as[MarkupType] mustBe m
      succeed
    }

    "serialize MarkupText" in {
      Json.toJson(MarkupText("foo", MarkupType.PlainText)) mustBe a[JsValue]
      Json.toJson(MarkupText("foo", MarkupType.PlainText)).toString mustBe a[String]
      Json
        .toJson(MarkupText("foo", MarkupType.PlainText))
        .toString mustEqual """{"value":"foo","markupType":"PlainText"}"""
    }

    "parse MarkupText" in {
      Json.parse(""" {"value":"foo","markupType":"PlainText"} """).as[MarkupText] mustEqual MarkupText(
        "foo",
        MarkupType.PlainText)
    }

    "(de)serialize Events" in {
      val event = TestObjects.storedEvent()
      val serialized = Json.toJson(event).toString
      Json.parse(serialized).as[StoredEvent] mustEqual event
    }
  }
}
