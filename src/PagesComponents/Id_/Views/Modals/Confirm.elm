module PagesComponents.Id_.Views.Modals.Confirm exposing (viewConfirm)

import Components.Molecules.Modal as Modal
import Html exposing (Html)
import PagesComponents.Id_.Models exposing (ConfirmDialog, Msg(..))


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
