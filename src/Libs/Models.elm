module Libs.Models exposing (Color, FileContent, FileLine, FileLineContent, FileLineIndex, FileModified, FileName, FileSize, FileUrl, HtmlId, Image, Link, Millis, SizeChange, Text, TrackEvent, TrackedLink, UID, ZoomDelta, ZoomLevel)

import Libs.Position exposing (Position)
import Libs.Size exposing (Size)
import Time


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


type alias FileSize =
    Int


type alias FileLineIndex =
    Int


type alias FileLineContent =
    String


type alias FileLine =
    { index : FileLineIndex, content : FileLineContent }


type alias FileModified =
    Time.Posix


type alias ZoomLevel =
    Float


type alias ZoomDelta =
    Float


type alias SizeChange =
    { id : HtmlId, position : Position, size : Size }


type alias Color =
    String


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
