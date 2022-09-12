package com.portl.test

import com.portl.admin.services.LocalDataService

class LocalDataServiceSpec extends PortlBaseTest {
  val service = injectorObj[LocalDataService]
  "LocalDataService" should {
    "load cities file" in {
      for {
        locations <- service.usCityLocations()
      } yield {
        locations must have length 307
      }
    }
  }
}
