module Libs.Models.Url exposing (asString, empty)

import Url exposing (Url)


empty : Url
empty =
    { protocol = Url.Https, host = "", port_ = Nothing, path = "", query = Nothing, fragment = Nothing }


asString : Url -> String
asString url =
    -- similar to Url.toString but without the host
    url.path
        |> addPrefixed "?" url.query
        |> addPrefixed "#" url.fragment


addPrefixed : String -> Maybe String -> String -> String
addPrefixed prefix maybeSegment starter =
    case maybeSegment of
        Nothing ->
            starter

        Just segment ->
            starter ++ prefix ++ segment
