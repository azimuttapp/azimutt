module PagesComponents.Projects.Id_.Views.Navbar exposing (viewNavbar)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Atoms.Kbd as Kbd
import Components.Molecules.Dropdown as Dropdown exposing (Direction(..))
import Conf
import Css
import Dict
import Either exposing (Either(..))
import Gen.Route as Route
import Html.Styled exposing (Html, a, button, div, img, nav, span, text)
import Html.Styled.Attributes exposing (alt, class, css, height, href, id, src, tabindex, type_, width)
import Html.Styled.Events exposing (onClick)
import Html.Styled.Lazy as Lazy
import Libs.Bool as B
import Libs.Either as E
import Libs.Hotkey as Hotkey exposing (Hotkey)
import Libs.Html.Styled exposing (extLink)
import Libs.Html.Styled.Attributes exposing (ariaControls, ariaExpanded, role)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.Color as Color
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Theme exposing (Theme)
import Libs.Tailwind.Utilities as Tu
import Models.Project exposing (Project)
import Models.Project.Layout exposing (Layout)
import Models.Project.LayoutName exposing (LayoutName)
import PagesComponents.Projects.Id_.Models exposing (FindPathMsg(..), HelpMsg(..), LayoutMsg(..), Msg(..), NavbarModel, ProjectSettingsMsg(..), VirtualRelation, VirtualRelationMsg(..), resetCanvas)
import PagesComponents.Projects.Id_.Views.Navbar.Search exposing (viewNavbarSearch)
import PagesComponents.Projects.Id_.Views.Navbar.Title exposing (viewNavbarTitle)
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


type alias Btn msg =
    { action : Either String msg, content : Html msg, hotkey : Maybe Hotkey }


viewNavbar : Theme -> HtmlId -> Maybe VirtualRelation -> List Project -> Project -> NavbarModel -> Html Msg
viewNavbar theme openedDropdown virtualRelation storedProjects project model =
    let
        features : List (Btn Msg)
        features =
            [ { action = Right HideAllTables, content = text "Hide all tables", hotkey = Nothing }
            , { action = Right ShowAllTables, content = text "Show all tables", hotkey = Nothing }
            , { action = Right (LayoutMsg LOpen), content = text "Save your layout", hotkey = Conf.hotkeys |> Dict.get "save-layout" |> Maybe.andThen List.head }
            , virtualRelation
                |> Maybe.map (\_ -> { action = Right (VirtualRelationMsg VRCancel), content = text "Cancel virtual relation", hotkey = Conf.hotkeys |> Dict.get "create-virtual-relation" |> Maybe.andThen List.head })
                |> Maybe.withDefault { action = Right (VirtualRelationMsg VRCreate), content = text "Create a virtual relation", hotkey = Conf.hotkeys |> Dict.get "create-virtual-relation" |> Maybe.andThen List.head }
            , { action = Right (FindPathMsg (FPOpen Nothing Nothing)), content = text "Find path between tables", hotkey = Conf.hotkeys |> Dict.get "find-path" |> Maybe.andThen List.head }
            , { action = Left Conf.constants.azimuttFeatureRequests, content = text "Suggest a feature 🚀", hotkey = Nothing }
            ]
    in
    nav [ class "tw-navbar", css [ Tw.relative, Tu.z_max, Color.bg theme.color 600 ] ]
        [ div [ css [ Tw.mx_auto, Tw.px_2, Bp.lg [ Tw.px_8 ], Bp.sm [ Tw.px_4 ] ] ]
            [ div [ css [ Tw.relative, Tw.flex, Tw.items_center, Tw.justify_between, Tw.h_16 ] ]
                [ div [ css [ Tw.flex, Tw.items_center, Tw.px_2, Bp.lg [ Tw.px_0 ] ] ]
                    [ viewNavbarBrand
                    , Lazy.lazy3 viewNavbarSearch theme openedDropdown { id = Conf.ids.searchInput, search = model.search.text, active = model.search.active, project = project }
                    , Lazy.lazy viewNavbarHelp theme
                    ]
                , div [ css [ Tw.flex_1, Tw.flex, Tw.justify_center, Tw.px_2 ] ]
                    [ Lazy.lazy4 viewNavbarTitle theme openedDropdown storedProjects project
                    ]
                , navbarMobileButton theme model.mobileMenuOpen
                , div [ css [ Tw.hidden, Bp.lg [ Tw.block, Tw.ml_4 ] ] ]
                    [ div [ css [ Tw.flex, Tw.items_center ] ]
                        [ viewNavbarResetLayout theme project.usedLayout project.layout
                        , viewNavbarFeatures theme features openedDropdown
                        , viewNavbarSettings theme
                        ]
                    ]
                ]
            ]
        , viewNavbarMobileMenu theme features project.usedLayout project.layout model.mobileMenuOpen
        ]


viewNavbarBrand : Html msg
viewNavbarBrand =
    a [ href (Route.toHref Route.Projects), css [ Tw.flex, Tw.justify_start, Tw.items_center, Tw.flex_shrink_0, Tw.font_medium ] ]
        [ img [ css [ Tw.block, Tw.h_8, Tw.h_8 ], src "/logo.png", alt "Azimutt", width 32, height 32 ] []
        , span [ css [ Tw.ml_3, Tw.text_2xl, Tw.text_white, Tw.hidden, Bp.lg [ Tw.block ] ] ] [ text "Azimutt" ]
        ]


viewNavbarHelp : Theme -> Html Msg
viewNavbarHelp theme =
    button [ onClick (HelpMsg (HOpen "")), css [ Tw.ml_3, Tw.rounded_full, Tu.focusRing ( Color.white, 600 ) ( theme.color, 600 ) ] ]
        [ Icon.solid QuestionMarkCircle [ Color.text theme.color 300 ] ]


