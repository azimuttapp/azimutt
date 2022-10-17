module DataSources.SqlMiner.Dialects.SqlserverTest exposing (..)

import DataSources.SqlMiner.SqlParser exposing (Command(..), parseCommand)
import DataSources.SqlMiner.TestHelpers.Tests exposing (parsedColumn, parsedTable, testStatement)
import Libs.Nel exposing (Nel)
import Test exposing (Test, describe)


suite : Test
suite =
    describe "SQL Server"
        [ describe "CREATE TABLE"
            -- https://docs.microsoft.com/en-us/sql/t-sql/statements/create-table-transact-sql
            [ testStatement ( parseCommand, "with primary key" )
                """CREATE TABLE dbo.Employee (
                       EmployeeID INT PRIMARY KEY
                   );"""
                (CreateTable
                    { parsedTable
                        | schema = Just "dbo"
                        , table = "Employee"
                        , columns = Nel { parsedColumn | name = "EmployeeID", kind = "INT", primaryKey = Just "" } []
                    }
                )
            ]
        ]
