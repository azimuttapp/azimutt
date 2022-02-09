module Models.Project.Column exposing (Column, ColumnLike, decode, encode, merge, withName, withNullable)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Maybe as Maybe
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


type alias ColumnLike x =
    { x
        | index : ColumnIndex
        , name : ColumnName
        , kind : ColumnType
        , nullable : Bool
        , default : Maybe ColumnValue
        , comment : Maybe Comment
        , origins : List Origin
    }


withName : ColumnLike x -> String -> String
withName column text =
    ColumnName.withName column.name text


withNullable : ColumnLike x -> String -> String
withNullable column text =
    if column.nullable then
        text ++ "?"

    else
        text


merge : Column -> Column -> Column
merge c1 c2 =
    { index = c1.index
    , name = c1.name
    , kind = c1.kind
    , nullable = c1.nullable && c2.nullable
    , default = Maybe.merge ColumnValue.merge c1.default c2.default
    , comment = Maybe.merge Comment.merge c1.comment c2.comment
    , origins = c1.origins ++ c2.origins
    }


encode : Column -> Value
encode value =
    Encode.notNullObject
        [ ( "name", value.name |> ColumnName.encode )
        , ( "type", value.kind |> ColumnType.encode )
        , ( "nullable", value.nullable |> Encode.withDefault Encode.bool False )
        , ( "default", value.default |> Encode.maybe ColumnValue.encode )
        , ( "comment", value.comment |> Encode.maybe Comment.encode )
        , ( "origins", value.origins |> Encode.withDefault (Encode.list Origin.encode) [] )
        ]


decode : Decode.Decoder (Int -> Column)
decode =
    Decode.map6 (\n t nu d c s -> \i -> Column i n t nu d c s)
        (Decode.field "name" ColumnName.decode)
        (Decode.field "type" ColumnType.decode)
        (Decode.defaultField "nullable" Decode.bool False)
        (Decode.maybeField "default" ColumnValue.decode)
        (Decode.maybeField "comment" Comment.decode)
        (Decode.defaultField "origins" (Decode.list Origin.decode) [])
