module PagesComponents.Projects.Id_.Updates.Table exposing (showTable)

import Dict
import Libs.List as L
import Libs.Maybe as M
import Libs.Task as T
import Models.Project exposing (Project)
import Models.Project.Layout exposing (Layout)
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableProps as TableProps exposing (TableProps)
import PagesComponents.App.Updates.Helpers exposing (setLayout)
import PagesComponents.Projects.Id_.Models exposing (Msg, toastError, toastInfo)
import Ports exposing (observeTableSize)


showTable : TableId -> Project -> ( Project, Cmd Msg )
showTable id project =
    case project.tables |> Dict.get id of
        Just table ->
            if project.layout.tables |> L.memberBy .id id then
                ( project, T.send (toastInfo ("Table <b>" ++ TableId.show id ++ "</b> already shown")) )

            else
                ( project |> performShowTable table, Cmd.batch [ observeTableSize id ] )

        Nothing ->
            ( project, T.send (toastError ("Can't show table <b>" ++ TableId.show id ++ "</b>: not found")) )


performShowTable : Table -> Project -> Project
performShowTable table project =
    project
        |> setLayout
            (\layout ->
                { layout
                    | tables = (getTableProps project layout table :: layout.tables) |> L.uniqueBy .id
                    , hiddenTables = layout.hiddenTables |> L.removeBy .id table.id
                }
            )


getTableProps : Project -> Layout -> Table -> TableProps
getTableProps project layout table =
    (layout.tables |> L.findBy .id table.id)
        |> M.orElse (layout.hiddenTables |> L.findBy .id table.id)
        |> Maybe.withDefault (TableProps.init project.settings project.relations table)
