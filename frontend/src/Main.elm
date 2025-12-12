module Main exposing (..)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Exercises
import Games.Stopwatch as Stopwatch
import Html exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Time exposing (Posix)
import Url
import Url.Parser as UP exposing ((</>), (<?>))


type alias Model =
    { url : Url.Url
    , key : Nav.Key
    , route : Route
    , exercisesModel : Exercises.Model
    , stopwatchModel : Stopwatch.Model
    }


type Msg
    = UrlChanged Url.Url
    | LinkClicked Browser.UrlRequest
    | ExercisesMsg Exercises.Msg
    | StopwatchMsg Stopwatch.Msg


type Route
    = Home
    | ExercisesRoute
    | NotFound


type alias Flags =
    String


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map StopwatchMsg (Stopwatch.subscriptions model.stopwatchModel)
        , Sub.map ExercisesMsg (Exercises.subscriptions model.exercisesModel)
        ]


init : Flags -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        route =
            UP.parse routeParser url
                |> Maybe.withDefault NotFound

        ( exercisesModel, exercisesCmd ) =
            Exercises.init flags

        stopwatchModel =
            Stopwatch.init

        exercisesFetchOnStart =
            case route of
                ExercisesRoute ->
                    Cmd.none

                _ ->
                    Cmd.none
    in
    ( { url = url
      , key = key
      , route = route
      , exercisesModel = exercisesModel
      , stopwatchModel = stopwatchModel
      }
    , Cmd.batch
        [ Cmd.map ExercisesMsg exercisesCmd
        , exercisesFetchOnStart
        ]
    )


routeParser : UP.Parser (Route -> a) a
routeParser =
    UP.oneOf
        [ UP.map Home (UP.s "home")
        , UP.map ExercisesRoute (UP.s "exercises")
        , UP.map Home UP.top

        -- removed Game route from top-level routing; exercises and their games are handled in Exercises.elm
        ]


startGame : msg -> Html msg
startGame msg =
    Html.div []
        [ Html.button [ HE.onClick msg ] [ Html.text "Start" ] ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChanged newUrl ->
            let
                newRoute =
                    UP.parse routeParser newUrl
                        |> Maybe.withDefault NotFound

                exercisesFetchCmd =
                    case newRoute of
                        ExercisesRoute ->
                            Cmd.none

                        _ ->
                            Cmd.none
            in
            ( { model
                | url = newUrl
                , route = newRoute
              }
            , Cmd.batch [ exercisesFetchCmd ]
            )

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        ExercisesMsg subMsg ->
            let
                ( updatedExercisesModel, cmd ) =
                    Exercises.update subMsg model.exercisesModel
            in
            ( { model | exercisesModel = updatedExercisesModel }
            , Cmd.map ExercisesMsg cmd
            )

        StopwatchMsg subMsg ->
            let
                ( updatedStopwatch, cmd ) =
                    Stopwatch.update subMsg model.stopwatchModel
            in
            ( { model | stopwatchModel = updatedStopwatch }
            , Cmd.map StopwatchMsg cmd
            )


view : Model -> Browser.Document Msg
view model =
    { title = viewTitle model.route
    , body =
        [ Html.div [ HA.class "wrapper" ]
            [ viewHeader model.url.path
            , Html.main_ [ HA.class "content-container" ]
                [ viewRoute model
                ]
            , viewFooter
            ]
        ]
    }


viewTitle : Route -> String
viewTitle route =
    case route of
        Home ->
            "Home"

        ExercisesRoute ->
            "Exercises"

        NotFound ->
            "Page not found"


viewHeader : String -> Html Msg
viewHeader currentPath =
    Html.div [ HA.class "header-container" ]
        [ Html.header [ HA.class "header" ]
            [ Html.ul []
                [ Html.li [] [ viewLink "Home" "/home" currentPath ]
                , Html.li [] [ viewLink "Exercises" "/exercises" currentPath ]

                -- removed direct game link from top-level header; exercises page lists games
                ]
            ]
        ]


viewRoute : Model -> Html Msg
viewRoute model =
    case model.route of
        Home ->
            Html.div [] [ Html.text "You are at the home page" ]

        ExercisesRoute ->
            Html.map ExercisesMsg (Exercises.view model.exercisesModel)

        NotFound ->
            Html.div []
                [ Html.text "Page not found" ]


viewLink : String -> String -> String -> Html Msg
viewLink label path currentPath =
    let
        maybeUrl =
            Url.fromString ("http://localhost:8000" ++ path)

        isActive =
            path == currentPath
    in
    case maybeUrl of
        Just url ->
            Html.a
                [ HA.href path
                , HA.classList [ ( "active", isActive ) ]
                , HE.onClick (LinkClicked (Browser.Internal url))
                ]
                [ Html.text label ]

        Nothing ->
            Html.text ("Invalid Url: " ++ path)


viewFooter : Html Msg
viewFooter =
    Html.div [ HA.class "footer-container" ]
        [ Html.footer [ HA.class "footer" ] []
        ]
