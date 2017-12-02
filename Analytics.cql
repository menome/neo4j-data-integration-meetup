// Not all spils have a licensee ID, so see if we can match using string methods
// set property on existing relationships to 1 to show they are explicit
MATCH (l:Licensee)-[r:Licensee]-(f:Facility) set r.Weight=1

// number of facilities not matched
match (s:Facility) where not (s)-[]-() return count(s)

// clean name string example
// generate cleaned string key
MATCH (f:Facility) where not (f)-[]-() return apoc.text.clean(f.Name)

// generate phonetic key
MATCH (n:Facility) with n call apoc.text.phonetic(f.LicenseeName) yield value as phonetic return phonetic

// generate clean name string property
MATCH (n:Facility) with n set n.NameKey=apoc.text.clean(n.OperatorName)

// illustrate matches based on string
match (f:Facility) where not (f)-[]-() 
WITH f 
MATCH (l:Licensee) where l.NameKey = apoc.text.clean(f.OperatorName) 
MERGE (f)-[:LICENSEE_OF{Weight:2}]->(l)

 

// illustrate match based on phoneme
match (f:Facility) where not (f)-[]-() 
WITH f 
call apoc.text.phonetic(f.OperatorName) yield value  as phoneme
WITH f, phoneme
MATCH (l:Licensee) where l.NamePhonemeKey = phoneme  return count(f)

// merge relationship
match (f:Facility) where not (f)-[]-() 
WITH f 
call apoc.text.phonetic(f.OperatorName) yield value  as phoneme
WITH f, phoneme
MATCH (l:Licensee) where l.NamePhonemeKey = phoneme 
MERGE (f)-[:LICENSEE_OF{Weight:3}]->(l)


// generate phoneme string key
MATCH (n:Facility) with n call apoc.text.phonetic(n.OperatorName) yield value as phonetic WITH phonetic,n set n.NamePhonemeKey=phonetic

// Find spills that don't have a match that can be matched based on cleaned string 
match (f:Facility) where not (f)-[]-() 
WITH f
MATCH (l:Licensee) where l.NameKey = f.NameKey return count(distinct s),count(distinct l)


// ------------ 
// ANALYTICS:
//Basic statistics over the data tell us that we have these entities:
MATCH (n)
RETURN labels(n), count(*)
ORDER BY count(*) DESC


MATCH (n)
WITH labels(n) AS type, size( (n)--() ) AS degree
RETURN type,
       max(degree) AS max, round(avg(degree)) AS avg, round(stdev(degree)) AS stdev

// count wells and spills for licensees


// licensees with wells and spills
MATCH (s:Spill)-[]-(l:LICENSEE_OF)-[]-(lc:License)
WITH lc , l,count(s) as spillCount limit 1000
MATCH (lc)-[]-(w:Well) 
return l.Name, l.FullName,count(distinct w) as wellCount,  spillCount order by wellCount descending

// number of wells for licensee
match (s:Spill)-[]-(li:LICENSEE_OF)-[]-(l:License)-[]-(w:Well) 
return li.Name, count(distinct w) order by count(distinct w) desc

// ------------ 
// SPATIAL ANALYTICS:
// have to find out if lat/long or LSD are coincident between spill and well
MATCH  p=(e:Well)-[:LICENSEE_OF]-(o:Licensee)-[:LICENSEE_OF]-(a:Spill)
WHERE exists(a.Latitude) AND exists(a.Longitude)
AND DISTANCE(POINT({latitude: toFloat(a.Latitude), longitude:toFloat(a.Longitude)}), POINT({latitude: toFloat(e.Latitude), longitude:toFloat(e.Longitude)})) < 100
RETURN p limit 100


/ generate heatmap 
MATCH (sr:SubstanceReleased)<-[SubstanceReleased]-(a:Spill)-[:SPILL_NEAR_WELL]->(o:Well)-[:LICENSEE_OF]->(e:Licensee)
              WHERE exists(a.Latitude) and exists(a.Longitude)
              WITH a, COLLECT(DISTINCT o)[0..5] AS wells, COLLECT(DISTINCT e)[0..5] AS entities, COLLECT(DISTINCT sr.Name)[0..5] AS substance, 1.0*COUNT(*) AS strength
              RETURN a.EnvironmentAffected AS spill, a.Latitude AS latitude, a.Longitude AS longitude, [x IN wells | x.Name] as wells, [x IN entities | x.FullName] as licensees, substance, strength

