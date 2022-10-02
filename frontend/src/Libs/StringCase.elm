module Libs.StringCase exposing (StringCase(..), compatibleCases)

import Libs.Bool as Bool
import Libs.Regex as Regex


type StringCase
    = CamelUpper -- capitalize every word, ex: AzimuttIsAwesome
    | CamelLower -- capitalize every word except first, ex: azimuttIsAwesome
    | SnakeUpper -- all caps with words separated by _, ex: AZIMUTT_IS_AWESOME
    | SnakeLower -- only lowercase with words separated by _, ex: azimutt_is_awesome
    | Kebab -- lowercase with words separated by -, ex: azimutt-is-awesome


compatibleCases : String -> List StringCase
compatibleCases text =
    [ Bool.maybe (text |> Regex.match "^([A-Z][a-z0-9]*)+$") CamelUpper
    , Bool.maybe (text |> Regex.match "^([a-z][a-z0-9]*)([A-Z][a-z0-9]*)*$") CamelLower
    , Bool.maybe (text |> Regex.match "^([A-Z][A-Z0-9]*)(_[A-Z][A-Z0-9]*)*$") SnakeUpper
    , Bool.maybe (text |> Regex.match "^([a-z][a-z0-9]*)(_[a-z][a-z0-9]*)*$") SnakeLower
    , Bool.maybe (text |> Regex.match "^([a-z][a-z0-9]*)(-[a-z][a-z0-9]*)*$") Kebab
    ]
        |> List.filterMap identity
