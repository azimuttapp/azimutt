module Pages.Projects exposing (Model, Msg, page)

import Effect exposing (Effect)
import Gen.Params.Projects exposing (Params)
import Gen.Route as Route
import Html exposing (Html, a, button, div, h1, img, nav, node, span, text)
import Html.Attributes exposing (alt, class, height, href, id, src, type_)
import Libs.Bootstrap exposing (bsToggleCollapse)
import Libs.Html.Attributes exposing (ariaLabel)
import Page
import PagesComponents.Containers as Containers
import Request
import Shared
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page _ _ =
    Page.advanced
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Model =
    {}


init : ( Model, Effect Msg )
init =
    ( {}, Effect.none )


type Msg
    = ReplaceMe


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        ReplaceMe ->
            ( model, Effect.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


view : Model -> View Msg
view _ =
    { title = "Azimutt - Explore your database schema"
    , body =
        Containers.root
            [ node "style" [] [ text "body { background-color: var(--bg-light); }" ]
            , viewNavbar
            , viewProjects
            ]
    }


viewNavbar : Html msg
viewNavbar =
    nav [ id "navbar", class "navbar navbar-expand-md navbar-light bg-white shadow-sm" ]
        [ div [ class "container-fluid" ]
            [ a [ href (Route.toHref Route.Home_), class "navbar-brand" ]
                [ img [ src "/logo.png", alt "Azimutt logo", height 24, class "d-inline-block align-text-top" ] []
                , text " Azimutt"
                ]
            , button ([ type_ "button", class "navbar-toggler", ariaLabel "Toggle navigation" ] ++ bsToggleCollapse "navbar-content")
                [ span [ class "navbar-toggler-icon" ] []
                ]
            ]
        ]


viewProjects : Html msg
viewProjects =
    div [ class "container bg-white rounded-3 shadow-sm mt-3 p-3" ]
        [ h1 [] [ text "Projects" ]
        ]
