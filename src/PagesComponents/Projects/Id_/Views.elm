module PagesComponents.Projects.Id_.Views exposing (title, view)

import Components.Atoms.Loader as Loader
import Components.Molecules.ContextMenu as ContextMenu exposing (Direction(..))
import Components.Slices.NotFound as NotFound
import Conf
import Dict
import Gen.Route as Route
import Html exposing (Html, aside, div, main_, section)
import Html.Attributes exposing (class, style)
import Html.Keyed as Keyed
import Html.Lazy as Lazy
import Libs.Bool as B
import Libs.Html.Attributes exposing (css)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.String as String
import Models.User exposing (User)
import PagesComponents.Projects.Id_.Components.AmlSlidebar as AmlSlidebar
import PagesComponents.Projects.Id_.Components.ProjectUploadDialog as ProjectUploadDialog
import PagesComponents.Projects.Id_.Components.SourceUpdateDialog as SourceUpdateDialog
import PagesComponents.Projects.Id_.Models exposing (ContextMenu, Model, Msg(..), ProjectSettingsMsg(..))
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Projects.Id_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Projects.Id_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Projects.Id_.Views.Commands exposing (viewCommands)
import PagesComponents.Projects.Id_.Views.Erd as Erd exposing (viewErd)
import PagesComponents.Projects.Id_.Views.Modals.Confirm exposing (viewConfirm)
import PagesComponents.Projects.Id_.Views.Modals.CreateLayout exposing (viewCreateLayout)
import PagesComponents.Projects.Id_.Views.Modals.EditNotes exposing (viewEditNotes)
import PagesComponents.Projects.Id_.Views.Modals.FindPath exposing (viewFindPath)
import PagesComponents.Projects.Id_.Views.Modals.Help exposing (viewHelp)
import PagesComponents.Projects.Id_.Views.Modals.ProjectSettings exposing (viewProjectSettings)
import PagesComponents.Projects.Id_.Views.Modals.Prompt exposing (viewPrompt)
import PagesComponents.Projects.Id_.Views.Modals.SchemaAnalysis exposing (viewSchemaAnalysis)
import PagesComponents.Projects.Id_.Views.Modals.Sharing exposing (viewSharing)
import PagesComponents.Projects.Id_.Views.Modals.SourceParsing exposing (viewSourceParsing)
import PagesComponents.Projects.Id_.Views.Navbar as Navbar exposing (viewNavbar)
import PagesComponents.Projects.Id_.Views.Watermark exposing (viewWatermark)
import Router
import Services.Toasts as Toasts
import Shared exposing (StoredProjects(..))
import Url exposing (Url)
import View exposing (View)


title : Maybe Erd -> String
title erd =
    erd |> Maybe.mapOrElse (\e -> e.project.name ++ " - Azimutt") Conf.constants.defaultTitle


view : Cmd Msg -> Url -> Shared.Model -> Model -> View Msg
view onDelete currentUrl shared model =
    { title = model.erd |> title
    , body = model |> viewProject onDelete currentUrl shared
    }


viewProject : Cmd Msg -> Url -> Shared.Model -> Model -> List (Html Msg)
viewProject onDelete currentUrl shared model =
    [ if model.loaded then
        model.erd |> Maybe.mapOrElse (viewApp currentUrl shared model "app") (viewNotFound currentUrl shared.user model.conf)

      else
        Loader.fullScreen
    , Lazy.lazy4 viewModal currentUrl shared model onDelete
    , Lazy.lazy2 Toasts.view Toast model.toasts
    , Lazy.lazy viewContextMenu model.contextMenu
    ]


viewApp : Url -> Shared.Model -> Model -> HtmlId -> Erd -> Html Msg
viewApp currentUrl shared model htmlId erd =
    div [ class "az-app h-full" ]
        [ if model.conf.showNavbar then
            Lazy.lazy8 viewNavbar shared.conf shared.user model.conf model.virtualRelation erd model.projects model.navbar (Navbar.argsToString currentUrl (htmlId ++ "-nav") (model.openedDropdown |> String.filterStartsWith (htmlId ++ "-nav")))

          else
            div [] []
        , main_
            [ class "flex-1 flex overflow-hidden"
            , style "height" (B.cond model.conf.showNavbar ("calc(100% - " ++ String.fromFloat Conf.ui.navbarHeight ++ "px)") "100%")
            ]
            [ section [ class "relative min-w-0 flex-1 h-full flex flex-col overflow-y-auto" ]
                [ Lazy.lazy8 viewErd model.conf model.screen model.hoverTable erd model.selectionBox model.virtualRelation (Erd.argsToString shared.conf.platform model.cursorMode model.openedDropdown model.openedPopover) model.dragging
                , if model.conf.fullscreen || model.conf.move then
                    let
                        layout : ErdLayout
                        layout =
                            erd |> Erd.currentLayout
                    in
                    Lazy.lazy6 viewCommands model.conf model.cursorMode layout.canvas.zoom (htmlId ++ "-commands") (layout.tables |> List.isEmpty |> not) (model.openedDropdown |> String.filterStartsWith (htmlId ++ "-commands"))

                  else
                    div [] []
                , if not model.conf.showNavbar then
                    viewWatermark

                  else
                    div [] []
                ]
            , viewRightSidebar model
            ]
        ]


