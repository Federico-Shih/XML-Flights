declare function local:generate_country($flag as element()) as node()*{
    let $v := doc("countries.xml")//response/response[code/text() = $flag/text() ]
    where not (fn:empty($v))
    return
            <country>
                {$v/name/text()}
            </country>

};

declare function local:generate_airport($code as element(), $is_arrival as xs:boolean) as node()* {
    let $v := doc("airports.xml")//response/response[iata_code/text() = $code/text()]
    where not(fn:empty($v))
    return
        if ($is_arrival = fn:true())
            then <arrival_airport> {local:generate_country($v[position() = 1]/country_code), $v/name } </arrival_airport>
            else <departure_airport> {local:generate_country($v[position() = 1]/country_code), $v/name} </departure_airport>
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