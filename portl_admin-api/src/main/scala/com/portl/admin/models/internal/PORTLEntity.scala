package com.portl.admin.models.internal
import com.portl.commons.models.SourceIdentifier

trait PORTLEntity {
  def externalId: SourceIdentifier
}
