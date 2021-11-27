module Libs.FileInput exposing (DropConfig, File, hiddenInputSingle, onDrop)

-- variation of https://package.elm-lang.org/packages/mpizenberg/elm-file with Html.Styled.Attributes

import Html.Styled exposing (Attribute, Html, input)
import Html.Styled.Attributes as Attributes
import Html.Styled.Events as Events
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Time


type alias File =
    { value : Value
    , name : String
    , mime : String
    , size : Int
    , lastModified : Time.Posix
    }


type alias DropConfig msg =
    { onOver : File -> List File -> msg
    , onDrop : File -> List File -> msg
    , onLeave : Maybe { id : String, msg : msg }
    }


onDrop : DropConfig msg -> List (Attribute msg)
onDrop config =
    filesOn "dragover" config.onOver
        :: filesOn "drop" config.onDrop
        :: (case config.onLeave of
                Nothing ->
                    []

                Just { id, msg } ->
                    [ Attributes.id id
                    , onWithId id "dragleave" msg
                    ]
           )


hiddenInputSingle : String -> List String -> (File -> msg) -> Html msg
hiddenInputSingle id mimes msgTag =
    input (loadFile msgTag :: inputAttributes id mimes) []


filesOn : String -> (File -> List File -> msg) -> Attribute msg
filesOn event msgTag =
    Decode.at [ "dataTransfer", "files" ] multipleFilesDecoder
        |> Decode.map (\( file, list ) -> { message = msgTag file list, stopPropagation = True, preventDefault = True })
        |> Events.custom event


onWithId : String -> String -> msg -> Attribute msg
onWithId id event msg =
    Decode.at [ "target", "id" ] Decode.string
        |> Decode.andThen
            (\targetId ->
                if targetId == id then
                    Decode.succeed msg

                else
                    Decode.fail "Wrong target"
            )
        |> Decode.map (\message -> { message = message, stopPropagation = True, preventDefault = True })
        |> Events.custom event


multipleFilesDecoder : Decoder ( File, List File )
multipleFilesDecoder =
    dynamicListOf decoder
        |> Decode.andThen
            (\files ->
                case files of
                    file :: list ->
                        Decode.succeed ( file, list )

                    _ ->
                        Decode.succeed ( errorFile, [] )
            )


decoder : Decoder File
decoder =
    Decode.map5 File
        Decode.value
        (Decode.field "name" Decode.string)
        (Decode.field "type" Decode.string)
        (Decode.field "size" Decode.int)
        (Decode.map Time.millisToPosix (Decode.field "lastModified" Decode.int))


errorFile : File
errorFile =
    { value = Encode.null
    , name = "If you see this file, please report an error at https://github.com/mpizenberg/elm-files/issues"
    , mime = "text/plain"
    , size = 0
    , lastModified = Time.millisToPosix 0
    }


dynamicListOf : Decoder a -> Decoder (List a)
dynamicListOf itemDecoder =
    let
        decodeN : Int -> Decoder (List a)
        decodeN n =
            List.range 0 (n - 1)
                |> List.map decodeOne
                |> all

        decodeOne : Int -> Decoder a
        decodeOne n =
            Decode.field (String.fromInt n) itemDecoder
    in
    Decode.field "length" Decode.int
        |> Decode.andThen decodeN


all : List (Decoder a) -> Decoder (List a)
all =
    List.foldr (Decode.map2 (::)) (Decode.succeed [])


loadFile : (File -> msg) -> Attribute msg
loadFile msgTag =
    Decode.at [ "target", "files", "0" ] decoder
        |> Decode.map (\file -> { message = msgTag file, stopPropagation = True, preventDefault = True })
        |> Events.custom "change"


inputAttributes : String -> List String -> List (Attribute msg)
inputAttributes id mimes =
    [ Attributes.id id
    , Attributes.type_ "file"
    , Attributes.style "display" "none"
    , Attributes.accept (String.join "," mimes)
    ]
