package com.portl.commons.models.base

import com.portl.commons.models.SourceIdentifier
import org.joda.time.DateTime

trait StoredPortlEntity extends MongoObject {
  def externalId: SourceIdentifier
  def externalIdSet: Set[SourceIdentifier]
  def markedForDeletion: Option[DateTime]
}
