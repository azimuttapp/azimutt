module DataSources.NewSqlParser.Parsers.CreateTableTest exposing (..)

import DataSources.NewSqlParser.Parsers.CreateTable exposing (createTableParser)
import DataSources.NewSqlParser.Utils.Types exposing (ParsedColumn, ParsedTable, SqlStatement)
import Expect
import Parser
import Test exposing (Test, describe, skip, test)


suite : Test
suite =
    describe "CreateTable"
        [ skip
            (testParse "basic"
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
                }
            )
        , skip
            (testParse "WIP"
                """CREATE TABLE IF NOT EXISTS public.users(
                     `id` INT NOT NULL PRIMARY KEY,
                     'name' VARCHAR
                   );"""
                { schema = Just "public"
                , table = "users"
                , columns =
                    [ { column | name = "id", kind = "INT", nullable = False, primaryKey = Just "" }
                    , { column | name = "name", kind = "VARCHAR" }
                    ]
                }
            )
        , skip
            (testParse "with schema, quotes, not null, primary key and default"
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
                }
            )
        , skip
            (testParse "with constraints"
                """CREATE TABLE [Users] (
                     [id] int identity(1,1) NOT NULL CONSTRAINT users_pk PRIMARY KEY
                     , "name" VARCHAR(255) check(LEN(name) > 4)
                     , profile_id INT CONSTRAINT users_profile_fk REFERENCES public.profiles.id
                   );"""
                { schema = Nothing
                , table = "Users"
                , columns =
                    [ { column | name = "id", kind = "int identity(1,1)", nullable = False, primaryKey = Just "users_pk" }
                    , { column | name = "name", kind = "VARCHAR(255)", check = Just "LEN(name) > 4" }
                    , { column | name = "profile_id", kind = "INT", foreignKey = Just ( "users_profile_fk", { schema = Just "public", table = "profiles", column = Just "id" } ) }
                    ]
                }
            )
        ]


testParse : String -> SqlStatement -> ParsedTable -> Test
testParse name sql result =
    test name (\_ -> sql |> Parser.run createTableParser |> Expect.equal (Ok result))


column : ParsedColumn
column =
    { name = "", kind = "", nullable = True, default = Nothing, primaryKey = Nothing, foreignKey = Nothing, check = Nothing }
