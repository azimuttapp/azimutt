module DataSources.SqlParser.StatementParserTest exposing (..)

import DataSources.SqlParser.Parsers.AlterTable exposing (TableConstraint(..), TableUpdate(..))
import DataSources.SqlParser.StatementParser exposing (Command(..))
import DataSources.SqlParser.TestHelpers.Tests exposing (testParseStatement)
import Libs.Nel exposing (Nel)
import Test exposing (Test, describe)


suite : Test
suite =
    describe "StatementParser"
        [ describe "parseStatement"
            [ testParseStatement "parse create table"
                "CREATE TABLE aaa.bbb (ccc int);"
                (CreateTable { schema = Just "aaa", table = "bbb", columns = Nel { name = "ccc", kind = "int", nullable = True, default = Nothing, primaryKey = Nothing, foreignKey = Nothing } [], primaryKey = Nothing, foreignKeys = [], uniques = [], indexes = [], checks = [] })
            , testParseStatement "parse alter table"
                "ALTER TABLE ONLY public.t2 ADD CONSTRAINT t2_id_pkey PRIMARY KEY (id);"
                (AlterTable (AddTableConstraint (Just "public") "t2" (ParsedPrimaryKey (Just "t2_id_pkey") (Nel "id" []))))
            , testParseStatement "parse table comment"
                "COMMENT ON TABLE public.table1 IS 'A comment';"
                (TableComment { schema = Just "public", table = "table1", comment = "A comment" })
            , testParseStatement "parse column comment"
                "COMMENT ON COLUMN public.table1.col IS 'A comment';"
                (ColumnComment { schema = Just "public", table = "table1", column = "col", comment = "A comment" })
            , testParseStatement "parse lowercase"
                "comment on column public.table1.col is 'A comment';"
                (ColumnComment { schema = Just "public", table = "table1", column = "col", comment = "A comment" })
            , testParseStatement "ignore GO"
                "GO /****** Object:  Schema [api]    Script Date: 6-9-2021 13:53:38 ******/ CREATE SCHEMA [api] ;"
                (Ignored (Nel { file = "", line = 0, text = "GO /****** Object:  Schema [api]    Script Date: 6-9-2021 13:53:38 ******/ CREATE SCHEMA [api] ;" } []))
            ]
        ]
