module DataSources.SqlParser.Dialects.SqlserverTest exposing (..)

import DataSources.SqlParser.StatementParser exposing (Command(..))
import DataSources.SqlParser.TestHelpers.Tests exposing (parsedColumn, parsedTable, testParseStatement)
import Libs.Nel exposing (Nel)
import Test exposing (Test, describe)


suite : Test
suite =
    describe "SQL Server"
        [ describe "CREATE TABLE"
            -- https://docs.microsoft.com/en-us/sql/t-sql/statements/create-table-transact-sql
            [ testParseStatement "with primary key"
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
