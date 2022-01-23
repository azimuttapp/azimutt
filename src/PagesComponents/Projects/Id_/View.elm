module PagesComponents.Projects.Id_.View exposing (viewProject)

import Components.Atoms.Styles as Styles
import Components.Molecules.Toast as Toast
import Components.Slices.NotFound as NotFound
import Conf
import Css.Global as Global
import Gen.Route as Route
import Html.Styled exposing (Html, div)
import Html.Styled.Attributes exposing (class, css)
import Html.Styled.Keyed as Keyed
import Html.Styled.Lazy as Lazy
import Libs.List as L
import Libs.Maybe as Maybe
import Libs.Models.Color as Color
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Theme exposing (Theme)
import Libs.String as String
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


viewProject : Shared.Model -> Model -> List (Html Msg)
viewProject shared model =
    [ Global.global Tw.globalStyles
    , Global.global [ Global.selector "html" [ Tw.h_full, Tw.bg_gray_100, Tw.overflow_hidden ], Global.selector "body" [ Tw.h_full ] ]
    , Styles.global
    , if model.loaded then
        model.erd |> Maybe.mapOrElse (viewApp shared.theme model "app") (Lazy.lazy viewNotFound shared.theme)

      else
        viewLoader shared.theme
    , Lazy.lazy4 viewModal shared.theme shared.zone shared.now model
    , Lazy.lazy2 viewToasts shared.theme model.toasts
    ]


viewApp : Theme -> Model -> HtmlId -> Erd -> Html Msg
viewApp theme model htmlId erd =
    div [ class "tw-app" ]
        [ Lazy.lazy6 viewNavbar theme model.virtualRelation erd model.navbar (htmlId ++ "-nav") (model.openedDropdown |> String.filterStartsWith (htmlId ++ "-nav"))
        , Lazy.lazy3 viewErd theme model erd
        , Lazy.lazy5 viewCommands theme model.cursorMode erd.canvas.zoom (htmlId ++ "-commands") (model.openedDropdown |> String.filterStartsWith (htmlId ++ "-commands"))
        ]


viewLoader : Theme -> Html msg
viewLoader theme =
    div [ class "tw-loader", css [ Tw.flex, Tw.justify_center, Tw.items_center, Tw.h_screen ] ]
        [ div [ css [ Tw.animate_spin, Tw.rounded_full, Tw.h_32, Tw.w_32, Tw.border_t_2, Tw.border_b_2, Color.border theme.color 500 ] ] []
        ]


viewNotFound : Theme -> Html msg
viewNotFound theme =
    NotFound.simple theme
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


viewModal : Theme -> Time.Zone -> Time.Posix -> Model -> Html Msg
viewModal theme zone now model =
    Keyed.node "div"
        [ class "tw-modals" ]
        ([ model.confirm |> Maybe.map (\m -> ( m.id, viewConfirm (model.openedDialogs |> L.has m.id) m ))
         , model.newLayout |> Maybe.map (\m -> ( m.id, viewCreateLayout theme (model.openedDialogs |> L.has m.id) m ))
         , model.findPath |> Maybe.map2 (\e m -> ( m.id, viewFindPath theme (model.openedDialogs |> L.has m.id) e.tables e.settings.findPath m )) model.erd
         , model.settings |> Maybe.map2 (\e m -> ( m.id, viewProjectSettings zone (model.openedDialogs |> L.has m.id) e m )) model.erd
         , model.sourceUpload |> Maybe.map (\m -> ( m.id, viewSourceUpload theme zone now (model.openedDialogs |> L.has m.id) m ))
         , model.help |> Maybe.map (\m -> ( m.id, viewHelp theme (model.openedDialogs |> L.has m.id) m ))
         ]
            |> List.filterMap identity
            |> List.sortBy (\( id, _ ) -> model.openedDialogs |> L.indexOf id |> Maybe.withDefault 0 |> negate)
        )


viewToasts : Theme -> List Toast.Model -> Html Msg
viewToasts theme toasts =
    div [ class "tw-toasts" ] [ Toast.container theme toasts ToastHide ]
