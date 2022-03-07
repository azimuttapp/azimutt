module Models.Project.Table exposing (Table, TableLike, clearOrigins, decode, encode, inChecks, inIndexes, inPrimaryKey, inUniques, merge)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Ned as Ned exposing (Ned)
import Libs.Nel as Nel
import Models.Project.Check as Check exposing (Check)
import Models.Project.Column as Column exposing (Column, ColumnLike)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.Comment as Comment exposing (Comment)
import Models.Project.Index as Index exposing (Index)
import Models.Project.Origin as Origin exposing (Origin)
import Models.Project.PrimaryKey as PrimaryKey exposing (PrimaryKey)
import Models.Project.SchemaName as SchemaName exposing (SchemaName)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableName as TableName exposing (TableName)
import Models.Project.Unique as Unique exposing (Unique)
import Services.Lenses exposing (mapChecks, mapColumns, mapCommentM, mapIndexes, mapPrimaryKeyM, mapUniques, setOrigins)


type alias Table =
    { id : TableId
    , schema : SchemaName
    , name : TableName
    , view : Bool
    , columns : Ned ColumnName Column
    , primaryKey : Maybe PrimaryKey
    , uniques : List Unique
    , indexes : List Index
    , checks : List Check
    , comment : Maybe Comment
    , origins : List Origin
    }


type alias TableLike x y =
    { x
        | id : TableId
        , schema : SchemaName
        , name : TableName
        , view : Bool
        , columns : Ned ColumnName (ColumnLike y)
        , primaryKey : Maybe PrimaryKey
        , uniques : List Unique
        , indexes : List Index
        , checks : List Check
        , comment : Maybe Comment
        , origins : List Origin
    }


inPrimaryKey : TableLike x y -> ColumnName -> Maybe PrimaryKey
inPrimaryKey table column =
    table.primaryKey |> Maybe.filter (\{ columns } -> columns |> Nel.toList |> hasColumn column)


inUniques : TableLike x y -> ColumnName -> List Unique
inUniques table column =
    table.uniques |> List.filter (\u -> u.columns |> Nel.toList |> hasColumn column)


inIndexes : TableLike x y -> ColumnName -> List Index
inIndexes table column =
    table.indexes |> List.filter (\i -> i.columns |> Nel.toList |> hasColumn column)


inChecks : TableLike x y -> ColumnName -> List Check
inChecks table column =
    table.checks |> List.filter (\i -> i.columns |> hasColumn column)


hasColumn : ColumnName -> List ColumnName -> Bool
hasColumn column columns =
    columns |> List.any (\c -> c == column)


merge : Table -> Table -> Table
merge t1 t2 =
    { id = t1.id
    , schema = t1.schema
    , name = t1.name
    , view = t1.view
    , columns = Ned.merge Column.merge t1.columns t2.columns
    , primaryKey = Maybe.merge PrimaryKey.merge t1.primaryKey t2.primaryKey
    , uniques = List.merge .name Unique.merge t1.uniques t2.uniques
    , indexes = List.merge .name Index.merge t1.indexes t2.indexes
    , checks = List.merge .name Check.merge t1.checks t2.checks
    , comment = Maybe.merge Comment.merge t1.comment t2.comment
    , origins = t1.origins ++ t2.origins
    }


clearOrigins : Table -> Table
clearOrigins table =
    table
        |> setOrigins []
        |> mapColumns (Ned.map (\_ c -> c |> setOrigins [] |> mapCommentM (setOrigins [])))
        |> mapPrimaryKeyM (setOrigins [])
        |> mapUniques (List.map (setOrigins []))
        |> mapIndexes (List.map (setOrigins []))
        |> mapChecks (List.map (setOrigins []))
        |> mapCommentM (setOrigins [])


encode : Table -> Value
encode value =
    Encode.notNullObject
        [ ( "schema", value.schema |> SchemaName.encode )
        , ( "table", value.name |> TableName.encode )
        , ( "view", value.view |> Encode.withDefault Encode.bool False )
        , ( "columns", value.columns |> Ned.values |> Nel.sortBy .index |> Encode.nel Column.encode )
        , ( "primaryKey", value.primaryKey |> Encode.maybe PrimaryKey.encode )
        , ( "uniques", value.uniques |> Encode.withDefault (Encode.list Unique.encode) [] )
        , ( "indexes", value.indexes |> Encode.withDefault (Encode.list Index.encode) [] )
        , ( "checks", value.checks |> Encode.withDefault (Encode.list Check.encode) [] )
        , ( "comment", value.comment |> Encode.maybe Comment.encode )
        , ( "origins", value.origins |> Encode.withDefault (Encode.list Origin.encode) [] )
        ]


decode : Decode.Decoder Table
decode =
    Decode.map10 (\s t v c p u i ch co so -> Table ( s, t ) s t v c p u i ch co so)
        (Decode.field "schema" SchemaName.decode)
        (Decode.field "table" TableName.decode)
        (Decode.defaultField "view" Decode.bool False)
        (Decode.field "columns" (Decode.nel Column.decode |> Decode.map (Nel.indexedMap (\i c -> c i) >> Ned.fromNelMap .name)))
        (Decode.maybeField "primaryKey" PrimaryKey.decode)
        (Decode.defaultField "uniques" (Decode.list Unique.decode) [])
        (Decode.defaultField "indexes" (Decode.list Index.decode) [])
        (Decode.defaultField "checks" (Decode.list Check.decode) [])
        (Decode.maybeField "comment" Comment.decode)
        (Decode.defaultField "origins" (Decode.list Origin.decode) [])
