### Neo4j Data Integration Demonstration:

[Menome Technologies](http://www.menome.com), created this example to help illustrate the power and potential of Neo4j's data integration capabilities. This post will go through a technical example.

*   An overview is provided  [here](https://www.menome.com/wp/data-integration-challenge/).
*   The presentation from the meetup is here: [161114-5 Calgary Meetup 1.pptx](https://www.menome.com/wp/wp-content/uploads/2017/03/161114-5-Calgary-Meetup-1.pptx.zip)
*   The meetup site for calgary graph databases is here: [Calgary Neo4j Neo4 Graph Meetup Site](https://www.meetup.com/Calgary-Neo4j-Graph-Meetup/events/237621040/)

This example uses well data, facility and licensee data from the Alberta Energy Regulator site, and integrated it with spill data from the Edmonton Open Data Portal using the JSON API. The AER site data is downloadable in CSV and text formats. Our goal was to integrate these data in as few steps as possible, with as little pre-processing as possible. I was able to keep the pre-processing to  adding clean column names, and doing a pass to transform the Lat Long coordinates into WGS84 (typically used by google maps) from the format used in the file. Our objective will be to integrate these data to form the following graph: [![Screen Shot 2017-03-31 at 5.26.01 PM](https://www.menome.com/wp/wp-content/uploads/2017/03/Screen-Shot-2017-03-31-at-5.26.01-PM-1024x742.png)](https://www.menome.com/wp/?attachment_id=9144)

#### Source Data:

Original Source Files for this example:

*   [Alberta Energy Regulator: Licensee Codes](https://www.aer.ca/data-and-publications/statistical-reports/st104)
*   [Alberta Energy Regulator: Active Facilities](https://www.aer.ca/data-and-publications/statistical-reports/st102)
*   [Alberta Energy Regulator: Well Dat](https://www.aer.ca/data-and-publications/statistical-reports/st37)a

The pre-processed data files I created from these files for the example you can download from:

*   Pre-processed [DataIntegrationFiles](https://www.menome.com/wp/wp-content/uploads/2017/03/DataIntegrationFiles.zip)

The JSON feed for the spill data from the Edmonton Open Data Portal is here:

*   [Edmonton Open Data Portal Alberta Oil Spills ](https://data.edmonton.ca/Environmental-Services/Alberta-Oil-Spills-1975-2013/ek45-xtjs) - you will need to sign up for a key (free registration)

The final graph.db Neo4j database if you just want to skip to the punch line is here:

* [www.menome.com/menome/graph.db.zip] (http://www.menome.com/menome/graph.db.zip)

#### Preparation:

Use GIT to clone the[ https://github.com/menome/neo4j-data-integration-meetup](https://github.com/menome/neo4j-data-integration-meetup) repo. You will need to have a clean instance of Neo4j running. We have provided a **docker file** and a **docker-compose.yml** file for this, and the steps below assume you are using docker although you don't have to. If you want to perform the reverse geocoding step, you will need to register for and add a google maps API key to the **neo4j.conf** file:


*   apoc.spatial.geocode.google.key=YOUR_GOOGLE_MAPS_API_KEY_HERE

Create a /**neo4jdata** folder, and create an **import** subfolder. The docker-compose.yml file will map the Neoj **import** folder to this location outside the docker container. This way you can copy and manipulate the files outside the docker container. Download the Pre Processed files for the Data Integration example from here: [DataIntegrationFiles](https://www.menome.com/wp/wp-content/uploads/2017/03/DataIntegrationFiles.zip) and extract them  into the **/neo4jdata/import** folder. Copy the *.cql files to the  **/neo4jdata/import** folder. This will make the import files and the cypher command files available inside the Neoj docker container. If you are running Neoj in another way or on the cloud, you will need to copy these files into the Neoj **import** folder on the server you are using.

If you have docker Mac or Windows, you can start a container up by opening a shell and executing:

> 1.  **docker-compose build**
> 2.  **docker-compose up -d**

This will build and start a Neoj database. The data will reside on /neo4jdata/data. Once the database is running, start a web browser and go to the following address:

1.  http://localhost:7474/
2.  If the database is running, you should see the Neoj browser come up and ask for a password - set a new password.
3.  You should now have a blank Neoj database.

The .cql cypher command files are designed to be either used as a batch by calling the cypher-shell, or you can step through them by copying and pasting the individual cypher commands into the Neoj browser. For the purposes of pasting the code into the Neoj browser, each command section is terminated by a semi-colon. The .cql cypher command files are named to match the corresponding import file source.

#### Import The Well Data:

In order to import the Well data, we first need to have a look and get a sense of how the tabular data will be transformed into Nodes and Relationships. Typically CSV files will correspond to one main node type: in this case Wells. A rule of thumb in the graph world is that things that normally would be 'properties' or 'columns' in a traditional data model should be created as 'Nodes', with an appropriate relationship.  If we have a look at the Well file, we can see the columns in the CSV file as marked might make good nodes: [![](https://www.menome.com/wp/wp-content/uploads/2017/05/Screen-Shot-2017-04-02-at-6.01.50-PM-1024x573.png)](https://www.menome.com/wp/?attachment_id=9237) Start by importing the **WellListLocationsWGS84.csv** file using  the 1_**ImportWellLocations.cq**l file. You can paste each of the commands individually from the .cql file, or paste the following command into a shell, which will execute the cypher-shell inside the docker container, and feed in the .cql command file (NOTE* - I have noticed depending on the machine, the command may paste with the wrong double quote style...):



> docker exec neo4jdataintegrationmeetup_neo4j_1 sh -c "cat /var/lib/neo4j/import/1_ImportWellLocations.cql | /var/lib/neo4j/bin/cypher-shell -u neo4j -p password "

If the command is running correctly, you should see messages begin to appear in the shell as the cypher-shell executes: eg. 'Adding 1 constraints'. There are in excess of 500,000 well records, so the file may take some time to process depending on how much memory etc. you have.  You can always cut down the size of the import either by truncating the file, or by setting a LIMIT on the cypher command for the well import (I left a LIMIT commented out at the end of the LOAD CSV statement).



You can inspect the file to get a sense of the commands and how the import is structured, but in general I am re-running the import for each Node type, and creating the associated relationship.

[![](https://www.menome.com/wp/wp-content/uploads/2017/05/Screen-Shot-2017-04-02-at-6.01.29-PM-1024x424.png)](https://www.menome.com/wp/?attachment_id=9239)

[![](https://www.menome.com/wp/wp-content/uploads/2017/05/Screen-Shot-2017-04-02-at-6.01.38-PM-1024x580.png)](https://www.menome.com/wp/?attachment_id=9238)

While you could do this as a single statement, using WITH to feed the file through the sequence, I did this to commit the transaction for each Node type boundary. This way if it only partially completes I can simply start the command from the failed step instead of having to re-run the whole thing.

When it completes you should have the following graph:

 [![](https://www.menome.com/wp/wp-content/uploads/2017/05/Screen-Shot-2017-04-02-at-6.20.09-PM-1024x807.png)](https://www.menome.com/wp/?attachment_id=9247)



#### Import The Active Facility Data:

This follows the same pattern as the well example. In this case though the thing to focus on is the fact we will be integrating a different data set that contains overlapping data - in this case operators.

[![](https://www.menome.com/wp/wp-content/uploads/2017/05/Screen-Shot-2017-04-02-at-6.11.55-PM-1024x561.png)](https://www.menome.com/wp/?attachment_id=9245)

One of the powerful things about integrating data with Neo4j is the fact that the graph database does a great job in terms of handling this type of data integration. Using the MERGE statement, we can tell Neo4j to either add a new node and relationship if those don't already exist for incoming OperatorNode data, or merge the incoming data with an existing node. There are a lot of powerful things that can be done from an ETL perspective with this in terms of enabling regular runs of integration scripts that simply update data and relationships where needed.

[![](https://www.menome.com/wp/wp-content/uploads/2017/05/Screen-Shot-2017-04-02-at-6.12.05-PM-1024x564.png)](https://www.menome.com/wp/?attachment_id=9244)

Run the command below in the shell to import the Active Facility data and merge the operators:

docker exec neo4jdataintegrationmeetup_neo4j_1 sh -c "cat /var/lib/neo4j/import/2_ImportActiveFacilities.cql | /var/lib/neo4j/bin/cypher-shell -u neo4j -p password "

If you import the full set, it will take a while - again depending on the amount of ram etc. you have available.

Once its complete you should have the following graph:

[![](https://www.menome.com/wp/wp-content/uploads/2017/05/Screen-Shot-2017-04-02-at-7.17.55-PM-1024x806.png)](https://www.menome.com/wp/?attachment_id=9259)

#### Import The Licensee Data:

The Licensee data set will build and extend the original set imported with the Well data. Integrating this data set in will add address data to Licensees as part of the process. The more you can connect and integrate data, the more valuable it becomes. Adding address data to the set increases the value of the data by itself, - but with Neo4j, we can take this even further by harnessing the [APOC extensions](https://neo4j-contrib.github.io/neo4j-apoc-procedures/#_configuring_geocode). By setting the following configuration in the neo4j.conf file:


> # APOC geocoding
> 
> apoc.spatial.geocode.provider=google
> 
> apoc.spatial.geocode.google.throttle=100
> 
> apoc.spatial.geocode.google.key=YOUR_GOOGLE_MAPS_API_KEY_HERE


we can set Neoj up to automatically geocode the Licensee addresses!

[![](https://www.menome.com/wp/wp-content/uploads/2017/05/Screen-Shot-2017-04-02-at-6.12.13-PM-1024x571.png)](https://www.menome.com/wp/?attachment_id=9243)

I have been making extensive use of this already for clients. APOC also gives powerful tools for doing similarity comparisons that help identify duplicate address data. We have big plans for this feature.

Once you have the configuration setup, restart docker-compose with docker-compose up -d and paste the following statement into the shell:

docker exec neo4jdataintegrationmeetup_neo4j_1 sh -c "cat /var/lib/neo4j/import/3_ImportLicensee.cql | /var/lib/neo4j/bin/cypher-shell -u neo4j -p password "

We should now have Licensees with Address and Lat Long data on them!

[![](https://www.menome.com/wp/wp-content/uploads/2017/05/Screen-Shot-2017-04-02-at-8.17.55-PM-1024x808.png)](https://www.menome.com/wp/?attachment_id=9262)

#### Import the Edmonton Spill Data:

And now le pièce de résistance: we will directly integrate spill incident data from the Edmonton Open Data Portal using the Neo4j [APOC extensions json importer](https://neo4j-contrib.github.io/neo4j-apoc-procedures/#_load_json_2).

The great this about this is the potential it opens up to be able to continuously keep a graph up to date from a remote API source. By using this either through an external program passing the cypher call into Neoj, or by using the APOC periodic execution function, it becomes possible to continuously integrate data!

The JSON data from the Edmonton portal is shaped as follows:

[![](https://www.menome.com/wp/wp-content/uploads/2017/05/Screen-Shot-2017-04-02-at-6.35.53-PM-859x1024.png)](https://www.menome.com/wp/?attachment_id=9251)

You will notice that inside the JSON there is a sub-section describing a location. The great news here is that using Neo4j it becomes very simple to take a fairly complex JSON structure and turn it into a graph with a very small number of commands relative to what it would take in an equivalent SQL ETL (I have commented the location pull in the cypher).

Rest APIs often will throttle and have limits on how much data you can pull at a time. Cypher gives us a nice way of handling these situations as well:

    WITH 'YOUR_EDMONTON_DATA_PORTAL_KEY_HERE' as token, 1000 as pagesTotal
     WITH token, RANGE(1,pagesTotal,1000) as fromNumber, "https://data.edmonton.ca/resource/xir8-nx6p.json?$limit=1000&$offset=number&$order=:id" as baseUrl// loop through results by range step (1000 records is max)
     UNWIND fromNumber as from
     WITH token, from, REPLACE(baseUrl,'number',toString(from)) as Url// sleep to prevent hitting throttling threshold
     CALL apoc.util.sleep(5)CALL apoc.load.jsonParams(Url,
     {`X-App-Token`:token}, null
     )
     yield value as data

You will notice in the statement above that I set a **pagesTotal** parameter that I then feed into a range. I then use a REPLACE statement to put the resulting offset into the URL I am passing. This way I can have repeatedly call the API through cypher and step through, download and integrate all the data in segments. In this case, you will see that I have limited the pagesTotal to 1000 - there are ~62,000 spill records in the total data set if you wanted to pull more data down.

Finally you will notice the **CALL apoc.util.sleep(5)** command - this pauses the call for 5ms, which will prevent our call from exceeding the API's throttling limits.

You will need to register for an Edmonton Open Data portal to get a key. This key must be added to the **3_ImportLicensee.cql - **'**YOUR_EDMONTON_DATA_PORTAL_KEY_HERE**'

When you are set to go, paste the following into your command shell:

docker exec neo4jdataintegrationmeetup_neo4j_1 sh -c "cat /var/lib/neo4j/import/4_ImportEdmontonSpillData.cql | /var/lib/neo4j/bin/cypher-shell -u neo4j -p password "

Once the command completes, we should have a graph that looks like:  


#### Graph Refactoring:

Neo4j's graph structure makes adjusting, adapting and evolving the structure of data simple to accomplish. There are cases where in the course of integrating data, it becomes evident that values imported as properties should in fact be nodes. Modifying the graph to extract properties to nodes is a simple process. In our graph, we notice that the FailureType property on the Spill node might be a very useful element of data to match patterns on. The following statement will take the FailureType property, create a node from it, set a relationship with the Spill node, and then remove the property from the Spill node.

```
// Spill FailureType - refactor property to Node
// lets say we want to convert a property to a node:
MATCH (s:Spill)
where s.FailureType <> ''
CALL apoc.create.uuids(1) YIELD uuid as Uuid
MERGE (f:FailureType:Card {Name:s.FailureType})
ON CREATE
set
f.Uuid = Uuid
MERGE (s)-[:HasFailureType]->(f)
REMOVE s.FailureType;
```


Another type of refactoring involves changing or restructuring relationships to make the graph more clear, more efficient or to make implicit relationships explicit. In the case of the graph we are setting up, we notice that the Field node has become very 'dense'. 

 [![](https://www.menome.com/wp/wp-content/uploads/2017/05/Screen-Shot-2017-04-03-at-6.15.53-PM-1024x1004.png)](https://www.menome.com/wp/?attachment_id=9273)

The Field node also has a FieldCenter property on it. On inspection, it becomes clear that extracting this property to a node would allow us to reduce the number of relationships that directly connect to the node, while also increasing the usefulness of the graph. The following set of statements takes the FieldCenter property, turns it into a node sets up a relationship and removes the property. We then match the Spill and the FieldCenter, and setup a relationship between these nodes. Finally, we remove the original relationship between Spill and Field nodes.


```
// TOO MANY IsInField->Spill links
// Refactor Field Center out of Fields
MATCH (f:Field)
where f.FieldCenter <> ''
CALL apoc.create.uuids(1) YIELD uuid as Uuid
MERGE (fc:FieldCenter:Card {Name:f.FieldCenter})
ON CREATE
set
f.Uuid = Uuid
MERGE (f)-[:IsCenteredIn]->(fc)
REMOVE f.FieldCenter;

// remap relationship with spill:
MATCH (s:Spill)-[d:IsInField]->(f:Field)
MATCH (fc:FieldCenter) where fc.Name=f.Name
MERGE (s)-[:IsInFieldCenter]->(fc);

// now delete the spill-Field relationship
MATCH (s:Spill)-[d:IsInField]->(f:Field)
DELETE d
```


Our graph should now look like:

[![](https://www.menome.com/wp/wp-content/uploads/2017/05/Screen-Shot-2017-04-03-at-6.21.44-PM-1024x758.png)](https://www.menome.com/wp/?attachment_id=9274)

And our final graph schema for this example:

[![](https://www.menome.com/wp/wp-content/uploads/2017/05/Screen-Shot-2017-04-03-at-6.23.03-PM-1024x742.png)](https://www.menome.com/wp/?attachment_id=9275)

I hope to have some time in the near future to work this example further by introducing some more data elements, and then running some analytics on the Spills, Wells, Facilities, Licensees and Operators.

We also plan to put up an example of this data set inside of the open source version of our Knowledge Dicsovery platform [ -->theLink<-- ](https://www.menome.com/wp/products/): Watch for more on that front soon!

If you have any questions, please do not hesitate to contact me (can get me on linkedIn)!

Thanks [Mike Morley...](https://www.linkedin.com/in/mikemorley/)!

[Menome Technologies Inc.](https://www.menome.com)
