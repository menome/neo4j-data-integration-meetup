// Neo4j Data Integration Example from Calgary Neo4j Graph Meetup, 
// https://www.meetup.com/Calgary-Neo4j-Graph-Meetup/events/237621040/
// Hosted by Menome Technologies Inc, Nulli and Arcurve
// Data Integration Example created by Menome Technologies Inc http://www.menome.com

// Imports Active Facilities from Alberta ATS Site 
// Uses file: ActiveFacility_edctCodes.csv
// Pre-Processed file for use with this import available here:
// https://www.dropbox.com/s/u1rm4d62nqg23nh/DataIntegrationFiles.zip?dl=0
// Original source file from Alberta Energy Regulator Open Data ST102
// https://www.aer.ca/data-and-publications/statistical-reports/st102

// the following command will batch import the active facility data using this file via docker:
// docker exec neo4jdataintegrationmeetup_neo4j_1 sh -c "cat /var/lib/neo4j/import/2_ImportActiveFacilities.cql | /var/lib/neo4j/bin/cypher-shell -u neo4j -p password " 


// constraints
CREATE CONSTRAINT ON (f:Facility) ASSERT f.Code IS UNIQUE;
CREATE CONSTRAINT ON (e:Edct) ASSERT e.Code IS UNIQUE;
CREATE CONSTRAINT ON (s:SubType) ASSERT s.Code IS UNIQUE;
// indexes
CREATE INDEX ON :Facility(Uuid);
CREATE INDEX ON :Facility(Name);
CREATE INDEX ON :Facility(LSD);
CREATE INDEX ON :Operator(Code);
CREATE INDEX ON :SubType(Name);

// Energy Development Category Type (EDCT)
USING PERIODIC COMMIT 1000
LOAD CSV WITH HEADERS FROM 'file:///ActiveFacility_edctCodes.csv' AS line // with line limit 100
// create uuid
CALL apoc.create.uuids(1) YIELD uuid as wuuid

MERGE (c:Edct {  Code: line.EDCT   })
ON CREATE set
    c.Uuid = wuuid,
    c.Name =  line.ShortDescription,
    c.Summary = line.Description;

// Facility 
USING PERIODIC COMMIT 1000
LOAD CSV WITH HEADERS FROM 'file:///ActiveFacility.csv' AS line //with line limit 100
CALL apoc.create.uuids(1) YIELD uuid as fuuid

MERGE (f:Facility {Code: line.FacilityID})
ON CREATE set
f.Uuid= fuuid,
f.Name= line.FacilityName,
f.LSD= line.LSD,
f.LicenseeId= line.LicenseeId,
f.OperatorCode: line.OperatorCode,
f.Status= line.OperationalStatus;

// Facility Has EdctCode EdctCodes
USING PERIODIC COMMIT 1000
LOAD CSV WITH HEADERS FROM 'file:///ActiveFacility.csv' AS line //with line limit 100
CALL apoc.create.uuids(1) YIELD uuid as fuuid

// facility HasEdct Edct 
WITH  line
where line.EDCTCode <> ''
MATCH(e:Edct {Code:line.EDCTCode}) 
MATCH(f:Facility {Code:line.FacilityID})
MERGE(f)-[:HasEdct]->(e);

// Operator
USING PERIODIC COMMIT 1000
LOAD CSV WITH HEADERS FROM 'file:///ActiveFacility.csv' AS line 
WITH line 
where line.OperatorCode <> ''

MATCH (l:Operator {Name: line.OperatorCode})
set
l.Name= line.OperatorName,
l.Code= line.OperatorCode;

// Operator
USING PERIODIC COMMIT 1000
LOAD CSV WITH HEADERS FROM 'file:///ActiveFacility.csv' AS line 
WITH line 
where line.OperatorCode <> ''

// Facility HasOperator Operator
WITH line 
MATCH(o:Operator {Code:line.OperatorCode})
MATCH(f:Facility {Code:line.FacilityID})
MERGE (f)-[:HasOperator]->(o);

// Facility SubType
USING PERIODIC COMMIT 1000
LOAD CSV WITH HEADERS FROM 'file:///ActiveFacility.csv' AS line 
WITH line 
where line.SubTypeCode <> ''
CALL apoc.create.uuids(1) YIELD uuid as Uuid
MERGE (l:SubType {Code: line.SubTypeCode})
ON CREATE set
l.Uuid = line.Uuid,
l.Name= line.SubType
ON MATCH SET
l.Uuid = line.Uuid,
l.Name=line.SubType;

// Facility SubType
USING PERIODIC COMMIT 1000
LOAD CSV WITH HEADERS FROM 'file:///ActiveFacility.csv' AS line 
WITH line 
where line.SubTypeCode <> ''

// Facility SUBTYPE
WITH line 
MATCH(s:SubType {Code:line.SubTypeCode})
MATCH(f:Facility {Code:line.FacilityID})
MERGE (f)-[:HAS_SUBTYPE]->(s);
