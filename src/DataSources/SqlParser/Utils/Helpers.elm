module DataSources.SqlParser.Utils.Helpers exposing (buildRawSql, commaSplit, noEnclosingQuotes, parseIndexDefinition)

import DataSources.SqlParser.Utils.Types exposing (ParseError, RawSql, SqlColumnName, SqlStatement)
import Libs.Nel as Nel
import Libs.Regex as R


parseIndexDefinition : String -> Result (List ParseError) (List SqlColumnName)
parseIndexDefinition definition =
    case definition |> R.matches "^\\((?<columns>[^)]+)\\)$" of
        (Just columns) :: [] ->
            Ok (columns |> String.split "," |> List.map String.trim)

        _ ->
            case definition |> R.matches "^USING[ \t]+[^ ]+[ \t]+\\((?<columns>[^)]+)\\).*$" of
                (Just columns) :: [] ->
                    Ok (columns |> String.split "," |> List.map String.trim)

                _ ->
                    Err [ "Can't parse definition: '" ++ definition ++ "' in create index" ]


buildRawSql : SqlStatement -> RawSql
buildRawSql statement =
    statement |> Nel.toList |> List.map .text |> String.join " "


noEnclosingQuotes : String -> String
noEnclosingQuotes text =
    text |> removeEnclosingDoubleQuotes |> removeEnclosingSingleQuotes |> removeEnclosingBackQuotes


removeEnclosingDoubleQuotes : String -> String
removeEnclosingDoubleQuotes text =
    case text |> R.matches "\"(.*)\"" of
        (Just res) :: [] ->
            res

        _ ->
            text


removeEnclosingSingleQuotes : String -> String
removeEnclosingSingleQuotes text =
    case text |> R.matches "'(.*)'" of
        (Just res) :: [] ->
            res

        _ ->
            text


removeEnclosingBackQuotes : String -> String
removeEnclosingBackQuotes text =
    case text |> R.matches "`(.*)`" of
        (Just res) :: [] ->
            res

        _ ->
            text


commaSplit : String -> List String
commaSplit text =
    String.foldr
        (\char ( res, cur, open ) ->
            if char == ',' && open == 0 then
                ( (cur |> String.fromList) :: res, [], open )

            else if char == '(' then
                ( res, char :: cur, open + 1 )

            else if char == ')' then
                ( res, char :: cur, open - 1 )

            else
                ( res, char :: cur, open )
        )
        ( [], [], 0 )
        text
        |> (\( res, end, _ ) -> (end |> String.fromList) :: res)
