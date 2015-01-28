#
# HTTP library
#
#
package provide HTTP 1.2
package require ncgi
package require Dict

namespace eval ::HTTP {
  namespace export {[a-z]*}
  
  variable isInitialHeaderSend no

  # --------------------------- Procedure -----------------------------
  # Name: parseQueryString
  #
  #	parse query string to name, value list
  #
  # Args:
  #   query_string ... url query string
  #
  # Returns: name, value list
  # -------------------------------------------------------------------
  proc parseQueryString { dataArr str } {
    upvar $dataArr r
    foreach var [split $str &] {
      set var [split $var =]
      set key [ncgi::decode [lindex $var 0]]
      set value [ncgi::decode [lindex $var 1]]
      if { $key != "" } {
        Dict::put r $key $value
      }
    }
  }

  # --------------------------- Procedure -----------------------------
  # Name: getRequest
  #
  #	Get name, value list from GET and POST together
  #
  # Args: -
  # Returns: -
  # -------------------------------------------------------------------
  proc getRequest {} {
    global env
    set request [list]
    parseQueryString request $env(QUERY_STRING)
    if { [info exists env(CONTENT_LENGTH)] } {
      parseQueryString request [read stdin $env(CONTENT_LENGTH)]
    }
    return $request
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: toXML
  #
  #	Convert name, value list to XML string
  #
  # Args:
  #   nameValueListArr  ...  name, value list 
  #   addRootNode       ...  name of root element, if not given, return only XML snippet
  #
  # TODO: isn't complete implemented
  #
  # Returns: -
  # -------------------------------------------------------------------
  proc toXML { nameValueListArr  {addRootNode ""} } {
    set xml ""
    
    puts $nameValueListArr
    foreach row $nameValueListArr {
      
      set subXml ""
      foreach {key value} $row {
        set subXml "$subXml<$key length=\"[lindex $value]\"><\!\[CDATA\[$value\]\]></$key>"
      }
      
      set xml "$xml<row>$subXml</row>"
#      if { [llength $value] > 1 } {
#        set xml [toXML $value]
#      } else {
       
#      }
    }
    
    if { $addRootNode != "" } {
      set xml "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?><$addRootNode>$xml</$addRootNode>"
    }
    
    return $xml
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: listApi
  #
  #	List API functions
  #
  # Args:
  #   workNameSpace       ... 
  #
  # Returns: -
  # -------------------------------------------------------------------
  proc listApi { workNameSpace } {
    # if nothing found, list all functions
    foreach procName [lsort [info procs $workNameSpace*]] {
      set _procName [lindex [split $procName :] 4]
      set vars {}
      if { [string first _ $_procName] == 0 } {
        continue
      }
      puts "<h3>$_procName</h3>"
      foreach name [info args $procName]  {
        if { $name == "type" ||  $name == "getId" } {
          continue
        }
        puts "<li style='margin-bottom'>?${name}? - $name</li>"
        lappend vars "$name=wert"
      }
      set link "\?act=$_procName&[join $vars &]"
      puts "<br/><a href='$link'>$link</a><hr/>"
    }
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: sendInitalHeaders
  #
  #	Send HTTP server initial headers
  #
  # Args:
  #   contentType       ... document content type. default text/plain
  #   charSet       ... document charset. default utf-8
  #
  # Returns: -
  # -------------------------------------------------------------------
  proc sendInitalHeaders { {contentType text/plain} {charSet utf-8} } {
    variable isInitialHeaderSend 
    
    if {$isInitialHeaderSend} {
      return
    }
    
    set isInitialHeaderSend yes
    #puts "HTTP/1.1 200 OK" 
    puts "Content-Type: $contentType; charset=${charSet}\n" 
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: executeNamespaceProcedure
  #
  #	Execute namespace function with parameters given in $request as name, value list
  #
  # Args:
  #   workNameSpace     ... namespace 
  #   act               ... procedure name
  #   request           ... request data as name, value list
  #
  # Returns: function result or error description as text
  # -------------------------------------------------------------------
  proc executeNamespaceFunction { workNameSpace functionName request } {
    # add namespace prefix
    set act "$workNameSpace$functionName"
    
    # search if namespace has this procedure
    foreach procName [info procs $workNameSpace*] {
      if { $act eq $procName } {
        
        array set requestArray $request
        set cmd [list $procName]
        
        foreach name [info args $procName]  {
          if { ![info exists requestArray($name)] } {
            if { $name != "type" &&  $name != "getId" } {
              return "Error: Function <b>$procName</b> need <b>$name</b>!"
            }
          } else {
            lappend cmd $requestArray($name)
          }
        }
        
        set result [eval $cmd]
        return $result
      }
    } 
    
    puts stdout "Error: Function <b>$act</b> not found"
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: toNumber
  #
  # filter string from non-numerical characters
  #
  # Args:
  #   dataArr   ... key value list
  #   key       ... 
  #
  # Created: 07.05.2013 16:20:50
  # Returns: numerical string
  # -------------------------------------------------------------------
  proc toNumber { dataArr key } {
    upvar $dataArr data
    regsub -all {[^0-9]+} [Dict::get data $key] {}
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: 
  #
  # Description:
  #   
  #
  # Args:
  #   args		  ...
  #
  # Returns: -
  # -------------------------------------------------------------------
  proc parseUrl { rawUrl } {
    set url [list]
    
    regexp {^([^:]*)://([^/]*)([^\?]*)([^\#]*)\#?(.*)} $rawUrl urlRaw protokol host uri request deepLink
    
    Dict::put url protokol $protokol 
     
    # is login given?
    set hostInfo [split $host @]
    
    if { [llength $hostInfo ] > 1 } {
      set userLogin [split [lindex $hostInfo 0] :]
      
      # set user name
      Dict::put url user [lindex $userLogin 0]
      
      # is password given?
      if { [llength $userLogin ] > 1 } {
        Dict::put url pass [lindex $userLogin 1]
      }
      
      # remove login from host
      set host [lindex $hostInfo 1]
    }
    
    # is port given?
    set hostInfo [split $host :]
    if { [llength $hostInfo ] > 1 } {
      Dict::put url port [lindex $hostInfo 1]
      
      # remove port from host
      set host [lindex $hostInfo 0]
    }
    
    Dict::put url host $host ;# can contain user pass and port 
    Dict::put url uri $uri 
    Dict::put url queryString $request 
    Dict::put url deepLink $deepLink 
    Dict::put url url $urlRaw 
  }
  
  proc display { rowLink {print yes}} {
    upvar $rowLink row
    set r "<table style='border-width:  1px;
      border-spacing: 1;
      border-collapse: collapse;
      border-style: solid;'>"
    
    foreach {k v} $row {

      set r "$r<tr>
        <td style='border-width: 1px; border-style: solid'><b>$k</b></td>
        <td style='border-width: 1px; border-style: solid'>$v</td></tr>"
    }
    
    set r "$r</table>"
    
    if {$print} {
      puts $r
    }
    return $r
  }
}
