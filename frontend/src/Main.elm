module Main exposing (..)

import Api.Auth as Auth
import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Exercises.Stopwatch as Stopwatch
import Html exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Http
import Pages.Dashboard as Dashboard
import Pages.Exercises as Exercises
import Pages.Login as Login
import Pages.Register as Register
import Time exposing (Posix)
import Url
import Url.Parser as UP exposing ((</>), (<?>))


type alias Model =
    { url : Url.Url
    , key : Nav.Key
    , route : Route
    , exercisesModel : Exercises.Model
    , loginModel : Login.Model
    , registerModel : Register.Model
    , dashboardModel : Dashboard.Model
    , stopwatchModel : Stopwatch.Model
    , auth : AuthState
    , isLoggedIn : Bool
    , isLoading : Bool
    }


type alias AuthState =
    { refreshing : Bool
    , retryAfterRefresh : Maybe ( Retry, Url.Url )
    }


type Retry
    = RetryGetMe



-- later: RetryOtherProtectedCall


type Msg
    = UrlChanged Url.Url
    | LinkClicked Browser.UrlRequest
    | ExercisesMsg Exercises.Msg
    | LoginMsg Login.Msg
    | RegisterMsg Register.Msg
    | DashboardMsg Dashboard.Msg
    | StopwatchMsg Stopwatch.Msg
    | AuthRefreshed (Result Http.Error ())
    | Logout
    | LogoutCompleted


type Route
    = Home
    | Exercises
    | Login
    | Register
    | Dashboard
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
        , Sub.map DashboardMsg (Dashboard.subscriptions model.dashboardModel)
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

        ( registerModel, registerCmd ) =
            Register.init

        ( dashboardModel, dashboardCmd ) =
            Dashboard.init

        stopwatchModel =
            Stopwatch.init

        exercisesFetchOnStart =
            case route of
                Exercises ->
                    Cmd.none

                _ ->
                    Cmd.none

        checkLoginCmd =
            Auth.getMe (Dashboard.GotUser >> DashboardMsg)
    in
    ( { url = url
      , key = key
      , route = route
      , exercisesModel = exercisesModel
      , loginModel = loginModel
      , registerModel = registerModel
      , dashboardModel = dashboardModel
      , stopwatchModel = stopwatchModel
      , auth = { refreshing = False, retryAfterRefresh = Nothing }
      , isLoggedIn = False
      , isLoading = True
      }
    , Cmd.batch
        [ Cmd.map ExercisesMsg exercisesCmd
        , exercisesFetchOnStart
        , Cmd.map LoginMsg loginCmd
        , Cmd.map RegisterMsg registerCmd
        , Cmd.map DashboardMsg dashboardCmd
        , checkLoginCmd
        ]
    )


onProtectedCallFail : Retry -> Model -> ( Model, Cmd Msg )
onProtectedCallFail retry model =
    if model.auth.refreshing then
        -- Already refreshing → just queue the retry
        ( { model | auth = { refreshing = False, retryAfterRefresh = Just ( retry, model.url ) } }
        , Cmd.none
        )

    else
        -- Start refresh immediately
        ( { model | auth = { refreshing = True, retryAfterRefresh = Just ( retry, model.url ) } }
        , Auth.refreshToken AuthRefreshed
        )


