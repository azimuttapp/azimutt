module Pages.Blog.Slug_ exposing (Model, Msg, page)

import Gen.Params.Blog.Slug_ exposing (Params)
import Html.Styled as Styled
import Http
import Libs.Regex as Rgx
import Libs.Result as R
import Page
import PagesComponents.Blog.Slug.Models as Models exposing (Model(..))
import PagesComponents.Blog.Slug.Updates exposing (getArticle, parseContent)
import PagesComponents.Blog.Slug.View exposing (viewArticle)
import Request
import Shared
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page _ req =
    Page.element
        { init = init (req.params.slug |> Rgx.replace "[^a-zA-Z0-9_-]" "-")
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- INIT


type alias Model =
    Models.Model


init : String -> ( Model, Cmd Msg )
init slug =
    ( Loading, slug |> getArticle GotArticle )



-- UPDATE


type Msg
    = GotArticle String (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg _ =
    case msg of
        GotArticle slug (Ok content) ->
            ( content |> parseContent slug |> R.fold BadContent Loaded, Cmd.none )

        GotArticle _ (Err err) ->
            ( BadSlug err, Cmd.none )



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
