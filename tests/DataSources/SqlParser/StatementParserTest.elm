module DataSources.SqlParser.StatementParserTest exposing (..)

import DataSources.SqlParser.Parsers.AlterTable exposing (TableConstraint(..), TableUpdate(..))
import DataSources.SqlParser.StatementParser exposing (Command(..), parseCommand)
import DataSources.SqlParser.Utils.HelpersTest exposing (stmCheck)
import Libs.Nel exposing (Nel)
import Test exposing (Test, describe)


suite : Test
suite =
    describe "StatementParser"
        [ describe "parseCommand"
            [ stmCheck "parse create table" "CREATE TABLE aaa.bbb (ccc int);" parseCommand (\s -> Ok (CreateTable { schema = Just "aaa", table = "bbb", columns = Nel { name = "ccc", kind = "int", nullable = True, default = Nothing, primaryKey = Nothing, foreignKey = Nothing } [], primaryKey = Nothing, uniques = [], indexes = [], checks = [], source = s }))
            , stmCheck "parse alter table" "ALTER TABLE ONLY public.t2 ADD CONSTRAINT t2_id_pkey PRIMARY KEY (id);" parseCommand (\_ -> Ok (AlterTable (AddTableConstraint (Just "public") "t2" (ParsedPrimaryKey "t2_id_pkey" (Nel "id" [])))))
            , stmCheck "parse table comment" "COMMENT ON TABLE public.table1 IS 'A comment';" parseCommand (\_ -> Ok (TableComment { schema = Just "public", table = "table1", comment = "A comment" }))
            , stmCheck "parse column comment" "COMMENT ON COLUMN public.table1.col IS 'A comment';" parseCommand (\_ -> Ok (ColumnComment { schema = Just "public", table = "table1", column = "col", comment = "A comment" }))
            , stmCheck "parse lowercase" "comment on column public.table1.col is 'A comment';" parseCommand (\_ -> Ok (ColumnComment { schema = Just "public", table = "table1", column = "col", comment = "A comment" }))
            ]
        ]
