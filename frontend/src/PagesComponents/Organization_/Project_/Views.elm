module PagesComponents.Organization_.Project_.Views exposing (title, view)

import Components.Atoms.Loader as Loader
import Components.Molecules.ContextMenu as ContextMenu exposing (Direction(..))
import Conf
import Dict
import Html exposing (Html, a, aside, br, button, div, footer, h1, img, main_, nav, p, section, span, text)
import Html.Attributes exposing (alt, class, href, src, style)
import Html.Events exposing (onClick)
import Html.Keyed as Keyed
import Html.Lazy as Lazy
import Libs.Bool as B
import Libs.Html.Attributes exposing (ariaHidden, css)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.String as String
import Libs.Tailwind exposing (hover, lg, sm)
import Models.OrganizationId exposing (OrganizationId)
import Models.Position as Position
import Models.Project.ProjectId exposing (ProjectId)
import Models.Project.ProjectStorage as ProjectStorage
import Models.ProjectInfo exposing (ProjectInfo)
import Models.User exposing (User)
import PagesComponents.Organization_.Project_.Components.AmlSidebar as AmlSidebar
import PagesComponents.Organization_.Project_.Components.DetailsSidebar as DetailsSidebar
import PagesComponents.Organization_.Project_.Components.EmbedSourceParsingDialog as EmbedSourceParsingDialog
import PagesComponents.Organization_.Project_.Components.ProjectSaveDialog as ProjectSaveDialog
import PagesComponents.Organization_.Project_.Components.SourceUpdateDialog as SourceUpdateDialog
import PagesComponents.Organization_.Project_.Models exposing (ContextMenu, LayoutMsg(..), Model, Msg(..), NotesMsg(..), ProjectSettingsMsg(..), confirmDanger)
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Views.Commands exposing (viewCommands)
import PagesComponents.Organization_.Project_.Views.Erd as Erd exposing (viewErd)
import PagesComponents.Organization_.Project_.Views.Modals.EditNotes exposing (viewEditNotes)
import PagesComponents.Organization_.Project_.Views.Modals.FindPath exposing (viewFindPath)
import PagesComponents.Organization_.Project_.Views.Modals.Help exposing (viewHelp)
import PagesComponents.Organization_.Project_.Views.Modals.Modals as Modals
import PagesComponents.Organization_.Project_.Views.Modals.NewLayout as NewLayout
import PagesComponents.Organization_.Project_.Views.Modals.ProjectSettings exposing (viewProjectSettings)
import PagesComponents.Organization_.Project_.Views.Modals.SchemaAnalysis exposing (viewSchemaAnalysis)
import PagesComponents.Organization_.Project_.Views.Modals.Sharing exposing (viewSharing)
import PagesComponents.Organization_.Project_.Views.Navbar as Navbar exposing (viewNavbar)
import PagesComponents.Organization_.Project_.Views.Watermark exposing (viewWatermark)
import Services.Backend as Backend
import Services.Toasts as Toasts
import Shared exposing (StoredProjects(..))
import Url exposing (Url)
import View exposing (View)


title : Maybe Erd -> String
title erd =
    erd |> Maybe.mapOrElse (\e -> e.project.name ++ " - Azimutt") Conf.constants.defaultTitle


view : Cmd Msg -> Url -> Maybe OrganizationId -> Maybe ProjectId -> Shared.Model -> Model -> View Msg
view onDelete currentUrl urlOrganization urlProject shared model =
    { title = model.erd |> title
    , body = model |> viewProject onDelete currentUrl urlOrganization urlProject shared
    }


viewProject : Cmd Msg -> Url -> Maybe OrganizationId -> Maybe ProjectId -> Shared.Model -> Model -> List (Html Msg)
viewProject onDelete currentUrl urlOrganization urlProject shared model =
    [ if model.loaded then
        model.erd |> Maybe.mapOrElse (viewApp currentUrl urlOrganization shared model "app") (viewNotFound currentUrl urlOrganization urlProject shared.user shared.projects model.conf)

      else
        Loader.fullScreen
    , Lazy.lazy5 viewModal currentUrl urlOrganization shared model onDelete
    , Lazy.lazy2 Toasts.view Toast model.toasts
    , Lazy.lazy viewContextMenu model.contextMenu
    ]


