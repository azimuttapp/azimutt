module Libs.Json.Decode exposing (customDict, customNed, defaultField, defaultFieldDeep, errorToHtml, filter, map10, map11, map12, map9, matchOn, maybeField, maybeWithDefault, nel, tuple)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Libs.Maybe as M
import Libs.Ned as Ned exposing (Ned)
import Libs.Nel exposing (Nel)


filter : (a -> Bool) -> Decoder a -> Decoder a
filter predicate decoder =
    decoder
        |> Decode.andThen
            (\a ->
                if predicate a then
                    Decode.succeed a

                else
                    Decode.fail "Invalid predicate"
            )


tuple : Decoder a -> Decoder b -> Decoder ( a, b )
tuple aDecoder bDecoder =
    Decode.map2 Tuple.pair
        (Decode.index 0 aDecoder)
        (Decode.index 1 bDecoder)


customDict : (String -> comparable) -> Decode.Decoder a -> Decode.Decoder (Dict comparable a)
customDict buildKey decoder =
    Decode.dict decoder |> Decode.map (\d -> d |> Dict.toList |> List.map (\( k, a ) -> ( buildKey k, a )) |> Dict.fromList)


nel : Decode.Decoder a -> Decode.Decoder (Nel a)
nel decoder =
    Decode.oneOrMore Nel decoder


customNed : (String -> comparable) -> Decode.Decoder a -> Decode.Decoder (Ned comparable a)
customNed buildKey decoder =
    customDict buildKey decoder |> Decode.andThen (\d -> d |> Ned.fromDict |> M.mapOrElse Decode.succeed (Decode.fail "Non empty dict can't be empty"))


maybeField : String -> Decoder a -> Decoder (Maybe a)
maybeField field decoder =
    Decode.maybe (Decode.field field decoder)


maybeWithDefault : (a -> Decode.Decoder a) -> a -> Decode.Decoder a
maybeWithDefault decoder a =
    Decode.maybe (decoder a) |> Decode.map (Maybe.withDefault a)


defaultField : String -> Decoder a -> a -> Decoder a
defaultField name decoder default =
    maybeWithDefault (\_ -> Decode.field name decoder) default


defaultFieldDeep : String -> (a -> Decoder a) -> a -> Decoder a
defaultFieldDeep name decoder default =
    maybeWithDefault (\_ -> Decode.field name (decoder default)) default


matchOn : String -> (String -> Decoder a) -> Decoder a
matchOn field decode =
    Decode.field field Decode.string |> Decode.andThen decode


errorToHtml : Decode.Error -> String
errorToHtml error =
    "<pre>" ++ Decode.errorToString error ++ "</pre>"


map9 : (a -> b -> c -> d -> e -> f -> g -> h -> i -> value) -> Decode.Decoder a -> Decode.Decoder b -> Decode.Decoder c -> Decode.Decoder d -> Decode.Decoder e -> Decode.Decoder f -> Decode.Decoder g -> Decode.Decoder h -> Decode.Decoder i -> Decode.Decoder value
map9 callback da db dc dd de df dg dh di =
    Decode.map2 (\( ( a, b, c ), ( d, e, f ) ) ( g, h, i ) -> callback a b c d e f g h i)
        (Decode.map6 (\a b c d e f -> ( ( a, b, c ), ( d, e, f ) )) da db dc dd de df)
        (Decode.map3 (\g h i -> ( g, h, i )) dg dh di)


map10 : (a -> b -> c -> d -> e -> f -> g -> h -> i -> j -> value) -> Decode.Decoder a -> Decode.Decoder b -> Decode.Decoder c -> Decode.Decoder d -> Decode.Decoder e -> Decode.Decoder f -> Decode.Decoder g -> Decode.Decoder h -> Decode.Decoder i -> Decode.Decoder j -> Decode.Decoder value
map10 callback da db dc dd de df dg dh di dj =
    Decode.map2 (\( ( a, b, c ), ( d, e, f ) ) ( ( g, h ), ( i, j ) ) -> callback a b c d e f g h i j)
        (Decode.map6 (\a b c d e f -> ( ( a, b, c ), ( d, e, f ) )) da db dc dd de df)
        (Decode.map4 (\g h i j -> ( ( g, h ), ( i, j ) )) dg dh di dj)


map11 : (a -> b -> c -> d -> e -> f -> g -> h -> i -> j -> k -> value) -> Decode.Decoder a -> Decode.Decoder b -> Decode.Decoder c -> Decode.Decoder d -> Decode.Decoder e -> Decode.Decoder f -> Decode.Decoder g -> Decode.Decoder h -> Decode.Decoder i -> Decode.Decoder j -> Decode.Decoder k -> Decode.Decoder value
map11 callback da db dc dd de df dg dh di dj dk =
    Decode.map2 (\( ( a, b, c ), ( d, e, f ) ) ( ( g, h, i ), ( j, k ) ) -> callback a b c d e f g h i j k)
        (Decode.map6 (\a b c d e f -> ( ( a, b, c ), ( d, e, f ) )) da db dc dd de df)
        (Decode.map5 (\g h i j k -> ( ( g, h, i ), ( j, k ) )) dg dh di dj dk)


map12 : (a -> b -> c -> d -> e -> f -> g -> h -> i -> j -> k -> l -> value) -> Decode.Decoder a -> Decode.Decoder b -> Decode.Decoder c -> Decode.Decoder d -> Decode.Decoder e -> Decode.Decoder f -> Decode.Decoder g -> Decode.Decoder h -> Decode.Decoder i -> Decode.Decoder j -> Decode.Decoder k -> Decode.Decoder l -> Decode.Decoder value
map12 callback da db dc dd de df dg dh di dj dk dl =
    Decode.map2 (\( ( a, b, c ), ( d, e, f ) ) ( ( g, h, i ), ( j, k, l ) ) -> callback a b c d e f g h i j k l)
        (Decode.map6 (\a b c d e f -> ( ( a, b, c ), ( d, e, f ) )) da db dc dd de df)
        (Decode.map6 (\g h i j k l -> ( ( g, h, i ), ( j, k, l ) )) dg dh di dj dk dl)
