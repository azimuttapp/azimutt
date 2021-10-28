module DataSources.SqlParser.StatementParserTest exposing (..)

import DataSources.SqlParser.Parsers.AlterTable exposing (TableConstraint(..), TableUpdate(..))
import DataSources.SqlParser.Parsers.Comment exposing (ParsedComment)
import DataSources.SqlParser.StatementParser exposing (Command(..))
import DataSources.SqlParser.TestHelpers.Tests exposing (parsedColumn, parsedTable, testParseStatement)
import Libs.Nel exposing (Nel)
import Test exposing (Test, describe)


suite : Test
suite =
    describe "StatementParser"
        [ describe "parseStatement"
            [ testParseStatement "parse create table"
                "CREATE TABLE aaa.bbb (ccc int);"
                (CreateTable { parsedTable | schema = Just "aaa", table = "bbb", columns = Nel { parsedColumn | name = "ccc", kind = "int" } [] })
            , testParseStatement "parse alter table"
                "ALTER TABLE ONLY public.t2 ADD CONSTRAINT t2_id_pkey PRIMARY KEY (id);"
                (AlterTable (AddTableConstraint (Just "public") "t2" (ParsedPrimaryKey (Just "t2_id_pkey") (Nel "id" []))))
            , testParseStatement "parse table comment"
                "COMMENT ON TABLE public.table1 IS 'A comment';"
                (TableComment { schema = Just "public", table = "table1", comment = ParsedComment "A comment" })
            , testParseStatement "parse column comment"
                "COMMENT ON COLUMN public.table1.col IS 'A comment';"
                (ColumnComment { schema = Just "public", table = "table1", column = "col", comment = ParsedComment "A comment" })
            , testParseStatement "parse lowercase"
                "comment on column public.table1.col is 'A comment';"
                (ColumnComment { schema = Just "public", table = "table1", column = "col", comment = ParsedComment "A comment" })
            , testParseStatement "ignore GO"
                "GO /****** Object:  Schema [api]    Script Date: 6-9-2021 13:53:38 ******/ CREATE SCHEMA [api] ;"
                (Ignored (Nel { line = 0, text = "GO /****** Object:  Schema [api]    Script Date: 6-9-2021 13:53:38 ******/ CREATE SCHEMA [api] ;" } []))
            ]
        ]
