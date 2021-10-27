module Models.Project.Column exposing (Column, decode, encode, withNullableInfo)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as D
import Libs.Json.Encode as E
import Models.Project.ColumnIndex exposing (ColumnIndex)
import Models.Project.ColumnName as ColumnName exposing (ColumnName)
import Models.Project.ColumnType as ColumnType exposing (ColumnType)
import Models.Project.ColumnValue as ColumnValue exposing (ColumnValue)
import Models.Project.Comment as Comment exposing (Comment)
import Models.Project.Origin as Origin exposing (Origin)


type alias Column =
    { index : ColumnIndex
    , name : ColumnName
    , kind : ColumnType
    , nullable : Bool
    , default : Maybe ColumnValue
    , comment : Maybe Comment
    , origins : List Origin
    }


withNullableInfo : Bool -> String -> String
withNullableInfo nullable text =
    if nullable then
        text ++ "?"

    else
        text


encode : Column -> Value
encode value =
    E.object
        [ ( "name", value.name |> ColumnName.encode )
        , ( "type", value.kind |> ColumnType.encode )
        , ( "nullable", value.nullable |> E.withDefault Encode.bool False )
        , ( "default", value.default |> E.maybe ColumnValue.encode )
        , ( "comment", value.comment |> E.maybe Comment.encode )
        , ( "origins", value.origins |> E.withDefault (Encode.list Origin.encode) [] )
        ]


decode : Decode.Decoder (Int -> Column)
decode =
    Decode.map6 (\n t nu d c s -> \i -> Column i n t nu d c s)
        (Decode.field "name" ColumnName.decode)
        (Decode.field "type" ColumnType.decode)
        (D.defaultField "nullable" Decode.bool False)
        (D.maybeField "default" ColumnValue.decode)
        (D.maybeField "comment" Comment.decode)
        (D.defaultField "origins" (Decode.list Origin.decode) [])
