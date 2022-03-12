module Pages.Blog.Slug_ exposing (Model, Msg, page)

import Conf
import Gen.Params.Blog.Slug_ exposing (Params)
import Gen.Route as Route
import Http
import Libs.Regex as Rgx
import Page
import PagesComponents.Blog.Slug.Models as Models exposing (Model(..))
import PagesComponents.Blog.Slug.Updates exposing (getArticle, parseContent)
import PagesComponents.Blog.Slug.View exposing (viewArticle)
import Ports
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


title : Model -> String
title model =
    case model of
        Loaded article ->
            article.title ++ " - Azimutt blog"

        _ ->
            "Azimutt blog - Explore your database schema"


init : String -> ( Model, Cmd Msg )
init slug =
    ( Loading
    , Cmd.batch
        [ Ports.setMeta
            { title = Just (title Loading)
            , description = Just Conf.constants.defaultDescription
            , canonical = Just (Route.Blog__Slug_ { slug = slug })
            , html = Just ""
            , body = Just ""
            }
        , Ports.trackPage "blog-article"
        , slug |> getArticle GotArticle
        ]
    )



-- UPDATE


type Msg
    = GotArticle String (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg _ =
    case msg of
        GotArticle slug (Ok content) ->
            case content |> parseContent slug of
                Ok article ->
                    ( Loaded article, Ports.setMeta { title = Just (title (Loaded article)), description = Just article.excerpt, canonical = Nothing, html = Nothing, body = Nothing } )

                Err err ->
                    ( BadContent err, Cmd.none )

        GotArticle _ (Err err) ->
            ( BadSlug err, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = title model, body = viewArticle model }
