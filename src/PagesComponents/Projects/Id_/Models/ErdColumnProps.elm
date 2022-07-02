module PagesComponents.Projects.Id_.Models.ErdColumnProps exposing (ErdColumnProps, create, initAll)

import Dict
import Libs.List as List
import Models.ColumnOrder as ColumnOrder
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ProjectSettings as ProjectSettings exposing (ProjectSettings)
import Models.Project.Relation as Relation exposing (Relation)
import PagesComponents.Projects.Id_.Models.ErdTable exposing (ErdTable)


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
            relations |> Relation.withTableSrc table.id
    in
    table.columns
        |> Dict.values
        |> List.filterNot (ProjectSettings.hideColumn settings.hiddenColumns)
        |> ColumnOrder.sortBy settings.columnOrder table tableRelations
        |> List.map (.name >> create)
