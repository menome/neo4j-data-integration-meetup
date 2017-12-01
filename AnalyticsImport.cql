// ----------------------------------------------
// Well head identifier
USING PERIODIC COMMIT 1000
LOAD CSV WITH HEADERS FROM 'file:///WellListLocationsWGS84.csv' AS line // with line limit 100
// create uuid
CALL apoc.create.uuids(1) YIELD uuid as wuuid

MERGE (c:Well {  Uwi: line.UWI   })
ON CREATE set
    c.Uuid = wuuid,
    c.LSD = (substring(line.UWI,3,14)),
    c.Keylist = line.Keylist,
    c.Name= line.Name,
    c.TotalDepth= line.TotalDep,
    c.WellStat= line.WellStat,
    c.StatDate= line.StatDate,
    c.FDDate= line.FDDate,
    c.LicenseeId=left(line.Licensee,length(line.Licensee)-1),
    c.License=line.License,
    c.Latitude= toFloat(line.Y),
    c.Longitude= toFloat(line.X)
ON MATCH set    
    c.Uuid = wuuid,
    c.LSD = (substring(line.UWI,3,14)),
    c.Keylist = line.Keylist,
    c.Name= line.Name,
    c.TotalDepth= line.TotalDep,
    c.WellStat= line.WellStat,
    c.StatDate= line.StatDate,
    c.FDDate= line.FDDate,
    c.LicenseeId=left(line.Licensee,length(line.Licensee)-1),
    c.License=line.License,
    c.Latitude= toFloat(line.Y),
    c.Longitude= toFloat(line.X);


// Well WellLicensedTo Licensee
USING PERIODIC COMMIT 1000
LOAD CSV WITH HEADERS FROM 'file:///WellListLocationsWGS84.csv' AS line //with line limit 100
MATCH(w:Well {Uwi:line.UWI})
MATCH(l:Licensee {Code: left(line.Licensee,length(line.Licensee)-1)})
MERGE (w)-[:LICENSEE_OF]->(l);

// match wells to licensee in memory using Code
MATCH (w:Well) where not ((w)-[:Licensee]-()) and not exists(w.CodeProcessed)
WITH w limit 5000
MATCH(l:Licensee {Code:w.LicenseeId})
MERGE (w)-[:LICENSEE_OF]->(l)
set w.CodeProcessed=true;

call apoc.periodic.commit("
MATCH (w:Well) where not exists(w.CodeProcessed)
WITH w limit {limit}
MATCH(l:Licensee {Code:w.LicenseeId})
MERGE (w)-[:Licensee]->(l)
set w.CodeProcessed=true
RETURN count(*)
",{limit:10000})


// Facility 
USING PERIODIC COMMIT 1000
LOAD CSV WITH HEADERS FROM 'file:///ActiveFacility.csv' AS line //with line limit 100
CALL apoc.create.uuids(1) YIELD uuid as fuuid

MERGE (f:Facility {Code: line.FacilityID})
ON CREATE set
f.Uuid= fuuid,
f.Name= line.FacilityName,
f.LSD= line.LSD,
f.Status= line.OperationalStatus,
f.OperatorCode=line.OperatorCode,
f.OperatorName = line.OperatorName,
f.LicenseeId=line.LicenseeCode;


// OPERATOR_OF
USING PERIODIC COMMIT 1000
LOAD CSV WITH HEADERS FROM 'file:///ActiveFacility.csv' AS line 
WITH line 
where line.OperatorCode <> ''

// Facility OPERATOR_OF Licenseee
WITH line 
MATCH(li:Licensee {Code:line.OperatorCode})
MATCH(f:Facility {Code:line.FacilityID})
MERGE (f)-[:OPERATOR_OF]->(o);

// Facility LICENSEE_OF Licenseee
WITH line 
MATCH(li:Licensee {Code:line.OperatorCode})
MATCH(f:Facility {Code:line.FacilityID})
MERGE (f)-[:OPERATOR_OF]->(o);


// Import substance released records from edmonton open data portal
WITH 'yUEgWneqrRgNzGUIRQb7yW90M' as token,  70000 as pagesTotal
WITH token, RANGE(1,pagesTotal,1000) as fromNumber, "https://data.edmonton.ca/resource/xir8-nx6p.json?$limit=1000&$offset=number&$order=:id" as baseUrl

// loop through results by range step (1000 records is max)
UNWIND fromNumber as from
WITH token, from, REPLACE(baseUrl,'number',toString(from)) as Url

// sleep to prevent hitting throttling threshold
CALL apoc.util.sleep(1)

CALL apoc.load.jsonParams(Url,
{`X-App-Token`:token}, null
) 
yield value as data 

// generate spill node
WITH data as record //limit 5 - for testing
CALL apoc.create.uuids(1) YIELD uuid as Uuid
WITH record, Uuid, record.location_1 as locations // this statement pulls the locations out 

MERGE (s:Spill {Code: record.incident_number}) 
ON MATCH 
set 
s.SubstanceReleased = record.substance_released,
s.VolumeRecovered = toFloat(record.volume_recovered),
s.VolumeReleased = toFloat(record.volume_released),
s.Units = record.volume_units