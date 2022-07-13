module PagesComponents.Id_.Views.Modals.Prompt exposing (viewPrompt)

import Components.Molecules.Modal as Modal
import Html exposing (Html)
import PagesComponents.Id_.Models exposing (Msg(..), PromptDialog)


viewPrompt : Bool -> PromptDialog -> Html Msg
viewPrompt opened model =
    Modal.prompt
        { id = model.id
        , color = model.content.color
        , icon = model.content.icon
        , title = model.content.title
        , message = model.content.message
        , placeholder = ""
        , value = model.input
        , onUpdate = PromptUpdate
        , confirm = model.content.confirm
        , cancel = model.content.cancel
        , onConfirm = ModalClose (PromptAnswer (model.content.onConfirm model.input))
        , onCancel = ModalClose (PromptAnswer Cmd.none)
        }
        opened
