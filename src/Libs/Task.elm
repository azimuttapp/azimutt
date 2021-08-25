module Libs.Task exposing (send, sendAfter)

import Libs.Models exposing (Millis)
import Process
import Task


send : msg -> Cmd msg
send msg =
    Task.succeed msg |> Task.perform identity


sendAfter : Millis -> msg -> Cmd msg
sendAfter millis msg =
    Process.sleep (toFloat millis) |> Task.perform (always msg)


andThen : msg -> msg -> Cmd msg
andThen msg2 msg1 =
    Task.succeed msg1 |> Task.andThen (\_ -> Task.succeed msg2) |> Task.perform identity
