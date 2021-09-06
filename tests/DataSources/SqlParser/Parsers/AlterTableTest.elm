module DataSources.SqlParser.Parsers.AlterTableTest exposing (..)

import DataSources.SqlParser.Parsers.AlterTable exposing (ColumnUpdate(..), TableConstraint(..), TableUpdate(..), parseAlterTable)
import DataSources.SqlParser.Utils.HelpersTest exposing (testStatement)
import Libs.Nel exposing (Nel)
import Test exposing (Test, describe)


suite : Test
suite =
    describe "AlterTable"
        [ describe "parseAlterTable"
            [ testStatement "primary key" "ALTER TABLE public.t2 ADD CONSTRAINT t2_id_pkey PRIMARY KEY (id);" parseAlterTable (\_ -> Ok (AddTableConstraint (Just "public") "t2" (ParsedPrimaryKey "t2_id_pkey" (Nel "id" []))))
            , testStatement "foreign key" "ALTER TABLE p.t2 ADD CONSTRAINT t2_t1_id_fk FOREIGN KEY (t1_id) REFERENCES p.t1 (id);" parseAlterTable (\_ -> Ok (AddTableConstraint (Just "p") "t2" (ParsedForeignKey "t2_t1_id_fk" { column = "t1_id", ref = { schema = Just "p", table = "t1", column = Just "id" } })))
            , testStatement "foreign key without schema" "ALTER TABLE p.t2 ADD CONSTRAINT t2_t1_id_fk FOREIGN KEY (t1_id) REFERENCES t1 (id);" parseAlterTable (\_ -> Ok (AddTableConstraint (Just "p") "t2" (ParsedForeignKey "t2_t1_id_fk" { column = "t1_id", ref = { schema = Nothing, table = "t1", column = Just "id" } })))
            , testStatement "foreign key without column" "ALTER TABLE p.t2 ADD CONSTRAINT t2_t1_id_fk FOREIGN KEY (t1_id) REFERENCES p.t1;" parseAlterTable (\_ -> Ok (AddTableConstraint (Just "p") "t2" (ParsedForeignKey "t2_t1_id_fk" { column = "t1_id", ref = { schema = Just "p", table = "t1", column = Nothing } })))
            , testStatement "foreign key without schema & column" "ALTER TABLE p.t2 ADD CONSTRAINT t2_t1_id_fk FOREIGN KEY (t1_id) REFERENCES t1;" parseAlterTable (\_ -> Ok (AddTableConstraint (Just "p") "t2" (ParsedForeignKey "t2_t1_id_fk" { column = "t1_id", ref = { schema = Nothing, table = "t1", column = Nothing } })))
            , testStatement "foreign key not valid" "ALTER TABLE p.t2 ADD CONSTRAINT t2_t1_id_fk FOREIGN KEY (t1_id) REFERENCES p.t1 (id) NOT VALID;" parseAlterTable (\_ -> Ok (AddTableConstraint (Just "p") "t2" (ParsedForeignKey "t2_t1_id_fk" { column = "t1_id", ref = { schema = Just "p", table = "t1", column = Just "id" } })))
            , testStatement "unique" "ALTER TABLE p.t1 ADD CONSTRAINT name_unique UNIQUE (first_name, last_name);" parseAlterTable (\_ -> Ok (AddTableConstraint (Just "p") "t1" (ParsedUnique "name_unique" { columns = Nel "first_name" [ "last_name" ], definition = "(first_name, last_name)" })))
            , testStatement "check" "ALTER TABLE p.t1 ADD CONSTRAINT t1_kind_not_null CHECK ((kind IS NOT NULL)) NOT VALID;" parseAlterTable (\_ -> Ok (AddTableConstraint (Just "p") "t1" (ParsedCheck "t1_kind_not_null" "((kind IS NOT NULL)) NOT VALID")))
            , testStatement "column default" "ALTER TABLE public.table1 ALTER COLUMN id SET DEFAULT 1;" parseAlterTable (\_ -> Ok (AlterColumn (Just "public") "table1" (ColumnDefault "id" "1")))
            , testStatement "column statistics" "ALTER TABLE public.table1 ALTER COLUMN table1_id SET STATISTICS 5000;" parseAlterTable (\_ -> Ok (AlterColumn (Just "public") "table1" (ColumnStatistics "table1_id" 5000)))
            , testStatement "owner" "ALTER TABLE public.table1 OWNER TO admin;" parseAlterTable (\_ -> Ok (AddTableOwner (Just "public") "table1" "admin"))
            , testStatement "without schema" "ALTER TABLE t2 ADD CONSTRAINT t2_id_pkey PRIMARY KEY (id);" parseAlterTable (\_ -> Ok (AddTableConstraint Nothing "t2" (ParsedPrimaryKey "t2_id_pkey" (Nel "id" []))))
            , testStatement "with only" "ALTER TABLE ONLY public.t2 ADD CONSTRAINT t2_id_pkey PRIMARY KEY (id);" parseAlterTable (\_ -> Ok (AddTableConstraint (Just "public") "t2" (ParsedPrimaryKey "t2_id_pkey" (Nel "id" []))))
            , testStatement "bad" "bad" parseAlterTable (\_ -> Err [ "Can't parse alter table: 'bad'" ])
            ]
        ]
