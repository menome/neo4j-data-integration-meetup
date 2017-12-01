
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



// --- fuzzy name matching 
// add phoneme string to spill node
match (s:Spill) with  s limit 1
CALL apoc.text.phonetic(s.LicenseeName) YIELD value as phoneme WITH phoneme, s set s.PhonemeKey=phoneme return s

match (li:Licensee) with  li limit 1
CALL apoc.text.phonetic(li.FullName) YIELD value as phoneme WITH phoneme, s set s.PhonemeKey=phoneme return li


// match up Facility and SPill based on LSD
MATCH (f:Facility)
MATCH (s:Spill) 

Where f.LSD = s.LSD return f,s limit 100

