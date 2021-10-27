module Models.Project.Comment exposing (Comment)

import Models.Project.Origin exposing (Origin)


type alias Comment =
    { text : String, origins : List Origin }
