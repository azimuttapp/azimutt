module PagesComponents.Id_.Views.Navbar exposing (NavbarArgs, argsToString, viewNavbar)

import Components.Atoms.Icon as Icon
import Components.Molecules.ContextMenu as ContextMenu exposing (Direction(..))
import Components.Molecules.Dropdown as Dropdown
import Components.Molecules.Tooltip as Tooltip
import Conf
import Either exposing (Either(..))
import Gen.Route as Route
import Html exposing (Attribute, Html, a, button, div, img, nav, span, text)
import Html.Attributes exposing (alt, class, height, href, id, src, tabindex, type_, width)
import Html.Events exposing (onClick)
import Html.Lazy as Lazy
import Libs.Bool as B
import Libs.Dict as Dict
import Libs.Either as Either
import Libs.Html as Html exposing (extLink)
import Libs.Html.Attributes exposing (ariaControls, ariaExpanded, css, hrefBlank, role)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.Hotkey exposing (Hotkey)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Platform exposing (Platform)
import Libs.String as String
import Libs.Tailwind as Tw exposing (TwClass, batch, focus, focus_ring_offset_600, hover, lg, sm)
import Libs.Url as Url
import Models.User exposing (User)
import PagesComponents.Helpers as Helpers
import PagesComponents.Id_.Models exposing (FindPathMsg(..), HelpMsg(..), Msg(..), NavbarModel, ProjectSettingsMsg(..), SchemaAnalysisMsg(..), SharingMsg(..), VirtualRelation, VirtualRelationMsg(..))
import PagesComponents.Id_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Id_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Id_.Models.ProjectInfo exposing (ProjectInfo)
import PagesComponents.Id_.Views.Navbar.Search exposing (viewNavbarSearch)
import PagesComponents.Id_.Views.Navbar.Title exposing (viewNavbarTitle)
import Shared exposing (GlobalConf)
import Url exposing (Url)


type alias Btn msg =
    { action : Either String msg, content : Html msg, hotkeys : List Hotkey }


type alias NavbarArgs =
    String


argsToString : Url -> HtmlId -> HtmlId -> NavbarArgs
argsToString currentUrl htmlId openedDropdown =
    Url.toString currentUrl ++ "~" ++ htmlId ++ "~" ++ openedDropdown


stringToArgs : NavbarArgs -> ( Url, HtmlId, HtmlId )
stringToArgs args =
    case String.split "~" args of
        [ url, htmlId, openedDropdown ] ->
            ( url |> Url.fromString |> Maybe.withDefault Url.empty, htmlId, openedDropdown )

        _ ->
            ( Url.empty, "", "" )


viewNavbar : GlobalConf -> Maybe User -> ErdConf -> Maybe VirtualRelation -> Erd -> List ProjectInfo -> NavbarModel -> NavbarArgs -> Html Msg
viewNavbar gConf maybeUser eConf virtualRelation erd projects model args =
    let
        ( currentUrl, htmlId, openedDropdown ) =
            stringToArgs args

        features : List (Btn Msg)
        features =
            [ Just
                (virtualRelation
                    |> Maybe.map (\_ -> { action = Right (VirtualRelationMsg VRCancel), content = text "Cancel virtual relation", hotkeys = Conf.hotkeys |> Dict.getOrElse "create-virtual-relation" [] })
                    |> Maybe.withDefault { action = Right (VirtualRelationMsg VRCreate), content = text "Create a virtual relation", hotkeys = Conf.hotkeys |> Dict.getOrElse "create-virtual-relation" [] }
                )
            , Maybe.when eConf.findPath { action = Right (FindPathMsg (FPOpen Nothing Nothing)), content = text "Find path between tables", hotkeys = Conf.hotkeys |> Dict.getOrElse "find-path" [] }
            , Just { action = Right (SchemaAnalysisMsg SAOpen), content = text "Analyze your schema 🔎", hotkeys = [] }
            , Just { action = Left Conf.constants.azimuttFeatureRequests, content = text "Suggest a feature 🚀", hotkeys = [] }
            ]
                |> List.filterMap identity
    in
    nav [ css [ "az-navbar relative z-max bg-primary-600" ] ]
        [ div [ css [ "mx-auto px-2", sm [ "px-4" ], lg [ "px-8" ] ] ]
            [ div [ class "relative flex items-center justify-between h-16" ]
                [ div [ css [ "flex items-center px-2", lg [ "px-0" ] ] ]
                    [ viewNavbarBrand eConf
                    , Lazy.lazy8 viewNavbarSearch erd.settings.defaultSchema model.search erd.tables erd.relations erd.notes (erd |> Erd.currentLayout |> .tables) (htmlId ++ "-search") (openedDropdown |> String.filterStartsWith (htmlId ++ "-search"))
                    , viewNavbarHelp
                    ]
                , div [ class "flex-1 flex justify-center px-2" ]
                    [ Lazy.lazy8 viewNavbarTitle gConf eConf projects erd.project erd.currentLayout erd.layouts (htmlId ++ "-title") (openedDropdown |> String.filterStartsWith (htmlId ++ "-title"))
                    ]
                , navbarMobileButton model.mobileMenuOpen
                , div [ css [ "hidden", lg [ "block ml-4" ] ] ]
                    [ div [ class "flex items-center print:hidden" ]
                        [ viewNavbarFeatures gConf.platform features (htmlId ++ "-features") (openedDropdown |> String.filterStartsWith (htmlId ++ "-features"))
                        , B.cond eConf.sharing viewNavbarShare Html.none
                        , viewNavbarSettings
                        , if gConf.enableCloud then
                            Helpers.viewProfileIcon currentUrl maybeUser (htmlId ++ "-profile") openedDropdown DropdownToggle Logout

                          else
                            div [] []
                        ]
                    ]
                ]
            ]
        , Lazy.lazy2 viewNavbarMobileMenu features model.mobileMenuOpen
        ]


viewNavbarBrand : ErdConf -> Html msg
viewNavbarBrand conf =
    let
        attrs : List (Attribute msg)
        attrs =
            if conf.dashboardLink then
                [ href (Route.toHref Route.Home_) ]

            else
                hrefBlank Conf.constants.azimuttWebsite
    in
    a (attrs ++ [ class "flex justify-start items-center flex-shrink-0 font-medium" ])
        [ img [ class "block h-8 h-8", src "/logo.png", alt "Azimutt", width 32, height 32 ] []
        , span [ css [ "ml-3 text-2xl text-white hidden", lg [ "block" ] ] ] [ text "Azimutt" ]
        ]


viewNavbarHelp : Html Msg
viewNavbarHelp =
    button [ onClick (HelpMsg (HOpen "")), css [ "mx-3 rounded-full print:hidden", focus_ring_offset_600 Tw.primary ] ]
        [ Icon.solid Icon.QuestionMarkCircle "text-primary-300" ]
        |> Tooltip.b "Help"


viewNavbarFeatures : Platform -> List (Btn Msg) -> HtmlId -> HtmlId -> Html Msg
viewNavbarFeatures platform features htmlId openedDropdown =
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
                                    (\action -> ContextMenu.btnHotkey "flex justify-between" action [ btn.content ] platform btn.hotkeys)
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


viewNavbarMobileMenu : List (Btn Msg) -> Bool -> Html Msg
viewNavbarMobileMenu features isOpen =
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
        ([ features
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
