module Libs.Url exposing (addQuery, buildQueryString, domain, empty, relative)

import Libs.Maybe as Maybe
import Url exposing (Url)


empty : Url
empty =
    { protocol = Url.Https, host = "", port_ = Nothing, path = "", query = Nothing, fragment = Nothing }


buildQueryString : List ( String, String ) -> String
buildQueryString params =
    params |> List.map (\( key, value ) -> key ++ "=" ++ Url.percentEncode value) |> String.join "&"


addQuery : String -> String -> Url -> Url
addQuery key value url =
    { url | query = (url.query |> Maybe.mapOrElse (\q -> q ++ "&") "") ++ (key ++ "=" ++ Url.percentEncode value) |> Just }


domain : Url -> String
domain url =
    let
        http : String
        http =
            case url.protocol of
                Url.Http ->
                    "http://"

                Url.Https ->
                    "https://"
    in
    addPort url.port_ (http ++ url.host)


relative : Url -> String
relative url =
    -- similar to Url.toString but without the host
    url.path
        |> addPrefixed "?" url.query
        |> addPrefixed "#" url.fragment



-- taken from Url.elm because they are not exported


addPort : Maybe Int -> String -> String
addPort maybePort starter =
    case maybePort of
        Nothing ->
            starter

        Just port_ ->
            starter ++ ":" ++ String.fromInt port_


addPrefixed : String -> Maybe String -> String -> String
addPrefixed prefix maybeSegment starter =
    case maybeSegment of
        Nothing ->
            starter

        Just segment ->
            starter ++ prefix ++ segment
