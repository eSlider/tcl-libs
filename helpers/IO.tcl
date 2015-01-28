#
# Base input/output lib 
# relized some files handling, checksum and string output
#

package provide IO 1.1

namespace eval ::IO {
  
  namespace export {[a-z]*}
  
  variable green    "\\033\[32m"
  variable white    "\\033\[1m"
  variable colorOff "\\033\[0m"
   
  # --------------------------- Procedure -----------------------------
  # Name: printTitle
  #
  #	output text in border
  #
  # Args:
  #   title       ... some text as string 
  #   textColor   ... <white|green>
  #
  # Returns: -
  # Created: 20.04.2013 20:01:56
  # -------------------------------------------------------------------
  proc printTitle { title {textColor white} } {
    variable green 
    variable white
    variable colorOff
    
    set title " $title "; # add some padding
    set borderColor ${green}
    
    switch -glob $textColor { 
      green {
        set textColor $green
      }
      
      default {
        set textColor $white
      }
    }

    set borderNum [string repeat "═" [string length $title]]
    puts [exec -- echo -e "${borderColor}╔${borderNum}╗\n║${colorOff}${textColor}${title}${colorOff}${borderColor}║\n╚${borderNum}╝${colorOff}"]
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: printRow
  #
  # Display key-value row	
  #
  # Args:
  #   row       ... key-value row 
  #
  # Returns: -
  # -------------------------------------------------------------------
  proc printRow { row } {
    foreach {key value} $row {
      puts [format " > %s: %s " $key $value]
    }
  }
 
  # --------------------------- Procedure -----------------------------
  # Name: getFileContent
  #
  #	Get file content as binary string
  #
  # Args:
  #   src       ... file location source
  #
  # Returns: -
  # -------------------------------------------------------------------
  proc getFileContent { src } {
    #  Slurp up the data file
    set fp [open $src r]
    fconfigure $fp -translation binary
    set file_data [read $fp]
    close $fp
    return $file_data
  }
  
  
  # --------------------------- Procedure -----------------------------
  # Name: openFile
  #
  #	
  #
  # Args:
  #   src       ... file source
  #
  # Returns: file pipe
  # -------------------------------------------------------------------
  proc openFile {src {mode r}} {
    set fp [open $src $mode]
    fconfigure $fp -translation binary
    return $fp
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: writeFile
  #
  #	write to pipe without adding new line
  #
  # Args:
  #   fp       ... file pipe
  #
  # Returns: -
  # -------------------------------------------------------------------
  proc writeFile {fp content {addNewLine 1} } {
    if {$addNewLine} {
      puts $fp $content 
    } else {
      puts -nonewline $fp $content 
    }
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: closeFile
  #
  #	close file pipe
  #
  # Args:
  #   fp       ... file pipe
  #
  # Returns: -
  # -------------------------------------------------------------------
  proc closeFile {fp} {
    close $fp
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: saveFile
  #
  #	Save file on disk
  #
  # Args:
  #   src       ... new file location source
  #   dataArr   ... reference to variable with binary string file data 
  # Returns: -
  # -------------------------------------------------------------------
  proc saveFile { src dataArr {mode w} } {
    upvar $dataArr data
    set fp [open $src $mode]
    fconfigure $fp -translation binary
    puts -nonewline $fp $data
    close $fp
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: removeFile
  #
  #	Remove file from disk
  #
  # Args:
  #   src       ... file location
  # Returns: -
  # -------------------------------------------------------------------
  proc removeFile { src } {
    file delete -force $src
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: getFileChecksum
  #
  #	Get file checksum
  #
  # Args:
  #   src       ...  file location source
  #
  # Returns: hash value
  # -------------------------------------------------------------------
  proc getFileChecksum {src} {
    lindex [exec -- md5sum $src] 0 
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: getMD5
  #
  # Get checksum of content 
  #
  # Args:
  #   contentVar       ... content data
  #
  # Returns: hash value
  # -------------------------------------------------------------------
  proc getMD5 { contentVar } {
    upvar $contentVar content
    return [string tolower [::md5::md5 -hex $content]]
  }
  
  
  # --------------------------- Procedure -----------------------------
  # Name: parseCliArgs
  #
  # Parse arguments into key value list
  #
  # Args:
  #   argv       ... arguments as string 
  #
  # Returns: key value list
  # -------------------------------------------------------------------
  proc parseCliArgs {argv} {
    set request [list]
    foreach key [lreplace [split $argv -] 0 0] {
      set keyName  [lindex $key 0]
      
      if { $keyName == "" } {
        continue
      }
      
      set value [lreplace $key 0 0]
      
      if { $value == "" } {
        set value 1
      }
      
      lappend request $keyName $value;  # set value
    }
    return $request
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: loadLib
  #
  # Load Lib
  #
  # Args:
  #   name        ... name
  #   libDir      ... path - default is /opt/SIGOS/
  #
  # Returns: hash value
  # -------------------------------------------------------------------
  proc loadLib { name {libDir /opt/SIGOS/} } {
    global env
    set env(DISTRIBUTOR) [lindex [split $env(MACHTYPE) -] 1]
    if { $env(OSTYPE) == "linux" } {
      set searchLib ".so"
      if { [regexp "86$" $env(CPU)] } {
        set searchLib  ".x86$searchLib"
      } else {
        set searchLib  ".x86_64$searchLib"
      }

      foreach libSrc [exec find $libDir -type f -iname "*$name*$env(DISTRIBUTOR)*$searchLib"] {
        load $libSrc
        return $libSrc
      }
    }
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: include
  #
  # Load Lib
  #
  # Args:
  #   name        ... name
  #   libDir      ... path - default is /opt/SIGOS/
  #
  # Returns: hash value
  # -------------------------------------------------------------------
  proc include { libs { path "libs/"}} {
    foreach libName $libs {
      source "$path${libName}.tcl"
    }
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: showEnvSettings
  #
  # Load Lib
  #
  # Args:
  #   name        ... name
  #   libDir      ... path - default is /opt/SIGOS/
  #
  # Returns: hash value
  # -------------------------------------------------------------------
  proc showEnvSettings {} {
    global env
    foreach {key name} [array get env] {
      puts $key=$name
    }
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: createDir
  #
  # mkdir
  #
  # Args:
  #   path        ... path
  #   replace     ... 1: delete old dir first - default 1
  #
  # Returns: hash value
  # -------------------------------------------------------------------
  proc createDir { path {replace 1} } {
    if { $replace && [file isdirectory $path]} {
      file delete -force $path
    }
    file mkdir $path
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: readCsv
  #
  # read CSV file to key name list array
  #
  # Args:
  #   fileSrc ... file location
  #   columns ... column name list, default: {}
  #   separator ... separator, default ";"
  #
  # Returns: key name list array if columns given, elswhere only data list
  # -------------------------------------------------------------------
  proc readCsv { fileSrc {columns {}} {separator ";"} } {
    set definitions [list]
    
    # skip all comments and empty strings...
    foreach line [regexp -all -line -inline -- {^[^#]+} [getFileContent $fileSrc]] {
      set definition [list]
      set data [split $line $separator] 
      
      # without format?
      if { [llength $columns] < 1} {
        lappend definitions $data
        continue
      }

      # with format
      set i -1
      foreach key $columns {
         Dict::put definition $key [lindex $data [incr i]] 
      }
      lappend definitions $definition
    }
    return $definitions
  }
  
}
