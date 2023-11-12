module PagesComponents.Organization_.Project_.Models.ErdOrigin exposing (ErdOrigin, create, unpack)

import Libs.List as List
import Libs.Models.DatabaseUrl exposing (DatabaseUrl)
import Models.Project.Origin exposing (Origin)
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId exposing (SourceId)
import Models.Project.SourceKind exposing (SourceKind)
import Models.Project.SourceName exposing (SourceName)


type alias ErdOrigin =
    { id : SourceId, source : Maybe { name : SourceName, kind : SourceKind, db : Maybe DatabaseUrl } }


create : List Source -> Origin -> ErdOrigin
create sources origin =
    sources
        |> List.findBy .id origin.id
        |> Maybe.map
            (\source ->
                { id = origin.id
                , source = Just { name = source.name, kind = source.kind, db = Source.databaseUrl source }
                }
            )
        |> Maybe.withDefault { id = origin.id, source = Nothing }


unpack : ErdOrigin -> Origin
unpack origin =
    { id = origin.id }
