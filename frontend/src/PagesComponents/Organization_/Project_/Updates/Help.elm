module PagesComponents.Organization_.Project_.Updates.Help exposing (Model, handleHelp)

import Conf
import Libs.Bool as B
import Libs.Task as T
import PagesComponents.Organization_.Project_.Models exposing (HelpDialog, HelpMsg(..), Msg(..))
import PagesComponents.Organization_.Project_.Models.Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
import Track


type alias Model x =
    { x | help : Maybe HelpDialog, erd : Maybe Erd }


handleHelp : HelpMsg -> Model x -> ( Model x, Extra Msg )
handleHelp msg model =
    case msg of
        HOpen section ->
            ( { model | help = Just { id = Conf.ids.helpDialog, openedSection = section } }, Extra.cmdL [ T.sendAfter 1 (ModalOpen Conf.ids.helpDialog), Track.docOpened "navbar_top" model.erd ] )

        HClose ->
            ( { model | help = Nothing }, Extra.none )

        HToggle section ->
            ( model |> setHelp (setOpenedSection (\s -> B.cond (s == section) "" section)), Extra.none )


setHelp : (h -> h) -> { item | help : Maybe h } -> { item | help : Maybe h }
setHelp transform item =
    { item | help = item.help |> Maybe.map transform }


setOpenedSection : (s -> s) -> { item | openedSection : s } -> { item | openedSection : s }
setOpenedSection transform item =
    { item | openedSection = item.openedSection |> transform }
