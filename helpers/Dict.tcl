#
# Dict 
# 
# Example of nested list: 
# 
# set dict {id 1 name {test #1} description {}}
# 
# id  - is uniq key of associative array 
# 1   - is a value of associative array element with id key
#
# Changelog:
#
# @version 1.2
#   - renamed setv to put (more Java like style)
#   - removed create procedure
#
# @version 1.1
#   getKeys:
#     - bug fixed 
#     - performance improvements
#   getKeyIndex:
#     - implementation based on getKeys
# 
package provide Dict 1.2

namespace eval ::Dict { 
  
  # --------------------------- Procedure -----------------------------
  # Name: put
  #
  # Set row value by key.
  # If no key-value was found, add it to the end of list 
  # 
  # Issues:
  #   [info exists row] - 16 % performance reducing :(
  # 
  # Args:
  #  rowLink - row link value 
  #  searchKey - key to search in, or add new one
  #  newValue - value to replace old, if nothing given, then will be removed!
  #
  # Returns: -
  # -------------------------------------------------------------------
  proc put { rowLink searchKey {newValue {}}} {
    upvar $rowLink row
    set isEmpty [expr {$newValue == ""}]
    
    if {$isEmpty} {
      remove row $searchKey
      return $newValue
    }
    
    # need more performance as search from array, but has key order!
    set keyIndex [getKeyIndex row $searchKey]
    
    if {$keyIndex < 0 && !$isEmpty} {
      # add new key/value
      lappend row $searchKey $newValue
    } else {  
      # replace value 
      set valueIndex [expr {$keyIndex+1}]
      set row [lreplace $row $valueIndex $valueIndex $newValue]
    }

    return $newValue
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: getKeyIndex
  #
  #	search for key and return index or -2 if not found
  #
  # Args:
  #   rowLink      ...  list reference
  #
  # Returns: index > -1 or -2 if nothing found
  # -------------------------------------------------------------------
  proc getKeyIndex {rowLink key} {
    upvar $rowLink row
    ## executionTime 00:00.285
    for {set idx 0} {[set idx [lsearch -exact -start $idx $row $key]] > -1 } {incr idx} { 
      if {  $idx % 2 == 0 } {
        return $idx
      }
    }
    return -2

    ## executionTime 00:00.359
    #
    #    set idx 0
    #    while {1} { 
    #      set idx [lsearch -exact -start $idx $row $key]
    #      if { $idx < 0 } {
    #        return -2
    #      }
    #      
    #      if {  $idx % 2 == 0 } {
    #        return $idx
    #      }
    #      incr idx
    #    }
    
    ##  executionTime 00:01.438
    #    set i 0
    #    foreach {k v} $row {
    #      if {$k == $key} {
    #         return $i
    #      }
    #      incr i 2
    #    }
    #    return -2
        
    ## executionTime 00:01.538
    #    set l [llength $row]
    #    for {set i 0} {$i < $l} {incr i 2} {
    #      if {[lindex $row $i] == $key } {
    #         return $i
    #      }
    #    }
    #    return -2
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: getKeys
  #
  # get row keys as list
  #
  # Args:
  #   rowLink      ...  list reference
  #
  # Returns: key list
  # -------------------------------------------------------------------
  proc getKeys { rowLink  } {
    upvar $rowLink row
    set l [llength $row] 
    set r {}
    for {set i 0} {$i < $l} {incr i 2} {
      lappend r [lindex $row $i]
    }
#    set r {}
#    foreach {key value} $row {
#      lappend r $key
#    }
    return $r
  }
  # --------------------------- Procedure -----------------------------
  # Name: getValues
  #
  # get row value as list
  #
  # Args:
  #   rowLink      ...  list reference
  #
  # Returns: key list
  # -------------------------------------------------------------------
  proc getValues { rowLink  } {
    upvar $rowLink row
    set l [llength $row] 
    set r {}
    for {set i 1} {$i < $l} {incr i 2} {
      lappend r [lindex $row $i]
    }
    return $r
#    set values {}
#    foreach {key value} $row {
#      lappend values $value
#    }
#    return $values
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: get
  #
  # Get row value by key.
  #
  # Example:
  #   puts [getValue row id]
  #
  # Args:
  #   rowLink      ...  list reference
  #
  # Returns: value by key, if key is not exits default string will be returned and set to the key
  # -------------------------------------------------------------------
  proc get {rowLink searchKey {default {}}} {
    upvar $rowLink row
    
    # lindex search
    # executionTime 00:00.662
    set idx [getKeyIndex row $searchKey] 
    if {$idx > -1} {
      lindex $row [expr {$idx+1}]
    } elseif {$default ne ""} {
      put row $searchKey $default
    }
    
    # array search
    # executionTime 00:02.634
    #    array set arr $row
    #    
    #    if {[info exists arr($searchKey)]} {
    #      return $arr($seachKey)
    #    } else {
    #      return ""
    #    }
    
  }
  # --------------------------- Procedure -----------------------------
  # Name: has
  #
  # Check if dict has an key
  #
  # Args:
  #   rowLink       ...  list reference
  #   searchKey     ...  key name
  #
  # Returns: 1 or 0
  # -------------------------------------------------------------------
  proc has {rowLink searchKey} {
    upvar $rowLink row
    expr {[getKeyIndex row $searchKey]  > -1}
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: export
  #
  #	export dict vars in local scope
  # 
  # Example:
  #
  #  set dict {id 1} 
  #  Dict::exportVars dict
  #  puts $id ;# will display 1
  #
  # Args:
  #   rowLink      ... list reference
  #   isLink       ... ist reference or value?
  #
  # Returns: -
  # -------------------------------------------------------------------
  proc export {rowLink {isLink 1}} {
    if {$isLink} {
      upvar $rowLink row
    } else {
      set row $rowLink
    }
    
    foreach {k v} $row {
      if {[string is digit $k]} {
        continue;
      }
      upvar $k $k
      set $k $v
    }
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: with
  #
  #	evaluate dict vars in own local scope
  #
  # Example:
  #  set dbSettings {user test host localhost}
  #  Dict::with dbSettings {
  #    puts $name
  #    puts $host
  #  }
  #
  # Args:
  #   rowLink      ... list reference
  #   callback     ... optional. if given, then will be evaluated with exported vars in own local scope, but not exported 
  #
  # Returns: -
  # -------------------------------------------------------------------
  proc with {rowLink callback} {
    upvar $rowLink row 
    foreach {k v} $row {
      if {[string is digit $k]} {
        continue;
      }
      set $k $v
    }
    eval $callback
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: setValues
  #
  #	set values and numbers as keys 0,1,2...
  #
  # Args:
  #   rowLink      ... list reference
  #   values       ... data list
  #
  # Returns: last nummeric id
  # -------------------------------------------------------------------
  proc setValues {rowLink values} {
    upvar $rowLink row 
    set i 0
    foreach v $values {
      put row $i $v
      incr i
    }
    return $i
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: length
  #
  #	Get dict length
  #
  # Args:
  #   rowLink      ... list reference
  #
  # Returns: dict length
  # -------------------------------------------------------------------
  proc length {rowLink} {
    upvar $rowLink row
    expr {[llength $row]/2}
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: merge
  #
  #	Merge two dicts
  #
  # Args:
  #   rowLink1 ... dict 
  #   rowLink2 ... dict 
  #
  # Returns: -
  # -------------------------------------------------------------------
  proc merge { rowLink1 rowLink2 } {
    upvar $rowLink1 row1
    upvar $rowLink2 row2
    
    if {[info exists row1]} {
      set row3 $row1
    } else {
      set row3 {}
    }
    
    if {[info exists row2]} {
      foreach {k v} $row2 {
        put row3 $k $v
      }
    }
    
    return $row3
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: forEach
  #
  # Example:
  #  Dict::forEach parameters {k value} {
  #    puts "$k:$value"
  #  } {^site}
  #	
  #
  # Args:
  #   keyValue       ... key value list. Example:  {k v}
  #   rowLink        ... list reference
  #   callback       ... expression
  #   searchRegEx    ... key search filter
  # Returns: -
  # -------------------------------------------------------------------
  proc forEach {keyValue rowLink callback} {
    upvar $rowLink row
    
    set i 0
    set __k [lindex $keyValue 0]
    set __v [lindex $keyValue 1]
    set __l [llength $row]
    
    for {} {$i < $__l} { incr i 2 } {
      set $__k [lindex $row $i]
      set $__v [lindex $row [expr {$i+1}]]
      eval $callback 
    }
#    foreach "$__keyName $__valueName" $row {
#      eval $callback
#    }
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: removeKeys
  #
  #	Remove values by key list. 
  # 
  # Args:
  #   rowLink      ...  list reference
  #   keys         ...  key list 
  #
  # Returns: -
  # -------------------------------------------------------------------
  proc remove {rowLink keys} {
    upvar $rowLink row
    foreach key $keys {
      set idx [getKeyIndex row $key]
      if { $idx > -1  } {
        set row [lreplace $row $idx [expr $idx+1]]
      }
    }
  }
} 