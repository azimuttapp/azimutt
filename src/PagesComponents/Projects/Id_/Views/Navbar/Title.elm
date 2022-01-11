module PagesComponents.Projects.Id_.Views.Navbar.Title exposing (viewNavbarTitle)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Dropdown as Dropdown exposing (Direction(..))
import Components.Molecules.Tooltip as Tooltip
import Conf
import Css
import Dict
import Gen.Route as Route
import Html.Styled exposing (Html, br, button, div, small, span, text)
import Html.Styled.Attributes exposing (css, id, tabindex, type_)
import Html.Styled.Events exposing (onClick)
import Libs.Bool as B
import Libs.Html.Styled exposing (bText)
import Libs.Html.Styled.Attributes exposing (ariaExpanded, ariaHaspopup, role)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.Color as Color
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Theme exposing (Theme)
import Libs.String as S
import Libs.Tailwind.Utilities as Tu
import Libs.Task as T
import Models.Project exposing (Project)
import Models.Project.Layout exposing (Layout)
import Models.Project.LayoutName exposing (LayoutName)
import PagesComponents.Projects.Id_.Models exposing (LayoutMsg(..), Msg(..))
import Tailwind.Utilities as Tw
import Time


viewNavbarTitle : Theme -> HtmlId -> List Project -> Project -> Html Msg
viewNavbarTitle theme openedDropdown storedProjects project =
    div [ css [ Tw.flex, Tw.justify_center, Tw.items_center, Tw.text_white ] ]
        ([ viewProjectsDropdown theme openedDropdown storedProjects project ]
            ++ viewLayouts theme openedDropdown project
        )


viewProjectsDropdown : Theme -> HtmlId -> List Project -> Project -> Html Msg
viewProjectsDropdown theme openedDropdown storedProjects project =
    let
        projects : List Project
        projects =
            storedProjects |> List.filter (\p -> p.id /= project.id) |> List.sortBy (\p -> negate (Time.posixToMillis p.updatedAt))
    in
    Dropdown.dropdown { id = Conf.ids.navProjectDropdown, direction = BottomRight, isOpen = openedDropdown == Conf.ids.navProjectDropdown }
        (\m ->
            button [ type_ "button", id m.id, onClick (DropdownToggle m.id), ariaExpanded False, ariaHaspopup True, css [ Tw.flex, Tw.justify_center, Tw.items_center, Tw.p_1, Tw.rounded_full, Tu.focusRing ( Color.white, 600 ) ( theme.color, 600 ) ] ]
                [ span [] [ text project.name ]
                , Icon.solid ChevronDown [ Tw.transform, Tw.transition, Tu.when m.isOpen [ Tw.neg_rotate_180 ] ]
                ]
        )
        (\_ ->
            div [ css [ Tw.divide_y, Tw.divide_gray_100 ] ]
                (([ [ Dropdown.btn [] SaveProject [ text "Save project" ] ] ]
                    ++ B.cond (List.isEmpty projects) [] [ projects |> List.map (\p -> Dropdown.link { url = Route.toHref (Route.Projects__Id_ { id = p.id }), text = p.name }) ]
                    ++ [ [ Dropdown.link { url = Route.toHref Route.Projects, text = "Back to dashboard" } ] ]
                 )
                    |> L.filterNot List.isEmpty
                    |> List.map (\section -> div [ role "none", css [ Tw.py_1 ] ] section)
                )
        )


viewLayouts : Theme -> HtmlId -> Project -> List (Html Msg)
viewLayouts theme openedDropdown project =
    if project.layouts |> Dict.isEmpty then
        []

    else
        [ Icon.slash [ Color.text theme.color 300 ]
        , Dropdown.dropdown { id = Conf.ids.navLayoutDropdown, direction = BottomLeft, isOpen = openedDropdown == Conf.ids.navLayoutDropdown }
            (\m ->
                button [ type_ "button", id m.id, onClick (DropdownToggle m.id), ariaExpanded False, ariaHaspopup True, css [ Tw.flex, Tw.justify_center, Tw.items_center, Tw.p_1, Tw.rounded_full, Tu.focusRing ( Color.white, 600 ) ( theme.color, 600 ) ] ]
                    [ span [] [ text (project.usedLayout |> M.mapOrElse (\l -> l) "layouts") ]
                    , Icon.solid ChevronDown [ Tw.transform, Tw.transition, Tu.when m.isOpen [ Tw.neg_rotate_180 ] ]
                    ]
            )
            (\_ ->
                div [ css [ Tw.min_w_max, Tw.divide_y, Tw.divide_gray_100 ] ]
                    [ div [ role "none", css [ Tw.py_1 ] ]
                        ((project.usedLayout |> M.mapOrElse (\l -> [ Dropdown.btn [] (LUnload |> LayoutMsg) [ text "Stop using ", bText l, text " layout" ] ]) [])
                            ++ [ Dropdown.btn [] (LOpen |> LayoutMsg) [ text "New layout" ] ]
                        )
                    , div [ role "none", css [ Tw.py_1 ] ]
                        (project.layouts |> Dict.toList |> List.sortBy (\( name, _ ) -> name) |> List.map (\( name, layout ) -> viewLayoutItem name layout))
                    ]
            )
        ]


viewLayoutItem : LayoutName -> Layout -> Html Msg
viewLayoutItem name layout =
    span [ role "menuitem", tabindex -1, css [ Tw.flex, Dropdown.itemStyles ] ]
        [ button [ type_ "button", onClick (name |> confirmDeleteLayout layout), css [ Css.focus [ Tw.outline_none ] ] ] [ Icon.solid Trash [ Tw.inline_block ] ] |> Tooltip.t "Delete this layout"
        , button [ type_ "button", onClick (name |> LUpdate |> LayoutMsg), css [ Tw.mx_2, Css.focus [ Tw.outline_none ] ] ] [ Icon.solid Pencil [ Tw.inline_block ] ] |> Tooltip.t "Update layout with current one"
        , button [ type_ "button", onClick (name |> LLoad |> LayoutMsg), css [ Tw.flex_grow, Tw.text_left, Css.focus [ Tw.outline_none ] ] ]
            [ text name
            , text " "
            , small [] [ text ("(" ++ (layout.tables |> S.pluralizeL "table") ++ ")") ]
            ]
        ]


confirmDeleteLayout : Layout -> LayoutName -> Msg
confirmDeleteLayout layout name =
    ConfirmOpen
        { color = Color.red
        , icon = Trash
        , title = "Delete layout"
        , message =
            span []
                [ text "Are you sure you want to delete "
                , bText name
                , text " layout?"
                , br [] []
                , text ("It contains " ++ (layout.tables |> S.pluralizeL "table") ++ ".")
                ]
        , confirm = "Delete " ++ name ++ " layout"
        , cancel = "Cancel"
        , onConfirm = T.send (name |> LDelete |> LayoutMsg)
        }
