module Pages.Blog exposing (Model, Msg, page)

import Components.Slices.Blog exposing (Article)
import Conf
import Gen.Params.Blog exposing (Params)
import Gen.Route as Route
import Http
import Libs.Bool as B
import Libs.DateTime as DateTime
import Libs.Http exposing (errorToString)
import Libs.Nel as Nel exposing (Nel)
import Libs.Result as Result
import Page
import PagesComponents.Blog.Models as Models
import PagesComponents.Blog.Slug.Models exposing (Content)
import PagesComponents.Blog.Slug.Updates exposing (getArticle, parseContent)
import PagesComponents.Blog.View exposing (viewBlog)
import Ports
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



-- INIT


type alias Model =
    Models.Model


init : ( Model, Cmd Msg )
init =
    Conf.blogPosts
        |> (\slugs ->
                ( { articles = slugs |> List.map (\slug -> ( slug, buildInitArticle slug )) }
                , Cmd.batch
                    ([ Ports.setClasses { html = "", body = "" }
                     , Ports.trackPage "blog"
                     ]
                        ++ (slugs |> List.map (getArticle GotArticle))
                    )
                )
           )



-- UPDATE


type Msg
    = GotArticle String (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotArticle slug (Ok body) ->
            ( body
                |> parseContent slug
                |> Result.fold (buildBadArticle slug) (buildArticle slug)
                |> (\article -> updateArticle slug article model)
            , Cmd.none
            )

        GotArticle slug (Err err) ->
            ( model |> updateArticle slug (buildErrArticle slug err), Cmd.none )


defaultDate : Time.Posix
defaultDate =
    "2023-01-01" |> DateTime.unsafeParse


buildArticle : String -> Content -> Article
buildArticle slug content =
    { slug = slug
    , date = content.published
    , link = Route.toHref (Route.Blog__Slug_ { slug = slug })
    , title = content.title
    , excerpt = content.excerpt
    }


buildInitArticle : String -> Article
buildInitArticle slug =
    { slug = slug
    , date = defaultDate
    , link = "#"
    , title = "Loading " ++ slug
    , excerpt = "Loading..."
    }


buildBadArticle : String -> Nel String -> Article
buildBadArticle slug errors =
    { slug = slug
    , date = defaultDate
    , link = "#"
    , title = "Bad " ++ slug ++ " article"
    , excerpt = "Errors: " ++ (errors |> Nel.toList |> String.join ", ")
    }


buildErrArticle : String -> Http.Error -> Article
buildErrArticle slug error =
    { slug = slug
    , date = defaultDate
    , link = "#"
    , title = slug ++ " in error"
    , excerpt = errorToString error
    }


updateArticle : String -> Article -> Model -> Model
updateArticle slug article model =
    { model | articles = model.articles |> List.map (\( s, art ) -> B.cond (s == slug) ( s, article ) ( s, art )) }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "Azimutt blog - Explore your database schema"
    , body = viewBlog model
    }
