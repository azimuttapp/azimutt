module Components.Slices.LlmKey exposing (promptLlmKey)

import Components.Atoms.Icon as Icon
import Html exposing (br, p, text)
import Html.Attributes exposing (class)
import Libs.Html exposing (extLink)
import Libs.Tailwind as Tw
import Libs.Task as T
import Shared exposing (Prompt)


promptLlmKey : (Prompt msg -> String -> msg) -> (String -> msg) -> msg
promptLlmKey openPrompt updateLlmKey =
    openPrompt
        { color = Tw.blue
        , icon = Just Icon.Key
        , title = "OpenAI API Key"
        , message =
            p []
                [ text "Please enter your OpenAI API Key to use it within Azimutt."
                , br [] []
                , text "You can get it on "
                , extLink "https://platform.openai.com/api-keys" [ class "link" ] [ text "platform.openai.com/api-keys" ]
                , text "."
                ]
        , placeholder = ""
        , multiline = False
        , choices = []
        , confirm = "Save"
        , cancel = "Cancel"
        , onConfirm = updateLlmKey >> T.send
        }
        ""
