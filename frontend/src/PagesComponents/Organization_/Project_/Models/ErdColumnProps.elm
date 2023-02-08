module PagesComponents.Organization_.Project_.Models.ErdColumnProps exposing (ErdColumnProps, create, initAll)

import Dict
import Libs.List as List
import Models.ColumnOrder as ColumnOrder
import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.ProjectSettings as ProjectSettings exposing (ProjectSettings)
import PagesComponents.Organization_.Project_.Models.ErdRelation exposing (ErdRelation)
import PagesComponents.Organization_.Project_.Models.ErdTable exposing (ErdTable)


type alias ErdColumnProps =
    { path : ColumnPath
    , highlighted : Bool
    }


create : ColumnPath -> ErdColumnProps
create path =
    { path = path
    , highlighted = False
    }


initAll : ProjectSettings -> List ErdRelation -> ErdTable -> List ErdColumnProps
initAll settings relations table =
    let
        tableRelations : List ErdRelation
        tableRelations =
            relations |> List.filter (\r -> r.src.table == table.id)
    in
    table.columns
        |> Dict.values
        |> List.filterNot (ProjectSettings.hideColumn settings.hiddenColumns)
        |> ColumnOrder.sortBy settings.columnOrder table tableRelations
        |> List.take settings.hiddenColumns.max
        |> List.map (.path >> create)
