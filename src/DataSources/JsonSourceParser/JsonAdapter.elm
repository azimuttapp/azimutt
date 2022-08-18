module DataSources.JsonSourceParser.JsonAdapter exposing (buildSource)

import Array
import DataSources.Helpers exposing (defaultCheckName, defaultIndexName, defaultUniqueName)
import DataSources.JsonSourceParser.JsonSchema exposing (JsonSchema)
import DataSources.JsonSourceParser.Models.JsonRelation exposing (JsonRelation)
import DataSources.JsonSourceParser.Models.JsonTable exposing (JsonCheck, JsonColumn, JsonIndex, JsonPrimaryKey, JsonTable, JsonUnique)
import DataSources.JsonSourceParser.Models.JsonType exposing (JsonType, JsonTypeValue(..))
import Dict exposing (Dict)
import Libs.Dict as Dict
import Models.Project.Check exposing (Check)
import Models.Project.Column exposing (Column)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.Comment exposing (Comment)
import Models.Project.CustomType exposing (CustomType)
import Models.Project.CustomTypeValue as CustomTypeValue
import Models.Project.Index exposing (Index)
import Models.Project.Origin exposing (Origin)
import Models.Project.PrimaryKey exposing (PrimaryKey)
import Models.Project.Relation as Relation exposing (Relation)
import Models.Project.Source exposing (Source)
import Models.Project.Table exposing (Table)
import Models.Project.Unique exposing (Unique)
import Models.SourceInfo exposing (SourceInfo)


buildSource : SourceInfo -> JsonSchema -> Source
buildSource source schema =
    let
        origins : List Origin
        origins =
            [ { id = source.id, lines = [] } ]
    in
    { id = source.id
    , name = source.name
    , kind = source.kind
    , content = Array.empty
    , tables = schema.tables |> List.map (buildTable origins) |> Dict.fromListMap .id
    , relations = schema.relations |> List.map (buildRelation origins)
    , types = schema.types |> List.map (buildType origins) |> Dict.fromListMap .id
    , enabled = source.enabled
    , fromSample = source.fromSample
    , createdAt = source.createdAt
    , updatedAt = source.updatedAt
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


buildColumns : List Origin -> List JsonColumn -> Dict ColumnName Column
buildColumns origins columns =
    columns |> List.indexedMap (buildColumn origins) |> Dict.fromListMap .name


buildColumn : List Origin -> Int -> JsonColumn -> Column
buildColumn origins index column =
    { index = index
    , name = column.name
    , kind = column.kind
    , nullable = column.nullable |> Maybe.withDefault True
    , default = column.default
    , comment = column.comment |> Maybe.map (buildComment origins)
    , origins = origins
    }


buildPrimaryKey : List Origin -> JsonPrimaryKey -> PrimaryKey
buildPrimaryKey origins pk =
    { name = pk.name
    , columns = pk.columns
    , origins = origins
    }


buildUnique : List Origin -> String -> JsonUnique -> Unique
buildUnique origins table unique =
    { name = unique.name |> Maybe.withDefault (defaultUniqueName table unique.columns.head)
    , columns = unique.columns
    , definition = unique.definition
    , origins = origins
    }


buildIndex : List Origin -> String -> JsonIndex -> Index
buildIndex origins table index =
    { name = index.name |> Maybe.withDefault (defaultIndexName table index.columns.head)
    , columns = index.columns
    , definition = index.definition
    , origins = origins
    }


buildCheck : List Origin -> String -> JsonCheck -> Check
buildCheck origins table check =
    { name = check.name |> Maybe.withDefault (defaultCheckName table (check.columns |> List.head |> Maybe.withDefault ""))
    , columns = check.columns
    , predicate = check.predicate
    , origins = origins
    }


buildComment : List Origin -> String -> Comment
buildComment origins comment =
    { text = comment
    , origins = origins
    }


buildRelation : List Origin -> JsonRelation -> Relation
buildRelation origins relation =
    Relation.new relation.name
        { table = ( relation.src.schema, relation.src.table ), column = relation.src.column }
        { table = ( relation.ref.schema, relation.ref.table ), column = relation.ref.column }
        origins


buildType : List Origin -> JsonType -> CustomType
buildType origins t =
    (case t.value of
        JsonTypeEnum values ->
            CustomTypeValue.Enum values

        JsonTypeDefinition definition ->
            CustomTypeValue.Definition definition
    )
        |> (\value -> { id = ( t.schema, t.name ), name = t.name, value = value, origins = origins })
