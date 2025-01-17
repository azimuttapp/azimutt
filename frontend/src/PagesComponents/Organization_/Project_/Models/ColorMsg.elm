module PagesComponents.Organization_.Project_.Models.ColorMsg exposing (ColorMsg(..))

import Libs.Tailwind exposing (Color)
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.TableId exposing (TableId)


type ColorMsg
    = CSave TableId (Maybe Color) (Maybe Color)
    | CApply TableId Color
    | CSet (List ( LayoutName, TableId, ( Color, Color ) ))
