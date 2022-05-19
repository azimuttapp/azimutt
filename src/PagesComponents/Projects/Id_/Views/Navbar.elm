module PagesComponents.Projects.Id_.Views.Navbar exposing (viewNavbar)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon
import Components.Atoms.Kbd as Kbd
import Components.Molecules.ContextMenu as ContextMenu exposing (Direction(..))
import Components.Molecules.Dropdown as Dropdown
import Components.Molecules.Tooltip as Tooltip
import Conf
import Dict
import Either exposing (Either(..))
import Gen.Route as Route
import Html exposing (Attribute, Html, a, button, div, img, nav, span, text)
import Html.Attributes exposing (alt, class, height, href, id, src, tabindex, type_, width)
import Html.Events exposing (onClick)
import Html.Lazy as Lazy
import Libs.Bool as B
import Libs.Dict as Dict
import Libs.Either as Either
import Libs.Hotkey as Hotkey exposing (Hotkey)
import Libs.Html as Html exposing (extLink)
import Libs.Html.Attributes exposing (ariaControls, ariaExpanded, css, hrefBlank, role)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.String as String
import Libs.Tailwind as Tw exposing (TwClass, batch, focus, focus_ring_offset_600, hover, lg, sm)
import Models.Project.CanvasProps as CanvasProps
import Models.User exposing (User)
import PagesComponents.Helpers as Helpers
import PagesComponents.Projects.Id_.Models exposing (FindPathMsg(..), HelpMsg(..), LayoutMsg(..), Msg(..), NavbarModel, ProjectSettingsMsg(..), SchemaAnalysisMsg(..), SharingMsg(..), VirtualRelation, VirtualRelationMsg(..), resetCanvas)
import PagesComponents.Projects.Id_.Models.Erd exposing (Erd)
import PagesComponents.Projects.Id_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Projects.Id_.Models.ProjectInfo exposing (ProjectInfo)
import PagesComponents.Projects.Id_.Views.Navbar.Search exposing (viewNavbarSearch)
import PagesComponents.Projects.Id_.Views.Navbar.Title exposing (viewNavbarTitle)


type alias Btn msg =
    { action : Either String msg, content : Html msg, hotkey : Maybe Hotkey }


viewNavbar : Maybe User -> ErdConf -> Maybe VirtualRelation -> Erd -> List ProjectInfo -> NavbarModel -> HtmlId -> HtmlId -> Html Msg
viewNavbar maybeUser conf virtualRelation erd projects model htmlId openedDropdown =
    let
        features : List (Btn Msg)
        features =
            [ Maybe.when conf.layoutManagement { action = Right (LayoutMsg LOpen), content = text "Save current layout", hotkey = Conf.hotkeys |> Dict.get "save-layout" |> Maybe.andThen List.head }
            , Just
                (virtualRelation
                    |> Maybe.map (\_ -> { action = Right (VirtualRelationMsg VRCancel), content = text "Cancel virtual relation", hotkey = Conf.hotkeys |> Dict.get "create-virtual-relation" |> Maybe.andThen List.head })
                    |> Maybe.withDefault { action = Right (VirtualRelationMsg VRCreate), content = text "Create a virtual relation", hotkey = Conf.hotkeys |> Dict.get "create-virtual-relation" |> Maybe.andThen List.head }
                )
            , Maybe.when conf.findPath { action = Right (FindPathMsg (FPOpen Nothing Nothing)), content = text "Find path between tables", hotkey = Conf.hotkeys |> Dict.get "find-path" |> Maybe.andThen List.head }
            , Just { action = Right (SchemaAnalysisMsg SAOpen), content = text "Analyze your schema 🔎", hotkey = Nothing }
            , Just { action = Left Conf.constants.azimuttFeatureRequests, content = text "Suggest a feature 🚀", hotkey = Nothing }
            ]
                |> List.filterMap identity

        canResetCanvas : Bool
        canResetCanvas =
            erd.canvas /= CanvasProps.zero || Dict.nonEmpty erd.tableProps || erd.usedLayout /= Nothing
    in
    nav [ css [ "az-navbar relative z-max bg-primary-600" ] ]
        [ div [ css [ "mx-auto px-2", sm [ "px-4" ], lg [ "px-8" ] ] ]
            [ div [ class "relative flex items-center justify-between h-16" ]
                [ div [ css [ "flex items-center px-2", lg [ "px-0" ] ] ]
                    [ viewNavbarBrand conf
                    , Lazy.lazy6 viewNavbarSearch model.search erd.tables erd.relations erd.shownTables (htmlId ++ "-search") (openedDropdown |> String.filterStartsWith (htmlId ++ "-search"))
                    , viewNavbarHelp
                    ]
                , div [ class "flex-1 flex justify-center px-2" ]
                    [ Lazy.lazy7 viewNavbarTitle conf projects erd.project erd.usedLayout erd.layouts (htmlId ++ "-title") (openedDropdown |> String.filterStartsWith (htmlId ++ "-title"))
                    ]
                , navbarMobileButton model.mobileMenuOpen
                , div [ css [ "hidden", lg [ "block ml-4" ] ] ]
                    [ div [ class "flex items-center print:hidden" ]
                        [ viewNavbarResetLayout canResetCanvas
                        , viewNavbarFeatures features (htmlId ++ "-features") (openedDropdown |> String.filterStartsWith (htmlId ++ "-features"))
                        , B.cond conf.sharing viewNavbarShare Html.none
                        , viewNavbarSettings
                        , Helpers.viewProfileIcon maybeUser (Route.Projects__Id_ { id = erd.project.id }) (htmlId ++ "-profile") openedDropdown DropdownToggle Logout "mx-1 text-primary-200 hover:text-white"
                        ]
                    ]
                ]
            ]
        , Lazy.lazy3 viewNavbarMobileMenu features canResetCanvas model.mobileMenuOpen
        ]


