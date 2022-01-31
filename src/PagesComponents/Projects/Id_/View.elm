module PagesComponents.Projects.Id_.View exposing (viewProject)

import Components.Atoms.Styles as Styles
import Components.Molecules.Toast as Toast
import Components.Slices.NotFound as NotFound
import Conf
import Css.Global as Global
import Dict
import Gen.Route as Route
import Html exposing (div)
import Html.Attributes exposing (class)
import Html.Keyed as Keyed
import Html.Lazy as Lazy
import Html.Styled as Styled exposing (fromUnstyled)
import Html.Styled.Lazy as Styled
import Libs.List as L
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.String as String
import Libs.Tailwind exposing (border_500)
import PagesComponents.Projects.Id_.Models exposing (Model, Msg(..))
import PagesComponents.Projects.Id_.Models.Erd exposing (Erd)
import PagesComponents.Projects.Id_.Views.Commands exposing (viewCommands)
import PagesComponents.Projects.Id_.Views.Erd exposing (viewErd)
import PagesComponents.Projects.Id_.Views.Modals.Confirm exposing (viewConfirm)
import PagesComponents.Projects.Id_.Views.Modals.CreateLayout exposing (viewCreateLayout)
import PagesComponents.Projects.Id_.Views.Modals.FindPath exposing (viewFindPath)
import PagesComponents.Projects.Id_.Views.Modals.Help exposing (viewHelp)
import PagesComponents.Projects.Id_.Views.Modals.ProjectSettings exposing (viewProjectSettings)
import PagesComponents.Projects.Id_.Views.Modals.SourceUpload exposing (viewSourceUpload)
import PagesComponents.Projects.Id_.Views.Navbar exposing (viewNavbar)
import Shared exposing (StoredProjects(..))
import Tailwind.Utilities as Tw
import Time


viewProject : Shared.Model -> Model -> List (Styled.Html Msg)
viewProject shared model =
    [ Global.global Tw.globalStyles
    , Global.global [ Global.selector "html" [ Tw.h_full, Tw.bg_gray_100, Tw.overflow_hidden ], Global.selector "body" [ Tw.h_full ] ]
    , Styles.global
    , if model.loaded then
        model.erd |> Maybe.mapOrElse (viewApp model "app") viewNotFound

      else
        viewLoader
    , Styled.lazy3 viewModal shared.zone shared.now model
    , Styled.lazy viewToasts model.toasts
    ]


viewApp : Model -> HtmlId -> Erd -> Styled.Html Msg
viewApp model htmlId erd =
    div [ class "tw-app" ]
        [ Lazy.lazy5 viewNavbar model.virtualRelation erd model.navbar (htmlId ++ "-nav") (model.openedDropdown |> String.filterStartsWith (htmlId ++ "-nav"))
        , Lazy.lazy7 viewErd model.screen erd model.cursorMode model.selectionBox model.virtualRelation model.openedDropdown model.dragging
        , Lazy.lazy5 viewCommands model.cursorMode erd.canvas.zoom (erd.tableProps |> Dict.isEmpty) (htmlId ++ "-commands") (model.openedDropdown |> String.filterStartsWith (htmlId ++ "-commands"))
        ]
        |> fromUnstyled


viewLoader : Styled.Html msg
viewLoader =
    div [ class "tw-loader flex justify-center items-center h-screen" ]
        [ div [ class ("animate-spin rounded-full h-32 w-32 border-t-2 border-b-2 " ++ border_500 Conf.theme.color) ] []
        ]
        |> fromUnstyled


viewNotFound : Styled.Html msg
viewNotFound =
    NotFound.simple Conf.theme
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
        |> fromUnstyled


viewModal : Time.Zone -> Time.Posix -> Model -> Styled.Html Msg
viewModal zone now model =
    Keyed.node "div"
        [ class "tw-modals" ]
        ([ model.confirm |> Maybe.map (\m -> ( m.id, viewConfirm (model.openedDialogs |> L.has m.id) m ))
         , model.newLayout |> Maybe.map (\m -> ( m.id, viewCreateLayout (model.openedDialogs |> L.has m.id) m ))
         , model.findPath |> Maybe.map2 (\e m -> ( m.id, viewFindPath (model.openedDialogs |> L.has m.id) e.tables e.settings.findPath m )) model.erd
         , model.settings |> Maybe.map2 (\e m -> ( m.id, viewProjectSettings zone (model.openedDialogs |> L.has m.id) e m )) model.erd
         , model.sourceUpload |> Maybe.map (\m -> ( m.id, viewSourceUpload zone now (model.openedDialogs |> L.has m.id) m ))
         , model.help |> Maybe.map (\m -> ( m.id, viewHelp (model.openedDialogs |> L.has m.id) m ))
         ]
            |> List.filterMap identity
            |> List.sortBy (\( id, _ ) -> model.openedDialogs |> L.indexOf id |> Maybe.withDefault 0 |> negate)
        )
        |> fromUnstyled


viewToasts : List Toast.Model -> Styled.Html Msg
viewToasts toasts =
    div [ class "tw-toasts" ] [ Toast.container Conf.theme toasts ToastHide ] |> fromUnstyled
