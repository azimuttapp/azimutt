module Libs.Models exposing (Color, FileContent, FileName, FileUrl, HtmlId, Millis, SizeChange, Text, UID, ZoomDelta, ZoomLevel)

import Libs.Size exposing (Size)


type alias UID =
    String


type alias HtmlId =
    String


type alias Text =
    String


type alias FileName =
    String


type alias FileUrl =
    String


type alias FileContent =
    String


type alias ZoomLevel =
    Float


type alias ZoomDelta =
    Float


type alias SizeChange =
    { id : HtmlId, size : Size }


type alias Color =
    String


type alias Millis =
    Int
