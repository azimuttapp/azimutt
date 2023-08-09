module PagesComponents.Organization_.Project_.Views.Erd.Memo exposing (viewMemo)

import Components.Atoms.Markdown as Markdown
import Conf
import Html exposing (Attribute, Html, div, textarea)
import Html.Attributes exposing (autofocus, class, classList, id, name, placeholder, value)
import Html.Events exposing (onBlur, onInput)
import Html.Events.Extra.Mouse exposing (Button(..))
import Libs.Bool as Bool
import Libs.Html.Events exposing (PointerEvent, onContextMenu, onDblClick, onPointerDown, onPointerUp)
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Platform exposing (Platform)
import Libs.Tailwind as Tw
import Models.Area as Area
import Models.Position as Position
import Models.Size as Size
import PagesComponents.Organization_.Project_.Models exposing (MemoMsg(..), Msg(..))
import PagesComponents.Organization_.Project_.Models.CursorMode as CursorMode exposing (CursorMode)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.Memo exposing (Memo)
import PagesComponents.Organization_.Project_.Models.MemoId as MemoId
import PagesComponents.Organization_.Project_.Views.Modals.MemoContextMenu as MemoContextMenu


viewMemo : Platform -> ErdConf -> CursorMode -> Maybe String -> Memo -> Html Msg
viewMemo platform conf cursorMode edit memo =
    let
        htmlId : HtmlId
        htmlId =
            MemoId.toHtmlId memo.id

        dragAttrs : List (Attribute Msg)
        dragAttrs =
            Bool.cond (cursorMode == CursorMode.Drag || not conf.move) [] [ onPointerDown (handlePointerDown htmlId) platform ]

        resizeMemo : List (Attribute Msg)
        resizeMemo =
            Bool.cond (cursorMode == CursorMode.Drag || not conf.move) [] [ onPointerDown (\_ -> Noop "no drag on memo resize") platform ]
    in
    edit
        |> Maybe.map
            (\v ->
                div ([ id htmlId, class "absolute" ] ++ Position.stylesGrid memo.position)
                    [ textarea
                        ([ id (MemoId.toInputId memo.id)
                         , name (MemoId.toInputId memo.id)
                         , value v
                         , onInput (MEditUpdate >> MemoMsg)
                         , onBlur (MemoMsg MEditSave)
                         , autofocus True
                         , placeholder "Write any useful memo here!"
                         , class "resize block rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                         ]
                            ++ Size.stylesCanvas memo.size
                        )
                        []
                    ]
            )
        |> Maybe.withDefault
            (div
                ([ id htmlId
                 , onPointerUp (\e -> SelectItem htmlId (e.ctrl || e.shift)) platform
                 , class ("select-none absolute px-3 py-1 cursor-pointer overflow-hidden rounded border border-transparent border-dashed hover:border-gray-300 hover:resize hover:overflow-auto" ++ (memo.color |> Maybe.mapOrElse (\c -> " shadow " ++ Tw.bg_200 c) ""))
                 , classList [ ( "ring-2 " ++ Tw.ring_300 (memo.color |> Maybe.withDefault Tw.gray), memo.selected ) ]
                 ]
                    ++ Bool.cond conf.layout [ onDblClick (\_ -> MemoMsg (MEdit memo)) platform, onContextMenu (ContextMenuCreate (MemoContextMenu.view conf memo)) platform ] []
                    ++ Area.stylesGrid memo
                    ++ resizeMemo
                )
                [ div ([ class "w-full h-full" ] ++ dragAttrs) [ viewMarkdown memo.content ]
                ]
            )


viewMarkdown : String -> Html msg
viewMarkdown content =
    Markdown.prose "prose-img:pointer-events-none" content


handlePointerDown : HtmlId -> PointerEvent -> Msg
handlePointerDown htmlId e =
    if e.button == MainButton then
        e |> .clientPos |> DragStart htmlId

    else if e.button == MiddleButton then
        e |> .clientPos |> DragStart Conf.ids.erd

    else
        Noop "No match on memo pointer down"
