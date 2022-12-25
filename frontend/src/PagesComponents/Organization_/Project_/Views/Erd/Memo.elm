module PagesComponents.Organization_.Project_.Views.Erd.Memo exposing (viewMemo)

import Conf
import Html exposing (Attribute, Html, div, text)
import Html.Attributes exposing (class, id)
import Html.Events.Extra.Mouse exposing (Button(..))
import Libs.Bool as Bool
import Libs.Html.Events exposing (PointerEvent, stopPointerDown)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Platform exposing (Platform)
import Models.Area as Area
import PagesComponents.Organization_.Project_.Models exposing (Msg(..))
import PagesComponents.Organization_.Project_.Models.CursorMode as CursorMode exposing (CursorMode)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.Memo as Memo exposing (Memo)


viewMemo : Platform -> ErdConf -> CursorMode -> Memo -> Html Msg
viewMemo platform conf cursorMode memo =
    let
        htmlId : HtmlId
        htmlId =
            Memo.htmlId memo.id

        drag : List (Attribute Msg)
        drag =
            Bool.cond (cursorMode == CursorMode.Drag || not conf.move) [] [ stopPointerDown platform (handleMemoPointerDown htmlId) ]
    in
    div ([ id htmlId, class "select-none absolute bg-red-500" ] ++ Area.stylesGrid memo ++ drag)
        [ text memo.content
        ]


handleMemoPointerDown : HtmlId -> PointerEvent -> Msg
handleMemoPointerDown htmlId e =
    if e.button == MainButton then
        e |> .clientPos |> DragStart htmlId

    else if e.button == MiddleButton then
        e |> .clientPos |> DragStart Conf.ids.erd

    else
        Noop "No match on memo pointer down"
