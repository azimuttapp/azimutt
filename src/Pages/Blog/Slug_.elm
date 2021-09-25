module Pages.Blog.Slug_ exposing (Model, Msg, page)

import Gen.Params.Blog.Slug_ exposing (Params)
import Html.Styled as Styled
import Libs.Task exposing (send)
import Page
import PagesComponents.Blog.Slug.Models as Models
import PagesComponents.Blog.Slug.View exposing (viewArticle)
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



-- INIT


type alias Model =
    Models.Model


init : ( Model, Cmd Msg )
init =
    ( {}, send ReplaceMe )



-- UPDATE


type Msg
    = ReplaceMe


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
view model =
    { title = "Azimutt article"
    , body = viewArticle model |> List.map Styled.toUnstyled
    }
