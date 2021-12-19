module PagesComponents.Projects.Id_.Views.Navbar.Title exposing (viewNavbarTitle)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Dropdown as Dropdown exposing (Direction(..))
import Components.Molecules.Tooltip as Tooltip
import Css
import Dict
import Gen.Route as Route
import Html.Styled exposing (Html, button, div, small, span, text)
import Html.Styled.Attributes exposing (css, id, tabindex, type_)
import Html.Styled.Events exposing (onClick)
import Libs.Bool as B
import Libs.Html.Styled.Attributes exposing (ariaExpanded, ariaHaspopup, role)
import Libs.Maybe as M
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Theme exposing (Theme)
import Libs.Models.TwColor as TwColor exposing (TwColor(..), TwColorLevel(..), TwColorPosition(..))
import Libs.String as S
import Libs.Tailwind.Utilities as Tu
import Models.Project exposing (Project)
import PagesComponents.Projects.Id_.Models exposing (Msg(..))
import Tailwind.Utilities as Tw
import Time


viewNavbarTitle : Theme -> HtmlId -> List Project -> Project -> Html Msg
viewNavbarTitle theme openedDropdown storedProjects project =
    div [ css [ Tw.flex, Tw.justify_center, Tw.items_center, Tw.text_white ] ]
        ([ Dropdown.dropdown { id = "switch-project", direction = BottomRight, isOpen = openedDropdown == "switch-project" }
            (\m ->
                button [ type_ "button", id m.id, onClick (DropdownToggle m.id), ariaExpanded False, ariaHaspopup True, css [ Tw.flex, Tw.justify_center, Tw.items_center, Tw.p_1, Tw.rounded_full, Tu.focusRing ( White, L600 ) ( theme.color, L600 ) ] ]
                    [ span [] [ text project.name ]
                    , Icon.solid (B.cond m.isOpen ChevronUp ChevronDown) []
                    ]
            )
            (\_ ->
                div [ css [ Tw.divide_y, Tw.divide_gray_100 ] ]
                    [ div [ role "none", css [ Tw.py_1 ] ]
                        (storedProjects
                            |> List.filter (\p -> p.id /= project.id)
                            |> List.sortBy (\p -> negate (Time.posixToMillis p.updatedAt))
                            |> List.map (\p -> Dropdown.link { url = Route.toHref (Route.Projects__Id_ { id = p.id }), text = p.name })
                        )
                    , div [ role "none", css [ Tw.py_1 ] ] [ Dropdown.link { url = Route.toHref Route.Projects, text = "Back to dashboard" } ]
                    ]
            )
         ]
            ++ (project.usedLayout
                    |> M.mapOrElse
                        (\usedLayout ->
                            [ Icon.slash [ TwColor.render Text theme.color L300 ]
                            , Dropdown.dropdown { id = "switch-layout", direction = BottomLeft, isOpen = openedDropdown == "switch-layout" }
                                (\m ->
                                    button [ type_ "button", id m.id, onClick (DropdownToggle m.id), ariaExpanded False, ariaHaspopup True, css [ Tw.flex, Tw.justify_center, Tw.items_center, Tw.p_1, Tw.rounded_full, Tu.focusRing ( White, L600 ) ( theme.color, L600 ) ] ]
                                        [ span [] [ text usedLayout ]
                                        , Icon.solid (B.cond m.isOpen ChevronUp ChevronDown) []
                                        ]
                                )
                                (\_ ->
                                    div [ css [ Tw.min_w_max, Tw.divide_y, Tw.divide_gray_100 ] ]
                                        [ div [ role "none", css [ Tw.py_1 ] ]
                                            (project.layouts
                                                |> Dict.toList
                                                |> List.sortBy (\( name, _ ) -> name)
                                                |> List.map
                                                    (\( name, layout ) ->
                                                        span [ role "menuitem", tabindex -1, css ([ Tw.block ] ++ Dropdown.itemStyles) ]
                                                            [ button [ type_ "button", onClick (Noop "delete layout"), css [ Css.focus [ Tw.outline_none ] ] ] [ Icon.solid Trash [ Tw.inline_block ] ] |> Tooltip.top "Delete this layout"
                                                            , button [ type_ "button", onClick (Noop "update layout"), css [ Tw.mx_3, Css.focus [ Tw.outline_none ] ] ] [ Icon.solid Pencil [ Tw.inline_block ] ] |> Tooltip.top "Update layout with current one"
                                                            , button [ type_ "button", onClick (Noop "load layout"), css [ Css.focus [ Tw.outline_none ] ] ]
                                                                [ text name
                                                                , text " "
                                                                , small [] [ text ("(" ++ (layout.tables |> List.length |> S.pluralize "table") ++ ")") ]
                                                                ]
                                                            ]
                                                    )
                                            )
                                        , div [ role "none", css [ Tw.py_1 ] ] [ Dropdown.btn (Noop "stop using layout") [ text ("Stop using " ++ usedLayout) ] ]
                                        ]
                                )
                            ]
                        )
                        []
               )
        )
