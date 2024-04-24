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
import Models.Project.PrimaryKey exposing (PrimaryKey)
import Models.Project.Relation as Relation exposing (Relation)
import Models.Project.Schema exposing (Schema)
import Models.Project.Source exposing (Source)
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId
import Models.Project.Unique exposing (Unique)
import Models.SourceInfo exposing (SourceInfo)


buildSource : SourceInfo -> JsonSchema -> Source
buildSource source jsonSchema =
    let
        schema : Schema
        schema =
            buildSchema jsonSchema
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


buildSchema : JsonSchema -> Schema
buildSchema schema =
    { tables = schema.tables |> List.map buildTable |> Dict.fromListMap .id
    , relations = schema.relations |> List.map buildRelation
    , types = schema.types |> List.map buildType |> Dict.fromListMap .id
    }


unpackSchema : Schema -> JsonSchema
unpackSchema schema =
    { tables = schema.tables |> Dict.values |> List.map unpackTable
    , relations = schema.relations |> List.map unpackRelation
    , types = schema.types |> Dict.values |> List.map unpackType
    }


buildTable : JsonTable -> Table
buildTable table =
    { id = ( table.schema, table.table )
    , schema = table.schema
    , name = table.table
    , view = table.view |> Maybe.withDefault False
    , definition = table.definition
    , columns = table.columns |> buildColumns
    , primaryKey = table.primaryKey |> Maybe.map buildPrimaryKey
    , uniques = table.uniques |> List.map (buildUnique table.table)
    , indexes = table.indexes |> List.map (buildIndex table.table)
    , checks = table.checks |> List.map (buildCheck table.table)
    , comment = table.comment |> Maybe.map buildComment
    , stats = table.stats
    }


unpackTable : Table -> JsonTable
unpackTable table =
    { schema = table.schema
    , table = table.name
    , view = Just table.view |> Maybe.filter (\n -> n /= False)
    , definition = table.definition
    , columns = table.columns |> unpackColumns
    , primaryKey = table.primaryKey |> Maybe.map unpackPrimaryKey
    , uniques = table.uniques |> List.map (unpackUnique table.name)
    , indexes = table.indexes |> List.map (unpackIndex table.name)
    , checks = table.checks |> List.map (unpackCheck table.name)
    , comment = table.comment |> Maybe.map unpackComment
    , stats = table.stats
    }


buildColumns : List JsonColumn -> Dict ColumnName Column
buildColumns columns =
    columns |> List.indexedMap buildColumn |> Dict.fromListMap .name


unpackColumns : Dict ColumnName Column -> List JsonColumn
unpackColumns columns =
    columns |> Dict.values |> List.sortBy .index |> List.map unpackColumn


buildColumn : Int -> JsonColumn -> Column
buildColumn index column =
    { index = index
    , name = column.name
    , kind = column.kind
    , nullable = column.nullable |> Maybe.withDefault False
    , default = column.default
    , comment = column.comment |> Maybe.map buildComment
    , values = column.values
    , columns = column.columns |> Maybe.map buildNestedColumns
    , stats = column.stats
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
    , stats = column.stats
    }


buildNestedColumns : JsonNestedColumns -> NestedColumns
buildNestedColumns (JsonNestedColumns columns) =
    columns |> Nel.indexedMap buildColumn |> Ned.fromNelMap .name |> NestedColumns


unpackNestedColumns : NestedColumns -> JsonNestedColumns
unpackNestedColumns (NestedColumns columns) =
    columns |> Ned.values |> Nel.sortBy .index |> Nel.map unpackColumn |> JsonNestedColumns


buildPrimaryKey : JsonPrimaryKey -> PrimaryKey
buildPrimaryKey pk =
    { name = pk.name
    , columns = pk.columns |> Nel.map ColumnPath.fromString
    }


unpackPrimaryKey : PrimaryKey -> JsonPrimaryKey
unpackPrimaryKey pk =
    { name = pk.name
    , columns = pk.columns |> Nel.map ColumnPath.toString
    }


buildUnique : String -> JsonUnique -> Unique
buildUnique table unique =
    { name = unique.name |> Maybe.withDefault (defaultUniqueName table unique.columns.head)
    , columns = unique.columns |> Nel.map ColumnPath.fromString
    , definition = unique.definition
    }


unpackUnique : String -> Unique -> JsonUnique
unpackUnique table unique =
    { name = Just unique.name |> Maybe.filter (\n -> n /= defaultUniqueName table (unique.columns.head |> ColumnPath.toString))
    , columns = unique.columns |> Nel.map ColumnPath.toString
    , definition = unique.definition
    }


buildIndex : String -> JsonIndex -> Index
buildIndex table index =
    { name = index.name |> Maybe.withDefault (defaultIndexName table index.columns.head)
    , columns = index.columns |> Nel.map ColumnPath.fromString
    , definition = index.definition
    }


unpackIndex : String -> Index -> JsonIndex
unpackIndex table index =
    { name = Just index.name |> Maybe.filter (\n -> n /= defaultIndexName table (index.columns.head |> ColumnPath.toString))
    , columns = index.columns |> Nel.map ColumnPath.toString
    , definition = index.definition
    }


buildCheck : String -> JsonCheck -> Check
buildCheck table check =
    { name = check.name |> Maybe.withDefault (defaultCheckName table (check.columns |> List.head |> Maybe.withDefault ""))
    , columns = check.columns |> List.map ColumnPath.fromString
    , predicate = check.predicate
    }


unpackCheck : String -> Check -> JsonCheck
unpackCheck table check =
    { name = Just check.name |> Maybe.filter (\n -> n /= defaultCheckName table (check.columns |> List.head |> Maybe.map ColumnPath.toString |> Maybe.withDefault ""))
    , columns = check.columns |> List.map ColumnPath.toString
    , predicate = check.predicate
    }


buildComment : String -> Comment
buildComment comment =
    { text = comment
    }


unpackComment : Comment -> String
unpackComment comment =
    comment.text


buildRelation : JsonRelation -> Relation
buildRelation relation =
    Relation.new relation.name
        { table = relation.src.table |> TableId.parse, column = ColumnPath.fromString relation.src.column }
        { table = relation.ref.table |> TableId.parse, column = ColumnPath.fromString relation.ref.column }


unpackRelation : Relation -> JsonRelation
unpackRelation relation =
    { name = relation.name
    , src =
        { table = relation.src.table |> TableId.toString
        , column = relation.src.column |> ColumnPath.toString
        }
    , ref =
        { table = relation.ref.table |> TableId.toString
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
