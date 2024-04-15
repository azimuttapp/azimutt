module Libs.Models.Bytes exposing (humanize)

import Libs.Basics exposing (prettyNumber)
import Libs.String exposing (pluralize)


humanize : Int -> String
humanize bytes =
    let
        fBytes : Float
        fBytes =
            toFloat bytes
    in
    if fBytes > po then
        (fBytes / po |> prettyNumber) ++ " Po"

    else if fBytes > to then
        (fBytes / to |> prettyNumber) ++ " To"

    else if fBytes > go then
        (fBytes / go |> prettyNumber) ++ " Go"

    else if fBytes > mo then
        (fBytes / mo |> prettyNumber) ++ " Mo"

    else if fBytes > ko then
        (fBytes / ko |> prettyNumber) ++ " Ko"

    else
        bytes |> pluralize "byte"


ko : Float
ko =
    -- bytes
    1024


mo : Float
mo =
    1024 * ko


go : Float
go =
    1024 * mo


to : Float
to =
    1024 * go


po : Float
po =
    1024 * to
