module PagesComponents.Organization_.Project_.Models.ErdCheck exposing (ErdCheck, create, unpack)

import Models.Project.Check exposing (Check)
import Models.Project.CheckName exposing (CheckName)
import Models.Project.ColumnPath exposing (ColumnPath)
import PagesComponents.Organization_.Project_.Models.Erd.TableWithOrigin exposing (CheckWithOrigin)
import PagesComponents.Organization_.Project_.Models.ErdOrigin exposing (ErdOrigin)


type alias ErdCheck =
    { name : CheckName
    , columns : List ColumnPath
    , predicate : Maybe String
    , origins : List ErdOrigin
    }


create : CheckWithOrigin -> ErdCheck
create check =
    { name = check.name
    , columns = check.columns
    , predicate = check.predicate
    , origins = check.origins
    }


unpack : ErdCheck -> Check
unpack erdCheck =
    { name = erdCheck.name
    , columns = erdCheck.columns
    , predicate = erdCheck.predicate
    }
