module Models.Project.Source exposing (Source, addRelations, aml, databaseUrl, decode, encode, getColumn, getTable, refreshWith, toInfo)

import Array exposing (Array)
import Conf
import DataSources.AmlMiner.AmlGenerator as AmlGenerator
import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Dict as Dict
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.List as List
import Libs.Models.DatabaseUrl exposing (DatabaseUrl)
import Libs.Time as Time
import Models.Project.Column exposing (Column)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.CustomType as CustomType exposing (CustomType)
import Models.Project.CustomTypeId exposing (CustomTypeId)
import Models.Project.Relation as Relation exposing (Relation)
import Models.Project.SampleKey as SampleKey exposing (SampleKey)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Project.SourceKind as SourceKind exposing (SourceKind(..))
import Models.Project.SourceLine as SourceLine exposing (SourceLine)
import Models.Project.SourceName as SourceName exposing (SourceName)
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Models.SourceInfo exposing (SourceInfo)
import Services.Lenses exposing (mapContent, mapRelations, setUpdatedAt)
import Time


type alias Source =
    { id : SourceId
    , name : SourceName
    , kind : SourceKind
    , content : Array SourceLine
    , tables : Dict TableId Table
    , relations : List Relation
    , types : Dict CustomTypeId CustomType
    , enabled : Bool
    , fromSample : Maybe SampleKey
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


aml : SourceName -> Time.Posix -> SourceId -> Source
aml name now id =
    { id = id
    , name = name
    , kind = AmlEditor
    , content = Array.empty
    , tables = Dict.empty
    , relations = []
    , types = Dict.empty
    , enabled = True
    , fromSample = Nothing
    , createdAt = now
    , updatedAt = now
    }


toInfo : Source -> SourceInfo
toInfo source =
    { id = source.id
    , name = source.name
    , kind = source.kind
    , enabled = source.enabled
    , fromSample = source.fromSample
    , createdAt = source.createdAt
    , updatedAt = source.updatedAt
    }


databaseUrl : Source -> Maybe DatabaseUrl
databaseUrl source =
    SourceKind.databaseUrl source.kind


getTable : TableId -> Source -> Maybe Table
getTable table source =
    source.tables |> Dict.get table


getColumn : ColumnRef -> Source -> Maybe Column
getColumn column source =
    source |> getTable column.table |> Maybe.andThen (Table.getColumn column.column)


refreshWith : Source -> Source -> Source
refreshWith new current =
    if (new.id == current.id) && (new.kind |> SourceKind.same current.kind) then
        { current | kind = new.kind, content = new.content, tables = new.tables, relations = new.relations, types = new.types, updatedAt = new.updatedAt }

    else
        current


addRelations : Time.Posix -> List { src : ColumnRef, ref : ColumnRef } -> Source -> Source
addRelations now rels source =
    source
        |> mapContent (Array.append (Array.fromList (rels |> List.map (\r -> AmlGenerator.relation r.src r.ref))))
        |> mapRelations (\rs -> rs ++ (rels |> List.map (\r -> Relation.virtual r.src r.ref)))
        |> setUpdatedAt now


encode : Source -> Value
encode value =
    Encode.notNullObject
        [ ( "id", value.id |> SourceId.encode )
        , ( "name", value.name |> SourceName.encode )
        , ( "kind", value.kind |> SourceKind.encode )
        , ( "content", value.content |> Encode.array SourceLine.encode )
        , ( "tables", value.tables |> Dict.values |> Encode.list Table.encode )
        , ( "relations", value.relations |> Encode.list Relation.encode )
        , ( "types", value.types |> Dict.values |> Encode.withDefault (Encode.list CustomType.encode) [] )
        , ( "enabled", value.enabled |> Encode.withDefault Encode.bool True )
        , ( "fromSample", value.fromSample |> Encode.maybe SampleKey.encode )
        , ( "createdAt", value.createdAt |> Time.encode )
        , ( "updatedAt", value.updatedAt |> Time.encode )
        ]


decode : Decode.Decoder Source
decode =
    Decode.map11 decodeSource
        (Decode.field "id" SourceId.decode)
        (Decode.field "name" SourceName.decode)
        (Decode.field "kind" SourceKind.decode)
        (Decode.field "content" (Decode.array SourceLine.decode))
        (Decode.field "tables" (Decode.list Table.decode) |> Decode.map (Dict.fromListMap .id))
        (Decode.field "relations" (Decode.list Relation.decode))
        (Decode.defaultField "types" (Decode.list CustomType.decode |> Decode.map (Dict.fromListMap .id)) Dict.empty)
        (Decode.defaultField "enabled" Decode.bool True)
        (Decode.maybeField "fromSample" SampleKey.decode)
        (Decode.field "createdAt" Time.decode)
        (Decode.field "updatedAt" Time.decode)


decodeSource : SourceId -> SourceName -> SourceKind -> Array SourceLine -> Dict TableId Table -> List Relation -> Dict CustomTypeId CustomType -> Bool -> Maybe SampleKey -> Time.Posix -> Time.Posix -> Source
decodeSource id name kind content tables relations types enabled fromSample createdAt updatedAt =
    let
        ( n, c ) =
            if kind == AmlEditor && Array.isEmpty content && Dict.isEmpty tables && List.nonEmpty relations then
                -- migration from previous: no content, only relations and bad name for virtual relations
                ( Conf.constants.virtualRelationSourceName
                , Array.fromList (relations |> List.map (\r -> AmlGenerator.relation r.src r.ref))
                )

            else
                ( name, content )
    in
    { id = id
    , name = n
    , kind = kind
    , content = c
    , tables = tables
    , relations = relations
    , types = types
    , enabled = enabled
    , fromSample = fromSample
    , createdAt = createdAt
    , updatedAt = updatedAt
    }
