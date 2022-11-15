
# function called by keyValueToList()
# to take a configTbl lstValue and return as list
# I had a heck of a time getting it to parse a listValue like
# 1234,5678 or "AnkenyHill", "Bullards Bridge" into tokens I
# could use for populating a picklist etc. Im sure there must
# be a cleaner way..
lv2list <- function(value) {
  s<- value[1]
  us<-unlist(c(s),",")
  us2<-strsplit(us,",")
  n<-length(us2[[1]])
  for (p in us2) {
    for (i in 1:n) {
       if(i==1){
        list1=list(p[i]) #new list
       } else { 
        list1= append(list1,p[i])
       }
     }
  } #end for p in us
  #print(list1)
  #print(length(list1))
  return(list1)
} #end function lv2list()


# function to take a Key and the config table
# and return the value as list, typically length 1 but could be multiple
# eg. a ReceiverShortName lstValue could be "Ankeny Hill","Bullards Bridge"
# would return a list of length=2 with items list[1] and list[2]
# or only "Ankeny Hill" we get a list of length=1 and the item is at list[1]
# returns NULL if key not found
keyValueToList <- function(theTable,theKey) {
  # get the value for the key, convert to numeric
  # print(paste0("in keyValueToList() with key:",theKey))
  lstValue <- theTable[theKey][1,2]
  #print(paste0("found lstValue:",lstValue))
  if( is.na(lstValue)) {
    print(paste0("Missing config value for key:", theKey))
    return(NULL)
  }
  return(lv2list(lstValue))
} #end function keyValueToList()

