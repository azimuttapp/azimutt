module PagesComponents.App.Commands.GetZone exposing (getZone)

import PagesComponents.App.Models exposing (Msg(..))
import Task
import Time


getZone : Cmd Msg
getZone =
    Task.perform ZoneChanged Time.here
