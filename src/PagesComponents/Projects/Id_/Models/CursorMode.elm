module PagesComponents.Projects.Id_.Models.CursorMode exposing (CursorMode(..), fromString, toString)


type CursorMode
    = Drag
    | Select


fromString : String -> CursorMode
fromString value =
    case value of
        "drag" ->
            Drag

        "select" ->
            Select

        _ ->
            Drag


toString : CursorMode -> String
toString mode =
    case mode of
        Drag ->
            "drag"

        Select ->
            "select"
