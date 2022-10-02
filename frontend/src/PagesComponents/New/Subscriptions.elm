module PagesComponents.New.Subscriptions exposing (subscriptions)

import Components.Molecules.Dropdown as Dropdown
import PagesComponents.New.Models exposing (Model, Msg(..))
import Ports


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch (Ports.onJsMessage JsMessage :: Dropdown.subs model DropdownToggle (Noop "dropdown already opened"))
