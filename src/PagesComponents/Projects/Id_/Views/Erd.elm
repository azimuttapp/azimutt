module PagesComponents.Projects.Id_.Views.Erd exposing (viewErd)

import Components.Organisms.Table as Table
import Dict exposing (Dict)
import Html.Styled exposing (Html, div, main_)
import Html.Styled.Attributes exposing (class, css)
import Html.Styled.Events exposing (onClick)
import Html.Styled.Keyed as Keyed
import Libs.Html.Styled.Attributes exposing (onMousedown)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Theme exposing (Theme)
import Libs.Ned as Ned
import Libs.Tailwind.Utilities as Tu
import Models.Project exposing (Project)
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableProps exposing (TableProps)
import PagesComponents.Projects.Id_.Models exposing (DragState, Msg(..))
import Tailwind.Utilities as Tw


viewErd : Theme -> HtmlId -> Maybe DragState -> Project -> Html Msg
viewErd _ openedDropdown dragging project =
    main_ [ class "erd" ]
        [ div [ class "canvas" ]
            [ viewTables openedDropdown dragging project.tables project.layout.tables
            ]
        ]


viewTables : HtmlId -> Maybe DragState -> Dict TableId Table -> List TableProps -> Html Msg
viewTables openedDropdown dragging tables layout =
    Keyed.node "div"
        [ class "tables" ]
        (layout
            |> List.reverse
            |> L.filterZip (\p -> tables |> Dict.get p.id)
            |> List.indexedMap (\i ( p, t ) -> ( TableId.toString t.id, viewTable openedDropdown dragging i t p ))
        )


viewTable : HtmlId -> Maybe DragState -> Int -> Table -> TableProps -> Html Msg
viewTable openedDropdown dragging _ table props =
    let
        tableId : HtmlId
        tableId =
            TableId.toHtmlId table.id

        position : Position
        position =
            props.position |> Position.add (dragging |> M.filter (\d -> d.id == tableId) |> M.mapOrElse (\d -> d.last |> Position.sub d.init) (Position 0 0))
    in
    div [ onMousedown (DragStart tableId), onClick Noop, css [ Tw.absolute, Tw.transform, Tu.translate_x_y position.left position.top "px" ] ]
        [ Table.table
            { id = tableId
            , name = TableId.show table.id
            , isView = table.view
            , columns =
                props.columns
                    |> List.filterMap (\c -> table.columns |> Ned.get c)
                    |> List.map
                        (\c ->
                            { name = c.name
                            , kind = c.kind
                            , nullable = c.nullable
                            , default = c.default
                            , comment = c.comment |> Maybe.map .text
                            }
                        )
            , relations = []
            , state =
                { color = props.color
                , hover = False
                , selected = props.selected
                , openedDropdown = openedDropdown
                }
            , actions =
                { toggleSettings = DropdownToggle
                }
            }
        ]
