module Models.Project.Column exposing (Column, ColumnLike, NestedColumns(..), decode, encode, flatten, getColumn)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Maybe as Maybe
import Libs.Ned as Ned exposing (Ned)
import Libs.Nel as Nel exposing (Nel)
import Models.Project.ColumnIndex exposing (ColumnIndex)
import Models.Project.ColumnName as ColumnName exposing (ColumnName)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.ColumnType as ColumnType exposing (ColumnType)
import Models.Project.ColumnValue as ColumnValue exposing (ColumnValue)
import Models.Project.Comment as Comment exposing (Comment)


type alias Column =
    { index : ColumnIndex
    , name : ColumnName
    , kind : ColumnType
    , nullable : Bool
    , default : Maybe ColumnValue
    , comment : Maybe Comment
    , values : Maybe (Nel String)
    , columns : Maybe NestedColumns
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
    }


flatten : Column -> List { path : ColumnPath, column : Column }
flatten col =
    Nel col.name [] |> (\path -> { path = path, column = col } :: (col.columns |> Maybe.mapOrElse (flattenNested path) []))


flattenNested : ColumnPath -> NestedColumns -> List { path : ColumnPath, column : Column }
flattenNested path (NestedColumns cols) =
    cols |> Ned.values |> Nel.toList |> List.concatMap (\col -> path |> ColumnPath.child col.name |> (\p -> [ { path = p, column = col } ] ++ (col.columns |> Maybe.mapOrElse (flattenNested p) [])))


getColumn : ColumnPath -> Column -> Maybe Column
getColumn path column =
    column.columns
        |> Maybe.andThen (\(NestedColumns cols) -> cols |> Ned.get path.head)
        |> Maybe.andThen (\col -> path.tail |> Nel.fromList |> Maybe.mapOrElse (\next -> getColumn next col) (Just col))


encode : Column -> Value
encode value =
    Encode.notNullObject
        [ ( "name", value.name |> ColumnName.encode )
        , ( "type", value.kind |> ColumnType.encode )
        , ( "nullable", value.nullable |> Encode.withDefault Encode.bool False )
        , ( "default", value.default |> Encode.maybe ColumnValue.encode )
        , ( "comment", value.comment |> Encode.maybe Comment.encode )
        , ( "values", value.values |> Encode.maybe (Encode.nel Encode.string) )
        , ( "columns", value.columns |> Encode.maybe (\(NestedColumns d) -> d |> Ned.values |> Nel.toList |> List.sortBy .index |> Encode.list encode) )
        ]


decode : Decoder (Int -> Column)
decode =
    Decode.map7 (\n t nu d c v cols -> \i -> Column i n t nu d c v cols)
        (Decode.field "name" ColumnName.decode)
        (Decode.field "type" ColumnType.decode)
        (Decode.defaultField "nullable" Decode.bool False)
        (Decode.maybeField "default" ColumnValue.decode)
        (Decode.maybeField "comment" Comment.decode)
        (Decode.maybeField "values" (Decode.nel Decode.string))
        (Decode.maybeField "columns" decodeNestedColumns)


decodeNestedColumns : Decoder NestedColumns
decodeNestedColumns =
    Decode.map NestedColumns
        (Decode.nel (Decode.lazy (\_ -> decode)) |> Decode.map (Nel.indexedMap (\i c -> c i) >> Ned.fromNelMap .name))
