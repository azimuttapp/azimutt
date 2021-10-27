module Models.Project.Table exposing (Table, decode, encode, inChecks, inIndexes, inPrimaryKey, inUniques)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as D
import Libs.Json.Encode as E
import Libs.Maybe as M
import Libs.Ned as Ned exposing (Ned)
import Libs.Nel as Nel
import Models.Project.Check as Check exposing (Check)
import Models.Project.Column as Column exposing (Column)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.Comment as Comment exposing (Comment)
import Models.Project.Index as Index exposing (Index)
import Models.Project.Origin as Origin exposing (Origin)
import Models.Project.PrimaryKey as PrimaryKey exposing (PrimaryKey)
import Models.Project.SchemaName as SchemaName exposing (SchemaName)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableName as TableName exposing (TableName)
import Models.Project.Unique as Unique exposing (Unique)


type alias Table =
    { id : TableId
    , schema : SchemaName
    , name : TableName
    , columns : Ned ColumnName Column
    , primaryKey : Maybe PrimaryKey
    , uniques : List Unique
    , indexes : List Index
    , checks : List Check
    , comment : Maybe Comment
    , origins : List Origin
    }


inPrimaryKey : Table -> ColumnName -> Maybe PrimaryKey
inPrimaryKey table column =
    table.primaryKey |> M.filter (\{ columns } -> columns |> Nel.toList |> hasColumn column)


inUniques : Table -> ColumnName -> List Unique
inUniques table column =
    table.uniques |> List.filter (\u -> u.columns |> Nel.toList |> hasColumn column)


inIndexes : Table -> ColumnName -> List Index
inIndexes table column =
    table.indexes |> List.filter (\i -> i.columns |> Nel.toList |> hasColumn column)


inChecks : Table -> ColumnName -> List Check
inChecks table column =
    table.checks |> List.filter (\i -> i.columns |> hasColumn column)


hasColumn : ColumnName -> List ColumnName -> Bool
hasColumn column columns =
    columns |> List.any (\c -> c == column)


encode : Table -> Value
encode value =
    E.object
        [ ( "schema", value.schema |> SchemaName.encode )
        , ( "table", value.name |> TableName.encode )
        , ( "columns", value.columns |> Ned.values |> Nel.sortBy .index |> E.nel Column.encode )
        , ( "primaryKey", value.primaryKey |> E.maybe PrimaryKey.encode )
        , ( "uniques", value.uniques |> E.withDefault (Encode.list Unique.encode) [] )
        , ( "indexes", value.indexes |> E.withDefault (Encode.list Index.encode) [] )
        , ( "checks", value.checks |> E.withDefault (Encode.list Check.encode) [] )
        , ( "comment", value.comment |> E.maybe Comment.encode )
        , ( "origins", value.origins |> E.withDefault (Encode.list Origin.encode) [] )
        ]


decode : Decode.Decoder Table
decode =
    D.map9 (\s t c p u i ch co so -> Table ( s, t ) s t c p u i ch co so)
        (Decode.field "schema" SchemaName.decode)
        (Decode.field "table" TableName.decode)
        (Decode.field "columns" (D.nel Column.decode |> Decode.map (Nel.indexedMap (\i c -> c i) >> Ned.fromNelMap .name)))
        (D.maybeField "primaryKey" PrimaryKey.decode)
        (D.defaultField "uniques" (Decode.list Unique.decode) [])
        (D.defaultField "indexes" (Decode.list Index.decode) [])
        (D.defaultField "checks" (Decode.list Check.decode) [])
        (D.maybeField "comment" Comment.decode)
        (D.defaultField "origins" (Decode.list Origin.decode) [])
