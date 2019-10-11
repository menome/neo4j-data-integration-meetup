// refactor license
MATCH (w:Well) with w limit 1
merge (l:License {License:w.Licence})
ON CREATE set
l.Uuid=apoc.create.uuid(),
l.Type='Well'
ON MATCH set
l.Uuid=w.Uuid, 
l.Type='Well'
with w,l
merge (w)-[:HAS_LICENSE]->(l)
return w,l