viewRightSidebar : Model -> Html Msg
viewRightSidebar model =
    let
        content : Maybe (Html Msg)
        content =
            Maybe.map2 AmlSlidebar.view model.erd model.amlSidebar
    in
    aside [ css [ "block flex-shrink-0 order-last" ] ]
        [ div [ css [ B.cond (content == Nothing) "-mr-112" "", "w-112 transition-[margin] ease-in-out duration-200 h-full relative flex flex-col border-r border-gray-200 bg-white overflow-y-auto" ] ]
            [ content |> Maybe.withDefault (div [] [])
            ]
        ]


viewModal : Url -> Shared.Model -> Model -> Cmd Msg -> Html Msg
viewModal currentUrl shared model onDelete =
    Keyed.node "div"
        [ class "az-modals" ]
        ([ model.confirm |> Maybe.map (\m -> ( m.id, viewConfirm (model.openedDialogs |> List.member m.id) m ))
         , model.prompt |> Maybe.map (\m -> ( m.id, viewPrompt (model.openedDialogs |> List.member m.id) m ))
         , model.newLayout |> Maybe.map2 (\e m -> ( m.id, viewCreateLayout (e.layouts |> Dict.keys) (model.openedDialogs |> List.member m.id) m )) model.erd
         , model.editNotes |> Maybe.map2 (\e m -> ( m.id, viewEditNotes (model.openedDialogs |> List.member m.id) e m )) model.erd
         , model.findPath |> Maybe.map2 (\e m -> ( m.id, viewFindPath (model.openedDialogs |> List.member m.id) model.openedDropdown e.settings.defaultSchema e.tables e.settings.findPath m )) model.erd
         , model.schemaAnalysis |> Maybe.map2 (\e m -> ( m.id, viewSchemaAnalysis (model.openedDialogs |> List.member m.id) e.settings.defaultSchema e.tables m )) model.erd
         , model.sharing |> Maybe.map2 (\e m -> ( m.id, viewSharing (model.openedDialogs |> List.member m.id) e m )) model.erd
         , model.upload |> Maybe.map2 (\e m -> ( m.id, ProjectUploadDialog.view ConfirmOpen onDelete ProjectUploadDialogMsg MoveProjectTo ModalClose currentUrl shared.user (model.openedDialogs |> List.member m.id) e.project m )) model.erd
         , model.settings |> Maybe.map2 (\e m -> ( m.id, viewProjectSettings shared.zone (model.openedDialogs |> List.member m.id) e m )) model.erd
         , model.sourceUpload |> Maybe.map (\m -> ( m.id, SourceUpdateDialog.view (PSSourceUpdate >> ProjectSettingsMsg) (PSSourceSet >> ProjectSettingsMsg) ModalClose Noop shared.zone shared.now (model.openedDialogs |> List.member m.id) m ))
         , model.sourceParsing |> Maybe.map (\m -> ( m.id, viewSourceParsing (model.openedDialogs |> List.member m.id) m ))
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
                div
                    [ class "az-context-menu absolute"
                    , style "left" (String.fromFloat m.position.left ++ "px")
                    , style "top" (String.fromFloat m.position.top ++ "px")
                    ]
                    [ ContextMenu.menu "" BottomRight 0 m.show m.content ]
            )
            (div [ class "az-context-menu" ] [])


viewNotFound : Url -> Maybe User -> ErdConf -> Html msg
viewNotFound currentUrl user conf =
    NotFound.simple
        { brand =
            { img = { src = "/logo.png", alt = "Azimutt" }
            , link = { url = Route.toHref Route.Home_, text = "Azimutt" }
            }
        , header = "404 error"
        , title = "Project not found."
        , message = "Sorry, we couldn't find the project you’re looking for."
        , links =
            (if conf.projectManagement then
                [ { url = Route.toHref Route.Projects, text = "Back to dashboard" } ]

             else
                [ { url = Conf.constants.azimuttWebsite, text = "Visit Azimutt" } ]
            )
                ++ (user |> Maybe.mapOrElse (\_ -> []) [ { url = Router.login currentUrl, text = "Sign in" } ])
        , footer =
            [ { url = Conf.constants.azimuttDiscussions, text = "Contact Support" }
            , { url = Conf.constants.azimuttTwitter, text = "Twitter" }
            , { url = Route.toHref Route.Blog, text = "Blog" }
            ]
        }
