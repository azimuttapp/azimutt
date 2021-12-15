module PagesComponents.Projects.Id_.Views.Navbar.Title exposing (viewNavbarTitle)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Dropdown as Dropdown exposing (Direction(..))
import Css
import Dict
import Gen.Route as Route
import Html.Styled exposing (Html, a, button, div, small, span, text)
import Html.Styled.Attributes exposing (css, href, id, tabindex, title, type_)
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
            (\m ->
                div [ css [ Tw.w_48, Tw.divide_y, Tw.divide_gray_100 ] ]
                    [ div [ role "none", css [ Tw.py_1 ] ]
                        (storedProjects
                            |> List.filter (\p -> p.id /= project.id)
                            |> List.sortBy (\p -> negate (Time.posixToMillis p.updatedAt))
                            |> List.map (\p -> a [ href (Route.toHref (Route.Projects__Id_ { id = p.id })), role "menuitem", tabindex -1, id (m.id ++ "-item-1"), css [ Tw.block, Tw.px_4, Tw.py_2, Tw.text_sm, Tw.text_gray_700, Css.hover [ Tw.bg_gray_100 ] ] ] [ text p.name ])
                        )
                    , div [ role "none", css [ Tw.py_1 ] ]
                        [ a [ href (Route.toHref Route.Projects), role "menuitem", tabindex -1, id (m.id ++ "-item-last"), css [ Tw.block, Tw.px_4, Tw.py_2, Tw.text_sm, Tw.text_gray_700, Css.hover [ Tw.bg_gray_100 ] ] ] [ text "Back to dashboard" ] ]
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
                                (\m ->
                                    div [ css [ Tw.min_w_max, Tw.divide_y, Tw.divide_gray_100 ] ]
                                        [ div [ role "none", css [ Tw.py_1 ] ]
                                            (project.layouts
                                                |> Dict.toList
                                                |> List.sortBy (\( name, _ ) -> name)
                                                |> List.indexedMap
                                                    (\i ( name, layout ) ->
                                                        span [ role "menuitem", tabindex -1, id (m.id ++ "-item-" ++ String.fromInt i), css [ Tw.block, Tw.px_4, Tw.py_2, Tw.text_sm, Tw.text_gray_700, Css.hover [ Tw.bg_gray_100 ] ] ]
                                                            [ button [ type_ "button", onClick (Noop "delete layout"), title "Delete this layout" ] [ Icon.solid Trash [ Tw.inline_block, Tw.mr_3 ] ]
                                                            , button [ type_ "button", onClick (Noop "update layout"), title "Update layout with current one" ] [ Icon.solid Pencil [ Tw.inline_block, Tw.mr_3 ] ]
                                                            , button [ type_ "button", onClick (Noop "load layout") ]
                                                                [ text name
                                                                , text " "
                                                                , small [] [ text ("(" ++ (layout.tables |> List.length |> S.pluralize "table") ++ ")") ]
                                                                ]
                                                            ]
                                                    )
                                            )
                                        , div [ role "none", css [ Tw.py_1 ] ]
                                            [ button [ type_ "button", onClick (Noop "stop using layout"), role "menuitem", tabindex -1, id (m.id ++ "-item-last"), css [ Tw.block, Tw.w_full, Tw.px_4, Tw.py_2, Tw.text_sm, Tw.text_gray_700, Css.hover [ Tw.bg_gray_100 ] ] ] [ text ("Stop using " ++ usedLayout) ] ]
                                        ]
                                )
                            ]
                        )
                        []
               )
        )
