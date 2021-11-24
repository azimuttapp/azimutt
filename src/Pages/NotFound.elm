module Pages.NotFound exposing (Model, Msg, page)

import Components.Slices.NotFound as NotFound
import Conf exposing (constants)
import Css.Global as Global
import Gen.Params.NotFound exposing (Params)
import Gen.Route as Route
import Html.Styled as Styled exposing (Html)
import Page
import Ports exposing (trackPage)
import Request exposing (Request)
import Shared
import Tailwind.Utilities as Tw
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.element
        { init = init req
        , update = update
        , view = view shared
        , subscriptions = subscriptions
        }


type alias Model =
    String


type alias Msg =
    ()



-- INIT


init : Request -> ( Model, Cmd Msg )
init req =
    ( req.url.path |> addPrefixed "?" req.url.query |> addPrefixed "#" req.url.fragment
    , trackPage "not-found"
    )


addPrefixed : String -> Maybe String -> String -> String
addPrefixed prefix maybeSegment starter =
    case maybeSegment of
        Nothing ->
            starter

        Just segment ->
            starter ++ prefix ++ segment



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update _ model =
    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = "Page not found - Azimutt"
    , body = model |> viewNotFound shared |> List.map Styled.toUnstyled
    }


viewNotFound : Shared.Model -> Model -> List (Html msg)
viewNotFound shared _ =
    [ Global.global Tw.globalStyles
    , Global.global [ Global.selector "html" [ Tw.h_full ], Global.selector "body" [ Tw.h_full ] ]
    , NotFound.simple shared.theme
        { brand =
            { img = { src = "/logo.png", alt = "Azimutt" }
            , link = { url = Route.toHref Route.Home_, text = "Azimutt" }
            }
        , header = "404 error"
        , title = "Page not found."
        , message = "Sorry, we couldn't find the page you’re looking for."
        , link = { url = Route.toHref Route.Home_, text = "Go back home" }
        , footer =
            [ { url = constants.azimuttGithub ++ "/discussions", text = "Contact Support" }
            , { url = constants.azimuttTwitter, text = "Twitter" }
            , { url = Route.toHref Route.Blog, text = "Blog" }
            ]
        }
    ]
