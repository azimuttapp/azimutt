module DataSources.SqlParser.Dialects.SqliteTest exposing (..)

import DataSources.SqlParser.StatementParser exposing (Command(..))
import DataSources.SqlParser.TestHelpers.Tests exposing (parsedColumn, parsedTable, testParseStatement)
import Libs.Nel exposing (Nel)
import Test exposing (Test, describe)


suite : Test
suite =
    describe "SQLite"
        [ describe "CREATE TABLE"
            -- https://www.sqlite.org/lang_createtable.html
            [ testParseStatement "with primary key"
                """CREATE TABLE artist(
                     artistid    INTEGER,
                     artistname  TEXT
                   );"""
                (CreateTable
                    { parsedTable
                        | table = "artist"
                        , columns =
                            Nel { parsedColumn | name = "artistid", kind = "INTEGER" }
                                [ { parsedColumn | name = "artistname", kind = "TEXT" }
                                ]
                    }
                )
            , testParseStatement "with foreign key"
                """CREATE TABLE public.track (
                     trackid     INTEGER PRIMARY KEY,
                     trackname   TEXT,
                     trackartist INTEGER,
                     FOREIGN KEY(trackartist) REFERENCES artist(artistid)
                   );"""
                (CreateTable
                    { parsedTable
                        | schema = Just "public"
                        , table = "track"
                        , columns =
                            Nel { parsedColumn | name = "trackid", kind = "INTEGER", primaryKey = Just "" }
                                [ { parsedColumn | name = "trackname", kind = "TEXT" }
                                , { parsedColumn | name = "trackartist", kind = "INTEGER" }
                                ]
                        , foreignKeys = [ { name = Nothing, src = "trackartist", ref = { schema = Nothing, table = "artist", column = Just "artistid" } } ]
                    }
                )
            ]
        ]
