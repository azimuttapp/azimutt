module DataSources.SqlMiner.Parsers.CreateType exposing (ParsedType, ParsedTypeValue(..), parseCreateType)

import DataSources.SqlMiner.Utils.Helpers exposing (buildEnumValue, buildRawSql, buildSchemaName, buildSqlLine, buildTypeName, commaSplit)
import DataSources.SqlMiner.Utils.Types exposing (ParseError, RawSql, SqlEnumValue, SqlSchemaName, SqlStatement, SqlTypeName)
import Libs.Regex as Regex
import Libs.String as String


type alias ParsedType =
    { schema : Maybe SqlSchemaName, name : SqlTypeName, value : ParsedTypeValue }


type ParsedTypeValue
    = EnumType (List SqlEnumValue)
    | UnknownType String


parseCreateType : SqlStatement -> Result (List ParseError) ParsedType
parseCreateType statement =
    case statement |> buildSqlLine |> Regex.matches "^CREATE\\s+TYPE\\s+(?:(?<schema>[^ .]+)\\.)?(?<name>[^ .]+)(?:\\s+AS)?\\s+(?<definition>.+);$" of
        schema :: (Just name) :: (Just definition) :: [] ->
            (if definition |> String.startsWith "ENUM" then
                parseCreateTypeEnum definition |> Result.map EnumType

             else
                definition |> UnknownType |> Ok
            )
                |> Result.map
                    (\value ->
                        { schema = schema |> Maybe.map buildSchemaName
                        , name = name |> buildTypeName
                        , value = value
                        }
                    )

        _ ->
            Err [ "Can't parse type: '" ++ buildRawSql statement ++ "'" ]


parseCreateTypeEnum : RawSql -> Result (List ParseError) (List SqlEnumValue)
parseCreateTypeEnum definition =
    case definition |> Regex.matches "^ENUM\\s*\\((?<values>.+)\\)$" of
        (Just values) :: [] ->
            Ok (values |> commaSplit |> List.map buildEnumValue |> List.filter String.nonEmpty)

        _ ->
            Err [ "Can't parse enum type: '" ++ definition ++ "'" ]
