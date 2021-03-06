#!/bin/bash

# UI colors in ANSI escape code
#
# Link: https://en.wikipedia.org/wiki/ANSI_escape_code
COLOR_ERROR='\033[1m\033[31m'       # (Bold Red)
COLOR_SUCCESS='\033[1m\033[32m'     # (Bold Green)
COLOR_WAIT='\033[1m\033[34m'        # (Bold Blue)
COLOR_TASK="\033[1m\033[35m"        # (Bold Magenta)
COLOR_WRITING="\033[1m\033[33m"     # (Bold Yellow)
NC='\033[0m'                        # (No Color)

# UI messages styled tags
TAG_ERROR="${COLOR_ERROR}ERROR${NC}"
TAG_SUCCESS="${COLOR_SUCCESS}SUCCESS${NC}"
TAG_CONNECTING="${COLOR_WAIT}CONNECTING${NC}"
TAG_CONNECTED="${COLOR_SUCCESS}CONNECTED${NC}"
TAG_DOWNLOADING="${COLOR_WAIT}DOWNLOADING${NC}"
TAG_DOWNLOADED="${COLOR_SUCCESS}DOWNLOADED${NC}"
TAG_EXTRACTING="${COLOR_TASK}EXTRACTING${NC}"
TAG_EXTRACTED="${COLOR_SUCCESS}EXTRACTED${NC}"
TAG_GENERATING="${COLOR_WRITING}GENERATING${NC}"
TAG_GENERATED="${COLOR_SUCCESS}GENERATED${NC}"

### UI Utility functions

function show_spinner {
    local i=0
    local sp='/-\|'
    local s=${#sp}
    sleep 0.1
    while true; do
        printf '\b%s' "${sp:i++%s:1}"
        sleep 0.1
    done
}

function hideinput {
  if [ -t 0 ]; then
     stty -echo -icanon time 0 min 0
  fi
}

function cleanup {
  if [ -t 0 ]; then
    stty sane
  fi
}

####

# AirLabs API URL
AIRLABS_URL="https://airlabs.co/api/v9/"

# Dependencies package names
XERCES_PACKAGE_NAME="xercesImpl.jar"
SAXON_PACKAGE_NAME="saxon9he.jar"

# Filepaths
AIRPORTS_OUT_PATH="airports.xml"
FLIGHTS_OUT_PATH="flights.xml"
COUNTRIES_OUT_PATH="countries.xml"

XQ_OUT_PATH="flight_data.xml"
XLST_OUT_PATH="generate_report.xsl"

TEX_OUT_PATH="report.tex"
PDF_OUT_PATH="report.pdf"
DBG_OUT_PATH="debug.html"

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
        printf "${TAG_ERROR}: Java is not installed.\n"
    fi
    if ! [[ ${CLASSPATH} == *$XERCES_PACKAGE_NAME* ]]; then
        printf "${TAG_ERROR}: Missing Xerces. Package $XERCES_PACKAGE_NAME not found in \$CLASSPATH.\n"
    fi
    if ! [[ ${CLASSPATH} == *$SAXON_PACKAGE_NAME* ]]; then
        printf "${TAG_ERROR}: Missing Saxon. Package $SAXON_PACKAGE_NAME not found in \$CLASSPATH.\n"
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
    printf "${TAG_DOWNLOADING}: Downloading $1 data...\n"
    show_spinner & show_spinner_pid=$!
    curl "${AIRLABS_URL}$1.$2?api_key=${AIRLABS_API_KEY}" --silent >$3
    kill "$show_spinner_pid"
    wait "$show_spinner_pid" 2> /dev/null
    printf "\e[1A\e[K\b${TAG_DOWNLOADED}: Succesfully downloaded $1 data.\n"
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
    printf "${TAG_CONNECTING}: Connecting to \e[4mAirLabs.co\e[0m...\n"

    curl ${AIRLABS_URL}/ping?api_key=${AIRLABS_API_KEY} --silent >/dev/null

    if [ $? -ne 0 ]; then
        printf "\e[1A\e[K${TAG_ERROR}: Cannot connect to \e[4mAirLabs.co\e[0m.\n"

    else
        printf "\e[1A\e[K${TAG_CONNECTED}: Succesfully connected to \e[4mAirLabs.co\e[0m\n"
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
    printf "${TAG_EXTRACTING}: Running XQuery query to extract flights data...\n"
    show_spinner & show_spinner_pid=$!
    java net.sf.saxon.Query extract_data.xq -TP:$2 &>/dev/null >$1 
    kill "$show_spinner_pid"
    wait "$show_spinner_pid" 2> /dev/null
    printf "\e[1A\e[K\b${TAG_EXTRACTED}: Flights data extracted.\n"
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
    printf "${TAG_GENERATING}: Generating ${TEX_OUT_PATH} file...\n"
    show_spinner & show_spinner_pid=$!
    java net.sf.saxon.Transform -s:$1 -xsl:$2 -o:$3 qty=$4 &>/dev/null
    kill "$show_spinner_pid" 
    wait "$show_spinner_pid" 2> /dev/null
    printf "\e[1A\e[K\b${TAG_GENERATED}: Generated ${TEX_OUT_PATH} file.\n"
}

# Creates a PDF file from .tex generated file
#
# Globals:
#   TEX_OUT_PATH
# Arguments:
#   None
function generate_latex_pdf {
    if ! which pdflatex >/dev/null; then
        printf "${TAG_ERROR}: Cannot generate PDF file. Pdflatex is not installed.\n"
    else
        printf "${TAG_GENERATING}: Generating PDF file...\n"
        pdflatex $TEX_OUT_PATH >/dev/null
        printf "\e[1A\e[K\b${TAG_GENERATED}: Generated PDF file.\n"
    fi
}

# Deletes the files created by the lastest query
#
# Globals:
#   None
# Arguments:
#   None
function clear_environment {
    rm -f $FLIGHTS_OUT_PATH $AIRPORTS_OUT_PATH $COUNTRIES_OUT_PATH $DBG_OUT_PATH $TEX_OUT_PATH $PDF_OUT_PATH $XQ_OUT_PATH
}

#### Disables user input while code is running

trap cleanup EXIT
trap hideinput CONT
hideinput

####

if [ -z ${AIRLABS_API_KEY} ]; then
    printf "${TAG_ERROR}: AIRLABS_API_KEY environment variable not found.\n"
    exit
fi

if [ $# -gt 0 ] && [ $1 -le 0 ] &> /dev/null; then
    printf "${TAG_ERROR}: Invalid argument. QTY must be positive number.\n"
    exit
fi   

clear_environment
check_environment
make_request
run_xquery $XQ_OUT_PATH $DBG_OUT_PATH
run_xslt $XQ_OUT_PATH $XLST_OUT_PATH $TEX_OUT_PATH $1

if [ $2 == "-p" ] &> /dev/null;  then
    generate_latex_pdf
fi

exit 0

