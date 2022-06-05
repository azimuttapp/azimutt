module Router exposing (login)

import Gen.Route as Route
import Libs.Models.Url as Url
import Url exposing (Url)


login : Url -> String
login redirect =
    let
        path : String
        path =
            Url.asString redirect
    in
    if path == "" then
        Route.toHref Route.Login

    else
        Route.toHref Route.Login ++ "?redirect=" ++ Url.percentEncode path