// generate heatmap with distance as strenght 
MATCH (sr:SubstanceReleased)<-[SubstanceReleased]-(a:Spill)-[sn:SPILL_NEAR_WELL]->(o:Well)-[:LICENSEE_OF]->(e:Licensee)
              WHERE exists(a.Latitude) and exists(a.Longitude)
              WITH a, COLLECT(DISTINCT o)[0..5] AS wells, COLLECT(DISTINCT e)[0..5] AS entities, COLLECT(DISTINCT sr.Name)[0..5] AS substance, sum(sn.Distance) AS strength
              RETURN a.EnvironmentAffected AS spill, a.Latitude AS latitude, a.Longitude AS longitude, [x IN wells | x.Name] as wells, [x IN entities | x.FullName] as licensees, substance, strength



// generate heatmap with crude oil released as strength 
MATCH       (sr:SubstanceReleased {Name:'Crude Oil'})<-[SubstanceReleased]-(a:Spill)-[sn:SPILL_NEAR_WELL]->(o:Well)-[:LICENSEE_OF]->(e:Licensee)
              WHERE exists(a.Latitude) and exists(a.Longitude)
              WITH a, COLLECT(DISTINCT o)[0..5] AS wells, COLLECT(DISTINCT e)[0..5] AS entities, COLLECT(DISTINCT sr.Name)[0..5] AS substance, sum(a.VolumeReleased) AS strength
              RETURN a.EnvironmentAffected AS spill, a.Latitude AS latitude, a.Longitude AS longitude, [x IN wells | x.Name] as wells, [x IN entities | x.FullName] as licensees, substance, strength


              // generate heatmap with salt and produced water released as strength 
MATCH       (sr:SubstanceReleased {Name:'Salt/Produced Water'})<-[SubstanceReleased]-(a:Spill)-[sn:SPILL_NEAR_WELL]->(o:Well)-[:LICENSEE_OF]->(e:Licensee)
              WHERE exists(a.Latitude) and exists(a.Longitude)
              WITH a, COLLECT(DISTINCT o)[0..5] AS wells, COLLECT(DISTINCT e)[0..5] AS entities, COLLECT(DISTINCT sr.Name)[0..5] AS substance, sum(a.VolumeReleased) AS strength
              RETURN a.EnvironmentAffected AS spill, a.Latitude AS latitude, a.Longitude AS longitude, [x IN wells | x.Name] as wells, [x IN entities | x.FullName] as licensees, substance, strength order by strength desc


              // where licensee and operator are different vs the same in terms of number of spills




// time required to clean up spill
// calculate number of days between incident date and time cleaned up
Match (s:Spill)
WITH s,  apoc.date.parse(s.ReleaseCleanupDate,'d','yyyyMMdd') - apoc.date.parse(s.IncidentDate,'d','yyyyMMdd')  as days 
WHERE days is not null  and days <> 0 SET s.CleanupTimeInDays=days  return s

// for salt - how fast does cleanup happen? 
MATCH (sr:SubstanceReleased {Name:'Salt/Produced Water'})<-[SubstanceReleased]-(s:Spill)-[sn:SPILL_NEAR_WELL]->(w:Well)-[:LICENSEE_OF]->(li:Licensee)
WITH s,w,li, sum(s.VolumeReleased) AS productVolume 
RETURN li.FullName, collect(distinct w.Name), productVolume order by productVolume desc limit 20


// do things in the north not get cleaned up as quickly as things in the south - i.e. near towns
// township (township 1 montana, 115 farther north) vs time between spill incident and cleanup...?
// over given decade? - 
MATCH (sr:SubstanceReleased {Name:'Salt/Produced Water'})<-[SubstanceReleased]-(s:Spill)-[sn:SPILL_NEAR_WELL]->(w:Well)-[:LICENSEE_OF]->(li:Licensee) WHERE exists(s.CleanupTimeInDays)
WITH s,w,li, sum(s.VolumeReleased) AS productVolume, toInt(split(s.LSD,'-')[2]) as township 
RETURN li.FullName, collect(distinct w.Name), s.CleanupTimeInDays, township, productVolume order by  s.CleanupTimeInDays, township  limit 1000


// game of licensees
// find out what things husky and CNRL have in common
MATCH (one:Licensee {NameKey: "huskyoiloperationslimited"}), (two:Licensee {NameKey: "canadiannaturalresourceslimited"})
MATCH p=allShortestPaths((one)-[*]-(two)) 
RETURN p

