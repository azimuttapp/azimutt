module DataSources.SqlParser.Parsers.CreateTableTest exposing (..)

import DataSources.SqlParser.Parsers.CreateTable exposing (parseCreateTable, parseCreateTableColumn)
import DataSources.SqlParser.Utils.HelpersTest exposing (stmCheck)
import Expect
import Libs.Nel exposing (Nel)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "CreateTable"
        [ describe "parseCreateTable"
            [ stmCheck "basic" "CREATE TABLE aaa.bbb (ccc int);" parseCreateTable (\s -> Ok { schema = Just "aaa", table = "bbb", columns = Nel { name = "ccc", kind = "int", nullable = True, default = Nothing, primaryKey = Nothing, foreignKey = Nothing } [], primaryKey = Nothing, uniques = [], indexes = [], checks = [], source = s })
            , stmCheck "complex"
                "CREATE TABLE public.users (id bigint NOT NULL, name character varying(255), price numeric(8,2)) WITH (autovacuum_enabled='false');"
                parseCreateTable
                (\s ->
                    Ok
                        { schema = Just "public"
                        , table = "users"
                        , columns =
                            Nel { name = "id", kind = "bigint", nullable = False, default = Nothing, primaryKey = Nothing, foreignKey = Nothing }
                                [ { name = "name", kind = "character varying(255)", nullable = True, default = Nothing, primaryKey = Nothing, foreignKey = Nothing }
                                , { name = "price", kind = "numeric(8,2)", nullable = True, default = Nothing, primaryKey = Nothing, foreignKey = Nothing }
                                ]
                        , primaryKey = Nothing
                        , uniques = []
                        , indexes = []
                        , checks = []
                        , source = s
                        }
                )
            , stmCheck "with options" "CREATE TABLE p.table (id bigint NOT NULL)    WITH (autovacuum_analyze_threshold='100000');" parseCreateTable (\s -> Ok { schema = Just "p", table = "table", columns = Nel { name = "id", kind = "bigint", nullable = False, default = Nothing, primaryKey = Nothing, foreignKey = Nothing } [], primaryKey = Nothing, uniques = [], indexes = [], checks = [], source = s })
            , stmCheck "without schema, lowercase and no space before body" "create table migrations(version varchar not null);" parseCreateTable (\s -> Ok { schema = Nothing, table = "migrations", columns = Nel { name = "version", kind = "varchar", nullable = False, default = Nothing, primaryKey = Nothing, foreignKey = Nothing } [], primaryKey = Nothing, uniques = [], indexes = [], checks = [], source = s })
            , stmCheck "bad" "bad" parseCreateTable (\_ -> Err [ "Can't parse table: 'bad'" ])
            ]
        , describe "parseCreateTableColumn"
            [ test "basic"
                (\_ ->
                    "id bigint NOT NULL"
                        |> parseCreateTableColumn
                        |> Expect.equal (Ok { name = "id", kind = "bigint", nullable = False, default = Nothing, primaryKey = Nothing, foreignKey = Nothing })
                )
            , test "nullable"
                (\_ ->
                    "id bigint"
                        |> parseCreateTableColumn
                        |> Expect.equal (Ok { name = "id", kind = "bigint", nullable = True, default = Nothing, primaryKey = Nothing, foreignKey = Nothing })
                )
            , test "with default"
                (\_ ->
                    "status character varying(255) DEFAULT 'done'::character varying"
                        |> parseCreateTableColumn
                        |> Expect.equal (Ok { name = "status", kind = "character varying(255)", nullable = True, default = Just "'done'::character varying", primaryKey = Nothing, foreignKey = Nothing })
                )
            , test "with comma in type"
                (\_ ->
                    "price numeric(8,2)"
                        |> parseCreateTableColumn
                        |> Expect.equal (Ok { name = "price", kind = "numeric(8,2)", nullable = True, default = Nothing, primaryKey = Nothing, foreignKey = Nothing })
                )
            , test "with enclosing quotes"
                (\_ ->
                    "\"id\" bigint"
                        |> parseCreateTableColumn
                        |> Expect.equal (Ok { name = "id", kind = "bigint", nullable = True, default = Nothing, primaryKey = Nothing, foreignKey = Nothing })
                )
            , test "with primary key"
                (\_ ->
                    "id bigint NOT NULL CONSTRAINT users_pk PRIMARY KEY"
                        |> parseCreateTableColumn
                        |> Expect.equal (Ok { name = "id", kind = "bigint", nullable = False, default = Nothing, primaryKey = Just "users_pk", foreignKey = Nothing })
                )
            , test "with foreign key having schema, table & column"
                (\_ ->
                    "user_id bigint CONSTRAINT users_fk REFERENCES public.users.id"
                        |> parseCreateTableColumn
                        |> Expect.equal (Ok { name = "user_id", kind = "bigint", nullable = True, default = Nothing, primaryKey = Nothing, foreignKey = Just ( "users_fk", { schema = Just "public", table = "users", column = Just "id" } ) })
                )
            , test "with foreign key having table & column"
                (\_ ->
                    "user_id bigint CONSTRAINT users_fk REFERENCES users.id"
                        |> parseCreateTableColumn
                        |> Expect.equal (Ok { name = "user_id", kind = "bigint", nullable = True, default = Nothing, primaryKey = Nothing, foreignKey = Just ( "users_fk", { schema = Nothing, table = "users", column = Just "id" } ) })
                )
            , test "with foreign key having only table"
                (\_ ->
                    "user_id bigint CONSTRAINT users_fk REFERENCES users"
                        |> parseCreateTableColumn
                        |> Expect.equal (Ok { name = "user_id", kind = "bigint", nullable = True, default = Nothing, primaryKey = Nothing, foreignKey = Just ( "users_fk", { schema = Nothing, table = "users", column = Nothing } ) })
                )
            , test "bad" (\_ -> "bad" |> parseCreateTableColumn |> Expect.equal (Err "Can't parse column: 'bad'"))
            ]
        ]
