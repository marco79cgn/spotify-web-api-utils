#!/bin/bash
tempDir="/home/pi/temp"
credentialsDir="/home/pi/scripts/credentials"

# curl radioeins for currently playing song
function curlRadioeins() {
    previousTitle=$(<$tempDir/previous-radioeins-title)
    cacheKiller=$(echo $[ $RANDOM % 20000 + 80 ])
    result=$(curl -s "https://www.radioeins.de/include/rad/nowonair/now_on_air.html?cacheKiller=$cacheKiller")
    if [[ -n $result  ]]; then
        # xmllint to parse html, perl to decode html entities
        artist=$(echo -n $result | xmllint --html --xpath '//p[@class="artist"]/text()' - | perl -n -mHTML::Entities -e ' ; print HTML::Entities::decode_entities($_) ;')
        title=$(echo -n $result | xmllint --html --xpath '//p[@class="songtitle"]/text()' - | sed -r 's/[ ]+\(.*\)//' | perl -n -mHTML::Entities -e ' ; print HTML::Entities::decode_entities($_) ;')
        playlistName="Radioeins - Der schöne Morgen"
        # search spotify and add to playlist
        if [[ -n "$title" && -n "$artist" && "$title" != "$previousTitle" ]]; then
            echo -e "New song detected: $artist - $title"
            echo -e "$title" > $tempDir/previous-radioeins-title
	        searchOnSpotify "$title" "$artist"
        fi
    fi
}

# search current song on Spotify
function searchOnSpotify() {
    track=$1
    artist=$2
    searchToken=$(<$credentialsDir/spotify-search-token)
    DATA=$(/usr/bin/perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' "track:$track artist:$artist")
    url="https://api.spotify.com/v1/search?q=$DATA&type=track&market=DE"
    result=$(curl -s -H "Authorization: Bearer $searchToken" -H "Content-Type: application/json" -o search-response.txt -w "%{http_code}" $url)
    if [[ $result == "401" ]]; then
        getSearchToken
        searchOnSpotify "$track" "$artist"
    else
        spotifyUri=$(cat search-response.txt | jq -r '.tracks.items[0].uri')
        if [[ -n "$spotifyUri" ]] && [[ "$spotifyUri" != "null" ]]; then
            addToSpotifyPlaylist "$spotifyUri"
        fi
    fi
}

# obtain new search token if the old one expired
function getSearchToken() {
    echo -e "Search token expired, refreshing..."
    spotifyClientId=$(<$credentialsDir/spotify-client-id)
    spotifyClientSecret=$(<$credentialsDir/spotify-client-secret)
    authToken=$(echo -n "${spotifyClientId}:${spotifyClientSecret}" | base64 | tr --delete '\n')
    searchToken=$(curl -s -X POST -H "Authorization: Basic $authToken" -H "Content-Type: application/x-www-form-urlencoded" -d "grant_type=client_credentials" https://accounts.spotify.com/api/token | jq -r '.access_token')
    echo -e "$searchToken" > $credentialsDir/spotify-search-token
}

# obtain new access token if the old one expired
function refreshAccessToken() {
    echo -e "Access token expired, refreshing..."
    spotifyClientId=$(<$credentialsDir/spotify-client-id)
    spotifyClientSecret=$(<$credentialsDir/spotify-client-secret)
    url="https://accounts.spotify.com/api/token"
    result=$(curl -s -X POST -H "Content-Type: application/x-www-form-urlencoded" -d "grant_type=refresh_token" -d "refresh_token=$1" -d "client_id=$spotifyClientId" -d "client_secret=$spotifyClientSecret" https://accounts.spotify.com/api/token | jq -r '.access_token')
    echo -e "$result" > $credentialsDir/spotify-access-token
}

# add song to Spotify playlist
function addToSpotifyPlaylist() {
    playlistId="6s74bH5QFcZwHb8QA9PRmS"
    accessToken=$(<$credentialsDir/spotify-access-token)
    refreshToken=$(<$credentialsDir/spotify-refresh-token)
    url="https://api.spotify.com/v1/playlists/$playlistId/tracks?uris=$1"
    result=$(curl -s -X POST -H "Authorization: Bearer $accessToken" -H "Content-Type: application/json" -o response.txt -w "%{http_code}" $url)
    if [[ $result == "401" ]]; then
        refreshAccessToken "$refreshToken"
        addToSpotifyPlaylist "$1"
    else
        echo "Successfully added $1 to playlist."
    fi
}

curlRadioeins
