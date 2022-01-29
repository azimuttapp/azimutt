module PagesComponents.Projects.Id_.Updates.Help exposing (Model, handleHelp)

import Conf
import Libs.Bool as B
import Libs.Task as T
import PagesComponents.Projects.Id_.Models exposing (HelpDialog, HelpMsg(..), Msg(..))
import Ports
import Track


type alias Model x =
    { x | help : Maybe HelpDialog }


handleHelp : HelpMsg -> Model x -> ( Model x, Cmd Msg )
handleHelp msg model =
    case msg of
        HOpen section ->
            ( { model | help = Just { id = Conf.ids.helpDialog, openedSection = section } }, Cmd.batch [ T.sendAfter 1 (ModalOpen Conf.ids.helpDialog), Ports.track Track.openHelp ] )

        HClose ->
            ( { model | help = Nothing }, Cmd.none )

        HToggle section ->
            ( model |> setHelp (setOpenedSection (\s -> B.cond (s == section) "" section)), Cmd.none )


setHelp : (h -> h) -> { item | help : Maybe h } -> { item | help : Maybe h }
setHelp transform item =
    { item | help = item.help |> Maybe.map transform }


setOpenedSection : (s -> s) -> { item | openedSection : s } -> { item | openedSection : s }
setOpenedSection transform item =
    { item | openedSection = item.openedSection |> transform }
