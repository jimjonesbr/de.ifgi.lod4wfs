
prefixes <- "
@prefix geo:  <http://www.opengis.net/ont/geosparql/1.0#> . 
@prefix my:   <http://ifgi.lod4wfs.de/resource/> . 
@prefix dbpedia-owl: <http://dbpedia.org/ontology/> . 
@prefix dbpedia-prop: <http://dbpedia.org/property/> . 
@prefix rdf:     <http://www.w3.org/1999/02/22-rdf-syntax-ns#> . 
@prefix dct: <http://purl.org/dc/terms/> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix sf:   <http://www.opengis.net/ont/sf#> . 
@prefix dc:   <http://purl.org/dc/elements/1.1/> .
@prefix vocab:   <http://test.vocabulary.com/> . 

\n"

basePrefix <- "my"

subject <- paste(basePrefix,":GEO_RIVER_",sep="")
geometryPredicate <- "geo:asWKT " 
featureSubject <- paste(basePrefix,":FEATURE_RIVER_",sep="")

shpFolder <- "/home/jones/Desktop/AMAZ_LEG_HIDRO_POL_250/" 
shpName <- "AMAZ_LEG_HIDRO_POL_250" # Shapefile name, WITHOUT extension.


geometryID <- 0 # Column number of the geometry ID in the DBF file, or 0 for using record sequencial.
outputFile <- "/home//jones/Desktop/hydrology_amazon.nt"

#Named Graph information.
namedGraph <- "<http://ifgi.lod4wfs.de/layer/amazon_hydrology>"
abstract <- "Rivers of the Brazilian Amazon - LOD4WFS Test Dataset."
title <- "Brazilian Amazon Hidrology"
keywords <- "hidrology, linked open data, lod4wfs, amazon"

# Mapping geometry's attribute table to predicates.
mapping <- cbind()

mapping[1] <- "my:isnavigab"
mapping[2] <- "my:isintermi"
mapping[3] <- "my:refoctyp"
mapping[4] <- "my:name"
mapping[5] <- "my:nameofas"
mapping[6] <- "my:classifica"
mapping[7] <- "my:refocide"
mapping[8] <- "my:projectid"
mapping[9] <- "my:featureid"
mapping[10] <- "my:shapearea"
mapping[11] <- "my:shapelen"

##################################### Don't change! #############################################

options(warn=-1)

require(rgdal)
require(rgeos)

formatSubject = function(object) {object}
setGeneric("formatSubject", 
           function(object) 
             standardGeneric("formatSubject"))

setMethod("formatSubject", 
          definition = function(object)
          {            
            
            result = gsub("\\s","_",object)
            result = gsub("\\,","_",result)
            result = gsub("\\+","_",result)
            result = gsub("\\&","_",result)
            result = gsub("\\%","_",result)
            result = gsub("\\!","_",result)
            result = gsub("\\\"","_",result)
            result = gsub("\\?","_",result)
            result = gsub("\\§","_",result)
            result = gsub("\\=","_",result)
            result = gsub("\\ß","_",result)
            result = gsub("\\(","_",result)
            result = gsub("\\)","_",result)
            result = gsub("\\$","_",result)
            result = gsub("\\/","_",result)
            result = gsub("\\[","_",result)
            result = gsub("\\]","_",result)
            result = gsub("\\#","_",result)
            result = gsub("\\@","_",result)
            result = gsub("\\^","_",result)
            result = gsub("\\°","_",result)
            result = gsub("\\:","_",result)
            result = gsub("\\;","_",result)
            
            return(result)
          }
          
)

features <- readOGR(shpFolder,shpName,dropNULLGeometries=TRUE)
feature_type <- data.frame((slotNames(features)))

plot(features)

cat(paste(prefixes,"\n"), file=outputFile,append=FALSE)

# Identifying feature type
if(feature_type[2,]=="lines") {
  print("Feature type: Line")
  spoly <- features@lines
  max <- length(spoly)
}

if(feature_type[2,]=="polygons") {
  print("Feature type: Polygon")
  spoly <- features@polygons
  max <- length(spoly)
}

if(feature_type[3,]=="coords") {
  print("Feature type: Point")
  spoly <- features@coords
  max <- nrow(spoly)
}


# Storing the attribute table (DBF)
df <- features@data
print("Converting shapefile to RDF triples, please wait...")
temp.matrix <- cbind("     ")

#Creating triples related to the Feature (Shapefile)
cat(namedGraph," dct:abstract \"",abstract,"\"^^xsd:string . \n",sep="", file=outputFile,append=TRUE)
cat(namedGraph," dct:title \"",title,"\"^^xsd:string . \n",sep="", file=outputFile,append=TRUE)
cat(namedGraph," dct:subject \"",keywords,"\"^^xsd:string . \n",sep="", file=outputFile,append=TRUE)  


# Iterating over the shapefile geometries
for(i in 1:max){
  # Storing the geometry of a single record
  temp_spo <- spoly[i]
  temp_df <- formatSubject(format(df[i,],scientific=FALSE))
  # Storing current geometry record, using spatial functions for each geometry type.
  if(feature_type[2,]=="lines") {
    polys_single_feature <- SpatialLines(temp_spo) 
  }
  
  if(feature_type[3,]=="coords") {
    temp_spo <- spoly[i,]
    polys_single_feature <- SpatialPoints(cbind(temp_spo[1],temp_spo[2])) 
  }
  
  if(feature_type[2,]=="polygons") {
    polys_single_feature <- SpatialPolygons(temp_spo) 
    
  }
  
  # - Creating triple subject
  if (geometryID==0) {
    subject2 <- paste(subject, i,sep="")  
    featureSubject2 <- paste(featureSubject, i,sep="")  
  } else {
    subject2 <- paste(subject, temp_df[geometryID],sep="")
    featureSubject2 <- paste(featureSubject, temp_df[geometryID],sep="")
  }
  
  # - Creating triple object with coordinates in Well Known Text
  wkt <- writeWKT(polys_single_feature, byid = FALSE)
  
  Encoding(geometryPredicate) <- "UTF-16"
  Encoding(subject2) <- "UTF-16"
  Encoding(wkt) <- "UTF-16"
  
  
  if (temp.matrix[i] != paste("\n",subject2," ",geometryPredicate," ","\"",wkt,"\" .")){
    
    cat("\n",subject2," a geo:Geometry .",sep="", file=outputFile,append=TRUE)    
    cat("\n",featureSubject2," a geo:Feature .",sep="", file=outputFile,append=TRUE)  
    cat("\n",featureSubject2," geo:hasGeometry ", subject2, " ." ,sep="", file=outputFile,append=TRUE)      
    
    cat("\n",paste(subject2," ",geometryPredicate," "),file=outputFile,append=TRUE)
    cat("\"<http://www.opengis.net/def/crs/EPSG/0/4326> ", file=outputFile,append=TRUE)    
    cat(wkt, file=outputFile,append=TRUE)     
    cat("\"^^sf:wktLiteral . \n", file=outputFile,append=TRUE)
    
  }
  
  temp.matrix = cbind(temp.matrix,paste("\n",subject2," ",geometryPredicate," ","\"",wkt,"\" ."))
  
  #Creating  triples from attributes table
  if (length(mapping)!=0){
    for(j in 1:length(mapping)){
      
      if ((j!=geometryID) & (!is.na(mapping[j]))){
        
        cat(paste("",featureSubject2," ",mapping[j]," \"",features@data[i,j],"\" .\n ",sep=""),file=outputFile,append=TRUE)
        
      }    
    }
  }
}

print(paste("Spatial triples created at: ", outputFile, sep=""))
