module PagesComponents.Projects.Id_.Views.Navbar exposing (viewNavbar)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Atoms.Kbd as Kbd
import Components.Molecules.Dropdown as Dropdown exposing (Direction(..))
import Conf
import Dict
import Either exposing (Either(..))
import Gen.Route as Route
import Html exposing (Html, a, button, div, img, nav, span, text)
import Html.Attributes exposing (alt, class, height, href, id, src, tabindex, type_, width)
import Html.Events exposing (onClick)
import Html.Lazy as Lazy
import Html.Styled exposing (toUnstyled)
import Libs.Bool as B
import Libs.Dict as Dict
import Libs.Either as E
import Libs.Hotkey as Hotkey exposing (Hotkey)
import Libs.Html exposing (extLink)
import Libs.Html.Attributes exposing (ariaControls, ariaExpanded, classes, role)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.Color as Color
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.String as String
import Libs.Tailwind exposing (TwClass, bg_500, bg_600, border_500, focusRing, text_100, text_200)
import Libs.Tailwind.Utilities as Tu
import Models.Project.CanvasProps as CanvasProps
import PagesComponents.Projects.Id_.Models exposing (FindPathMsg(..), HelpMsg(..), LayoutMsg(..), Msg(..), NavbarModel, ProjectSettingsMsg(..), VirtualRelation, VirtualRelationMsg(..), resetCanvas)
import PagesComponents.Projects.Id_.Models.Erd exposing (Erd)
import PagesComponents.Projects.Id_.Views.Navbar.Search exposing (viewNavbarSearch)
import PagesComponents.Projects.Id_.Views.Navbar.Title exposing (viewNavbarTitle)
import Tailwind.Utilities as Tw


type alias Btn msg =
    { action : Either String msg, content : Html msg, hotkey : Maybe Hotkey }


viewNavbar : Maybe VirtualRelation -> Erd -> NavbarModel -> HtmlId -> HtmlId -> Html Msg
viewNavbar virtualRelation erd model htmlId openedDropdown =
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

        canResetCanvas : Bool
        canResetCanvas =
            erd.canvas /= CanvasProps.zero || Dict.nonEmpty erd.tableProps || erd.usedLayout /= Nothing
    in
    nav [ classes [ "tw-navbar relative z-max", bg_600 Conf.theme.color ] ]
        [ div [ class "mx-auto px-2 lg:px-8 sm:px-4" ]
            [ div [ class "relative flex items-center justify-between h-16" ]
                [ div [ class "flex items-center px-2 lg:px-0" ]
                    [ viewNavbarBrand
                    , Lazy.lazy6 viewNavbarSearch model.search erd.tables erd.relations erd.shownTables (htmlId ++ "-search") (openedDropdown |> String.filterStartsWith (htmlId ++ "-search"))
                    , viewNavbarHelp
                    ]
                , div [ class "flex-1 flex justify-center px-2" ]
                    [ Lazy.lazy6 viewNavbarTitle erd.otherProjects erd.project erd.usedLayout erd.layouts (htmlId ++ "-title") (openedDropdown |> String.filterStartsWith (htmlId ++ "-title"))
                    ]
                , navbarMobileButton model.mobileMenuOpen
                , div [ class "hidden lg:block lg:ml-4" ]
                    [ div [ class "flex items-center" ]
                        [ viewNavbarResetLayout canResetCanvas
                        , viewNavbarFeatures features (htmlId ++ "-features") (openedDropdown |> String.filterStartsWith (htmlId ++ "-features"))
                        , viewNavbarSettings
                        ]
                    ]
                ]
            ]
        , Lazy.lazy3 viewNavbarMobileMenu features canResetCanvas model.mobileMenuOpen
        ]


viewNavbarBrand : Html msg
viewNavbarBrand =
    a [ href (Route.toHref Route.Projects), class "flex justify-start items-center flex-shrink-0 font-medium" ]
        [ img [ class "block h-8 h-8", src "/logo.png", alt "Azimutt", width 32, height 32 ] []
        , span [ class "ml-3 text-2xl text-white hidden lg:block" ] [ text "Azimutt" ]
        ]


viewNavbarHelp : Html Msg
viewNavbarHelp =
    button [ onClick (HelpMsg (HOpen "")), class ("ml-3 rounded-full " ++ focusRing ( Color.white, 600 ) ( Conf.theme.color, 600 )) ]
        [ Icon.solid QuestionMarkCircle [ Color.text Conf.theme.color 300 ] |> toUnstyled ]


viewNavbarResetLayout : Bool -> Html Msg
viewNavbarResetLayout canResetCanvas =
    Button.primary3 Conf.theme.color [ onClick resetCanvas, classes [ "ml-auto", B.cond canResetCanvas "" "invisible" ] ] [ text "Reset canvas" ]


