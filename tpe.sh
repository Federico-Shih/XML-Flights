#!/bin/bash

### Error information and outputs

# ERROR: Java not installed
# ERROR: Missing XML APIs. Package xml-apis.jar not found in $CLASSPATH"
# ERROR: Missing Xerces. Package xercesImpl.jar not found in $CLASSPATH"
# ERROR: Missing Saxon. Package saxon9he.jar not found in $CLASSPATH"
#
# ERROR: Missing API key
# CURL: (0)
# XML: <?xml version="1.0" encoding="UTF-8"?><root><error><message>Missing api_key</message><code>wrong_params</code></error><terms>Unauthorized access is prohibited and punishable by law.
#      Reselling data 'As Is' without AirLabs.Co permission is strictly prohibited.
#      Full terms on https://airlabs.co/.
#      Contact us info@airlabs.co</terms></root>
#
# ERROR: Invalid API key
# CURL: (0)
# XML: <?xml version="1.0" encoding="UTF-8"?><root><error><message>Unknown api_key</message><code>unknown_api_key</code></error><terms>Unauthorized access is prohibited and punishable by law.
#      Reselling data 'As Is' without AirLabs.Co permission is strictly prohibited.
#      Full terms on https://airlabs.co/.
#      Contact us info@airlabs.co</terms></root>
#
# ERROR: Connection Timeout
# CURL: curl: (6) Could not resolve host: airlabs.co
# XML: Empty

# UI colors in ANSI escape code
#
# Link:
#    https://en.wikipedia.org/wiki/ANSI_escape_code
COLOR_ERROR='\033[0;31m'   # (Red)
COLOR_SUCCESS='\033[0;32m' # (Green)
COLOR_WAIT='\033[0;34m'    # (Blue)
NC='\033[0m'               # (No Color)

# UI messages styled tags
TAG_ERROR="${COLOR_ERROR}ERROR${NC}"
TAG_SUCCESS="${COLOR_SUCCESS}SUCCESS${NC}"
TAG_CONNECTING="${COLOR_WAIT}CONNECTING${NC}"
TAG_CONNECTED="${COLOR_SUCCESS}CONNECTED${NC}"
TAG_DOWNLOADING="${COLOR_WAIT}DOWNLOADING${NC}"
TAG_DOWNLOADED="${COLOR_SUCCESS}DOWNLOADED${NC}"
TAG_EXTRACTING="${COLOR_WAIT}EXTRACTING${NC}"
TAG_EXTRACTED="${COLOR_SUCCESS}EXTRACTED${NC}"
TAG_GENERATING="${COLOR_WAIT}GENERATING${NC}"
TAG_GENERATED="${COLOR_SUCCESS}GENERATED${NC}"

# AirLabs API URL
AIRLABS_URL="https://airlabs.co/api/v9/"
AIRLABS_API_KEY=0ca508c6-95b4-48c7-a35a-702231253f9b

# Dependencies package names
XML_PACKAGE_NAME="xml-apis.jar"
XERCES_PACKAGE_NAME="xercesImpl.jar"
SAXON_PACKAGE_NAME="saxon9he.jar"

# Query output filepaths
AIRPORTS_OUT_PATH="airports.xml"
FLIGHTS_OUT_PATH="flights.xml"
COUNTRIES_OUT_PATH="countries.xml"

# Checks if all required dependencies
# are installed
#
# Globals:
#   XML_PACKAGE_NAME
#   XERCES_PACKAGE_NAME
#   SAXON_PACKAGE_NAME
#   CLASSPATH
# Arguments:
#   None
# Outputs:
#   Error messages
function check_environment {
    if ! which java >/dev/null; then
        printf "${TAG_ERROR}:\tJava not installed\n"
    fi
    if ! [[ ${CLASSPATH} == *$XML_PACKAGE_NAME* ]]; then
        printf "${TAG_ERROR}:\tMissing XML APIs. Package $XML_PACKAGE_NAME not found in \$CLASSPATH\n"
    fi
    if ! [[ ${CLASSPATH} == *$XERCES_PACKAGE_NAME* ]]; then
        printf "${TAG_ERROR}:\tMissing Xerces. Package $XERCES_PACKAGE_NAME not found in \$CLASSPATH\n"
    fi
    if ! [[ ${CLASSPATH} == *$SAXON_PACKAGE_NAME* ]]; then
        printf "${TAG_ERROR}:\tMissing Saxon. Package $SAXON_PACKAGE_NAME not found in \$CLASSPATH\n"
    fi
}

# Makes a request to
# the database
#
# Globals:
#   AIRLABS_URL
#   AIRLABS_API_KEY
# Arguments:
#   Database name ( flights | countries | airports )
#   Output format ( xml | json | csv )
#   Output file path
# Outputs:
#   Creates and writes output file
#   from selected database
function get {
    printf "${TAG_DOWNLOADING}:\t$1 data...\n"
    curl "${AIRLABS_URL}$1.$2?api_key=${AIRLABS_API_KEY}" --silent >$3
    printf "\e[1A\e[K${TAG_DOWNLOADED}:\t$1 data\n"
}

# Makes all the required requests to
# the API
#
# Globals:
#   AIRLABS_API_KEY
#   FLIGHTS_OUT_PATH
#   COUNTRIES_OUT_PATH
#   AIRPORTS_OUT_PATH
# Arguments:
#   None
# Outputs:
#   Creates and writes flights,
#   countries and airports .xml files
function make_request {
    printf "${TAG_CONNECTING}:\tto AirLabs...\n"

    curl ${AIRLABS_URL}/ping?api_key=${AIRLABS_API_KEY} --silent >/dev/null

    if [ $? -ne 0 ]; then
        printf "\e[1A\e[K${TAG_ERROR}:\tCannot connect to AirLabs API\n"
        
    else
        printf "\e[1A\e[K${TAG_CONNECTED}:\tto AirLabs\n"
        get flights xml $FLIGHTS_OUT_PATH
        get countries xml $COUNTRIES_OUT_PATH
        get airports xml $AIRPORTS_OUT_PATH
    fi

}

# Executes XQuery query
#
# Globals:
#   None
# Arguments:
#   Output file path
function run_xquery {
    printf "${TAG_EXTRACTING}:\tflights data\n"
    java net.sf.saxon.Query extract_data.xq -TP:$2 >$1
    printf "\e[1A\e[K${TAG_EXTRACTED}:\tflights data\n"
}

# Executes XSLT transformation
#
# Globals:
#   None
# Arguments:
#   Source file path
#   Template file path
#   Output file path
function run_xslt {
    printf "${TAG_GENERATING}:\t.tex file\n"
    java net.sf.saxon.Transform -s:$1 -xsl:$2 -o:$3 qty=$4 
    printf "\e[1A\e[K${TAG_GENERATED}:\t.tex file\n"
}

function clear_environment {
    rm -f ./flights.xml ./airports.xml ./countries.xml
}

clear_environment
check_environment
make_request
run_xquery flight_data.xml debug.html
run_xslt flight_data.xml generate_report.xsl report.tex $1
# pdflatex report.tex > /dev/null
