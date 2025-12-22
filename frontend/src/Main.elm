module Main exposing (..)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Db.Auth as Auth
import Exercises.Stopwatch as Stopwatch
import Html exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Http
import Pages.Dashboard as Dashboard
import Pages.Exercises as Exercises
import Pages.Login as Login
import Pages.Register as Register
import Route exposing (ExercisesRoute(..), Route(..))
import Time exposing (Posix)
import Url
import Url.Parser as UP exposing ((</>), (<?>))



-- MAIN MODEL


type alias Model =
    { url : Url.Url
    , key : Nav.Key
    , page : Page
    , auth : AuthState
    , isLoggedIn : Bool
    , isLoading : Bool
    , stopwatchModel : Stopwatch.Model
    }


type Page
    = HomePage
    | ExercisesPage Exercises.Model
    | LoginPage Login.Model
    | RegisterPage Register.Model
    | DashboardPage Dashboard.Model


type alias AuthState =
    { refreshing : Bool
    , retryAfterRefresh : Maybe ( Retry, Url.Url )
    }


type Retry
    = RetryGetMe


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



-- MAIN PROGRAM


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map StopwatchMsg (Stopwatch.subscriptions model.stopwatchModel)
        , case model.page of
            ExercisesPage m ->
                Sub.map ExercisesMsg (Exercises.subscriptions m)

            DashboardPage m ->
                Sub.map DashboardMsg (Dashboard.subscriptions m)

            _ ->
                Sub.none
        ]



-- INITIALIZATION


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    let
        route =
            Route.fromUrl url

        ( page, cmd ) =
            case route of
                Exercises exercisesRoute ->
                    let
                        ( m, c ) =
                            Exercises.init exercisesRoute
                    in
                    ( ExercisesPage m, Cmd.map ExercisesMsg c )

                Login ->
                    let
                        ( m, c ) =
                            Login.init
                    in
                    ( LoginPage m, Cmd.map LoginMsg c )

                Register ->
                    let
                        ( m, c ) =
                            Register.init
                    in
                    ( RegisterPage m, Cmd.map RegisterMsg c )

                Dashboard ->
                    let
                        ( m, c ) =
                            Dashboard.init
                    in
                    ( DashboardPage m, Cmd.map DashboardMsg c )

                _ ->
                    ( HomePage, Cmd.none )

        checkLoginCmd =
            Auth.getMe (Dashboard.GotUser >> DashboardMsg)
    in
    ( { url = url
      , key = key
      , page = page
      , auth = { refreshing = False, retryAfterRefresh = Nothing }
      , isLoggedIn = False
      , isLoading = False
      , stopwatchModel = Stopwatch.init
      }
    , Cmd.batch [ cmd, checkLoginCmd ]
    )



-- HELPER: PROTECTED CALL FAIL