viewNavbarResetLayout : Theme -> Maybe LayoutName -> Layout -> Html Msg
viewNavbarResetLayout theme usedLayout layout =
    Button.primary3 theme.color [ onClick resetCanvas, css [ Tw.ml_auto, Tu.unless (canResetCanvas usedLayout layout) [ Tw.invisible ] ] ] [ text "Reset canvas" ]


viewNavbarFeatures : Theme -> List (Btn Msg) -> HtmlId -> Html Msg
viewNavbarFeatures theme features openedDropdown =
    Dropdown.dropdown { id = "features", direction = BottomLeft, isOpen = openedDropdown == "features" }
        (\m ->
            button [ type_ "button", id m.id, onClick (DropdownToggle m.id), css [ Tw.ml_3, Tw.flex_shrink_0, Tw.flex, Tw.justify_center, Tw.items_center, Color.bg theme.color 600, Tw.p_1, Tw.rounded_full, Color.text theme.color 200, Tu.focusRing ( Color.white, 600 ) ( theme.color, 600 ), Css.hover [ Tw.text_white ] ] ]
                [ span [ css [ Tw.sr_only ] ] [ text "View features" ]
                , Icon.outline LightningBolt []
                , Icon.solid ChevronDown [ Tw.transform, Tw.transition, Tu.when m.isOpen [ Tw.neg_rotate_180 ] ]
                ]
        )
        (\_ ->
            div []
                (features
                    |> List.map
                        (\btn ->
                            btn.action
                                |> E.reduce
                                    (\url -> extLink url [ role "menuitem", tabindex -1, css [ Tw.block, Dropdown.itemStyles ] ] [ btn.content ])
                                    (\action -> Dropdown.btn [ Tw.flex, Tw.justify_between ] action (btn.content :: (btn.hotkey |> M.mapOrElse (\h -> [ Kbd.badge [ css [ Tw.ml_3 ] ] (Hotkey.keys h) ]) [])))
                        )
                )
        )


viewNavbarSettings : Theme -> Html Msg
viewNavbarSettings theme =
    button [ type_ "button", onClick (ProjectSettingsMsg PSOpen), css [ Tw.ml_3, Tw.flex_shrink_0, Color.bg theme.color 600, Tw.p_1, Tw.rounded_full, Color.text theme.color 200, Tu.focusRing ( Color.white, 600 ) ( theme.color, 600 ), Css.hover [ Tw.text_white ] ] ]
        [ span [ css [ Tw.sr_only ] ] [ text "View settings" ]
        , Icon.outline Cog []
        ]


navbarMobileButton : Theme -> Bool -> Html Msg
navbarMobileButton theme open =
    div [ css [ Tw.flex, Bp.lg [ Tw.hidden ] ] ]
        [ button [ type_ "button", onClick ToggleMobileMenu, ariaControls "mobile-menu", ariaExpanded False, css [ Tw.inline_flex, Tw.items_center, Tw.justify_center, Tw.p_2, Tw.rounded_md, Color.text theme.color 200, Css.focus [ Tw.outline_none, Tw.ring_2, Tw.ring_inset, Tw.ring_white ], Css.hover [ Tw.text_white, Color.bg theme.color 500 ] ] ]
            [ span [ css [ Tw.sr_only ] ] [ text "Open main menu" ]
            , Icon.outline Menu [ B.cond open Tw.hidden Tw.block ]
            , Icon.outline X [ B.cond open Tw.block Tw.hidden ]
            ]
        ]


viewNavbarMobileMenu : Theme -> List (Btn Msg) -> Maybe LayoutName -> Layout -> Bool -> Html Msg
viewNavbarMobileMenu theme features usedLayout layout isOpen =
    let
        groupSpace : Css.Style
        groupSpace =
            Css.batch [ Tw.px_2, Tw.pt_2, Tw.pb_3, Tw.space_y_1 ]

        groupBorder : Css.Style
        groupBorder =
            Css.batch [ Tw.border_t, Color.border theme.color 500 ]

        btnStyle : Css.Style
        btnStyle =
            Css.batch [ Color.text theme.color 100, Tw.flex, Tw.w_full, Tw.items_center, Tw.justify_start, Tw.px_3, Tw.py_2, Tw.rounded_md, Tw.text_base, Tw.font_medium, Css.hover [ Color.bg theme.color 500, Tw.text_white ], Css.focus [ Tw.outline_none ] ]
    in
    div [ css [ Bp.lg [ Tw.hidden ], Tu.unless isOpen [ Tw.hidden ] ], id "mobile-menu" ]
        ([ B.cond (canResetCanvas usedLayout layout) [ button [ type_ "button", onClick resetCanvas, css [ btnStyle ] ] [ text "Reset canvas" ] ] []
         , features
            |> List.map
                (\f ->
                    f.action
                        |> E.reduce
                            (\url -> extLink url [ css [ btnStyle ] ] [ f.content ])
                            (\action -> button [ type_ "button", onClick action, css [ btnStyle ] ] [ f.content ])
                )
         , [ button [ type_ "button", onClick (ProjectSettingsMsg PSOpen), css [ btnStyle ] ] [ Icon.outline Cog [ Tw.mr_3 ], text "Settings" ] ]
         ]
            |> List.filter L.nonEmpty
            |> List.indexedMap (\i groupContent -> div [ css [ groupSpace, Tu.when (i /= 0) [ groupBorder ] ] ] groupContent)
        )


canResetCanvas : Maybe LayoutName -> Layout -> Bool
canResetCanvas usedLayout { tables, hiddenTables, canvas } =
    usedLayout /= Nothing || not ((tables == []) && (hiddenTables == []) && canvas.position == { left = 0, top = 0 } && canvas.zoom == 1)
