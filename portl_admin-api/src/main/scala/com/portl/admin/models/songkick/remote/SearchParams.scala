package com.portl.admin.models.songkick.remote

import com.portl.commons.models.Location

case class SearchParams(
    location: Location,
    page: Int = 1
)
