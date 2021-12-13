module Pages.Projects.Id_ exposing (Model, Msg, page)

import Browser.Events
import Components.Atoms.Icon exposing (Icon(..))
import Components.Molecules.Toast exposing (Content(..))
import Gen.Params.Projects.Id_ exposing (Params)
import Html.Events.Extra.Mouse as Mouse
import Html.Styled as Styled exposing (text)
import Json.Decode as Decode exposing (Decoder)
import Libs.Bool as B
import Libs.Json.Decode as D
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position as Position
import Libs.Models.TwColor exposing (TwColor(..))
import Libs.Task as T
import Models.Project.TableId as TableId
import Page
import PagesComponents.App.Updates.Helpers exposing (setProjectWithCmd, setTableProps)
import PagesComponents.Projects.Id_.Models as Models exposing (Msg(..), toastSuccess)
import PagesComponents.Projects.Id_.Updates.Table exposing (showTable)
import PagesComponents.Projects.Id_.View exposing (viewProject)
import Ports exposing (JsMsg(..))
import Request
import Shared
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.element
        { init = init shared req
        , update = update req
        , view = view shared
        , subscriptions = subscriptions
        }


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg



-- INIT


init : Shared.Model -> Request.With Params -> ( Model, Cmd Msg )
init shared req =
    ( { project = shared |> Shared.projects |> L.find (\p -> p.id == req.params.id)
      , navbar = { mobileMenuOpen = False, search = "" }
      , openedDropdown = ""
      , dragging = Nothing
      , toastIdx = 0
      , toasts = []
      , confirm = { color = Red, icon = X, title = "", message = text "", confirm = "", cancel = "", onConfirm = T.send Noop, isOpen = False }
      }
    , Cmd.none
    )



-- UPDATE


update : Request.With Params -> Msg -> Model -> ( Model, Cmd Msg )
update req msg model =
    case msg of
        ToggleMobileMenu ->
            ( { model | navbar = model.navbar |> (\n -> { n | mobileMenuOpen = not n.mobileMenuOpen }) }, Cmd.none )

        SearchUpdated search ->
            ( { model | navbar = model.navbar |> (\n -> { n | search = search }) }, Cmd.none )

        ShowTable id ->
            model |> setProjectWithCmd (showTable id)

        HideTable id ->
            ( model, T.send (toastSuccess ("HideTable: " ++ TableId.toString id)) )

        ResetCanvas ->
            ( model, T.send (toastSuccess "ResetCanvas") )

        ShowAllTables ->
            ( model, T.send (toastSuccess "ShowAllTables") )

        HideAllTables ->
            ( model, T.send (toastSuccess "HideAllTables") )

        LayoutMsg ->
            ( model, T.send (toastSuccess "LayoutMsg") )

        VirtualRelationMsg ->
            ( model, T.send (toastSuccess "VirtualRelationMsg") )

        FindPathMsg ->
            ( model, T.send (toastSuccess "FindPathMsg") )

        DropdownToggle id ->
            ( { model | openedDropdown = B.cond (model.openedDropdown == id) "" id }, Cmd.none )

        DragStart id pos ->
            ( { model | dragging = Just { id = id, init = pos, last = pos } }, Cmd.none )

        DragMove pos ->
            ( { model | dragging = model.dragging |> Maybe.map (\d -> { d | last = pos }) }, Cmd.none )

        DragEnd last ->
            ( model.dragging |> M.mapOrElse (\d -> { model | dragging = Nothing } |> setTableProps (TableId.fromHtmlId d.id) (\t -> { t | position = t.position |> Position.add (last |> Position.sub d.init) })) model, Cmd.none )

        ToastAdd millis toast ->
            model.toastIdx |> String.fromInt |> (\key -> ( { model | toastIdx = model.toastIdx + 1, toasts = { key = key, content = toast, isOpen = False } :: model.toasts }, T.sendAfter 1 (ToastShow millis key) ))

        ToastShow millis key ->
            ( { model | toasts = model.toasts |> List.map (\t -> B.cond (t.key == key) { t | isOpen = True } t) }, millis |> M.mapOrElse (\delay -> T.sendAfter delay (ToastHide key)) Cmd.none )

        ToastHide key ->
            ( { model | toasts = model.toasts |> List.map (\t -> B.cond (t.key == key) { t | isOpen = False } t) }, T.sendAfter 300 (ToastRemove key) )

        ToastRemove key ->
            ( { model | toasts = model.toasts |> List.filter (\t -> t.key /= key) }, Cmd.none )

        ConfirmOpen confirm ->
            ( { model | confirm = { confirm | isOpen = True } }, Cmd.none )

        ConfirmAnswer answer cmd ->
            ( { model | confirm = model.confirm |> (\c -> { c | isOpen = False }) }, B.cond answer cmd Cmd.none )

        JsMessage (GotProjects ( _, projects )) ->
            ( { model | project = projects |> L.find (\p -> p.id == req.params.id) }, Cmd.none )

        JsMessage _ ->
            ( model, Cmd.none )

        Noop ->
            ( model, T.send (toastSuccess "Noop") )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        ([ Ports.onJsMessage JsMessage ]
            ++ B.cond (model.openedDropdown == "") [] [ Browser.Events.onClick (targetIdDecoder |> Decode.map (\id -> B.cond (id == model.openedDropdown) Noop (DropdownToggle id))) ]
            ++ (model.dragging
                    |> M.mapOrElse
                        (\_ ->
                            [ Browser.Events.onMouseMove (Mouse.eventDecoder |> Decode.map (.pagePos >> Position.fromTuple >> DragMove))
                            , Browser.Events.onMouseUp (Mouse.eventDecoder |> Decode.map (.pagePos >> Position.fromTuple >> DragEnd))
                            ]
                        )
                        []
               )
        )


targetIdDecoder : Decoder HtmlId
targetIdDecoder =
    Decode.field "target"
        (Decode.oneOf
            [ Decode.at [ "id" ] Decode.string |> D.filter (\id -> id /= "")
            , Decode.at [ "parentElement", "id" ] Decode.string |> D.filter (\id -> id /= "")
            , Decode.at [ "parentElement", "parentElement", "id" ] Decode.string |> D.filter (\id -> id /= "")
            , Decode.at [ "parentElement", "parentElement", "parentElement", "id" ] Decode.string |> D.filter (\id -> id /= "")
            , Decode.succeed ""
            ]
        )



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = model.project |> M.mapOrElse (\p -> p.name ++ " - Azimutt") "Azimutt - Explore your database schema"
    , body = model |> viewProject shared |> List.map Styled.toUnstyled
    }
