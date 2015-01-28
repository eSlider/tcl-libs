#
# Base input/output lib 
# relized some files handling, checksum and string output
#
# @version 1.0
#
package provide Git 1.0

namespace eval ::Git {
  # --------------------------- Procedure -----------------------------
  # Name: getRevisions
  #
  # get revision number and save into file named "revsion" 
  #
  # Args: -
  # Returns: -
  # -------------------------------------------------------------------
  proc getRevision {} {
    if { [ catch {
      set revision [exec git rev-list HEAD --count] 
      exec echo $revision > revision
    } errorMessage ] } {
      set revision [exec cat revision] 
    }
    return $revision
  }
}