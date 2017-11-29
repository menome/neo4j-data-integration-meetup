// Neo4j Data Integration Example from Calgary Neo4j Graph Meetup, 
// https://www.meetup.com/Calgary-Neo4j-Graph-Meetup/events/237621040/
// Hosted by Menome Technologies Inc, Nulli and Arcurve
// Data Integration Example created by Menome Technologies Inc http://www.menome.com

// Get Spill data from Edmonton Open Data Site example of direct data pull from JSON service
// Imports Spill data from Edmonton Open Data Site using JSON API directly
// Alberta Oil Spills: 
// https://data.edmonton.ca/Environmental-Services/Alberta-Oil-Spills-1975-2013/ek45-xtjs
// API: https://data.edmonton.ca/resource/xir8-nx6p.json?$limit=1000&$offset=number&$order=:id
// *** NOTE *** You will need to sign up for a key on the portal to run this example. 
// Registration is free. 

// if you are using docker, the following command will import this entire file:
// docker exec neo4jdataintegrationmeetup_neo4j_1 sh -c "cat /var/lib/neo4j/import/4_ImportEdmontonSpillData.cql | /var/lib/neo4j/bin/cypher-shell -u neo4j -p password "

// setup constraints
CREATE CONSTRAINT ON (s:Spill) ASSERT s.Code IS UNIQUE;
CREATE CONSTRAINT ON (s:SubstanceReleased) ASSERT s.Code IS UNIQUE;

// setup indexes
CREATE INDEX ON :Spill(Latitude);
CREATE INDEX ON :Spill(Longitude);
CREATE INDEX ON :Spill(Uuid);
CREATE INDEX ON :FieldCenter(Name);
CREATE INDEX ON :FieldCenter(Uuid);


// BENEFITS: Graph and sub-categories auto-resolve : no duplicates are created
// Graph can be extended and added to dynamically - either in batch, or in continous updates
// Duplicates can be detected, matched and reduced on the fly
// https://soda.demo.socrata.com/resource/earthquakes.json?$limit=1000&$offset=number&$order=:id

// Call below is designed to facilitate paging. 
// There are ~61,000 spill incident records in the overall data set. 
// Through texting, its best to run in batches of ~10,000 (i.e. 10000 as pagesTotal, set range in intervals of 10,000)
// Might be possbile to re-write this using APOC periodic iterate. 
WITH 'yourkeyhere' as token,  1000 as pagesTotal
WITH token, RANGE(1,pagesTotal,1000) as fromNumber, "https://data.edmonton.ca/resource/xir8-nx6p.json?$limit=1000&$offset=number&$order=:id" as baseUrl

// loop through results by range step (1000 records is max)
UNWIND fromNumber as from
WITH token, from, REPLACE(baseUrl,'number',toString(from)) as Url

// sleep to prevent hitting throttling threshold
CALL apoc.util.sleep(5)

CALL apoc.load.jsonParams(Url,
{`X-App-Token`:token}, null
) 
yield value as data 

// generate spill node
WITH data as record //limit 5 - for testing
CALL apoc.create.uuids(1) YIELD uuid as Uuid
WITH record, Uuid, record.location_1 as locations // this statement pulls the locations out 

MERGE (s:Spill {Code: record.incident_number}) 
ON CREATE 
set 
s.Uuid = Uuid,
s.Name =  record.incident_number,
s.IndicentId=record.incident_number, 
s.AreaAffected=record.area_affected,
s.EnvironmentAffected=record.environment_affected,
s.PublicAffected = record.PublicAffected,
s.WildlifeLivestockAffected = record.wildlife_livestock_affected,
s.LSD = record.location,
s.FailureType = record.failure_type,
s.FatalityCount = toInt(record.fatality_count),
s.InjuryCount = toInt(record.injury_count),
s.IncidentCompleteDate = replace(left(record.incident_complete_date,10), "-",""),
s.IncidentDate = replace(left(record.incident_date,10), "-",""),
s.IndicentNotificationCate =  replace(left(record.incident_notification_date,10), "-",""),
s.ReleaseCleanupDate = replace(left(record.release_cleanup_date,10), "-",""),
s.ReleaseOffsite = record.release_offsite,
s.SensitiveArea = record.sensitive_area,
s.Source = record.source,
s.StrikeArea = record.strike_area,
s.Latitude = toFloat(locations.coordinates[1]),
s.Longitude = toFloat(locations.coordinates[0]),
s.IncidentType = record.incident_type,
s.LicenseeId = record.licensee_id,
s.LicenseeName = record.licensee_name
ON MATCH 
set 
s.Uuid = Uuid,
s.Name =  record.incident_number,
s.IndicentId=record.incident_number, 
s.AreaAffected=record.area_affected,
s.EnvironmentAffected=record.environment_affected,
s.PublicAffected = record.PublicAffected,
s.WildlifeLivestockAffected = record.wildlife_livestock_affected,
s.LSD = record.location,
s.FailureType = record.failure_type,
s.FatalityCount = toInt(record.fatality_count),
s.InjuryCount = toInt(record.injury_count),
s.IncidentCompleteDate = replace(left(record.incident_complete_date,10), "-",""),
s.IncidentDate = replace(left(record.incident_date,10), "-",""),
s.IndicentNotificationCate =  replace(left(record.incident_notification_date,10), "-",""),
s.ReleaseCleanupDate = replace(left(record.release_cleanup_date,10), "-",""),
s.ReleaseOffsite = record.release_offsite,
s.SensitiveArea = record.sensitive_area,
s.Source = record.source,
s.StrikeArea = record.strike_area,
s.Latitude = toFloat(locations.coordinates[1]),
s.Longitude = toFloat(locations.coordinates[0]),
s.IncidentType = record.incident_type,
s.LicenseeId = record.licensee_id,
s.LicenseeName = record.licensee_name

