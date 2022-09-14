module Libs.Json.Decode exposing (customDict, customNed, defaultField, defaultFieldDeep, errorToHtml, errorToStringNoValue, filter, map10, map11, map12, map13, map17, map9, matchOn, maybeField, maybeWithDefault, nel, tuple)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Libs.Maybe as Maybe
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
    customDict buildKey decoder |> Decode.andThen (\d -> d |> Ned.fromDict |> Maybe.mapOrElse Decode.succeed (Decode.fail "Non empty dict can't be empty"))


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


errorToStringNoValue : Decode.Error -> String
errorToStringNoValue error =
    errorToStringNoValueInternal error []


errorToStringNoValueInternal : Decode.Error -> List String -> String
errorToStringNoValueInternal error context =
    case error of
        Decode.Field f err ->
            let
                isSimple : Bool
                isSimple =
                    case String.uncons f of
                        Nothing ->
                            False

                        Just ( char, rest ) ->
                            Char.isAlpha char && String.all Char.isAlphaNum rest

                fieldName : String
                fieldName =
                    if isSimple then
                        "." ++ f

                    else
                        "['" ++ f ++ "']"
            in
            errorToStringNoValueInternal err (fieldName :: context)

        Decode.Index i err ->
            let
                indexName : String
                indexName =
                    "[" ++ String.fromInt i ++ "]"
            in
            errorToStringNoValueInternal err (indexName :: context)

        Decode.OneOf errors ->
            case errors of
                [] ->
                    "Ran into a Json.Decode.oneOf with no possibilities"
                        ++ (case context of
                                [] ->
                                    "!"

                                _ ->
                                    " at json" ++ String.join "" (List.reverse context)
                           )

                [ err ] ->
                    errorToStringNoValueInternal err context

                _ ->
                    let
                        starter : String
                        starter =
                            case context of
                                [] ->
                                    "Json.Decode.oneOf"

                                _ ->
                                    "The Json.Decode.oneOf at json" ++ String.join "" (List.reverse context)

                        introduction : String
                        introduction =
                            starter ++ " failed in the following " ++ String.fromInt (List.length errors) ++ " ways:"
                    in
                    String.join "\n\n" (introduction :: List.indexedMap errorOneOf errors)

        Decode.Failure msg _ ->
            let
                introduction : String
                introduction =
                    case context of
                        [] ->
                            ""

                        _ ->
                            "Problem at '" ++ String.join "" (List.reverse context) ++ "': "
            in
            introduction ++ msg


errorOneOf : Int -> Decode.Error -> String
errorOneOf i error =
    "\n\n(" ++ String.fromInt (i + 1) ++ ") " ++ indent (errorToStringNoValue error)


indent : String -> String
indent str =
    String.join "\n    " (String.split "\n" str)


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


map13 : (a -> b -> c -> d -> e -> f -> g -> h -> i -> j -> k -> l -> m -> value) -> Decode.Decoder a -> Decode.Decoder b -> Decode.Decoder c -> Decode.Decoder d -> Decode.Decoder e -> Decode.Decoder f -> Decode.Decoder g -> Decode.Decoder h -> Decode.Decoder i -> Decode.Decoder j -> Decode.Decoder k -> Decode.Decoder l -> Decode.Decoder m -> Decode.Decoder value
map13 callback da db dc dd de df dg dh di dj dk dl dm =
    Decode.map3 (\( ( a, b, c ), ( d, e, f ) ) ( ( g, h, i ), ( j, k, l ) ) m -> callback a b c d e f g h i j k l m)
        (Decode.map6 (\a b c d e f -> ( ( a, b, c ), ( d, e, f ) )) da db dc dd de df)
        (Decode.map6 (\g h i j k l -> ( ( g, h, i ), ( j, k, l ) )) dg dh di dj dk dl)
        dm


map17 : (a -> b -> c -> d -> e -> f -> g -> h -> i -> j -> k -> l -> m -> n -> o -> p -> q -> value) -> Decode.Decoder a -> Decode.Decoder b -> Decode.Decoder c -> Decode.Decoder d -> Decode.Decoder e -> Decode.Decoder f -> Decode.Decoder g -> Decode.Decoder h -> Decode.Decoder i -> Decode.Decoder j -> Decode.Decoder k -> Decode.Decoder l -> Decode.Decoder m -> Decode.Decoder n -> Decode.Decoder o -> Decode.Decoder p -> Decode.Decoder q -> Decode.Decoder value
map17 callback da db dc dd de df dg dh di dj dk dl dm dn do dp dq =
    Decode.map3 (\( ( a, b, c ), ( d, e, f ) ) ( ( g, h, i ), ( j, k, l ) ) ( ( m, n, o ), ( p, q ) ) -> callback a b c d e f g h i j k l m n o p q)
        (Decode.map6 (\a b c d e f -> ( ( a, b, c ), ( d, e, f ) )) da db dc dd de df)
        (Decode.map6 (\g h i j k l -> ( ( g, h, i ), ( j, k, l ) )) dg dh di dj dk dl)
        (Decode.map5 (\m n o p q -> ( ( m, n, o ), ( p, q ) )) dm dn do dp dq)
