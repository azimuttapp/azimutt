module DataSources.SqlParser.Utils.Helpers exposing (buildColumnName, buildConstraintName, buildRawSql, buildSchemaName, buildSqlLine, buildTableName, commaSplit, defaultCheckName, defaultFkName, defaultPkName, defaultUniqueName, noEnclosingQuotes, parseIndexDefinition, sqlTriggers)

import DataSources.SqlParser.Utils.Types exposing (ParseError, RawSql, SqlColumnName, SqlConstraintName, SqlSchemaName, SqlStatement, SqlTableName)
import Libs.Nel as Nel
import Libs.Regex as Regex


parseIndexDefinition : String -> Result (List ParseError) (List SqlColumnName)
parseIndexDefinition definition =
    case definition |> Regex.matches "^\\((?<columns>[^)]+)\\)(?:(?:\\s+NOT)?\\s+DEFERRABLE)?$" of
        (Just columns) :: [] ->
            Ok (columns |> String.split "," |> List.map String.trim)

        _ ->
            case definition |> Regex.matches "^USING[ \t]+[^ ]+[ \t]+\\((?<columns>[^)]+)\\).*$" of
                (Just columns) :: [] ->
                    Ok (columns |> String.split "," |> List.map String.trim)

                _ ->
                    Err [ "Can't parse definition: '" ++ definition ++ "' in create index" ]


sqlTriggers : String
sqlTriggers =
    "(?:\\s+(?:ON UPDATE|ON DELETE)\\s+(?:NO ACTION|CASCADE|SET NULL|SET DEFAULT|RESTRICT))*"


buildRawSql : SqlStatement -> RawSql
buildRawSql statement =
    statement |> Nel.toList |> List.map .text |> String.join "\n"


buildSqlLine : SqlStatement -> RawSql
buildSqlLine statement =
    statement |> Nel.toList |> List.map .text |> List.map String.trim |> String.join " "


defaultPkName : SqlTableName -> SqlConstraintName
defaultPkName table =
    table ++ "_pk_az"


defaultFkName : SqlTableName -> SqlColumnName -> SqlConstraintName
defaultFkName table column =
    table ++ "_" ++ column ++ "_fk_az"


defaultUniqueName : SqlTableName -> SqlColumnName -> SqlConstraintName
defaultUniqueName table column =
    table ++ "_" ++ column ++ "_unique_az"


defaultCheckName : SqlTableName -> SqlColumnName -> SqlConstraintName
defaultCheckName table column =
    table ++ "_" ++ column ++ "_check_az"


buildSchemaName : String -> SqlSchemaName
buildSchemaName name =
    name |> String.trim |> noEnclosingQuotes


buildTableName : String -> SqlTableName
buildTableName name =
    name |> String.trim |> noEnclosingQuotes


buildColumnName : String -> SqlColumnName
buildColumnName name =
    name |> String.trim |> noEnclosingQuotes


buildConstraintName : String -> SqlConstraintName
buildConstraintName name =
    name |> String.trim |> noEnclosingQuotes


noEnclosingQuotes : String -> String
noEnclosingQuotes text =
    text |> extract "\"(.*)\"" |> extract "'(.*)'" |> extract "`(.*)`" |> extract "\\[(.*)]"


extract : String -> String -> String
extract regex text =
    case text |> Regex.matches regex of
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
