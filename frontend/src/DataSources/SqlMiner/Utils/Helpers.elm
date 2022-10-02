module DataSources.SqlMiner.Utils.Helpers exposing (buildColumnName, buildColumnType, buildComment, buildConstraintName, buildEnumValue, buildRawSql, buildSchemaName, buildSqlLine, buildTableName, buildTypeName, commaSplit, deferrable, noEnclosingQuotes, parseIndexDefinition, sqlTriggers)

import DataSources.SqlMiner.Utils.Types exposing (ParseError, RawSql, SqlColumnName, SqlColumnType, SqlComment, SqlConstraintName, SqlEnumValue, SqlSchemaName, SqlStatement, SqlTableName, SqlTypeName)
import Libs.Nel as Nel
import Libs.Regex as Regex


parseIndexDefinition : String -> Result (List ParseError) (List SqlColumnName)
parseIndexDefinition definition =
    case definition |> Regex.matches ("^\\((?<columns>[^)]+)\\)" ++ deferrable ++ ".*$") of
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


deferrable : String
deferrable =
    "(?:(?:\\s+NOT)?\\s+DEFERRABLE(?:\\s+INITIALLY (?:IMMEDIATE|DEFERRED))?)?"


buildRawSql : SqlStatement -> RawSql
buildRawSql statement =
    statement |> Nel.toList |> List.map .text |> String.join "\n"


buildSqlLine : SqlStatement -> RawSql
buildSqlLine statement =
    statement |> Nel.toList |> List.map .text |> List.map String.trim |> String.join " "


buildSchemaName : String -> SqlSchemaName
buildSchemaName name =
    name |> String.trim |> noEnclosingQuotes


buildTableName : String -> SqlTableName
buildTableName name =
    name |> String.trim |> noEnclosingQuotes


buildColumnName : String -> SqlColumnName
buildColumnName name =
    name |> String.trim |> noEnclosingQuotes


buildColumnType : String -> SqlColumnType
buildColumnType name =
    name |> String.trim |> noEnclosingQuotes


buildTypeName : String -> SqlTypeName
buildTypeName name =
    name |> String.trim |> noEnclosingQuotes


buildEnumValue : String -> SqlEnumValue
buildEnumValue name =
    name |> String.trim |> noEnclosingQuotes


buildConstraintName : String -> SqlConstraintName
buildConstraintName name =
    name |> String.trim |> String.split "." |> List.map noEnclosingQuotes |> String.join "."


buildComment : String -> SqlComment
buildComment comment =
    comment |> String.replace "''" "'" |> String.replace "\"\"" "\""


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
    -- split on comma but ignore when inside (), '' or ""
    String.foldr
        (\char ( res, cur, open ) ->
            if char == ',' && List.isEmpty open then
                ( (cur |> String.fromList) :: res, [], open )

            else if char == '(' && List.head open == Just ')' then
                ( res, char :: cur, open |> List.tail |> Maybe.withDefault [] )

            else if char == ')' then
                ( res, char :: cur, char :: open )

            else if char == '\'' && List.head open == Just '\'' then
                ( res, char :: cur, open |> List.tail |> Maybe.withDefault [] )

            else if char == '\'' && List.head open /= Just '"' then
                ( res, char :: cur, char :: open )

            else if char == '"' && List.head open == Just '"' then
                ( res, char :: cur, open |> List.tail |> Maybe.withDefault [] )

            else if char == '"' && List.head open /= Just '\'' then
                ( res, char :: cur, char :: open )

            else
                ( res, char :: cur, open )
        )
        ( [], [], [] )
        text
        |> (\( res, end, _ ) -> (end |> String.fromList) :: res)
