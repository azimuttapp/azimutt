module Models.Project.Source exposing (Source, decode, encode, refreshWith, user)

import Array exposing (Array)
import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Dict as D
import Libs.Json.Decode as D
import Libs.Json.Encode as E
import Libs.Time as Time
import Models.Project.Relation as Relation exposing (Relation)
import Models.Project.SampleName as SampleName exposing (SampleKey)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Project.SourceKind as SourceKind exposing (SourceKind(..))
import Models.Project.SourceLine as SourceLine exposing (SourceLine)
import Models.Project.SourceName as SourceName exposing (SourceName)
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Time


type alias Source =
    { id : SourceId
    , name : SourceName
    , kind : SourceKind
    , content : Array SourceLine
    , tables : Dict TableId Table
    , relations : List Relation
    , enabled : Bool
    , fromSample : Maybe SampleKey
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


user : SourceId -> Dict TableId Table -> List Relation -> Time.Posix -> Source
user id tables relations now =
    { id = id
    , name = "User"
    , kind = UserDefined
    , content = Array.empty
    , tables = tables
    , relations = relations
    , enabled = True
    , fromSample = Nothing
    , createdAt = now
    , updatedAt = now
    }


refreshWith : Source -> Source -> Source
refreshWith new current =
    if (new.id == current.id) && (new.kind |> SourceKind.same current.kind) then
        { current | kind = new.kind, content = new.content, tables = new.tables, relations = new.relations, updatedAt = new.updatedAt }

    else
        current


encode : Source -> Value
encode value =
    E.object
        [ ( "id", value.id |> SourceId.encode )
        , ( "name", value.name |> SourceName.encode )
        , ( "kind", value.kind |> SourceKind.encode )
        , ( "content", value.content |> Encode.array SourceLine.encode )
        , ( "tables", value.tables |> Dict.values |> Encode.list Table.encode )
        , ( "relations", value.relations |> Encode.list Relation.encode )
        , ( "enabled", value.enabled |> E.withDefault Encode.bool True )
        , ( "fromSample", value.fromSample |> E.maybe SampleName.encode )
        , ( "createdAt", value.createdAt |> Time.encode )
        , ( "updatedAt", value.updatedAt |> Time.encode )
        ]


decode : Decode.Decoder Source
decode =
    D.map10 Source
        (Decode.field "id" SourceId.decode)
        (Decode.field "name" SourceName.decode)
        (Decode.field "kind" SourceKind.decode)
        (Decode.field "content" (Decode.array SourceLine.decode))
        (Decode.field "tables" (Decode.list Table.decode) |> Decode.map (D.fromListMap .id))
        (Decode.field "relations" (Decode.list Relation.decode))
        (D.defaultField "enabled" Decode.bool True)
        (D.maybeField "fromSample" SampleName.decode)
        (Decode.field "createdAt" Time.decode)
        (Decode.field "updatedAt" Time.decode)
