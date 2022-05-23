module PagesComponents.Projects.Id_.Components.ProjectTeam exposing (Model, Msg(..), init, update, view)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Tooltip as Tooltip
import Html exposing (Html, br, div, img, input, label, p, text)
import Html.Attributes exposing (alt, class, disabled, for, id, name, placeholder, src, type_, value)
import Html.Events exposing (onClick, onInput)
import Libs.Html exposing (bText)
import Libs.Html.Attributes exposing (ariaDescribedby, css, role)
import Libs.Models.Email as Email
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind as Tw exposing (focus, sm)
import Models.User as User exposing (User)
import PagesComponents.Projects.Id_.Models.ProjectInfo exposing (ProjectInfo)
import Ports


type alias Model =
    { shareInput : String
    , shareUser : Maybe ( String, Maybe User )
    , owners : List User
    }


type Msg
    = ShareUpdate String
    | UpdateShareUser (Maybe ( String, Maybe User ))
    | UpdateOwners (List User)


init : Model
init =
    { shareInput = ""
    , shareUser = Nothing
    , owners = []
    }


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        ShareUpdate value ->
            ( { model | shareInput = value }, Cmd.none )

        UpdateShareUser value ->
            ( { model | shareUser = value }, Cmd.none )

        UpdateOwners value ->
            ( { model | owners = value }, Cmd.none )


view : (Cmd msg -> msg) -> (Msg -> msg) -> HtmlId -> User -> ProjectInfo -> Model -> Html msg
view send wrap htmlId user project model =
    div []
        [ shareWithForm send wrap htmlId model.shareInput model.shareUser model.owners project
        , listOwners send user model.owners project
        ]


shareWithForm : (Cmd msg -> msg) -> (Msg -> msg) -> HtmlId -> String -> Maybe ( String, Maybe User ) -> List User -> ProjectInfo -> Html msg
shareWithForm send wrap htmlId shareInput shareUser owners project =
    let
        ( inputId, descriptionId ) =
            ( htmlId ++ "-email", htmlId ++ "-email-description" )

        inputBorder : String
        inputBorder =
            if shareInput == "" || Email.isValid shareInput then
                "border-gray-300"

            else
                "border-red-300"

        inputIndicator : Html msg
        inputIndicator =
            if shareInput == "" || Email.isValid shareInput then
                div [] []

            else
                div [ class "absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none" ] [ Icon.solid ExclamationCircle "text-red-500" ]
    in
    div []
        [ label [ for inputId, class "block text-sm font-medium text-gray-700" ] [ text "Share with:" ]
        , div [ class "mt-1" ]
            [ div [ class "flex justify-between" ]
                [ div [ class "relative grow" ]
                    [ input
                        [ type_ "email"
                        , name "email"
                        , id inputId
                        , placeholder "you@example.com"
                        , ariaDescribedby descriptionId
                        , value shareInput
                        , onInput (ShareUpdate >> wrap)
                        , css [ "block w-full rounded-md shadow-sm", inputBorder, focus [ "ring-indigo-500 border-indigo-500" ], sm [ "text-sm" ] ]
                        ]
                        []
                    , inputIndicator
                    ]
                , if Email.isValid shareInput then
                    Button.primary3 Tw.emerald [ onClick (send (Ports.getUser shareInput)), class "ml-3 whitespace-nowrap" ] [ text "Search" ]

                  else
                    Button.primary3 Tw.emerald [ disabled True, class "ml-3 whitespace-nowrap" ] [ text "Search" ]
                ]
            ]
        , case shareUser of
            Nothing ->
                div [] []

            Just ( email, Nothing ) ->
                div [ class "py-3 text-red-500" ]
                    [ bText ("No user with email: " ++ email)
                    , br [] []
                    , bText "Please check email address or them to join Azimutt before if not done."
                    ]

            Just ( _, Just user ) ->
                div [ class "flex justify-between items-center" ]
                    [ showUser user
                    , if owners |> List.any (\u -> u.id == user.id) then
                        Button.primary3 Tw.emerald [ disabled True, class "ml-3 whitespace-nowrap" ] [ text "Already owner" ]

                      else
                        Button.primary3 Tw.emerald [ onClick (send (Ports.setOwners project.id ((owners |> List.map .id) ++ [ user.id ]))), class "ml-3 whitespace-nowrap" ] [ text "Add as owner" ]
                    ]
        , p [ class "mt-1 text-sm text-gray-500", id descriptionId ]
            [ text "Use email to share project ownership with other people."
            , br [] []
            , text "All owners have the same rights, they can add/remove owners but also delete the project!"
            , br [] []
            , text "Make sure you trust them!"
            ]
        ]


listOwners : (Cmd msg -> msg) -> User -> List User -> ProjectInfo -> Html msg
listOwners send user owners project =
    div [ class "mt-3" ]
        [ div [ class "text-sm font-semibold text-gray-800" ] [ text "Project owners:" ]
        , if owners == [] then
            div [ class "pl-6 pt-6 pb-7" ] [ Icon.loading "animate-spin" ]

          else
            div [ role "list", class "divide-y divide-gray-200" ]
                (owners
                    |> List.map
                        (\owner ->
                            div [ class "flex justify-between items-center" ]
                                [ showUser owner
                                , if user.id == owner.id then
                                    Button.primary1 Tw.red [ disabled True, class "ml-3 whitespace-nowrap" ] [ text "Remove" ] |> Tooltip.tl "You can't remove yourself"

                                  else
                                    Button.primary1 Tw.red [ onClick (send (Ports.setOwners project.id (owners |> List.map .id |> List.filter (\id -> id /= owner.id)))), class "ml-3 whitespace-nowrap" ] [ text "Remove" ]
                                ]
                        )
                )
        ]


showUser : User -> Html msg
showUser user =
    div [ class "py-4 flex" ]
        [ img [ class "h-10 w-10 rounded-full", src (user |> User.avatar), alt user.name ] []
        , div [ class "ml-3" ]
            [ p [ class "text-sm font-medium text-gray-900" ] [ text user.name ]
            , p [ class "text-sm text-gray-500" ] [ text user.email ]
            ]
        ]
