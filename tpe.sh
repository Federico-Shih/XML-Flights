
# Requests
curl https://airlabs.co/api/v9/airports.xml?api_key=${AIRLABS_API_KEY} > airports.xml

curl https://airlabs.co/api/v9/flights.xml?api_key=${AIRLABS_API_KEY} > flights.xml

curl https://airlabs.co/api/v9/countries.xml?api_key=${AIRLABS_API_KEY} > countries.xml

# XQuery

java net.sf.saxon.Query extract_data.xq > flights_data_0.xml

# XSLT
java net.sf.saxon.Transform -s:flights_data.xml -xsl:generate_report.xsl -o:hola.xml



