module DataSources.SqlParser.StatementParser exposing (Command(..), parse)

import DataSources.SqlParser.Parsers.AlterTable exposing (TableUpdate, parseAlterTable)
import DataSources.SqlParser.Parsers.Comment exposing (CommentOnColumn, CommentOnTable, parseColumnComment, parseTableComment)
import DataSources.SqlParser.Parsers.CreateIndex exposing (ParsedIndex, parseCreateIndex)
import DataSources.SqlParser.Parsers.CreateTable exposing (ParsedTable, parseCreateTable)
import DataSources.SqlParser.Parsers.CreateUnique exposing (ParsedUnique, parseCreateUniqueIndex)
import DataSources.SqlParser.Parsers.CreateView exposing (ParsedView, parseView)
import DataSources.SqlParser.Utils.Helpers exposing (buildRawSql)
import DataSources.SqlParser.Utils.Types exposing (ParseError, SqlStatement)
import Libs.Regex as Regex


type Command
    = CreateTable ParsedTable
    | CreateView ParsedView
    | AlterTable TableUpdate
    | CreateIndex ParsedIndex
    | CreateUnique ParsedUnique
    | TableComment CommentOnTable
    | ColumnComment CommentOnColumn
    | Ignored SqlStatement


parse : SqlStatement -> Result (List ParseError) ( SqlStatement, Command )
parse statement =
    let
        firstLine : String
        firstLine =
            statement.head.text |> String.trim |> String.toUpper
    in
    (if firstLine |> Regex.match "^CREATE( UNLOGGED)? TABLE " then
        parseCreateTable statement |> Result.map CreateTable

     else if firstLine |> String.startsWith "CREATE VIEW " then
        parseView statement |> Result.map CreateView

     else if firstLine |> String.startsWith "CREATE MATERIALIZED VIEW " then
        parseView statement |> Result.map CreateView

     else if firstLine |> String.startsWith "ALTER TABLE " then
        parseAlterTable statement |> Result.map AlterTable

     else if firstLine |> String.startsWith "CREATE INDEX " then
        parseCreateIndex statement |> Result.map CreateIndex

     else if firstLine |> String.startsWith "CREATE UNIQUE INDEX " then
        parseCreateUniqueIndex statement |> Result.map CreateUnique

     else if firstLine |> String.startsWith "COMMENT ON TABLE " then
        parseTableComment statement |> Result.map TableComment

     else if firstLine |> String.startsWith "COMMENT ON COLUMN " then
        parseColumnComment statement |> Result.map ColumnComment

     else if firstLine |> String.startsWith "ALTER COLUMN " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "CREATE OR REPLACE VIEW " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "COMMENT ON VIEW " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "ALTER INDEX " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "COMMENT ON INDEX " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "CREATE TYPE " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "ALTER TYPE " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "DROP TYPE " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "COMMENT ON TYPE " then
        Ok (Ignored statement)

     else if firstLine |> Regex.match "^CREATE( OR REPLACE)? FUNCTION " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "ALTER FUNCTION " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "CREATE OPERATOR " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "ALTER OPERATOR " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "CREATE DATABASE " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "DROP DATABASE " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "CREATE SCHEMA " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "ALTER SCHEMA " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "COMMENT ON SCHEMA " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "DROP SCHEMA " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "DROP TABLE " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "LOCK TABLES " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "UNLOCK TABLES;" then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "CREATE EXTENSION " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "COMMENT ON EXTENSION " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "CREATE TEXT SEARCH CONFIGURATION " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "ALTER TEXT SEARCH CONFIGURATION " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "CREATE SEQUENCE " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "ALTER SEQUENCE " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "CREATE TRIGGER " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "GRANT " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "REVOKE " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "SELECT " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "INSERT INTO " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "START TRANSACTION" then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "CREATE AGGREGATE " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "ALTER AGGREGATE " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "USE " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "PRAGMA " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "BEGIN" then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "COMMIT" then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "SET " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "GO " then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "END" then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "$$" then
        Ok (Ignored statement)

     else
        Err [ "Statement not handled: '" ++ buildRawSql statement ++ "'" ]
    )
        |> Result.map (\cmd -> ( statement, cmd ))
