module Pages.Home_ exposing (Model, Msg, page)

import Gen.Params.Home_ exposing (Params)
import Html.Styled as Styled
import Page
import PagesComponents.Home_.View exposing (viewHome)
import Ports exposing (activateTooltipsAndPopovers, trackPage)
import Request
import Shared
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model msg
page shared _ =
    Page.element
        { init = init
        , update = update
        , view = view shared
        , subscriptions = subscriptions
        }


type alias Model =
    ()


type alias Msg =
    ()


init : ( Model, Cmd msg )
init =
    ( (), Cmd.batch [ trackPage "home", activateTooltipsAndPopovers ] )


update : msg -> Model -> ( Model, Cmd msg )
update _ model =
    ( model, Cmd.none )


view : Shared.Model -> Model -> View msg
view shared _ =
    { title = "Azimutt - Explore your database schema"
    , body = viewHome shared |> List.map Styled.toUnstyled
    }


subscriptions : Model -> Sub msg
subscriptions _ =
    Sub.none
