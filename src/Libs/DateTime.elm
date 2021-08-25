module Libs.DateTime exposing (format, human)

import Libs.String as S
import Time


format : String -> Time.Zone -> Time.Posix -> String
format pattern zone time =
    let
        date : DateTime
        date =
            buildDateTime zone time
    in
    pattern
        |> String.replace "yyyy" (String.fromInt date.year)
        |> String.replace "yy" (String.fromInt (modBy 100 date.year))
        |> String.replace "MMMMM" date.month.full
        |> String.replace "MMM" date.month.short
        |> String.replace "MM" (padLeft (String.fromInt date.month.num) 2 '0')
        |> String.replace "dd" (String.fromInt date.day)
        |> String.replace "HH" (padLeft (String.fromInt date.hour) 2 '0')
        |> String.replace "mm" (padLeft (String.fromInt date.minute) 2 '0')
        |> String.replace "ss" (padLeft (String.fromInt date.second) 2 '0')
        |> String.replace "SSS" (padLeft (String.fromInt date.millis) 3 '0')


human : Time.Posix -> Time.Posix -> String
human now date =
    let
        diff : Int
        diff =
            Time.posixToMillis date - Time.posixToMillis now
    in
    if abs diff < aSecond then
        "just now"

    else if abs diff < aMinute then
        "a few seconds" |> humanDirection diff

    else if abs diff < anHour then
        humanText diff aMinute "a minute" "minutes"

    else if abs diff < aDay then
        humanText diff anHour "an hour" "hours"

    else if abs diff < aMonth then
        humanText diff aDay "a day" "days"

    else if abs diff < aYear then
        humanText diff aMonth "a month" "months"

    else if abs diff < aDecade then
        humanText diff aYear "a year" "years"

    else if abs diff < aCentury then
        humanText diff aYear "a year" "years"

    else
        "a long time" |> humanDirection diff


humanText : Int -> Int -> String -> String -> String
humanText diff unit one many =
    S.plural (abs (round (toFloat diff / toFloat unit))) one one many |> humanDirection diff


humanDirection : Int -> String -> String
humanDirection diff text =
    if diff > 0 then
        "in " ++ text

    else
        text ++ " ago"


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


type alias DateTime =
    { year : Int, month : MonthFormat, day : Int, weekday : WeekdayFormat, hour : Int, minute : Int, second : Int, millis : Int }


type alias MonthFormat =
    { num : Int, short : String, full : String }


type alias WeekdayFormat =
    { num : Int, short : String, full : String }


buildDateTime : Time.Zone -> Time.Posix -> DateTime
buildDateTime zone date =
    { year = Time.toYear zone date
    , month = Time.toMonth zone date |> formatMonth
    , day = Time.toDay zone date
    , weekday = Time.toWeekday zone date |> formatWeekday
    , hour = Time.toHour zone date
    , minute = Time.toMinute zone date
    , second = Time.toSecond zone date
    , millis = Time.toMillis zone date
    }


formatMonth : Time.Month -> MonthFormat
formatMonth month =
    case month of
        Time.Jan ->
            { num = 1, short = "Jan", full = "January" }

        Time.Feb ->
            { num = 2, short = "Feb", full = "February" }

        Time.Mar ->
            { num = 3, short = "Mar", full = "March" }

        Time.Apr ->
            { num = 4, short = "Apr", full = "April" }

        Time.May ->
            { num = 5, short = "May", full = "May" }

        Time.Jun ->
            { num = 6, short = "Jun", full = "June" }

        Time.Jul ->
            { num = 7, short = "Jul", full = "July" }

        Time.Aug ->
            { num = 8, short = "Aug", full = "August" }

        Time.Sep ->
            { num = 9, short = "Sep", full = "September" }

        Time.Oct ->
            { num = 10, short = "Oct", full = "October" }

        Time.Nov ->
            { num = 11, short = "Nov", full = "November" }

        Time.Dec ->
            { num = 12, short = "Dec", full = "December" }


formatWeekday : Time.Weekday -> WeekdayFormat
formatWeekday day =
    case day of
        Time.Mon ->
            { num = 1, short = "Mon", full = "Monday" }

        Time.Tue ->
            { num = 2, short = "Tue", full = "Tuesday" }

        Time.Wed ->
            { num = 3, short = "Wed", full = "Wednesday" }

        Time.Thu ->
            { num = 4, short = "Thu", full = "Thursday" }

        Time.Fri ->
            { num = 5, short = "Fri", full = "Friday" }

        Time.Sat ->
            { num = 6, short = "Sat", full = "Saturday" }

        Time.Sun ->
            { num = 7, short = "Sun", full = "Sunday" }


padLeft : String -> Int -> Char -> String
padLeft text size char =
    if String.length text >= size then
        text

    else
        padLeft (String.cons char text) size char
