module PagesComponents.App.Views.Graph exposing (viewGraph)

import Conf exposing (conf)
import Dict exposing (Dict)
import Html exposing (Html)
import Libs.DomInfo exposing (DomInfo)
import Libs.Models exposing (HtmlId)
import Libs.Size exposing (Size)
import Models.Project exposing (Schema, viewportSize)
import PagesComponents.App.Models exposing (Hover, Msg)
import TypedSvg exposing (svg)
import TypedSvg.Attributes exposing (id, viewBox)


viewGraph : Dict HtmlId DomInfo -> Maybe Schema -> Html Msg
viewGraph domInfos _ =
    let
        size : Size
        size =
            viewportSize domInfos |> Maybe.withDefault (Size 0 0)
    in
    svg [ viewBox 0 0 size.width size.height, id conf.ids.erd ] []
