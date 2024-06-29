module PagesComponents.Organization_.Project_.Views exposing (title, view)

import Components.Atoms.Loader as Loader
import Components.Molecules.ContextMenu as ContextMenu exposing (Direction(..))
import Components.Slices.DataExplorer as DataExplorer
import Conf
import Dict
import Html exposing (Html, a, aside, br, button, div, footer, h1, img, main_, nav, p, section, span, text)
import Html.Attributes exposing (alt, class, href, src, style)
import Html.Events exposing (onClick)
import Html.Keyed as Keyed
import Html.Lazy as Lazy
import Libs.Bool as B
import Libs.Html as Html
import Libs.Html.Attributes exposing (ariaHidden, css)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.String as String
import Libs.Tailwind exposing (hover, lg, sm)
import Models.Organization exposing (Organization)
import Models.OrganizationId exposing (OrganizationId)
import Models.Position as Position
import Models.Project.ProjectStorage as ProjectStorage
import Models.ProjectInfo exposing (ProjectInfo)
import Models.ProjectRef exposing (ProjectRef)
import Models.UrlInfos exposing (UrlInfos)
import Models.User exposing (User)
import PagesComponents.Organization_.Project_.Components.AmlSidebar as AmlSidebar
import PagesComponents.Organization_.Project_.Components.DetailsSidebar as DetailsSidebar
import PagesComponents.Organization_.Project_.Components.EmbedSourceParsingDialog as EmbedSourceParsingDialog
import PagesComponents.Organization_.Project_.Components.ExportDialog as ExportDialog
import PagesComponents.Organization_.Project_.Components.LlmGenerateSqlDialog as LlmGenerateSqlDialog
import PagesComponents.Organization_.Project_.Components.ProjectSaveDialog as ProjectSaveDialog
import PagesComponents.Organization_.Project_.Components.ProjectSharing as ProjectSharing
import PagesComponents.Organization_.Project_.Components.SourceUpdateDialog as SourceUpdateDialog
import PagesComponents.Organization_.Project_.Models exposing (ContextMenu, LayoutMsg(..), Model, Msg(..), ProjectSettingsMsg(..), confirmDanger)
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.ErdLayout as ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.NotesMsg as NotesMsg
import PagesComponents.Organization_.Project_.Views.Commands as Commands exposing (viewCommands)
import PagesComponents.Organization_.Project_.Views.Erd as Erd exposing (viewErd)
import PagesComponents.Organization_.Project_.Views.Modals.EditNotes exposing (viewEditNotes)
import PagesComponents.Organization_.Project_.Views.Modals.FindPath exposing (viewFindPath)
import PagesComponents.Organization_.Project_.Views.Modals.Help exposing (viewHelp)
import PagesComponents.Organization_.Project_.Views.Modals.Modals as Modals
import PagesComponents.Organization_.Project_.Views.Modals.NewLayout as NewLayout
import PagesComponents.Organization_.Project_.Views.Modals.ProjectSettings exposing (viewProjectSettings)
import PagesComponents.Organization_.Project_.Views.Modals.SchemaAnalysis exposing (viewSchemaAnalysis)
import PagesComponents.Organization_.Project_.Views.Navbar as Navbar exposing (viewNavbar)
import PagesComponents.Organization_.Project_.Views.Watermark exposing (viewWatermark)
import Services.Backend as Backend
import Services.Toasts as Toasts
import Shared
import Url exposing (Url)
import View exposing (View)


title : Maybe Erd -> String
title erd =
    erd |> Maybe.mapOrElse (\e -> e.project.name ++ " - Azimutt") Conf.constants.defaultTitle


view : Cmd Msg -> Url -> UrlInfos -> Shared.Model -> Model -> View Msg
view onDelete currentUrl urlInfos shared model =
    { title = model.erd |> title
    , body = model |> viewProject onDelete currentUrl urlInfos shared
    }


viewProject : Cmd Msg -> Url -> UrlInfos -> Shared.Model -> Model -> List (Html Msg)
viewProject onDelete currentUrl urlInfos shared model =
    [ if model.loaded then
        model.erd |> Maybe.mapOrElse (viewApp currentUrl urlInfos.organization shared model "app") (viewNotFound currentUrl urlInfos shared.user shared.projects model.conf)

      else
        Loader.fullScreen
    , Lazy.lazy5 viewModal currentUrl urlInfos shared model onDelete
    , Lazy.lazy2 Toasts.view Toast model.toasts
    , Lazy.lazy viewContextMenu model.contextMenu
    , if model.saving then
        div [ class "absolute inset-0 flex z-max bg-white opacity-10 animate-pulse" ]
            [ h1 [ class "m-auto select-none animate-text bg-gradient-to-r from-teal-500 via-purple-500 to-orange-500 bg-clip-text text-transparent text-5xl leading-normal font-black" ] [ text "Saving" ] ]

      else
        Html.none
    ]


