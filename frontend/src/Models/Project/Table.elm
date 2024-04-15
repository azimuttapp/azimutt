module Models.Project.Table exposing (Table, TableLike, decode, encode, findColumn, getAltColumns, getColumn, getPeerColumns, new)

import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Dict as Dict
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Nel as Nel
import Models.Project.Check as Check exposing (Check)
import Models.Project.Column as Column exposing (Column, ColumnLike)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.Comment as Comment exposing (Comment)
import Models.Project.Index as Index exposing (Index)
import Models.Project.PrimaryKey as PrimaryKey exposing (PrimaryKey)
import Models.Project.SchemaName as SchemaName exposing (SchemaName)
import Models.Project.TableDbStats as TableDbStats exposing (TableDbStats)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableName as TableName exposing (TableName)
import Models.Project.Unique as Unique exposing (Unique)


type alias Table =
    { id : TableId
    , schema : SchemaName
    , name : TableName
    , view : Bool
    , definition : Maybe String
    , columns : Dict ColumnName Column
    , primaryKey : Maybe PrimaryKey
    , uniques : List Unique
    , indexes : List Index
    , checks : List Check
    , comment : Maybe Comment
    , stats : Maybe TableDbStats
    }


type alias TableLike x y =
    { x
        | id : TableId
        , schema : SchemaName
        , name : TableName
        , view : Bool
        , definition : Maybe String
        , columns : Dict ColumnName (ColumnLike y)
        , primaryKey : Maybe PrimaryKey
        , uniques : List Unique
        , indexes : List Index
        , checks : List Check
        , comment : Maybe Comment
        , stats : Maybe TableDbStats
    }


new : SchemaName -> TableName -> Bool -> Maybe String -> Dict ColumnName Column -> Maybe PrimaryKey -> List Unique -> List Index -> List Check -> Maybe Comment -> Maybe TableDbStats -> Table
new schema name view definition columns primaryKey uniques indexes checks comment stats =
    Table ( schema, name ) schema name view definition columns primaryKey uniques indexes checks comment stats


getColumn : ColumnPath -> Table -> Maybe Column
getColumn path table =
    table.columns
        |> Dict.get path.head
        |> Maybe.andThen (\col -> path.tail |> Nel.fromList |> Maybe.mapOrElse (\next -> Column.getColumn next col) (Just col))


getPeerColumns : ColumnPath -> Table -> List Column
getPeerColumns path table =
    (path |> ColumnPath.parent)
        |> Maybe.map (\p -> table |> getColumn p |> Maybe.mapOrElse Column.nestedColumns [])
        |> Maybe.withDefault (table.columns |> Dict.values)


getAltColumns : Table -> List ( ColumnPath, ColumnType )
getAltColumns table =
    -- guess interesting columns to show instead of primary key in table row relations (can be empty)
    [ [ "name" ]
    , [ "title" ]
    , [ "slug" ]
    , [ "first_name", "last_name" ]
    ]
        |> List.findMap (List.map (\name -> table.columns |> Dict.get name) >> List.maybeSeq)
        |> Maybe.orElse (table.columns |> Dict.values |> List.find (\col -> col.name |> String.endsWith "name") |> Maybe.map (\col -> [ col ]))
        |> Maybe.withDefault []
        |> List.map (\c -> ( ColumnPath.root c.name, c.kind ))


findColumn : (ColumnPath -> Column -> Bool) -> Table -> Maybe ( ColumnPath, Column )
findColumn predicate table =
    table.columns
        |> Dict.toList
        |> List.findMap (\( _, col ) -> Column.findColumn predicate col)


encode : Table -> Value
encode value =
    Encode.notNullObject
        [ ( "schema", value.schema |> SchemaName.encode )
        , ( "table", value.name |> TableName.encode )
        , ( "view", value.view |> Encode.withDefault Encode.bool False )
        , ( "definition", value.definition |> Encode.maybe Encode.string )
        , ( "columns", value.columns |> Dict.values |> List.sortBy .index |> Encode.list Column.encode )
        , ( "primaryKey", value.primaryKey |> Encode.maybe PrimaryKey.encode )
        , ( "uniques", value.uniques |> Encode.withDefault (Encode.list Unique.encode) [] )
        , ( "indexes", value.indexes |> Encode.withDefault (Encode.list Index.encode) [] )
        , ( "checks", value.checks |> Encode.withDefault (Encode.list Check.encode) [] )
        , ( "comment", value.comment |> Encode.maybe Comment.encode )
        , ( "stats", value.stats |> Encode.maybe TableDbStats.encode )
        ]


decode : Decode.Decoder Table
decode =
    Decode.map11 new
        (Decode.field "schema" SchemaName.decode)
        (Decode.field "table" TableName.decode)
        (Decode.defaultField "view" Decode.bool False)
        (Decode.maybeField "definition" Decode.string)
        (Decode.field "columns" (Decode.list Column.decode |> Decode.map (List.indexedMap (\i c -> c i) >> Dict.fromListMap .name)))
        (Decode.maybeField "primaryKey" PrimaryKey.decode)
        (Decode.defaultField "uniques" (Decode.list Unique.decode) [])
        (Decode.defaultField "indexes" (Decode.list Index.decode) [])
        (Decode.defaultField "checks" (Decode.list Check.decode) [])
        (Decode.maybeField "comment" Comment.decode)
        (Decode.maybeField "stats" TableDbStats.decode)
