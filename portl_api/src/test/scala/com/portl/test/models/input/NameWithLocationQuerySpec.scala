package com.portl.test.models.input
import com.portl.api.models.input.{Location, NameWithLocationQuery}
import com.portl.test.PortlBaseTest
import play.api.libs.json.Json

class NameWithLocationQuerySpec extends PortlBaseTest {
  "NameWithLocationQuery" must {
    "parse input" in {
      val sampleInput =
        """
          |{"pageSize":10,"name":"amphitheater","location":{"lat":44.051569346200225,"lng":-123.09216074688713},"page":0}
        """.stripMargin
      val query = Json.parse(sampleInput).as[NameWithLocationQuery]
      query.pageSize must equal(10)
      query.page must equal(0)
      query.name must equal("amphitheater")
      query.location must contain(Location(-123.09216074688713, 44.051569346200225))
    }
  }
}
