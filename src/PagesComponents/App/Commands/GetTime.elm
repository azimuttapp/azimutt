module PagesComponents.App.Commands.GetTime exposing (getTime)

import PagesComponents.App.Models exposing (Msg(..))
import Task
import Time


getTime : Cmd Msg
getTime =
    Task.perform TimeChanged Time.now
