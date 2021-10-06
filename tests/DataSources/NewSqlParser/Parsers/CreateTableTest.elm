module DataSources.NewSqlParser.Parsers.CreateTableTest exposing (..)

import DataSources.NewSqlParser.Parsers.CreateTable exposing (parseCreateTable)
import DataSources.NewSqlParser.Utils.Types exposing (ParsedColumn, ParsedTable, SqlStatement)
import Expect
import Parser exposing ((|.), (|=), DeadEnd, Parser, Step(..), chompIf, chompWhile, float, getChompedString, loop, map, oneOf, spaces, succeed, symbol)
import Test exposing (Test, describe, only, test)


type alias Table =
    { name : String
    , columns : List Column
    }


type alias Column =
    { name : String
    , type_ : String
    }


parse : String -> Result (List DeadEnd) Table
parse sql =
    Parser.run parser sql


parser : Parser Table
parser =
    succeed Table
        |. symbol "CREATE TABLE"
        |. spaces
        |= tableName
        |. spaces
        |. symbol "("
        |. spaces
        |= parseColumns


tableName : Parser String
tableName =
    getChompedString <|
        succeed ()
            |. chompIf Char.isAlpha
            |. chompWhile (\c -> c /= ' ' && c /= '(')


columnName : Parser String
columnName =
    getChompedString <|
        succeed ()
            |. chompIf Char.isAlpha
            |. chompWhile (\c -> c /= ' ' && c /= '(')


columnType : Parser String
columnType =
    getChompedString <|
        succeed ()
            |. chompIf Char.isAlpha
            |. chompWhile (\c -> c /= ' ' && c /= ',' && c /= '\n')


parseColumns : Parser (List Column)
parseColumns =
    loop [] parseColumnsHelp


parseColumnsHelp : List Column -> Parser (Step (List Column) (List Column))
parseColumnsHelp revColumns =
    succeed
        (\column_ continues ->
            if continues then
                Loop (column_ :: revColumns)

            else
                Done (List.reverse (column_ :: revColumns))
        )
        |= parseColumn
        |. spaces
        |= oneOf
            [ succeed True |. symbol ","
            , succeed False |. symbol ")"
            ]
        |. spaces


parseColumn : Parser Column
parseColumn =
    succeed Column
        |= columnName
        |. spaces
        |= columnType


statement =
    """CREATE TABLE users (
          id INT,
          name VARCHAR
        );"""


suite : Test
suite =
    describe "CreateTable"
        [ only
            (test "test"
                (\_ ->
                    statement
                        |> parse
                        |> Expect.equal
                            (Ok
                                (Table "users"
                                    [ Column "id" "INT"
                                    , Column "name" "VARCHAR"
                                    ]
                                )
                            )
                )
            )
        , testParse "basic"
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
            }
        , testParse "with constraints"
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
        ]


testParse : String -> SqlStatement -> ParsedTable -> Test
testParse name sql result =
    test name (\_ -> sql |> parseCreateTable |> Expect.equal (Ok result))


column : ParsedColumn
column =
    { name = "", kind = "", nullable = True, default = Nothing, primaryKey = Nothing, foreignKey = Nothing, check = Nothing }
