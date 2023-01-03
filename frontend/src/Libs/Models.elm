module Libs.Models exposing (ErrorMessage, FileContent, FileLine, FileLineContent, Image, Link, ListIndex, Millis, SizeChange, Text, TrackEvent, TrackedLink, TweetText, TweetUrl, ZoomDelta)

import Libs.Models.Delta exposing (Delta)
import Libs.Models.FileLineIndex exposing (FileLineIndex)
import Libs.Models.HtmlId exposing (HtmlId)
import Models.Position as Position
import Models.Size as Size


type alias ErrorMessage =
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
    { id : HtmlId, position : Position.Viewport, size : Size.Viewport, seeds : Delta }


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


type alias TweetUrl =
    String


type alias TweetText =
    String
