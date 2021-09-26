module Libs.Result exposing (ap, fold, map6)

import Libs.Nel exposing (Nel)


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
    case ( r1, r2 ) of
        ( Ok a1, Ok a2 ) ->
            Ok (transform a1 a2)

        ( Err e1, Ok _ ) ->
            Err (Nel e1 [])

        ( Ok _, Err e2 ) ->
            Err (Nel e2 [])

        ( Err e1, Err e2 ) ->
            Err (Nel e1 [ e2 ])


map6 : (a -> b -> c -> d -> e -> f -> value) -> Result x a -> Result x b -> Result x c -> Result x d -> Result x e -> Result x f -> Result x value
map6 func ra rb rc rd re rf =
    Result.map2 (\( a, b, c ) ( d, e, f ) -> func a b c d e f)
        (Result.map3 (\a b c -> ( a, b, c )) ra rb rc)
        (Result.map3 (\d e f -> ( d, e, f )) rd re rf)
