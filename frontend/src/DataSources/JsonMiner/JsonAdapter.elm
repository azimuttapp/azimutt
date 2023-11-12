module DataSources.JsonMiner.JsonAdapter exposing (buildSchema, buildSource, unpackSchema)

import Array
import DataSources.Helpers exposing (defaultCheckName, defaultIndexName, defaultUniqueName)
import DataSources.JsonMiner.JsonSchema exposing (JsonSchema)
import DataSources.JsonMiner.Models.JsonRelation exposing (JsonRelation)
import DataSources.JsonMiner.Models.JsonTable exposing (JsonCheck, JsonColumn, JsonIndex, JsonNestedColumns(..), JsonPrimaryKey, JsonTable, JsonUnique)
import DataSources.JsonMiner.Models.JsonType exposing (JsonType, JsonTypeValue(..))
import Dict exposing (Dict)
import Libs.Dict as Dict
import Libs.Maybe as Maybe
import Libs.Ned as Ned
import Libs.Nel as Nel exposing (Nel)
import Models.Project.Check exposing (Check)
import Models.Project.Column exposing (Column, NestedColumns(..))
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath as ColumnPath
import Models.Project.Comment exposing (Comment)
import Models.Project.CustomType exposing (CustomType)
import Models.Project.CustomTypeValue as CustomTypeValue
import Models.Project.Index exposing (Index)
import Models.Project.Origin exposing (Origin)
import Models.Project.PrimaryKey exposing (PrimaryKey)
import Models.Project.Relation as Relation exposing (Relation)
import Models.Project.Schema exposing (Schema)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId exposing (SourceId)
import Models.Project.Table exposing (Table)
import Models.Project.Unique exposing (Unique)
import Models.SourceInfo exposing (SourceInfo)


buildSource : SourceInfo -> JsonSchema -> Source
buildSource source jsonSchema =
    let
        schema : Schema
        schema =
            buildSchema source.id jsonSchema
    in
    { id = source.id
    , name = source.name
    , kind = source.kind
    , content = Array.empty
    , tables = schema.tables
    , relations = schema.relations
    , types = schema.types
    , enabled = source.enabled
    , fromSample = source.fromSample
    , createdAt = source.createdAt
    , updatedAt = source.updatedAt
    }


buildSchema : SourceId -> JsonSchema -> Schema
buildSchema source schema =
    let
        origins : List Origin
        origins =
            [ { id = source } ]
    in
    { tables = schema.tables |> List.map (buildTable origins) |> Dict.fromListMap .id
    , relations = schema.relations |> List.map (buildRelation origins)
    , types = schema.types |> List.map buildType |> Dict.fromListMap .id
    }


unpackSchema : Schema -> JsonSchema
unpackSchema schema =
    { tables = schema.tables |> Dict.values |> List.map unpackTable
    , relations = schema.relations |> List.map unpackRelation
    , types = schema.types |> Dict.values |> List.map unpackType
    }


buildTable : List Origin -> JsonTable -> Table
buildTable origins table =
    { id = ( table.schema, table.table )
    , schema = table.schema
    , name = table.table
    , view = table.view |> Maybe.withDefault False
    , columns = table.columns |> buildColumns origins
    , primaryKey = table.primaryKey |> Maybe.map (buildPrimaryKey origins)
    , uniques = table.uniques |> List.map (buildUnique origins table.table)
    , indexes = table.indexes |> List.map (buildIndex origins table.table)
    , checks = table.checks |> List.map (buildCheck origins table.table)
    , comment = table.comment |> Maybe.map (buildComment origins)
    , origins = origins
    }


unpackTable : Table -> JsonTable
unpackTable table =
    { schema = table.schema
    , table = table.name
    , view = Just table.view |> Maybe.filter (\n -> n /= False)
    , columns = table.columns |> unpackColumns
    , primaryKey = table.primaryKey |> Maybe.map unpackPrimaryKey
    , uniques = table.uniques |> List.map (unpackUnique table.name)
    , indexes = table.indexes |> List.map (unpackIndex table.name)
    , checks = table.checks |> List.map (unpackCheck table.name)
    , comment = table.comment |> Maybe.map unpackComment
    }


buildColumns : List Origin -> List JsonColumn -> Dict ColumnName Column
buildColumns origins columns =
    columns |> List.indexedMap (buildColumn origins) |> Dict.fromListMap .name


unpackColumns : Dict ColumnName Column -> List JsonColumn
unpackColumns columns =
    columns |> Dict.values |> List.sortBy .index |> List.map unpackColumn


buildColumn : List Origin -> Int -> JsonColumn -> Column
buildColumn origins index column =
    { index = index
    , name = column.name
    , kind = column.kind
    , nullable = column.nullable |> Maybe.withDefault False
    , default = column.default
    , comment = column.comment |> Maybe.map (buildComment origins)
    , values = column.values
    , columns = column.columns |> Maybe.map (buildNestedColumns origins)
    , origins = origins
    }


