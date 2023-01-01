module Pages.Home_ exposing (Model, Msg, page)

import Components.Atoms.Link as Link
import Conf
import Gen.Params.Home_ exposing (Params)
import Gen.Route as Route
import Html exposing (text)
import Html.Attributes exposing (href)
import Libs.Models.Env as Env
import Libs.Tailwind as Tw
import Page
import Ports
import Request
import Shared


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared _ =
    Page.element
        { init = ( {}, Ports.trackPage "home" )
        , update = \_ model -> ( model, Cmd.none )
        , view =
            \_ ->
                { title = Conf.constants.defaultTitle
                , body =
                    [ Link.primary5 Tw.indigo [ href (Route.toHref Route.Projects) ] [ text "Open projects" ]
                    , text ("Env: " ++ Env.toString shared.conf.env)
                    ]
                }
        , subscriptions = \_ -> Sub.none
        }


type alias Model =
    {}


type alias Msg =
    ()
