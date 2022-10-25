module Services.AmlSource exposing (Model, Msg, init, update, viewInput)

import Components.Molecules.InputText as InputText
import Html exposing (Html, div, label, p, text)
import Html.Attributes exposing (class, for)
import Libs.Html exposing (extLink)
import Libs.Models.HtmlId exposing (HtmlId)
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Random
import Time


type alias Model =
    { name : String
    , parsedSource : Maybe (Result String Source)
    }


type Msg
    = UpdateName String
    | BuildSource SourceId



-- INIT


init : Model
init =
    { name = ""
    , parsedSource = Nothing
    }



-- UPDATE


update : (Msg -> msg) -> Time.Posix -> Msg -> Model -> ( Model, Cmd msg )
update wrap now msg model =
    case msg of
        UpdateName name ->
            if name == "" then
                ( { model | name = name, parsedSource = Nothing }, Cmd.none )

            else if model.parsedSource == Nothing then
                ( { model | name = name }, SourceId.generator |> Random.generate (BuildSource >> wrap) )

            else
                ( { model | name = name, parsedSource = model.parsedSource |> Maybe.map (Result.map (\s -> { s | name = name })) }, Cmd.none )

        BuildSource id ->
            if model.name == "" then
                ( model, Cmd.none )

            else
                ( { model | parsedSource = Source.aml model.name now id |> Ok |> Just }, Cmd.none )



-- VIEW


viewInput : (Msg -> msg) -> HtmlId -> Model -> Html msg
viewInput wrap htmlId model =
    let
        fieldId : HtmlId
        fieldId =
            htmlId ++ "-layout"
    in
    div []
        [ p [ class "mt-1 text-sm text-gray-500" ]
            [ text "AML means "
            , extLink "https://github.com/azimuttapp/azimutt/blob/main/docs/aml/README.md" [ class "link" ] [ text "Azimutt Markup Language" ]
            , text ", it's our very simple language allowing you to define your own schema in Azimutt."
            ]
        , label [ for fieldId, class "mt-1 block text-sm font-medium text-gray-700" ] [ text "Source name" ]
        , div [ class "mt-1" ] [ InputText.simple fieldId "ex: feature-xyz" model.name (UpdateName >> wrap) ]
        ]
