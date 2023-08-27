module PagesComponents.Organization_.Project_.Models.ErdOrigin exposing (ErdOrigin, create, unpack)

import Libs.List as List
import Libs.Models.DatabaseUrl exposing (DatabaseUrl)
import Libs.Models.FileLineIndex exposing (FileLineIndex)
import Models.Project.Origin exposing (Origin)
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId exposing (SourceId)
import Models.Project.SourceKind exposing (SourceKind)
import Models.Project.SourceName exposing (SourceName)


type alias ErdOrigin =
    { id : SourceId, source : Maybe { name : SourceName, kind : SourceKind, db : Maybe DatabaseUrl }, lines : List FileLineIndex }


create : List Source -> Origin -> ErdOrigin
create sources origin =
    sources
        |> List.findBy .id origin.id
        |> Maybe.map
            (\source ->
                { id = origin.id
                , source = Just { name = source.name, kind = source.kind, db = Source.databaseUrl source }
                , lines = origin.lines
                }
            )
        |> Maybe.withDefault { id = origin.id, source = Nothing, lines = origin.lines }


unpack : ErdOrigin -> Origin
unpack origin =
    { id = origin.id, lines = origin.lines }
