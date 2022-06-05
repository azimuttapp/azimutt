module Router exposing (login)

import Gen.Route as Route exposing (Route)


login : Route -> String
login redirect =
    if redirect == Route.Home_ then
        Route.toHref Route.Login

    else
        Route.toHref Route.Login ++ "?redirect=" ++ Route.toHref redirect
