#
# Functions backed to namespace, 
# to simplify handle of lists
#
# @version 1.0
# 
package provide List 1.0

namespace eval ::List {
  
  namespace export {[a-z]*}
 
  # --------------------------- Procedure -----------------------------
  # Name: removeByIndex
  #
  #	Remove value from list by id
  #
  # Args:
  #   listArr       ... list reference
  #   index         ... list index number
  #
  # Returns: -
  # -------------------------------------------------------------------
  proc removeByIndex {listArr index} {
    upvar $listArr listRef
    listArr [lreplace $listArr $index $index]
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: removeByValue
  #
  # Remove from list by value 
  #
  # Args:
  #   listArr       ... list reference
  #   value         ... value data
  #
  # Returns: -
  # -------------------------------------------------------------------
  proc removeByValue {listArr value} {
    upvar $listArr listRef
    set idx [lsearch $listRef $value]
    set listRef [lreplace $listRef $idx $idx]
  }

  # --------------------------- Procedure -----------------------------
  # Name: formatEachElement
  #
  # Format and replace each element in the reference list.
  #
  # Format definition:
  #  http://www.tcl.tk/man/tcl8.4/TclCmd/format.htm    
  #
  # Example:
  #   formatEachElement listName "|%s|"  
  #
  # Args:
  #   listArr       ... list reference
  #   value         ... value data
  #
  # Returns: -
  # -------------------------------------------------------------------
  proc formatEachElement {listArr value} {
    upvar $listArr listRef
    set newList {}
    foreach { item } $listRef {
      lappend newList [format ${value} ${item}]
    }
    set listRef $newList
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: setVars
  #
  #	Set variables by name and value lists
  #
  # Args:
  #   vars       ... variable names
  #   data       ... values for names
  #
  # Returns: -
  # -------------------------------------------------------------------
  proc setVars {vars data} {
    foreach k $vars v $data {
        upvar "${k}" $k
        set $k $v
    }
  }
}
