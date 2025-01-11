module PagesComponents.Organization_.Project_.Views.Modals.Modals exposing (view, viewConfirm, viewPrompt)

import Components.Molecules.Modal as Modal
import Html exposing (Html)
import Libs.Models.HtmlId exposing (HtmlId)
import PagesComponents.Organization_.Project_.Models exposing (ConfirmDialog, ModalDialog, Msg(..), PromptDialog)


view : Bool -> ModalDialog -> Html Msg
view opened model =
    let
        titleId : HtmlId
        titleId =
            model.id ++ "-title"
    in
    Modal.modal
        { id = model.id
        , titleId = titleId
        , isOpen = opened
        , onBackgroundClick = ModalClose CustomModalClose
        }
        [ model.content (ModalClose CustomModalClose) titleId ]


viewConfirm : Bool -> ConfirmDialog -> Html Msg
viewConfirm opened model =
    Modal.confirm
        { id = model.id
        , color = model.content.color
        , icon = model.content.icon
        , title = model.content.title
        , message = model.content.message
        , confirm = model.content.confirm
        , cancel = model.content.cancel
        , onConfirm = ModalClose (ConfirmAnswer True model.content.onConfirm)
        , onCancel = ModalClose (ConfirmAnswer False Cmd.none)
        }
        opened


viewPrompt : Bool -> PromptDialog -> Html Msg
viewPrompt opened model =
    Modal.prompt
        { id = model.id
        , color = model.content.color
        , icon = model.content.icon
        , title = model.content.title
        , message = model.content.message
        , placeholder = model.content.placeholder
        , value = model.input
        , multiline = model.content.multiline
        , onUpdate = PromptUpdate
        , confirm = model.content.confirm
        , cancel = model.content.cancel
        , onConfirm = ModalClose (PromptAnswer (model.content.onConfirm model.input))
        , onCancel = ModalClose (PromptAnswer Cmd.none)
        }
        opened
