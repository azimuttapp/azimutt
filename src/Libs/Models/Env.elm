module Libs.Models.Env exposing (Env(..), fromString)


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
