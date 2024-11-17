module Libs.Set exposing (toggle)

import Set exposing (Set)


toggle : comparable -> Set comparable -> Set comparable
toggle item set =
    if set |> Set.member item then
        set |> Set.remove item

    else
        set |> Set.insert item
