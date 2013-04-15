//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 

#import <collections.h>
#import <objectbase.h>
#import <gui.h>

#import "ExperSwarm.h"
#import "TroutModelSwarm.h"
#import "HabitatSpace.h"
#import "UTMTroutObserverSwarm.h"

@implementation UTMTroutObserverSwarm
//////////////////////////////////////////////
//
// create
//
//////////////////////////////////////////
+ create: aZone
{
  UTMTroutObserverSwarm* obj=nil;

  obj = [super create: aZone];

  obj->finished=NO;
  obj->probeMap=nil;

  [obj buildProbesIn: aZone];

  return obj;
}

/////////////////////////////////////////
//
// setExperSwarm
//
/////////////////////////////////////////
- setExperSwarm: anExperSwarm
{
    experSwarm = anExperSwarm;
    return self;
}


/////////////////////////////////////////////////////////////////
//
// getModel
//
//////////////////////////////////////////////////////////////
- getModel 
{
    return troutModelSwarm;
}



////////////////////////////////////////////////////////////////
//
// buildProbesIn
//
///////////////////////////////////////////////////////////////
- buildProbesIn: aZone 
{
  //
  // HabitatSpace
  //
  probeMap = [CustomProbeMap create: aZone forClass: [HabitatSpace class]
			     withIdentifiers: "reachName",
							 "Date",
                             "currentHour",
                             "currentPhase",
							 "numberOfDaylightHours",
                             "temperature",
                             "currentHourlyFlow",
							 "dailyMeanFlow",
                             "turbidity",
                             "habDriftConc",
                             ":",
                             "switchColorRep",
                             "tagCellNumber:",
                             "untagCellNumber:",
                             "untagAllCells",
                             "writeDepthsAndVelsToFile:",
                             NULL];
  [probeLibrary setProbeMap: probeMap For: [HabitatSpace class]];


  //
  // FishCells
  //

  probeMap = [CustomProbeMap createBegin: aZone];
  [probeMap setProbedClass: [FishCell class]];
  probeMap = [probeMap createEnd];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "polyCellNumber"
  				   inClass: [PolyCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "reachEnd"
  				   inClass: [FishCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "polyCellDepth"
  				   inClass: [PolyCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "polyCellVelocity"
  				   inClass: [PolyCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "polyCellArea"
  				   inClass: [PolyCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "meanDepth"
  				   inClass: [FishCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "meanVelocity"
  				   inClass: [FishCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "cellFracSpawn"
  				   inClass: [FishCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "cellFracShelter"
  				   inClass: [FishCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "cellShelterArea"
  				   inClass: [FishCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "shelterAreaAvailable"
  				   inClass: [FishCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "isShelterAvailable"
  				   inClass: [FishCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "fracHidingCover"
  				   inClass: [FishCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "availableHidingCover"
  				   inClass: [FishCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "cellDistToHide"
  				   inClass: [FishCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "driftHourlyCellTotal"
  				   inClass: [FishCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "searchHourlyCellTotal"
  				   inClass: [FishCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "hourlyAvailDriftFood"
  				   inClass: [FishCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "hourlyAvailSearchFood"
  				   inClass: [FishCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "numberOfFish"
  				   inClass: [FishCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForMessage: "tagPolyCell"
  				   inClass: [PolyCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForMessage: "unTagPolyCell"
  				   inClass: [PolyCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForMessage: "tagAdjacentCells"
  				   inClass: [PolyCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForMessage: "unTagAdjacentCells"
  				   inClass: [PolyCell class]]];
  [probeLibrary setProbeMap: probeMap For: [FishCell class]];


  //
  // The fish probes are defined in buildFishProbes
  //


  //
  // Redds
  //
  probeMap = [CustomProbeMap create: aZone forClass: [UTMRedd class]
			     withIdentifiers: "species",
			     "numberOfEggs",
                             "emergeDays",
                             "fracDeveloped",
                             "spawnerLength",
                             "polyCellNumber",
                             ":",
                             NULL];
  [probeLibrary setProbeMap: probeMap For: [UTMRedd class]];

  return self;
}


////////////////////////////////////////////////////////////////////
//
// buildFishProbes
//
///////////////////////////////////////////////////////////////////
- buildFishProbes 
{
  id <ListIndex> listNdx;
  id speciesClass;

  probeMap = [CustomProbeMap create: [self getZone] 
                           forClass: [UTMTrout class]
                    withIdentifiers: "age",
                                     "fishLength",
                                     "fishWeight",
                                     "fishCondition",
                                     "prevLength",
                                     "prevWeight",
                                     "prevCondition",
                                     "netEnergyForBestCell",
                                     "driftFoodIntake",
                                     "driftNetEnergy",
                                     "searchFoodIntake",
                                     "searchNetEnergy",
                                     "totalFoodConsumptionThisStep",
                                     "cMax",
                                     "standardResp",
                                     "activeResp",
                                     "feedStrategy",
                                     "inShelter",
                                     "inHidingCover",
                                     "deadOrAlive",
                                     "deathCausedBy",
                                     "reactiveDistance",
                                     "captureArea",
                                     "maxSwimSpeed",
                                     "nonStarvSurvival",
                                     "TransectNumber",
                                     "CellNumber",
                                     ":",
                                     "tagFish",
                                     "killFish",
                                      NULL];
                                     
   listNdx = [[troutModelSwarm getSpeciesClassList] listBegin: [self getZone]];
   while (([listNdx getLoc] != End) && ((speciesClass = [listNdx next]) != nil)) 
   {
       [probeLibrary setProbeMap: probeMap For: speciesClass];
   }
   [listNdx drop];


   return self;
}





///////////////////////////////
//
// _worldRasterDeath_
//
///////////////////////////////
- worldRasterDeath : caller
{
  //[utmWorldRaster drop];
  utmWorldRaster = nil;
  return self;
}


- _mortalityGraphDeath : caller
{
  //[mortalityGraph drop];
  mortalityGraph = nil;
  return self;
}



//////////////////////////////////////////////////
//
// objectSetup
//
/////////////////////////////////////////////////
- objectSetup 
{
  obsZone = [Zone create: [self getZone]];

  troutModelSwarm = [TroutModelSwarm create: self];

  [troutModelSwarm setPolyRasterResolutionX:  rasterResolutionX
                   setPolyRasterResolutionY:  rasterResolutionY 
                 setPolyRasterColorVariable:  rasterColorVariable];

  [troutModelSwarm setObserverSwarm: self];
  
  //fprintf(stdout,"modelSetupFile = %s \n", modelSetupFile);
  //fflush(0);

  if(modelSetupFile != NULL) 
  {
     [ObjectLoader load: troutModelSwarm fromFileNamed: modelSetupFile];
  }
  else 
  {
     [ObjectLoader load: troutModelSwarm fromFileNamed: "Model.Setup"];
  }

  //
  // instantiate the objects first;
  // this allows the experiment swarm to operate on 
  // model objects BEFORE their final creation 
  //
  [troutModelSwarm instantiateObjects];

  return self;
}



////////////////////////////////////////////////////////
//
// buildObjects
//
///////////////////////////////////////////////////////
- buildObjects
{
  int ndx;

  fprintf(stdout, "UTMTroutObserverSwarm >>>> buildObjects >>>> BEGIN\n");
  fflush(0);

  if((rasterResolutionX <= 0) || (rasterResolutionY <= 0))
  {
     fprintf(stderr, "TroutObserverSwarm >>>> buildObjects >>>> one of the rasterResolution parameters is <= zero\n");
     fflush(0);
     exit(1);
  }

  habitatRasterMap  = [Map create: obsZone];
  habColormapMap  = [Map create: obsZone];
  habCellDisplayMap = [Map create: obsZone];

  utmColorMaps = [Map create: obsZone];
  Depth = [Symbol create: obsZone
                 setName: "Depth"];
  depthColormap = [Colormap create: obsZone];
  Velocity = [Symbol create: obsZone
                 setName: "Velocity"];
  velocityColormap = [Colormap create: obsZone];

  [utmColorMaps at: Depth
         insert: depthColormap];

  [utmColorMaps at: Velocity
         insert: velocityColormap];

  //utmColormap = [Colormap create: obsZone];

  //fprintf(stdout, "UTMTroutObserverSwarm >>>> buildObjects >>>> before velocity\n");
  //fflush(0);

  {
     strncpy(toggleColorVariable, "velocity", 9);
     //utmColormap = velocityColormap;
     //currentRepresentation = Velocity;

     if(maxShadeVelocity <= 0.0)
     {
         fprintf(stderr, "ERROR: UTMTroutObserverSwarm >>>> maxShadeVelocity is <= 0.0 >>>> check Observer.Setup\n");
         fflush(0);
         exit(1);
     }
     else shadeColorMax = (double) maxShadeVelocity;
 
     for(ndx = 0; ndx < CELL_COLOR_MAX; ndx++)
     {
           double aRedFrac = 1.0;
           double aGreenFrac = (double) (CELL_COLOR_MAX - 1.0 - ndx)/((double) CELL_COLOR_MAX - 1.0);
           double aBlueFrac = 0.0;


           [velocityColormap setColor: ndx 
                           ToRed: aRedFrac
                           Green: aGreenFrac
                            Blue: aBlueFrac];

     }
  }
  //fprintf(stdout, "UTMTroutObserverSwarm >>>> buildObjects >>>> before depth\n");
  //fflush(0);
  {
     strncpy(toggleColorVariable, "depth", 6);

     //currentRepresentation = Depth;
     //utmColormap = depthColormap;

     if(maxShadeDepth <= 0.0)
     {
         fprintf(stderr, "ERROR: UTMTroutObserverSwarm >>>> maxShadeDepth is <= 0.0 >>>> check Observer.Setup\n");
         fflush(0);
         exit(1);
     }
	 else shadeColorMax = (double) maxShadeDepth;
 
     for(ndx = 0; ndx < CELL_COLOR_MAX; ndx++)
     {
           double aRedFrac = 0.0;
           double aGreenFrac = (double) (CELL_COLOR_MAX - 1.0 - ndx)/((double) CELL_COLOR_MAX - 1.0);
           double aBlueFrac =  1.0;

           [depthColormap setColor: ndx 
                           ToRed: aRedFrac
                           Green: aGreenFrac
                            Blue: aBlueFrac];

     }
  }


  if(strncmp(rasterColorVariable, "velocity", 8) == 0)
  {
     strncpy(toggleColorVariable, "velocity", 9);
     utmColormap = velocityColormap;
     currentRepresentation = Velocity;
  }
  else if(strncmp(rasterColorVariable, "depth", 5) == 0)
  {
     strncpy(toggleColorVariable, "depth", 6);
     utmColormap = depthColormap;
     currentRepresentation = Depth;
  }
  else
  {
      fprintf(stderr, "ERROR: UTMTroutObserverSwarm >>>> buildObjects >>>> rasterColorVariable = %s\n", rasterColorVariable);
      fflush(0);
      exit(1);
  }

  //fprintf(stdout, "UTMTroutObserverSwarm >>>> buildObjects >>>> before colormaps\n");
  //fflush(0);
  [depthColormap setColor: POLYBOUNDARYCOLOR ToName: "black"];
  [depthColormap setColor: TAG_CELL_COLOR ToName: tagCellColor];
  [depthColormap setColor: TAG_FISH_COLOR ToName: tagFishColor];
  [depthColormap setColor: DAYTIMERASTER ToName: "LightBlue1"];
  //[depthColormap setColor: NIGHTTIMERASTER ToName: "gray5"];
  [depthColormap setColor: NIGHTTIMERASTER ToName: "MidnightBlue"];

  [velocityColormap setColor: POLYBOUNDARYCOLOR ToName: "black"];
  [velocityColormap setColor: TAG_CELL_COLOR ToName: tagCellColor];
  [velocityColormap setColor: TAG_FISH_COLOR ToName: tagFishColor];
  [velocityColormap setColor: DAYTIMERASTER ToName: "LightBlue1"];
  //[velocityColormap setColor: NIGHTTIMERASTER ToName: "gray5"];
  [velocityColormap setColor: NIGHTTIMERASTER ToName: "MidnightBlue"];
  
  
  //fprintf(stdout, "UTMTroutObserverSwarm >>>> buildObjects >>>> before rasterres\n");
  //fflush(0);
   //
   //build model Objects and set the fish color in the ModelSwarm
   //
   [troutModelSwarm setUTMRasterResolutionX: rasterResolutionX
                    setUTMRasterResolutionY:  rasterResolutionY 
                  setUTMRasterColorVariable:  rasterColorVariable];

   //[troutModelSwarm buildObjectsWith: utmColormap
   [troutModelSwarm buildObjectsWith: utmColorMaps
                             andWith: shadeColorMax];

  [self buildFishProbes];

  //
  // Build the rasters, display objects, etc from the 
  // HabitatManager 
  // 
  {
       int numberOfSpaces = -1;
       int spaceCount;
       id habitatManager = nil;
       id <List> habSpaceList;

       habitatManager = [troutModelSwarm getHabitatManager];    
       numberOfSpaces = [habitatManager getNumberOfHabitatSpaces];
       habSpaceList = [habitatManager getHabitatSpaceList];
       
       habitatRasterList = [List create: obsZone];
       habCellDisplayList = [List create: obsZone];

       fprintf(stdout, "TroutObserverSwarm >>>> buildObjects >>>> building space display objects >>>> BEGIN\n");
       fflush(0);

       for(spaceCount = 0; spaceCount < numberOfSpaces; spaceCount++)
       {
            id <ZoomRaster> polyWorldRaster = nil;
            id habitatSpace = [habSpaceList atOffset: spaceCount];
             
            polyWorldRaster = [ZoomRaster createBegin: obsZone];
            [polyWorldRaster setWindowGeometryRecordName: [habitatSpace getReachName]];
            polyWorldRaster = [polyWorldRaster createEnd];
            [polyWorldRaster enableDestroyNotification: self
	                 notificationMethod: @selector (polyRasterDeath:)];

              [habitatRasterMap at: habitatSpace
                            insert: polyWorldRaster];
              [habitatRasterList addLast: polyWorldRaster];

             if(strncmp(rasterColorVariable, "velocity", 8) == 0)
             {
                strncpy(toggleColorVariable, "velocity", 9);
                [polyWorldRaster setColormap: velocityColormap];

                [habColormapMap   at: polyWorldRaster
                              insert:velocityColormap];
                currentRepresentation = Velocity;
             }
             else if(strncmp(rasterColorVariable, "depth", 5) == 0)
             {
                strncpy(toggleColorVariable, "depth", 6);
                [polyWorldRaster setColormap: depthColormap];

                [habColormapMap   at: polyWorldRaster
                              insert: depthColormap];

                currentRepresentation = Depth;
             }
             else
             {
                 fprintf(stderr, "ERROR: TroutObserverSwarm >>>> buildObjects >>>> rasterColorVariable = %s\n", rasterColorVariable);
                 fflush(0);
                 exit(1);
             }

            polyRasterX = [habitatSpace getPolyPixelsX];
            polyRasterY = [habitatSpace getPolyPixelsY];

            //fprintf(stdout, "TroutObserverSwarm >>>> buildObjects >>>> polyRasterX = %d\n", polyRasterX);
            //fprintf(stdout, "TroutObserverSwarm >>>> buildObjects >>>> polyRasterY = %d\n", polyRasterY);
            //fflush(0);

            [polyWorldRaster setWidth: polyRasterX/rasterResolutionX Height: polyRasterY/rasterResolutionY];

            [polyWorldRaster setWindowTitle: [habitatSpace getReachName]];

            [polyWorldRaster pack];				  // draw the window.

            polyCellDisplay = [Object2dDisplay createBegin: obsZone];
            [polyCellDisplay setDisplayWidget: polyWorldRaster];
            [polyCellDisplay setDiscrete2dToDisplay: habitatSpace];
            [polyCellDisplay setObjectCollection: 
		            [habitatSpace getPolyCellList]];
            [polyCellDisplay setDisplayMessage: M(drawSelfOn:)];   // draw method
            polyCellDisplay = [polyCellDisplay createEnd];

            [polyWorldRaster setButton: ButtonLeft
		               Client: habitatSpace 
		              Message: M(probePolyCellAtX:Y:)];

            [polyWorldRaster setButton: ButtonRight
	                       Client: habitatSpace 
	                      Message: M(probeFishAtX:Y:)];

            [habCellDisplayMap at: habitatSpace
                           insert: polyCellDisplay];

         } //for

         fprintf(stdout, "TroutObserverSwarm >>>> buildObjects >>>> building space display objects >>>> END\n");
         fflush(0);

   } 

  populationHisto = [EZBin createBegin: obsZone];
  SET_WINDOW_GEOMETRY_RECORD_NAME (populationHisto);
  [populationHisto setTitle: "Population in each Age"];
  [populationHisto setAxisLabelsX: "Age" Y: "# of Fish"];
  [populationHisto setBinCount: 5];
  [populationHisto setLowerBound: 0];
  [populationHisto setUpperBound: 5];
  [populationHisto setCollection: [troutModelSwarm getLiveFishList]];
  [populationHisto setProbedSelector: M(getAge)];
  populationHisto = [populationHisto createEnd];
  [populationHisto enableDestroyNotification: self
                notificationMethod: @selector (_populationHistoDeath_:)];


  mortalityGraph = [EZGraph createBegin: self];
  SET_WINDOW_GEOMETRY_RECORD_NAME (mortalityGraph); 
  [mortalityGraph setTitle: "Mortality"];
  [mortalityGraph setAxisLabelsX: "Time" Y: "Number dead"];
  mortalityGraph = [mortalityGraph createEnd];

  //
  // Now create the graph sequences
  //
  {
      id <List> listOfMortalityCounts = [troutModelSwarm getListOfMortalityCounts];
      id <ListIndex> lstNdx = nil;
      id mortalityCount = nil;

      if(listOfMortalityCounts == nil) 
      {
          fprintf(stderr, "ERROR: TroutObserverSwarm >>>> buildObjects >>>> listOfMortalityCounts is nil\n");
          fflush(0);
          exit(1);
      }
  
      lstNdx = [listOfMortalityCounts listBegin: scratchZone];

      [lstNdx setLoc: Start];

      while(([lstNdx getLoc] != End) && ((mortalityCount = [lstNdx next]) != nil)) 
      {
            [mortalityGraph createSequence: [[mortalityCount getMortality] getName]
                              withFeedFrom: mortalityCount
                               andSelector: M(getNumDead)];
      }

      [lstNdx drop];
  }

  [mortalityGraph enableDestroyNotification: self
               notificationMethod: @selector (_mortalityGraphDeath:)];



  //
  // One for each habitat space
  //
  if(troutModelSwarm)
  {
      id <List> aHabitatSpaceList = [[troutModelSwarm getHabitatManager] getHabitatSpaceList]; 
      int habitatSpaceCount = [aHabitatSpaceList getCount];
      int i;

      for(i = 0; i < habitatSpaceCount; i++)
      {
          CREATE_ARCHIVED_PROBE_DISPLAY([aHabitatSpaceList atOffset: i]);
      }
  }

   fprintf(stdout, "UTMTroutObserverSwarm >>>> buildObjects >>>> END\n");
   fflush(0);

   return self;

}  //buildObjects


///////////////////////////////////
//
// switchColorRep
//
///////////////////////////////////
- switchColorRepFor: aHabitatSpace
{
  id <ZoomRaster> habitatRaster = nil;
  id <Colormap> habitatColormap;

  fprintf(stdout, "TroutObserverSwarm >>>> switchColorRep >>>> BEGIN\n");
  fflush(0);

      habitatRaster = [habitatRasterMap at: aHabitatSpace];
      habitatColormap = [habColormapMap  at: habitatRaster];

      if(habitatColormap == depthColormap)
      {
            [habitatRaster setColormap: velocityColormap];
            [habColormapMap at: habitatRaster replace: velocityColormap];
            if(maxShadeVelocity <= 0)
            {
                fprintf(stderr, "ERROR: TroutObserverSwarm >>>> maxShadeVelocity is <= 0 >>>> check Observer.Setup\n");
                fflush(0);
                exit(1);
            }
            else shadeColorMax = (double) maxShadeVelocity;
      }
      else if(habitatColormap == velocityColormap)
      {
            [habitatRaster setColormap: depthColormap];
            [habColormapMap at: habitatRaster replace: depthColormap];

            if(maxShadeDepth <= 0)
            {
                fprintf(stderr, "ERROR: TroutObserverSwarm >>>> maxShadeVelocity is <= 0 >>>> check Observer.Setup\n");
                fflush(0);
                exit(1);
            }
            else shadeColorMax = (double) maxShadeDepth;
      }
      
      [troutModelSwarm setShadeColorMax: shadeColorMax inHabitatSpace: aHabitatSpace]; 
      [troutModelSwarm toggleCellsColorRepIn: aHabitatSpace];
      [self redrawRasterFor: aHabitatSpace];
    
  fprintf(stdout, "TroutObserverSwarm >>>> switchColorRep END\n");
  fflush(0);

  return self;
}


////////////////////////////////////
//
// redrawRaster
//
//////////////////////////////////
- redrawRasterFor: aHabitatSpace
{
   // fprintf(stdout, "TroutObserverSwarm >>>> redrawRaster >>>> BEGIN\n");
   // fflush(0);

   id theRaster = [habitatRasterMap at: aHabitatSpace];
  // fprintf(stdout, "UTMTroutObserverSwarm >>>> redrawRaster >>>> currentPhase = %d\n", [aHabitatSpace getCurrentPhase]);
  //fflush(0);
 

   [theRaster erase];

   if([aHabitatSpace getCurrentPhase] == 0)
   {
      [theRaster fillRectangleX0: 0 
                              Y0: 0 
                              X1: [theRaster getWidth] 
                              Y1: [theRaster getHeight] 
                           Color: NIGHTTIMERASTER];
   }
  else
   {
      [theRaster fillRectangleX0: 0 
                              Y0: 0 
                              X1: [theRaster getWidth] 
                              Y1: [theRaster getHeight] 
                           Color: DAYTIMERASTER];

   }
       [[habCellDisplayMap at: aHabitatSpace] display];
       [theRaster drawSelf];

    // fprintf(stdout, "TroutObserverSwarm >>>> redrawRaster >>>> END\n");
    // fflush(0);

    return self;
}


////////////////////////////////////
//
// _update_
//
//////////////////////////////////
- _update_ 
{
  if(mortalityGraph) 
  {
     [mortalityGraph step];
  }
   if(habitatRasterMap)
   {
        id habitatManager = [troutModelSwarm getHabitatManager];    
        id habSpaceList = [habitatManager getHabitatSpaceList];
        id habitatSpace = nil;
        id <ListIndex> listNdx = [habSpaceList listBegin: scratchZone];

        while(([listNdx getLoc] != End) && ((habitatSpace = [listNdx next]) != nil))
        {
             // [[habitatRasterMap at: habitatSpace] erase];
             // [[habCellDisplayMap at: habitatSpace] display];
             // [[habitatRasterMap at: habitatSpace] drawSelf];
			 [self redrawRasterFor: habitatSpace];
        }

        [listNdx drop];

    } //if habitatRasterMap


  return self;
}

 
- buildActions
{
  [super buildActions];
  [troutModelSwarm buildActions];

  displayActions = [ActionGroup create: obsZone];
  [displayActions createActionTo: self message: M(_update_)];
  [displayActions createActionTo: probeDisplayManager message: M(update)];
  //[displayActions createActionTo: actionCache message: M(doTkEvents)];


  displaySchedule = [Schedule createBegin: obsZone];
  [displaySchedule setRepeatInterval: displayFrequency]; // note frequency!
  displaySchedule = [displaySchedule createEnd];
  [displaySchedule at: 0 createAction: displayActions];
  [displaySchedule at: 0 createActionTo: self message: M(checkToStop)];
  
  if (rasterOutputFrequency > 0) {
    outputSchedule = [Schedule createBegin: obsZone];
    [outputSchedule setRepeatInterval: rasterOutputFrequency];
    outputSchedule = [outputSchedule createEnd];
    if ((strcmp(takeRasterPictures, "YES") == 0) ||
	(strcmp(takeRasterPictures, "yes") == 0) ||
	(strcmp(takeRasterPictures, "Yes") == 0) ||
	(strcmp(takeRasterPictures, "Y") == 0) ||
	(strcmp(takeRasterPictures, "y") == 0))
      [outputSchedule at: 0 createActionTo: self message: M(writeFrame)];
  }

  return self;
}  



//////////////////////////////////////////////////////////
//
// updateTkEvents
//
// called from the model swarm when tagFish is invoked.
//
/////////////////////////////////////////////////////////
- updateTkEventsFor: aHabitatSpace
{
    id <Raster> habitatRaster = nil;

   //fprintf(stdout, "TroutObserverSwarm >>>> updateTkEvents >>>> BEGIN\n");
   //fflush(0); 


   if(experSwarm == nil)
   {
       fprintf(stderr, "ERROR: TroutObserverSwarm >>>> updateTkEvents >>>> experSwarm is nil\n");
       fflush(0);
       exit(1);
   }


   habitatRaster = [habitatRasterMap at: aHabitatSpace] ;
   [habitatRaster erase];
   [[habCellDisplayMap at: aHabitatSpace] display];
   [habitatRaster drawSelf];

   [experSwarm updateTkEvents];

   //fprintf(stdout, "TroutObserverSwarm >>>> updateTkEvents >>>> END\n");
   //fflush(0); 

   return self;
}



- activateIn:  swarmContext
{
  [super activateIn: swarmContext];
  modelActivity = [troutModelSwarm activateIn: self];
  [displaySchedule activateIn: self];
  if (rasterOutputFrequency > 0)
  {
    [outputSchedule activateIn: self];
  }

  myActivity = [self getActivity];

  return [self getActivity];
}


//////////////////////////////////////
//
// checkToStop
//
/////////////////////////////////////
- checkToStop 
{
  if([troutModelSwarm whenToStop] == YES)  
  {
    finished = YES;
    modelActivity = nil;
    [[self getActivity] stop];
  }

  return self;
}



- (BOOL) areYouFinishedYet 
{
  return finished;
}

- setModelNumberTo: (int) anInt 
{
  modelNumber = anInt;
  return self;
}

-(void) writeFrame 
{
  char filename[256];
  id pixID;

  sprintf(filename, "Model%03d_Frame%03ld.png", modelNumber, getCurrentTime());

  pixID =  [Pixmap createBegin: [self getZone]];
  [pixID  setWidget: utmWorldRaster];
  pixID = [pixID createEnd];
  [pixID save: filename];
  [pixID drop];

}


///////////////////////////////////////////
//
// iAmAlive
//
//////////////////////////////////////////
- iAmAlive 
{
  static int iveBeenCalled=0;
  iveBeenCalled++;
  (void) fprintf(stdout, "ObserverSwarm is alive. (%d)\n", iveBeenCalled); 
  fflush(0);
  return self;
}


/////////////////////////////////////////////////////
//
// getWorldRaster
//
////////////////////////////////////////////////////
- (id <ZoomRaster>) getWorldRaster
{
  return utmWorldRaster;
}

///////////////////////////////////
//
// getModelSwarm
//
//////////////////////////////////
- (id <Swarm>) getModelSwarm 
{
     return troutModelSwarm;
}


//////////////////////////////////
//
// drop
//
//////////////////////////////////
- (void) drop 
{
  [probeDisplayManager setDropImmediatelyFlag: NO];
  if(utmWorldRaster)
  {
      [utmWorldRaster drop];
      utmWorldRaster = nil;
  }

  if(mortalityGraph)
  {
      [mortalityGraph drop];
      mortalityGraph = nil;
  }


  if(displayActions)
  {
     [displayActions drop];
     displayActions = nil;
  }

  if(displaySchedule)
  {
      [displaySchedule drop];
      displaySchedule = nil;
  }

  if(troutModelSwarm)
  {
      [troutModelSwarm drop];
      troutModelSwarm = nil;
  }

  if(probeMap)
  {
      [probeMap drop];
      probeMap = nil;
  }

  if(obsZone)
  {
      [obsZone drop];
      obsZone = nil;
  }
  
  [super drop];

} //drop



@end
