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
#import "UTMTroutModelSwarm.h"
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
			     withIdentifiers: "Date",
                             "hour",
                             "currentPhase",
                             "temperature",
                             "currentHourlyFlow",
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
  [probeMap addProbe: [probeLibrary getProbeForVariable: "utmCellNumber"
  				   inClass: [UTMCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "rasterColorVariable"
  				   inClass: [UTMCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "utmCellDepth"
  				   inClass: [UTMCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "utmCellVelocity"
  				   inClass: [UTMCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "meanDepth"
  				   inClass: [FishCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "meanVelocity"
  				   inClass: [FishCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "interiorColor"
  				   inClass: [UTMCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "cellFracSpawn"
  				   inClass: [FishCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "cellFracShelter"
  				   inClass: [FishCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "cellShelterArea"
  				   inClass: [FishCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "shelterAreaAvailable"
  				   inClass: [FishCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "availableHidingCover"
  				   inClass: [FishCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "isShelterAvailable"
  				   inClass: [FishCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "cellDistToHide"
  				   inClass: [FishCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForVariable: "fracHidingCover"
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
  [probeMap addProbe: [probeLibrary getProbeForMessage: "tagUTMCell"
  				   inClass: [UTMCell class]]];
  [probeMap addProbe: [probeLibrary getProbeForMessage: "unTagUTMCell"
  				   inClass: [UTMCell class]]];
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
                             "utmCellNumber",
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
- _worldRasterDeath_ : caller
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

  troutModelSwarm = [UTMTroutModelSwarm create: self];

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
  id habitatSpace = nil;
  char reachName[50];
  int ndx;

  int shadeColorMax; 

  fprintf(stdout, "UTMTroutObserverSwarm >>>> buildObjects >>>> BEGIN\n");
  fflush(0);

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
     else if(maxShadeVelocity < CELL_COLOR_MAX)
     {
         shadeColorMax = (int) (maxShadeVelocity + 0.5);
     }
     else 
     {
        shadeColorMax = CELL_COLOR_MAX;
     }
 
     for(ndx = 0; ndx < shadeColorMax; ndx++)
     {
           double aRedFrac = 1.0;
           double aGreenFrac = (double) (shadeColorMax - 1.0 - ndx)/((double) shadeColorMax - 1.0);
           double aBlueFrac = 0.0;


           //[utmColormap setColor: ndx 
           [velocityColormap setColor: ndx 
                           ToRed: aRedFrac
                           Green: aGreenFrac
                            Blue: aBlueFrac];

     }
     //exit(0);
  }
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
     else if(maxShadeDepth < CELL_COLOR_MAX)
     {
         shadeColorMax = (int) (maxShadeDepth + 0.5);
     }
     else 
     {
        shadeColorMax = CELL_COLOR_MAX;
     }
 
     for(ndx = 0; ndx < shadeColorMax; ndx++)
     {
           double aRedFrac = 0.0;
           double aGreenFrac = (double) (shadeColorMax - 1.0 - ndx)/((double) shadeColorMax - 1.0);
           double aBlueFrac =  1.0;

           //[utmColormap setColor: ndx 
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

  [depthColormap setColor: UTMBOUNDARYCOLOR ToName: "black"];
  [depthColormap setColor: TAG_CELL_COLOR ToName: "LightCyan"];
  [depthColormap setColor: TAG_FISH_COLOR ToName: "green"];
  [depthColormap setColor: DAYTIMERASTER ToName: "LightBlue1"];
  //[depthColormap setColor: NIGHTTIMERASTER ToName: "gray5"];
  [depthColormap setColor: NIGHTTIMERASTER ToName: "MidnightBlue"];

  [velocityColormap setColor: UTMBOUNDARYCOLOR ToName: "black"];
  [velocityColormap setColor: TAG_CELL_COLOR ToName: "LightCyan"];
  [velocityColormap setColor: TAG_FISH_COLOR ToName: "green"];
  [velocityColormap setColor: DAYTIMERASTER ToName: "LightBlue1"];
  //[velocityColormap setColor: NIGHTTIMERASTER ToName: "gray5"];
  [velocityColormap setColor: NIGHTTIMERASTER ToName: "MidnightBlue"];
  
  /*
  [utmColormap setColor: UTMBOUNDARYCOLOR ToName: "black"];
  [utmColormap setColor: TAG_CELL_COLOR ToName: "LightCyan"];
  [utmColormap setColor: TAG_FISH_COLOR ToName: "green"];
  [utmColormap setColor: DAYTIMERASTER ToName: "LightBlue1"];
  [utmColormap setColor: NIGHTTIMERASTER ToName: "gray5"];
  */
  

  /*
  [utmColormap setColor: TAG_CELL_COLOR ToName: "aquamarine"];
  [utmColormap setColor: UTMINTERIORCOLOR ToName: "yellow"];
  [utmColormap setColor: UTMBOUNDARYCOLOR ToName: "LightCyan"];
  */

  /*
  for( ndx = CELL_COLOR_DRY; ndx < (CELL_COLOR_DRY + CELL_COLOR_WET); ndx++)
  {

        double aBlueRatio =  (double) (ndx - CELL_COLOR_DRY)/((double) CELL_COLOR_WET - 1.0);
        double aBlueFrac = (double) (1.0 + (2.0 * aBlueRatio));
        double aRedGreenFrac = (double) ((3.0 - aBlueFrac)/2.0);
      
        [backwaterColormap setColor: ndx 
                     ToRed: aRedGreenFrac
                     Green: aRedGreenFrac 
                      Blue: aBlueFrac];


  }
  */


  /*
  utmColormap = [Colormap create: globalZone];

  for (ndx = 0; ndx <= CELL_COLOR_MAX; ndx++)  
  {
     [utmColormap setColor: ndx 
                     ToRed: (CELL_COLOR_START + 
                            ((double)ndx * 
                            ((1.0-CELL_COLOR_START)/((double)CELL_COLOR_MAX))))
                     Green: (CELL_COLOR_START + 
                            ((double)ndx * 
                            ((1.0-CELL_COLOR_START)/((double)CELL_COLOR_MAX))))
                      Blue: (CELL_COLOR_START + 
                            ((double)ndx * 
                            ((1.0-CELL_COLOR_START)/((double)CELL_COLOR_MAX))))];
  }
  */

  

  
   //
   //build model Objects and set the fish color in the ModelSwarm
   //
   [troutModelSwarm setUTMRasterResolution:  rasterResolution
                   setUTMRasterResolutionX:  rasterResolutionX
                   setUTMRasterResolutionY:  rasterResolutionY 
                 setUTMRasterColorVariable:  rasterColorVariable];

   //[troutModelSwarm buildObjectsWith: utmColormap
   [troutModelSwarm buildObjectsWith: utmColorMaps
                             andWith: shadeColorMax];

   habitatSpace = [troutModelSwarm getHabitatSpace];
            
   utmWorldRaster = [ZoomRaster createBegin: obsZone];
   SET_WINDOW_GEOMETRY_RECORD_NAME (utmWorldRaster);
   utmWorldRaster = [utmWorldRaster createEnd];
   [utmWorldRaster enableDestroyNotification: self
                          notificationMethod: @selector (utmRasterDeath:)];

   [utmWorldRaster setColormap: utmColormap];

   rasterX = [habitatSpace getUTMPixelsX];
   rasterY = [habitatSpace getUTMPixelsY];
   rasterSize = (rasterX >= rasterY ? rasterX : rasterY )/rasterResolution;
   [utmWorldRaster setZoomFactor: rasterZoomFactor];
 
   [utmWorldRaster setWidth: rasterX/rasterResolutionX Height: rasterY/rasterResolutionY];
 
   strncpy(reachName, [habitatSpace getReachName], 50);
   [utmWorldRaster setWindowTitle: reachName];

   [utmWorldRaster pack];				  // draw the window.


   utmCellDisplay = [Object2dDisplay createBegin: obsZone];
   [utmCellDisplay setDisplayWidget: utmWorldRaster];
   [utmCellDisplay setDiscrete2dToDisplay: habitatSpace];
   [utmCellDisplay setObjectCollection: 
   [habitatSpace getUTMCellList]];
   [utmCellDisplay setDisplayMessage: M(drawSelfOn:)];   // draw method
   utmCellDisplay = [utmCellDisplay createEnd];

   [utmWorldRaster setButton: ButtonLeft
                      Client: habitatSpace 
                     Message: M(probeUTMCellAtX:Y:)];
     
   [utmWorldRaster setButton: ButtonRight
                      Client: habitatSpace 
                     Message: M(probeFishAtX:Y:)];

   [self buildFishProbes];

   //
   // The graph sequences are generated in the 
   // ModelSwarm method -- createGraphSeq
   //
   mortalityGraph = [EZGraph createBegin: self];
   SET_WINDOW_GEOMETRY_RECORD_NAME (mortalityGraph); 
   [mortalityGraph setTitle: "Mortality"];
   [mortalityGraph setAxisLabelsX: "Time" Y: "NumberDead"];
   mortalityGraph = [mortalityGraph createEnd];
 
   [troutModelSwarm setMortalityGraph: mortalityGraph];

   [mortalityGraph enableDestroyNotification: self
                          notificationMethod: @selector (_mortalityGraphDeath:)];


   CREATE_ARCHIVED_PROBE_DISPLAY (habitatSpace);
   

   fprintf(stdout, "UTMTroutObserverSwarm >>>> buildObjects >>>> END\n");
   fflush(0);

   return self;

}  //buildObjects


///////////////////////////////////
//
// switchColorRep
//
///////////////////////////////////
- switchColorRep
{
  //int ndx;
  int shadeColorMax;

  //fprintf(stdout, "UTMTroutOPbserverSwarm >>>> switchColorRep BEGIN\n");
  //fflush(0);

  /*
  for(ndx = 0; ndx < CELL_COLOR_MAX; ndx++)
  {
     [utmColormap unsetColor: ndx];
  } 
  */
  
  if(strncmp(toggleColorVariable, "velocity", 8) == 0)
  {
     strncpy(toggleColorVariable, "depth", 6);

     if(maxShadeDepth <= 0.0)
     {
         fprintf(stderr, "ERROR: UTMTroutObserverSwarm >>>> maxShadeDepth is <= 0.0 >>>> check Observer.Setup\n");
         fflush(0);
         exit(1);
     }
     else if(maxShadeDepth < CELL_COLOR_MAX)
     {
         shadeColorMax = (int) (maxShadeDepth + 0.5);
     }
     else 
     {
        shadeColorMax = CELL_COLOR_MAX;
     }
 
     /*
     for(ndx = 0; ndx < shadeColorMax; ndx++)
     {
           double aRedFrac = 0.0;
           double aGreenFrac = (double) (shadeColorMax - 1.0 - ndx)/((double) shadeColorMax - 1.0);
           double aBlueFrac =  1.0;

           [utmColormap setColor: ndx 
                           ToRed: aRedFrac
                           Green: aGreenFrac
                            Blue: aBlueFrac];

     }
     */

     [troutModelSwarm setShadeColorMax: shadeColorMax]; 
  }
  else if(strncmp(toggleColorVariable, "depth", 5) == 0)
  {
     strncpy(toggleColorVariable, "velocity", 9);

     if(maxShadeVelocity <= 0.0)
     {
         fprintf(stderr, "ERROR: UTMTroutObserverSwarm >>>> maxShadeVelocity is <= 0.0 >>>> check Observer.Setup\n");
         fflush(0);
         exit(1);
     }
     else if(maxShadeVelocity < CELL_COLOR_MAX)
     {
         shadeColorMax = (int) (maxShadeVelocity + 0.5);
     }
     else 
     {
        shadeColorMax = CELL_COLOR_MAX;
     }
 
     /*
     for(ndx = 0; ndx < shadeColorMax; ndx++)
     {
           double aRedFrac = 1.0;
           double aGreenFrac = (double) (shadeColorMax - 1.0 - ndx)/((double) shadeColorMax - 1.0);
           double aBlueFrac = 0.0;

           [utmColormap setColor: ndx 
                           ToRed: aRedFrac
                           Green: aGreenFrac
                            Blue: aBlueFrac];

     }
     */
     [troutModelSwarm setShadeColorMax: shadeColorMax]; 
  }


  if(currentRepresentation == Velocity)
  {
     currentRepresentation = Depth;
     utmColormap = [utmColorMaps at: Depth];
     [utmWorldRaster setColormap: utmColormap];
  }
  else if(currentRepresentation == Depth)
  {
     currentRepresentation = Velocity;
     utmColormap = [utmColorMaps at: Velocity];
     [utmWorldRaster setColormap: utmColormap];
  }


  [troutModelSwarm updateCells];
  [self redrawRaster];

  //fprintf(stdout, "UTMTroutOPbserverSwarm >>>> switchColorRep END\n");
  //fflush(0);

  return self;
}



////////////////////////////////////
//
// redrawRaster
//
//////////////////////////////////
- redrawRaster
{
  id habitatSpace = [troutModelSwarm getHabitatSpace];
  [utmWorldRaster erase];

  //fprintf(stdout, "UTMTroutObserverSwarm >>>> redrawRaster >>>> currentPhase = %d\n", [habitatSpace getCurrentPhase]);
  //fflush(0);
 
  if([habitatSpace getCurrentPhase] == 0)
  {
      [utmWorldRaster fillRectangleX0: 0 
                                Y0: 0 
                                X1: rasterX/rasterResolutionX 
                                Y1: rasterY/rasterResolutionY 
                             Color: NIGHTTIMERASTER];
  }
  else
  {
      [utmWorldRaster fillRectangleX0: 0 
                                Y0: 0 
                                X1: rasterX/rasterResolutionX 
                                Y1: rasterY/rasterResolutionY 
                             Color: DAYTIMERASTER];

  }

  [utmCellDisplay display];
  [utmWorldRaster drawSelf];

  return self;
}

////////////////////////////////////
//
// _update_
//
//////////////////////////////////
- _update_ 
{
  //if(utmWorldRaster) 
  //{
    [self redrawRaster];
    //[utmWorldRaster erase];
    //[utmCellDisplay display];
    //[utmWorldRaster drawSelf];
  //}
  if(mortalityGraph) 
  {
     [mortalityGraph step];
  }


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
