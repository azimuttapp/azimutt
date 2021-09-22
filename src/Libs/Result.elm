module Libs.Result exposing (fold, map6)


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


map6 : (a -> b -> c -> d -> e -> f -> value) -> Result x a -> Result x b -> Result x c -> Result x d -> Result x e -> Result x f -> Result x value
map6 func ra rb rc rd re rf =
    Result.map2 (\( a, b, c ) ( d, e, f ) -> func a b c d e f)
        (Result.map3 (\a b c -> ( a, b, c )) ra rb rc)
        (Result.map3 (\d e f -> ( d, e, f )) rd re rf)
