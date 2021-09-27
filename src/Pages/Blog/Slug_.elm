module Pages.Blog.Slug_ exposing (Model, Msg, page)

import Gen.Params.Blog.Slug_ exposing (Params)
import Html.Styled as Styled
import Http
import Libs.Regex as Rgx
import Libs.Result as R
import Page
import PagesComponents.Blog.Slug.Models as Models exposing (Model(..))
import PagesComponents.Blog.Slug.Updates exposing (parseContent)
import PagesComponents.Blog.Slug.View exposing (viewArticle)
import Request
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



-- INIT


type alias Model =
    Models.Model


init : Request.With Params -> ( Model, Cmd Msg )
init req =
    ( Loading, getContent req.params.slug )


getContent : String -> Cmd Msg
getContent slug =
    Http.get { url = "/blog/" ++ (slug |> Rgx.replace "[^a-zA-Z0-9_-]" "-") ++ "/article.md", expect = Http.expectString GotContent }



-- UPDATE


type Msg
    = GotContent (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg _ =
    case msg of
        GotContent (Ok content) ->
            ( content |> parseContent |> R.fold BadContent Loaded, Cmd.none )

        GotContent (Err err) ->
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
