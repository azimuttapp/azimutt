module PagesComponents.Organization_.Project_.Views.Erd.Memo exposing (viewMemo)

import Components.Atoms.Markdown as Markdown
import Conf
import Html exposing (Attribute, Html, div, textarea)
import Html.Attributes exposing (autofocus, class, id, name, placeholder, value)
import Html.Events exposing (onBlur, onInput)
import Html.Events.Extra.Mouse exposing (Button(..))
import Libs.Bool as Bool
import Libs.Html.Events exposing (PointerEvent, onContextMenu, stopDoubleClick, stopPointerDown)
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Platform exposing (Platform)
import Libs.Svg.Attributes as Attributes
import Libs.Tailwind as Tw
import Models.Area as Area
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

        drag : List (Attribute Msg)
        drag =
            Bool.cond (cursorMode == CursorMode.Drag || not conf.move) [] [ stopPointerDown platform (handleMemoPointerDown htmlId) ]
    in
    edit
        |> Maybe.map
            (\v ->
                div ([ id htmlId, class "absolute" ] ++ Area.stylesGrid memo)
                    [ textarea
                        [ id (MemoId.toInputId memo.id)
                        , name (MemoId.toInputId memo.id)
                        , value v
                        , onInput (MEditUpdate >> MemoMsg)
                        , onBlur (MemoMsg MEditSave)
                        , autofocus True
                        , placeholder "Write any useful memo here!"
                        , class "w-full h-full block rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                        ]
                        []
                    ]
            )
        |> Maybe.withDefault
            (div
                ([ id htmlId
                 , class ("select-none absolute p-1 cursor-pointer border border-transparent border-dashed hover:border-gray-300 hover:resize hover:overflow-auto" ++ (memo.color |> Maybe.mapOrElse (\c -> " shadow rounded " ++ Tw.bg_200 c) ""))
                 , Attributes.when conf.layout (onContextMenu platform (ContextMenuCreate (MemoContextMenu.view platform conf memo)))
                 , Attributes.when conf.update (stopDoubleClick (MemoMsg (MEdit memo)))
                 ]
                    ++ Area.stylesGrid memo
                )
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