onProtectedCallFail : Retry -> Model -> ( Model, Cmd Msg )
onProtectedCallFail retry model =
    if model.auth.refreshing then
        ( { model | auth = { refreshing = False, retryAfterRefresh = Just ( retry, model.url ) } }, Cmd.none )

    else
        ( { model | auth = { refreshing = True, retryAfterRefresh = Just ( retry, model.url ) } }
        , Auth.refreshToken AuthRefreshed
        )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChanged newUrl ->
            let
                route =
                    Route.fromUrl newUrl


                ( page, cmd ) =
                    case route of
                        Exercises exercisesRoute ->
                            let
                                ( m, c ) =
                                    Exercises.init exercisesRoute
                            in
                            ( ExercisesPage m, Cmd.map ExercisesMsg c )

                        Login ->
                            let
                                ( m, c ) =
                                    Login.init
                            in
                            ( LoginPage m, Cmd.map LoginMsg c )

                        Register ->
                            let
                                ( m, c ) =
                                    Register.init
                            in
                            ( RegisterPage m, Cmd.map RegisterMsg c )

                        Dashboard ->
                            let
                                ( m, c ) =
                                    Dashboard.init
                            in
                            ( DashboardPage m, Cmd.map DashboardMsg c )

                        _ ->
                            ( HomePage, Cmd.none )
            in
            ( { model | url = newUrl, page = page }, cmd )

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        ExercisesMsg subMsg ->
            case subMsg of
                Exercises.RequestNavigateToChordGuesser ->
                    ( model
                    , Nav.pushUrl model.key "/all-exercises/chord-guesser"
                    )

                _ ->
                    case model.page of
                        ExercisesPage m ->
                            let
                                ( updated, cmd ) =
                                    Exercises.update subMsg m
                            in
                            ( { model | page = ExercisesPage updated }
                            , Cmd.map ExercisesMsg cmd
                            )

                        _ ->
                            ( model, Cmd.none )


        LoginMsg subMsg ->
            case model.page of
                LoginPage m ->
                    let
                        ( updated, cmd ) =
                            Login.update subMsg m
                    in
                    case subMsg of
                        Login.LoginResult (Ok response) ->
                            if response.ok then
                                ( { model | isLoggedIn = True, page = LoginPage updated }
                                , Cmd.batch
                                    [ Auth.getMe (Dashboard.GotUser >> DashboardMsg)
                                    , Nav.pushUrl model.key "/dashboard"
                                    , Cmd.map LoginMsg cmd
                                    ]
                                )

                            else
                                ( { model | page = LoginPage updated }, Cmd.map LoginMsg cmd )

                        _ ->
                            ( { model | page = LoginPage updated }, Cmd.map LoginMsg cmd )

                _ ->
                    ( model, Cmd.none )

        RegisterMsg subMsg ->
            case model.page of
                RegisterPage m ->
                    let
                        ( updated, cmd ) =
                            Register.update subMsg m
                    in
                    case subMsg of
                        Register.RegisterResult (Ok value) ->
                            if value.ok then
                                ( { model | page = RegisterPage updated }
                                , Nav.pushUrl model.key "/login"
                                )

                            else
                                ( { model | page = RegisterPage updated }
                                , Nav.pushUrl model.key "/login"
                                )

                        _ ->
                            ( { model | page = RegisterPage updated }, Cmd.map RegisterMsg cmd )

                _ ->
                    ( model, Cmd.none )

        DashboardMsg subMsg ->
            case model.page of
                DashboardPage m ->
                    let
                        ( updated, cmd ) =
                            Dashboard.update subMsg m

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
                                    onProtectedCallFail RetryGetMe model |> Tuple.second

                                _ ->
                                    Cmd.none
                    in
                    ( { model | page = DashboardPage updated, isLoggedIn = updatedIsLoggedIn, isLoading = setIsLoading }
                    , Cmd.batch [ Cmd.map DashboardMsg cmd, refreshCmd ]
                    )

                _ ->
                    ( model, Cmd.none )

        AuthRefreshed result ->
            case result of
                Ok _ ->
                    case model.auth.retryAfterRefresh of
                        Just ( RetryGetMe, url ) ->
                            ( { model | auth = { refreshing = False, retryAfterRefresh = Nothing } }
                            , Cmd.batch
                                [ Auth.getMe (Dashboard.GotUser >> DashboardMsg)
                                , Nav.pushUrl model.key (Url.toString url)
                                ]
                            )

                        Nothing ->
                            ( { model | auth = { refreshing = False, retryAfterRefresh = Nothing } }, Cmd.none )

                Err _ ->
                    ( { model
                        | auth = { refreshing = False, retryAfterRefresh = Nothing }
                        , isLoggedIn = False
                        , isLoading = False
                      }
                    , Nav.pushUrl model.key "/login"
                    )

        StopwatchMsg subMsg ->
            let
                ( updated, cmd ) =
                    Stopwatch.update subMsg model.stopwatchModel
            in
            ( { model | stopwatchModel = updated }, Cmd.map StopwatchMsg cmd )

        Logout ->
            ( model
            , Cmd.batch
                [ Nav.pushUrl model.key "/login"
                , Auth.logout (\_ -> LogoutCompleted)
                ]
            )

        LogoutCompleted ->
            ( { model | isLoggedIn = False }, Cmd.none )



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = viewTitle model.page
    , body =
        [ viewHeader model
        , Html.main_ []
            [ viewRoute model ]
        , viewFooter
        ]
    }


viewTitle : Page -> String
viewTitle page =
    case page of
        HomePage ->
            "Home"

        ExercisesPage _ ->
            "Exercises"

        LoginPage _ ->
            "Login"

        RegisterPage _ ->
            "Register"

        DashboardPage _ ->
            "Dashboard"


viewHeader : Model -> Html Msg
viewHeader model =
    Html.header []
        [ if model.isLoggedIn then
            Html.nav []
                [ Html.a [ HA.class "logo", HA.href "/" ] [ Html.img [ HA.src "/assets/logo.png", HA.alt "TQ" ] [] ]
                , Html.ul []
                    [ Html.li [] [ viewLink "HOME" "/home" model.url.path ]
                    , Html.li [] [ viewLink "EXERCISES" "/all-exercises" model.url.path ]
                    , Html.li [] [ viewLink "THEORY" "/theory" model.url.path ]
                    , Html.li [] [ viewLink "DASHBOARD" "/dashboard" model.url.path ]
                    , Html.li [] [ viewLink "ABOUT" "/about" model.url.path ]
                    ]
                , Html.button [ HE.onClick Logout ] [ Html.text "LOGOUT" ]
                ]

          else
            Html.nav []
                [ Html.a [ HA.class "logo", HA.href "/" ] [ Html.img [ HA.src "/assets/logo.png", HA.alt "TQ" ] [] ]
                , Html.ul []
                    [ Html.li [] [ viewLink "HOME" "/home" model.url.path ]
                    , Html.li [] [ viewLink "EXERCISES" "/all-exercises" model.url.path ]
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
        case model.page of
            HomePage ->
                Html.section []
                    [ Html.h1 [] [ Html.text "MUSIC THEORY", Html.br [] [], Html.text "MADE EASY" ]
                    , Html.div []
                        [ Html.a [ HA.href "/all-exercises" ] [ Html.text "Exercises" ]
                        , Html.a [ HA.href "/theory" ] [ Html.text "Theory" ]
                        ]
                    ]

            ExercisesPage m ->
                Html.map ExercisesMsg (Exercises.view m)

            LoginPage m ->
                Html.map LoginMsg (Login.view m)

            RegisterPage m ->
                Html.map RegisterMsg (Register.view m)

            DashboardPage m ->
                Html.map DashboardMsg (Dashboard.view m model.isLoggedIn)


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
    Html.footer [] [ Html.text "© 2025 Footer" ]
