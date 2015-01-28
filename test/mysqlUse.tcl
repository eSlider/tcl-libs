     MySql::connect $dbHost $dbUser $dbPassword $dbName
      
      set userName "root"
      MySql::execute "SHOW TABLES" {columnData} {
        upvar userName userName
        foreach {key value} $columnData {
          MySql::execute "SHOW PROCESSLIST" {proccess} { 
            upvar userName userName
            if {[Dict::get proccess User] == $userName } {
             puts "ID:[Dict::get proccess Id]"
             puts "Host:[Dict::get proccess Host]"
            }
          }
        }
      }