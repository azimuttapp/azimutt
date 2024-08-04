module Models.Project.ColumnPath exposing (ColumnPath, ColumnPathStr, child, decode, decodeStr, dictGetI, encode, encodeStr, eqI, fromString, get, isRoot, merge, name, parent, root, rootName, separator, show, startsWith, toLower, toString, update, withName)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode
import Libs.Dict as Dict
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Nel as Nel exposing (Nel)
import Models.Project.ColumnName exposing (ColumnName)


type alias ColumnPath =
    -- for nested columns
    Nel ColumnName


type alias ColumnPathStr =
    -- used when `comparable` type is needed
    String


separator : String
separator =
    ":"


toLower : ColumnPath -> ColumnPath
toLower path =
    path |> Nel.map String.toLower


eqI : ColumnPath -> ColumnPath -> Bool
eqI p1 p2 =
    toLower p1 == toLower p2


dictGetI : ColumnPath -> Dict ColumnPathStr a -> Maybe a
dictGetI id dict =
    let
        str : ColumnPathStr
        str =
            toString id
    in
    (dict |> Dict.get str)
        |> Maybe.orElse (str |> String.toLower |> (\lowerStr -> dict |> Dict.find (\k _ -> String.toLower k == lowerStr)))


fromString : ColumnPathStr -> ColumnPath
fromString path =
    path |> String.split separator |> Nel.fromList |> Maybe.withDefault (Nel path [])


toString : ColumnPath -> ColumnPathStr
toString path =
    -- use `show` to display info instead
    path |> Nel.toList |> String.join separator


show : ColumnPath -> String
show path =
    path |> Nel.toList |> String.join "."


root : ColumnName -> ColumnPath
root n =
    Nel n []


withName : ColumnPath -> ColumnName -> String
withName column text =
    text ++ "." ++ show column


name : ColumnPath -> ColumnName
name { head, tail } =
    tail |> List.last |> Maybe.withDefault head


rootName : ColumnPath -> ColumnName
rootName { head } =
    head


parent : ColumnPath -> Maybe ColumnPath
parent path =
    path |> Nel.toList |> List.dropRight 1 |> Nel.fromList


child : ColumnName -> ColumnPath -> ColumnPath
child col path =
    path |> Nel.add col


isRoot : ColumnPath -> Bool
isRoot path =
    path.tail |> List.isEmpty


merge : ColumnPath -> ColumnPath -> ColumnPath
merge n1 _ =
    n1


startsWith : ColumnPath -> ColumnPath -> Bool
startsWith a b =
    b |> Nel.startsWith a


get : ColumnPath -> Dict ColumnPathStr a -> Maybe a
get path dict =
    dict |> Dict.get (toString path)


update : ColumnPath -> (Maybe a -> Maybe a) -> Dict ColumnPathStr a -> Dict ColumnPathStr a
update path transform dict =
    dict |> Dict.update (toString path) transform


encode : ColumnPath -> Value
encode value =
    value |> toString |> Encode.string


decode : Decoder ColumnPath
decode =
    Decode.string |> Decode.map fromString


encodeStr : ColumnPathStr -> Value
encodeStr value =
    value |> Encode.string


decodeStr : Decoder ColumnPathStr
decodeStr =
    Decode.string
