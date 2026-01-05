module Pages.Register exposing (..)

import Db.Auth as Auth
import Html exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Http
import Json.Encode as Encode
import Platform.Cmd exposing (Cmd)
import String


type alias Model =
    { username : String
    , email : String
    , firstname : String
    , lastname : String
    , password : String
    , repeatPassword : String
    , isSubmitting : Bool
    , error : Maybe String
    , successMessage : Maybe String
    }


type Msg
    = SetUsername String
    | SetEmail String
    | SetFirstname String
    | SetLastname String
    | SetPassword String
    | SetRepeatPassword String
    | Submit
    | RegisterResult (Result Http.Error Auth.RegisterResponse)


init : ( Model, Cmd Msg )
init =
    ( { username = ""
      , email = ""
      , firstname = ""
      , lastname = ""
      , password = ""
      , repeatPassword = ""
      , isSubmitting = False
      , error = Nothing
      , successMessage = Nothing
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetUsername u ->
            ( { model | username = u }, Cmd.none )

        SetEmail e ->
            ( { model | email = e }, Cmd.none )

        SetFirstname f ->
            ( { model | firstname = f }, Cmd.none )

        SetLastname l ->
            ( { model | lastname = l }, Cmd.none )

        SetPassword p ->
            let
                passwordMatch =
                    if model.repeatPassword /= p then
                        "Passwords must match"

                    else
                        ""
            in
            ( { model | password = p, error = Just passwordMatch }, Cmd.none )

        SetRepeatPassword p ->
            let
                passwordMatch =
                    if model.password /= p then
                        "Passwords must match"

                    else
                        ""
            in
            ( { model | repeatPassword = p, error = Just passwordMatch }, Cmd.none )

        Submit ->
            if model.isSubmitting then
                ( model, Cmd.none )

            else if model.password /= model.repeatPassword then
                ( { model | error = Just "Passwords must match" }, Cmd.none )

            else
                let
                    body =
                        Encode.object
                            [ ( "username", Encode.string model.username )
                            , ( "email", Encode.string model.email )
                            , ( "firstname", Encode.string model.firstname )
                            , ( "lastname", Encode.string model.lastname )
                            , ( "password", Encode.string model.password )
                            ]
                in
                ( { model | isSubmitting = True, error = Nothing }
                , Auth.register body RegisterResult
                )

        RegisterResult (Ok response) ->
            if response.ok then
                ( { model
                    | isSubmitting = False
                    , error = Nothing
                    , successMessage = Just response.message
                  }
                , Cmd.none
                )

            else
                ( { model
                    | isSubmitting = False
                    , error = Just response.message
                  }
                , Cmd.none
                )

        RegisterResult (Err httpError) ->
            ( { model | isSubmitting = False, error = Just (httpErrorToString httpError) }, Cmd.none )


httpErrorToString : Http.Error -> String
httpErrorToString httpError =
    case httpError of
        Http.BadUrl msg ->
            "Bad url: " ++ msg

        Http.Timeout ->
            "Request timed out"

        Http.NetworkError ->
            "Network error"

        Http.BadStatus code ->
            "Bad status: " ++ String.fromInt code

        Http.BadBody msg ->
            "Bad body: " ++ msg


view : Model -> Html Msg
view model =
    case model.successMessage of
        Just message ->
            Html.div [] [ Html.text message ]

        Nothing ->
            Html.div
                [ HA.class "login-register-container"
                ]
                [ Html.h1 [] [ Html.text "REGISTER" ]
                , Html.div [ HA.class "input-group" ]
                    [ Html.label [] [ Html.text "Username" ]
                    , Html.input [ HA.required True, HA.type_ "text", HA.value model.username, HE.onInput SetUsername ] []
                    ]
                , Html.div [ HA.class "input-group" ]
                    [ Html.label [] [ Html.text "Email" ]
                    , Html.input [ HA.required True, HA.type_ "email", HA.value model.email, HE.onInput SetEmail ] []
                    ]
                , Html.div [ HA.class "input-group" ]
                    [ Html.label [] [ Html.text "First name" ]
                    , Html.input [ HA.required True, HA.type_ "text", HA.value model.firstname, HE.onInput SetFirstname ] []
                    ]
                , Html.div [ HA.class "input-group" ]
                    [ Html.label [] [ Html.text "Last name" ]
                    , Html.input [ HA.required True, HA.type_ "text", HA.value model.lastname, HE.onInput SetLastname ] []
                    ]
                , Html.div [ HA.class "input-group" ]
                    [ Html.label [] [ Html.text "Password" ]
                    , Html.input [ HA.required True, HA.type_ "password", HA.value model.password, HE.onInput SetPassword ] []
                    ]
                , Html.div [ HA.class "input-group" ]
                    [ Html.label [] [ Html.text "Repeat password" ]
                    , Html.input [ HA.required True, HA.type_ "password", HA.value model.repeatPassword, HE.onInput SetRepeatPassword ] []
                    ]
                , case model.error of
                    Just e ->
                        Html.div [ HA.class "error" ] [ Html.text e ]

                    Nothing ->
                        Html.div [] []
                , Html.button [ HA.class "custom-button", HA.class "submit-button", HA.disabled model.isSubmitting, HE.onClick Submit ]
                    [ Html.text
                        (if model.isSubmitting then
                            "Registering..."

                         else
                            "Register"
                        )
                    ]
                ]
