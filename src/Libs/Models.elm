module Libs.Models exposing (FileContent, FileLine, FileLineContent, Image, Link, ListIndex, Millis, SizeChange, Text, TrackEvent, TrackedLink, UID, ZoomDelta)

import Libs.Models.FileLineIndex exposing (FileLineIndex)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position exposing (Position)
import Libs.Models.Size exposing (Size)


type alias UID =
    String


type alias ListIndex =
    Int


type alias Text =
    String


type alias FileContent =
    String


type alias FileLineContent =
    String


type alias FileLine =
    { index : FileLineIndex, content : FileLineContent }


type alias ZoomDelta =
    Float


type alias SizeChange =
    { id : HtmlId, position : Position, size : Size, seeds : Position }


type alias Millis =
    Int


type alias Image =
    { src : String, alt : String }


type alias Link =
    { url : String, text : String }


type alias TrackEvent =
    { name : String, details : List ( String, String ), enabled : Bool }


type alias TrackedLink =
    { url : String, text : String, track : Maybe TrackEvent }
