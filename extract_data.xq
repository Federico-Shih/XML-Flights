declare variable $airports := doc("airports.xml")/root/response/response;
declare variable $countries := doc("countries.xml")/root/response/response;

declare function local:generate_country($flag as element()) as node()*{
    let $v := ($countries/.[code/text() = $flag/text() and position() = 1 ])[1]
    where not (fn:empty($v))
    return
            (<country>
                {$v/name/text()}
            </country>)
};

declare function local:generate_airport($code as element()) as node()* {
    let $v := ($airports/.[iata_code/text() = $code/text() and position() = 1])[1]
    let $country := local:generate_country($v/country_code)
    where not(fn:empty($v))
    return ($country, $v/name)
};

<flights_data>
{
for $flight in doc("flights.xml")/root/response/response
return
        <flight>
        {
        if (fn:exists($flight/hex))
            then 
                attribute id {$flight/hex}
            else()
        }

        {
        if (fn:exists($flight/flag))
        then 
            local:generate_country($flight/flag)
        else()
        }

        <position>
            {$flight/lat}
            {$flight/lng}
        </position>

        {$flight/status}

        {
        if (fn:exists($flight/dep_iata))
            then 
                <departure_airport>
                    {local:generate_airport($flight/dep_iata)}
                </departure_airport>
            else()
        }
        {
        if (fn:exists($flight/arr_iata))
            then
                <arrival_airport>
                    {local:generate_airport($flight/arr_iata)}
                </arrival_airport>
            else()
        }


    </flight>
}
</flights_data>