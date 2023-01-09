module Libs.Time exposing (decode, encode, encodeIso, intervalToString, isZero, stringToInterval, zero)

import Iso8601
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Time
import Time.Extra exposing (Interval(..))


zero : Time.Posix
zero =
    Time.millisToPosix 0


isZero : Time.Posix -> Bool
isZero time =
    Time.posixToMillis time == 0


intervalToString : Interval -> String
intervalToString interval =
    case interval of
        Year ->
            "Year"

        Quarter ->
            "Quarter"

        Month ->
            "Month"

        Week ->
            "Week"

        Monday ->
            "Monday"

        Tuesday ->
            "Tuesday"

        Wednesday ->
            "Wednesday"

        Thursday ->
            "Thursday"

        Friday ->
            "Friday"

        Saturday ->
            "Saturday"

        Sunday ->
            "Sunday"

        Day ->
            "Day"

        Hour ->
            "Hour"

        Minute ->
            "Minute"

        Second ->
            "Second"

        Millisecond ->
            "Millisecond"


stringToInterval : String -> Maybe Interval
stringToInterval interval =
    case interval of
        "Year" ->
            Just Year

        "Quarter" ->
            Just Quarter

        "Month" ->
            Just Month

        "Week" ->
            Just Week

        "Monday" ->
            Just Monday

        "Tuesday" ->
            Just Tuesday

        "Wednesday" ->
            Just Wednesday

        "Thursday" ->
            Just Thursday

        "Friday" ->
            Just Friday

        "Saturday" ->
            Just Saturday

        "Sunday" ->
            Just Sunday

        "Day" ->
            Just Day

        "Hour" ->
            Just Hour

        "Minute" ->
            Just Minute

        "Second" ->
            Just Second

        "Millisecond" ->
            Just Millisecond

        _ ->
            Nothing


encode : Time.Posix -> Value
encode value =
    value |> Time.posixToMillis |> Encode.int


encodeIso : Time.Posix -> Value
encodeIso value =
    Iso8601.encode value


decode : Decode.Decoder Time.Posix
decode =
    Decode.oneOf
        [ Decode.int |> Decode.map Time.millisToPosix
        , Iso8601.decoder
        ]
