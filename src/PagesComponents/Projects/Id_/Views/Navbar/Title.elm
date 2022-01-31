module PagesComponents.Projects.Id_.Views.Navbar.Title exposing (viewNavbarTitle)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Dropdown as Dropdown exposing (Direction(..))
import Components.Molecules.Tooltip as Tooltip
import Conf
import Dict exposing (Dict)
import Gen.Route as Route
import Html exposing (Html, br, button, div, small, span, text)
import Html.Attributes exposing (class, id, tabindex, type_)
import Html.Events exposing (onClick)
import Html.Lazy as Lazy
import Html.Styled exposing (fromUnstyled, toUnstyled)
import Libs.Bool as B
import Libs.Html exposing (bText)
import Libs.Html.Attributes exposing (ariaExpanded, ariaHaspopup, classes, role)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.Color as Color
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.String as String
import Libs.Tailwind exposing (focusRing)
import Libs.Tailwind.Utilities as Tu
import Libs.Task as T
import Models.Project.Layout exposing (Layout)
import Models.Project.LayoutName exposing (LayoutName)
import PagesComponents.Projects.Id_.Models exposing (LayoutMsg(..), Msg(..))
import PagesComponents.Projects.Id_.Models.ProjectInfo exposing (ProjectInfo)
import Tailwind.Utilities as Tw


viewNavbarTitle : List ProjectInfo -> ProjectInfo -> Maybe LayoutName -> Dict LayoutName Layout -> HtmlId -> HtmlId -> Html Msg
viewNavbarTitle otherProjects project usedLayout layouts htmlId openedDropdown =
    div [ class "flex justify-center items-center text-white" ]
        ([ Lazy.lazy4 viewProjectsDropdown otherProjects project (htmlId ++ "-projects") (openedDropdown |> String.filterStartsWith (htmlId ++ "-projects")) ]
            ++ viewLayoutsMaybe usedLayout layouts (htmlId ++ "-layouts") (openedDropdown |> String.filterStartsWith (htmlId ++ "-layouts"))
        )


viewProjectsDropdown : List ProjectInfo -> ProjectInfo -> HtmlId -> HtmlId -> Html Msg
viewProjectsDropdown otherProjects project htmlId openedDropdown =
    Dropdown.dropdown { id = htmlId, direction = BottomRight, isOpen = openedDropdown == htmlId }
        (\m ->
            button [ type_ "button", id m.id, onClick (DropdownToggle m.id), ariaExpanded False, ariaHaspopup True, class ("flex justify-center items-center p-1 rounded-full " ++ focusRing ( Color.white, 600 ) ( Conf.theme.color, 600 )) ]
                [ span [] [ text project.name ]
                , Icon.solid ChevronDown [ Tw.transform, Tw.transition, Tu.when m.isOpen [ Tw.neg_rotate_180 ] ] |> toUnstyled
                ]
        )
        (\_ ->
            div [ class "divide-y divide-gray-100" ]
                (([ [ Dropdown.btn "" SaveProject [ text "Save project" ] ] ]
                    ++ B.cond (List.isEmpty otherProjects) [] [ otherProjects |> List.map (\p -> Dropdown.link { url = Route.toHref (Route.Projects__Id_ { id = p.id }), text = p.name }) ]
                    ++ [ [ Dropdown.link { url = Route.toHref Route.Projects, text = "Back to dashboard" } ] ]
                 )
                    |> L.filterNot List.isEmpty
                    |> List.map (\section -> div [ role "none", class "py-1" ] section)
                )
        )


viewLayoutsMaybe : Maybe LayoutName -> Dict LayoutName Layout -> HtmlId -> HtmlId -> List (Html Msg)
viewLayoutsMaybe usedLayout layouts htmlId openedDropdown =
    if layouts |> Dict.isEmpty then
        []

    else
        [ Icon.slash [ Color.text Conf.theme.color 300 ] |> toUnstyled
        , Lazy.lazy4 viewLayouts usedLayout layouts htmlId openedDropdown
        ]


viewLayouts : Maybe LayoutName -> Dict LayoutName Layout -> HtmlId -> HtmlId -> Html Msg
viewLayouts usedLayout layouts htmlId openedDropdown =
    Dropdown.dropdown { id = htmlId, direction = BottomLeft, isOpen = openedDropdown == htmlId }
        (\m ->
            button [ type_ "button", id m.id, onClick (DropdownToggle m.id), ariaExpanded False, ariaHaspopup True, class ("flex justify-center items-center p-1 rounded-full " ++ focusRing ( Color.white, 600 ) ( Conf.theme.color, 600 )) ]
                [ span [] [ text (usedLayout |> M.mapOrElse (\l -> l) "layouts") ]
                , Icon.solid ChevronDown [ Tw.transform, Tw.transition, Tu.when m.isOpen [ Tw.neg_rotate_180 ] ] |> toUnstyled
                ]
        )
        (\_ ->
            div [ class "min-w-max divide-y divide-gray-100" ]
                (L.prependOn usedLayout
                    (\l ->
                        div [ role "none", class "py-1" ]
                            [ Dropdown.btn "" (l |> LUpdate |> LayoutMsg) [ text "Update ", bText l, text " with current layout" ]
                            , Dropdown.btn "" (LUnload |> LayoutMsg) [ text "Stop using ", bText l, text " layout" ]
                            ]
                    )
                    [ div [ role "none", class "py-1" ]
                        [ Dropdown.btn "" (LOpen |> LayoutMsg) [ text "Create new layout" ] ]
                    , div [ role "none", class "py-1" ]
                        (layouts |> Dict.toList |> List.sortBy (\( name, _ ) -> name) |> List.map (\( name, layout ) -> viewLayoutItem name layout))
                    ]
                )
        )


viewLayoutItem : LayoutName -> Layout -> Html Msg
viewLayoutItem name layout =
    span [ role "menuitem", tabindex -1, classes [ "flex", Dropdown.itemStyles ] ]
        [ button [ type_ "button", onClick (name |> confirmDeleteLayout layout), class "focus:outline-none" ] [ Icon.solid Trash [ Tw.inline_block ] |> toUnstyled ] |> Tooltip.t "Delete this layout"
        , button [ type_ "button", onClick (name |> LUpdate |> LayoutMsg), class "mx-2 focus:outline-none" ] [ Icon.solid Pencil [ Tw.inline_block ] |> toUnstyled ] |> Tooltip.t "Update layout with current one"
        , button [ type_ "button", onClick (name |> LLoad |> LayoutMsg), class "flex-grow text-left focus:outline-none" ]
            [ text name
            , text " "
            , small [] [ text ("(" ++ (layout.tables |> String.pluralizeL "table") ++ ")") ]
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
                , text ("It contains " ++ (layout.tables |> String.pluralizeL "table") ++ ".")
                ]
                |> fromUnstyled
        , confirm = "Delete " ++ name ++ " layout"
        , cancel = "Cancel"
        , onConfirm = T.send (name |> LDelete |> LayoutMsg)
        }
