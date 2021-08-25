module Libs.List exposing (addAt, addIf, appendOn, dropUntil, dropWhile, filterMap, filterZip, find, findBy, findIndex, findIndexBy, get, groupBy, has, hasNot, indexOf, last, memberBy, move, moveBy, nonEmpty, prependOn, resultCollect, resultSeq, unique, uniqueBy, updateBy, zipWith)

import Dict exposing (Dict)
import Libs.Bool as B
import Libs.Maybe as M
import Libs.Nel as Nel exposing (Nel)
import Random
import Set


get : Int -> List a -> Maybe a
get index list =
    list |> List.drop index |> List.head


last : List a -> Maybe a
last list =
    case list of
        [] ->
            Nothing

        [ a ] ->
            Just a

        _ :: tail ->
            last tail


nonEmpty : List a -> Bool
nonEmpty list =
    not (List.isEmpty list)


find : (a -> Bool) -> List a -> Maybe a
find predicate list =
    case list of
        [] ->
            Nothing

        first :: rest ->
            if predicate first then
                Just first

            else
                find predicate rest


findIndex : (a -> Bool) -> List a -> Maybe Int
findIndex =
    findIndexInner 0


findIndexInner : Int -> (a -> Bool) -> List a -> Maybe Int
findIndexInner index predicate list =
    case list of
        [] ->
            Nothing

        first :: rest ->
            if predicate first then
                Just index

            else
                findIndexInner (index + 1) predicate rest


findBy : (a -> b) -> b -> List a -> Maybe a
findBy matcher value list =
    find (\a -> matcher a == value) list


findIndexBy : (a -> b) -> b -> List a -> Maybe Int
findIndexBy matcher value list =
    findIndex (\a -> matcher a == value) list


memberBy : (a -> b) -> b -> List a -> Bool
memberBy matcher value list =
    findBy matcher value list |> M.isJust


indexOf : a -> List a -> Maybe Int
indexOf item xs =
    xs |> List.indexedMap (\i a -> ( i, a )) |> find (\( _, a ) -> a == item) |> Maybe.map Tuple.first


updateBy : (a -> b) -> b -> (a -> a) -> List a -> List a
updateBy matcher value transform list =
    list |> List.map (\a -> B.cond (matcher a == value) (transform a) a)


has : a -> List a -> Bool
has item xs =
    xs |> List.any (\a -> a == item)


hasNot : a -> List a -> Bool
hasNot item xs =
    not (has item xs)


filterZip : (a -> Maybe b) -> List a -> List ( a, b )
filterZip f xs =
    List.filterMap (\a -> f a |> Maybe.map (\b -> ( a, b ))) xs


filterMap : (a -> Bool) -> (a -> b) -> List a -> List b
filterMap predicate transform list =
    list |> List.foldr (\a res -> B.lazyCond (predicate a) (\_ -> transform a :: res) (\_ -> res)) []


move : Int -> Int -> List a -> List a
move from to list =
    list |> get from |> Maybe.map (\v -> list |> removeAt from |> addAt v to) |> Maybe.withDefault list


moveBy : (a -> b) -> b -> Int -> List a -> List a
moveBy matcher value position list =
    list |> findIndexBy matcher value |> Maybe.map (\index -> list |> move index position) |> Maybe.withDefault list


removeAt : Int -> List a -> List a
removeAt index list =
    list |> List.indexedMap (\i a -> ( i, a )) |> List.filter (\( i, _ ) -> not (i == index)) |> List.map (\( _, a ) -> a)


addAt : a -> Int -> List a -> List a
addAt item index list =
    if index >= List.length list then
        list ++ [ item ]

    else if index < 0 then
        item :: list

    else
        -- list |> List.indexedMap (\i a -> ( i, a )) |> List.concatMap (\( i, a ) -> B.cond (i == index) [ item, a ] [ a ])
        -- list |> List.foldl (\a ( res, i ) -> ( List.concat [ res, B.cond (i == index) [ item, a ] [ a ] ], i + 1 )) ( [], 0 ) |> Tuple.first
        list |> List.foldr (\a ( res, i ) -> ( B.cond (i == index) (item :: a :: res) (a :: res), i - 1 )) ( [], List.length list - 1 ) |> Tuple.first


addIf : Bool -> a -> List a -> List a
addIf predicate item list =
    if predicate then
        item :: list

    else
        list


prependOn : Maybe b -> (b -> a) -> List a -> List a
prependOn maybe transform list =
    case maybe of
        Just b ->
            transform b :: list

        Nothing ->
            list


appendOn : Maybe b -> (b -> a) -> List a -> List a
appendOn maybe transform list =
    case maybe of
        Just b ->
            list ++ [ transform b ]

        Nothing ->
            list


zipWith : (a -> b) -> List a -> List ( a, b )
zipWith transform list =
    list |> List.map (\a -> ( a, transform a ))


dropWhile : (a -> Bool) -> List a -> List a
dropWhile predicate list =
    case list of
        [] ->
            []

        x :: xs ->
            if predicate x then
                dropWhile predicate xs

            else
                list


dropUntil : (a -> Bool) -> List a -> List a
dropUntil predicate list =
    dropWhile (\a -> not (predicate a)) list


unique : List comparable -> List comparable
unique list =
    uniqueBy identity list


uniqueBy : (a -> comparable) -> List a -> List a
uniqueBy matcher list =
    list
        |> zipWith matcher
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


groupBy : (a -> comparable) -> List a -> Dict comparable (Nel a)
groupBy key list =
    List.foldr (\a dict -> dict |> Dict.update (key a) (\v -> v |> Maybe.map (Nel.prepend a) |> Maybe.withDefault (Nel a []) |> Just)) Dict.empty list


resultCollect : List (Result e a) -> ( List e, List a )
resultCollect list =
    List.foldr
        (\r ( errs, res ) ->
            case r of
                Ok a ->
                    ( errs, a :: res )

                Err e ->
                    ( e :: errs, res )
        )
        ( [], [] )
        list


resultSeq : List (Result e a) -> Result (List e) (List a)
resultSeq list =
    case resultCollect list of
        ( [], res ) ->
            Ok res

        ( errs, _ ) ->
            Err errs


genSeq : List (Random.Generator a) -> Random.Generator (List a)
genSeq generators =
    generators |> List.foldr (Random.map2 (::)) (Random.constant [])
