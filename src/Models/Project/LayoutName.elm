module Models.Project.LayoutName exposing (LayoutName, fromString, toString)


type alias LayoutName =
    -- needs to be comparable to be in Dict key
    String


toString : LayoutName -> String
toString name =
    name


fromString : String -> LayoutName
fromString name =
    name
