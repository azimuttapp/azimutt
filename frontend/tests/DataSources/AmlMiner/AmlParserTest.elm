module DataSources.AmlMiner.AmlParserTest exposing (..)

import DataSources.AmlMiner.AmlParser as AmlParser exposing (AmlColumn, AmlParsedColumnType, AmlStatement(..), AmlTable)
import Dict
import Expect
import Libs.Nel as Nel exposing (Nel)
import Libs.Tailwind as Color
import Parser exposing (DeadEnd, Parser, Problem(..))
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "AmlParser"
        [ describe "aml"
            [ parserTest ( "empty", AmlParser.parser ) "" []
            , parserTest ( "script", AmlParser.parser )
                ("\n"
                    ++ "users\n"
                    ++ "  id int\n"
                    ++ "  name varchar(12)\n"
                    ++ "\n"
                    ++ "talks\n"
                    ++ "  id int\n"
                    ++ "  title varchar(140)\n"
                    ++ "  speaker int fk users.id\n"
                    ++ "\n"
                )
                [ AmlEmptyStatement { comment = Nothing }
                , AmlTableStatement
                    { table
                        | table = "users"
                        , columns =
                            [ { column | name = "id", kind = Just "int" }
                            , { column | name = "name", kind = Just "varchar(12)" }
                            ]
                    }
                , AmlEmptyStatement { comment = Nothing }
                , AmlTableStatement
                    { table
                        | table = "talks"
                        , columns =
                            [ { column | name = "id", kind = Just "int" }
                            , { column | name = "title", kind = Just "varchar(140)" }
                            , { column | name = "speaker", kind = Just "int", foreignKey = Just { schema = Nothing, table = "users", column = "id" } }
                            ]
                    }
                , AmlEmptyStatement { comment = Nothing }
                ]
            , parserTest ( "multiline", AmlParser.parser )
                """
emails
  email varchar
  score "double precision"

# How to define a table and it's columns
public.users {color=red, top=10, left=20} | Table description # a table with everything!
  id int pk
  role varchar=guest {hidden}
  score "double precision"=0.0 index {hidden} | User progression # a column with almost all possible attributes
  first_name varchar(10) unique=name
  last_name varchar(10) unique=name
  email varchar nullable fk emails.email

admins* | View of `users` table with only admins
  id
  name | Computed from user first_name and last_name

fk admins.id -> users.id

"""
                [ AmlEmptyStatement { comment = Nothing }
                , AmlTableStatement
                    { table
                        | table = "emails"
                        , columns =
                            [ { column | name = "email", kind = Just "varchar" }
                            , { column | name = "score", kind = Just "double precision" }
                            ]
                    }
                , AmlEmptyStatement { comment = Nothing }
                , AmlEmptyStatement { comment = Just "How to define a table and it's columns" }
                , AmlTableStatement
                    { table
                        | schema = Just "public"
                        , table = "users"
                        , props = Just { color = Just Color.red, position = Just { top = 10, left = 20 } }
                        , notes = Just "Table description"
                        , comment = Just "a table with everything!"
                        , columns =
                            [ { column | name = "id", kind = Just "int", primaryKey = True }
                            , { column | name = "role", kind = Just "varchar", default = Just "guest", props = Just { hidden = True } }
                            , { column | name = "score", kind = Just "double precision", default = Just "0.0", index = Just "", props = Just { hidden = True }, notes = Just "User progression", comment = Just "a column with almost all possible attributes" }
                            , { column | name = "first_name", kind = Just "varchar(10)", unique = Just "name" }
                            , { column | name = "last_name", kind = Just "varchar(10)", unique = Just "name" }
                            , { column | name = "email", kind = Just "varchar", nullable = True, foreignKey = Just { schema = Nothing, table = "emails", column = "email" } }
                            ]
                    }
                , AmlEmptyStatement { comment = Nothing }
                , AmlTableStatement
                    { table
                        | table = "admins"
                        , isView = True
                        , notes = Just "View of `users` table with only admins"
                        , columns =
                            [ { column | name = "id" }
                            , { column | name = "name", notes = Just "Computed from user first_name and last_name" }
                            ]
                    }
                , AmlEmptyStatement { comment = Nothing }
                , AmlRelationStatement { from = { schema = Nothing, table = "admins", column = "id" }, to = { schema = Nothing, table = "users", column = "id" }, comment = Nothing }
                , AmlEmptyStatement { comment = Nothing }
                ]

            --, parserTest ( "space tolerant", AmlParser.parser )
            --    (""
            --        ++ "users\n"
            --        ++ "  id\n"
            --        ++ "  \n"
            --        ++ "\n"
            --        ++ "events\n"
            --        ++ "  id\n"
            --    )
            --    [ AmlTableStatement { table | table = "users", columns = [ { column | name = "id" } ] }
            --    , AmlEmptyStatement { comment = Nothing }
            --    , AmlEmptyStatement { comment = Nothing }
            --    , AmlTableStatement { table | table = "events", columns = [ { column | name = "id" } ] }
            --    ]
            , parserFail ( "ExpectingSymbol", AmlParser.parser ) "users\n  id fk bad\n" [ { row = 2, col = 12, problem = ExpectingSymbol "." } ]
            , parserFail ( "UnexpectedChar", AmlParser.parser ) "users\n  id fk bad.\n" [ { row = 2, col = 13, problem = UnexpectedChar }, { row = 2, col = 13, problem = UnexpectedChar } ]
            ]
        , describe "statement"
            [ parserTest ( "table", AmlParser.statement ) "users\n  id int\n" (AmlTableStatement { table | table = "users", columns = [ { column | name = "id", kind = Just "int" } ] })
            , parserTest ( "relation", AmlParser.statement ) "fk from.to_id -> to.id\n" (AmlRelationStatement { from = { schema = Nothing, table = "from", column = "to_id" }, to = { schema = Nothing, table = "to", column = "id" }, comment = Nothing })
            , parserTest ( "comment", AmlParser.statement ) "# comment\n" (AmlEmptyStatement { comment = Just "comment" })
            ]
        , describe "empty"
            [ parserTest ( "base", AmlParser.empty ) "\n" { comment = Nothing }
            , parserFail ( "with spaces", AmlParser.empty ) "   \n" [ { row = 1, col = 1, problem = ExpectingSymbol "\n" } ]
            , parserTest ( "with comment", AmlParser.empty ) "# comment  \n" { comment = Just "comment" }
            , parserFail ( "with spaces and comment", AmlParser.empty ) "   #  comment  \n" [ { row = 1, col = 1, problem = ExpectingSymbol "\n" } ]
            ]
        , describe "relation"
            [ parserTest ( "base", AmlParser.relation ) "fk from.to_id -> to.id\n" { from = { schema = Nothing, table = "from", column = "to_id" }, to = { schema = Nothing, table = "to", column = "id" }, comment = Nothing }
            , parserTest ( "with comment", AmlParser.relation ) "fk from.to_id -> to.id # comment\n" { from = { schema = Nothing, table = "from", column = "to_id" }, to = { schema = Nothing, table = "to", column = "id" }, comment = Just "comment" }
            ]
        , describe "table"
            [ parserTest ( "name", AmlParser.table ) "users\n" { table | table = "users" }
            , parserTest ( "with schema", AmlParser.table ) "public.users\n" { table | schema = Just "public", table = "users" }
            , parserTest ( "is view", AmlParser.table ) "users*\n" { table | table = "users", isView = True }
            , parserTest ( "with props", AmlParser.table ) "users {color=red}\n" { table | table = "users", props = Just { color = Just Color.red, position = Nothing } }
            , parserTest ( "with notes", AmlParser.table ) "users | note\n" { table | table = "users", notes = Just "note" }
            , parserTest ( "with comment", AmlParser.table ) "users # comment\n" { table | table = "users", comment = Just "comment" }
            , parserTest ( "with all", AmlParser.table ) "public.users* {color=red, left=20, top=10} | a note # a comment\n" { schema = Just "public", table = "users", isView = True, props = Just { color = Just Color.red, position = Just { left = 20, top = 10 } }, notes = Just "a note", comment = Just "a comment", columns = [] }
            , parserTest ( "with columns", AmlParser.table ) "users\n  id int\n  name varchar\n" { table | table = "users", columns = [ { column | name = "id", kind = Just "int" }, { column | name = "name", kind = Just "varchar" } ] }
            ]
        , describe "column"
            [ parserTest ( "name", AmlParser.column ) "  id\n" { column | name = "id" }
            , parserTest ( "with type", AmlParser.column ) "  id int\n" { column | name = "id", kind = Just "int" }
            , parserTest ( "with default value", AmlParser.column ) "  id int=0\n" { column | name = "id", kind = Just "int", default = Just "0" }
            , parserTest ( "with nullable", AmlParser.column ) "  id nullable\n" { column | name = "id", nullable = True }
            , parserTest ( "with type & nullable", AmlParser.column ) "  id int nullable\n" { column | name = "id", kind = Just "int", nullable = True }
            , parserTest ( "with pk", AmlParser.column ) "  id pk\n" { column | name = "id", primaryKey = True }
            , parserTest ( "with type & pk", AmlParser.column ) "  id int pk\n" { column | name = "id", kind = Just "int", primaryKey = True }
            , parserTest ( "with index", AmlParser.column ) "  id index\n" { column | name = "id", index = Just "" }
            , parserTest ( "with type & index", AmlParser.column ) "  id int index\n" { column | name = "id", kind = Just "int", index = Just "" }
            , parserTest ( "with unique", AmlParser.column ) "  id unique\n" { column | name = "id", unique = Just "" }
            , parserTest ( "with type & unique", AmlParser.column ) "  id int unique\n" { column | name = "id", kind = Just "int", unique = Just "" }
            , parserTest ( "with check", AmlParser.column ) "  id check\n" { column | name = "id", check = Just "" }
            , parserTest ( "with type & check", AmlParser.column ) "  id int check\n" { column | name = "id", kind = Just "int", check = Just "" }
            , parserTest ( "with fk", AmlParser.column ) "  id fk logins.id\n" { column | name = "id", foreignKey = Just { schema = Nothing, table = "logins", column = "id" } }
            , parserTest ( "with type & fk", AmlParser.column ) "  id int fk logins.id\n" { column | name = "id", kind = Just "int", foreignKey = Just { schema = Nothing, table = "logins", column = "id" } }
            , parserTest ( "with props", AmlParser.column ) "  id {hidden}\n" { column | name = "id", props = Just { hidden = True } }
            , parserTest ( "with type & props", AmlParser.column ) "  id int {hidden}\n" { column | name = "id", kind = Just "int", props = Just { hidden = True } }
            , parserTest ( "with notes", AmlParser.column ) "  id | note\n" { column | name = "id", notes = Just "note" }
            , parserTest ( "with type & notes", AmlParser.column ) "  id int | note\n" { column | name = "id", kind = Just "int", notes = Just "note" }
            , parserTest ( "with comment", AmlParser.column ) "  id # comment\n" { column | name = "id", comment = Just "comment" }
            , parserTest ( "with type & comment", AmlParser.column ) "  id int # comment\n" { column | name = "id", kind = Just "int", comment = Just "comment" }
            , parserTest ( "with all", AmlParser.column ) "  id p.int(0, 1, 2)=0 nullable pk index unique=main check=id>0 fk public.logins.id {hidden} | a note # a comment\n" { name = "id", kind = Just "int", kindSchema = Just "p", values = Just (Nel "0" [ "1", "2" ]), default = Just "0", nullable = True, primaryKey = True, index = Just "", unique = Just "main", check = Just "id>0", foreignKey = Just { schema = Just "public", table = "logins", column = "id" }, props = Just { hidden = True }, notes = Just "a note", comment = Just "a comment" }
            , parserFail ( "UnexpectedChar", AmlParser.column ) "  id fk bad.\n" [ { row = 1, col = 13, problem = UnexpectedChar }, { row = 1, col = 13, problem = UnexpectedChar } ]
            ]
        , describe "constraint"
            [ parserTest ( "lowercase", AmlParser.constraint "index" ) "index" ""
            , parserTest ( "uppercase", AmlParser.constraint "index" ) "INDEX" ""
            , parserTest ( "with value", AmlParser.constraint "index" ) "index=test" "test"
            , parserTest ( "with spaced value", AmlParser.constraint "index" ) "index = \"a test\"" "a test"
            , parserTest ( "with empty value", AmlParser.constraint "index" ) "index=" ""
            ]
        , describe "tableProps"
            [ parserTest ( "empty", AmlParser.tableProps ) "{}" { position = Nothing, color = Nothing }
            , parserTest ( "color", AmlParser.tableProps ) "{color=red}" { position = Nothing, color = Just Color.red }
            , parserTest ( "position", AmlParser.tableProps ) "{left=20, top=10}" { position = Just { left = 20, top = 10 }, color = Nothing }
            , parserTest ( "both", AmlParser.tableProps ) "{color=red, left=20, top=10}" { position = Just { left = 20, top = 10 }, color = Just Color.red }
            , parserFail ( "bad color", AmlParser.tableProps ) "{color=bad}" [ { row = 1, col = 12, problem = Problem "Unknown color 'bad'" } ]
            , parserFail ( "bad left", AmlParser.tableProps ) "{left=a}" [ { row = 1, col = 9, problem = Problem "Property 'left' should be a number" } ]
            , parserFail ( "bad top", AmlParser.tableProps ) "{top=a}" [ { row = 1, col = 8, problem = Problem "Property 'top' should be a number" } ]
            , parserFail ( "no top", AmlParser.tableProps ) "{left=10}" [ { row = 1, col = 10, problem = Problem "Missing property 'top'" } ]
            , parserFail ( "no left", AmlParser.tableProps ) "{top=10}" [ { row = 1, col = 9, problem = Problem "Missing property 'left'" } ]
            , parserFail ( "unknown prop", AmlParser.tableProps ) "{wat=10}" [ { row = 1, col = 9, problem = Problem "Unknown property 'wat'" } ]
            ]
        , describe "columnProps"
            [ parserTest ( "empty", AmlParser.columnProps ) "{}" { hidden = False }
            , parserTest ( "hidden", AmlParser.columnProps ) "{hidden}" { hidden = True }
            , parserTest ( "hidden=", AmlParser.columnProps ) "{hidden=}" { hidden = True }
            , parserFail ( "hidden=true", AmlParser.columnProps ) "{hidden=true}" [ { row = 1, col = 14, problem = Problem "Property 'hidden' should have no value" } ]
            , parserFail ( "unknown prop", AmlParser.columnProps ) "{wat=10}" [ { row = 1, col = 9, problem = Problem "Unknown property 'wat'" } ]
            ]
        , describe "properties"
            [ parserTest ( "empty", AmlParser.properties ) "{}" Dict.empty
            , parserTest ( "empty with spaces", AmlParser.properties ) "{ }" Dict.empty
            , parserTest ( "key/value", AmlParser.properties ) "{ top = 20, flag }" (Dict.fromList [ ( "top", "20" ), ( "flag", "" ) ])
            ]
        , describe "property"
            [ parserTest ( "key/value", AmlParser.property ) "key=value" ( "key", "value" )
            , parserTest ( "key/value with spaces", AmlParser.property ) "key = value" ( "key", "value" )
            , parserTest ( "key/value with more spaces", AmlParser.property ) "\"a key\" = \"a value\"" ( "a key", "a value" )
            , parserTest ( "flag", AmlParser.property ) "flag" ( "flag", "" )
            , parserTest ( "flag with spaces", AmlParser.property ) "\"a flag\"" ( "a flag", "" )
            ]
        , describe "tableRef"
            [ parserTest ( "table and schema", AmlParser.tableRef ) "public.users" { schema = Just "public", table = "users" }
            , parserTest ( "table only", AmlParser.tableRef ) "users" { schema = Nothing, table = "users" }
            , parserTest ( "with spaces", AmlParser.tableRef ) "\"a schema\".\"a table\"" { schema = Just "a schema", table = "a table" }
            ]
        , describe "columnRef"
            [ parserTest ( "column, table and schema", AmlParser.columnRef ) "public.users.id" { schema = Just "public", table = "users", column = "id" }
            , parserTest ( "column and table", AmlParser.columnRef ) "users.id" { schema = Nothing, table = "users", column = "id" }
            , parserTest ( "with spaces", AmlParser.columnRef ) "\"a schema\".\"a table\".\"a column\"" { schema = Just "a schema", table = "a table", column = "a column" }
            , parserFail ( "UnexpectedChar", AmlParser.columnRef ) "bad." [ { row = 1, col = 5, problem = UnexpectedChar }, { row = 1, col = 5, problem = UnexpectedChar } ]
            ]
        , describe "schemaName"
            [ parserTest ( "basic", AmlParser.schemaName ) "public" "public"
            , parserTest ( "with spaces", AmlParser.schemaName ) "\"a schema\"" "a schema"
            , parserTest ( "with dot", AmlParser.schemaName ) "\"a.schema\"" "a.schema"
            ]
        , describe "tableName"
            [ parserTest ( "basic", AmlParser.tableName ) "users" "users"
            , parserTest ( "with spaces", AmlParser.tableName ) "\"a table\"" "a table"
            , parserFail ( "UnexpectedChar", AmlParser.tableName ) "" [ { row = 1, col = 1, problem = UnexpectedChar }, { row = 1, col = 1, problem = UnexpectedChar } ]
            ]
        , describe "columnName"
            [ parserTest ( "basic", AmlParser.columnName ) "id" "id"
            , parserTest ( "with spaces", AmlParser.columnName ) "\"a column\"" "a column"
            ]
        , describe "columnType"
            [ parserTest ( "basic", AmlParser.columnType ) "number" { parsedType | name = "number" }
            , parserTest ( "with space", AmlParser.columnType ) "\"character varying\"" { parsedType | name = "character varying" }
            , parserTest ( "with precision", AmlParser.columnType ) "varchar(12)" { parsedType | name = "varchar(12)" }
            , parserTest ( "with space before precision", AmlParser.columnType ) "varchar (12)" { parsedType | name = "varchar(12)" }
            , parserTest ( "with 2 precisions", AmlParser.columnType ) "decimal(5,2)" { parsedType | name = "decimal(5, 2)" }
            , parserTest ( "with 2 precisions & space", AmlParser.columnType ) "decimal(5, 2)" { parsedType | name = "decimal(5, 2)" }
            , parserTest ( "enum", AmlParser.columnType ) "user_role(guest, admin)" { parsedType | name = "user_role", values = Nel.fromList [ "guest", "admin" ] }
            , parserTest ( "enum with schema", AmlParser.columnType ) "public.user_role(guest, admin)" { parsedType | schema = Just "public", name = "user_role", values = Nel.fromList [ "guest", "admin" ] }
            , parserTest ( "with default", AmlParser.columnType ) "varchar=val" { parsedType | name = "varchar", default = Just "val" }
            , parserTest ( "with default & space", AmlParser.columnType ) "varchar = val" { parsedType | name = "varchar", default = Just "val" }
            , parserTest ( "with space in default", AmlParser.columnType ) "varchar=\"a val\"" { parsedType | name = "varchar", default = Just "a val" }
            , parserTest ( "with enum and default", AmlParser.columnType ) "user_role(guest, admin)=admin" { parsedType | name = "user_role", values = Nel.fromList [ "guest", "admin" ], default = Just "admin" }
            , parserTest ( "with everything", AmlParser.columnType ) "\"my schema\".\"my type\" ( val 1 , \"val2 \" ) = \"val 1\"" { schema = Just "my schema", name = "my type", values = Nel.fromList [ "val 1", "val2" ], default = Just "val 1" }
            ]
        , describe "columnValue"
            [ parserTest ( "basic", AmlParser.columnValue ) "0" "0"
            , parserTest ( "with dot", AmlParser.columnValue ) "0.0" "0.0"
            , parserTest ( "with spaces", AmlParser.columnValue ) "\"default value\"" "default value"
            ]
        , describe "notes"
            [ parserTest ( "basic", AmlParser.notes ) "| a note" "a note"
            , parserTest ( "no space", AmlParser.notes ) "|a note" "a note"
            , parserTest ( "with #", AmlParser.notes ) "| \"a # note\"" "a # note"
            ]
        , describe "comment"
            [ parserTest ( "basic", AmlParser.comment ) "# a comment" "a comment"
            ]
        ]


table : AmlTable
table =
    { schema = Nothing, table = "", isView = False, props = Nothing, notes = Nothing, comment = Nothing, columns = [] }


column : AmlColumn
column =
    { name = "", kind = Nothing, kindSchema = Nothing, values = Nothing, default = Nothing, nullable = False, primaryKey = False, index = Nothing, unique = Nothing, check = Nothing, foreignKey = Nothing, props = Nothing, notes = Nothing, comment = Nothing }


parsedType : AmlParsedColumnType
parsedType =
    { schema = Nothing, name = "", values = Nothing, default = Nothing }


parserTest : ( String, Parser a ) -> String -> a -> Test
parserTest ( name, parser ) input result =
    test name (\_ -> input |> Parser.run parser |> Expect.equal (Ok result))


parserFail : ( String, Parser a ) -> String -> List DeadEnd -> Test
parserFail ( name, parser ) input errors =
    test name (\_ -> input |> Parser.run parser |> Expect.equal (Err errors))