viewNavbarBrand : ErdConf -> Html msg
viewNavbarBrand conf =
    let
        attrs : List (Attribute msg)
        attrs =
            if conf.dashboardLink then
                [ href (Route.toHref Route.Projects) ]

            else
                hrefBlank Conf.constants.azimuttWebsite
    in
    a (attrs ++ [ class "flex justify-start items-center flex-shrink-0 font-medium" ])
        [ img [ class "block h-8 h-8", src "/logo.png", alt "Azimutt", width 32, height 32 ] []
        , span [ css [ "ml-3 text-2xl text-white hidden", lg [ "block" ] ] ] [ text "Azimutt" ]
        ]


viewNavbarHelp : Html Msg
viewNavbarHelp =
    button [ onClick (HelpMsg (HOpen "")), css [ "ml-3 rounded-full print:hidden", focus_ring_offset_600 Tw.primary ] ]
        [ Icon.solid Icon.QuestionMarkCircle "text-primary-300" ]


viewNavbarResetLayout : Bool -> Html Msg
viewNavbarResetLayout canResetCanvas =
    Button.primary3 Tw.primary [ onClick resetCanvas, css [ "ml-auto", B.cond canResetCanvas "" "invisible" ] ] [ text "Reset canvas" ]


viewNavbarFeatures : List (Btn Msg) -> HtmlId -> HtmlId -> Html Msg
viewNavbarFeatures features htmlId openedDropdown =
    Dropdown.dropdown { id = htmlId, direction = BottomLeft, isOpen = openedDropdown == htmlId }
        (\m ->
            button [ type_ "button", id m.id, onClick (DropdownToggle m.id), css [ "mx-1 flex-shrink-0 flex justify-center items-center bg-primary-600 p-1 rounded-full text-primary-200", hover [ "text-white animate-bounce" ], focus_ring_offset_600 Tw.primary ] ]
                [ span [ class "sr-only" ] [ text "Advanced features" ]
                , Icon.outline Icon.LightningBolt ""
                ]
                |> Tooltip.b "Advanced features"
        )
        (\_ ->
            div []
                (features
                    |> List.map
                        (\btn ->
                            btn.action
                                |> Either.reduce
                                    (\url -> extLink url [ role "menuitem", tabindex -1, css [ "block", ContextMenu.itemStyles ] ] [ btn.content ])
                                    (\action -> ContextMenu.btn "flex justify-between" action (btn.content :: (btn.hotkey |> Maybe.mapOrElse (\h -> [ Kbd.badge [ class "ml-3" ] (Hotkey.keys h) ]) [])))
                        )
                )
        )


viewNavbarShare : Html Msg
viewNavbarShare =
    button [ type_ "button", onClick (SharingMsg SOpen), css [ "mx-1 flex-shrink-0 bg-primary-600 p-1 rounded-full text-primary-200", hover [ "text-white animate-pulse" ], focus_ring_offset_600 Tw.primary ] ]
        [ span [ class "sr-only" ] [ text "Share" ]
        , Icon.outline Icon.Share ""
        ]
        |> Tooltip.b "Share diagram"


viewNavbarSettings : Html Msg
viewNavbarSettings =
    button [ type_ "button", onClick (ProjectSettingsMsg PSOpen), css [ "mx-1 flex-shrink-0 bg-primary-600 p-1 rounded-full text-primary-200", hover [ "text-white animate-spin" ], focus_ring_offset_600 Tw.primary ] ]
        [ span [ class "sr-only" ] [ text "Settings" ]
        , Icon.outline Icon.Cog ""
        ]
        |> Tooltip.b "Settings"


navbarMobileButton : Bool -> Html Msg
navbarMobileButton open =
    div [ css [ "flex", lg [ "hidden" ] ] ]
        [ button [ type_ "button", onClick ToggleMobileMenu, ariaControls "mobile-menu", ariaExpanded False, css [ "inline-flex items-center justify-center p-2 rounded-md text-primary-200", hover [ "text-white bg-primary-500" ], focus [ "outline-none ring-2 ring-inset ring-white" ] ] ]
            [ span [ class "sr-only" ] [ text "Open main menu" ]
            , Icon.outline Icon.Menu (B.cond open "hidden" "block")
            , Icon.outline Icon.X (B.cond open "block" "hidden")
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
            "border-t border-primary-500"

        btnStyle : TwClass
        btnStyle =
            batch [ "text-primary-100 flex w-full items-center justify-start px-3 py-2 rounded-md text-base font-medium", hover [ "bg-primary-500 text-white" ], focus [ "outline-none" ] ]
    in
    div [ css [ lg [ "hidden" ], B.cond isOpen "" "hidden" ], id "mobile-menu" ]
        ([ B.cond canResetCanvas [ button [ type_ "button", onClick resetCanvas, class btnStyle ] [ text "Reset canvas" ] ] []
         , features
            |> List.map
                (\f ->
                    f.action
                        |> Either.reduce
                            (\url -> extLink url [ class btnStyle ] [ f.content ])
                            (\action -> button [ type_ "button", onClick action, class btnStyle ] [ f.content ])
                )
         , [ button [ type_ "button", onClick (ProjectSettingsMsg PSOpen), class btnStyle ] [ Icon.outline Icon.Cog "mr-3", text "Settings" ] ]
         ]
            |> List.filter List.nonEmpty
            |> List.indexedMap (\i groupContent -> div [ css [ groupSpace, B.cond (i /= 0) groupBorder "" ] ] groupContent)
        )
