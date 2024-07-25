module Models.UserRole exposing (UserRole(..), fromString, toString)


type UserRole
    = Owner
    | Writer
    | Reader


fromString : String -> Maybe UserRole
fromString value =
    case value of
        "owner" ->
            Just Owner

        "writer" ->
            Just Writer

        "reader" ->
            Just Reader

        _ ->
            Nothing


toString : UserRole -> String
toString value =
    case value of
        Owner ->
            "owner"

        Writer ->
            "writer"

        Reader ->
            "reader"
