module Models.Project.ColumnType exposing (ColumnType, asBasic, decode, encode, label)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Regex as Regex
import Libs.String as String
import Models.Project.SchemaName exposing (SchemaName)


type alias ColumnType =
    String


label : SchemaName -> ColumnType -> String
label defaultSchema kind =
    kind |> String.stripLeft (defaultSchema ++ ".")


encode : ColumnType -> Value
encode value =
    Encode.string value


decode : Decode.Decoder ColumnType
decode =
    Decode.string


asBasic : ColumnType -> ColumnType
asBasic kind =
    kind |> parse |> toString


type ParsedColumnType
    = Unknown ColumnType
    | Array ParsedColumnType
    | Text
    | Int
    | Float
    | Bool
    | Date
    | Time
    | DateTime
    | Interval
    | Uuid
    | Ip
    | Json
    | Binary


parse : ColumnType -> ParsedColumnType
parse kind =
    if kind |> String.endsWith "[]" then
        Array (parse (kind |> String.dropRight 2))

    else if (kind |> Regex.matchI "^(tiny|medium|long)?text$") || (kind |> Regex.matchI "^character( varying)? ?(\\(\\d+\\))?$") || (kind |> Regex.matchI "^n?(var)?char ?(\\([^)]+\\))?$") then
        Text

    else if (kind |> Regex.matchI "integer|bit") || (kind |> Regex.matchI "number\\(\\d+(\\s*,\\s*0)?\\)") || (kind |> Regex.matchI "^(small)?serial$") || (kind |> Regex.matchI "^(tiny|small|big)?int ?(\\(\\d+\\))?( unsigned)?$") then
        Int

    else if (kind |> Regex.matchI "double precision") || (kind |> Regex.matchI "number") || (kind |> Regex.matchI "^numeric ?(\\(\\d+,\\d+\\))?$") then
        Float

    else if kind |> Regex.matchI "boolean" then
        Bool

    else if kind |> Regex.matchI "date$" then
        Date

    else if kind |> Regex.matchI "^time ?(\\(\\d+\\))?( with(out)? time zone)?$" then
        Time

    else if (kind |> Regex.matchI "^datetime(offset)?$") || (kind |> Regex.matchI "^timestamp(tz)? ?(\\(\\d+\\))?( with(out)? time zone)?$") then
        DateTime

    else if kind |> Regex.matchI "^interval ?(\\(\\d+\\))?$" then
        Interval

    else if kind |> Regex.matchI "uuid" then
        Uuid

    else if (kind |> Regex.matchI "cidr") || (kind |> Regex.matchI "inet") then
        Ip

    else if kind |> Regex.matchI "^jsonb?$" then
        Json

    else if kind |> Regex.matchI "bytea" then
        Binary

    else
        Unknown kind


toString : ParsedColumnType -> String
toString kind =
    case kind of
        Unknown value ->
            value

        Array k ->
            toString k ++ "[]"

        Text ->
            "Text"

        Int ->
            "Int"

        Float ->
            "Float"

        Bool ->
            "Bool"

        Date ->
            "Date"

        Time ->
            "Time"

        DateTime ->
            "DateTime"

        Interval ->
            "Interval"

        Uuid ->
            "Uuid"

        Ip ->
            "Ip"

        Json ->
            "Json"

        Binary ->
            "Binary"