viewApp : Url -> Maybe OrganizationId -> Shared.Model -> Model -> HtmlId -> Erd -> Html Msg
viewApp currentUrl urlOrganization shared model htmlId erd =
    div [ class "az-app h-full" ]
        [ if model.conf.showNavbar then
            let
                projects : List ProjectInfo
                projects =
                    case shared.legacyProjects of
                        Loading ->
                            []

                        Loaded legacyProjects ->
                            legacyProjects
            in
            Lazy.lazy8 viewNavbar shared.conf shared.user model.conf model.virtualRelation erd (shared.projects ++ projects) model.navbar (Navbar.argsToString currentUrl urlOrganization (shared.organizations |> List.map .id) (htmlId ++ "-nav") (model.openedDropdown |> String.filterStartsWith (htmlId ++ "-nav")) model.dirty)

          else
            div [] []
        , main_
            [ class "flex-1 flex overflow-hidden"
            , style "height" (B.cond model.conf.showNavbar ("calc(100% - " ++ (model.erdElem.position |> Position.extractViewport |> .top |> String.fromFloat) ++ "px)") "100%")
            ]
            [ -- model.erdElem |> Area.debugViewport "erdElem" "border-red-500",
              section [ class "relative min-w-0 flex-1 h-full flex flex-col overflow-y-auto" ]
                [ Lazy.lazy8 viewErd model.conf model.erdElem model.hoverTable erd model.selectionBox model.virtualRelation (Erd.argsToString shared.conf.platform model.cursorMode model.openedDropdown model.openedPopover (model.detailsSidebar |> Maybe.mapOrElse DetailsSidebar.selected "")) model.dragging
                , if model.conf.fullscreen || model.conf.move then
                    let
                        layout : ErdLayout
                        layout =
                            erd |> Erd.currentLayout
                    in
                    Lazy.lazy8 viewCommands model.conf model.cursorMode layout.canvas.zoom (htmlId ++ "-commands") (layout.tables |> List.isEmpty |> not) (model.openedDropdown |> String.filterStartsWith (htmlId ++ "-commands")) (model.amlSidebar /= Nothing) (model.detailsSidebar /= Nothing)

                  else
                    div [] []
                , if not model.conf.showNavbar then
                    viewWatermark

                  else
                    div [] []
                ]
            , viewLeftSidebar model
            , viewRightSidebar model
            ]
        ]


viewLeftSidebar : Model -> Html Msg
viewLeftSidebar model =
    let
        content : Maybe (Html Msg)
        content =
            model.detailsSidebar |> Maybe.map2 (DetailsSidebar.view DetailsSidebarMsg (\id -> ShowTable id Nothing) HideTable ShowColumn HideColumn (LLoad >> LayoutMsg) (\ref -> NSave ref >> NotesMsg) model.tableStats model.columnStats) model.erd
    in
    aside [ css [ "block flex-shrink-0 order-first" ] ]
        [ div [ css [ B.cond (content == Nothing) "-ml-112" "", "w-112 transition-[margin] ease-in-out duration-200 h-full relative flex flex-col border-r border-gray-200 bg-white overflow-y-auto" ] ]
            [ content |> Maybe.withDefault (div [] [])
            ]
        ]


viewRightSidebar : Model -> Html Msg
viewRightSidebar model =
    let
        content : Maybe (Html Msg)
        content =
            model.amlSidebar |> Maybe.map2 AmlSidebar.view model.erd
    in
    aside [ css [ "block flex-shrink-0 order-last" ] ]
        [ div [ css [ B.cond (content == Nothing) "-mr-112" "", "w-112 transition-[margin] ease-in-out duration-200 h-full relative flex flex-col border-l border-gray-200 bg-white overflow-y-auto" ] ]
            [ content |> Maybe.withDefault (div [] [])
            ]
        ]


viewModal : Url -> Maybe OrganizationId -> Shared.Model -> Model -> Cmd Msg -> Html Msg
viewModal currentUrl urlOrganization shared model _ =
    Keyed.node "div"
        [ class "az-modals" ]
        ([ model.modal |> Maybe.map (\m -> ( m.id, Modals.view (model.openedDialogs |> List.member m.id) m ))
         , model.confirm |> Maybe.map (\m -> ( m.id, Modals.viewConfirm (model.openedDialogs |> List.member m.id) m ))
         , model.prompt |> Maybe.map (\m -> ( m.id, Modals.viewPrompt (model.openedDialogs |> List.member m.id) m ))
         , model.newLayout |> Maybe.map2 (\e m -> ( m.id, NewLayout.view NewLayoutMsg ModalClose (e |> Erd.getOrganization urlOrganization) (e.layouts |> Dict.keys) (model.openedDialogs |> List.member m.id) m )) model.erd
         , model.editNotes |> Maybe.map2 (\e m -> ( m.id, viewEditNotes (model.openedDialogs |> List.member m.id) e m )) model.erd
         , model.findPath |> Maybe.map2 (\e m -> ( m.id, viewFindPath (model.openedDialogs |> List.member m.id) model.openedDropdown e.settings.defaultSchema e.tables e.settings.findPath m )) model.erd
         , model.schemaAnalysis |> Maybe.map2 (\e m -> ( m.id, viewSchemaAnalysis (e |> Erd.getOrganization urlOrganization) (model.openedDialogs |> List.member m.id) e.settings.defaultSchema e.tables m )) model.erd
         , model.sharing |> Maybe.map2 (\e m -> ( m.id, viewSharing currentUrl (model.openedDialogs |> List.member m.id) e m )) model.erd
         , model.save |> Maybe.map2 (\e m -> ( m.id, ProjectSaveDialog.view ProjectSaveMsg ModalClose CreateProject currentUrl shared.user shared.organizations (model.openedDialogs |> List.member m.id) e m )) model.erd
         , model.settings |> Maybe.map2 (\e m -> ( m.id, viewProjectSettings shared.zone (model.openedDialogs |> List.member m.id) e m )) model.erd
         , model.sourceUpdate |> Maybe.map (\m -> ( m.id, SourceUpdateDialog.view (PSSourceUpdate >> ProjectSettingsMsg) (PSSourceSet >> ProjectSettingsMsg) ModalClose Noop shared.zone shared.now (model.openedDialogs |> List.member m.id) m ))
         , model.embedSourceParsing |> Maybe.map (\m -> ( m.id, EmbedSourceParsingDialog.view EmbedSourceParsingMsg SourceParsed ModalClose Noop (model.openedDialogs |> List.member m.id) m ))
         , model.help |> Maybe.map (\m -> ( m.id, viewHelp (model.openedDialogs |> List.member m.id) m ))
         ]
            |> List.filterMap identity
            |> List.sortBy (\( id, _ ) -> model.openedDialogs |> List.indexOf id |> Maybe.withDefault 0 |> negate)
        )


