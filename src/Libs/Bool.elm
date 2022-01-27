module Libs.Bool exposing (cond, lazyCond, maybe, toString)


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


lazyCond : Bool -> (() -> a) -> (() -> a) -> a
lazyCond predicate true false =
    if predicate then
        true ()

    else
        false ()


toString : Bool -> String
toString bool =
    case bool of
        True ->
            "True"

        False ->
            "False"
