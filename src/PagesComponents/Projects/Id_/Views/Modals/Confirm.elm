module PagesComponents.Projects.Id_.Views.Modals.Confirm exposing (viewConfirm)

import Components.Molecules.Modal as Modal
import Html.Styled exposing (Html)
import PagesComponents.Projects.Id_.Models exposing (ConfirmDialog, Msg(..))


viewConfirm : Bool -> ConfirmDialog -> Html Msg
viewConfirm opened model =
    Modal.confirm
        { id = model.id
        , icon = model.content.icon
        , color = model.content.color
        , title = model.content.title
        , message = model.content.message
        , confirm = model.content.confirm
        , cancel = model.content.cancel
        , onConfirm = ModalClose (ConfirmAnswer True model.content.onConfirm)
        , onCancel = ModalClose (ConfirmAnswer False Cmd.none)
        }
        opened
