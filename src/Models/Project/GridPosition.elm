module Models.Project.GridPosition exposing (decode, encode)

import Conf
import Json.Decode as Decode exposing (Value)
import Libs.Models.Position as Position exposing (Position)



-- similar to Position but with grid constraints


encode : Position -> Value
encode value =
    value |> Position.stepBy Conf.canvas.grid |> Position.encode


decode : Decode.Decoder Position
decode =
    Position.decode |> Decode.map (Position.stepBy Conf.canvas.grid)