// Generate Substance Released Node:
WITH s, record
where record.substance_released <> ''
CALL apoc.create.uuids(1) YIELD uuid as Uuid
MERGE (sr:SubstanceReleased {Code: record.substance_released})
ON CREATE
set
sr.Uuid = Uuid,
sr.Name = record.substance_released,
sr.VolumeRecovered = toFloat(record.volume_recovered),
sr.VolumeReleased = toFloat(record.volume_released),
sr.Units = record.volume_units
ON MATCH
set
sr.Uuid = Uuid,
sr.Name = record.substance_released,
sr.VolumeRecovered = toFloat(record.volume_recovered),
sr.VolumeReleased = toFloat(record.volume_released),
sr.Units = record.volume_units

// create SubstanceReleased<-Spill relationship
WITH sr, s, record
MERGE (s)-[:ReleasedSubstance]->(sr)

// merge field center
WITH record, s, upper(record.field_centre) as fieldCenter
where record.field_centre <> ''
CALL apoc.create.uuids(1) YIELD uuid as Uuid
MERGE (f:Field {FieldCenter: fieldCenter})
ON CREATE
set
f.Uuid = Uuid,
f.Name = record.field_centre

MERGE (s)-[:IsInField]->(f)

// Generate/Merge Licensee node and relationship 
WITH record, s
where record.licensee_id <> ''
CALL apoc.create.uuids(1) YIELD uuid as Uuid
MERGE (l:Licensee {Code: record.licensee_id})
ON CREATE
set
l.Uuid = Uuid,
//l.Code = record.licensee_code,
l.LicenseNumber = record.licence_number,
l.LicenseeId = record.licensee_id,
l.LicenseType = record.licence_type,
l.FullName = record.licensee_name
ON MATCH 
set
l.Uuid = Uuid,
//l.Code = record.licensee_code,
l.LicenseNumber = record.licence_number,
l.LicenseeId = record.licensee_id,
l.LicenseType = record.licence_type,
l.FullName = record.licensee_name

WITH record
MATCH (li {Code:record.licensee_id})
MATCH (s {Code:record.incident_number})
MERGE (li)-[:Spilled]->(s);


// GRAPH REFACORING EXAMPLES: 

// Spill FailureType - refactor property to Node
// lets say we want to convert a property to a node:
MATCH (s:Spill) 
where s.FailureType <> ''
CALL apoc.create.uuids(1) YIELD uuid as Uuid
MERGE (f:FailureType {Name:s.FailureType})
ON CREATE
set 
f.Uuid = Uuid

MERGE (s)-[:HasFailureType]->(f)
REMOVE s.FailureType;

// TOO MANY IsInField->Spill links
// Refactor Field Center out of Fields
MATCH (f:Field) 
where f.FieldCenter <> ''
CALL apoc.create.uuids(1) YIELD uuid as Uuid
MERGE (fc:FieldCenter:Card {Name:f.FieldCenter})
ON CREATE
set 
f.Uuid = Uuid

MERGE (f)-[:IsCenteredIn]->(fc)
REMOVE f.FieldCenter;

// remap relationship with spill: 
MATCH (s:Spill)-[d:IsInField]->(f:Field)
MATCH (fc:FieldCenter) where fc.Name=f.Name 

MERGE (s)-[:IsInFieldCenter]->(fc);

// now delete the spill-Field relationship
MATCH (s:Spill)-[d:IsInField]->(f:Field)
DELETE d
