module Libs.Dict exposing (alter, count, find, fromIndexedList, fromListMap, fuse, getOrElse, getResult, nonEmpty, notMember)

import Dict exposing (Dict)


nonEmpty : Dict k a -> Bool
nonEmpty dict =
    not (Dict.isEmpty dict)


fromIndexedList : List a -> Dict Int a
fromIndexedList list =
    list |> List.indexedMap (\i a -> ( i, a )) |> Dict.fromList


fromListMap : (a -> comparable) -> List a -> Dict comparable a
fromListMap getKey list =
    list |> List.map (\item -> ( getKey item, item )) |> Dict.fromList


getOrElse : comparable -> a -> Dict comparable a -> a
getOrElse key default dict =
    dict |> Dict.get key |> Maybe.withDefault default


getResult : String -> Dict String a -> Result String a
getResult key dict =
    dict |> Dict.get key |> Result.fromMaybe ("Missing key '" ++ key ++ "'")


notMember : comparable -> Dict comparable v -> Bool
notMember key dict =
    case Dict.get key dict of
        Just _ ->
            False

        Nothing ->
            True


find : (comparable -> v -> Bool) -> Dict comparable v -> Maybe ( comparable, v )
find predicate dict =
    Dict.foldl
        (\k v acc ->
            case acc of
                Just _ ->
                    acc

                Nothing ->
                    if predicate k v then
                        Just ( k, v )

                    else
                        Nothing
        )
        Nothing
        dict


filterMap : (comparable -> a -> Maybe b) -> Dict comparable a -> Dict comparable b
filterMap f dict =
    dict |> Dict.toList |> List.filterMap (\( k, a ) -> f k a |> Maybe.map (\b -> ( k, b ))) |> Dict.fromList


filterZip : (comparable -> a -> Maybe b) -> Dict comparable a -> Dict comparable ( a, b )
filterZip f dict =
    dict |> Dict.toList |> List.filterMap (\( k, a ) -> f k a |> Maybe.map (\b -> ( k, ( a, b ) ))) |> Dict.fromList


count : (comparable -> a -> Bool) -> Dict comparable a -> Int
count predicate dict =
    dict
        |> Dict.foldl
            (\k v cpt ->
                if predicate k v then
                    cpt + 1

                else
                    cpt
            )
            0


alter : comparable -> (v -> v) -> Dict comparable v -> Dict comparable v
alter key transform dict =
    Dict.update key (Maybe.map transform) dict


fuse : (a -> a -> a) -> Dict comparable a -> Dict comparable a -> Dict comparable a
fuse mergeValue d1 d2 =
    Dict.merge Dict.insert (\k a1 a2 acc -> Dict.insert k (mergeValue a1 a2) acc) Dict.insert d1 d2 Dict.empty
