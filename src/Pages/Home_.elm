module Pages.Home_ exposing (Model, Msg, page)

import Gen.Params.Home_ exposing (Params)
import Html.Styled as Styled
import Page
import PagesComponents.Home_.Models as Models exposing (Msg(..))
import PagesComponents.Home_.View exposing (viewHome)
import Ports exposing (JsMsg(..), onJsMessage, trackPage)
import Request
import Shared
import Time
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
    Models.Model


type alias Msg =
    Models.Msg



-- INIT


init : ( Model, Cmd msg )
init =
    ( { projects = [] }
    , Cmd.batch
        [ Ports.loadProjects
        , trackPage "home"
        ]
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        JsMessage message ->
            model |> handleJsMessage message


handleJsMessage : JsMsg -> Model -> ( Model, Cmd Msg )
handleJsMessage msg model =
    case msg of
        GotProjects ( _, projects ) ->
            ( { model | projects = projects |> List.sortBy (\p -> negate (Time.posixToMillis p.updatedAt)) }, Cmd.none )

        _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    onJsMessage JsMessage



-- VIEW


view : Model -> View msg
view model =
    { title = "Azimutt - Explore your database schema"
    , body = viewHome model |> List.map Styled.toUnstyled
    }
