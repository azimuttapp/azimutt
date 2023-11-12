module PagesComponents.Organization_.Project_.Models.ErdIndex exposing (ErdIndex, create, unpack)

import Libs.Nel exposing (Nel)
import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.Index exposing (Index)
import Models.Project.IndexName exposing (IndexName)
import PagesComponents.Organization_.Project_.Models.Erd.TableWithOrigin exposing (IndexWithOrigin)
import PagesComponents.Organization_.Project_.Models.ErdOrigin exposing (ErdOrigin)


type alias ErdIndex =
    { name : IndexName
    , columns : Nel ColumnPath
    , definition : Maybe String
    , origins : List ErdOrigin
    }


create : IndexWithOrigin -> ErdIndex
create index =
    { name = index.name
    , columns = index.columns
    , definition = index.definition
    , origins = index.origins
    }


unpack : ErdIndex -> Index
unpack erdIndex =
    { name = erdIndex.name
    , columns = erdIndex.columns
    , definition = erdIndex.definition
    }
