module PagesComponents.Organization_.Project_.Models.LinkLayoutId exposing (LinkLayoutId, fromHtmlId, fromString, toHtmlId, toString)

import Libs.Models.HtmlId exposing (HtmlId)
import Libs.String as String


type alias LinkLayoutId =
    Int


toString : LinkLayoutId -> String
toString id =
    String.fromInt id


fromString : String -> Maybe LinkLayoutId
fromString id =
    String.toInt id


htmlIdPrefix : HtmlId
htmlIdPrefix =
    "az-link-"


isHtmlId : HtmlId -> Bool
isHtmlId id =
    id |> String.startsWith htmlIdPrefix


toHtmlId : LinkLayoutId -> HtmlId
toHtmlId id =
    htmlIdPrefix ++ String.fromInt id


fromHtmlId : HtmlId -> Maybe LinkLayoutId
fromHtmlId id =
    if isHtmlId id then
        id |> String.stripLeft htmlIdPrefix |> String.toInt

    else
        Nothing
