#! /bin/sh
# This should be run outside of the container.
docker exec thelinkcommunity_neo4j_1 sh -c "cat /var/lib/neo4j/import/theLinkHNI/setupNeo4j.cql | /var/lib/neo4j/bin/cypher-shell -u neo4j -p password "   
docker exec thelinkcommunity_neo4j_1 sh -c "cat /var/lib/neo4j/import/theLinkHNI/ImportWellLocations.cql | /var/lib/neo4j/bin/cypher-shell -u neo4j -p password "   




