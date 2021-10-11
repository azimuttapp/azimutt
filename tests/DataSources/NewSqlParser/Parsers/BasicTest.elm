module DataSources.NewSqlParser.Parsers.BasicTest exposing (..)

import DataSources.NewSqlParser.Parsers.Basic exposing (columnNameParser, columnTypeParser, defaultValueParser, notNullParser, primaryKeyParser, schemaNameParser, tableNameParser, tableRefParser)
import Expect
import Parser
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Basic"
        [ describe "tableRefParser"
            [ test "no schema" (\_ -> "table" |> Parser.run tableRefParser |> Expect.equal (Ok ( Nothing, "table" )))
            , test "with schema" (\_ -> "schema.table" |> Parser.run tableRefParser |> Expect.equal (Ok ( Just "schema", "table" )))
            , test "with brackets" (\_ -> "schema.[Table]" |> Parser.run tableRefParser |> Expect.equal (Ok ( Just "schema", "Table" )))
            ]
        , describe "schemaNameParser"
            [ test "basic" (\_ -> "schema" |> Parser.run schemaNameParser |> Expect.equal (Ok "schema"))
            ]
        , describe "tableNameParser"
            [ test "basic" (\_ -> "table" |> Parser.run tableNameParser |> Expect.equal (Ok "table"))
            , test "brackets" (\_ -> "[table]" |> Parser.run tableNameParser |> Expect.equal (Ok "table"))
            ]
        , describe "columnNameParser"
            [ test "basic" (\_ -> "column" |> Parser.run columnNameParser |> Expect.equal (Ok "column"))
            , test "space" (\_ -> "column " |> Parser.run columnTypeParser |> Expect.equal (Ok "column"))
            , test "quoted" (\_ -> "'column'" |> Parser.run columnNameParser |> Expect.equal (Ok "column"))
            , test "double quoted" (\_ -> "\"column\"" |> Parser.run columnNameParser |> Expect.equal (Ok "column"))
            , test "back quoted" (\_ -> "`column`" |> Parser.run columnNameParser |> Expect.equal (Ok "column"))
            , test "brackets" (\_ -> "[column]" |> Parser.run columnNameParser |> Expect.equal (Ok "column"))
            , test "quoted with space" (\_ -> "'a column'" |> Parser.run columnNameParser |> Expect.equal (Ok "a column"))
            , test "brackets with space" (\_ -> "[a column]" |> Parser.run columnNameParser |> Expect.equal (Ok "a column"))
            ]
        , describe "columnTypeParser"
            [ test "basic" (\_ -> "INT" |> Parser.run columnTypeParser |> Expect.equal (Ok "INT"))
            , test "space stop" (\_ -> "INT " |> Parser.run columnTypeParser |> Expect.equal (Ok "INT"))
            , test "comma stop" (\_ -> "INT," |> Parser.run columnTypeParser |> Expect.equal (Ok "INT"))
            , test "parenthesis stop" (\_ -> "INT)" |> Parser.run columnTypeParser |> Expect.equal (Ok "INT"))
            , test "bit varying" (\_ -> "bit varying(8)" |> Parser.run columnTypeParser |> Expect.equal (Ok "bit varying(8)"))
            , test "character varying" (\_ -> "character varying ( 255 )" |> Parser.run columnTypeParser |> Expect.equal (Ok "character varying(255)"))
            , test "double precision" (\_ -> "double precision" |> Parser.run columnTypeParser |> Expect.equal (Ok "double precision"))
            , test "numeric" (\_ -> "numeric(4, 2)" |> Parser.run columnTypeParser |> Expect.equal (Ok "numeric(4, 2)"))
            ]
        , describe "notNullParser"
            [ test "not null" (\_ -> "NOT NULL" |> Parser.run notNullParser |> Expect.equal (Ok False))
            , test "nullable" (\_ -> "" |> Parser.run notNullParser |> Expect.equal (Ok True))
            ]
        , describe "primaryKeyParser"
            [ test "primary key" (\_ -> "PRIMARY KEY" |> Parser.run primaryKeyParser |> Expect.equal (Ok (Just "")))
            , test "no primary key" (\_ -> "" |> Parser.run primaryKeyParser |> Expect.equal (Ok Nothing))
            ]
        , describe "defaultValueParser"
            [ test "no value" (\_ -> "" |> Parser.run defaultValueParser |> Expect.equal (Ok Nothing))
            , test "int value" (\_ -> "DEFAULT 42" |> Parser.run defaultValueParser |> Expect.equal (Ok (Just "42")))
            , test "string value" (\_ -> "DEFAULT 'some value'" |> Parser.run defaultValueParser |> Expect.equal (Ok (Just "some value")))
            , test "typed value" (\_ -> "DEFAULT '{}'::bigint[]" |> Parser.run defaultValueParser |> Expect.equal (Ok (Just "{}::bigint[]")))
            ]
        ]
