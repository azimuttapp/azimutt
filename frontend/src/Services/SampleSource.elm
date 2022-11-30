module Services.SampleSource exposing (Model, Msg(..), init, update, viewParsing)

import Components.Molecules.Divider as Divider
import Html exposing (Html, div)
import Html.Attributes exposing (class)
import Json.Decode as Decode
import Json.Encode as Encode
import Libs.Task as T
import Models.OrganizationId as OrganizationId
import Models.Project exposing (Project)
import Ports
import Services.Backend exposing (Sample)
import Services.Lenses exposing (setProject)


type alias Model =
    { selectedSample : Maybe Sample
    , parsedProject : Maybe (Result Decode.Error Project)
    , project : Maybe (Result String Project)
    }


type Msg
    = GetSample Sample
    | GotProject (Maybe (Result Decode.Error Project))
    | BuildProject



-- INIT


init : Model
init =
    { selectedSample = Nothing
    , parsedProject = Nothing
    , project = Nothing
    }



-- UPDATE


update : (Msg -> msg) -> Msg -> Model -> ( Model, Cmd msg )
update wrap msg model =
    case msg of
        GetSample sample ->
            ( init |> (\m -> { m | selectedSample = Just sample })
            , Ports.getProject OrganizationId.zero sample.project_id
            )

        GotProject r ->
            ( { model | parsedProject = r |> Maybe.withDefault (Err (Decode.Failure "Missing project" Encode.null)) |> Just }
            , T.send (BuildProject |> wrap)
            )

        BuildProject ->
            model.parsedProject
                |> Maybe.andThen Result.toMaybe
                |> Maybe.map (\parsedProject -> ( model |> setProject (parsedProject |> Ok |> Just), Cmd.none ))
                |> Maybe.withDefault ( model, Cmd.none )



-- VIEW


viewParsing : Model -> Html msg
viewParsing model =
    model.selectedSample
        |> Maybe.map
            (\_ ->
                div []
                    [ div [ class "mt-6" ]
                        [ Divider.withLabel ((model.project |> Maybe.map (\_ -> "Loaded!")) |> Maybe.withDefault "Fetching...")
                        ]
                    ]
            )
        |> Maybe.withDefault (div [] [])
