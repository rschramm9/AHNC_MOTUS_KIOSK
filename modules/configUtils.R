# utility functions for managing kiosk configuration 

# read  kiosk.cfg (or sample.cfg is no kiosk.cfg)
# set GLOBAL config parameters
# return TRUE if made it all the way thru or FALSE if there were issues.
#
getConfig <- function() {
  
  tryCatch( 
    {  
      #attempt to read file from current directory
      # use assign so you can access the variable outside of the function
      assign("configfrm", read.table(file='kiosk.cfg',header=FALSE,
                                     sep='=',col.names=c('Key','Value')), envir=.GlobalEnv) 
      WarningPrint("Loaded configuration data from local file kiosk.cfg")
    },
    warning = function( w )
    {
      print() # dummy warning function to suppress the output of warnings
    },
    error = function( err ) 
    {
      WarningPrint("Could not read cfg data from current directory, will use defaults from sample.cfg...")
      #attempt to read from alternate template
      tryCatch(
        {
          # use assign so you can access the variable outside of the function
          #attempt to read file from current directorygit commit glo
          # use assign so you can access the variable outside of the function
          assign("configfrm", read.table(file='sample.cfg',header=FALSE,
                                         sep='=',col.names=c('Key','Value')), envir=.GlobalEnv) 
          WarningPrint("Loaded installation data from sample.cfg")
        },
        warning = function( w )
        {
          print() # dummy warning function to suppress the output of warnings
        },
        error = function( err )
        {
          ErrorPrint("Config file read error: Could not load configuration data. Exiting Program")
          ErrorPrint("here is the err returned by the read:")
          ErrorPrint(err)
          stop("There is an error reading your cfg file")
        }
      )
      
      
    })

  configtbl <- data.table(configfrm, key='Key')
  #print("---------  The configtbl ------------")
  #print(configtbl)
  #print("-------------------------------------")
  
  badCfg<-FALSE  #assume good config
  
  #print("------------ MainLogoFile ----------------")
  list1 <- keyValueToList(configtbl,'MainLogoFile')
  if( is.null(list1) ){
    badCfg<-TRUE
    config.MainLogoFile<<-NULL
  } else {
    #I ultimately want a string
    config.MainLogoFile<<- toString(list1[1])  
  }

  #print("------------ MainTitle ----------------")
  list1 <- keyValueToList(configtbl,'MainTitle')
  if( is.null(list1) ){
    badCfg<-TRUE 
    config.MainTitle<<-NULL
  } else {
    #I ultimately want a string
    config.MainTitle<<- toString(list1[1])  
  }
  
  #print("------------ MainLogoHeight --------------")
  list1 <- keyValueToList(configtbl,'MainLogoHeight')
  if( is.null(list1) ){
    badCfg<-TRUE 
    config.MainLogoHeight <<- NULL
  } else {
    config.MainLogoHeight <<- as.numeric(list1[1]) #assume length=1
  }
  
  #print("------------ ReceiverDeploymentID --------------")
  # set global parms of both the list and the first item on the list
  #the default target receiver is the first list item (set in global.R after processing config)
  config.ReceiverDeployments <<- keyValueToList(configtbl,'ReceiverDeploymentID')
  if( is.null(list1) ){
    message("Config is missing list of Receiver Deployment IDs")
    badCfg<-TRUE 
  }
  #print("------------ ReceiverShortName ----------------")
  # set global parms of both the list and the first item on the list
  config.ReceiverShortNames<<-keyValueToList(configtbl,'ReceiverShortName')
  if( is.null(config.ReceiverShortNames) ){
    badCfg<-TRUE
    message("Config is missing list of ReceiverShortNames")
  }
  
  # these two lists support the receiver Picklist they must be same length
  if( length(config.ReceiverShortNames) != length(config.ReceiverDeployments) ){
    message("There is a problem with your kiosk.cfg file. THe ReceiverShortName list must be same length as ReceiverIDs list")
    badCfg<-TRUE
  }
  
  #print("------------ MovingMarkerIcon ----------------")
  list1 <- keyValueToList(configtbl,'MovingMarkerIcon')
  if( is.null(list1) ){
    badCfg<-TRUE 
    config.MovingMarkerIcon<<-NULL
  } else {
    #I ultimately want a string
    config.MovingMarkerIcon<<- toString(list1[1])  
  }
  
  #print("------------ MovingMarkerIconWidth --------------")
  list1 <- keyValueToList(configtbl,'MovingMarkerIconWidth')
  if( is.null(list1) ){
    badCfg<-TRUE 
    config.MovingMarkerIconWidth<<-NULL
  } else {
    config.MovingMarkerIconWidth<<- as.numeric(list1[1]) #assume length=1
  }
  
  list1 <- keyValueToList(configtbl,'MovingMarkerIconHeight')
  if( is.null(list1) ){
    badCfg<-TRUE 
    config.MovingMarkerIconHeight<<-NULL
  } else {
    config.MovingMarkerIconHeight<<- as.numeric(list1[1]) #assume length=1
  }
  
  #print("------------ InactivityTimeoutSeconds --------------")
  list1 <- keyValueToList(configtbl,'InactivityTimeoutSeconds')
  if( is.null(list1) ){
    config.InactivityTimeoutSeconds<<-1800 #30 minutes
  } else {
    config.InactivityTimeoutSeconds<<- as.numeric(list1[1]) #assume length=1
  }
  
  #print("------------ CheckMotusIntervalMinutes --------------")
  list1 <- keyValueToList(configtbl,'CheckMotusIntervalMinutes')
  if( is.null(list1) ){
    config.CheckMotusIntervalMinutes<<-10 
  } else {
    config.CheckMotusIntervalMinutes<<- as.numeric(list1[1]) #assume length=1
  }
  
  #print("------------ EnableReadCache --------------")
  list1 <- keyValueToList(configtbl,'EnableReadCache')
  if( is.null(list1) ){
    config.EnableReadCache<<-1 #1=True, 0=False
  } else {
    config.EnableReadCache<<- as.numeric(list1[1]) #assume length=1
  }
  
  #print("------------ EnableWriteCache --------------")
  list1 <- keyValueToList(configtbl,'EnableWriteCache')
  if( is.null(list1) ){
    config.EnableWriteCache<<-1 #1=True, 0=False
  } else {
    config.EnableWriteCache<<- as.numeric(list1[1]) #assume length=1
  }
  
  
  #print("------------ CacheAgeLimitMinutes --------------")
  list1 <- keyValueToList(configtbl,'CacheAgeLimitMinutes')
  if( is.null(list1) ){
    config.CacheAgeLimitMinutes<<-300 #5 minutes
  } else {
    config.CacheAgeLimitMinutes<<- as.numeric(list1[1]) #assume length=1
  }
  
  #print("------------ HttpGetTimeoutSeconds --------------")
  list1 <- keyValueToList(configtbl,'HttpGetTimeoutSeconds')
  if( is.null(list1) ){
    config.HttpGetTimeoutSeconds<<-10 
  } else {
    config.HttpGetTimeoutSeconds<<- as.numeric(list1[1]) #assume length=1
  }
  
 
  #print("------------ CachePath ----------------")
  list1 <- keyValueToList(configtbl,'CachePath')
  if( is.null(list1) ){
    badCfg<-TRUE 
    config.CachePath<<-NULL
  } else {
    #I ultimately want a string
    config.CachePath<<- toString(list1[1])  
  }
  
  #print("------------ LogLevel ----------------")
  list1 <- keyValueToList(configtbl,'LogLevel')
  if( is.null(list1) ){
    badCfg<-TRUE 
    config.LogLevel<<-LOG_LEVEL_WARNING
  } else {
    #I ultimately want a string
    config.LogLevel<<- toString(list1[1])  
  }
  
  result=switch(
    config.LogLevel,
    "LOG_LEVEL_DEBUG"=TRUE,
    "LOG_LEVEL_INFO"=TRUE,
    "LOG_LEVEL_WARNING"=TRUE,
    "LOG_LEVEL_ERROR"=TRUE,
    "LOG_LEVEL_FATAL"=TRUE,
    "LOG_LEVEL_NONE"=TRUE,
     FALSE
  )
  if(!result){
    message(paste0("Unrecognized log level in config file:", config.LogLevel))
    badCfg=TRUE
  }

  return(badCfg)
  
} #end getConfig()

