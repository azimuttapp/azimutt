module Libs.Result exposing (ap, ap3, ap4, ap5, bimap, fold, isOk, map6, partition, toErrMaybe)

import Libs.Nel as Nel exposing (Nel)


isOk : Result e a -> Bool
isOk result =
    case result of
        Ok _ ->
            True

        Err _ ->
            False


toErrMaybe : Result e a -> Maybe e
toErrMaybe result =
    case result of
        Ok _ ->
            Nothing

        Err e ->
            Just e


partition : List (Result e a) -> ( List e, List a )
partition list =
    list
        |> List.foldr
            (\result ( eList, aList ) ->
                case result of
                    Ok a ->
                        ( eList, a :: aList )

                    Err e ->
                        ( e :: eList, aList )
            )
            ( [], [] )


fold : (x -> b) -> (a -> b) -> Result x a -> b
fold onError onSuccess result =
    case result of
        Ok a ->
            onSuccess a

        Err x ->
            onError x


bimap : (x -> y) -> (a -> b) -> Result x a -> Result y b
bimap onError onSuccess result =
    case result of
        Ok a ->
            Ok (onSuccess a)

        Err x ->
            Err (onError x)


ap : (a1 -> a2 -> b) -> Result e a1 -> Result e a2 -> Result (Nel e) b
ap transform r1 r2 =
    apx (\a1 a2 -> transform a1 a2) r1 (r2 |> Result.mapError (\e -> Nel e []))


ap3 : (a1 -> a2 -> a3 -> b) -> Result e a1 -> Result e a2 -> Result e a3 -> Result (Nel e) b
ap3 transform r1 r2 r3 =
    apx (\a1 ( a2, a3 ) -> transform a1 a2 a3) r1 (ap (\a2 a3 -> ( a2, a3 )) r2 r3)


ap4 : (a1 -> a2 -> a3 -> a4 -> b) -> Result e a1 -> Result e a2 -> Result e a3 -> Result e a4 -> Result (Nel e) b
ap4 transform r1 r2 r3 r4 =
    apx (\a1 ( a2, a3, a4 ) -> transform a1 a2 a3 a4) r1 (ap3 (\a2 a3 a4 -> ( a2, a3, a4 )) r2 r3 r4)


ap5 : (a1 -> a2 -> a3 -> a4 -> a5 -> b) -> Result e a1 -> Result e a2 -> Result e a3 -> Result e a4 -> Result e a5 -> Result (Nel e) b
ap5 transform r1 r2 r3 r4 r5 =
    apx (\a1 ( ( a2, a3 ), ( a4, a5 ) ) -> transform a1 a2 a3 a4 a5) r1 (ap4 (\a2 a3 a4 a5 -> ( ( a2, a3 ), ( a4, a5 ) )) r2 r3 r4 r5)


apx : (a1 -> ax -> b) -> Result e a1 -> Result (Nel e) ax -> Result (Nel e) b
apx transform r1 rx =
    case ( r1, rx ) of
        ( Ok a1, Ok ax ) ->
            Ok (transform a1 ax)

        ( Err e1, Ok _ ) ->
            Err (Nel e1 [])

        ( Ok _, Err ex ) ->
            Err ex

        ( Err e1, Err ex ) ->
            Err (Nel e1 (ex |> Nel.toList))


map6 : (a -> b -> c -> d -> e -> f -> value) -> Result x a -> Result x b -> Result x c -> Result x d -> Result x e -> Result x f -> Result x value
map6 func ra rb rc rd re rf =
    Result.map2 (\( a, b, c ) ( d, e, f ) -> func a b c d e f)
        (Result.map3 (\a b c -> ( a, b, c )) ra rb rc)
        (Result.map3 (\d e f -> ( d, e, f )) rd re rf)
