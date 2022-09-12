package com.portl.admin.services
import java.io.File
import java.util.{Date, UUID}

import com.portl.admin.models.portlAdmin.FileUploadConfig
import javax.inject.Inject
import play.api.Configuration
import play.api.libs.ws.WSClient
import awscala._
import com.amazonaws.HttpMethod
import org.slf4j.{Logger, LoggerFactory}
import s3._

import scala.concurrent.{ExecutionContext, Future}
import scala.concurrent.duration._

class FileUploadService @Inject()(configuration: Configuration, wsClient: WSClient, implicit val executionContext: ExecutionContext) {
  val S3_MEDIA_PREFIX: String = "media"
  val S3_URL_LIFESPAN_MILLIS: Int = 1.minute.toMillis.toInt

  val publicBaseURL: String = configuration.get[String]("cloudfront.baseUrl")
  val bucketName: String = configuration.get[String]("s3.bucketName")
  val bucketRegion: String = configuration.get[String]("s3.region")
  private val s3 = S3.at(Region(bucketRegion))

  lazy val log: Logger = LoggerFactory.getLogger(getClass)

  def createFileUploadConfig(filename: String): FileUploadConfig = {
    val uuid = UUID.randomUUID()
    val key = s"$S3_MEDIA_PREFIX/$uuid/$filename"
    val expiration = new Date
    expiration.setTime(expiration.getTime + S3_URL_LIFESPAN_MILLIS)

    val signedURL = s3.generatePresignedUrl(bucketName, key, expiration, HttpMethod.PUT)

    FileUploadConfig(
      signedURL.toString,
      s"$publicBaseURL/$key"
    )
  }

  def isPortlUrl(url: String): Boolean = url.startsWith(publicBaseURL)

  def uploadFile(file: File, filename: String): Future[String] = {
    val uuid = UUID.randomUUID()
    val key = s"$S3_MEDIA_PREFIX/$uuid/$filename"

    log.info(s"upload file $file as $key")
    Future(s3.putObject(bucketName, key, file))
      .map(_ => s"$publicBaseURL/$key")
  }
}
