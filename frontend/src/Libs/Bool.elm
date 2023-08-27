module Libs.Bool exposing (cond, fromString, lazyCond, list, maybe, toString)


cond : Bool -> a -> a -> a
cond predicate true false =
    if predicate then
        true

    else
        false


maybe : Bool -> a -> Maybe a
maybe predicate a =
    if predicate then
        Just a

    else
        Nothing


list : a -> Bool -> List a
list a predicate =
    if predicate then
        [ a ]

    else
        []


lazyCond : Bool -> (() -> a) -> (() -> a) -> a
lazyCond predicate true false =
    if predicate then
        true ()

    else
        false ()


fromString : String -> Maybe Bool
fromString value =
    case value of
        "True" ->
            Just True

        "False" ->
            Just False

        "true" ->
            Just True

        "false" ->
            Just False

        _ ->
            Nothing


toString : Bool -> String
toString bool =
    case bool of
        True ->
            "True"

        False ->
            "False"
