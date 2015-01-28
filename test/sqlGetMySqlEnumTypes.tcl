# --------------------------- Procedure -----------------------------
# Name: sql_getTableTypeList
#
# Get table ENUM column list as tcl list.
#
# Args:
#   connectionId    ... connection id
#   tableName       ... table name
#   columnName      ... table ENUM column name
#
# Returns:
#   list of table column enum types
# -------------------------------------------------------------------
proc sql_getTableTypeList {connectionId tableName columnName} {
  set enumSql [sql_query $connectionId "SELECT COLUMN_TYPE FROM information_schema.`columns` 
    WHERE  table_schema = DATABASE()
    AND    DATA_TYPE = 'enum'
    AND    table_name   = '[mysqlescape ${tableName}]' 
    AND    column_name  = '[mysqlescape ${columnName}]'"]
   
   regsub -all {^.+?\('|'\)$} $enumSql {} enumSql
   regsub -all {','} $enumSql | enumSql
   return [split $enumSql |]
}

# connect to CU
sql_connect CU -host localhost -user root -conn CU

puts [sql_getTableTypeList CU Accounts PackageType]
puts [sql_getTableTypeList CU Accounts OrderStatus]