module Main exposing (..)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Exercises.Stopwatch as Stopwatch
import Html exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Pages.Exercises as Exercises
import Pages.Login as Login
import Time exposing (Posix)
import Url
import Url.Parser as UP exposing ((</>), (<?>))


type alias Model =
    { url : Url.Url
    , key : Nav.Key
    , route : Route
    , exercisesModel : Exercises.Model
    , loginModel : Login.Model
    , stopwatchModel : Stopwatch.Model
    }


type Msg
    = UrlChanged Url.Url
    | LinkClicked Browser.UrlRequest
    | ExercisesMsg Exercises.Msg
    | LoginMsg Login.Msg
    | StopwatchMsg Stopwatch.Msg


type Route
    = Home
    | Exercises
    | Login
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

        ( loginModel, loginCmd ) =
            Login.init

        stopwatchModel =
            Stopwatch.init

        exercisesFetchOnStart =
            case route of
                Exercises ->
                    Cmd.none

                _ ->
                    Cmd.none
    in
    ( { url = url
      , key = key
      , route = route
      , exercisesModel = exercisesModel
      , loginModel = loginModel
      , stopwatchModel = stopwatchModel
      }
    , Cmd.batch
        [ Cmd.map ExercisesMsg exercisesCmd
        , exercisesFetchOnStart
        , Cmd.map LoginMsg loginCmd
        ]
    )


routeParser : UP.Parser (Route -> a) a
routeParser =
    UP.oneOf
        [ UP.map Home (UP.s "home")
        , UP.map Exercises (UP.s "exercises")
        , UP.map Login (UP.s "login")
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
                        Exercises ->
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

        LoginMsg subMsg ->
            let
                ( updatedLoginModel, cmd ) =
                    Login.update subMsg model.loginModel
            in
            ( { model | loginModel = updatedLoginModel }
            , Cmd.map LoginMsg cmd
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
        [ viewHeader model.url.path
        , Html.main_ []
            [ viewRoute model
            ]
        , viewFooter
        ]
    }


viewTitle : Route -> String
viewTitle route =
    case route of
        Home ->
            "Home"

        Exercises ->
            "Exercises"

        Login ->
            "Login"

        NotFound ->
            "Page not found"


viewHeader : String -> Html Msg
viewHeader currentPath =
    Html.header []
        [ Html.nav []
            [ Html.a [ HA.class "logo", HA.href "/" ]
                [ Html.img [ HA.src "/assets/logo.png", HA.alt "TQ" ] []
                ]
            , Html.ul []
                [ Html.li [] [ viewLink "HOME" "/home" currentPath ]
                , Html.li [] [ viewLink "EXERCISES" "/exercises" currentPath ]
                , Html.li [] [ viewLink "THEORY" "/theory" currentPath ]
                , Html.li [] [ viewLink "ABOUT" "/about" currentPath ]
                ]
            , Html.div []
                [ viewLink "LOGIN" "/login" currentPath ]
            ]
        ]


viewRoute : Model -> Html Msg
viewRoute model =
    case model.route of
        Home ->
            Html.section []
                [ Html.h1 []
                    [ Html.text "MUSIC THEORY"
                    , Html.br [] []
                    , Html.text "MADE EASY"
                    ]
                , Html.div
                    []
                    [ Html.a
                        [ HA.href "/exercises" ]
                        [ Html.text "Exercises" ]
                    , Html.a
                        [ HA.href "/theory" ]
                        [ Html.text "Theory" ]
                    ]
                ]

        Exercises ->
            Html.map ExercisesMsg (Exercises.view model.exercisesModel)

        Login ->
            Html.map LoginMsg (Login.view model.loginModel)

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
    Html.footer [] [ Html.text "© 2024 My Elm App" ]