viewApp : Url -> Maybe OrganizationId -> Shared.Model -> Model -> HtmlId -> Erd -> Html Msg
viewApp currentUrl urlOrganization shared model htmlId erd =
    div [ class "az-app h-full" ]
        [ if model.conf.showNavbar then
            Lazy.lazy8 viewNavbar shared.conf shared.user model.conf model.virtualRelation erd shared.projects model.navbar (Navbar.argsToString currentUrl urlOrganization (shared.organizations |> List.map .id) (htmlId ++ "-nav") (model.openedDropdown |> String.filterStartsWith (htmlId ++ "-nav")) model.dirty)

          else
            div [] []
        , main_
            [ class "flex-1 flex overflow-hidden transition-[height] ease-in-out duration-200"
            , style "height" ("calc(" ++ calcErdHeight model ++ ")")
            ]
            [ -- model.erdElem |> Area.debugViewport "erdElem" "border-red-500",
              section [ class "relative min-w-0 flex-1 h-full flex flex-col overflow-y-auto" ]
                [ Lazy.lazy8 viewErd model.conf model.erdElem erd model.selectionBox model.virtualRelation model.editMemo (Erd.argsToString shared.now shared.conf.platform model.cursorMode model.openedDropdown model.openedPopover (model.detailsSidebar |> Maybe.mapOrElse DetailsSidebar.selected "") model.hoverTable model.hoverTableRow model.editGroup) model.dragging
                , if model.conf.fullscreen || model.conf.move then
                    let
                        layout : ErdLayout
                        layout =
                            erd |> Erd.currentLayout
                    in
                    Lazy.lazy5 viewCommands
                        model.conf
                        layout.canvas.zoom
                        model.history
                        model.future
                        (Commands.argsToString
                            model.cursorMode
                            (htmlId ++ "-commands")
                            (model.openedDropdown |> String.filterStartsWith (htmlId ++ "-commands"))
                            (layout |> ErdLayout.nonEmpty)
                            (model.amlSidebar /= Nothing)
                            (model.detailsSidebar /= Nothing)
                            (model.dataExplorer.display /= Nothing)
                        )

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
        , viewBottomSheet model
        ]


viewLeftSidebar : Model -> Html Msg
viewLeftSidebar model =
    let
        content : Maybe (Html Msg)
        content =
            model.detailsSidebar |> Maybe.map2 (DetailsSidebar.view DetailsSidebarMsg (\id -> ShowTable id Nothing "details") (ShowColumn 1000) HideColumn (LLoad "fit" >> LayoutMsg) (\source q -> DataExplorer.Open (Just source) (Just q) |> DataExplorerMsg) model.tableStats model.columnStats) model.erd
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


viewBottomSheet : Model -> Html Msg
viewBottomSheet model =
    let
        content : Maybe (Html Msg)
        content =
            model.dataExplorer.display |> Maybe.map2 (\erd -> DataExplorer.view DataExplorerMsg DropdownToggle CustomModalOpen (\id -> ShowTable id Nothing "data-explorer") (\i q s h -> ShowTableRow i q s h "data-explorer") (\t c -> NotesMsg.NOpen t c |> NotesMsg) (calcNavbarHeight model) model.openedDropdown erd.settings.defaultSchema Conf.ids.dataExplorerDialog erd.sources (erd |> Erd.currentLayout) erd.metadata model.dataExplorer) model.erd
    in
    aside [ class "block flex-shrink-0" ]
        [ div [ style "height" ("calc(" ++ calcBottomSheetHeight model ++ ")"), css [ "relative border-t border-gray-200 bg-white overflow-y-auto" ] ]
            [ content |> Maybe.withDefault (div [] [])
            ]
        ]


viewModal : Url -> UrlInfos -> Shared.Model -> Model -> Cmd Msg -> Html Msg
viewModal curUrl urlInfos shared model _ =
    let
        projectRef : ProjectRef
        projectRef =
            model.erd |> Erd.getProjectRef urlInfos shared.organizations

        isOpen : { a | id : HtmlId } -> Bool
        isOpen =
            \m -> model.openedDialogs |> List.member m.id
    in
    Keyed.node "div"
        [ class "az-modals" ]
        ([ model.modal |> Maybe.map (\m -> ( m.id, Modals.view (isOpen m) m ))
         , model.confirm |> Maybe.map (\m -> ( m.id, Modals.viewConfirm (isOpen m) m ))
         , model.prompt |> Maybe.map (\m -> ( m.id, Modals.viewPrompt (isOpen m) m ))
         , model.newLayout |> Maybe.map2 (\e m -> ( m.id, NewLayout.view NewLayoutMsg ModalClose projectRef (e.layouts |> Dict.keys) (isOpen m) m )) model.erd
         , model.editNotes |> Maybe.map2 (\e m -> ( m.id, viewEditNotes (isOpen m) e m )) model.erd
         , model.findPath |> Maybe.map2 (\e m -> ( m.id, viewFindPath (isOpen m) model.openedDropdown e.settings.defaultSchema e.tables e.settings.findPath m )) model.erd
         , model.llmGenerateSql |> Maybe.map2 (\e m -> ( m.id, LlmGenerateSqlDialog.view LlmGenerateSqlDialogMsg Send Batch (Toasts.success >> Toast) (\source q -> DataExplorer.Open (Just source) (Just q) |> DataExplorerMsg) ModalClose (isOpen m) e m )) model.erd
         , model.schemaAnalysis |> Maybe.map2 (\e m -> ( m.id, viewSchemaAnalysis projectRef (isOpen m) e.settings.defaultSchema e.sources e.tables e.relations e.ignoredRelations m )) model.erd
         , model.exportDialog |> Maybe.map (\m -> ( m.id, ExportDialog.view ExportDialogMsg Send ModalClose (isOpen m) projectRef m ))
         , model.sharing |> Maybe.map2 (\e m -> ( m.id, ProjectSharing.view SharingMsg Send ModalClose confirmDanger shared.zone curUrl projectRef (isOpen m) e m )) model.erd
         , model.save |> Maybe.map2 (\e m -> ( m.id, ProjectSaveDialog.view ProjectSaveMsg ModalClose CreateProject curUrl shared.user shared.organizations shared.projects (isOpen m) e m )) model.erd
         , model.settings |> Maybe.map2 (\e m -> ( m.id, viewProjectSettings shared.zone (isOpen m) e m )) model.erd
         , model.sourceUpdate |> Maybe.map (\m -> ( m.id, SourceUpdateDialog.view (PSSourceUpdate >> ProjectSettingsMsg) (PSSourceSet >> ProjectSettingsMsg) ModalClose Noop shared.zone shared.now (isOpen m) m ))
         , model.embedSourceParsing |> Maybe.map (\m -> ( m.id, EmbedSourceParsingDialog.view EmbedSourceParsingMsg SourceParsed ModalClose Noop (isOpen m) m ))
         , model.help |> Maybe.map (\m -> ( m.id, viewHelp (isOpen m) m ))
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


viewNotFound : Url -> UrlInfos -> Maybe User -> List ProjectInfo -> ErdConf -> Html Msg
viewNotFound currentUrl urlInfos user projects conf =
    let
        localProject : Maybe ProjectInfo
        localProject =
            urlInfos.project |> Maybe.andThen (\id -> projects |> List.find (\p -> p.id == id)) |> Maybe.filter (\p -> p.storage == ProjectStorage.Local)
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
                            [ { url = urlInfos.organization |> Backend.organizationUrl, text = "Back to dashboard" } ]

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


calcNavbarHeight : Model -> String
calcNavbarHeight model =
    if model.conf.showNavbar then
        --(model.erdElem.position |> Position.extractViewport |> .top |> String.fromFloat) ++ "px"
        -- FIXME: when open data explorer for the first time with the table row incoming relation "See all", the erd moves and break everything
        --        we still see the issue but at least it comes back as normal just after
        "64px"

    else
        "0px"


calcBottomSheetHeight : Model -> String
calcBottomSheetHeight model =
    (model.dataExplorer.display |> Maybe.map (\d -> d == DataExplorer.FullScreenDisplay))
        |> Maybe.mapOrElse (\full -> B.cond full ("100vh - " ++ calcNavbarHeight model) "400px") "0px"


calcErdHeight : Model -> String
calcErdHeight model =
    "100vh - (" ++ calcNavbarHeight model ++ ") - (" ++ calcBottomSheetHeight model ++ ")"
