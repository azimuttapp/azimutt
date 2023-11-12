module PagesComponents.Organization_.Project_.Models.ErdUnique exposing (ErdUnique, create, unpack)

import Libs.Nel exposing (Nel)
import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.Unique exposing (Unique)
import Models.Project.UniqueName exposing (UniqueName)
import PagesComponents.Organization_.Project_.Models.Erd.TableWithOrigin exposing (UniqueWithOrigin)
import PagesComponents.Organization_.Project_.Models.ErdOrigin exposing (ErdOrigin)


type alias ErdUnique =
    { name : UniqueName
    , columns : Nel ColumnPath
    , definition : Maybe String
    , origins : List ErdOrigin
    }


create : UniqueWithOrigin -> ErdUnique
create unique =
    { name = unique.name
    , columns = unique.columns
    , definition = unique.definition
    , origins = unique.origins
    }


unpack : ErdUnique -> Unique
unpack unique =
    { name = unique.name
    , columns = unique.columns
    , definition = unique.definition
    }
