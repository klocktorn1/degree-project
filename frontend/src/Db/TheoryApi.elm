module Db.TheoryApi exposing (Chord, buildErrorMessage, fetchChord, fetchChords)

import Http
import Json.Decode as Decode


type alias Chord =
    { chord : String
    , root : String
    , formula : List Int
    , degrees : List String
    , notes : List String
    }


baseUrl : String
baseUrl =
    "http://localhost:5000/api/v1"


buildErrorMessage : Http.Error -> String
buildErrorMessage httpError =
    case httpError of
        Http.BadUrl message ->
            "BadUrl: " ++ message

        Http.Timeout ->
            "Server is taking too long to respond. Please try again later"

        Http.NetworkError ->
            "Unable to reach server"

        Http.BadStatus statusCode ->
            "Request failed with status code: " ++ (statusCode |> String.fromInt)

        Http.BadBody message ->
            "BadBody: " ++ message


chordDecoder : Decode.Decoder Chord
chordDecoder =
    Decode.map5 Chord
        (Decode.field "chord" Decode.string)
        (Decode.field "root" Decode.string)
        (Decode.field "formula" (Decode.list Decode.int))
        (Decode.field "degrees" (Decode.list Decode.string))
        (Decode.field "notes" (Decode.list Decode.string))


chordListDecoder : Decode.Decoder (List Chord)
chordListDecoder =
    Decode.list chordDecoder


chordsDecoder : Decode.Decoder (List Chord)
chordsDecoder =
    Decode.field "chords" chordListDecoder


parseChordTypes : List String -> String
parseChordTypes chordTypes =
    chordTypes
        |> String.join "&type="
        |> (\s -> "&type=" ++ s)


parseRootNotes : List String -> String
parseRootNotes chordTypes =
    chordTypes
        |> String.join "&root="
        |> (\s -> "?root=" ++ s)



-- http://localhost:5000/api/v1/chords?root=F&root=G&root=C&type=major&type=minor


fetchChords : List String -> List String -> (Result Http.Error (List Chord) -> msg) -> Cmd msg
fetchChords rootNotes chordTypes toMsg =
    Http.get
        { url =
            baseUrl
                ++ "/chords"
                ++ parseRootNotes rootNotes
                ++ parseChordTypes chordTypes
        , expect = Http.expectJson toMsg chordsDecoder
        }


fetchChord : String -> String -> (Result Http.Error Chord -> msg) -> Cmd msg
fetchChord root quality toMsg =
    Http.get
        { url =
            baseUrl
                ++ "/chords/"
                ++ root
                ++ "/"
                ++ quality
        , expect = Http.expectJson toMsg chordDecoder
        }
