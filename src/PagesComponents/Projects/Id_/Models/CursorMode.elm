module PagesComponents.Projects.Id_.Models.CursorMode exposing (CursorMode(..), fromString, toString)


type CursorMode
    = Drag
    | Select
    | Update


fromString : String -> CursorMode
fromString value =
    case value of
        "drag" ->
            Drag

        "select" ->
            Select

        "update" ->
            Update

        _ ->
            Drag


toString : CursorMode -> String
toString mode =
    case mode of
        Drag ->
            "drag"

        Select ->
            "select"

        Update ->
            "update"
