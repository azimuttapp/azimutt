module Pages.NotFound exposing (Model, Msg, page)

import Gen.Params.NotFound exposing (Params)
import Page
import Ports exposing (trackPage)
import Request exposing (Request)
import Shared
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page _ req =
    Page.element
        { init = init req
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Model =
    String


type alias Msg =
    ()


init : Request -> ( Model, Cmd Msg )
init req =
    ( req.url.path |> addPrefixed "?" req.url.query |> addPrefixed "#" req.url.fragment
    , trackPage "not-found"
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update _ model =
    ( model, Cmd.none )


view : Model -> View Msg
view model =
    View.placeholder ("Page not found " ++ model ++ ".")


addPrefixed : String -> Maybe String -> String -> String
addPrefixed prefix maybeSegment starter =
    case maybeSegment of
        Nothing ->
            starter

        Just segment ->
            starter ++ prefix ++ segment


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
