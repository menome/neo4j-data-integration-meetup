
FROM neo4j:3.2.3-enterprise
COPY neo4j.conf /var/lib/neo4j/conf/neo4j.conf

# copy demo files into the link import dir
COPY *.cql import/

# copy plugins into the neo4j plugins folder
COPY plugins/* plugins/ 