viewNavbarFeatures : List (Btn Msg) -> HtmlId -> HtmlId -> Html Msg
viewNavbarFeatures features htmlId openedDropdown =
    Dropdown.dropdown { id = htmlId, direction = BottomLeft, isOpen = openedDropdown == htmlId }
        (\m ->
            button [ type_ "button", id m.id, onClick (DropdownToggle m.id), class ("ml-3 flex-shrink-0 flex justify-center items-center " ++ bg_600 Conf.theme.color ++ " p-1 rounded-full " ++ text_200 Conf.theme.color ++ " " ++ focusRing ( Color.white, 600 ) ( Conf.theme.color, 600 ) ++ " hover:text-white") ]
                [ span [ class "sr-only" ] [ text "View features" ]
                , Icon.outline LightningBolt [] |> toUnstyled
                , Icon.solid ChevronDown [ Tw.transform, Tw.transition, Tu.when m.isOpen [ Tw.neg_rotate_180 ] ] |> toUnstyled
                ]
        )
        (\_ ->
            div []
                (features
                    |> List.map
                        (\btn ->
                            btn.action
                                |> E.reduce
                                    (\url -> extLink url [ role "menuitem", tabindex -1, classes [ "block", Dropdown.itemStyles ] ] [ btn.content ])
                                    (\action -> Dropdown.btn "flex justify-between" action (btn.content :: (btn.hotkey |> M.mapOrElse (\h -> [ Kbd.badge [ class "ml-3" ] (Hotkey.keys h) ]) [])))
                        )
                )
        )


viewNavbarSettings : Html Msg
viewNavbarSettings =
    button [ type_ "button", onClick (ProjectSettingsMsg PSOpen), class ("ml-3 flex-shrink-0 " ++ bg_600 Conf.theme.color ++ " p-1 rounded-full " ++ text_200 Conf.theme.color ++ " " ++ focusRing ( Color.white, 600 ) ( Conf.theme.color, 600 ) ++ " hover:text-white") ]
        [ span [ class "sr-only" ] [ text "View settings" ]
        , Icon.outline Cog [] |> toUnstyled
        ]


navbarMobileButton : Bool -> Html Msg
navbarMobileButton open =
    div [ class "flex lg:hidden" ]
        [ button [ type_ "button", onClick ToggleMobileMenu, ariaControls "mobile-menu", ariaExpanded False, class ("inline-flex items-center justify-center p-2 rounded-md " ++ text_200 Conf.theme.color ++ " hover:text-white hover:" ++ bg_500 Conf.theme.color ++ " focus:outline-none focus:ring-2 focus:ring-inset focus:ring-white") ]
            [ span [ class "sr-only" ] [ text "Open main menu" ]
            , Icon.outline Menu [ B.cond open Tw.hidden Tw.block ] |> toUnstyled
            , Icon.outline X [ B.cond open Tw.block Tw.hidden ] |> toUnstyled
            ]
        ]


viewNavbarMobileMenu : List (Btn Msg) -> Bool -> Bool -> Html Msg
viewNavbarMobileMenu features canResetCanvas isOpen =
    let
        groupSpace : TwClass
        groupSpace =
            "px-2 pt-2 pb-3 space-y-1"

        groupBorder : TwClass
        groupBorder =
            "border-t " ++ border_500 Conf.theme.color

        btnStyle : TwClass
        btnStyle =
            text_100 Conf.theme.color ++ " flex w-full items-center justify-start px-3 py-2 rounded-md text-base font-medium hover:" ++ bg_500 Conf.theme.color ++ " hover:text-white focus:outline-none"
    in
    div [ classes [ "lg:hidden", B.cond isOpen "" "hidden" ], id "mobile-menu" ]
        ([ B.cond canResetCanvas [ button [ type_ "button", onClick resetCanvas, class btnStyle ] [ text "Reset canvas" ] ] []
         , features
            |> List.map
                (\f ->
                    f.action
                        |> E.reduce
                            (\url -> extLink url [ class btnStyle ] [ f.content ])
                            (\action -> button [ type_ "button", onClick action, class btnStyle ] [ f.content ])
                )
         , [ button [ type_ "button", onClick (ProjectSettingsMsg PSOpen), class btnStyle ] [ Icon.outline Cog [ Tw.mr_3 ] |> toUnstyled, text "Settings" ] ]
         ]
            |> List.filter L.nonEmpty
            |> List.indexedMap (\i groupContent -> div [ classes [ groupSpace, B.cond (i /= 0) groupBorder "" ] ] groupContent)
        )
