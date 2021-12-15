module Libs.Nel exposing (Nel, any, append, filter, filterMap, filterNot, filterZip, find, fromList, has, indexedMap, length, map, merge, partition, prepend, sortBy, toList, unique, uniqueBy, zipWith)

-- Nel: NonEmptyList

import Libs.List as L
import Set


type alias Nel a =
    { head : a, tail : List a }


prepend : a -> Nel a -> Nel a
prepend a nel =
    Nel a (nel.head :: nel.tail)


append : a -> Nel a -> Nel a
append a { head, tail } =
    Nel head (tail ++ [ a ])


map : (a -> b) -> Nel a -> Nel b
map f xs =
    { head = f xs.head, tail = xs.tail |> List.map f }


indexedMap : (Int -> a -> b) -> Nel a -> Nel b
indexedMap f xs =
    { head = f 0 xs.head, tail = xs.tail |> List.indexedMap (\i a -> f (i + 1) a) }


find : (a -> Bool) -> Nel a -> Maybe a
find predicate nel =
    if predicate nel.head then
        Just nel.head

    else
        case nel.tail of
            [] ->
                Nothing

            head :: tail ->
                find predicate (Nel head tail)


filter : (a -> Bool) -> Nel a -> List a
filter predicate nel =
    nel |> toList |> List.filter predicate


filterNot : (a -> Bool) -> Nel a -> List a
filterNot predicate nel =
    nel |> toList |> List.filter (\a -> not (predicate a))


filterMap : (a -> Maybe b) -> Nel a -> List b
filterMap f nel =
    nel |> toList |> List.filterMap f


filterZip : (a -> Maybe b) -> Nel a -> List ( a, b )
filterZip f nel =
    filterMap (\a -> f a |> Maybe.map (\b -> ( a, b ))) nel


partition : (a -> Bool) -> Nel a -> ( List a, List a )
partition predicate nel =
    nel |> toList |> List.partition predicate


any : (a -> Bool) -> Nel a -> Bool
any predicate nel =
    nel |> toList |> List.any predicate


has : a -> Nel a -> Bool
has value nel =
    nel |> toList |> List.any (\a -> a == value)


length : Nel a -> Int
length nel =
    1 + List.length nel.tail


sortBy : (a -> comparable) -> Nel a -> Nel a
sortBy transform nel =
    nel |> toList |> List.sortBy transform |> fromList |> Maybe.withDefault nel


zipWith : (a -> b) -> Nel a -> Nel ( a, b )
zipWith transform nel =
    nel |> map (\a -> ( a, transform a ))


unique : Nel comparable -> Nel comparable
unique nel =
    uniqueBy identity nel


uniqueBy : (a -> comparable) -> Nel a -> Nel a
uniqueBy matcher nel =
    nel |> toList |> listUniqueBy matcher |> fromList |> Maybe.withDefault nel


listUniqueBy : (a -> comparable) -> List a -> List a
listUniqueBy matcher list =
    -- from Libs.List to avoid circular dependency :(
    list
        |> listZipWith matcher
        |> List.foldl
            (\( item, key ) ( res, set ) ->
                if set |> Set.member key then
                    ( res, set )

                else
                    ( item :: res, set |> Set.insert key )
            )
            ( [], Set.empty )
        |> Tuple.first
        |> List.reverse


listZipWith : (a -> b) -> List a -> List ( a, b )
listZipWith transform list =
    -- from Libs.List to avoid circular dependency :(
    list |> List.map (\a -> ( a, transform a ))


merge : (a -> comparable) -> (a -> a -> a) -> Nel a -> Nel a -> Nel a
merge getKey mergeValue l1 l2 =
    L.merge getKey mergeValue (l1 |> toList) (l2 |> toList) |> fromList |> Maybe.withDefault l1


toList : Nel a -> List a
toList xs =
    xs.head :: xs.tail


fromList : List a -> Maybe (Nel a)
fromList list =
    case list of
        head :: tail ->
            Just (Nel head tail)

        _ ->
            Nothing
