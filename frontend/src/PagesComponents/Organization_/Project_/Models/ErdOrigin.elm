module PagesComponents.Organization_.Project_.Models.ErdOrigin exposing (ErdOrigin, create)

import Libs.Models.DatabaseUrl exposing (DatabaseUrl)
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId exposing (SourceId)
import Models.Project.SourceKind exposing (SourceKind)
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
