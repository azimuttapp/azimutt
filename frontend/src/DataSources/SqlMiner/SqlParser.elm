module DataSources.SqlMiner.SqlParser exposing (Command(..), buildStatements, hasKeyword, parse, parseCommand, splitLines)

import DataSources.Helpers exposing (SourceLine)
import DataSources.SqlMiner.Parsers.AlterTable exposing (TableUpdate, parseAlterTable)
import DataSources.SqlMiner.Parsers.Comment exposing (CommentOnColumn, CommentOnConstraint, CommentOnTable, parseColumnComment, parseColumnConstraint, parseTableComment)
import DataSources.SqlMiner.Parsers.CreateIndex exposing (ParsedIndex, parseCreateIndex)
import DataSources.SqlMiner.Parsers.CreateTable exposing (ParsedTable, parseCreateTable)
import DataSources.SqlMiner.Parsers.CreateType exposing (ParsedType, parseCreateType)
import DataSources.SqlMiner.Parsers.CreateUnique exposing (ParsedUnique, parseCreateUniqueIndex)
import DataSources.SqlMiner.Parsers.CreateView exposing (ParsedView, parseView)
import DataSources.SqlMiner.Utils.Helpers exposing (buildRawSql)
import DataSources.SqlMiner.Utils.Types exposing (ParseError, RawSql, SqlStatement)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Regex as Regex
import Libs.Result as Result


type Command
    = CreateTable ParsedTable
    | CreateView ParsedView
    | AlterTable TableUpdate
    | CreateIndex ParsedIndex
    | CreateUnique ParsedUnique
    | TableComment CommentOnTable
    | ColumnComment CommentOnColumn
    | ConstraintComment CommentOnConstraint
    | CreateType ParsedType
    | Ignored SqlStatement


parse : RawSql -> ( List ParseError, List Command )
parse input =
    input
        |> splitLines
        |> buildStatements
        |> List.foldr
            (\statement ( errors, commands ) ->
                statement
                    |> parseCommand
                    |> Result.fold (\errs -> ( errs ++ errors, commands )) (\command -> ( errors, command :: commands ))
            )
            ( [], [] )


splitLines : RawSql -> List SourceLine
splitLines input =
    input
        |> String.replace "\u{000D}\n" "\n"
        |> String.replace "\u{000D}" "\n"
        |> String.split "\n"
        |> List.indexedMap (\i line -> { index = i, text = line })


filterEmptyOrCommentedLines : List SourceLine -> List SourceLine
filterEmptyOrCommentedLines lines =
    lines
        |> List.filter
            (\line ->
                line.text
                    |> String.trim
                    |> (\text ->
                            String.isEmpty text
                                || String.startsWith "--" text
                                || String.startsWith "#" text
                                || Regex.matchI "^/\\*(.*)\\*/;?$" text
                                || String.startsWith "USE" text
                                || String.startsWith "GO" text
                       )
                    |> not
            )
        |> List.foldr
            (\line ( result, inComment ) ->
                if line.text |> Regex.match "^\\s*/\\*" then
                    ( result, False )

                else if line.text |> Regex.match "\\*/;?\\s*$" then
                    ( result, True )

                else if inComment then
                    ( result, inComment )

                else
                    ( line :: result, inComment )
            )
            ( [], False )
        |> Tuple.first


aggregateStatementLines : List SourceLine -> List SqlStatement
aggregateStatementLines lines =
    lines
        |> List.foldr
            (\line ( currentStatementLines, statements, nestedBlock ) ->
                case
                    ( ( (line.text |> hasKeyword "BEGIN") || (line.text |> hasKeyword "CASE") || (line.text |> hasKeyword "LOOP") || (line.text |> hasKeyword "\\$\\$")
                      , (line.text |> hasKeyword "END") || (line.text |> hasKeyword "\\$\\$;")
                      )
                    , ( line.text |> removeTrailingComment |> String.endsWith ";"
                      , nestedBlock
                      )
                    )
                of
                    ( ( True, _ ), ( False, _ ) ) ->
                        ( line :: currentStatementLines, statements, max (nestedBlock - 1) 0 )

                    ( ( _, True ), ( False, _ ) ) ->
                        ( line :: currentStatementLines, statements, nestedBlock + 1 )

                    ( ( _, True ), ( True, 0 ) ) ->
                        ( line :: [], addStatement currentStatementLines statements, nestedBlock + 1 )

                    ( ( _, True ), ( True, _ ) ) ->
                        ( line :: currentStatementLines, statements, nestedBlock + 1 )

                    ( ( _, False ), ( True, 0 ) ) ->
                        ( line :: [], addStatement currentStatementLines statements, nestedBlock )

                    _ ->
                        ( line :: currentStatementLines, statements, nestedBlock )
            )
            ( [], [], 0 )
        |> (\( cur, res, _ ) -> addStatement cur res)
        |> List.filterNot statementIsEmpty


