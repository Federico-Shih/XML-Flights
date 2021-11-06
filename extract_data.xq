declare function local:exists_airport($airport_icao as element()) as xs:boolean{

    doc("airports.xml")//response[./iata_code/text()=$airport_icao/text()]/name/text() != ""

};

declare function local:exists_country($flag as element()) as xs:boolean{

    doc("countries.xml")//response[./code/text()=$flag/text()]/name/text() != ""
};

<flights_data>
{
for $flight in doc("flight.xml")//response/response
order by $flight/hex
return
        <flightT>
        {
        if (fn:exists($flight/hex))
            then 
                attribute id {$flight/hex}
            else()
        }
        {
        if ( fn:exists($flight/flag) and local:exists_country($flight/flag))
            then
                <country>
                    {doc("countries.xml")//response[./code/text()=$flight/flag/text()]/name/text()}
                </country>
            else()    
        }
        <position>
            {$flight/lat}
            {$flight/lng}
        </position>
        {$flight/status}
        {
        if (fn:exists($flight/dep_iata) and local:exists_airport($flight/dep_iata[position()=1]))
            then
                <departure_airport>
                    {doc("airports.xml")//response[./iata_code/text()=$flight/dep_iata/text()]/name/text()}
                </departure_airport>
            else()
        }
        {
        if (fn:exists($flight/arr_iata) and local:exists_airport($flight/arr_iata[position()=1]))
            then
                <arrival_airport>
                    {doc("airports.xml")//response[./iata_code/text()=$flight/arr_iata/text()]/name/text()}
                </arrival_airport>
            else()
        }
    </flightT>
}
</flights_data>

