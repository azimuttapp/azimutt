module Libs.Models.Email exposing (Email, isValid)

import Libs.Regex as Regex


type alias Email =
    String


isValid : String -> Bool
isValid value =
    value |> Regex.match "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
