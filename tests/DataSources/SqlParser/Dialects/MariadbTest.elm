module DataSources.SqlParser.Dialects.MariadbTest exposing (..)

import DataSources.SqlParser.StatementParser exposing (Command(..))
import DataSources.SqlParser.TestHelpers.Tests exposing (parsedColumn, parsedTable, testParseStatement)
import Libs.Nel exposing (Nel)
import Test exposing (Test, describe)


suite : Test
suite =
    describe "MariaDB"
        [ describe "CREATE TABLE"
            [ testParseStatement "with primary key"
                """CREATE TABLE t1 (
                       c1 INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                       c2 VARCHAR(100),
                       c3 VARCHAR(100)
                   ) ENGINE=NDB COMMENT="NDB_TABLE=READ_BACKUP=0,PARTITION_BALANCE=FOR_RP_BY_NODE";"""
                (CreateTable
                    { parsedTable
                        | table = "t1"
                        , columns =
                            Nel { parsedColumn | name = "c1", kind = "INT", nullable = False, primaryKey = Just "t1_pk_az" }
                                [ { parsedColumn | name = "c2", kind = "VARCHAR(100)" }
                                , { parsedColumn | name = "c3", kind = "VARCHAR(100)" }
                                ]
                    }
                )
            ]
        ]
