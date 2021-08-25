module Libs.Json.Encode exposing (maybe, ned, nel, object, withDefault, withDefaultDeep)

import Json.Encode as Encode exposing (Value)
import Libs.Maybe as M
import Libs.Ned as Ned exposing (Ned)
import Libs.Nel as Nel exposing (Nel)


object : List ( String, Encode.Value ) -> Encode.Value
object attrs =
    Encode.object (attrs |> List.filter (\( _, value ) -> not (value == Encode.null)))


maybe : (a -> Value) -> Maybe a -> Value
maybe encoder value =
    value |> Maybe.map encoder |> Maybe.withDefault Encode.null


withDefault : (a -> Value) -> a -> a -> Value
withDefault encode default value =
    Just value |> M.filter (\v -> not (v == default)) |> maybe encode


withDefaultDeep : (a -> a -> Value) -> a -> a -> Value
withDefaultDeep encode default value =
    Just value |> M.filter (\v -> not (v == default)) |> maybe (encode default)


nel : (a -> Value) -> Nel a -> Encode.Value
nel encoder value =
    value |> Nel.toList |> Encode.list encoder


ned : (comparable -> String) -> (a -> Value) -> Ned comparable a -> Encode.Value
ned toKey encoder value =
    value |> Ned.toDict |> Encode.dict toKey encoder
