module PagesComponents.Create.Views exposing (title, view)

import Components.Atoms.Loader as Loader
import Html.Lazy as Lazy
import PagesComponents.Create.Models exposing (Model, Msg(..))
import Services.Toasts as Toasts
import View exposing (View)


title : String
title =
    "Creating project..."


view : Model -> View Msg
view model =
    { title = title, body = [ Loader.fullScreen, Lazy.lazy2 Toasts.view Toast model.toasts ] }
