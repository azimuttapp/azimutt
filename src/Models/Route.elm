module Models.Route exposing (Route, toHref, toUrl)

import Conf
import Dict exposing (Dict)
import Gen.Route as Gen
import Libs.String as String
import Url exposing (percentEncode)


type alias Route =
    { route : Gen.Route, query : Dict String String }


toHref : Route -> String
toHref route =
    let
        base : String
        base =
            Gen.toHref route.route |> String.stripRight "/"
    in
    if route.query |> Dict.isEmpty then
        base

    else
        base
            ++ "?"
            ++ (route.query
                    |> Dict.toList
                    |> List.sortBy Tuple.first
                    |> List.map (\( key, value ) -> key ++ "=" ++ percentEncode value)
                    |> String.join "&"
               )


toUrl : Route -> String
toUrl route =
    Conf.constants.azimuttWebsite ++ toHref route
