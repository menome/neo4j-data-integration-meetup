
// Neo4j Data Integration Example from Calgary Neo4j Graph Meetup, 
// https://www.meetup.com/Calgary-Neo4j-Graph-Meetup/events/237621040/
// Hosted by Menome Technologies Inc, Nulli and Arcurve
// Data Integration Example created by Menome Technologies Inc http://www.menome.com

// Imports Active Facilities from Alberta ATS Site 
// Uses file: LicenseeAgent_Codes.csv
// Pre-Processed file for use with this import available here:
// https://www.dropbox.com/s/u1rm4d62nqg23nh/DataIntegrationFiles.zip?dl=0
// Original source file from Alberta Energy Regulator Open Data ST104
// https://www.aer.ca/data-and-publications/statistical-reports/st104

// docker exec neo4jdataintegrationmeetup_neo4j_1 sh -c "cat /var/lib/neo4j/import/3_ImportLicensee.cql | /var/lib/neo4j/bin/cypher-shell -u neo4j -p password "

// indexes
CREATE INDEX ON :Licensee(Address);

// Well head identifier
USING PERIODIC COMMIT 1000
LOAD CSV WITH HEADERS FROM 'file:///LicenseeAgent_Codes.csv' AS line 
with line

// generate guid if we need to create
CALL apoc.create.uuids(1) YIELD uuid as Uuid
WITH Uuid, line

MERGE (l:Licensee {  Name: line.Code   })
ON CREATE set
l.Uuid= Uuid,
l.Code = line.Code,
l.Name = line.Licensee,
l.Abbreviation = line.Abbreviation,
l.Address = line.Address
ON MATCH set
l.Code = line.Code,
l.Name = line.Licensee,
l.Abbreviation = line.Abbreviation,
l.Address = line.Address;

// Use Cypher/Apoc to Geocode Addresses. 
// You will need to setup NEO4J.CONF file to include APOC config for this::
//# APOC geocoding
//apoc.spatial.geocode.provider=google
//apoc.spatial.geocode.google.throttle=100
//apoc.spatial.geocode.google.key=ADD_YOUR_GOOGLE_MAPS_API_KEY_HERE
// this call does a periodic transaction commit using batches of 10000, so is much more memory efficient
call apoc.periodic.commit("
MATCH (l:Licensee) where exists(l.Address) and length(l.Address) > 5 and (not l.Address contains 'not found') 
WITH l limit {limit}
match (l) where not exists (l.Latitude) and l.Address <> '' 

CALL apoc.spatial.geocodeOnce(l.Address) YIELD location
WITH l, location
SET l.Latitude=location.latitude, l.Longitude= location.longitude

RETURN count(*)

",{limit:500})
