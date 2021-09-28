module Pages.Blog exposing (Model, Msg, page)

import Gen.Params.Blog exposing (Params)
import Gen.Route as Route
import Html exposing (div)
import Html.Attributes exposing (class)
import Html.Keyed as Keyed
import Html.Styled as Styled
import Libs.Task exposing (send)
import Page
import PagesComponents.Blog.Models as Models
import PagesComponents.Blog.View exposing (viewBlog)
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
    ( { articles =
            [ { date = { label = "Oct 01, 2021", formatted = "20201-10-01" }
              , link = Route.toHref (Route.Blog__Slug_ { slug = "the-story-behind-azimutt" })
              , title = "The story behind Azimutt"
              , excerpt = "I believe organizing information is at the heart of the software mission. I have been thinking about this for years and focused on understanding databases for 5 years now. Here is how it happened..."
              }
            , { date = { label = "Oct 01, 2021", formatted = "20201-10-01" }
              , link = Route.toHref (Route.Blog__Slug_ { slug = "the-story-behind-azimutt" })
              , title = "The story behind Azimutt"
              , excerpt = "I believe organizing information is at the heart of the software mission. I have been thinking about this for years and focused on understanding databases for 5 years now. Here is how it happened..."
              }
            , { date = { label = "Oct 01, 2021", formatted = "20201-10-01" }
              , link = Route.toHref (Route.Blog__Slug_ { slug = "the-story-behind-azimutt" })
              , title = "The story behind Azimutt"
              , excerpt = "I believe organizing information is at the heart of the software mission. I have been thinking about this for years and focused on understanding databases for 5 years now. Here is how it happened..."
              }
            , { date = { label = "Oct 01, 2021", formatted = "20201-10-01" }
              , link = Route.toHref (Route.Blog__Slug_ { slug = "the-story-behind-azimutt" })
              , title = "The story behind Azimutt"
              , excerpt = "I believe organizing information is at the heart of the software mission. I have been thinking about this for years and focused on understanding databases for 5 years now. Here is how it happened..."
              }
            ]
      }
    , send ReplaceMe
    )



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
    { title = "Azimutt blog"
    , body = [ Keyed.node "div" [] [ ( "blog", div [ class "blog-key" ] (viewBlog model |> List.map Styled.toUnstyled) ) ] ]
    }
