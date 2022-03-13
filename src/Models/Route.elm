module Models.Route exposing (Route, toHref, toUrl)

import Conf
import Dict exposing (Dict)
import Gen.Route as Gen
import Libs.String as String
import Url


type alias Route =
    { route : Gen.Route, query : Dict String String }


toHref : Route -> String
toHref route =
    Gen.toHref route.route ++ buildQueryString route.query


toUrl : Route -> String
toUrl route =
    ((Conf.constants.azimuttWebsite ++ Gen.toHref route.route) |> String.stripRight "/") ++ buildQueryString route.query


buildQueryString : Dict String String -> String
buildQueryString query =
    if query |> Dict.isEmpty then
        ""

    else
        "?"
            ++ (query
                    |> Dict.toList
                    |> List.sortBy Tuple.first
                    |> List.map (\( key, value ) -> key ++ "=" ++ Url.percentEncode value)
                    |> String.join "&"
               )
