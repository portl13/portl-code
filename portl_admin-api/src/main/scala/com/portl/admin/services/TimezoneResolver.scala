package com.portl.admin.services
import java.util.TimeZone

import com.portl.commons.models.Location
import javax.inject.Singleton
import net.iakovlev.timeshape.TimeZoneEngine
import org.joda.time.DateTimeZone

@Singleton
class TimezoneResolver {
  private val timezoneEngine: TimeZoneEngine = TimeZoneEngine.initialize

  def getTimezone(location: Location): Option[DateTimeZone] = {
    val optional = timezoneEngine
      .query(location.latitude, location.longitude)
    val option = if (optional.isPresent) Some(optional.get) else None
    option.map(zoneId => DateTimeZone.forTimeZone(TimeZone.getTimeZone(zoneId)))
  }
}
