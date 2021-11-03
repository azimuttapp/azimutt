module Pages.Projects exposing (Model, Msg, page)

import Gen.Params.Projects exposing (Params)
import Gen.Route as Route
import Html.Styled as Styled exposing (Html, a, button, div, h1, img, nav, node, span, text)
import Html.Styled.Attributes exposing (alt, class, height, href, id, src, type_)
import Libs.Html.Styled.Attributes exposing (ariaLabel)
import Libs.Task exposing (send)
import Page
import PagesComponents.Helpers as Helpers
import Request
import Shared
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page _ _ =
    Page.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Model =
    {}


type Msg
    = ReplaceMe



-- INIT


init : ( Model, Cmd Msg )
init =
    ( {}, send ReplaceMe )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReplaceMe ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> View Msg
view _ =
    { title = "Azimutt - Explore your database schema"
    , body =
        Helpers.rootStyled
            [ node "style" [] [ text "body { background-color: var(--bg-light); }" ]
            , viewNavbar
            , viewProjects
            ]
            |> List.map Styled.toUnstyled
    }


viewNavbar : Html msg
viewNavbar =
    nav [ id "navbar", class "navbar navbar-expand-md navbar-light bg-white shadow-sm" ]
        [ div [ class "container-fluid" ]
            [ a [ href (Route.toHref Route.Home_), class "navbar-brand" ]
                [ img [ src "/logo.png", alt "Azimutt logo", height 24, class "d-inline-block align-text-top" ] []
                , text " Azimutt"
                ]
            , button [ type_ "button", class "navbar-toggler", ariaLabel "Toggle navigation" ]
                [ span [ class "navbar-toggler-icon" ] []
                ]
            ]
        ]


viewProjects : Html msg
viewProjects =
    div [ class "container bg-white rounded-3 shadow-sm mt-3 p-3" ]
        [ h1 [] [ text "Projects" ]
        ]
