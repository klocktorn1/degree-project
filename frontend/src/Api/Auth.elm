module Api.Auth exposing (..)

import Http
import Json.Decode as Decode
import Json.Encode as Encode


type alias LoginResponse =
    { ok : Bool
    , message : String
    , accessToken : Maybe String
    }


loginDecoder : Decode.Decoder LoginResponse
loginDecoder =
    Decode.map3 LoginResponse
        (Decode.field "ok" Decode.bool)
        (Decode.field "message" Decode.string)
        (Decode.maybe (Decode.field "accessToken" Decode.string))
{-
   Simple API wrapper for authentication requests.

   - `login` and `signup` accept a `Json.Encode.Value` body and return
     `Cmd (Result Http.Error String)` where the `String` is the raw response body.

   Adjust the URLs and response handling to match your backend.
-}


baseUrl : String
baseUrl =
    "http://localhost:3000"


login : Encode.Value -> (Result Http.Error LoginResponse -> msg) -> Cmd msg
login body toMsg =
    Http.request
        { method = "POST"
        , headers = []
        , url = baseUrl ++ "/auth/login"
        , body = Http.jsonBody body
        , expect = Http.expectJson toMsg loginDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


signup : Encode.Value -> Cmd (Result Http.Error String)
signup body =
    Http.post
        { url = baseUrl ++ "/auth/signup"
        , body = Http.jsonBody body
        , expect = Http.expectString identity
        }
