#
# MySQL library for handling of nested lists.
# Can dynamicaly create database, tables and columns on the fly (types defined by name convension)
#
# Provided functionality 
#
# Changelog:
#
# @version  1.4:
#  - save renamed to replace
#
# @version  1.3:
#  - data check by save not exists data for table key
#  - added flat data select 
#
# @version 1.2:
#  - mysql::fetch instead of mysql::sel and 
#  - callback option for each result
#
package provide MySql 1.4
package require mysqltcl
package require Dict

namespace eval ::MySql { 

  namespace export {[a-z]*}
  variable dbLink 
  variable dbAccount
  
  # --------------------------- Procedure -----------------------------
  # Name: connect
  #
  # Connect to MySQL 
  #
  # Args:
  #   host            ... MySQL hostname or ip address
  #   user            ... MySQL user name  
  #   pass            ... MySQL password
  #   name            ... MySQL database name. Optional.
  #   createStructure ... optional. default is 0. if 1, creates database if not exists.
  #
  # Returns: connection handler
  # -------------------------------------------------------------------
  proc connect {host user pass {name {}} {createStructure no}} {
    variable dbLink
    variable isDatabaseExists
    variable dbAccount [list host $host user $user pass $pass name $name createStructure $createStructure]
    
    set dbLink [::mysql::connect -host $host -user $user -password $pass]
    set isDatabaseExists [expr {[lsearch [execute "SHOW DATABASES" data] $name] > -1}]
    
    # set UTF-8 as default for names and values
    execute "SET CHARACTER SET 'utf8'"
    execute "SET NAMES 'utf8'"
    
    if {$isDatabaseExists} {
      if {$name ne ""} {
        ::mysql::use $dbLink $name
      }
    } else {
      if {$createStructure} {
        execute "CREATE DATABASE IF NOT EXISTS $name CHARACTER SET 'utf8'"
      }
    }
    
    return $dbLink
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: setConnection
  #
  # Description:
  #   Set connection handler   
  #
  # Args:
  #   connectionHandler		  ... connection handler
  #
  # Returns: -
  # -------------------------------------------------------------------
  proc setConnection { connectionHandler } {
    variable dbName
    set $dbName $connectionHandler
  }

  # --------------------------- Procedure -----------------------------
  # Name: execute
  #
  # Description:
  #
  #	  Execute SQL and return results
  #
  #  # Example #1: 
  #  MySql::execute "SELECT * FROM `dbscheme`" {columnData} {
  #       foreach {key value} $columnData {
  #         puts "$key:$value"
  #       }
  #     }
  #
  #  # Example #2: 
  #  set userName "root"
  #  MySql::execute "SHOW TABLES" {columnData} {
  #    upvar userName userName
  #    foreach {key value} $columnData {
  #      MySql::execute "SHOW PROCESSLIST" {proccess} { 
  #        upvar userName userName
  #        set keys [Dict::getKeys proccess]
  #         set values [Dict::getValues proccess]
  #        if {[Dict::get proccess User] == $userName } {
  #         puts "ID:[Dict::get proccess Id]"
  #         puts "Host:[Dict::get proccess Host]"
  #        }
  #      }
  #    }
  #  }
  #
  # Args:
  #  SQL      ... MySQL SQL 
  #  type     ... <rows|row|data|value> return type
  #               dicts       - dict list. rows with names
  #               data        - value list. rows withouts names
  #               flat        - value list as one list
  #               row|dict    - dict, only first result row will be returned.
  #               value - first value(cell) of result row
  #               name - if expression
  #  callback ... expression 
  #
  # Returns: see type
  # -------------------------------------------------------------------
  proc execute {sql {type dicts} {callback {}} }  {
    variable dbLink 
    
    set rows {}
    set isResultRow [expr {$type == "row" || $type == "dict"}]
    set isResultFirstValue [expr {$type == "value"}]
    set isResultData [expr {$type == "data"}] 
    set isResultFlat [expr {$type == "flat"}] 
    set isResultDataRow [expr {$type == "dataRow"}] 
    set isResultOnlyInfo [expr {$type == "info"}] 
    set isExpression [expr {[llength $callback] > 0}] 
    
    if {$isExpression} {
      set rowVarName [lindex $type 0]
      set keysVarName [lindex $type 1]
      set valuesVarName [lindex $type 2]
      set rowsVarNum [lindex $type 3]
      set rowsCurrentVarNum [lindex $type 4]
    }
    
    set queryResult [::mysql::query $dbLink $sql]
    
    if {$queryResult == -1} { 
      # parse info if no results
      return [::mysql::info $dbLink info]
    }
    
    set rowKeysInfo [::mysql::col $queryResult -current name]
    
    if {$isExpression} {
      set $keysVarName $rowKeysInfo
      #set $rowsCount [::mysql::result $queryResult rows?]
      set $rowsVarNum [::mysql::result $queryResult rows]
      set _currentRow 1
    }
    
    if {$isResultOnlyInfo} {
      #info [::mysql::info $dbLink info]
      #rowsNum [::mysql::result $queryResult rows]
      return [list columns $rowKeysInfo info [::mysql::info $dbLink info]]
    }

    while {[set dataRow [::mysql::fetch $queryResult]]!=""} {
      
      if {!$isExpression} {
        if { $isResultFirstValue} {
          return [lindex $dataRow 0]
        }
        if { $isResultFlat} {
          append rows $dataRow " "
          continue
        }
        if { $isResultData} {
          lappend rows $dataRow
          continue
        }
        if { $isResultDataRow } {
          return $dataRow
        }
      }
      
      set row {}
      set i 0
      
      foreach keyName $rowKeysInfo {
        lappend row $keyName [lindex $dataRow $i]
        incr i
      }
      
      if { $isExpression } {
        set $rowVarName $row
        set $valuesVarName $dataRow
        set $rowsCurrentVarNum $_currentRow
        eval $callback
        incr _currentRow
      }
      
      if { $isResultRow } {
        return $row
      }
      lappend rows $row
    }
    ::mysql::endquery $queryResult
    
    return $rows
  }

  # --------------------------- Procedure -----------------------------
  # Name: disconnect
  #
  #	Disconnect from MySQL
  #
  # Args: -
  # Returns: -
  # -------------------------------------------------------------------
  proc disconnect { } { 
    variable dbLink
    mysqlclose $dbLink
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: getTables
  #
  #	Get MySQL database table list
  #
  # Args: -
  # Returns: list of tables
  # -------------------------------------------------------------------
  proc getTables {} {
    execute "SHOW TABLES" data
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: getTableKeys
  #
  # Get table column list	
  # 
  # Args:
  #   tableName  ... Table name 
  #
  # Returns: column list
  # -------------------------------------------------------------------
  proc getTableKeys { tableName } {
    # executionTime 00:01.910
    set tableInfo [execute "SELECT * FROM `$tableName` LIMIT 0" info]
    Dict::get tableInfo columns
    
    # executionTime 00:04.430
    #    set fields {}
    #    foreach v [execute "DESCRIBE `$tableName`" data] {
    #      lappend fields [lindex $v 0]
    #    }
    #    return $fields

    # executionTime 00:24.263 
    # execute "SELECT COLUMN_NAME FROM information_schema.`COLUMNS` WHERE  TABLE_SCHEMA LIKE \"mprs\" AND TABLE_NAME LIKE \"$tableName\"" flat
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: createTable
  #
  #	Create table 
  #
  # Args:
  #   tableName       ... Table name 
  #   checkIfExists   ... <1|0> check before create
  #
  # Returns: -
  # -------------------------------------------------------------------
  proc createTable { tableName {checkIfExists 1}} {
    if { !$checkIfExists || [lsearch [getTables] $tableName] < 0 } {
      execute "CREATE TABLE `$tableName` (
        `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
        `creationDate` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`)
      ) CHARSET=utf8" 
    }
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: addTableFields
  #
  # Compare table field with row fields, 
  # and if table has no field it will be added to 
  #
  # Args:
  #   tableName   ...  Table name 
  #   keyName     ...  Table key
  #   type        ...  Table key type. Default: auto
  #                    @see: http://dev.mysql.com/doc/refman/5.5/en/choosing-types.html
  # Returns: -
  # -------------------------------------------------------------------
  proc addTableField {  tableName keyName {type {auto}} } {
    if { $type == "auto" } {
      switch -glob $keyName {
        id -
        *Id -
        *Nr {
          set type "INT(10) unsigned"
        }
        
        Ts -
        *Timestamp {
          set type "TIMESTAMP"
        } 
        
        date -
        *Date {
          set type "DATETIME"
        } 
        
        type - 
        key -
        name -
        label -
        title -
        field -
        *Label -
        *Title -
        *Type -
        *Field -
        *Key -
        *Name {
          set type "VARCHAR(255) NULL"
        }
        
        *ontent -
        *data {
            set type "LONGTEXT NULL"
        }
       
        default {
          set type "MEDIUMTEXT NULL"
        }
      }
      
      execute "ALTER TABLE `$tableName` ADD `[escape $keyName]` $type"
    }
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: escape
  #
  #	Escape string for MySQL
  #
  # Args:
  #   string       ... string to escape
  #
  # Returns: escaped string
  # -------------------------------------------------------------------
  proc escape { string } {
    return [::mysql::escape $string]
  }
  
  
  # --------------------------- Procedure -----------------------------
  # Name: replaceAll
  #
  # REPLACE is like INSERT except that it deletes old record as necessary when a duplicate unique key value is present in the new record.  
  # With REPLACE, the new record overwrite the old record completely.
  # REPLACE returns an information string that indicates how many rows is affected. 
  #
  # Args:
  #   tableName           ... Table name 
  #   columnsVar          ... Columns list link
  #   valuesVar           ... Values list link
  #
  # Returns: insert id
  # -------------------------------------------------------------------
  proc replaceAll {tableName columnsVar valuesVar} {
    variable dbLink 
    
    upvar $columnsVar columns
    upvar $valuesVar values
   
    set rows {}
    set cl [llength $columns]
    set vl [llength $values]
    set i 0
    
    for {} { $i < $vl } { incr i $cl } {
      set rowData {}
      foreach value [lrange $values $i [expr {$cl+$i-1}] ] {
        lappend rowData '[escape $value]'
      }
      lappend rows [join $rowData ,]
    }
    
    execute "REPLACE INTO `$tableName` (`[join $columns "`,`"]`) VALUES ([join $rows ),(])" info
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: replace
  #
  # Insert name, value list into table
  #
  # Example #1:
  #  set row {mimeType {text/plain} name {test} content {asda da''' *´ßЛДüäöäüppФ''''оаыдволаsd asd asd}}
  #  set id [mysqlInsert Files row]
  #
  # Example #2:
  #  set tableName "Files1"
  #  set newRow {name test content {test1 test2} xxLisxtddx {asdasd}}
  #  saveRow newRow $tableName
  #
  #
  # Args:
  #   rowLink         ... Link name to row
  #   tableName       ... Table name 
  #   createStructure ... Create rows automaticaly. Default: no
  #   checkData       ... Skip keys, which are not the part of database table? Default: yes
  #
  # Returns: insert id
  # -------------------------------------------------------------------
  proc replace { rowLink tableName {createStructure no} {checkData yes}} {
    variable dbLink 
    
    upvar $rowLink row
    
    set keys {}
    set values {}
    set tableKeys [getTableKeys $tableName]
    
    if {$createStructure} {
      createTable $tableName
    }
    
    foreach {key value} $row {
      if {$checkData} {
        # is key not valid?
        if {[expr {[lsearch -exact $tableKeys $key] < 0}]} {
          if {$createStructure} {
            addTableField $tableName $key
          } else {
            continue;
          }
        }
      }
      
      lappend keys "`[escape $key]`"
      lappend values "'[escape $value]'"
    }
    
    execute [format "REPLACE INTO %s (%s) VALUES (%s)" `$tableName` [join $keys ","] [join $values ","]]
    
    set id [::mysql::insertid $dbLink]
    
    if { $id > 0 } {
      Dict::put row id $id
    }
    
    return $id
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: remove
  #
  # Remove row from table by row ID ({id 1})
  #
  # Example:
  #  set tableName "Files1"
  #  set newRow {name test content {test1 test2} xxLisxtddx {asdasd}}
  #  saveRow newRow $tableName
  #  puts $newRow 
  #  remove newRow $tableName
  #
  # Args:
  #   rowLink       ... Link name to row
  #   tableName     ... Table name 
  #
  # Returns: -
  # -------------------------------------------------------------------
  proc remove { rowLink tableName } {
    upvar $rowLink row
    removeById [Dict::get row id]
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: removeById
  #
  # Remove row from table by ID 
  #
  # Args:
  #   id          ... Row id
  #   tableName   ... Table name
  #   keyName     ... Column name. Default id
  #
  # Returns: -
  # -------------------------------------------------------------------
  proc removeById { id tableName {keyName id} } {
    execute "DELETE FROM `$tableName` WHERE `$keyName`='[escape $id]'"
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: getIdByKey
  #
  #	Get table id by key/value as number
  #
  # Args:
  #   tableName ... table name
  #   key       ... column name
  #   value     ... value for WHERE key LIKE operation
  #   id        ... table id column. default=id
  #
  # Returns: >0, or 0 if nothing found
  # -------------------------------------------------------------------
  proc getIdByKey {tableName key value {id id}} {
    set id "`[escape $id]`"
    execute "SELECT IF(count($id)=0,0,$id) 
      FROM `$tableName` 
      WHERE `[escape $key]` 
      LIKE \"[escape $value]\"
      LIMIT 1" value
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: getKeyValue
  #
  # Get table key by value key/value as string
  #
  # Args:
  #   tableName ... table name
  #   key       ... column name
  #   value     ... value for WHERE key LIKE operation
  #   id        ... table id column. default=id
  #
  # Returns: string
  # -------------------------------------------------------------------
  proc getKeyValue {tableName key value {id id}} {
    execute "SELECT `[escape $key]`
      FROM `$tableName` 
      WHERE `[escape $id]` 
      LIKE \"[escape $value]\"
      LIMIT 1" value
  }
  
  # --------------------------- Procedure -----------------------------
  # Name: updateByKey
  #
  # Update table key/value by key
  #
  # Args:
  #   tableName        ... table name
  #   columnName       ... column name
  #   newValue         ... new value to replace
  #   idValue          ... ID column value
  #   idKeyName        ... ID column name
  #
  # Returns: mysql info
  # -------------------------------------------------------------------
  proc updateByKey {tableName columnName newValue idValue {idKeyName id}} {
    MySql::execute "UPDATE `$tableName` SET `$columnName`='[escape $newValue]' WHERE `$idKeyName`='[escape $idValue]'" info
  }
}