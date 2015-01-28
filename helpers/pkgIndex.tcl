# Tcl package index file, version 1.1

if {![namespace exists helpers]} {
  namespace eval helpers {}
  foreach src {List Dict Generator IO Profiling HTTP Git MySql} {
    if { [string first "pkgIndex.tcl" $src ] > 0} {
     continue 
    }
    source ${dir}/${src}.tcl
  }
}