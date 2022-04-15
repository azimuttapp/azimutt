module DataSources.AmlParser.ParsersTest exposing (..)

import DataSources.AmlParser.AmlParser exposing (AmlColumn, AmlTable)
import DataSources.AmlParser.Parsers as Parsers
import DataSources.AmlParser.TestHelpers exposing (testParser)
import Dict
import Libs.Tailwind as Color
import Test exposing (Test, describe)


suite : Test
suite =
    describe "AmlParser.Parsers"
        [ describe "table"
            [ testParser ( "name", Parsers.table ) "users" { table | table = "users" }
            , testParser ( "with schema", Parsers.table ) "public.users" { table | schema = Just "public", table = "users" }
            , testParser ( "with props", Parsers.table ) "users {color=red}" { table | table = "users", props = Just { color = Just Color.red, position = Nothing } }
            , testParser ( "with notes", Parsers.table ) "users | note" { table | table = "users", notes = Just "note" }
            , testParser ( "with comment", Parsers.table ) "users # comment" { table | table = "users", comment = Just "comment" }
            , testParser ( "with all", Parsers.table ) "public.users {color=red, left=20, top=10} | a note # a comment" { schema = Just "public", table = "users", props = Just { color = Just Color.red, position = Just { left = 20, top = 10 } }, notes = Just "a note", comment = Just "a comment", columns = [] }

            -- FIXME
            --, testParser ( "with columns", Parsers.table )
            --    """
            --users
            --  id int
            --  name varchar
            --"""
            --    { table
            --        | table = "users"
            --        , columns =
            --            [ { column | name = "id", kind = Just "int" }
            --            , { column | name = "name", kind = Just "varchar" }
            --            ]
            --    }
            ]
        , describe "column"
            [ testParser ( "name", Parsers.column ) "id" { column | name = "id" }
            , testParser ( "with type", Parsers.column ) "id int" { column | name = "id", kind = Just "int" }
            , testParser ( "with default value", Parsers.column ) "id int=0" { column | name = "id", kind = Just "int", default = Just "0" }
            , testParser ( "with nullable", Parsers.column ) "id int nullable" { column | name = "id", kind = Just "int", nullable = True }
            , testParser ( "with NULLABLE", Parsers.column ) "id int NULLABLE" { column | name = "id", kind = Just "int", nullable = True }
            , testParser ( "with pk", Parsers.column ) "id int pk" { column | name = "id", kind = Just "int", primaryKey = True }
            , testParser ( "with PK", Parsers.column ) "id int PK" { column | name = "id", kind = Just "int", primaryKey = True }
            , testParser ( "with index", Parsers.column ) "id int index" { column | name = "id", kind = Just "int", index = Just "" }
            , testParser ( "with unique", Parsers.column ) "id int unique" { column | name = "id", kind = Just "int", unique = Just "" }
            , testParser ( "with check", Parsers.column ) "id int check" { column | name = "id", kind = Just "int", check = Just "" }
            , testParser ( "with fk", Parsers.column ) "id int fk logins.id" { column | name = "id", kind = Just "int", foreignKey = Just { schema = Nothing, table = "logins", column = "id" } }
            , testParser ( "with fk full", Parsers.column ) "id int fk public.logins.id" { column | name = "id", kind = Just "int", foreignKey = Just { schema = Just "public", table = "logins", column = "id" } }
            , testParser ( "with props", Parsers.column ) "id int {hidden}" { column | name = "id", kind = Just "int", props = Just { hidden = True } }
            , testParser ( "with notes", Parsers.column ) "id int | note" { column | name = "id", kind = Just "int", notes = Just "note" }
            , testParser ( "with comment", Parsers.column ) "id int # comment" { column | name = "id", kind = Just "int", comment = Just "comment" }
            , testParser ( "with all", Parsers.column ) "id int=0 nullable pk index unique=main check fk public.logins.id {hidden} | a note # a comment" { name = "id", kind = Just "int", default = Just "0", nullable = True, primaryKey = True, index = Just "", unique = Just "main", check = Just "", foreignKey = Just { schema = Just "public", table = "logins", column = "id" }, props = Just { hidden = True }, notes = Just "a note", comment = Just "a comment" }
            ]
        , describe "constraint"
            [ testParser ( "lowercase", Parsers.constraint "index" ) "index" ""
            , testParser ( "uppercase", Parsers.constraint "index" ) "INDEX" ""
            , testParser ( "with value", Parsers.constraint "index" ) "index=test" "test"
            , testParser ( "with spaced value", Parsers.constraint "index" ) "index = \"a test\"" "a test"
            , testParser ( "with empty value", Parsers.constraint "index" ) "index=" ""
            ]
        , describe "tableProps"
            [ testParser ( "empty", Parsers.tableProps ) "{}" { position = Nothing, color = Nothing }
            , testParser ( "color", Parsers.tableProps ) "{color=red}" { position = Nothing, color = Just Color.red }
            , testParser ( "position", Parsers.tableProps ) "{left=20, top=10}" { position = Just { left = 20, top = 10 }, color = Nothing }
            , testParser ( "both", Parsers.tableProps ) "{color=red, left=20, top=10}" { position = Just { left = 20, top = 10 }, color = Just Color.red }
            ]
        , describe "columnProps"
            [ testParser ( "empty", Parsers.columnProps ) "{}" { hidden = False }
            , testParser ( "hidden", Parsers.columnProps ) "{hidden}" { hidden = True }
            , testParser ( "hidden=", Parsers.columnProps ) "{hidden=}" { hidden = True }
            , testParser ( "true", Parsers.columnProps ) "{hidden=true}" { hidden = True }
            , testParser ( "yes", Parsers.columnProps ) "{hidden=yes}" { hidden = True }
            , testParser ( "y", Parsers.columnProps ) "{hidden=y}" { hidden = True }
            , testParser ( "Y", Parsers.columnProps ) "{hidden=Y}" { hidden = True }
            , testParser ( "bad", Parsers.columnProps ) "{hidden=bad}" { hidden = False }
            ]
        , describe "properties"
            [ testParser ( "empty", Parsers.properties ) "{}" Dict.empty
            , testParser ( "empty with spaces", Parsers.properties ) "{ }" Dict.empty
            , testParser ( "key/value", Parsers.properties ) "{ top = 20, flag }" (Dict.fromList [ ( "top", "20" ), ( "flag", "" ) ])
            ]
        , describe "property"
            [ testParser ( "key/value", Parsers.property ) "key=value" ( "key", "value" )
            , testParser ( "key/value with spaces", Parsers.property ) "key = value" ( "key", "value" )
            , testParser ( "key/value with more spaces", Parsers.property ) "\"a key\" = \"a value\"" ( "a key", "a value" )
            , testParser ( "flag", Parsers.property ) "flag" ( "flag", "" )
            , testParser ( "flag with spaces", Parsers.property ) "\"a flag\"" ( "a flag", "" )
            ]
        , describe "tableRef"
            [ testParser ( "table and schema", Parsers.tableRef ) "public.users" { schema = Just "public", table = "users" }
            , testParser ( "table only", Parsers.tableRef ) "users" { schema = Nothing, table = "users" }
            , testParser ( "with spaces", Parsers.tableRef ) "\"a schema\".\"a table\"" { schema = Just "a schema", table = "a table" }
            ]
        , describe "columnRef"
            [ testParser ( "column, table and schema", Parsers.columnRef ) "public.users.id" { schema = Just "public", table = "users", column = "id" }
            , testParser ( "column and table", Parsers.columnRef ) "users.id" { schema = Nothing, table = "users", column = "id" }
            , testParser ( "with spaces", Parsers.columnRef ) "\"a schema\".\"a table\".\"a column\"" { schema = Just "a schema", table = "a table", column = "a column" }
            ]
        , describe "schemaName"
            [ testParser ( "basic", Parsers.schemaName ) "public" "public"
            , testParser ( "with spaces", Parsers.schemaName ) "\"a schema\"" "a schema"
            , testParser ( "with dot", Parsers.schemaName ) "\"a.schema\"" "a.schema"
            ]
        , describe "tableName"
            [ testParser ( "basic", Parsers.tableName ) "users" "users"
            , testParser ( "with spaces", Parsers.tableName ) "\"a table\"" "a table"
            ]
        , describe "columnName"
            [ testParser ( "basic", Parsers.columnName ) "id" "id"
            , testParser ( "with spaces", Parsers.columnName ) "\"a column\"" "a column"
            ]
        , describe "columnType"
            [ testParser ( "basic", Parsers.columnType ) "number" "number"
            , testParser ( "with precision", Parsers.columnType ) "varchar(12)" "varchar(12)"
            , testParser ( "with spaces", Parsers.columnName ) "\"varchar (12)\"" "varchar (12)"
            ]
        , describe "columnValue"
            [ testParser ( "basic", Parsers.columnValue ) "0" "0"
            , testParser ( "with dot", Parsers.columnValue ) "0.0" "0.0"
            , testParser ( "with spaces", Parsers.columnName ) "\"default value\"" "default value"
            ]
        , describe "notes"
            [ testParser ( "basic", Parsers.notes ) "| a note" "a note"
            , testParser ( "no space", Parsers.notes ) "|a note" "a note"
            , testParser ( "with #", Parsers.notes ) "| \"a # note\"" "a # note"
            ]
        , describe "comment"
            [ testParser ( "basic", Parsers.comment ) "# a comment" "a comment"
            ]
        ]


table : AmlTable
table =
    { schema = Nothing, table = "", props = Nothing, notes = Nothing, comment = Nothing, columns = [] }


column : AmlColumn
column =
    { name = "", kind = Nothing, default = Nothing, nullable = False, primaryKey = False, index = Nothing, unique = Nothing, check = Nothing, foreignKey = Nothing, props = Nothing, notes = Nothing, comment = Nothing }
