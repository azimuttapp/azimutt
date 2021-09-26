module Libs.Dict exposing (fromListMap, get, getOrElse)

import Dict exposing (Dict)


fromListMap : (a -> comparable) -> List a -> Dict comparable a
fromListMap getKey list =
    list |> List.map (\item -> ( getKey item, item )) |> Dict.fromList


getOrElse : comparable -> a -> Dict comparable a -> a
getOrElse key default dict =
    dict |> Dict.get key |> Maybe.withDefault default


get : String -> Dict String a -> Result String a
get key dict =
    dict |> Dict.get key |> Result.fromMaybe ("Missing key '" ++ key ++ "'")


filterMap : (comparable -> a -> Maybe b) -> Dict comparable a -> Dict comparable b
filterMap f dict =
    dict |> Dict.toList |> List.filterMap (\( k, a ) -> f k a |> Maybe.map (\b -> ( k, b ))) |> Dict.fromList


filterZip : (comparable -> a -> Maybe b) -> Dict comparable a -> Dict comparable ( a, b )
filterZip f dict =
    dict |> Dict.toList |> List.filterMap (\( k, a ) -> f k a |> Maybe.map (\b -> ( k, ( a, b ) ))) |> Dict.fromList
