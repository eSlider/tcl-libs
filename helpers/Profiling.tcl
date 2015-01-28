#
# Profiling
#
package provide Profiling 1.1

namespace eval ::Profiling {
  
  variable _profilerStartTimeMs
  variable intesivityFactor 1
  
  proc getTimestampInMilliSeconds {} {
    set secs [clock seconds]
    set ms [clock clicks -milliseconds]
    set base [expr { $secs * 1000 }]
    set fract [expr { $ms - $base }]
    if { $fract > 1000 } {
      set diff [expr { $fract / 1000 }]
      incr secs $diff
      incr fract [expr { -1000 * $diff }]
    }
    expr {($secs * wide(1000)) + $fract}
  }
  
  proc formatMs { milliseconds } {
    set ms [expr {$milliseconds % 1000 }]
    set seconds [expr {($milliseconds-$ms)/1000%60 }]
    set minutes [expr {($milliseconds-($seconds*1000)-$ms)/60/1000 }]
    format "%02d:%02d.%03d" $minutes $seconds $ms 
  }
  
  proc start {} {
    variable _profilerStartTimeMs
    lappend _profilerStartTimeMs [clock clicks -milliseconds]
    llength $_profilerStartTimeMs
  }
  
  proc stop {id {formated 0}} {
    variable _profilerStartTimeMs
    set startMs [lindex $_profilerStartTimeMs [expr {$id - 1}]]
    set durationMs [expr {[clock clicks -milliseconds] - $startMs }]
    
    if { $formated } {
      return [formatMs $durationMs]
    } else {
      return $durationMs
    }
  }
  
  variable _defaultDefinition {
    
    title "TEST"
    count 100
    intesivityFactor 1
    data 1
    printStatus yes
    
    results {}
    
    onStart {}
    onEach {}
    onCheck {}
    onError {exit}
    onErrorHandler {
      puts "\n -> Error by test #[expr {$i+1}]: $title"
      puts ""
      puts "   * data: $data"
      puts "   * dataItem: $dataItem"
      puts "   * executionTime: $executionTime ms"
      puts ""
      puts "   * onStart: $onStart"
      puts "   * onEach: $onEach"
      puts "   * onCheck: $onCheck"
      puts ""
      eval $onError
    }
    onComplete {}
    
    onPrintHeader {
      puts -nonewline "start test {$title}\r"
    }
    
    onPrintStatus {
      puts -nonewline "\r{test {$title} count ${count} pass $_ok fail $_failed complete true executionTime $totalTime}\n"
    }
  }
  
  proc test { definition } {
    variable _defaultDefinition
    
    # merge test definitions and export variables
    Dict::export [Dict::merge _defaultDefinition definition] no

    set pId [start]

    eval $onStart
    
    if {$printStatus} {
      eval $onPrintHeader
    }
    
    set c [expr { $count * $intesivityFactor}]
    set l [llength $data]
    set _ok 0 
    set _failed 0
    
    # test all items
    for {set i 0} {$i < $c} {incr i} {
      set dataItem [lindex $data [expr {$i%$l}]]
      set tId [start]
      set testResult [eval $onEach]
      set executionTime [stop $tId]
      
      if {[eval $onCheck] != 0} {
         incr _ok
      } else {
         incr _failed
         eval $onErrorHandler
      }
      if {$printStatus} {
        puts -nonewline "\r{test {$title} current [expr {$i+1}] count ${count} pass $_ok fail $_failed percentPass [expr { $_ok * 100 / $c }]}"
      }
    }
    
    set totalTime [stop $pId 1]
    
    # compare data
    eval $onComplete
    
    if {$printStatus} {
      eval $onPrintStatus
    }
  }
  
  proc testList { testList } {
    foreach conf $testList {
      test $conf
    }
  }
}