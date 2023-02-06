module Models.Project.Column exposing (Column, ColumnLike, NestedColumns(..), clearOrigins, decode, encode, merge, withNullable)

import Conf
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Maybe as Maybe
import Libs.Ned as Ned exposing (Ned)
import Libs.Nel as Nel
import Models.Project.ColumnIndex exposing (ColumnIndex)
import Models.Project.ColumnName as ColumnName exposing (ColumnName)
import Models.Project.ColumnType as ColumnType exposing (ColumnType)
import Models.Project.ColumnValue as ColumnValue exposing (ColumnValue)
import Models.Project.Comment as Comment exposing (Comment)
import Models.Project.Origin as Origin exposing (Origin)
import Services.Lenses exposing (mapCommentM, setOrigins)


type alias Column =
    { index : ColumnIndex
    , name : ColumnName
    , kind : ColumnType
    , nullable : Bool
    , default : Maybe ColumnValue
    , comment : Maybe Comment
    , columns : Maybe NestedColumns
    , origins : List Origin
    }


type NestedColumns
    = NestedColumns (Ned ColumnName Column)


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
    , kind =
        if c1.kind == Conf.schema.column.unknownType then
            c2.kind

        else
            c1.kind
    , nullable = c1.nullable && c2.nullable
    , default = Maybe.merge ColumnValue.merge c1.default c2.default
    , comment = Maybe.merge Comment.merge c1.comment c2.comment
    , columns = Maybe.merge mergeNested c1.columns c2.columns
    , origins = c1.origins ++ c2.origins
    }


mergeNested : NestedColumns -> NestedColumns -> NestedColumns
mergeNested (NestedColumns c1) (NestedColumns c2) =
    Ned.merge merge c1 c2 |> NestedColumns


clearOrigins : Column -> Column
clearOrigins column =
    column |> setOrigins [] |> mapCommentM Comment.clearOrigins


encode : Column -> Value
encode value =
    Encode.notNullObject
        [ ( "name", value.name |> ColumnName.encode )
        , ( "type", value.kind |> ColumnType.encode )
        , ( "nullable", value.nullable |> Encode.withDefault Encode.bool False )
        , ( "default", value.default |> Encode.maybe ColumnValue.encode )
        , ( "comment", value.comment |> Encode.maybe Comment.encode )
        , ( "columns", value.columns |> Encode.maybe (\(NestedColumns d) -> d |> Ned.values |> Nel.toList |> List.sortBy .index |> Encode.list encode) )
        , ( "origins", value.origins |> Origin.encodeList )
        ]


decode : Decoder (Int -> Column)
decode =
    Decode.map7 (\n t nu d c cols o -> \i -> Column i n t nu d c cols o)
        (Decode.field "name" ColumnName.decode)
        (Decode.field "type" ColumnType.decode)
        (Decode.defaultField "nullable" Decode.bool False)
        (Decode.maybeField "default" ColumnValue.decode)
        (Decode.maybeField "comment" Comment.decode)
        (Decode.maybeField "columns" decodeNestedColumns)
        (Decode.defaultField "origins" (Decode.list Origin.decode) [])


decodeNestedColumns : Decoder NestedColumns
decodeNestedColumns =
    Decode.map NestedColumns
        (Decode.nel (Decode.lazy (\_ -> decode)) |> Decode.map (Nel.indexedMap (\i c -> c i) >> Ned.fromNelMap .name))
