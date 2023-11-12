module Models.Project.Table exposing (Table, TableLike, decode, encode, getColumn, new)

import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Dict as Dict
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Maybe as Maybe
import Libs.Nel as Nel
import Models.Project.Check as Check exposing (Check)
import Models.Project.Column as Column exposing (Column, ColumnLike)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.Comment as Comment exposing (Comment)
import Models.Project.Index as Index exposing (Index)
import Models.Project.PrimaryKey as PrimaryKey exposing (PrimaryKey)
import Models.Project.SchemaName as SchemaName exposing (SchemaName)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableName as TableName exposing (TableName)
import Models.Project.Unique as Unique exposing (Unique)


type alias Table =
    { id : TableId
    , schema : SchemaName
    , name : TableName
    , view : Bool
    , columns : Dict ColumnName Column
    , primaryKey : Maybe PrimaryKey
    , uniques : List Unique
    , indexes : List Index
    , checks : List Check
    , comment : Maybe Comment
    }


type alias TableLike x y =
    { x
        | id : TableId
        , schema : SchemaName
        , name : TableName
        , view : Bool
        , columns : Dict ColumnName (ColumnLike y)
        , primaryKey : Maybe PrimaryKey
        , uniques : List Unique
        , indexes : List Index
        , checks : List Check
        , comment : Maybe Comment
    }


new : SchemaName -> TableName -> Bool -> Dict ColumnName Column -> Maybe PrimaryKey -> List Unique -> List Index -> List Check -> Maybe Comment -> Table
new schema name view columns primaryKey uniques indexes checks comment =
    Table ( schema, name ) schema name view columns primaryKey uniques indexes checks comment


getColumn : ColumnPath -> Table -> Maybe Column
getColumn path table =
    table.columns
        |> Dict.get path.head
        |> Maybe.andThen (\col -> path.tail |> Nel.fromList |> Maybe.mapOrElse (\next -> Column.getColumn next col) (Just col))


encode : Table -> Value
encode value =
    Encode.notNullObject
        [ ( "schema", value.schema |> SchemaName.encode )
        , ( "table", value.name |> TableName.encode )
        , ( "view", value.view |> Encode.withDefault Encode.bool False )
        , ( "columns", value.columns |> Dict.values |> List.sortBy .index |> Encode.list Column.encode )
        , ( "primaryKey", value.primaryKey |> Encode.maybe PrimaryKey.encode )
        , ( "uniques", value.uniques |> Encode.withDefault (Encode.list Unique.encode) [] )
        , ( "indexes", value.indexes |> Encode.withDefault (Encode.list Index.encode) [] )
        , ( "checks", value.checks |> Encode.withDefault (Encode.list Check.encode) [] )
        , ( "comment", value.comment |> Encode.maybe Comment.encode )
        ]


decode : Decode.Decoder Table
decode =
    Decode.map9 new
        (Decode.field "schema" SchemaName.decode)
        (Decode.field "table" TableName.decode)
        (Decode.defaultField "view" Decode.bool False)
        (Decode.field "columns" (Decode.list Column.decode |> Decode.map (List.indexedMap (\i c -> c i) >> Dict.fromListMap .name)))
        (Decode.maybeField "primaryKey" PrimaryKey.decode)
        (Decode.defaultField "uniques" (Decode.list Unique.decode) [])
        (Decode.defaultField "indexes" (Decode.list Index.decode) [])
        (Decode.defaultField "checks" (Decode.list Check.decode) [])
        (Decode.maybeField "comment" Comment.decode)
