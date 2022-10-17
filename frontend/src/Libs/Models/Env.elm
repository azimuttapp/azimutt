module Libs.Models.Env exposing (Env(..), fromString, toString)


type Env
    = Dev
    | Staging
    | Prod


fromString : String -> Env
fromString value =
    case value of
        "dev" ->
            Dev

        "staging" ->
            Staging

        "prod" ->
            Prod

        _ ->
            Dev


toString : Env -> String
toString value =
    case value of
        Dev ->
            "Dev"

        Staging ->
            "Staging"

        Prod ->
            "Prod"
