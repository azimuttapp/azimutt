module Pages.Organization_.New exposing (Model, Msg, page)

import Gen.Params.Organization_.New exposing (Params)
import Page
import PagesComponents.New.Element as Element
import PagesComponents.New.Models as Models exposing (Msg)
import Request
import Shared


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Element.init (Just req.params.organization) shared req


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg
