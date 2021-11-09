declare variable $FLIGHTS_FILE_PATH := "flights.xml";
declare variable $AIRPORTS_FILE_PATH := "airports.xml";
declare variable $COUNTRIES_FILE_PATH := "countries.xml";

declare variable $MSG_MISSING_API_KEY:= "Missing api_key";
declare variable $MSG_UNKNOWN_API_KEY := "Unknown api_key";
declare variable $MSG_CONNECTION_TIMEOUT := "Connection timeout";

declare function local:isEmpty($file_path as xs:string) as xs:boolean {
    fn:not(fn:doc-available($file_path))
};

declare function local:getCountry($code as element()) as node()? {
    let $country := (
        for $c in doc($COUNTRIES_FILE_PATH)//response/response[code = $code]
        return $c[1]/name/text()
    )
    return 
    if (fn:empty($country))
    then ()
    else <country>{$country}</country>
};

declare function local:getAirport($code as element() , $is_arrival as xs:boolean ) as node()?{
    let $airport := (
        for $a in doc($AIRPORTS_FILE_PATH)//response/response[iata_code=$code]
        where not(fn:empty($a/country_code) or (fn:empty($a/name)))
        return $a
    )
    return (
        if (fn:empty($airport)) 
        then ()
        else
            if ($is_arrival) 
            then
                <arrival_airport>{local:getCountry($airport[1]/country_code), $airport[1]/name}</arrival_airport>
            else 
                <departure_airport>{local:getCountry($airport[1]/country_code), $airport[1]/name}</departure_airport>
    )
};

<flights_data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation= "flights_data.xsd">
{
    if (local:isEmpty($FLIGHTS_FILE_PATH) and local:isEmpty($AIRPORTS_FILE_PATH) and local:isEmpty($COUNTRIES_FILE_PATH)) then
        <error>{$MSG_CONNECTION_TIMEOUT}</error>
    else if ((doc($FLIGHTS_FILE_PATH))//message/text() eq $MSG_MISSING_API_KEY) then
        <error>{$MSG_MISSING_API_KEY}</error>
    else if (doc($FLIGHTS_FILE_PATH)//message/text() eq $MSG_UNKNOWN_API_KEY) then
        <error>{$MSG_UNKNOWN_API_KEY}</error>
    else(
        for $flight in doc($FLIGHTS_FILE_PATH)/root/response/response
        return (
            <flight>

                {
                    if (fn:exists($flight/hex)) 
                    then 
                        attribute id {$flight/hex}
                    else()
                }

                {
                    if (fn:empty($flight/flag)) 
                    then ()
                    else
                        local:getCountry($flight/flag)
                }

                <position>
                    {$flight/lat}
                    {$flight/lng}
                </position>

                {$flight/status}

                {
                    if (fn:empty($flight/dep_iata)) 
                    then ()
                    else
                        local:getAirport($flight/dep_iata, xs:boolean('false'))
                }

                {
                    if(fn:empty($flight/arr_iata)) 
                    then ()
                    else
                        local:getAirport($flight/arr_iata, xs:boolean('true'))
                }

            </flight>
        )
    )
}
</flights_data>