module DataSources.SqlParser.Parsers.ColumnTypeTest exposing (..)

import DataSources.SqlParser.Parsers.ColomnType exposing (parse, toString)
import Expect
import Test exposing (Test, describe, test)



-- [...new Set(projects['b2f2c260-3fbc-4b06-bb77-f0a00f9471a4'].sources.flatMap(s => s.tables).flatMap(t => t.columns).map(c => c.type))].sort()


suite : Test
suite =
    describe "ColumnType"
        [ describe "parseColumnType"
            [ test "unknown" (\_ -> "bad type" |> parse |> toString |> Expect.equal "bad type")
            , test "text" (\_ -> "text" |> parse |> toString |> Expect.equal "String")
            , test "character" (\_ -> "character" |> parse |> toString |> Expect.equal "String")
            , test "character(xx)" (\_ -> "character(36)" |> parse |> toString |> Expect.equal "String")
            , test "character varying" (\_ -> "character varying" |> parse |> toString |> Expect.equal "String")
            , test "character varying(xx)" (\_ -> "character varying(10)" |> parse |> toString |> Expect.equal "String")
            , test "integer" (\_ -> "integer" |> parse |> toString |> Expect.equal "Int")
            , test "bigint" (\_ -> "bigint" |> parse |> toString |> Expect.equal "Int")
            , test "smallint" (\_ -> "smallint" |> parse |> toString |> Expect.equal "Int")
            , test "numeric" (\_ -> "numeric" |> parse |> toString |> Expect.equal "Float")
            , test "numeric(x,y)" (\_ -> "numeric(4,2)" |> parse |> toString |> Expect.equal "Float")
            , test "double precision" (\_ -> "double precision" |> parse |> toString |> Expect.equal "Float")
            , test "boolean" (\_ -> "boolean" |> parse |> toString |> Expect.equal "Bool")
            , test "date" (\_ -> "date" |> parse |> toString |> Expect.equal "Date")
            , test "time without time zone" (\_ -> "time without time zone" |> parse |> toString |> Expect.equal "Time")
            , test "timestamp without time zone" (\_ -> "timestamp without time zone" |> parse |> toString |> Expect.equal "DateTime")
            , test "timestamp with time zone" (\_ -> "timestamp with time zone" |> parse |> toString |> Expect.equal "DateTime")
            , test "timestamp(x) without time zone" (\_ -> "timestamp(6) without time zone" |> parse |> toString |> Expect.equal "DateTime")
            , test "interval" (\_ -> "interval" |> parse |> toString |> Expect.equal "Interval")
            , test "interval(x)" (\_ -> "interval(6)" |> parse |> toString |> Expect.equal "Interval")
            , test "bytea" (\_ -> "bytea" |> parse |> toString |> Expect.equal "Binary")
            , test "uuid" (\_ -> "uuid" |> parse |> toString |> Expect.equal "Uuid")
            , test "bigint[]" (\_ -> "bigint[]" |> parse |> toString |> Expect.equal "Int[]")
            , test "character varying(xx)[]" (\_ -> "character varying(255)[]" |> parse |> toString |> Expect.equal "String[]")
            ]
        ]