#
# print global config parameters
#
printConfig <- function() {
  
  TSprint(paste0("MainLogoFile:", config.MainLogoFile))
  
  TSprint(paste0("MainTitle:",config.MainTitle))
  
  TSprint(paste0("MainLogoHeight:",config.MainLogoHeight))
  
  if ( is.list( config.ReceiverDeployments)){
    for (i in 1:length(config.ReceiverDeployments)) {
      TSprint( paste0( "ReceiverDeployment[",i,"]:",config.ReceiverDeployments[[i]] ))
    }
  }
  
  if ( is.list( config.ReceiverShortNames)) {
    for (i in 1:length(config.ReceiverShortNames)) {
      TSprint( paste0( "ReceiverShortName[",i,"]:",config.ReceiverShortNames[[i]] ))
    }
  }
  
  TSprint(paste0("MovingMarkerIcon:",config.MovingMarkerIcon))
  
  TSprint(paste0("MovingMarkerIconWidth:",config.MovingMarkerIconWidth))
  
  TSprint(paste0("MovingMarkerIconHeight:",config.MovingMarkerIconHeight))
  
  TSprint(paste0("InactivityTimeoutSeconds:",config.InactivityTimeoutSeconds))
  
  TSprint(paste0("CheckMotusIntervalMinutes:",config.CheckMotusIntervalMinutes))
  
  TSprint(paste0(" EnableReadCache:",config.EnableReadCache))
  
  TSprint(paste0(" EnableWriteCache:",config.EnableWriteCache))
  
  TSprint(paste0("CacheAgeLimitMinutes:",config.CacheAgeLimitMinutes))
  
  TSprint(paste0("CachePath:", config.CachePath))
  
  TSprint(paste0("LogLevel:", config.LogLevel))
  
  TSprint(paste0("HttpGetTimeoutSeconds:", config.HttpGetTimeoutSeconds))
  return()
  
} #end printConfig()