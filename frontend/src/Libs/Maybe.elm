module Libs.Maybe exposing (all, andThenZip, any, any2, filter, filterBy, filterNot, has, hasBy, isJust, mapOrElse, merge, onNothing, orElse, resultSeq, toList, toResult, toResultErr, when, zip, zip3)

import Libs.Bool as B


when : Bool -> a -> Maybe a
when p a =
    if p then
        Just a

    else
        Nothing


orElse : Maybe a -> Maybe a -> Maybe a
orElse other item =
    case ( item, other ) of
        ( Just a1, _ ) ->
            Just a1

        ( Nothing, res ) ->
            res


onNothing : (() -> Maybe a) -> Maybe a -> Maybe a
onNothing f item =
    case item of
        Just a ->
            Just a

        Nothing ->
            f ()


mapOrElse : (a -> b) -> b -> Maybe a -> b
mapOrElse f default maybe =
    maybe |> Maybe.map f |> Maybe.withDefault default


filter : (a -> Bool) -> Maybe a -> Maybe a
filter predicate maybe =
    maybe |> Maybe.andThen (\a -> B.cond (predicate a) maybe Nothing)


filterNot : (a -> Bool) -> Maybe a -> Maybe a
filterNot predicate maybe =
    maybe |> Maybe.andThen (\a -> B.cond (predicate a) Nothing maybe)


filterBy : (a -> b) -> b -> Maybe a -> Maybe a
filterBy transform value maybe =
    maybe |> filter (\a -> transform a == value)


all : (a -> Bool) -> Maybe a -> Bool
all predicate maybe =
    Maybe.map predicate maybe |> Maybe.withDefault True


any : (a -> Bool) -> Maybe a -> Bool
any predicate maybe =
    Maybe.map predicate maybe |> Maybe.withDefault False


any2 : (a -> b -> Bool) -> Maybe a -> Maybe b -> Bool
any2 predicate maybeA maybeB =
    Maybe.map2 predicate maybeA maybeB |> Maybe.withDefault False


has : a -> Maybe a -> Bool
has value maybe =
    maybe |> mapOrElse (\a -> a == value) False


hasBy : (a -> b) -> b -> Maybe a -> Bool
hasBy transform value maybe =
    maybe |> mapOrElse (\a -> transform a == value) False


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


merge : (a -> a -> a) -> Maybe a -> Maybe a -> Maybe a
merge mergeValue m1 m2 =
    m1 |> Maybe.map (\a1 -> m2 |> mapOrElse (mergeValue a1) a1) |> orElse m2


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


toResult : e -> Maybe a -> Result e a
toResult err maybe =
    case maybe of
        Just a ->
            Ok a

        Nothing ->
            Err err


toResultErr : a -> Maybe e -> Result e a
toResultErr value maybe =
    case maybe of
        Just a ->
            Err a

        Nothing ->
            Ok value
