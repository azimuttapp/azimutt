module DataSources.SqlParser.Dialects.JdeTest exposing (..)

import DataSources.SqlParser.StatementParser exposing (Command(..))
import DataSources.SqlParser.TestHelpers.Tests exposing (parsedColumn, parsedTable, testParseStatement)
import Libs.Nel exposing (Nel)
import Test exposing (Test, describe)



{-
   Parsing error line 304204:
   Can't parse foreign key: 'FOREIGN KEY ("SCHED_NAME", "JOB_NAME", "JOB_GROUP") REFERENCES "CRPDTA"."QRTZ_JOB_DETAILS" ("SCHED_NAME", "JOB_NAME", "JOB_GROUP") ENABLE ) SEGMENT CREATION IMMEDIATE PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645 PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT) TABLESPACE "CRPDTAT" LOB ("JOB_DATA") STORE AS SECUREFILE ( TABLESPACE "CRPDTAT" ENABLE STORAGE IN ROW CHUNK 8192 NOCACHE LOGGING NOCOMPRESS KEEP_DUPLICATES STORAGE(INITIAL 106496 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645 PCTINCREASE 0 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)'

   Parsing error line 304332:
   Can't parse foreign key: 'FOREIGN KEY ("SCHED_NAME", "TRIGGER_NAME", "TRIGGER_GROUP") REFERENCES "CRPDTA"."QRTZ_TRIGGERS" ("SCHED_NAME", "TRIGGER_NAME", "TRIGGER_GROUP") ENABLE ) SEGMENT CREATION DEFERRED PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING TABLESPACE "CRPDTAT" LOB ("BLOB_DATA") STORE AS SECUREFILE ( TABLESPACE "CRPDTAT" ENABLE STORAGE IN ROW CHUNK 8192 NOCACHE LOGGING NOCOMPRESS KEEP_DUPLICATES'

   Parsing error line 304363:
   Can't parse foreign key: 'FOREIGN KEY ("SCHED_NAME", "TRIGGER_NAME", "TRIGGER_GROUP") REFERENCES "CRPDTA"."QRTZ_TRIGGERS" ("SCHED_NAME", "TRIGGER_NAME", "TRIGGER_GROUP") ENABLE ) SEGMENT CREATION IMMEDIATE PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645 PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT'
-}


suite : Test
suite =
    describe "SQL Server"
        [ describe "CREATE TABLE"
            [ testParseStatement "with big primary key"
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
            [ testParseStatement "index"
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
