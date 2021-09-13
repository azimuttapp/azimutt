module Libs.Bootstrap.Styled exposing (Toggle(..), bsToggle)

import Html.Styled exposing (Attribute)
import Html.Styled.Attributes exposing (attribute)


type Toggle
    = Alert
    | Tooltip
    | Dropdown
    | Modal
    | Collapse
    | Offcanvas


toggleName : Toggle -> String
toggleName toggle =
    case toggle of
        Alert ->
            "alert"

        Tooltip ->
            "tooltip"

        Dropdown ->
            "dropdown"

        Modal ->
            "modal"

        Collapse ->
            "collapse"

        Offcanvas ->
            "offcanvas"


bsToggle : Toggle -> Attribute msg
bsToggle kind =
    attribute "data-bs-toggle" (toggleName kind)
