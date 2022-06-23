module DataSources.SqlParser.Parsers.AlterTableTest exposing (..)

import DataSources.SqlParser.Parsers.AlterTable exposing (ColumnUpdate(..), TableConstraint(..), TableUpdate(..), parseAlterTable, parseAlterTableAddConstraint, parseAlterTableAddConstraintForeignKey)
import DataSources.SqlParser.TestHelpers.Tests exposing (testSql, testStatement)
import Libs.Nel exposing (Nel)
import Test exposing (Test, describe)


suite : Test
suite =
    describe "AlterTable"
        [ describe "parseAlterTable"
            [ testStatement ( parseAlterTable, "primary key" )
                "ALTER TABLE public.t2 ADD CONSTRAINT t2_id_pkey PRIMARY KEY (id);"
                (AddTableConstraint (Just "public") "t2" (ParsedPrimaryKey (Just "t2_id_pkey") (Nel "id" [])))
            , testStatement ( parseAlterTable, "foreign key" )
                "ALTER TABLE p.t2 ADD CONSTRAINT t2_t1_id_fk FOREIGN KEY (t1_id) REFERENCES p.t1 (id);"
                (AddTableConstraint (Just "p") "t2" (ParsedForeignKey (Just "t2_t1_id_fk") (Nel { column = "t1_id", ref = { schema = Just "p", table = "t1", column = Just "id" } } [])))
            , testStatement ( parseAlterTable, "foreign key without constraint" )
                "ALTER TABLE p.t2 ADD FOREIGN KEY (t1_id) REFERENCES p.t1(id);"
                (AddTableConstraint (Just "p") "t2" (ParsedForeignKey Nothing (Nel { column = "t1_id", ref = { schema = Just "p", table = "t1", column = Just "id" } } [])))
            , testStatement ( parseAlterTable, "foreign key without schema" )
                "ALTER TABLE p.t2 ADD CONSTRAINT t2_t1_id_fk FOREIGN KEY (t1_id) REFERENCES t1 (id);"
                (AddTableConstraint (Just "p") "t2" (ParsedForeignKey (Just "t2_t1_id_fk") (Nel { column = "t1_id", ref = { schema = Nothing, table = "t1", column = Just "id" } } [])))
            , testStatement ( parseAlterTable, "foreign key without column" )
                "ALTER TABLE p.t2 ADD CONSTRAINT t2_t1_id_fk FOREIGN KEY (t1_id) REFERENCES p.t1;"
                (AddTableConstraint (Just "p") "t2" (ParsedForeignKey (Just "t2_t1_id_fk") (Nel { column = "t1_id", ref = { schema = Just "p", table = "t1", column = Nothing } } [])))
            , testStatement ( parseAlterTable, "foreign key without schema & column" )
                "ALTER TABLE p.t2 ADD CONSTRAINT t2_t1_id_fk FOREIGN KEY (t1_id) REFERENCES t1;"
                (AddTableConstraint (Just "p") "t2" (ParsedForeignKey (Just "t2_t1_id_fk") (Nel { column = "t1_id", ref = { schema = Nothing, table = "t1", column = Nothing } } [])))
            , testStatement ( parseAlterTable, "foreign key not valid" )
                "ALTER TABLE p.t2 ADD CONSTRAINT t2_t1_id_fk FOREIGN KEY (t1_id) REFERENCES p.t1 (id) NOT VALID;"
                (AddTableConstraint (Just "p") "t2" (ParsedForeignKey (Just "t2_t1_id_fk") (Nel { column = "t1_id", ref = { schema = Just "p", table = "t1", column = Just "id" } } [])))
            , testStatement ( parseAlterTable, "unique" )
                "ALTER TABLE p.t1 ADD CONSTRAINT name_unique UNIQUE (first_name, last_name);"
                (AddTableConstraint (Just "p") "t1" (ParsedUnique "name_unique" { columns = Nel "first_name" [ "last_name" ], definition = "(first_name, last_name)" }))
            , testStatement ( parseAlterTable, "check" )
                "ALTER TABLE p.t1 ADD CONSTRAINT t1_kind_not_null CHECK ((kind IS NOT NULL)) NOT VALID;"
                (AddTableConstraint (Just "p") "t1" (ParsedCheck "t1_kind_not_null" { columns = [], predicate = "((kind IS NOT NULL)) NOT VALID" }))
            , testStatement ( parseAlterTable, "exclude using" )
                "ALTER TABLE p.t1 ADD CONSTRAINT name EXCLUDE USING p.t2 (rotation_id WITH =, tstzrange(starts_at, ends_at, '[)'::text) WITH &&);"
                (AddTableConstraint (Just "p") "t1" IgnoredConstraint)
            , testStatement ( parseAlterTable, "column default" )
                "ALTER TABLE public.table1 ALTER COLUMN id SET DEFAULT 1;"
                (AlterColumn (Just "public") "table1" (ColumnDefault "id" "1"))
            , testStatement ( parseAlterTable, "column default with quotes" )
                "ALTER TABLE public.table1 ALTER COLUMN \"id\" SET DEFAULT 1;"
                (AlterColumn (Just "public") "table1" (ColumnDefault "id" "1"))
            , testStatement ( parseAlterTable, "column mssql value" )
                "ALTER TABLE t1 ADD DEFAULT N'gitlab_' + CAST(NEXT VALUE FOR dbo.abuse_id_seq as NVARCHAR(20)) FOR id;"
                (AlterColumn Nothing "t1" (ColumnDefault "id" "N'gitlab_' + CAST(NEXT VALUE FOR dbo.abuse_id_seq as NVARCHAR(20))"))
            , testStatement ( parseAlterTable, "column statistics" )
                "ALTER TABLE public.table1 ALTER COLUMN table1_id SET STATISTICS 5000;"
                (AlterColumn (Just "public") "table1" (ColumnStatistics "table1_id" 5000))
            , testStatement ( parseAlterTable, "column statistics with quotes" )
                "ALTER TABLE public.table1 ALTER COLUMN \"table1_id\" SET STATISTICS 5000;"
                (AlterColumn (Just "public") "table1" (ColumnStatistics "table1_id" 5000))
            , testStatement ( parseAlterTable, "drop column" )
                "ALTER TABLE public.table1 DROP COLUMN admin;"
                (DropColumn (Just "public") "table1" "admin")
            , testStatement ( parseAlterTable, "owner" )
                "ALTER TABLE public.table1 OWNER TO admin;"
                (AddTableOwner (Just "public") "table1" "admin")
            , testStatement ( parseAlterTable, "space after schema" )
                "ALTER TABLE public. \"table1\" OWNER TO admin;"
                (AddTableOwner (Just "public") "table1" "admin")
            , testStatement ( parseAlterTable, "without schema" )
                "ALTER TABLE t2 ADD CONSTRAINT t2_id_pkey PRIMARY KEY (id);"
                (AddTableConstraint Nothing "t2" (ParsedPrimaryKey (Just "t2_id_pkey") (Nel "id" [])))
            , testStatement ( parseAlterTable, "with only" )
                "ALTER TABLE ONLY public.t2 ADD CONSTRAINT t2_id_pkey PRIMARY KEY (id);"
                (AddTableConstraint (Just "public") "t2" (ParsedPrimaryKey (Just "t2_id_pkey") (Nel "id" [])))
            , testStatement ( parseAlterTable, "primary key with add" )
                "ALTER TABLE public.t2 ADD PRIMARY KEY (`id`);"
                (AddTableConstraint (Just "public") "t2" (ParsedPrimaryKey Nothing (Nel "id" [])))
            , testStatement ( parseAlterTable, "clustered primary key" )
                "ALTER TABLE public.t2 ADD PRIMARY KEY CLUSTERED ([AlbumId]);"
                (AddTableConstraint (Just "public") "t2" (ParsedPrimaryKey Nothing (Nel "AlbumId" [])))
            , testStatement ( parseAlterTable, "nonclustered primary key" )
                "ALTER TABLE public.t2 ADD PRIMARY KEY NONCLUSTERED ([PlaylistId], [TrackId]);"
                (AddTableConstraint (Just "public") "t2" (ParsedPrimaryKey Nothing (Nel "PlaylistId" [ "TrackId" ])))
            , testStatement ( parseAlterTable, "if exists" )
                "alter table if exists t1 \n       drop constraint if exists abc;"
                (DropConstraint Nothing "t1" "abc")
            ]
        , describe "parseAlterTableAddConstraint"
            [ testSql ( parseAlterTableAddConstraint, "unique" )
                "add constraint `no_duplicate_tags` unique (`task_ulid`, `tag`)"
                (ParsedUnique "no_duplicate_tags" { columns = Nel "task_ulid" [ "tag" ], definition = "(`task_ulid`, `tag`)" })
            ]
        , describe "parseAlterTableAddConstraintForeignKey"
            [ testSql ( parseAlterTableAddConstraintForeignKey, "with on delete" )
                "FOREIGN KEY (supply_order_bill_id) REFERENCES public.supply_order_bills(id) ON DELETE SET NULL"
                (Nel { column = "supply_order_bill_id", ref = { schema = Just "public", table = "supply_order_bills", column = Just "id" } } [])
            , testSql ( parseAlterTableAddConstraintForeignKey, "with on delete not deferrable" )
                """FOREIGN KEY ("postId") REFERENCES post_entity(id) ON DELETE CASCADE NOT DEFERRABLE"""
                (Nel { column = "postId", ref = { schema = Nothing, table = "post_entity", column = Just "id" } } [])
            , testSql ( parseAlterTableAddConstraintForeignKey, "with initially immediate" )
                """FOREIGN KEY (actor_id) REFERENCES auth_user(id) DEFERRABLE INITIALLY IMMEDIATE"""
                (Nel { column = "actor_id", ref = { schema = Nothing, table = "auth_user", column = Just "id" } } [])
            , testSql ( parseAlterTableAddConstraintForeignKey, "with initially deferred" )
                """FOREIGN KEY (actor_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED"""
                (Nel { column = "actor_id", ref = { schema = Just "public", table = "auth_user", column = Just "id" } } [])
            , testSql ( parseAlterTableAddConstraintForeignKey, "with on update on delete and deferrable" )
                """FOREIGN KEY (postId) REFERENCES public.post(id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE"""
                (Nel { column = "postId", ref = { schema = Just "public", table = "post", column = Just "id" } } [])
            , testSql ( parseAlterTableAddConstraintForeignKey, "multi-column foreign key" )
                """FOREIGN KEY ("SCHED_NAME", "TRIGGER_NAME", "TRIGGER_GROUP") REFERENCES "CRPDTA"."QRTZ_TRIGGERS" ("SCHED_NAME", "TRIGGER_NAME", "TRIGGER_GROUP") ENABLE"""
                (Nel { column = "SCHED_NAME", ref = { schema = Just "CRPDTA", table = "QRTZ_TRIGGERS", column = Just "SCHED_NAME" } }
                    [ { column = "TRIGGER_NAME", ref = { schema = Just "CRPDTA", table = "QRTZ_TRIGGERS", column = Just "TRIGGER_NAME" } }
                    , { column = "TRIGGER_GROUP", ref = { schema = Just "CRPDTA", table = "QRTZ_TRIGGERS", column = Just "TRIGGER_GROUP" } }
                    ]
                )
            ]
        ]
