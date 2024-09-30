module Pages.Organization_.Create exposing (Model, Msg, page)

import Gen.Params.Organization_.Create exposing (Params)
import Page
import PagesComponents.Create.Element as Element
import PagesComponents.Create.Models as Models
import Request
import Shared


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Element.init (Just req.params.organization) shared req


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg
