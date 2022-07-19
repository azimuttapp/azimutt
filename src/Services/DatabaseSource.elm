module Services.DatabaseSource exposing (Model, Msg(..), Status(..), init, source, view)

import DataSources.DatabaseSchemaParser.DatabaseSchema exposing (DatabaseSchema)
import Html exposing (Html, div, img, input, span, text)
import Html.Attributes exposing (class, disabled, id, name, placeholder, src, type_, value)
import Html.Events exposing (onBlur, onInput)
import Http
import Libs.Html.Attributes exposing (css)
import Libs.Models.DatabaseUrl exposing (DatabaseUrl)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.String as String
import Libs.Tailwind as Tw exposing (focus)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId exposing (SourceId)


type alias Model =
    { source : Maybe Source
    , url : String
    , status : Status
    }


type Status
    = Pending
    | Fetching String
    | Error String
    | Success Source


source : Model -> Maybe Source
source model =
    case model.status of
        Success s ->
            Just s

        _ ->
            Nothing


type Msg
    = UpdateUrl DatabaseUrl
    | FetchSchema DatabaseUrl
    | GotSchema DatabaseUrl (Result Http.Error DatabaseSchema)
    | GotSchemaWithId DatabaseUrl (Result Http.Error DatabaseSchema) SourceId
    | DropSchema
    | CreateProject Source


init : Maybe Source -> Model
init src =
    { source = src
    , url = ""
    , status = Pending
    }


view : HtmlId -> Model -> Html Msg
view htmlId model =
    div [ class "mt-3" ]
        [ div [ class "flex rounded-md shadow-sm" ]
            [ span [ class "inline-flex items-center px-3 rounded-l-md border border-r-0 border-gray-300 bg-gray-50 text-gray-500 sm:text-sm" ] [ text "Database url" ]
            , input
                [ type_ "text"
                , id (htmlId ++ "-url")
                , name (htmlId ++ "-url")
                , placeholder "ex: postgres://<user>:<password>@<host>:<port>/<db_name>"
                , value model.url
                , disabled
                    (case model.status of
                        Fetching _ ->
                            True

                        _ ->
                            False
                    )
                , onInput UpdateUrl
                , onBlur (FetchSchema model.url)
                , css [ "flex-1 min-w-0 block w-full px-3 py-2 border-gray-300 rounded-none rounded-r-md sm:text-sm", focus [ "ring-indigo-500 border-indigo-500" ], Tw.disabled [ "bg-slate-50 text-slate-500 border-slate-200" ] ]
                ]
                []
            ]
        , case model.status of
            Pending ->
                div [] []

            Fetching url ->
                div [] [ text ("Fetching: " ++ url), img [ class "rounded-l-lg", src "/assets/images/illustrations/exploration.gif" ] [] ]

            Error err ->
                div [] [ text ("Error: " ++ err) ]

            Success src ->
                div []
                    [ text ("Got source " ++ src.name ++ ": " ++ (src.tables |> String.pluralizeD "table") ++ " and " ++ (src.relations |> String.pluralizeL "relation"))
                    ]
        ]
