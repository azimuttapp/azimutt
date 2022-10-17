module PagesComponents.Organization_.Project_.Models.ErdColumnProps exposing (ErdColumnProps, create, initAll)

import Dict
import Libs.List as List
import Models.ColumnOrder as ColumnOrder
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ProjectSettings as ProjectSettings exposing (ProjectSettings)
import Models.Project.Relation exposing (Relation)
import PagesComponents.Organization_.Project_.Models.ErdTable exposing (ErdTable)


type alias ErdColumnProps =
    { name : ColumnName
    , highlighted : Bool
    }


create : ColumnName -> ErdColumnProps
create name =
    { name = name
    , highlighted = False
    }


initAll : ProjectSettings -> List Relation -> ErdTable -> List ErdColumnProps
initAll settings relations table =
    let
        tableRelations : List Relation
        tableRelations =
            relations |> List.filter (\r -> r.src.table == table.id)
    in
    table.columns
        |> Dict.values
        |> List.filterNot (ProjectSettings.hideColumn settings.hiddenColumns)
        |> ColumnOrder.sortBy settings.columnOrder table tableRelations
        |> List.take settings.hiddenColumns.max
        |> List.map (.name >> create)
