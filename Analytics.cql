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