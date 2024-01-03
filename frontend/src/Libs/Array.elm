module Libs.Array exposing (filterNot)

import Array exposing (Array)


filterNot : (a -> Bool) -> Array a -> Array a
filterNot predicate list =
    list |> Array.filter (\a -> not (predicate a))
