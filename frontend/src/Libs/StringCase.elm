module Libs.StringCase exposing (StringCase(..), compatibleCases, isCamelLower, isCamelUpper, isKebab, isSnakeLower, isSnakeUpper)

import Libs.Bool as Bool
import Libs.Regex as Regex


type StringCase
    = CamelUpper -- capitalize every word, ex: AzimuttIsAwesome
    | CamelLower -- capitalize every word except first, ex: azimuttIsAwesome
    | SnakeUpper -- all caps with words separated by _, ex: AZIMUTT_IS_AWESOME
    | SnakeLower -- only lowercase with words separated by _, ex: azimutt_is_awesome
    | Kebab -- lowercase with words separated by -, ex: azimutt-is-awesome


isCamelUpper : String -> Bool
isCamelUpper text =
    text |> Regex.match "^([A-Z][a-z0-9]*)+$"


isCamelLower : String -> Bool
isCamelLower text =
    text |> Regex.match "^([a-z][a-z0-9]*)([A-Z][a-z0-9]*)*$"


isSnakeUpper : String -> Bool
isSnakeUpper text =
    text |> Regex.match "^([A-Z][A-Z0-9]*)(_[A-Z][A-Z0-9]*)*$"


isSnakeLower : String -> Bool
isSnakeLower text =
    text |> Regex.match "^([a-z][a-z0-9]*)(_[a-z][a-z0-9]*)*$"


isKebab : String -> Bool
isKebab text =
    text |> Regex.match "^([a-z][a-z0-9]*)(-[a-z][a-z0-9]*)*$"


compatibleCases : String -> List StringCase
compatibleCases text =
    [ Bool.maybe (isCamelUpper text) CamelUpper
    , Bool.maybe (isCamelLower text) CamelLower
    , Bool.maybe (isSnakeUpper text) SnakeUpper
    , Bool.maybe (isSnakeLower text) SnakeLower
    , Bool.maybe (isKebab text) Kebab
    ]
        |> List.filterMap identity
