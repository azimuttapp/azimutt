module PagesComponents.Organization_.Project_.Models.ErdPrimaryKey exposing (ErdPrimaryKey, create, unpack)

import Libs.Nel exposing (Nel)
import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.PrimaryKey exposing (PrimaryKey)
import Models.Project.PrimaryKeyName exposing (PrimaryKeyName)
import PagesComponents.Organization_.Project_.Models.Erd.TableWithOrigin exposing (PrimaryKeyWithOrigin)
import PagesComponents.Organization_.Project_.Models.ErdOrigin exposing (ErdOrigin)


type alias ErdPrimaryKey =
    { name : Maybe PrimaryKeyName
    , columns : Nel ColumnPath
    , origins : List ErdOrigin
    }


create : PrimaryKeyWithOrigin -> ErdPrimaryKey
create pk =
    { name = pk.name
    , columns = pk.columns
    , origins = pk.origins
    }


unpack : ErdPrimaryKey -> PrimaryKey
unpack pk =
    { name = pk.name
    , columns = pk.columns
    }
