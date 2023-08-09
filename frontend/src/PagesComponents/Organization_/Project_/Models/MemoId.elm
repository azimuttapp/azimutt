module PagesComponents.Organization_.Project_.Models.MemoId exposing (MemoId, fromHtmlId, fromString, isHtmlId, toHtmlId, toInputId, toString)

import Libs.Models.HtmlId exposing (HtmlId)
import Libs.String as String


type alias MemoId =
    Int


toString : MemoId -> String
toString id =
    String.fromInt id


fromString : String -> Maybe MemoId
fromString id =
    String.toInt id


htmlIdPrefix : HtmlId
htmlIdPrefix =
    "az-memo-"


isHtmlId : HtmlId -> Bool
isHtmlId id =
    id |> String.startsWith htmlIdPrefix


toHtmlId : MemoId -> HtmlId
toHtmlId id =
    htmlIdPrefix ++ String.fromInt id


fromHtmlId : HtmlId -> Maybe MemoId
fromHtmlId id =
    if isHtmlId id then
        id |> String.stripLeft htmlIdPrefix |> String.toInt

    else
        Nothing


toInputId : MemoId -> HtmlId
toInputId id =
    htmlIdPrefix ++ String.fromInt id ++ "-input"
