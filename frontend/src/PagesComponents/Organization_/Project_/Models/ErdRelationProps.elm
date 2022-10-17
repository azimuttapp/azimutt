module PagesComponents.Organization_.Project_.Models.ErdRelationProps exposing (ErdRelationProps, create)

import Models.Project.TableId exposing (TableId)
import Set exposing (Set)


type alias ErdRelationProps =
    { shown : Bool }


create : Set TableId -> TableId -> ErdRelationProps
create shownTables id =
    { shown = shownTables |> Set.member id }
