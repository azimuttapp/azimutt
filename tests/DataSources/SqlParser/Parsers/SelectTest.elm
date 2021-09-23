module DataSources.SqlParser.Parsers.SelectTest exposing (..)

import DataSources.SqlParser.Parsers.Select exposing (SelectColumn(..), SelectColumnBasic, SelectTable(..), SelectTableBasic, parseSelect, parseSelectColumn, parseSelectTable)
import DataSources.SqlParser.TestHelpers.Tests exposing (testParseSql)
import Libs.Nel exposing (Nel)
import Test exposing (Test, describe)


suite : Test
suite =
    describe "Select"
        [ describe "parseSelect"
            [ testParseSql ( parseSelect, "basic" )
                "SELECT id, name FROM users"
                { columns =
                    Nel (BasicColumn { column | column = "id" })
                        [ BasicColumn { column | column = "name" } ]
                , tables = [ BasicTable { table | table = "users" } ]
                , whereClause = Nothing
                }
            , testParseSql ( parseSelect, "distinct on" )
                "SELECT DISTINCT ON (id) id, name FROM users"
                { columns =
                    Nel (BasicColumn { column | column = "id" })
                        [ BasicColumn { column | column = "name" } ]
                , tables = [ BasicTable { table | table = "users" } ]
                , whereClause = Nothing
                }
            ]
        , describe "parseSelectColumn"
            [ testParseSql ( parseSelectColumn, "basic" )
                "id"
                (BasicColumn { column | column = "id" })
            , testParseSql ( parseSelectColumn, "with table" )
                "users.id"
                (BasicColumn { column | table = Just "users", column = "id" })
            , testParseSql ( parseSelectColumn, "with alias" )
                "id AS my_id"
                (BasicColumn { column | column = "id", alias = Just "my_id" })
            , testParseSql ( parseSelectColumn, "with everything" )
                "users.id AS my_id"
                (BasicColumn { column | table = Just "users", column = "id", alias = Just "my_id" })
            , testParseSql ( parseSelectColumn, "no space before as" )
                "`tasks`.`metadata`as `metadata`"
                (BasicColumn { column | table = Just "tasks", column = "metadata", alias = Just "metadata" })
            , testParseSql ( parseSelectColumn, "remove quotes" )
                "users.\"id\""
                (BasicColumn { column | table = Just "users", column = "id" })
            , testParseSql ( parseSelectColumn, "with space in alias" )
                "a.postal_code AS \"zip code\""
                (BasicColumn { column | table = Just "a", column = "postal_code", alias = Just "zip code" })
            , testParseSql ( parseSelectColumn, "null" )
                "NULL::bigint AS id"
                (ComplexColumn { formula = "NULL::bigint", alias = "id" })
            , testParseSql ( parseSelectColumn, "with function" )
                "length((users.name)::text) AS name_length"
                (ComplexColumn { formula = "length((users.name)::text)", alias = "name_length" })
            , testParseSql ( parseSelectColumn, "with multi function" )
                "((users.phone IS NULL) AND (users.old_phone IS NOT NULL)) AS has_deleted_phone"
                (ComplexColumn { formula = "((users.phone IS NULL) AND (users.old_phone IS NOT NULL))", alias = "has_deleted_phone" })
            , testParseSql ( parseSelectColumn, "complex" )
                "encode(public.digest(trackers.\"to\", 'sha256'::text), 'hex'::text) AS to_hashed"
                (ComplexColumn { formula = "encode(public.digest(trackers.\"to\", 'sha256'::text), 'hex'::text)", alias = "to_hashed" })
            , testParseSql ( parseSelectColumn, "very complex" )
                "CASE WHEN ((COALESCE(users.email, ''::character varying))::text <> ''::text) THEN true ELSE false END AS has_email"
                (ComplexColumn { formula = "CASE WHEN ((COALESCE(users.email, ''::character varying))::text <> ''::text) THEN true ELSE false END", alias = "has_email" })
            ]
        , describe "parseSelectTable"
            [ testParseSql ( parseSelectTable, "basic" )
                "users"
                (BasicTable { table | table = "users" })
            , testParseSql ( parseSelectTable, "with schema" )
                "public.users"
                (BasicTable { table | schema = Just "public", table = "users" })
            , testParseSql ( parseSelectTable, "with alias" )
                "users u"
                (BasicTable { table | table = "users", alias = Just "u" })
            , testParseSql ( parseSelectTable, "with everything" )
                "public.users u"
                (BasicTable { table | schema = Just "public", table = "users", alias = Just "u" })
            ]
        ]


column : SelectColumnBasic
column =
    { table = Nothing, column = "changeme", alias = Nothing }


table : SelectTableBasic
table =
    { schema = Nothing, table = "changeme", alias = Nothing }
