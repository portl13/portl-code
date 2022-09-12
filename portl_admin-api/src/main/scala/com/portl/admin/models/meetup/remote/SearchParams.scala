package com.portl.admin.models.meetup.remote

import com.portl.commons.models.Location

case class SearchParams (
  location: Location,
  offset: Int = 0
)
