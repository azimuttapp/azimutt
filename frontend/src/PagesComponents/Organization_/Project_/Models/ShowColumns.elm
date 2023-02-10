module PagesComponents.Organization_.Project_.Models.ShowColumns exposing (ShowColumns(..), filterBy, sortBy)

import Dict
import Libs.List as List
import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.ColumnRef as ColumnRef
import PagesComponents.Organization_.Project_.Models.ErdColumnProps as ErdColumnProps exposing (ErdColumnProps, ErdColumnPropsFlat)
import PagesComponents.Organization_.Project_.Models.ErdRelation as ErdRelation exposing (ErdRelation)
import PagesComponents.Organization_.Project_.Models.ErdTable exposing (ErdTable)


type ShowColumns
    = All
    | Relations
    | List (List ColumnPath)


filterBy : ShowColumns -> List ErdRelation -> ErdTable -> List ErdColumnProps -> List ErdColumnProps
filterBy kind tableRelations table columns =
    columns
        ++ (table.columns
                |> Dict.values
                |> List.filter (\c -> columns |> ErdColumnProps.member c.path |> not)
                |> List.filter
                    (\column ->
                        case kind of
                            All ->
                                True

                            Relations ->
                                tableRelations |> List.filter (ErdRelation.linkedTo (ColumnRef.from table column)) |> List.nonEmpty

                            List cols ->
                                cols |> List.member column.path
                    )
                |> List.map .path
                |> ErdColumnProps.createAll
           )


sortBy : ShowColumns -> List ErdColumnProps -> List ErdColumnProps
sortBy kind columns =
    case kind of
        All ->
            columns

        Relations ->
            columns

        List cols ->
            -- sort `columns` in the same order than `cols`, used for AML, only at root level
            let
                ( shown, others ) =
                    columns |> List.partition (\c -> cols |> List.map .head |> List.member c.name)

                shownSorted : List ErdColumnProps
                shownSorted =
                    cols |> List.filterMap (\path -> shown |> List.findBy .name path.head)
            in
            others ++ shownSorted
