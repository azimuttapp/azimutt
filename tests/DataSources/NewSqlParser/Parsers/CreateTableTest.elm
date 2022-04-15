module DataSources.NewSqlParser.Parsers.CreateTableTest exposing (..)

import DataSources.NewSqlParser.Dsl exposing (ParsedColumn, ParsedConstraint(..), ParsedTable, SqlStatement)
import DataSources.NewSqlParser.Parsers.CreateTable exposing (columnParser, columnsParser, createTableParser)
import Expect
import Libs.Nel exposing (Nel)
import Parser
import Test exposing (Test, describe, skip, test)


suite : Test
suite =
    describe "CreateTable"
        [ testParse "basic"
            """CREATE TABLE users (
                 id INT,
                 name VARCHAR
               );"""
            { schema = Nothing
            , table = "users"
            , columns =
                [ { column | name = "id", kind = "INT" }
                , { column | name = "name", kind = "VARCHAR" }
                ]
            , constraints = []
            }
        , testParse "with schema, quotes, not null, primary key and default"
            """CREATE TABLE IF NOT EXISTS public.users(
                 `id` INT NOT NULL PRIMARY KEY,
                 'name' character varying(255) DEFAULT 'no name'
               );"""
            { schema = Just "public"
            , table = "users"
            , columns =
                [ { column | name = "id", kind = "INT", nullable = False, primaryKey = Just "" }
                , { column | name = "name", kind = "character varying(255)", default = Just "'no name'" }
                ]
            , constraints = []
            }
        , testParse "WIP"
            """CREATE TABLE [Users] (
                 [id] int identity(1,1) NOT NULL CONSTRAINT users_pk PRIMARY KEY
                 , "name" VARCHAR(255) check(LEN(name) > 4)
                 , bio text default ''::character varying
                 , profile_id INT CONSTRAINT users_profile_fk REFERENCES public.profiles.id
               );"""
            { schema = Nothing
            , table = "Users"
            , columns =
                [ { column | name = "id", kind = "int identity(1,1)", nullable = False, primaryKey = Just "users_pk" }
                , { column | name = "name", kind = "VARCHAR(255)", check = Just "LEN(name) > 4" }
                , { column | name = "bio", kind = "text", default = Just "''::character varying" }
                , { column | name = "profile_id", kind = "INT", foreignKey = Just ( "users_profile_fk", { schema = Just "public", table = "profiles", column = Just "id" } ) }
                ]
            , constraints = []
            }
        , skip
            (testParse "with constraints"
                """CREATE TABLE [Users] (
                 [id] int identity(1,1) NOT NULL CONSTRAINT users_pk PRIMARY KEY
                 , "name" VARCHAR(255) check(LEN(name) > 4)
                 , bio text default ''::character varying
                 , profile_id INT CONSTRAINT users_profile_fk REFERENCES public.profiles.id
                 , foreign key(`profile_id`) references `profiles`(`id`)
                 , constraint `no_duplicate_name` unique (`name`)
                 , CONSTRAINT bio_not_null CHECK (bio IS NOT NULL)
               );"""
                { schema = Nothing
                , table = "Users"
                , columns =
                    [ { column | name = "id", kind = "int identity(1,1)", nullable = False, primaryKey = Just "users_pk" }
                    , { column | name = "name", kind = "VARCHAR(255)", check = Just "LEN(name) > 4" }
                    , { column | name = "bio", kind = "text" }
                    , { column | name = "profile_id", kind = "INT", foreignKey = Just ( "users_profile_fk", { schema = Just "public", table = "profiles", column = Just "id" } ) }
                    ]
                , constraints =
                    [ ForeignKey { name = Nothing, src = "profile_id", ref = { schema = Nothing, table = "profiles", column = Just "id" } }
                    , Unique { name = "no_duplicate_name", columns = Nel "name" [] }
                    , Check { name = "bio_not_null", columns = [], predicate = "bio IS NOT NULL" }
                    ]
                }
            )
        , describe "columnsParser"
            [ test "single" (\_ -> "(id INT)" |> Parser.run columnsParser |> Expect.equal (Ok [ { column | name = "id", kind = "INT" } ]))
            , test "multiple" (\_ -> "(id INT, name VARCHAR)" |> Parser.run columnsParser |> Expect.equal (Ok [ { column | name = "id", kind = "INT" }, { column | name = "name", kind = "VARCHAR" } ]))
            ]
        , describe "columnParser"
            [ test "basic" (\_ -> "id INT" |> Parser.run columnParser |> Expect.equal (Ok { column | name = "id", kind = "INT" }))
            , test "not null" (\_ -> "id INT NOT NULL" |> Parser.run columnParser |> Expect.equal (Ok { column | name = "id", kind = "INT", nullable = False }))
            , test "primary key" (\_ -> "id INT PRIMARY KEY" |> Parser.run columnParser |> Expect.equal (Ok { column | name = "id", kind = "INT", primaryKey = Just "" }))
            , test "default" (\_ -> "id INT DEFAULT 1" |> Parser.run columnParser |> Expect.equal (Ok { column | name = "id", kind = "INT", default = Just "1" }))
            , test "all" (\_ -> "id INT NOT NULL DEFAULT 1 PRIMARY KEY" |> Parser.run columnParser |> Expect.equal (Ok { column | name = "id", kind = "INT", nullable = False, primaryKey = Just "", default = Just "1" }))
            ]
        ]


testParse : String -> SqlStatement -> ParsedTable -> Test
testParse name sql result =
    test name (\_ -> sql |> Parser.run createTableParser |> Expect.equal (Ok result))


column : ParsedColumn
column =
    { name = "", kind = "", nullable = True, default = Nothing, primaryKey = Nothing, foreignKey = Nothing, check = Nothing }
