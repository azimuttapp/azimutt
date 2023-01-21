module PagesComponents.Organization_.Project_.Models.ShowColumns exposing (ShowColumns(..), filterBy, sortBy)

import Dict
import Libs.List as List
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.Relation as Relation
import PagesComponents.Organization_.Project_.Models.ErdColumnProps as ErdColumnProps exposing (ErdColumnProps)
import PagesComponents.Organization_.Project_.Models.ErdRelation exposing (ErdRelation)
import PagesComponents.Organization_.Project_.Models.ErdTable exposing (ErdTable)


type ShowColumns
    = All
    | Relations
    | List (List ColumnName)


filterBy : ShowColumns -> List ErdRelation -> ErdTable -> List ErdColumnProps -> List ErdColumnProps
filterBy kind tableRelations table columns =
    columns
        ++ (table.columns
                |> Dict.values
                |> List.filter (\c -> columns |> List.memberBy .name c.name |> not)
                |> List.filter
                    (\column ->
                        case kind of
                            All ->
                                True

                            Relations ->
                                tableRelations |> List.filter (Relation.linkedTo ( table.id, column.name )) |> List.nonEmpty

                            List cols ->
                                cols |> List.member column.name
                    )
                |> List.map (.name >> ErdColumnProps.create)
           )


sortBy : ShowColumns -> List ErdColumnProps -> List ErdColumnProps
sortBy kind columns =
    case kind of
        All ->
            columns

        Relations ->
            columns

        List cols ->
            let
                ( shown, others ) =
                    columns |> List.partition (\c -> cols |> List.member c.name)

                shownSorted : List ErdColumnProps
                shownSorted =
                    cols |> List.filterMap (\name -> shown |> List.findBy .name name)
            in
            others ++ shownSorted
