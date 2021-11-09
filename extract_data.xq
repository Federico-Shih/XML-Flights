declare function local:generate_country($flag as element()) as node()*{
    for $response in doc("countries.xml")//response/response
    where ($response/code/text() = $flag/text())
    return 
        if ( fn:empty($response))
        then ()
        else
            <country>
                {$response/name/text()}
            </country>

};

declare function local:generate_airport($code as element(), $is_arrival as xs:boolean) as node()* {
    for $response in doc("airports.xml")//response/response
    where ($response/iata_code/text() = $code/text())
    return
            if ( fn:empty($response))
            then  ()
            else 
                if ($is_arrival = fn:true())
                    then <arrival_airport> {local:generate_country($response/country_code), $response/name } </arrival_airport>
                    else <departure_airport> {local:generate_country($response/country_code), $response/name} </departure_airport>
};

<flights_data>
{
for $flight in doc("flights.xml")//response/response
order by $flight/hex
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
                local:generate_airport($flight/dep_iata[position()=1], fn:false())
            else()
        }
        {
        if (fn:exists($flight/arr_iata))
            then
                local:generate_airport($flight/arr_iata[position()=1], fn:true())
            else()
        }

    </flight>
}
</flights_data>