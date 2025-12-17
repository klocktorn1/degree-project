module Pages.Dashboard exposing (..)

import Api.Auth exposing (UserResponse)
import Html exposing (Html)
import Http


type alias Model =
    { user : Maybe User
    }


type alias User =
    { username : String
    , email : String
    , firstname : String
    , lastname : String
    , createdAt : String
    }


type Msg
    = GotUser (Result Http.Error UserResponse)


init : ( Model, Cmd Msg )
init =
    ( { user = Nothing }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotUser (Ok userResponse) ->
            ( { model
                | user =
                    Just
                        { username = userResponse.username
                        , email = userResponse.email
                        , firstname = userResponse.firstname
                        , lastname = userResponse.lastname
                        , createdAt = userResponse.createdAt
                        }
              }
            , Cmd.none
            )

        GotUser (Err httpError) ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    Html.div []
        [ Html.text "This is the dashboard page."
        , case model.user of
            Just user ->
                Html.div []
                    [ Html.p [] [ Html.text ("Username: " ++ user.username) ]
                    , Html.p [] [ Html.text ("Email: " ++ user.email) ]
                    , Html.p [] [ Html.text ("First Name: " ++ user.firstname) ]
                    , Html.p [] [ Html.text ("Last Name: " ++ user.lastname) ]
                    , Html.p [] [ Html.text ("Created At: " ++ user.createdAt) ]
                    ]

            Nothing ->
                Html.p [] [ Html.text "User data not available." ]
        ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