routeParser : UP.Parser (Route -> a) a
routeParser =
    UP.oneOf
        [ UP.map Home (UP.s "home")
        , UP.map Exercises (UP.s "exercises")
        , UP.map Login (UP.s "login")
        , UP.map Register (UP.s "register")
        , UP.map Dashboard (UP.s "dashboard")
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

        RegisterMsg subMsg ->
            case subMsg of
                Register.RegisterResult (Ok _) ->
                    ( model, Nav.pushUrl model.key "/login" )

                _ ->
                    let
                        ( updatedRegisterModel, cmd ) =
                            Register.update subMsg model.registerModel
                    in
                    ( { model | registerModel = updatedRegisterModel }
                    , Cmd.map RegisterMsg cmd
                    )

        LoginMsg subMsg ->
            case subMsg of
                Login.LoginResult result ->
                    let
                        ( updatedLoginModel, cmd ) =
                            Login.update subMsg model.loginModel

                        successCmd =
                            case result of
                                Ok response ->
                                    if response.ok then
                                        Cmd.batch
                                            [ Auth.getMe (Dashboard.GotUser >> DashboardMsg)
                                            , Nav.pushUrl model.key "/dashboard"
                                            ]

                                    else
                                        Cmd.none

                                Err _ ->
                                    Cmd.none
                    in
                    ( { model
                        | loginModel = updatedLoginModel
                        , isLoggedIn = True
                      }
                    , Cmd.batch [ Cmd.map LoginMsg cmd, successCmd ]
                    )

                _ ->
                    let
                        ( updatedLoginModel, cmd ) =
                            Login.update subMsg model.loginModel
                    in
                    ( { model | loginModel = updatedLoginModel }
                    , Cmd.map LoginMsg cmd
                    )

        DashboardMsg subMsg ->
            let
                ( updatedDashboardModel, cmd ) =
                    Dashboard.update subMsg model.dashboardModel

                updatedIsLoggedIn =
                    case subMsg of
                        Dashboard.GotUser (Ok response) ->
                            case response.user of
                                Just _ ->
                                    True

                                Nothing ->
                                    False

                        Dashboard.GotUser (Err (Http.BadStatus 401)) ->
                            False

                        _ ->
                            model.isLoggedIn

                setIsLoading =
                    case subMsg of
                        Dashboard.GotUser _ ->
                            False

                refreshCmd =
                    case subMsg of
                        Dashboard.GotUser (Err (Http.BadStatus 401)) ->
                            onProtectedCallFail RetryGetMe model
                                |> Tuple.second

                        _ ->
                            Cmd.none
            in
            ( { model
                | dashboardModel = updatedDashboardModel
                , isLoggedIn = updatedIsLoggedIn
                , isLoading = setIsLoading
              }
            , Cmd.batch [ Cmd.map DashboardMsg cmd, refreshCmd ]
            )

        AuthRefreshed result ->
            case result of
                Ok _ ->
                    case model.auth.retryAfterRefresh of
                        Just ( RetryGetMe, url ) ->
                            ( { model
                                | auth = { refreshing = False, retryAfterRefresh = Nothing }
                              }
                            , Cmd.batch
                                [ Auth.getMe (Dashboard.GotUser >> DashboardMsg)
                                , Nav.pushUrl model.key (Url.toString url)
                                ]
                            )

                        Nothing ->
                            ( { model | auth = { refreshing = False, retryAfterRefresh = Nothing } }
                            , Cmd.none
                            )

                Err _ ->
                    -- refresh failed → logout
                    ( model, Cmd.none )

        StopwatchMsg subMsg ->
            let
                ( updatedStopwatch, cmd ) =
                    Stopwatch.update subMsg model.stopwatchModel
            in
            ( { model | stopwatchModel = updatedStopwatch }
            , Cmd.map StopwatchMsg cmd
            )

        Logout ->
            ( model
            , Cmd.batch
                [ Nav.pushUrl model.key "/login"
                , Auth.logout (\_ -> LogoutCompleted)
                ]
            )

        LogoutCompleted ->
            ( { model
                | isLoggedIn = False
              }
            , Cmd.none
            )


view : Model -> Browser.Document Msg
view model =
    { title = viewTitle model.route
    , body =
        [ viewHeader model
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

        Register ->
            "Register"

        Dashboard ->
            "Dashboard"

        NotFound ->
            "Page not found"


viewHeader : Model -> Html Msg
viewHeader model =
    Html.header []
        [ if model.isLoggedIn then
            Html.nav []
                [ Html.a [ HA.class "logo", HA.href "/" ]
                    [ Html.img [ HA.src "/assets/logo.png", HA.alt "TQ" ] []
                    ]
                , Html.ul []
                    [ Html.li [] [ viewLink "HOME" "/home" model.url.path ]
                    , Html.li [] [ viewLink "EXERCISES" "/exercises" model.url.path ]
                    , Html.li [] [ viewLink "THEORY" "/theory" model.url.path ]
                    , Html.li [] [ viewLink "DASHBOARD" "/dashboard" model.url.path ]
                    , Html.li [] [ viewLink "ABOUT" "/about" model.url.path ]
                    ]
                , Html.button [ HE.onClick Logout ] [ Html.text "LOGOUT" ]
                ]

          else
            Html.nav []
                [ Html.a [ HA.class "logo", HA.href "/" ]
                    [ Html.img [ HA.src "/assets/logo.png", HA.alt "TQ" ] []
                    ]
                , Html.ul []
                    [ Html.li [] [ viewLink "HOME" "/home" model.url.path ]
                    , Html.li [] [ viewLink "EXERCISES" "/exercises" model.url.path ]
                    , Html.li [] [ viewLink "THEORY" "/theory" model.url.path ]
                    , Html.li [] [ viewLink "DASHBOARD" "/dashboard" model.url.path ]
                    , Html.li [] [ viewLink "REGISTER" "/register" model.url.path ]
                    , Html.li [] [ viewLink "ABOUT" "/about" model.url.path ]
                    ]
                , Html.button [ HE.onClick Logout ] [ Html.text "LOGIN" ]
                ]
        ]


viewRoute : Model -> Html Msg
viewRoute model =
    if model.isLoading then
        Html.div [] [ Html.text "Loading..." ]

    else
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

            Register ->
                Html.map RegisterMsg (Register.view model.registerModel)

            Dashboard ->
                Html.map DashboardMsg (Dashboard.view model.dashboardModel model.isLoggedIn)

            NotFound ->
                Html.div []
                    [ Html.text "Page not found" ]


viewLink : String -> String -> String -> Html Msg
viewLink label path currentPath =
    let
        maybeUrl =
            Url.fromString ("http://localhost:3000" ++ path)

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
