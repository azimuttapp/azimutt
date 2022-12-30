module PagesComponents.Organization_.Project_.Views.Erd.Memo exposing (viewMemo)

import Components.Atoms.Markdown as Markdown
import Conf
import Html exposing (Attribute, Html, div, textarea)
import Html.Attributes exposing (autofocus, class, id, name, placeholder, value)
import Html.Events exposing (onBlur, onInput)
import Html.Events.Extra.Mouse exposing (Button(..))
import Libs.Bool as Bool
import Libs.Html.Events exposing (PointerEvent, stopDoubleClick, stopPointerDown)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Platform exposing (Platform)
import Models.Area as Area
import PagesComponents.Organization_.Project_.Models exposing (MemoMsg(..), Msg(..))
import PagesComponents.Organization_.Project_.Models.CursorMode as CursorMode exposing (CursorMode)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.Memo exposing (Memo)
import PagesComponents.Organization_.Project_.Models.MemoId as MemoId


viewMemo : Platform -> ErdConf -> CursorMode -> Maybe String -> Memo -> Html Msg
viewMemo platform conf cursorMode edit memo =
    let
        htmlId : HtmlId
        htmlId =
            MemoId.toHtmlId memo.id

        drag : List (Attribute Msg)
        drag =
            Bool.cond (cursorMode == CursorMode.Drag || not conf.move) [] [ stopPointerDown platform (handleMemoPointerDown htmlId) ]
    in
    edit
        |> Maybe.map
            (\v ->
                textarea
                    ([ id htmlId
                     , name htmlId
                     , value v
                     , onInput (MUpdate >> MemoMsg)
                     , onBlur (MemoMsg MSave)
                     , autofocus True
                     , placeholder "Write any useful memo here!"
                     , class "absolute resize block rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                     ]
                        ++ Area.stylesGrid memo
                    )
                    []
            )
        |> Maybe.withDefault
            (div ([ id htmlId, class "select-none absolute p-1 cursor-pointer border border-transparent border-dashed hover:border-gray-300 hover:resize hover:overflow-auto", stopDoubleClick (MemoMsg (MEdit memo)) ] ++ Area.stylesGrid memo)
                [ div ([ class "w-full h-full" ] ++ drag) [ viewMarkdown memo.content ]
                ]
            )


viewMarkdown : String -> Html msg
viewMarkdown content =
    Markdown.prose "" content


handleMemoPointerDown : HtmlId -> PointerEvent -> Msg
handleMemoPointerDown htmlId e =
    if e.button == MainButton then
        e |> .clientPos |> DragStart htmlId

    else if e.button == MiddleButton then
        e |> .clientPos |> DragStart Conf.ids.erd

    else
        Noop "No match on memo pointer down"
