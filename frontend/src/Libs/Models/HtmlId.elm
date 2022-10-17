module Libs.Models.HtmlId exposing (HtmlId, decode, encode, from)

import Url exposing (percentDecode, percentEncode)


type alias HtmlId =
    -- needs to be comparable to be in Dict key
    String


from : String -> HtmlId
from text =
    text |> String.toLower |> String.replace " " "-" |> percentEncode


encode : String -> HtmlId
encode text =
    text |> percentEncode


decode : String -> HtmlId
decode text =
    text |> percentDecode |> Maybe.withDefault text
