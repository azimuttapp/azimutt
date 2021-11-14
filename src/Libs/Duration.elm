module Libs.Duration exposing (Duration, days, millis, toMillis)


type Duration
    = Duration Int


millis : Int -> Duration
millis amount =
    Duration amount


days : Int -> Duration
days amount =
    Duration (amount * aDay)


toMillis : Duration -> Int
toMillis (Duration ms) =
    ms


aSecond : Int
aSecond =
    1000


aMinute : Int
aMinute =
    aSecond * 60


anHour : Int
anHour =
    aMinute * 60


aDay : Int
aDay =
    anHour * 24


aMonth : Int
aMonth =
    aDay * 30


aYear : Int
aYear =
    aDay * 365


aDecade : Int
aDecade =
    aYear * 10


aCentury : Int
aCentury =
    aYear * 100
