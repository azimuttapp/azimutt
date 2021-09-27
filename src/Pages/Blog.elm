module Pages.Blog exposing (Model, Msg, page)

import Gen.Params.Blog exposing (Params)
import Gen.Route as Route
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
              , excerpt = "Illo sint voluptas. Error voluptates culpa eligendi. Hic vel totam vitae illo. Non aliquid explicabo necessitatibus unde. Sed exercitationem placeat consectetur nulla deserunt vel. Iusto corrupti dicta."
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
    , body = viewBlog model |> List.map Styled.toUnstyled
    }
