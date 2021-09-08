module DataSources.SqlParser.StatementParserTest exposing (..)

import DataSources.SqlParser.Parsers.AlterTable exposing (TableConstraint(..), TableUpdate(..))
import DataSources.SqlParser.StatementParser exposing (Command(..), parseCommand)
import DataSources.SqlParser.Utils.HelpersTest exposing (testStatement)
import Libs.Nel exposing (Nel)
import Test exposing (Test, describe)


suite : Test
suite =
    describe "StatementParser"
        [ describe "parseCommand"
            [ testStatement "parse create table" "CREATE TABLE aaa.bbb (ccc int);" parseCommand (\s -> Ok ( s, CreateTable { schema = Just "aaa", table = "bbb", columns = Nel { name = "ccc", kind = "int", nullable = True, default = Nothing, primaryKey = Nothing, foreignKey = Nothing } [], primaryKey = Nothing, uniques = [], indexes = [], checks = [], source = s } ))
            , testStatement "parse alter table" "ALTER TABLE ONLY public.t2 ADD CONSTRAINT t2_id_pkey PRIMARY KEY (id);" parseCommand (\s -> Ok ( s, AlterTable (AddTableConstraint (Just "public") "t2" (ParsedPrimaryKey (Just "t2_id_pkey") (Nel "id" []))) ))
            , testStatement "parse table comment" "COMMENT ON TABLE public.table1 IS 'A comment';" parseCommand (\s -> Ok ( s, TableComment { schema = Just "public", table = "table1", comment = "A comment" } ))
            , testStatement "parse column comment" "COMMENT ON COLUMN public.table1.col IS 'A comment';" parseCommand (\s -> Ok ( s, ColumnComment { schema = Just "public", table = "table1", column = "col", comment = "A comment" } ))
            , testStatement "parse lowercase" "comment on column public.table1.col is 'A comment';" parseCommand (\s -> Ok ( s, ColumnComment { schema = Just "public", table = "table1", column = "col", comment = "A comment" } ))
            , testStatement "ignore GO" "GO /****** Object:  Schema [api]    Script Date: 6-9-2021 13:53:38 ******/ CREATE SCHEMA [api] ;" parseCommand (\s -> Ok ( s, Ignored (Nel { file = "", line = 0, text = "GO /****** Object:  Schema [api]    Script Date: 6-9-2021 13:53:38 ******/ CREATE SCHEMA [api] ;" } []) ))
            ]
        ]