groupConsecutiveLines : List SourceLine -> List (List SourceLine)
groupConsecutiveLines lines =
    lines
        |> List.foldr
            (\line ( cur, groups ) ->
                if (cur |> List.isEmpty) || (line.index + 1 == (cur |> List.head |> Maybe.mapOrElse .index 0)) then
                    ( line :: cur, groups )

                else
                    ( [ line ], cur :: groups )
            )
            ( [], [] )
        |> (\( cur, groups ) -> cur :: groups)


buildStatements : List SourceLine -> List SqlStatement
buildStatements lines =
    lines
        |> filterEmptyOrCommentedLines
        |> groupConsecutiveLines
        |> List.concatMap aggregateStatementLines


parseCommand : SqlStatement -> Result (List ParseError) Command
parseCommand statement =
    let
        firstLine : String
        firstLine =
            statement.head.text |> String.trim |> String.toUpper
    in
    if firstLine |> startsWith "CREATE( UNLOGGED)? TABLE" then
        statement |> parseCreateTable |> Result.map CreateTable

    else if firstLine |> startsWith "ALTER TABLE" then
        statement |> parseAlterTable |> Result.map AlterTable

    else if firstLine |> startsWith "CREATE( OR REPLACE)?( MATERIALIZED)? VIEW" then
        statement |> parseView |> Result.map CreateView

    else if firstLine |> startsWith "COMMENT ON (TABLE|VIEW)" then
        statement |> parseTableComment |> Result.map TableComment

    else if firstLine |> startsWith "COMMENT ON COLUMN" then
        statement |> parseColumnComment |> Result.map ColumnComment

    else if firstLine |> startsWith "CREATE INDEX" then
        statement |> parseCreateIndex |> Result.map CreateIndex

    else if firstLine |> startsWith "CREATE UNIQUE INDEX" then
        statement |> parseCreateUniqueIndex |> Result.map CreateUnique

    else if firstLine |> startsWith "COMMENT ON CONSTRAINT" then
        statement |> parseColumnConstraint |> Result.map ConstraintComment

    else if firstLine |> startsWith "CREATE TYPE" then
        statement |> parseCreateType |> Result.map CreateType

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

    else if firstLine |> startsWith "(ALTER|DROP|COMMENT ON) TYPE" then
        Ok (Ignored statement)

    else if firstLine |> startsWith "(CREATE( OR REPLACE)?|ALTER) FUNCTION" then
        Ok (Ignored statement)

    else if firstLine |> startsWith "(CREATE|ALTER) OPERATOR" then
        Ok (Ignored statement)

    else if firstLine |> startsWith "(CREATE|COMMENT ON) EXTENSION" then
        Ok (Ignored statement)

    else if firstLine |> startsWith "(CREATE|ALTER) TEXT SEARCH CONFIGURATION" then
        Ok (Ignored statement)

    else if firstLine |> startsWith "(CREATE|ALTER|COMMENT ON) SEQUENCE" then
        Ok (Ignored statement)

    else if firstLine |> startsWith "(CREATE|ALTER) AGGREGATE" then
        Ok (Ignored statement)

    else if firstLine |> startsWith "(CREATE|COMMENT ON) TRIGGER" then
        Ok (Ignored statement)

    else if firstLine |> startsWith "CREATE PROCEDURE" then
        Ok (Ignored statement)

    else if firstLine |> startsWith "CREATE RULE" then
        Ok (Ignored statement)

    else if firstLine |> startsWith "CREATE POLICY" then
        Ok (Ignored statement)

    else if firstLine |> startsWith "(CREATE|DROP) PUBLICATION" then
        Ok (Ignored statement)

    else if firstLine |> startsWith "(CREATE|ALTER|COMMENT ON) TEXT SEARCH (PARSER|TEMPLATE|DICTIONARY|CONFIGURATION)" then
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


hasKeyword : String -> String -> Bool
hasKeyword keyword content =
    (content |> Regex.matchI ("(^|[^A-Z0-9_\"'`])" ++ keyword ++ "([^A-Z0-9_\"'`]|$)")) && not (content |> Regex.matchI ("'.*" ++ keyword ++ ".*'"))


removeTrailingComment : String -> String
removeTrailingComment line =
    (line |> String.split "--" |> List.head)
        |> Maybe.orElse (line |> String.split "#" |> List.head)
        |> Maybe.withDefault line
        |> String.trimRight


addStatement : List SourceLine -> List SqlStatement -> List SqlStatement
addStatement lines statements =
    case lines of
        [] ->
            statements

        head :: tail ->
            { head = head, tail = tail } :: statements


statementIsEmpty : SqlStatement -> Bool
statementIsEmpty statement =
    statement.head.text == ";"


startsWith : String -> String -> Bool
startsWith token text =
    text |> Regex.matchI ("^" ++ token ++ "( |$)")
