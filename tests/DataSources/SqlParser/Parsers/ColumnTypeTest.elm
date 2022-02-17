module DataSources.SqlParser.Parsers.ColumnTypeTest exposing (..)

import DataSources.SqlParser.Parsers.ColomnType exposing (parseColumnType, toString)
import Expect
import Test exposing (Test, describe, test)



-- [...new Set(projects['b2f2c260-3fbc-4b06-bb77-f0a00f9471a4'].sources.flatMap(s => s.tables).flatMap(t => t.columns).map(c => c.type))].sort()


suite : Test
suite =
    describe "ColumnType"
        [ describe "parseColumnType"
            [ test "unknown" (\_ -> "bad type" |> parseColumnType |> toString |> Expect.equal "bad type")
            , test "text" (\_ -> "text" |> parseColumnType |> toString |> Expect.equal "String")
            , test "character" (\_ -> "character" |> parseColumnType |> toString |> Expect.equal "String")
            , test "character(xx)" (\_ -> "character(36)" |> parseColumnType |> toString |> Expect.equal "String")
            , test "character varying" (\_ -> "character varying" |> parseColumnType |> toString |> Expect.equal "String")
            , test "character varying(xx)" (\_ -> "character varying(10)" |> parseColumnType |> toString |> Expect.equal "String")
            , test "integer" (\_ -> "integer" |> parseColumnType |> toString |> Expect.equal "Int")
            , test "bigint" (\_ -> "bigint" |> parseColumnType |> toString |> Expect.equal "Int")
            , test "smallint" (\_ -> "smallint" |> parseColumnType |> toString |> Expect.equal "Int")
            , test "numeric" (\_ -> "numeric" |> parseColumnType |> toString |> Expect.equal "Float")
            , test "numeric(x,y)" (\_ -> "numeric(4,2)" |> parseColumnType |> toString |> Expect.equal "Float")
            , test "double precision" (\_ -> "double precision" |> parseColumnType |> toString |> Expect.equal "Float")
            , test "boolean" (\_ -> "boolean" |> parseColumnType |> toString |> Expect.equal "Bool")
            , test "date" (\_ -> "date" |> parseColumnType |> toString |> Expect.equal "Date")
            , test "time without time zone" (\_ -> "time without time zone" |> parseColumnType |> toString |> Expect.equal "Time")
            , test "timestamp without time zone" (\_ -> "timestamp without time zone" |> parseColumnType |> toString |> Expect.equal "DateTime")
            , test "timestamp with time zone" (\_ -> "timestamp with time zone" |> parseColumnType |> toString |> Expect.equal "DateTime")
            , test "timestamp(x) without time zone" (\_ -> "timestamp(6) without time zone" |> parseColumnType |> toString |> Expect.equal "DateTime")
            , test "interval" (\_ -> "interval" |> parseColumnType |> toString |> Expect.equal "Interval")
            , test "interval(x)" (\_ -> "interval(6)" |> parseColumnType |> toString |> Expect.equal "Interval")
            , test "bytea" (\_ -> "bytea" |> parseColumnType |> toString |> Expect.equal "Binary")
            , test "uuid" (\_ -> "uuid" |> parseColumnType |> toString |> Expect.equal "Uuid")
            , test "bigint[]" (\_ -> "bigint[]" |> parseColumnType |> toString |> Expect.equal "Int[]")
            , test "character varying(xx)[]" (\_ -> "character varying(255)[]" |> parseColumnType |> toString |> Expect.equal "String[]")
            ]
        ]
