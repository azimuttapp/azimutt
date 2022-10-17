module DataSources.SqlMiner.Dialects.MysqlTest exposing (..)

import DataSources.SqlMiner.SqlParser exposing (Command(..), parseCommand)
import DataSources.SqlMiner.TestHelpers.Tests exposing (parsedColumn, parsedTable, testStatement)
import Libs.Nel exposing (Nel)
import Test exposing (Test, describe)


suite : Test
suite =
    describe "MySQL"
        [ describe "CREATE TABLE"
            -- https://dev.mysql.com/doc/refman/8.0/en/create-table.html
            [ testStatement ( parseCommand, "with primary key" )
                """CREATE TABLE t1 (
                       c1 INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                       c2 VARCHAR(100),
                       c3 VARCHAR(100)
                   ) ENGINE=NDB COMMENT="NDB_TABLE=READ_BACKUP=0,PARTITION_BALANCE=FOR_RP_BY_NODE";"""
                (CreateTable
                    { parsedTable
                        | table = "t1"
                        , columns =
                            Nel { parsedColumn | name = "c1", kind = "INT", nullable = False, primaryKey = Just "" }
                                [ { parsedColumn | name = "c2", kind = "VARCHAR(100)" }
                                , { parsedColumn | name = "c3", kind = "VARCHAR(100)" }
                                ]
                    }
                )
            ]
        ]
