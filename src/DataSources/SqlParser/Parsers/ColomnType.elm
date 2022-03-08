module DataSources.SqlParser.Parsers.ColomnType exposing (ParsedColumnType(..), parse, toString)

import DataSources.SqlParser.Utils.Types exposing (SqlColumnType)
import Libs.Regex as Regex


type ParsedColumnType
    = Unknown SqlColumnType
    | Array ParsedColumnType
    | String
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


parse : SqlColumnType -> ParsedColumnType
parse kind =
    if kind |> String.endsWith "[]" then
        Array (parse (kind |> String.dropRight 2))

    else if (kind |> Regex.match "^(tiny|medium|long)?text$") || (kind |> Regex.match "^character( varying)? ?(\\(\\d+\\))?$") || (kind |> Regex.match "^varchar ?(\\(\\d+\\))?$") then
        String

    else if kind == "integer" || kind == "serial" || (kind |> Regex.match "^(tiny|small|big)?int ?(\\(\\d+\\))?( unsigned)?$") then
        Int

    else if kind == "double precision" || (kind |> Regex.match "^numeric ?(\\(\\d+,\\d+\\))?$") then
        Float

    else if kind == "boolean" then
        Bool

    else if kind == "date" then
        Date

    else if kind |> Regex.match "^time ?(\\(\\d+\\))?( with(out)? time zone)?$" then
        Time

    else if kind == "datetime" || (kind |> Regex.match "^timestamp(tz)? ?(\\(\\d+\\))?( with(out)? time zone)?$") then
        DateTime

    else if kind |> Regex.match "^interval ?(\\(\\d+\\))?$" then
        Interval

    else if kind == "uuid" then
        Uuid

    else if kind == "cidr" || kind == "inet" then
        Ip

    else if kind |> Regex.match "^jsonb?$" then
        Json

    else if kind == "bytea" then
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

        String ->
            "String"

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
