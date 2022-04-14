module DataSources.SqlParser.Parsers.ColumnTypeTest exposing (..)

import DataSources.SqlParser.Parsers.ColumnType exposing (parse, toString)
import Expect
import Test exposing (Test, describe, test)



-- [...new Set(projects['b2f2c260-3fbc-4b06-bb77-f0a00f9471a4'].sources.flatMap(s => s.tables).flatMap(t => t.columns).map(c => c.type))].sort()


suite : Test
suite =
    describe "ColumnType"
        [ describe "parseColumnType"
            [ testParse "bad type" "bad type"
            , testParse "text" "String"
            , testParse "longtext" "String"
            , testParse "tinytext" "String"
            , testParse "mediumtext" "String"
            , testParse "character" "String"
            , testParse "character(36)" "String"
            , testParse "character varying" "String"
            , testParse "character varying(10)" "String"
            , testParse "integer" "Int"
            , testParse "tinyint(1)" "Int"
            , testParse "int(11)" "Int"
            , testParse "bigint" "Int"
            , testParse "bigint(10)" "Int"
            , testParse "bigint(20) unsigned" "Int"
            , testParse "smallint" "Int"
            , testParse "numeric" "Float"
            , testParse "numeric(4,2)" "Float"
            , testParse "double precision" "Float"
            , testParse "boolean" "Bool"
            , testParse "date" "Date"
            , testParse "time without time zone" "Time"
            , testParse "datetime" "DateTime"
            , testParse "DATETIME" "DateTime"
            , testParse "timestamp without time zone" "DateTime"
            , testParse "timestamp with time zone" "DateTime"
            , testParse "timestamp(6) without time zone" "DateTime"
            , testParse "interval" "Interval"
            , testParse "interval(6)" "Interval"
            , testParse "bytea" "Binary"
            , testParse "uuid" "Uuid"
            , testParse "bigint[]" "Int[]"
            , testParse "character varying(255)[]" "String[]"
            ]
        ]


testParse : String -> String -> Test
testParse input expected =
    test input (\_ -> input |> parse |> toString |> Expect.equal expected)
