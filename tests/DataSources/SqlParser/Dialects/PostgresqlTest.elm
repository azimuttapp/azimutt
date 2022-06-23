module DataSources.SqlParser.Dialects.PostgresqlTest exposing (..)

import DataSources.SqlParser.SqlParser exposing (Command(..), parseCommand)
import DataSources.SqlParser.TestHelpers.Tests exposing (parsedColumn, parsedTable, testStatement)
import Libs.Nel exposing (Nel)
import Test exposing (Test, describe)


suite : Test
suite =
    describe "PostgreSQL"
        [ describe "CREATE TABLE"
            -- https://www.postgresql.org/docs/9.1/sql-createtable.html
            [ testStatement ( parseCommand, "with primary key" )
                """CREATE TABLE films (
                       code        char(5),
                       title       varchar(40),
                       date_prod   date,
                       len         interval hour to minute,
                       CONSTRAINT code_title PRIMARY KEY(code,title)
                   );"""
                (CreateTable
                    { parsedTable
                        | table = "films"
                        , columns =
                            Nel { parsedColumn | name = "code", kind = "char(5)" }
                                [ { parsedColumn | name = "title", kind = "varchar(40)" }
                                , { parsedColumn | name = "date_prod", kind = "date" }
                                , { parsedColumn | name = "len", kind = "interval hour to minute" }
                                ]
                        , primaryKey = Just { name = Just "code_title", columns = Nel "code" [ "title" ] }
                    }
                )
            ]
        ]
