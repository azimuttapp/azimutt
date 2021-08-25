module DataSources.SqlParser.Parsers.SelectTest exposing (..)

import DataSources.SqlParser.Parsers.Select exposing (SelectColumn(..), SelectTable(..), parseSelect, parseSelectColumn, parseSelectTable)
import Expect
import Libs.Nel exposing (Nel)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Select"
        [ describe "parseSelect"
            [ test "basic"
                (\_ ->
                    parseSelect "SELECT id, name FROM users"
                        |> Expect.equal
                            (Ok
                                { columns =
                                    Nel (BasicColumn { table = Nothing, column = "id", alias = Nothing })
                                        [ BasicColumn { table = Nothing, column = "name", alias = Nothing } ]
                                , tables = [ BasicTable { schema = Nothing, table = "users", alias = Nothing } ]
                                , whereClause = Nothing
                                }
                            )
                )
            , test "distinct on"
                (\_ ->
                    parseSelect "SELECT DISTINCT ON (id) id, name FROM users"
                        |> Expect.equal
                            (Ok
                                { columns =
                                    Nel (BasicColumn { table = Nothing, column = "id", alias = Nothing })
                                        [ BasicColumn { table = Nothing, column = "name", alias = Nothing } ]
                                , tables = [ BasicTable { schema = Nothing, table = "users", alias = Nothing } ]
                                , whereClause = Nothing
                                }
                            )
                )
            ]
        , describe "parseSelectColumn"
            [ test "basic" (\_ -> parseSelectColumn "id" |> Expect.equal (Ok (BasicColumn { table = Nothing, column = "id", alias = Nothing })))
            , test "with table" (\_ -> parseSelectColumn "users.id" |> Expect.equal (Ok (BasicColumn { table = Just "users", column = "id", alias = Nothing })))
            , test "with alias" (\_ -> parseSelectColumn "id AS my_id" |> Expect.equal (Ok (BasicColumn { table = Nothing, column = "id", alias = Just "my_id" })))
            , test "with everything" (\_ -> parseSelectColumn "users.id AS my_id" |> Expect.equal (Ok (BasicColumn { table = Just "users", column = "id", alias = Just "my_id" })))
            , test "remove quotes" (\_ -> parseSelectColumn "users.\"id\"" |> Expect.equal (Ok (BasicColumn { table = Just "users", column = "id", alias = Nothing })))
            , test "null" (\_ -> parseSelectColumn "NULL::bigint AS id" |> Expect.equal (Ok (ComplexColumn { formula = "NULL::bigint", alias = "id" })))
            , test "with function" (\_ -> parseSelectColumn "length((users.name)::text) AS name_length" |> Expect.equal (Ok (ComplexColumn { formula = "length((users.name)::text)", alias = "name_length" })))
            , test "with multi function" (\_ -> parseSelectColumn "((users.phone IS NULL) AND (users.old_phone IS NOT NULL)) AS has_deleted_phone" |> Expect.equal (Ok (ComplexColumn { formula = "((users.phone IS NULL) AND (users.old_phone IS NOT NULL))", alias = "has_deleted_phone" })))
            , test "complex" (\_ -> parseSelectColumn "encode(public.digest(trackers.\"to\", 'sha256'::text), 'hex'::text) AS to_hashed" |> Expect.equal (Ok (ComplexColumn { formula = "encode(public.digest(trackers.\"to\", 'sha256'::text), 'hex'::text)", alias = "to_hashed" })))
            , test "very complex" (\_ -> parseSelectColumn "CASE WHEN ((COALESCE(users.email, ''::character varying))::text <> ''::text) THEN true ELSE false END AS has_email" |> Expect.equal (Ok (ComplexColumn { formula = "CASE WHEN ((COALESCE(users.email, ''::character varying))::text <> ''::text) THEN true ELSE false END", alias = "has_email" })))
            ]
        , describe "parseSelectTable"
            [ test "basic" (\_ -> parseSelectTable "users" |> Expect.equal (Ok (BasicTable { schema = Nothing, table = "users", alias = Nothing })))
            , test "with schema" (\_ -> parseSelectTable "public.users" |> Expect.equal (Ok (BasicTable { schema = Just "public", table = "users", alias = Nothing })))
            , test "with alias" (\_ -> parseSelectTable "users u" |> Expect.equal (Ok (BasicTable { schema = Nothing, table = "users", alias = Just "u" })))
            , test "with everything" (\_ -> parseSelectTable "public.users u" |> Expect.equal (Ok (BasicTable { schema = Just "public", table = "users", alias = Just "u" })))
            ]
        ]
