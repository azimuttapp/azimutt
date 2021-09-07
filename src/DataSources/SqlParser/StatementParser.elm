module DataSources.SqlParser.StatementParser exposing (Command(..), parseCommand)

import DataSources.SqlParser.Parsers.AlterTable exposing (TableUpdate, parseAlterTable)
import DataSources.SqlParser.Parsers.Comment exposing (CommentOnColumn, CommentOnTable, parseColumnComment, parseTableComment)
import DataSources.SqlParser.Parsers.CreateIndex exposing (ParsedIndex, parseCreateIndex)
import DataSources.SqlParser.Parsers.CreateTable exposing (ParsedTable, parseCreateTable)
import DataSources.SqlParser.Parsers.CreateUnique exposing (ParsedUnique, parseCreateUniqueIndex)
import DataSources.SqlParser.Parsers.CreateView exposing (ParsedView, parseView)
import DataSources.SqlParser.Utils.Helpers exposing (buildRawSql)
import DataSources.SqlParser.Utils.Types exposing (ParseError, SqlStatement)


type Command
    = CreateTable ParsedTable
    | CreateView ParsedView
    | AlterTable TableUpdate
    | CreateIndex ParsedIndex
    | CreateUnique ParsedUnique
    | TableComment CommentOnTable
    | ColumnComment CommentOnColumn
    | Ignored SqlStatement


parseCommand : SqlStatement -> Result (List ParseError) Command
parseCommand statement =
    if statement.head.text |> String.toUpper |> String.startsWith "CREATE TABLE " then
        parseCreateTable statement |> Result.map CreateTable

    else if statement.head.text |> String.toUpper |> String.startsWith "CREATE VIEW " then
        parseView statement |> Result.map CreateView

    else if statement.head.text |> String.toUpper |> String.startsWith "CREATE MATERIALIZED VIEW " then
        parseView statement |> Result.map CreateView

    else if statement.head.text |> String.toUpper |> String.startsWith "ALTER TABLE " then
        parseAlterTable statement |> Result.map AlterTable

    else if statement.head.text |> String.toUpper |> String.startsWith "CREATE INDEX " then
        parseCreateIndex statement |> Result.map CreateIndex

    else if statement.head.text |> String.toUpper |> String.startsWith "CREATE UNIQUE INDEX " then
        parseCreateUniqueIndex statement |> Result.map CreateUnique

    else if statement.head.text |> String.toUpper |> String.startsWith "COMMENT ON TABLE " then
        parseTableComment statement |> Result.map TableComment

    else if statement.head.text |> String.toUpper |> String.startsWith "COMMENT ON COLUMN " then
        parseColumnComment statement |> Result.map ColumnComment

    else if statement.head.text |> String.toUpper |> String.startsWith "CREATE OR REPLACE VIEW " then
        Ok (Ignored statement)

    else if statement.head.text |> String.toUpper |> String.startsWith "COMMENT ON VIEW " then
        Ok (Ignored statement)

    else if statement.head.text |> String.toUpper |> String.startsWith "COMMENT ON INDEX " then
        Ok (Ignored statement)

    else if statement.head.text |> String.toUpper |> String.startsWith "CREATE TYPE " then
        Ok (Ignored statement)

    else if statement.head.text |> String.toUpper |> String.startsWith "ALTER TYPE " then
        Ok (Ignored statement)

    else if statement.head.text |> String.toUpper |> String.startsWith "CREATE FUNCTION " then
        Ok (Ignored statement)

    else if statement.head.text |> String.toUpper |> String.startsWith "ALTER FUNCTION " then
        Ok (Ignored statement)

    else if statement.head.text |> String.toUpper |> String.startsWith "CREATE OPERATOR " then
        Ok (Ignored statement)

    else if statement.head.text |> String.toUpper |> String.startsWith "ALTER OPERATOR " then
        Ok (Ignored statement)

    else if statement.head.text |> String.toUpper |> String.startsWith "CREATE DATABASE " then
        Ok (Ignored statement)

    else if statement.head.text |> String.toUpper |> String.startsWith "CREATE SCHEMA " then
        Ok (Ignored statement)

    else if statement.head.text |> String.toUpper |> String.startsWith "ALTER SCHEMA " then
        Ok (Ignored statement)

    else if statement.head.text |> String.toUpper |> String.startsWith "COMMENT ON SCHEMA " then
        Ok (Ignored statement)

    else if statement.head.text |> String.toUpper |> String.startsWith "DROP TABLE " then
        Ok (Ignored statement)

    else if statement.head.text |> String.toUpper |> String.startsWith "LOCK TABLES " then
        Ok (Ignored statement)

    else if statement.head.text |> String.toUpper |> String.startsWith "UNLOCK TABLES;" then
        Ok (Ignored statement)

    else if statement.head.text |> String.toUpper |> String.startsWith "CREATE EXTENSION " then
        Ok (Ignored statement)

    else if statement.head.text |> String.toUpper |> String.startsWith "COMMENT ON EXTENSION " then
        Ok (Ignored statement)

    else if statement.head.text |> String.toUpper |> String.startsWith "CREATE TEXT SEARCH CONFIGURATION " then
        Ok (Ignored statement)

    else if statement.head.text |> String.toUpper |> String.startsWith "ALTER TEXT SEARCH CONFIGURATION " then
        Ok (Ignored statement)

    else if statement.head.text |> String.toUpper |> String.startsWith "CREATE SEQUENCE " then
        Ok (Ignored statement)

    else if statement.head.text |> String.toUpper |> String.startsWith "ALTER SEQUENCE " then
        Ok (Ignored statement)

    else if statement.head.text |> String.toUpper |> String.startsWith "GRANT ALL ON " then
        Ok (Ignored statement)

    else if statement.head.text |> String.toUpper |> String.startsWith "REVOKE ALL ON " then
        Ok (Ignored statement)

    else if statement.head.text |> String.toUpper |> String.startsWith "SELECT " then
        Ok (Ignored statement)

    else if statement.head.text |> String.toUpper |> String.startsWith "INSERT INTO " then
        Ok (Ignored statement)

    else if statement.head.text |> String.toUpper |> String.startsWith "USE " then
        Ok (Ignored statement)

    else if statement.head.text |> String.toUpper |> String.startsWith "SET " then
        Ok (Ignored statement)

    else
        Err [ "Statement not handled: '" ++ buildRawSql statement ++ "'" ]