unpackColumn : Column -> JsonColumn
unpackColumn column =
    { name = column.name
    , kind = column.kind
    , nullable = Just column.nullable |> Maybe.filter (\n -> n /= False)
    , default = column.default
    , comment = column.comment |> Maybe.map unpackComment
    , values = column.values
    , columns = column.columns |> Maybe.map unpackNestedColumns
    }


buildNestedColumns : List Origin -> JsonNestedColumns -> NestedColumns
buildNestedColumns origins (JsonNestedColumns columns) =
    columns |> Nel.indexedMap (buildColumn origins) |> Ned.fromNelMap .name |> NestedColumns


unpackNestedColumns : NestedColumns -> JsonNestedColumns
unpackNestedColumns (NestedColumns columns) =
    columns |> Ned.values |> Nel.sortBy .index |> Nel.map unpackColumn |> JsonNestedColumns


buildPrimaryKey : List Origin -> JsonPrimaryKey -> PrimaryKey
buildPrimaryKey origins pk =
    { name = pk.name
    , columns = pk.columns |> Nel.map ColumnPath.fromString
    , origins = origins
    }


unpackPrimaryKey : PrimaryKey -> JsonPrimaryKey
unpackPrimaryKey pk =
    { name = pk.name
    , columns = pk.columns |> Nel.map ColumnPath.toString
    }


buildUnique : List Origin -> String -> JsonUnique -> Unique
buildUnique origins table unique =
    { name = unique.name |> Maybe.withDefault (defaultUniqueName table unique.columns.head)
    , columns = unique.columns |> Nel.map ColumnPath.fromString
    , definition = unique.definition
    , origins = origins
    }


unpackUnique : String -> Unique -> JsonUnique
unpackUnique table unique =
    { name = Just unique.name |> Maybe.filter (\n -> n /= defaultUniqueName table (unique.columns.head |> ColumnPath.toString))
    , columns = unique.columns |> Nel.map ColumnPath.toString
    , definition = unique.definition
    }


buildIndex : List Origin -> String -> JsonIndex -> Index
buildIndex origins table index =
    { name = index.name |> Maybe.withDefault (defaultIndexName table index.columns.head)
    , columns = index.columns |> Nel.map ColumnPath.fromString
    , definition = index.definition
    , origins = origins
    }


unpackIndex : String -> Index -> JsonIndex
unpackIndex table index =
    { name = Just index.name |> Maybe.filter (\n -> n /= defaultIndexName table (index.columns.head |> ColumnPath.toString))
    , columns = index.columns |> Nel.map ColumnPath.toString
    , definition = index.definition
    }


buildCheck : List Origin -> String -> JsonCheck -> Check
buildCheck origins table check =
    { name = check.name |> Maybe.withDefault (defaultCheckName table (check.columns |> List.head |> Maybe.withDefault ""))
    , columns = check.columns |> List.map ColumnPath.fromString
    , predicate = check.predicate
    , origins = origins
    }


unpackCheck : String -> Check -> JsonCheck
unpackCheck table check =
    { name = Just check.name |> Maybe.filter (\n -> n /= defaultCheckName table (check.columns |> List.head |> Maybe.map ColumnPath.toString |> Maybe.withDefault ""))
    , columns = check.columns |> List.map ColumnPath.toString
    , predicate = check.predicate
    }


buildComment : List Origin -> String -> Comment
buildComment origins comment =
    { text = comment
    , origins = origins
    }


unpackComment : Comment -> String
unpackComment comment =
    comment.text


buildRelation : List Origin -> JsonRelation -> Relation
buildRelation origins relation =
    Relation.new relation.name
        { table = ( relation.src.schema, relation.src.table ), column = ColumnPath.fromString relation.src.column }
        { table = ( relation.ref.schema, relation.ref.table ), column = ColumnPath.fromString relation.ref.column }
        origins


unpackRelation : Relation -> JsonRelation
unpackRelation relation =
    { name = relation.name
    , src =
        { schema = relation.src.table |> Tuple.first
        , table = relation.src.table |> Tuple.second
        , column = relation.src.column |> ColumnPath.toString
        }
    , ref =
        { schema = relation.ref.table |> Tuple.first
        , table = relation.ref.table |> Tuple.second
        , column = relation.ref.column |> ColumnPath.toString
        }
    }


buildType : JsonType -> CustomType
buildType t =
    (case t.value of
        JsonTypeEnum values ->
            CustomTypeValue.Enum values

        JsonTypeDefinition definition ->
            CustomTypeValue.Definition definition
    )
        |> (\value -> { id = ( t.schema, t.name ), name = t.name, value = value })


unpackType : CustomType -> JsonType
unpackType t =
    { schema = t.id |> Tuple.first
    , name = t.name
    , value =
        case t.value of
            CustomTypeValue.Enum values ->
                JsonTypeEnum values

            CustomTypeValue.Definition definition ->
                JsonTypeDefinition definition
    }
