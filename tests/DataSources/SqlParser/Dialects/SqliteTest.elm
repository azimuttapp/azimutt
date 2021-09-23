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
            , testParseStatement "test"
                """CREATE TABLE IF NOT EXISTS "tasks" (
                     ulid text not null primary key,
                     state text check(state in (NULL, 'Done', 'Obsolete', 'Deletable')),
                     foreign key(`ulid`) references `tasks`(`ulid`),
                     constraint `no_duplicate_state` unique (`ulid`, `state`)
                   );"""
                (CreateTable
                    { parsedTable
                        | table = "tasks"
                        , columns =
                            Nel { parsedColumn | name = "ulid", kind = "text", nullable = False, primaryKey = Just "" }
                                [ { parsedColumn | name = "state", kind = "text", check = Just "state in (NULL, 'Done', 'Obsolete', 'Deletable')" }
                                ]
                        , foreignKeys = [ { name = Nothing, src = "ulid", ref = { schema = Nothing, table = "tasks", column = Just "ulid" } } ]
                        , uniques = [ { name = "no_duplicate_state", columns = Nel "ulid" [ "state" ], definition = "(`ulid`, `state`)" } ]
                    }
                )
            ]
        ]
