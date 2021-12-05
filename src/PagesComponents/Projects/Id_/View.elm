module PagesComponents.Projects.Id_.View exposing (viewProject)

import Components.Slices.NotFound as NotFound
import Conf
import Css.Global as Global
import Gen.Route as Route
import Html.Styled exposing (Html, div, main_)
import Html.Styled.Attributes exposing (css)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.Theme exposing (Theme)
import Libs.Models.TwColor as TwColor exposing (TwColor(..), TwColorLevel(..), TwColorPosition(..))
import Models.Project exposing (Project)
import PagesComponents.Projects.Id_.Models exposing (Model, Msg)
import PagesComponents.Projects.Id_.Views.Navbar exposing (viewNavbar)
import Shared exposing (StoredProjects(..))
import Tailwind.Utilities as Tw


viewProject : Shared.Model -> Model -> List (Html Msg)
viewProject shared model =
    [ Global.global Tw.globalStyles
    , Global.global [ Global.selector "html" [ Tw.h_full, Tw.bg_gray_100 ], Global.selector "body" [ Tw.h_full ] ]
    , case shared.projects of
        Loading ->
            viewLoader shared.theme

        Loaded projects ->
            projects |> L.find (\p -> p.id == model.projectId) |> M.mapOrElse (viewApp shared.theme model projects) (viewNotFound shared.theme)
    ]


viewLoader : Theme -> Html msg
viewLoader theme =
    div [ css [ Tw.flex, Tw.justify_center, Tw.items_center, Tw.h_screen ] ]
        [ div [ css [ Tw.animate_spin, Tw.rounded_full, Tw.h_32, Tw.w_32, Tw.border_t_2, Tw.border_b_2, TwColor.render Border theme.color L500 ] ] []
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
            [ { url = Conf.constants.azimuttGithub ++ "/discussions", text = "Contact Support" }
            , { url = Conf.constants.azimuttTwitter, text = "Twitter" }
            , { url = Route.toHref Route.Blog, text = "Blog" }
            ]
        }


viewApp : Theme -> Model -> List Project -> Project -> Html Msg
viewApp theme model storedProjects project =
    div []
        [ viewNavbar theme model.openedDropdown storedProjects project model.navbar
        , viewContent theme project
        ]


viewContent : Theme -> Project -> Html msg
viewContent _ _ =
    main_ [ css [ Tw.border_4, Tw.border_dashed, Tw.border_gray_200, Tw.rounded_lg, Tw.h_96 ] ]
        [{- Replace with your content -}]
