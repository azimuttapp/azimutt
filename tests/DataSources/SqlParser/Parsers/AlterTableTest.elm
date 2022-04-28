module DataSources.SqlParser.Parsers.AlterTableTest exposing (..)

import DataSources.SqlParser.Parsers.AlterTable exposing (ColumnUpdate(..), TableConstraint(..), TableUpdate(..), parseAlterTable, parseAlterTableAddConstraint, parseAlterTableAddConstraintForeignKey)
import DataSources.SqlParser.TestHelpers.Tests exposing (testParse, testParseSql)
import Libs.Nel exposing (Nel)
import Test exposing (Test, describe)


suite : Test
suite =
    describe "AlterTable"
        [ describe "parseAlterTable"
            [ testParse ( parseAlterTable, "primary key" )
                "ALTER TABLE public.t2 ADD CONSTRAINT t2_id_pkey PRIMARY KEY (id);"
                (AddTableConstraint (Just "public") "t2" (ParsedPrimaryKey (Just "t2_id_pkey") (Nel "id" [])))
            , testParse ( parseAlterTable, "foreign key" )
                "ALTER TABLE p.t2 ADD CONSTRAINT t2_t1_id_fk FOREIGN KEY (t1_id) REFERENCES p.t1 (id);"
                (AddTableConstraint (Just "p") "t2" (ParsedForeignKey "t2_t1_id_fk" { column = "t1_id", ref = { schema = Just "p", table = "t1", column = Just "id" } }))
            , testParse ( parseAlterTable, "foreign key without schema" )
                "ALTER TABLE p.t2 ADD CONSTRAINT t2_t1_id_fk FOREIGN KEY (t1_id) REFERENCES t1 (id);"
                (AddTableConstraint (Just "p") "t2" (ParsedForeignKey "t2_t1_id_fk" { column = "t1_id", ref = { schema = Nothing, table = "t1", column = Just "id" } }))
            , testParse ( parseAlterTable, "foreign key without column" )
                "ALTER TABLE p.t2 ADD CONSTRAINT t2_t1_id_fk FOREIGN KEY (t1_id) REFERENCES p.t1;"
                (AddTableConstraint (Just "p") "t2" (ParsedForeignKey "t2_t1_id_fk" { column = "t1_id", ref = { schema = Just "p", table = "t1", column = Nothing } }))
            , testParse ( parseAlterTable, "foreign key without schema & column" )
                "ALTER TABLE p.t2 ADD CONSTRAINT t2_t1_id_fk FOREIGN KEY (t1_id) REFERENCES t1;"
                (AddTableConstraint (Just "p") "t2" (ParsedForeignKey "t2_t1_id_fk" { column = "t1_id", ref = { schema = Nothing, table = "t1", column = Nothing } }))
            , testParse ( parseAlterTable, "foreign key not valid" )
                "ALTER TABLE p.t2 ADD CONSTRAINT t2_t1_id_fk FOREIGN KEY (t1_id) REFERENCES p.t1 (id) NOT VALID;"
                (AddTableConstraint (Just "p") "t2" (ParsedForeignKey "t2_t1_id_fk" { column = "t1_id", ref = { schema = Just "p", table = "t1", column = Just "id" } }))
            , testParse ( parseAlterTable, "unique" )
                "ALTER TABLE p.t1 ADD CONSTRAINT name_unique UNIQUE (first_name, last_name);"
                (AddTableConstraint (Just "p") "t1" (ParsedUnique "name_unique" { columns = Nel "first_name" [ "last_name" ], definition = "(first_name, last_name)" }))
            , testParse ( parseAlterTable, "check" )
                "ALTER TABLE p.t1 ADD CONSTRAINT t1_kind_not_null CHECK ((kind IS NOT NULL)) NOT VALID;"
                (AddTableConstraint (Just "p") "t1" (ParsedCheck "t1_kind_not_null" { columns = [], predicate = "((kind IS NOT NULL)) NOT VALID" }))
            , testParse ( parseAlterTable, "column default" )
                "ALTER TABLE public.table1 ALTER COLUMN id SET DEFAULT 1;"
                (AlterColumn (Just "public") "table1" (ColumnDefault "id" "1"))
            , testParse ( parseAlterTable, "column statistics" )
                "ALTER TABLE public.table1 ALTER COLUMN table1_id SET STATISTICS 5000;"
                (AlterColumn (Just "public") "table1" (ColumnStatistics "table1_id" 5000))
            , testParse ( parseAlterTable, "owner" )
                "ALTER TABLE public.table1 OWNER TO admin;"
                (AddTableOwner (Just "public") "table1" "admin")
            , testParse ( parseAlterTable, "without schema" )
                "ALTER TABLE t2 ADD CONSTRAINT t2_id_pkey PRIMARY KEY (id);"
                (AddTableConstraint Nothing "t2" (ParsedPrimaryKey (Just "t2_id_pkey") (Nel "id" [])))
            , testParse ( parseAlterTable, "with only" )
                "ALTER TABLE ONLY public.t2 ADD CONSTRAINT t2_id_pkey PRIMARY KEY (id);"
                (AddTableConstraint (Just "public") "t2" (ParsedPrimaryKey (Just "t2_id_pkey") (Nel "id" [])))
            , testParse ( parseAlterTable, "primary key with add" )
                "ALTER TABLE public.t2 ADD PRIMARY KEY (`id`);"
                (AddTableConstraint (Just "public") "t2" (ParsedPrimaryKey Nothing (Nel "id" [])))
            , testParse ( parseAlterTable, "if exists" )
                "alter table if exists t1 \n       drop constraint if exists abc;"
                (DropConstraint Nothing "t1" "abc")
            ]
        , describe "parseAlterTableAddConstraint"
            [ testParseSql ( parseAlterTableAddConstraint, "unique" )
                "add constraint `no_duplicate_tags` unique (`task_ulid`, `tag`)"
                (ParsedUnique "no_duplicate_tags" { columns = Nel "task_ulid" [ "tag" ], definition = "(`task_ulid`, `tag`)" })
            ]
        , describe "parseAlterTableAddConstraintForeignKey"
            [ testParseSql ( parseAlterTableAddConstraintForeignKey, "with on delete" )
                "FOREIGN KEY (supply_order_bill_id) REFERENCES public.supply_order_bills(id) ON DELETE SET NULL"
                { column = "supply_order_bill_id", ref = { schema = Just "public", table = "supply_order_bills", column = Just "id" } }
            , testParseSql ( parseAlterTableAddConstraintForeignKey, "with on delete not deferrable" )
                """FOREIGN KEY ("postId") REFERENCES post_entity(id) ON DELETE CASCADE NOT DEFERRABLE"""
                { column = "postId", ref = { schema = Nothing, table = "post_entity", column = Just "id" } }
            , testParseSql ( parseAlterTableAddConstraintForeignKey, "with initially immediate" )
                """FOREIGN KEY (actor_id) REFERENCES auth_user(id) DEFERRABLE INITIALLY IMMEDIATE"""
                { column = "actor_id", ref = { schema = Nothing, table = "auth_user", column = Just "id" } }
            , testParseSql ( parseAlterTableAddConstraintForeignKey, "with initially deferred" )
                """FOREIGN KEY (actor_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED"""
                { column = "actor_id", ref = { schema = Just "public", table = "auth_user", column = Just "id" } }
            , testParseSql ( parseAlterTableAddConstraintForeignKey, "with on update on delete and deferrable" )
                """FOREIGN KEY (postId) REFERENCES public.post(id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE"""
                { column = "postId", ref = { schema = Just "public", table = "post", column = Just "id" } }
            ]
        ]
