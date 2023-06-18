module Models.Project.ColumnTypeTest exposing (..)

import Expect
import Models.Project.ColumnType as ColumnType
import Test exposing (Test, describe, test)



-- get all types of a project:
-- [...new Set(projects['b2f2c260-3fbc-4b06-bb77-f0a00f9471a4'].sources.flatMap(s => s.tables).flatMap(t => t.columns).map(c => c.type))].sort()


suite : Test
suite =
    describe "ColumnType"
        [ describe "parseColumnType"
            [ testParse "bad type" "bad type"
            , testParse "text" "Text"
            , testParse "longtext" "Text"
            , testParse "tinytext" "Text"
            , testParse "mediumtext" "Text"
            , testParse "citext" "Text"
            , testParse "character" "Text"
            , testParse "character(36)" "Text"
            , testParse "character varying" "Text"
            , testParse "character varying(10)" "Text"
            , testParse "varchar(10)" "Text"
            , testParse "varchar(100) CHARACTER SET utf8mb4" "Text"
            , testParse "nchar(10)" "Text"
            , testParse "integer" "Int"
            , testParse "number(2)" "Int"
            , testParse "number(2, 0)" "Int"
            , testParse "tinyint(1)" "Int"
            , testParse "int(11)" "Int"
            , testParse "bigint" "Int"
            , testParse "bigint(10)" "Int"
            , testParse "bigint(20) unsigned" "Int"
            , testParse "smallint" "Int"
            , testParse "numeric" "Float"
            , testParse "numeric(4,2)" "Float"
            , testParse "double precision" "Float"
            , testParse "number" "Float"
            , testParse "number(4, 2)" "Float"
            , testParse "boolean" "Bool"
            , testParse "date" "Date"
            , testParse "time without time zone" "Time"
            , testParse "datetime" "Instant"
            , testParse "DATETIME" "Instant"
            , testParse "timestamp without time zone" "Instant"
            , testParse "timestamp with time zone" "Instant"
            , testParse "timestamp(6) without time zone" "Instant"
            , testParse "interval" "Interval"
            , testParse "interval(6)" "Interval"
            , testParse "bytea" "Binary"
            , testParse "uuid" "Uuid"
            , testParse "bigint[]" "Int[]"
            , testParse "character varying(255)[]" "Text[]"
            ]
        ]


testParse : String -> String -> Test
testParse input expected =
    test input (\_ -> input |> ColumnType.asBasic |> Expect.equal expected)
