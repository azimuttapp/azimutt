module Pages.Home_ exposing (Model, Msg, page)

import Components.Atoms.Link as Link
import Conf
import Gen.Params.Home_ exposing (Params)
import Gen.Route as Route
import Html exposing (text)
import Html.Attributes exposing (href)
import Libs.Tailwind as Tw
import Page
import Request
import Shared


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page _ _ =
    Page.element
        { init = ( {}, Cmd.none )
        , update = \_ model -> ( model, Cmd.none )
        , view =
            \_ ->
                { title = Conf.constants.defaultTitle
                , body = [ Link.primary5 Tw.indigo [ href (Route.toHref Route.Projects) ] [ text "Open projects" ] ]
                }
        , subscriptions = \_ -> Sub.none
        }


type alias Model =
    {}


type alias Msg =
    ()
