module DataSources.SqlMiner.Dialects.JdeTest exposing (..)

import DataSources.SqlMiner.SqlParser exposing (Command(..), parseCommand)
import DataSources.SqlMiner.TestHelpers.Tests exposing (parsedColumn, parsedTable, testStatement)
import Libs.Nel exposing (Nel)
import Test exposing (Test, describe)


suite : Test
suite =
    describe "SQL Server"
        [ describe "CREATE TABLE"
            [ testStatement ( parseCommand, "with big primary key" )
                """CREATE TABLE "CRPDTA"."F0000194" 
                      (\t"SYEDUS" NCHAR(10), 
                   \t"SYEDBT" NCHAR(15), 
                   \t"SYEDTN" NCHAR(22), 
                   \t"SYEDLN" NUMBER, 
                   \t"SYEDSP" NCHAR(1), 
                   \t CONSTRAINT "F0000194_PK" PRIMARY KEY ("SYEDUS", "SYEDBT", "SYEDTN", "SYEDLN")
                     USING INDEX (CREATE UNIQUE INDEX "CRPDTA"."F0000194_0" ON "CRPDTA"."F0000194" ("SYEDUS", "SYEDBT", "SYEDTN", "SYEDLN") 
                     PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
                     STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
                     PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
                     BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
                     TABLESPACE "CRPDTAI" )  ENABLE
                      ) SEGMENT CREATION IMMEDIATE 
                     PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
                    NOCOMPRESS LOGGING
                     STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
                     PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
                     BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
                     TABLESPACE "CRPDTAT" ;"""
                (CreateTable
                    { parsedTable
                        | schema = Just "CRPDTA"
                        , table = "F0000194"
                        , columns =
                            Nel { parsedColumn | name = "SYEDUS", kind = "NCHAR(10)" }
                                [ { parsedColumn | name = "SYEDBT", kind = "NCHAR(15)" }
                                , { parsedColumn | name = "SYEDTN", kind = "NCHAR(22)" }
                                , { parsedColumn | name = "SYEDLN", kind = "NUMBER" }
                                , { parsedColumn | name = "SYEDSP", kind = "NCHAR(1)" }
                                ]
                        , primaryKey = Just { name = Just "F0000194_PK", columns = Nel "SYEDUS" [ "SYEDBT", "SYEDTN", "SYEDLN" ] }
                    }
                )
            ]
        , describe "CREATE INDEX"
            [ testStatement ( parseCommand, "index" )
                """CREATE UNIQUE INDEX "CRPDTA"."F0000194_0" ON "CRPDTA"."F0000194" ("SYEDUS", "SYEDBT", "SYEDTN", "SYEDLN")
                         PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS
                         STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
                         PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
                         BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
                         TABLESPACE "CRPDTAI" ;"""
                (CreateUnique
                    { name = "CRPDTA.F0000194_0"
                    , table = { schema = Just "CRPDTA", table = "F0000194" }
                    , columns = Nel "SYEDUS" [ "SYEDBT", "SYEDTN", "SYEDLN" ]
                    , definition = "(\"SYEDUS\", \"SYEDBT\", \"SYEDTN\", \"SYEDLN\") PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645 PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT) TABLESPACE \"CRPDTAI\" "
                    }
                )
            ]
        ]
