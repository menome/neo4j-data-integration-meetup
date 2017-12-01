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
f.Status= line.OperationalStatus;