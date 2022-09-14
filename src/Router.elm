module Router exposing (login)

import Conf
import Libs.Url as Url
import Url exposing (Url)


login : Url -> String
login redirect =
    let
        path : String
        path =
            Url.asString redirect
    in
    if path == "" then
        Conf.constants.loginUrl

    else
        Conf.constants.loginUrl ++ "?redirect=" ++ Url.percentEncode path
