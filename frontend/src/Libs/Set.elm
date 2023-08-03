module Libs.Set exposing (toggle)

import Set exposing (Set)


toggle : comparable -> Set comparable -> Set comparable
toggle item list =
    if list |> Set.member item then
        list |> Set.remove item

    else
        list |> Set.insert item
