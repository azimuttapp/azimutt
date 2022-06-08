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
    (if firstLine |> startsWith "CREATE( UNLOGGED)? TABLE" then
        parseCreateTable statement |> Result.map CreateTable

     else if firstLine |> startsWith "ALTER TABLE" then
        parseAlterTable statement |> Result.map AlterTable

     else if firstLine |> startsWith "CREATE( OR REPLACE)?( MATERIALIZED)? VIEW" then
        parseView statement |> Result.map CreateView

     else if firstLine |> startsWith "COMMENT ON (TABLE|VIEW)" then
        parseTableComment statement |> Result.map TableComment

     else if firstLine |> startsWith "COMMENT ON COLUMN" then
        parseColumnComment statement |> Result.map ColumnComment

     else if firstLine |> startsWith "CREATE INDEX" then
        parseCreateIndex statement |> Result.map CreateIndex

     else if firstLine |> startsWith "CREATE UNIQUE INDEX" then
        parseCreateUniqueIndex statement |> Result.map CreateUnique

     else if firstLine |> startsWith "SELECT" then
        Ok (Ignored statement)

     else if firstLine |> startsWith "INSERT INTO" then
        Ok (Ignored statement)

     else if firstLine |> startsWith "CREATE DOMAIN" then
        Ok (Ignored statement)

     else if firstLine |> startsWith "(CREATE|DROP) DATABASE" then
        Ok (Ignored statement)

     else if firstLine |> startsWith "(CREATE|ALTER|DROP|COMMENT ON) SCHEMA" then
        Ok (Ignored statement)

     else if firstLine |> startsWith "DROP TABLE" then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "ALTER COLUMN " then
        Ok (Ignored statement)

     else if firstLine |> startsWith "(ALTER|COMMENT ON) INDEX" then
        Ok (Ignored statement)

     else if firstLine |> startsWith "(CREATE|ALTER|DROP|COMMENT ON) TYPE" then
        Ok (Ignored statement)

     else if firstLine |> startsWith "(CREATE( OR REPLACE)?|ALTER) FUNCTION" then
        Ok (Ignored statement)

     else if firstLine |> startsWith "(CREATE|ALTER) OPERATOR" then
        Ok (Ignored statement)

     else if firstLine |> startsWith "(CREATE|COMMENT ON) EXTENSION" then
        Ok (Ignored statement)

     else if firstLine |> startsWith "(CREATE|ALTER) TEXT SEARCH CONFIGURATION" then
        Ok (Ignored statement)

     else if firstLine |> startsWith "(CREATE|ALTER) SEQUENCE" then
        Ok (Ignored statement)

     else if firstLine |> startsWith "(CREATE|ALTER) AGGREGATE" then
        Ok (Ignored statement)

     else if firstLine |> startsWith "CREATE TRIGGER" then
        Ok (Ignored statement)

     else if firstLine |> startsWith "LOCK TABLES" then
        Ok (Ignored statement)

     else if firstLine |> String.startsWith "UNLOCK TABLES;" then
        Ok (Ignored statement)

     else if firstLine |> startsWith "GRANT" then
        Ok (Ignored statement)

     else if firstLine |> startsWith "REVOKE" then
        Ok (Ignored statement)

     else if firstLine |> startsWith "START TRANSACTION" then
        Ok (Ignored statement)

     else if firstLine |> startsWith "USE" then
        Ok (Ignored statement)

     else if firstLine |> startsWith "PRAGMA" then
        Ok (Ignored statement)

     else if firstLine |> startsWith "BEGIN" then
        Ok (Ignored statement)

     else if firstLine |> startsWith "END" then
        Ok (Ignored statement)

     else if firstLine |> startsWith "COMMIT" then
        Ok (Ignored statement)

     else if firstLine |> startsWith "DECLARE" then
        Ok (Ignored statement)

     else if firstLine |> startsWith "DELIMITER" then
        Ok (Ignored statement)

     else if firstLine |> startsWith "SET" then
        Ok (Ignored statement)

     else if firstLine |> startsWith "GO" then
        Ok (Ignored statement)

     else if firstLine |> startsWith "$$" then
        Ok (Ignored statement)

     else
        Err [ "Statement not handled: '" ++ buildRawSql statement ++ "'" ]
    )
        |> Result.map (\cmd -> ( statement, cmd ))


startsWith : String -> String -> Bool
startsWith token text =
    text |> Regex.matchI ("^" ++ token ++ "( |$)")
