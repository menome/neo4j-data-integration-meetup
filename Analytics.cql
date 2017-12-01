// Not all spils have a licensee ID, so see if we can match using string methods

// find out how many spills don't have a relationship to licensee based on ID
match (s:Spill) where not (s)-[]-() 
WITH s
MATCH (l:Licensee) where l.NameKey = s.NameKey return count(distinct s),count(distinct l)

// set property on existing relationships to 1 to show they are explicit
MATCH (l:Licensee)-[r:Licensee]-(s:Spill) set r.Weight=1

// generate cleaned string key
MATCH (n:Licensee) with n set n.NameKey=apoc.text.clean(n.FullName)

// generate phoneme string key
MATCH (n:Spill) with n call apoc.text.phonetic(n.LicenseeName) yield value as phonetic WITH phonetic,n set n.NamePhonemeKey=phonetic

// find out which spill nodes don't have a relationship
match (s:Spill) where not (s)-[]-() return count(s)

// Match using stringKey
match (s:Spill) where not (s)-[]-() 
WITH s
MATCH (l:Licensee) where l.NameKey = s.NameKey return count(distinct s),count(distinct l)

// Try match on string key


// count wells and spills for licensees
MATCH (l:Licensee)<-[:LicensedTo]-(li:License)<-[:HasLicense]-(w:Well) 
WITH l,w
OPTIONAL MATCH (l)-[:Spilled]->(s:Spill) 
return l.Name, count(distinct w), count(distinct s)  order by count(distinct w) descending

// licensees with wells and spills
MATCH (s:Spill)-[]-(l:Licensee)-[]-(lc:License)
WITH lc , l,count(s) as spillCount limit 1000
MATCH (lc)-[]-(w:Well) 
return l.Name, l.FullName,count(distinct w) as wellCount,  spillCount order by wellCount descending

// number of wells for licensee
match (s:Spill)-[]-(li:Licensee)-[]-(l:License)-[]-(w:Well) 
return li.Name, count(distinct w) order by count(distinct w) desc

// have to find out if lat/long or LSD are coincident between spill and well



// generate heatmap 
MATCH (sr:SubstanceReleased)<-[SubstanceReleased]-(a:Spill)-[:SPILL_NEAR_WELL]->(o:Well)-[:LICENSEE_OF]->(e:Licensee)
              WHERE exists(a.Latitude) and exists(a.Longitude) 
              WITH a, COLLECT(DISTINCT o)[0..5] AS wells, COLLECT(DISTINCT e)[0..5] AS entities, COLLECT(DISTINCT sr.Name)[0..5] AS substance, 1.0*COUNT(*) AS strength
              RETURN a.EnvironmentAffected AS spill, a.Latitude AS latitude, a.Longitude AS longitude, [x IN wells | x.Name] as wells, [x IN entities | x.FullName] as licensees, substance, strength

// generate heatmap with distance as strenght 
MATCH (sr:SubstanceReleased)<-[SubstanceReleased]-(a:Spill)-[:SPILL_NEAR_WELL]->(o:Well)-[:LICENSEE_OF]->(e:Licensee)
              WHERE exists(a.Latitude) and exists(a.Longitude) 
              WITH a, COLLECT(DISTINCT o)[0..5] AS wells, COLLECT(DISTINCT e)[0..5] AS entities, COLLECT(DISTINCT sr.Name)[0..5] AS substance, sum(sn.Distance) AS strengthAS strength
              RETURN a.EnvironmentAffected AS spill, a.Latitude AS latitude, a.Longitude AS longitude, [x IN wells | x.Name] as wells, [x IN entities | x.FullName] as licensees, substance, strength
