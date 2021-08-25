module Libs.Maybe exposing (andThenZip, contains, exist, filter, isJust, orElse, resultSeq, toList, zip, zip3)

import Libs.Bool as B


orElse : Maybe a -> Maybe a -> Maybe a
orElse other item =
    case ( item, other ) of
        ( Just a1, _ ) ->
            Just a1

        ( Nothing, res ) ->
            res


filter : (a -> Bool) -> Maybe a -> Maybe a
filter predicate maybe =
    maybe |> Maybe.andThen (\a -> B.cond (predicate a) maybe Nothing)


exist : (a -> Bool) -> Maybe a -> Bool
exist predicate maybe =
    maybe |> Maybe.map predicate |> Maybe.withDefault False


contains : a -> Maybe a -> Bool
contains v maybe =
    maybe |> Maybe.map (\a -> a == v) |> Maybe.withDefault False


isNothing : Maybe a -> Bool
isNothing maybe =
    maybe == Nothing


isJust : Maybe a -> Bool
isJust maybe =
    not (isNothing maybe)


zip : Maybe a -> Maybe b -> Maybe ( a, b )
zip maybeA maybeB =
    Maybe.map2 (\a b -> ( a, b )) maybeA maybeB


zip3 : Maybe a -> Maybe b -> Maybe c -> Maybe ( a, b, c )
zip3 maybeA maybeB maybeC =
    Maybe.map3 (\a b c -> ( a, b, c )) maybeA maybeB maybeC


andThenZip : (a -> Maybe b) -> Maybe a -> Maybe ( a, b )
andThenZip f maybe =
    maybe |> Maybe.andThen (\a -> f a |> Maybe.map (\b -> ( a, b )))


fold : b -> (a -> b) -> Maybe a -> b
fold empty transform maybe =
    case maybe of
        Just a ->
            transform a

        Nothing ->
            empty


add : (a -> Maybe b) -> Maybe a -> Maybe ( a, b )
add get maybe =
    maybe |> Maybe.andThen (\a -> get a |> Maybe.map (\b -> ( a, b )))


resultSeq : Maybe (Result x a) -> Result x (Maybe a)
resultSeq maybe =
    case maybe of
        Just r ->
            r |> Result.map (\a -> Just a)

        Nothing ->
            Ok Nothing


tupleFirstSeq : b -> Maybe ( a, b ) -> ( Maybe a, b )
tupleFirstSeq default maybe =
    case maybe of
        Just ( a, b ) ->
            ( Just a, b )

        Nothing ->
            ( Nothing, default )


tupleSecondSeq : a -> Maybe ( a, b ) -> ( a, Maybe b )
tupleSecondSeq default maybe =
    case maybe of
        Just ( a, b ) ->
            ( a, Just b )

        Nothing ->
            ( default, Nothing )


toList : Maybe a -> List a
toList maybe =
    case maybe of
        Just a ->
            [ a ]

        Nothing ->
            []
