##
## General
##
daemon=300              # check every 300 seconds
syslog=yes              # log update msgs to syslog
#mail=root              # mail all msgs to root
#mail-failure=root      # mail failed update msgs to root
pid=/var/run/ddclient/ddclient.pid  # record PID in file.
ssl=yes                 # use ssl-support.  Works with
                        # ssl-library

##
## IP scrape webpage
##
use=web
web='https://cloudflare.com/cdn-cgi/trace'
web-skip='ip='
verbose=yes

##
## CloudFlare (www.cloudflare.com)
##
protocol=cloudflare,        \
zone=${ddclient_cloudflare_zone},            \
ttl=1,                      \
login=token,                \
password=${ddclient_cloudflare_api_token}
${ddclient_hostname}