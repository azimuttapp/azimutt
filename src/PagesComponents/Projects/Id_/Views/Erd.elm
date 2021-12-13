module PagesComponents.Projects.Id_.Views.Erd exposing (viewErd)

import Components.Organisms.Table as Table
import Dict exposing (Dict)
import Html.Styled exposing (Html, div, main_)
import Html.Styled.Attributes exposing (class)
import Html.Styled.Keyed as Keyed
import Libs.List as L
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Theme exposing (Theme)
import Libs.Ned as Ned
import Models.Project exposing (Project)
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableProps exposing (TableProps)
import PagesComponents.Projects.Id_.Models exposing (Msg(..))
import Tailwind.Utilities as Tw


viewErd : Theme -> String -> Project -> Html Msg
viewErd _ openedDropdown project =
    main_ [ class "erd" ]
        [ div [ class "canvas" ]
            [ viewTables openedDropdown project.tables project.layout.tables
            ]
        ]


viewTables : String -> Dict TableId Table -> List TableProps -> Html Msg
viewTables openedDropdown tables layout =
    Keyed.node "div"
        [ class "tables" ]
        (layout
            |> List.reverse
            |> L.filterZip (\p -> tables |> Dict.get p.id)
            |> List.indexedMap (\i ( p, t ) -> ( TableId.toString t.id, viewTable openedDropdown i t p ))
        )


viewTable : String -> Int -> Table -> TableProps -> Html Msg
viewTable openedDropdown _ table props =
    let
        dropdownId : HtmlId
        dropdownId =
            TableId.toHtmlId table.id ++ "-settings"
    in
    Table.table [ Tw.absolute ]
        { id = TableId.toHtmlId table.id
        , name = TableId.show table.id
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
            , settingsOpened = openedDropdown == dropdownId
            }
        , actions =
            { toggleSettings = ToggleDropdown dropdownId
            }
        }
