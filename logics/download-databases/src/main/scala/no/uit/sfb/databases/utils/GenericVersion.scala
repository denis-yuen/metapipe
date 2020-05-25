package no.uit.sfb.databases.utils

import scala.util.Try

/**
  * Add ordering to versions of type X.Y.Z. ...
  * If X1 and X2 are integers, they are compared as integers
  * If not, they are compared lexicographically as string.
  * If the two versions do not have the same length, empty string is used to fill the missing items
  */
object GenericVersion extends Ordering[String] {
  def compare(v1: String, v2: String): Int = {
    val splt1 = v1.split('.')
    val splt2 = v2.split('.')
    splt1
      .zipAll(splt2, "", "")
      .foldLeft(0)((acc, couple) => {
        if (acc != 0)
          acc
        else if (couple._1 == couple._2)
          0
        else {
          Try {
            (couple._1.toInt, couple._2.toInt)
          }.toOption match {
            case Some((i1, i2)) => Ordering[Int].compare(i1, i2)
            case None =>
              Ordering[String].compare(couple._1, couple._2)
          }
        }
      })
  }
}
