module PagesComponents.Projects.Id_.Views exposing (view)

import Components.Atoms.Loader as Loader
import Components.Molecules.ContextMenu as ContextMenu exposing (Direction(..))
import Components.Molecules.Toast as Toast
import Components.Slices.NotFound as NotFound
import Conf
import Dict
import Gen.Route as Route
import Html exposing (Html, div)
import Html.Attributes exposing (class, style)
import Html.Keyed as Keyed
import Html.Lazy as Lazy
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.String as String
import PagesComponents.Projects.Id_.Models exposing (ContextMenu, Model, Msg(..))
import PagesComponents.Projects.Id_.Models.Erd exposing (Erd)
import PagesComponents.Projects.Id_.Views.Commands exposing (viewCommands)
import PagesComponents.Projects.Id_.Views.Erd as Erd exposing (viewErd)
import PagesComponents.Projects.Id_.Views.Modals.Confirm exposing (viewConfirm)
import PagesComponents.Projects.Id_.Views.Modals.CreateLayout exposing (viewCreateLayout)
import PagesComponents.Projects.Id_.Views.Modals.FindPath exposing (viewFindPath)
import PagesComponents.Projects.Id_.Views.Modals.Help exposing (viewHelp)
import PagesComponents.Projects.Id_.Views.Modals.ProjectSettings exposing (viewProjectSettings)
import PagesComponents.Projects.Id_.Views.Modals.Prompt exposing (viewPrompt)
import PagesComponents.Projects.Id_.Views.Modals.SchemaAnalysis exposing (viewSchemaAnalysis)
import PagesComponents.Projects.Id_.Views.Modals.SourceUpload exposing (viewSourceUpload)
import PagesComponents.Projects.Id_.Views.Navbar exposing (viewNavbar)
import PagesComponents.Projects.Id_.Views.Watermark exposing (viewWatermark)
import Shared exposing (StoredProjects(..))
import Time
import View exposing (View)


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = model.erd |> Maybe.mapOrElse (\e -> e.project.name ++ " - Azimutt") "Azimutt - Explore your database schema"
    , body = model |> viewProject shared
    }


viewProject : Shared.Model -> Model -> List (Html Msg)
viewProject shared model =
    [ if model.loaded then
        model.erd |> Maybe.mapOrElse (viewApp model "app") viewNotFound

      else
        Loader.fullScreen
    , Lazy.lazy3 viewModal shared.zone shared.now model
    , Lazy.lazy viewToasts model.toasts
    , Lazy.lazy viewContextMenu model.contextMenu
    ]


viewApp : Model -> HtmlId -> Erd -> Html Msg
viewApp model htmlId erd =
    div [ class "az-app h-full" ]
        [ if model.conf.showNavbar then
            Lazy.lazy6 viewNavbar model.conf model.virtualRelation erd model.navbar (htmlId ++ "-nav") (model.openedDropdown |> String.filterStartsWith (htmlId ++ "-nav"))

          else
            div [] []
        , Lazy.lazy8 viewErd model.conf model.screen erd model.cursorMode model.selectionBox model.virtualRelation (Erd.argsToString model.openedDropdown model.openedPopover) model.dragging
        , if not (erd.tableProps |> Dict.isEmpty) && (model.conf.fullscreen || model.conf.move) then
            Lazy.lazy5 viewCommands model.conf model.cursorMode erd.canvas.zoom (htmlId ++ "-commands") (model.openedDropdown |> String.filterStartsWith (htmlId ++ "-commands"))

          else
            div [] []
        , if not model.conf.showNavbar then
            viewWatermark

          else
            div [] []
        ]


viewNotFound : Html msg
viewNotFound =
    NotFound.simple
        { brand =
            { img = { src = "/logo.png", alt = "Azimutt" }
            , link = { url = Route.toHref Route.Home_, text = "Azimutt" }
            }
        , header = "404 error"
        , title = "Project not found."
        , message = "Sorry, we couldn't find the project you’re looking for."
        , link = { url = Route.toHref Route.Projects, text = "Go back to dashboard" }
        , footer =
            [ { url = Conf.constants.azimuttDiscussions, text = "Contact Support" }
            , { url = Conf.constants.azimuttTwitter, text = "Twitter" }
            , { url = Route.toHref Route.Blog, text = "Blog" }
            ]
        }


viewModal : Time.Zone -> Time.Posix -> Model -> Html Msg
viewModal zone now model =
    Keyed.node "div"
        [ class "az-modals" ]
        ([ model.confirm |> Maybe.map (\m -> ( m.id, viewConfirm (model.openedDialogs |> List.has m.id) m ))
         , model.prompt |> Maybe.map (\m -> ( m.id, viewPrompt (model.openedDialogs |> List.has m.id) m ))
         , model.newLayout |> Maybe.map (\m -> ( m.id, viewCreateLayout (model.openedDialogs |> List.has m.id) m ))
         , model.findPath |> Maybe.map2 (\e m -> ( m.id, viewFindPath (model.openedDialogs |> List.has m.id) e.tables e.settings.findPath m )) model.erd
         , model.schemaAnalysis |> Maybe.map2 (\e m -> ( m.id, viewSchemaAnalysis (model.openedDialogs |> List.has m.id) e.tables m )) model.erd
         , model.settings |> Maybe.map2 (\e m -> ( m.id, viewProjectSettings zone (model.openedDialogs |> List.has m.id) e m )) model.erd
         , model.sourceUpload |> Maybe.map (\m -> ( m.id, viewSourceUpload zone now (model.openedDialogs |> List.has m.id) m ))
         , model.help |> Maybe.map (\m -> ( m.id, viewHelp (model.openedDialogs |> List.has m.id) m ))
         ]
            |> List.filterMap identity
            |> List.sortBy (\( id, _ ) -> model.openedDialogs |> List.indexOf id |> Maybe.withDefault 0 |> negate)
        )


viewToasts : List Toast.Model -> Html Msg
viewToasts toasts =
    div [ class "az-toasts" ] [ Toast.container toasts ToastHide ]


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
