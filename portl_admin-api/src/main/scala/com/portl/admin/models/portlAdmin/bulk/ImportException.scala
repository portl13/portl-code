package com.portl.admin.models.portlAdmin.bulk

final case class ImportException(private val message: String = "", private val cause: Throwable = None.orNull)
    extends Exception(message, cause)
