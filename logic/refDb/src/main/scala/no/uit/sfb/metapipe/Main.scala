package no.uit.sfb.metapipe

import com.typesafe.scalalogging.LazyLogging
import scopt.OParser

import scala.util.control.NonFatal

object Main extends App with LazyLogging {
  try {
    OParser.parse(PackagesParser.parser, args, PackagesConfig()) match {
      case Some(config) => PackageActions(config)
      case _            => throw new IllegalArgumentException()
    }
  } catch {
    case NonFatal(e) =>
      println(e.toString)
      println(e.printStackTrace())
      sys.exit(1)
  }
}
