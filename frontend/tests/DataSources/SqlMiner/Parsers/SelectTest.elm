module DataSources.SqlMiner.Parsers.SelectTest exposing (..)

import DataSources.SqlMiner.Parsers.Select exposing (SelectColumn(..), SelectColumnBasic, SelectTable(..), SelectTableBasic, parseSelect, parseSelectColumn, parseSelectTable, splitFirstTopLevelFrom)
import DataSources.SqlMiner.TestHelpers.Tests exposing (testSql)
import Expect
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Select"
        [ describe "parseSelect"
            [ testSql ( parseSelect, "basic" )
                "SELECT id, name FROM users"
                { columns = [ BasicColumn { column | column = "id" }, BasicColumn { column | column = "name" } ]
                , tables = [ BasicTable { table | table = "users" } ]
                , whereClause = Nothing
                }
            , testSql ( parseSelect, "distinct on" )
                "SELECT DISTINCT ON (id) id, name FROM users"
                { columns = [ BasicColumn { column | column = "id" }, BasicColumn { column | column = "name" } ]
                , tables = [ BasicTable { table | table = "users" } ]
                , whereClause = Nothing
                }
            , testSql ( parseSelect, "subquery in columns" )
                "SELECT pg_authid.rolname AS groname, pg_authid.oid AS grosysid, ARRAY(SELECT pg_auth_members.member FROM pg_auth_members WHERE (pg_auth_members.roleid = pg_authid.oid)) AS grolist FROM pg_authid WHERE (NOT pg_authid.rolcanlogin)"
                { columns =
                    [ BasicColumn { table = Just "pg_authid", column = "rolname", alias = Just "groname" }
                    , BasicColumn { table = Just "pg_authid", column = "oid", alias = Just "grosysid" }
                    , ComplexColumn { formula = "ARRAY(SELECT pg_auth_members.member FROM pg_auth_members WHERE (pg_auth_members.roleid = pg_authid.oid))", alias = "grolist" }
                    ]
                , tables = [ BasicTable { table | table = "pg_authid" } ]
                , whereClause = Just "(NOT pg_authid.rolcanlogin)"
                }
            ]
        , describe "parseSelectColumn"
            [ testSql ( parseSelectColumn, "basic" )
                "id"
                (BasicColumn { column | column = "id" })
            , testSql ( parseSelectColumn, "with table" )
                "users.id"
                (BasicColumn { column | table = Just "users", column = "id" })
            , testSql ( parseSelectColumn, "with alias" )
                "id AS my_id"
                (BasicColumn { column | column = "id", alias = Just "my_id" })
            , testSql ( parseSelectColumn, "with everything" )
                "users.id AS my_id"
                (BasicColumn { column | table = Just "users", column = "id", alias = Just "my_id" })
            , testSql ( parseSelectColumn, "no space before as" )
                "`tasks`.`metadata`as `metadata`"
                (BasicColumn { column | table = Just "tasks", column = "metadata", alias = Just "metadata" })
            , testSql ( parseSelectColumn, "remove quotes" )
                "users.\"id\""
                (BasicColumn { column | table = Just "users", column = "id" })
            , testSql ( parseSelectColumn, "with space in alias" )
                "a.postal_code AS \"zip code\""
                (BasicColumn { column | table = Just "a", column = "postal_code", alias = Just "zip code" })
            , testSql ( parseSelectColumn, "null" )
                "NULL::bigint AS id"
                (ComplexColumn { formula = "NULL::bigint", alias = "id" })
            , testSql ( parseSelectColumn, "with function" )
                "length((users.name)::text) AS name_length"
                (ComplexColumn { formula = "length((users.name)::text)", alias = "name_length" })
            , testSql ( parseSelectColumn, "with multi function" )
                "((users.phone IS NULL) AND (users.old_phone IS NOT NULL)) AS has_deleted_phone"
                (ComplexColumn { formula = "((users.phone IS NULL) AND (users.old_phone IS NOT NULL))", alias = "has_deleted_phone" })
            , testSql ( parseSelectColumn, "complex" )
                "encode(public.digest(trackers.\"to\", 'sha256'::text), 'hex'::text) AS to_hashed"
                (ComplexColumn { formula = "encode(public.digest(trackers.\"to\", 'sha256'::text), 'hex'::text)", alias = "to_hashed" })
            , testSql ( parseSelectColumn, "very complex" )
                "CASE WHEN ((COALESCE(users.email, ''::character varying))::text <> ''::text) THEN true ELSE false END AS has_email"
                (ComplexColumn { formula = "CASE WHEN ((COALESCE(users.email, ''::character varying))::text <> ''::text) THEN true ELSE false END", alias = "has_email" })
            ]
        , describe "parseSelectTable"
            [ testSql ( parseSelectTable, "basic" )
                "users"
                (BasicTable { table | table = "users" })
            , testSql ( parseSelectTable, "with schema" )
                "public.users"
                (BasicTable { table | schema = Just "public", table = "users" })
            , testSql ( parseSelectTable, "with alias" )
                "users u"
                (BasicTable { table | table = "users", alias = Just "u" })
            , testSql ( parseSelectTable, "with everything" )
                "public.users u"
                (BasicTable { table | schema = Just "public", table = "users", alias = Just "u" })
            ]
        , describe "splitFirstTopLevelFrom"
            [ test "split on first FROM" (\_ -> "hello FROM to FROM there" |> splitFirstTopLevelFrom |> Expect.equal ( "hello", "to FROM there" ))
            , test "ignore in ()" (\_ -> "hello (FROM to) FROM there" |> splitFirstTopLevelFrom |> Expect.equal ( "hello (FROM to)", "there" ))
            , test "ignore in ''" (\_ -> "hello 'FROM to' FROM there" |> splitFirstTopLevelFrom |> Expect.equal ( "hello 'FROM to'", "there" ))
            ]
        ]


column : SelectColumnBasic
column =
    { table = Nothing, column = "changeme", alias = Nothing }


table : SelectTableBasic
table =
    { schema = Nothing, table = "changeme", alias = Nothing }
