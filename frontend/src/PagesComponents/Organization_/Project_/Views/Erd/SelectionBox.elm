module PagesComponents.Organization_.Project_.Views.Erd.SelectionBox exposing (Model, view)

import Html exposing (Html, div)
import Libs.Html.Attributes exposing (css)
import Libs.Models.HtmlId exposing (HtmlId)
import Models.Area as Area


type alias Model =
    { area : Area.Canvas
    , previouslySelected : List HtmlId
    }


view : Model -> List (Html msg)
view model =
    [ div ([ css [ "absolute border-2 bg-opacity-25 z-max border-teal-400 bg-teal-400" ] ] ++ Area.styleTransformCanvas model.area) [] ]
