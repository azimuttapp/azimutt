module PagesComponents.Organization_.Project_.Models.MemoId exposing (MemoId, fromString, isHtmlId, toHtmlId, toString)

import Libs.Models.HtmlId exposing (HtmlId)


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


toHtmlId : MemoId -> HtmlId
toHtmlId id =
    htmlIdPrefix ++ String.fromInt id


isHtmlId : HtmlId -> Bool
isHtmlId id =
    id |> String.startsWith htmlIdPrefix
