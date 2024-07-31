module PagesComponents.Organization_.Project_.Models.ErdOrigin exposing (ErdOrigin, create, query)

import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.DatabaseUrl exposing (DatabaseUrl)
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId exposing (SourceId)
import Models.Project.SourceKind as SourceKind exposing (SourceKind)
import Models.Project.SourceName exposing (SourceName)


type alias ErdOrigin =
    { id : SourceId
    , name : SourceName
    , kind : SourceKind
    , db : Maybe DatabaseUrl
    }


create : Source -> ErdOrigin
create source =
    { id = source.id
    , name = source.name
    , kind = source.kind
    , db = Source.databaseUrl source
    }


query : SourceId -> List ErdOrigin -> SourceId
query id origins =
    -- choose the source to query, first the initial one, or the first one with an url, or the first one with the database kind
    (origins |> List.findBy .id id)
        |> Maybe.orElse (origins |> List.find (\o -> o.db /= Nothing))
        |> Maybe.orElse (origins |> List.find (\o -> SourceKind.isDatabase o.kind))
        |> Maybe.mapOrElse .id id
