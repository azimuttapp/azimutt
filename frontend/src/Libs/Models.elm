module Libs.Models exposing (ErrorMessage, FileContent, Image, Link, ListIndex, Millis, SizeChange, Text, TweetText, TweetUrl, ZoomDelta)

import Libs.Models.Delta exposing (Delta)
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


type alias TweetUrl =
    String


type alias TweetText =
    String
