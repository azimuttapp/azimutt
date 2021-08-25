module Libs.Nel exposing (Nel, any, filter, filterMap, filterZip, find, fromList, indexedMap, length, map, prepend, sortBy, toList, unique, uniqueBy, zipWith)

-- Nel: NonEmptyList

import Set


type alias Nel a =
    { head : a, tail : List a }


prepend : a -> Nel a -> Nel a
prepend a nel =
    Nel a (nel.head :: nel.tail)


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


filterMap : (a -> Maybe b) -> Nel a -> List b
filterMap f nel =
    nel |> toList |> List.filterMap f


filterZip : (a -> Maybe b) -> Nel a -> List ( a, b )
filterZip f nel =
    filterMap (\a -> f a |> Maybe.map (\b -> ( a, b ))) nel


any : (a -> Bool) -> Nel a -> Bool
any predicate nel =
    nel |> toList |> List.any predicate


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