viewContextMenu : Maybe ContextMenu -> Html Msg
viewContextMenu menu =
    menu
        |> Maybe.mapOrElse
            (\m ->
                div ([ class "az-context-menu absolute" ] ++ Position.stylesViewport m.position)
                    [ ContextMenu.menu "" BottomRight 0 m.show m.content ]
            )
            (div [ class "az-context-menu" ] [])


viewNotFound : Url -> Maybe OrganizationId -> Maybe ProjectId -> Maybe User -> List ProjectInfo -> ErdConf -> Html Msg
viewNotFound currentUrl urlOrganization urlProject user projects conf =
    let
        localProject : Maybe ProjectInfo
        localProject =
            urlProject |> Maybe.andThen (\id -> projects |> List.find (\p -> p.id == id)) |> Maybe.filter (\p -> p.storage == ProjectStorage.Local)
    in
    div [ class "min-h-full pt-16 pb-12 flex flex-col bg-white" ]
        [ main_ [ css [ "flex-grow flex flex-col justify-center max-w-7xl w-full mx-auto px-4", sm [ "px-6" ], lg [ "px-8" ] ] ]
            [ div [ class "flex-shrink-0 flex justify-center" ]
                [ a [ href Backend.homeUrl, class "inline-flex" ]
                    [ span [ class "sr-only" ] [ text "Azimutt" ]
                    , img [ class "h-12 w-auto", src (Backend.resourceUrl "/logo_dark.svg"), alt "Azimutt" ] []
                    ]
                ]
            , div [ class "py-16" ]
                [ div [ class "text-center" ]
                    [ p [ class "text-sm font-semibold text-primary-600 uppercase tracking-wide" ] [ text "404 error" ]
                    , h1 [ css [ "mt-2 text-4xl font-extrabold text-gray-900 tracking-tight", sm [ "text-5xl" ] ] ]
                        [ text (localProject |> Maybe.mapOrElse (\_ -> "Local project not found.") "Project not found.") ]
                    , p [ class "mt-2 text-base text-gray-500" ]
                        (localProject
                            |> Maybe.mapOrElse
                                (\p ->
                                    [ text "This is a local project, stored in your browser. Make sure use the same browser to access it."
                                    , br [] []
                                    , text "If you cleared your storage, you can "
                                    , button [ class "link", onClick (DeleteProject p |> confirmDanger ("Delete project '" ++ p.name ++ "'?") (text "Make sure you are not just on the wrong device/browser.")) ] [ text "delete it" ]
                                    , text "."
                                    ]
                                )
                                [ text "Sorry, we couldn't find the project you’re looking for." ]
                        )
                    , div [ class "mt-6 flex justify-center space-x-4" ]
                        (((if conf.projectManagement then
                            [ { url = urlOrganization |> Backend.organizationUrl, text = "Back to dashboard" } ]

                           else
                            [ { url = Conf.constants.azimuttWebsite, text = "Visit Azimutt" } ]
                          )
                            ++ (user |> Maybe.mapOrElse (\_ -> []) [ { url = Backend.loginUrl currentUrl, text = "Sign in" } ])
                         )
                            |> List.map (\link -> a [ href link.url, css [ "text-base font-medium text-primary-600", hover [ "text-primary-500" ] ] ] [ text link.text ])
                            |> List.intersperse (span [ class "inline-block border-l border-gray-300", ariaHidden True ] [])
                        )
                    ]
                ]
            ]
        , footer [ css [ "flex-shrink-0 max-w-7xl w-full mx-auto px-4 ", sm [ "px-6" ], lg [ "px-8" ] ] ]
            [ nav [ class "flex justify-center space-x-4" ]
                ([ { url = Conf.constants.azimuttDiscussions, text = "Contact Support" }
                 , { url = Conf.constants.azimuttTwitter, text = "Twitter" }
                 , { url = Backend.blogUrl, text = "Blog" }
                 ]
                    |> List.map (\link -> a [ href link.url, css [ "text-sm font-medium text-gray-500 ", hover [ "text-gray-600" ] ] ] [ text link.text ])
                    |> List.intersperse (span [ class "inline-block border-l border-gray-300", ariaHidden True ] [])
                )
            ]
        ]
