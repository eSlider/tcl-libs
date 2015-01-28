#
# Random values generator
#
# @version  1.1:
#  - added getNumberByLength 
#
# @version 1.0
#   - init
#
package provide Generator 1.1

namespace eval ::Generator {
  namespace export {[a-z]*}

  # --------------------------- Procedure -----------------------------
  # Name: getIpAddress
  #
  #	Geneate random ip address
  #
  # Args: -
  # Returns: ip address string  (###.###.###.###)
  # Created: 20.04.2013 20:03:50
  # -------------------------------------------------------------------
  proc getIpAddress {} {
    for {set x 0} {$x<4} {incr x} {
      lappend ip [getNumber 1 254]
    }
    lappend listName 
    join $ip .
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: getNumber
  #
  # Geneate random number
  #
  # Args:
  #   start       ... start value number (default 1)
  #   end         ... end value number (default 1000000)
  #
  # Returns:random number
  # -------------------------------------------------------------------
  proc getNumber {{start 1} {end 1000000}} {
    expr round(rand()*${end}-${start})+${start}
  }

  # --------------------------- Procedure -----------------------------
  # Name: getNumberByLength
  #
  # Geneate random number
  #
  # Args:
  #   minLength       ... min length 
  #   maxLength       ... max length
  #
  # Returns:random number
  # -------------------------------------------------------------------
  proc getNumberByLength {{minLength 8} {maxLength 13}} {
    set min 1[string repeat 0 [expr { $minLength - 1 }]]
    set max [string repeat 9 $maxLength]
    getNumber $min $max
  }
}