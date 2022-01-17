module Libs.Debug exposing (time, timeEnd, timed, timed1, timed2)


time : String -> a -> a
time tag a =
    Debug.log ("[elm-time] " ++ tag) () |> (\_ -> a)


timeEnd : String -> a -> a
timeEnd tag a =
    Debug.log ("[elm-time-end] " ++ tag) () |> (\_ -> a)


timed : String -> (() -> x) -> x
timed tag f =
    time tag () |> f |> timeEnd tag


timed1 : String -> (a -> x) -> a -> x
timed1 tag f a =
    time tag a |> f |> timeEnd tag


timed2 : String -> (a -> b -> x) -> a -> b -> x
timed2 tag f a b =
    time tag b |> f a |> timeEnd tag
