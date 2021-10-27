module Models.Project.Source exposing (Source)

import Array exposing (Array)
import Dict exposing (Dict)
import Models.Project.Relation exposing (Relation)
import Models.Project.SampleName exposing (SampleName)
import Models.Project.SourceId exposing (SourceId)
import Models.Project.SourceKind exposing (SourceKind)
import Models.Project.SourceLine exposing (SourceLine)
import Models.Project.SourceName exposing (SourceName)
import Models.Project.Table exposing (Table)
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
    , fromSample : Maybe SampleName
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }
