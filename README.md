# spotify-web-api-utils
A collection of scripts, siri shortcuts etc. involving the [Spotify web API](https://developer.spotify.com/documentation/web-api/)

## radioeins to Spotify automatic live playlist creator
A little shell script which curls the current song on [radioeins vom rbb](https://www.radioeins.de) and adds it to a Spotify playlist using their official [web api](https://developer.spotify.com/documentation/web-api/). I'm using it on a Raspberry Pi but you can run it on any machine that is capable of executing shell scripts. The script uses perl to decode html entities, xmllint to parse html and curl for http calls.

### Background

In order to discover new music, I wanted to create an automated live playlist with music of my favorite morning show. The http call which they use on their web site to show the current song is a little out-fashioned, no rest api but plain old html:
`https://www.radioeins.de/include/rad/nowonair/now_on_air.html`
The result is an html snippet which looks like this: 
`<p class="artist">The Mamas &amp; The Papas</p><p class="songtitle">Dream a little dream of me</p>`
If no song is currently playing, the result will be empty. I created a script which polls once a minute, parses the html, searches the song on Spotify and adds it to a playlist.

### Installation

1. create a shell script, copy & paste the [source code](https://github.com/marco79cgn/spotify-web-api-utils/blob/main/scripts/radioeins-to-spotify.sh) above, save it and make it runnable, e.g.: `chmod 755 curlRadioeins.sh`
2. make the shellscript executable: `chmod 755 curlRadioeins.sh`
3. edit line 2 and 3 for a temp and credentials folder, make sure they exist
4. create an empty file for the previous song in your temp folder (line 2): `touch $tempDir/previous-radioeins-title`
5. put your spotify credentials in your desired credentials folder configured in line 3: 
- echo -n "YOUR_CLIENT_ID" > $credentialsDir/spotify-client-id
- echo -n "YOUR_CLIENT_SECRET" > $credentialsDir/spotify-client-secret
- echo -n "YOUR_ACCESS_TOKEN" > $credentialsDir/spotify-access-token
- echo -n "YOUR_REFRESH_TOKEN" > $credentialsDir/spotify-refresh-token
7. insert your Spotify playlist id in line 65
6. run the script once a minute via cron. Command: crontab -e
`* 5-10 * * 1-5 /bin/bash /home/pi/scripts/curlRadioeins.sh &>/dev/null &`
→ From monday to friday (1-5) between 5 and 10 am (5-10) the script is triggered every minute (*).

If you need help getting your Spotify access and refresh token, you can use my [Siri shortcut](https://routinehub.co/shortcut/13345/).
