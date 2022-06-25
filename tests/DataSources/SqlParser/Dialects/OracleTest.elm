module DataSources.SqlParser.Dialects.OracleTest exposing (..)

import DataSources.SqlParser.SqlParser exposing (Command(..), parseCommand)
import DataSources.SqlParser.TestHelpers.Tests exposing (parsedColumn, parsedTable, testStatement)
import Libs.Nel exposing (Nel)
import Test exposing (Test, describe)


suite : Test
suite =
    describe "Oracle"
        [ describe "CREATE TABLE"
            -- https://docs.oracle.com/cd/B28359_01/server.111/b28286/statements_7002.htm
            [ testStatement ( parseCommand, "with primary key" )
                """CREATE TABLE employees_demo
                       ( employee_id    NUMBER(6)
                       , name           VARCHAR2(20)
                       , email          VARCHAR2(25)
                            CONSTRAINT emp_email_nn_demo     NOT NULL
                       , hire_date      DATE  DEFAULT SYSDATE
                            CONSTRAINT emp_hire_date_nn_demo  NOT NULL
                       , CONSTRAINT     emp_email_uk_demo
                                        UNIQUE (email)
                       ) ;"""
                (CreateTable
                    { parsedTable
                        | table = "employees_demo"
                        , columns =
                            Nel { parsedColumn | name = "employee_id", kind = "NUMBER(6)" }
                                [ { parsedColumn | name = "name", kind = "VARCHAR2(20)" }
                                , { parsedColumn | name = "email", kind = "VARCHAR2(25)", nullable = False }
                                , { parsedColumn | name = "hire_date", kind = "DATE", nullable = False, default = Just "SYSDATE" }
                                ]
                        , uniques = [ { name = "emp_email_uk_demo", columns = Nel "email" [], definition = "(email)" } ]
                    }
                )
            ]
        ]
