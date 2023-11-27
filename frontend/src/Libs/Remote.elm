module Libs.Remote exposing (Remote(..), andThen, fold, map, map2, mapError, toList, toMaybe, toResult, withDefault)


type Remote error value
    = Pending
    | Fetching
    | Error error
    | Fetched value


map : (a -> b) -> Remote e a -> Remote e b
map f remote =
    case remote of
        Pending ->
            Pending

        Fetching ->
            Fetching

        Error e ->
            Error e

        Fetched a ->
            Fetched (f a)


andThen : (a -> Remote e b) -> Remote e a -> Remote e b
andThen f remote =
    case remote of
        Pending ->
            Pending

        Fetching ->
            Fetching

        Error e ->
            Error e

        Fetched value ->
            f value


mapError : (e -> f) -> Remote e a -> Remote f a
mapError f remote =
    case remote of
        Pending ->
            Pending

        Fetching ->
            Fetching

        Error e ->
            Error (f e)

        Fetched a ->
            Fetched a


map2 : (a -> b -> c) -> Remote e a -> Remote e b -> Remote e c
map2 f ra rb =
    ra |> andThen (\a -> rb |> map (\b -> f a b))


withDefault : a -> Remote e a -> a
withDefault default remote =
    case remote of
        Fetched a ->
            a

        _ ->
            default


fold : (() -> r) -> (() -> r) -> (e -> r) -> (a -> r) -> Remote e a -> r
fold pending fetching error fetched remote =
    case remote of
        Pending ->
            pending ()

        Fetching ->
            fetching ()

        Error e ->
            error e

        Fetched a ->
            fetched a


toMaybe : Remote e a -> Maybe a
toMaybe remote =
    case remote of
        Pending ->
            Nothing

        Fetching ->
            Nothing

        Error _ ->
            Nothing

        Fetched a ->
            Just a


toResult : e -> e -> Remote e a -> Result e a
toResult pendingErr fetchingErr remote =
    case remote of
        Pending ->
            Err pendingErr

        Fetching ->
            Err fetchingErr

        Error e ->
            Err e

        Fetched a ->
            Ok a


toList : Remote e a -> List a
toList remote =
    case remote of
        Pending ->
            []

        Fetching ->
            []

        Error _ ->
            []

        Fetched a ->
            [ a ]
