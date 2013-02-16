//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 




#import <math.h>
#import <string.h>
#import <simtools.h>
#import <random.h>
#import "UTMTroutObserverSwarm.h"
#import "FishParams.h"
#import "FishCell.h"
#import "UTMTroutModelSwarm.h"

id <Symbol> Female, Male;  // sex of fish
id <Symbol> Age0, Age1, Age2, Age3Plus;

id <Symbol> *mySpecies;
id <Symbol> Feed, Hide;
Class *MyTroutClass; 
char **speciesName;
char **speciesColor;
char **speciesParameter;
char **speciesPopFile;
char **speciesStocking;

@implementation UTMTroutModelSwarm


///////////////////////
//
// create
//
//////////////////////
+ create: aZone 
{
  UTMTroutModelSwarm * troutModelSwarm;

  troutModelSwarm = [super create: aZone];

  troutModelSwarm->observerSwarm = nil;

  troutModelSwarm->popInitDate = (char *) nil;

  troutModelSwarm->age0AveLength=nil;
  troutModelSwarm->age1AveLength=nil;
  troutModelSwarm->age2AveLength=nil;
  troutModelSwarm->age3PAveLength=nil;

  troutModelSwarm->fishMortalityPtr=NULL;
  troutModelSwarm->deathMap=nil;

  troutModelSwarm->timeManager=nil;

  troutModelSwarm->mortalityGraph=nil;

  troutModelSwarm->minSpeciesMinPiscLength = (double) LARGEINT; 

  troutModelSwarm->isFirstStep = TRUE;

  troutModelSwarm->habSetupFile = (char *) nil;
  troutModelSwarm->fishOutputFile = (char *) nil;
  troutModelSwarm->speciesDepthUseOutStreamMap = nil; 
  troutModelSwarm->speciesVelocityUseOutStreamMap = nil;

  // Initialize optional output file controls
  troutModelSwarm->writeFoodAvailabilityReport = NO;
  troutModelSwarm->writeDepthReport = NO;
  troutModelSwarm->writeVelocityReport = NO;
  troutModelSwarm->writeHabitatReport = NO;
  troutModelSwarm->writeDepthVelocityReport = NO;
  troutModelSwarm->writeMoveReport = NO;
  troutModelSwarm->writeReadyToSpawnReport = NO;
  troutModelSwarm->writeSpawnCellReport = NO;
  troutModelSwarm->writeReddSurvReport = NO;
  troutModelSwarm->writeCellFishReport = NO;
  troutModelSwarm->writeReddMortReport = NO;
  troutModelSwarm->writeIndividualFishReport = NO;
  troutModelSwarm->writeCellCentroidReport = NO;

  return troutModelSwarm;

}


////////////////////////////////////
//
// setObserverSwarm
//
///////////////////////////////////
- setObserverSwarm: anObserverSwarm
{
    observerSwarm = anObserverSwarm;
    return self;
}

//////////////////////////////////////////////////////////////
//
// instantiateObjects
//
/////////////////////////////////////////////////////////////
- instantiateObjects 
{
       fprintf(stdout, "UTMTroutModelSwarm >>>> instantiateObjects BEGIN\n"); 
       fflush(0);
   int numspecies;
   modelZone = [Zone create: globalZone];

  if(numberOfSpecies == 0)
  {
       fprintf(stderr, "ERROR: UTMTroutModelSwarm >>>> instantiateObjects numberOfSpecies is ZERO!\n"); 
       fflush(0);
       exit(1);
  }

  reachSymbolList = [List create: modelZone];

  [self readSpeciesSetupFile];

       fprintf(stdout, "UTMTroutModelSwarm >>>> instantiateObjects 2, %d \n",numberOfSpecies); 
       fflush(0);
  //
  // Create list of species symbols
  //
  mySpecies = (id *) [modelZone alloc: numberOfSpecies*sizeof(Symbol)];
  for(numspecies = 0; numspecies < numberOfSpecies; numspecies++ )
  {
       fprintf(stdout, "UTMTroutModelSwarm >>>> instantiateObjects 3, %d \n",numspecies); 
       fflush(0);
     mySpecies[numspecies] = [Symbol create: modelZone setName: speciesName[numspecies] ];
  }

  speciesSymbolList = [List create: modelZone];
  for(numspecies = 0; numspecies < numberOfSpecies; numspecies++ )
  {
    [speciesSymbolList addLast: mySpecies[numspecies] ];
  }


  fishMortSymbolList = [List create: modelZone];
  reddMortSymbolList = [List create: modelZone];

       fprintf(stdout, "UTMTroutModelSwarm >>>> instantiateObjects 3\n"); 
       fflush(0);
  [self getFishMortalitySymbolWithName: "DemonicIntrusion"];

  fishParamsMap = [Map create: modelZone];

  [self createFishParameters];
  [self findMinSpeciesPiscLength];

  //
  // To create additional age classes, add more symbols to this list.
  // Then modify the code in getAgeSymbolForAge 
  // that assigns symbols to fish.
  // 
  ageSymbolList = [List create: modelZone];

  Age0     = [Symbol create: modelZone setName: "Age0"];
  [ageSymbolList addLast: Age0];
  Age1     = [Symbol create: modelZone setName: "Age1"];
  [ageSymbolList addLast: Age1];
  Age2     = [Symbol create: modelZone setName: "Age2"];
  [ageSymbolList addLast: Age2];
  Age3Plus = [Symbol create: modelZone setName: "Age3Plus"];
  [ageSymbolList addLast: Age3Plus];

  reachSymbolList = [List create: modelZone];

  fishCounter = 0;

  habitatManager = [HabitatManager createBegin: modelZone];
  [habitatManager instantiateObjects];
  [habitatManager setSiteLatitude: siteLatitude];
  [habitatManager createSolarManager];
  [habitatManager setModel: self];
  [habitatManager readReachSetupFile: "Reach.Setup"];
  [habitatManager setNumberOfSpecies: numberOfSpecies];
  [habitatManager setFishParamsMap: fishParamsMap];
  [habitatManager instantiateHabitatSpacesInZone: modelZone];

  return self;

}

//////////////////////////////////////////////////////////////////
//
// buildObjects
//
/////////////////////////////////////////////////////////////////
- buildObjectsWith: theColormaps
          andWith: (double) aShadeColorMax
{
  int genSeed;
  time_t newYearTime = (time_t) 0;

  fprintf(stdout, "UTMTroutModelSwarm >>>> buildObjects >>>> BEGIN\n");
  fflush(0);

  shadeColorMax = aShadeColorMax;

  if(popInitDate == (char *) nil) 
  {
 
     fprintf(stderr, "ERROR: popInitDate is a NULL value\n"
                     "Check the \"Model Setup\" file\n"
                     "or the \"Experiment Setup\" file\n");
     fflush(0);
     exit(1);
  
  }

  //
  // if we're a sub-swarm, then run our super's buildObjects first
  //
  [super buildObjects];

  areaDepthHistoFmtStr = "%-10d";
  areaVelocityHistoFmtStr = "%-17d";

  modelDate = (char *) [modelZone allocBlock: 15*sizeof(char)];

  //
  // Create the time manager; only the model swarm is allowed to update 
  // the time. There is only one time manager object, any object that requires
  // a time manager will be pointed to the model swarm's time manager
  //

  timeManager = [TimeManager create: modelZone
                      setController: self
                        setTimeStep: (time_t) 3600
               setCurrentTimeWithDate: runStartDate
                           withHour: 0
                         withMinute: 0
                         withSecond: 0];

  [timeManager setDefaultHour: 0
               setDefaultMinute: 0
               setDefaultSecond: 0];


  timeManager = [timeManager createEnd];



  runStartTime = [timeManager getTimeTWithDate:  runStartDate
                                   withHour: 0
                                 withMinute: 0
                                 withSecond: 0];

  runEndTime = [timeManager getTimeTWithDate:  runEndDate
                                   withHour: 23
                                 withMinute: 0
                                 withSecond: 0];

  modelTime = [timeManager getCurrentTimeT];

  numHoursSinceLastStep = 0;

  strncpy(modelDate, [timeManager getDateWithTimeT: modelTime], 12);
    
  if(runStartTime > runEndTime)
  {
      fprintf(stderr, "ERROR: UTMTroutModelSwarm >>>> buildObjects >>>> Check runStartDate and runEndDate in Model.Setup\n");
      fflush(0);
      exit(1);
  }

  //
  // set up the random number generator to be used throughout the model
  //
  if(replicate != 0)
  {
      genSeed = randGenSeed * replicate;
  }
  else 
  {
      genSeed = randGenSeed;
  }

  randGen = [MT19937gen create: modelZone 
              setStateFromSeed: genSeed];

  coinFlip = [RandomBitDist create: modelZone
                      setGenerator: randGen];


  fishMortSymbolList = [List create: modelZone];
  reddMortSymbolList = [List create: modelZone];

  if(shuffleYears == YES){
     //
     // Create the year shuffler and the data start and end times.
     //
     [self createYearShuffler];
      newYearTime = [yearShuffler checkForNewYearAt: modelTime];

      if (newYearTime != modelTime)
      {
         [timeManager setCurrentTime: newYearTime];
         modelTime = newYearTime;
      }
  }else{
      modelTime = runStartTime;
      dataStartTime = runStartTime;
      dataEndTime = runEndTime + 86400;
  }

  //
  // Create the space in which the fish will live
  //
  [habitatManager setTimeManager: timeManager];

  [habitatManager setModelStartTime: (time_t) runStartTime
                         andEndTime: (time_t) runEndTime];

  [habitatManager setDataStartTime: (time_t) dataStartTime
                        andEndTime: (time_t) dataEndTime];

  //
  // Moved from instantiateObjects 
  //
  [habitatManager setPolyRasterResolutionX:  polyRasterResolutionX
                  setPolyRasterResolutionY:  polyRasterResolutionY
                    setRasterColorVariable:   polyRasterColorVariable
                          setShadeColorMax:  shadeColorMax];

  [habitatManager finishBuildingTheHabitatSpaces];
  
  /*
   * for now ignore reporting stuff --colin
  if(writeCellFishReport == YES){
      [habitatManager buildHabSpaceCellFishInfoReporter];
  }
  */

  [habitatManager updateHabitatManagerWithTime: modelTime
                         andWithModelStartFlag: initialDay];

  numberOfReaches = [habitatManager getNumberOfHabitatSpaces];
  reachList = [habitatManager getHabitatSpaceList];

  dataStartTime = runStartTime;
  dataEndTime = runEndTime;

  //
  // The Symbols needed by the model
  //

  Male = [Symbol create: modelZone setName: "Male"];
  Female = [Symbol create: modelZone setName: "Female"];


  Age0     = [Symbol create: modelZone setName: "Age0"];
  Age1     = [Symbol create: modelZone setName: "Age1"];
  Age2     = [Symbol create: modelZone setName: "Age2"];
  Age3Plus = [Symbol create: modelZone setName: "Age3Plus"];

  ageSymbolList = [List create: modelZone];
  [ageSymbolList addLast: Age0];
  [ageSymbolList addLast: Age1];
  [ageSymbolList addLast: Age2];
  [ageSymbolList addLast: Age3Plus];


  fishActivitySymbolList = [List create: modelZone];
  Hide = [Symbol create: modelZone setName: "Hide"];
  [fishActivitySymbolList addLast: Hide];
  Feed = [Symbol create: modelZone setName: "Feed"];
  [fishActivitySymbolList addLast: Feed];


  //
  // The fish lists 
  //
  liveFish   = [List create: modelZone];
  killedFish = [List create: modelZone];
  deadFish   = [List create: modelZone];


  //
  // The redd lists
  //
  reddList      = [List create: modelZone];
  emptyReddList = [List create: modelZone];
  removedRedds  = [List create: modelZone];
  killedRedds   = [List create: modelZone];
  deadRedds     = [List create: modelZone];


      //fprintf(stdout, "UTMTroutModelSwarm >>>> buildObjects >>>> before speciesSymbolList \n");
      //fflush(0);

  //
  // Create and populate the speciesSymbolList needed by the breakout reporters
  //
  {
      id <MapIndex> mapNdx = [fishParamsMap mapBegin: scratchZone];
      FishParams* fishParams = (FishParams *) nil;
    
      speciesSymbolList = [List create: modelZone];

      while(([mapNdx getLoc] != End) && ((fishParams = (FishParams *) [mapNdx next]) != (FishParams *) nil))
      {
         [speciesSymbolList addLast: [fishParams getFishSpecies]];
      }
  
      [mapNdx drop];
  }

  //
  // Create and populate the speciesClassList needed by the observer swarm
  //
  {
     id <ListIndex> lstNdx = nil;
     SpeciesSetup* speciesSetup = NULL;
     
     speciesClassList = [List create: modelZone];
     lstNdx = [speciesSetupList listBegin: scratchZone];
     while(([lstNdx getLoc] != End) && ((speciesSetup = (SpeciesSetup *) [lstNdx next]) != (SpeciesSetup *) nil))
     {
        [speciesClassList addLast: speciesSetup->troutClass];
     } 
  
     [lstNdx drop];  
  }

      //fprintf(stdout, "UTMTroutModelSwarm >>>> buildObjects >>>> before breakoutReporters\n");
      //fflush(0);
  //
  // Breakout reporters... 
  //
  [self createBreakoutReporters];


  if(theColormaps != nil) 
  {
      [self setFishColormap: theColormaps];
  }

      fprintf(stdout, "UTMTroutModelSwarm >>>> buildObjects >>>> before createInitialFish\n");
      fflush(0);
  [self createInitialFish]; 
  [QSort sortObjectsIn:  liveFish];
  [QSort reverseOrderOf: liveFish];
      fprintf(stdout, "UTMTroutModelSwarm >>>> buildObjects >>>> before toggleFish\n");
      fflush(0);
  [self toggleFishForHabSurvUpdate];

      fprintf(stdout, "UTMTroutModelSwarm >>>> buildObjects >>>> before createReproLog\n");
      fflush(0);

  [self createReproLogistics];

  //
  // the following was added here 3/20/2000  
  // numAge3PlusFish needed in the habitat->SpaceCell->survProbs
  // before the model actions execute
  //


  //[self openTroutDepthUseFiles];
  //[self openTroutVelocityUseFiles];


#ifdef INIT_FISH_REPORT
  [self printInitialFishReport];
#endif

  //
  // Initialize mortality counts
  //
  deathMap = [Map create: modelZone];
  numberDead = 0;

  firstTime = YES;

  //
  // Open the fish mortality output file
  // with write or append depending on the
  // values of appendFiles in the Model.Setup 
  // and Experiment.Setup files
  //
  [self openReddSummaryFilePtr];
  [self openReddReportFilePtr];
 
      fprintf(stdout, "UTMTroutModelSwarm >>>> buildObjects >>>> before stocking\n");
      fflush(0);

  //
  // STOCKING
  //
  nextFishStockTime = (time_t) 0;
  fishStockList = [List create: modelZone];
  [self readFishStockingRecords];

  fprintf(stdout, "UTMTroutModelSwarm >>>> buildObjects >>>> END\n");
  fflush(0);

  return self;

} // buildObjects  


///////////////////////////////////////////////
//
// createYearShuffler
//
///////////////////////////////////////////////
- createYearShuffler
{
   startDay = [timeManager getDayOfMonthWithTimeT: runStartTime];
   startMonth = [timeManager getMonthWithTimeT: runStartTime];
   startYear = [timeManager getYearWithTimeT: runStartTime];

   endDay = [timeManager getDayOfMonthWithTimeT: runEndTime];
   endMonth = [timeManager getMonthWithTimeT: runEndTime];
   endYear = [timeManager getYearWithTimeT: runEndTime];

   if(shuffleYearSeed < 0.0)
   {
      fprintf(stderr, "ERROR: TroutModelSwarm >>>> createYearShuffler >>> shuffleYearSeed less than 0\n");
      fflush(0);
      exit(1);
   }

   yearShuffler = [YearShuffler   createBegin: modelZone 
                                withStartTime: runStartTime
                                  withEndTime: runEndTime
                              withReplacement: shuffleYearReplace
                              withRandGenSeed: shuffleYearSeed
                              withTimeManager: timeManager];

   yearShuffler = [yearShuffler createEnd];

   if([[yearShuffler getListOfRandomizedYears] getCount] <= 1)
   {
       fprintf(stderr, "ERROR: TroutModelSwarm >>>> createYearShuffler >>>> Cannot use year shuffler for simulations of one year or less\n");
       fflush(0);
       exit(1);
   }

   //
   // Now calculate dataStartTime and dataEndTime
   //
   {
       int numSimYears = [[yearShuffler getListOfRandomizedYears] getCount];
       int dataEndYear = [timeManager getYearWithTimeT: runStartTime] + numSimYears;
       int dataEndMonth = startMonth;
       int dataEndDay = startDay;

       sprintf(dataEndDate, "%d/%d/%d", dataEndMonth, dataEndDay, dataEndYear);
       dataStartTime = runStartTime;
       dataEndTime = [timeManager getTimeTWithDate: dataEndDate
                                          withHour: 12
                                        withMinute: 0
                                        withSecond: 0];

       dataEndTime = dataEndTime + 86400;

       fprintf(stdout, "TroutModelSwarm >>>> createYearShuffler >>>> numSimYears %d\n", numSimYears);
       fprintf(stdout, "TroutModelSwarm >>>> createYearShuffler >>>> startYear %d endYear %d\n", startYear, endYear);
       fflush(0);
   }

   return self;
}

/////////////////////////////////////////////////////////////
//
// setPolyRasterResolution
//
/////////////////////////////////////////////////////////////
-   setPolyRasterResolutionX:  (int) aRasterResolutionX
    setPolyRasterResolutionY:  (int) aRasterResolutionY
  setPolyRasterColorVariable:  (char *) aRasterColorVariable
{
     polyRasterResolutionX = aRasterResolutionX;
     polyRasterResolutionY = aRasterResolutionY;
     strncpy(polyRasterColorVariable, aRasterColorVariable, 35);


     return self;
}

/////////////////////////
//
// getRandGen
//
/////////////////////////
- getRandGen 
{
   return randGen;
}


////////////////////////////////////////////////////////
//
// setUTMRasterVars
//
////////////////////////////////////////////////////////
-    setUTMRasterResolution:  (int) aUTMRasterResolution
    setUTMRasterResolutionX:  (int) aUTMRasterResolutionX
    setUTMRasterResolutionY:  (int) aUTMRasterResolutionY
  setUTMRasterColorVariable:  (char *) aUTMRasterColorVariable
{
    utmRasterResolution  = aUTMRasterResolution;
    utmRasterResolutionX = aUTMRasterResolutionX;
    utmRasterResolutionY = aUTMRasterResolutionY;
    strncpy(utmRasterColorVariable, aUTMRasterColorVariable, 35);

    return self;
}


////////////////////////////////////
//
// setMortalityGraph
//
////////////////////////////////////
- setMortalityGraph: (id) aGraph
{
   mortalityGraph = aGraph;
   return self;
}

//////////////////////////////////////////////////////
//
// createFishParameters
//
// Create parameter objects for the fish
// parameters
//
/////////////////////////////////////////////////////
- createFishParameters
{
   int speciesNdx;

   fprintf(stdout, "TroutMOdelSwarm >>>> createFishParameters >>>> BEGIN\n");
   fflush(0);


   for(speciesNdx = 0; speciesNdx < numberOfSpecies; speciesNdx++) 
   {
      FishParams* fishParams = [FishParams createBegin:  modelZone];
      [ObjectLoader load: fishParams fromFileNamed: speciesParameter[speciesNdx]];
 
      [fishParams setFishSpeciesIndex: speciesNdx]; 
      [fishParams setFishSpecies: mySpecies[speciesNdx]]; 

      [fishParams setInstanceName: (char *) [mySpecies[speciesNdx] getName]];
      fprintf(stdout, "TroutMOdelSwarm >>>> createFishParameters >>>> InstanceName: %s \n", (char *) [mySpecies[speciesNdx] getName]);
	   fflush(0);

      fishParams = [fishParams createEnd];

      #ifdef DEBUG_TROUT_FISHPARAMS
         [fishParams printSelf];
      #endif

      [fishParamsMap at: [fishParams getFishSpecies] insert: fishParams]; 
   }


   fprintf(stdout, "TroutMOdelSwarm >>>> createFishParameters >>>> END\n");
   fflush(0);
   return self;

}  // createFishParameters



//////////////////////////////////////////////
//
// findMinSpeciesPiscLength 
//
//////////////////////////////////////////////
- findMinSpeciesPiscLength
{
  id <MapIndex> mapNdx = nil;
  FishParams* fishParams = nil;

  fprintf(stdout, "TroutModelSwarm >>>> findMinSpeciesPiscLength >>>> BEGIN\n");
  fflush(0);

  mapNdx = [fishParamsMap mapBegin: scratchZone];

  while(([mapNdx getLoc] != End) && ((fishParams = (FishParams *) [mapNdx next]) != (FishParams *) nil))
  {
     minSpeciesMinPiscLength =  (minSpeciesMinPiscLength > fishParams->fishPiscivoryLength) ?
                                 fishParams->fishPiscivoryLength  
                                : minSpeciesMinPiscLength;
  }


  [mapNdx drop];

  fprintf(stdout, "TroutModelSwarm >>>> minSpeciesMinPiscLength = %f\n", minSpeciesMinPiscLength);
  fflush(0);

  fprintf(stdout, "TroutModelSwarm >>>> findMinSpeciesPiscLength >>>> END\n");
  fflush(0);

  return self;
}




/////////////////////////////////////////////////////
//
// createReproLogistics
//
// Revised SFR 8/29/02
// Revised per formulation changes SFR 3/27/03
////////////////////////////////////////////////////
- createReproLogistics
{
  id <MapIndex> mapNdx = [fishParamsMap mapBegin: scratchZone];
  FishParams* fishParams = (FishParams *) nil;
  double biggestFishLength = [[liveFish getFirst] getFishLength];

  fprintf(stdout, "TroutModelSwarm >>>> createReproLogistics >>>> BEGIN\n");
  fflush(0);
  reproLogisticFuncMap = [Map create: modelZone];

  while(([mapNdx getLoc] != End) && ((fishParams = (FishParams *) [mapNdx next]) != (FishParams *) nil))
  {
     LogisticFunc* reproLogisticFunc;

     if(biggestFishLength < (1.5 * fishParams->fishSpawnMinLength))
     {
         // If biggestFishLength is below 1.5 * spawning length,
         // then set the logistic to reach 0.9 at 1.5 times
         // min spawn length.

         biggestFishLength = 1.5 * fishParams->fishSpawnMinLength;
     }

     reproLogisticFunc = [LogisticFunc createBegin: modelZone
                                   withInputMethod: @selector(getFishLength)
                                        usingIndep: fishParams->fishSpawnMinLength
                                               dep: 0.7
                                             indep: biggestFishLength
                                               dep: 0.9];

     [reproLogisticFunc setLogisticFuncLimiterTo: 24.0];

     [reproLogisticFuncMap at: [fishParams getFishSpecies]
                       insert: reproLogisticFunc];

  }

  [mapNdx drop];

  fprintf(stdout, "UTMTroutModelSwarm >>>> createReproLogistics >>>> biggestFishLength = %f\n", biggestFishLength);
  fprintf(stdout, "UTMTroutModelSwarm >>>> createReproLogistics >>>> END\n");
  fflush(0);

  return self;
}
      

////////////////////////////////////////////////////////////
//
// updateReproFuncs
//
// Revised per formulation changes SFR 3/27/03
////////////////////////////////////////////////////////////
- updateReproFuncs
{
  id <MapIndex> mapNdx = [fishParamsMap mapBegin: scratchZone];
  FishParams* fishParams = (FishParams *) nil;
  double biggestFishLength = 0.0;

  if([liveFish getCount] > 0)
  {
     biggestFishLength = [[liveFish getFirst] getFishLength];
  }

  //fprintf(stdout, "UTMTroutModelSwarm >>>> updateReproFuncs BEGIN\n");
  //fflush(0);

  while(([mapNdx getLoc] != End) && ((fishParams = (FishParams *) [mapNdx next]) != (FishParams *) nil))
  {
     LogisticFunc* reproLogisticFunc = [reproLogisticFuncMap at: [fishParams getFishSpecies]];

     if(biggestFishLength < (1.5 * fishParams->fishSpawnMinLength))
     {
         // If biggestFishLength is below spawning length,
         // then set the logistic to reach 0.9 at 1.5 times
         // min spawn length.

         biggestFishLength = 1.5 * fishParams->fishSpawnMinLength;
     }

     [reproLogisticFunc initializeWithIndep: fishParams->fishSpawnMinLength
                                        dep: 0.7
                                      indep: biggestFishLength
                                        dep: 0.9];
  }

  [mapNdx drop];

  //fprintf(stdout, "UTMTroutModelSwarm >>>> updateReproFuncs biggestFishLength = %f\n", biggestFishLength);
  //fprintf(stdout, "UTMTroutModelSwarm >>>> updateReproFuncs END\n");
  //fflush(0);

  return self;

}



//////////////////////////////////////////////////
//
// getReproFuncFor:withLength
//
//////////////////////////////////////////////////
- (double) getReproFuncFor: aFish 
                withLength: (double) aLength
{
      return [[reproLogisticFuncMap at: [aFish getSpecies]]
                          evaluateFor: aLength];
}
                                                    




/////////////////////////////////////////////////////////
//
// setFishColormap
//
//////////////////////////////////////////////
- setFishColormap: theColormaps
{
  id <ListIndex> lstNdx = nil;
  int FISH_COLOR = (int) FISHCOLORSTART;
  SpeciesSetup* speciesSetup = (SpeciesSetup *) nil;

  id <MapIndex> clrMapNdx = [theColormaps mapBegin: scratchZone];
  id <Colormap> aColorMap = nil;

  

  fprintf(stdout, "UTMTroutModelSwarm >>>> setFishColorMap >>>> BEGIN\n");
  fprintf(stdout, "UTMTroutModelSwarm >>>> setFishColorMap >>>> FISH_COLOR = %d\n", FISH_COLOR);
  fflush(0);

  while(([clrMapNdx getLoc] != End) && ((aColorMap = [clrMapNdx next]) != nil))
  {
     [aColorMap setColor: FISH_COLOR 
                  ToName: tagFishColor];
  }

  fishColorMap = [Map create: modelZone];

  FISH_COLOR++;

  fprintf(stdout, "UTMTroutModelSwarm >>>> setFishColorMap >>>> FISH_COLOR = %d\n", FISH_COLOR);
  fflush(0);

  lstNdx = [speciesSetupList listBegin: scratchZone];
  while (([lstNdx getLoc] != End) && ((speciesSetup = (SpeciesSetup *) [lstNdx next]) != (SpeciesSetup *) nil)) 
  {
      int* fishColor = (int *) [ZoneAllocMapper allocBlockIn: modelZone
                                                      ofSize: sizeof(int)];
      [clrMapNdx setLoc: Start];
     
      while(([clrMapNdx getLoc] != End) && ((aColorMap = [clrMapNdx next]) != nil))
      {
          [aColorMap setColor: FISH_COLOR 
                       ToName: speciesSetup->fishColor];
      }

      *fishColor = FISH_COLOR;

      FISH_COLOR++;

      [fishColorMap at: speciesSetup->speciesSymbol 
                insert: (void *) fishColor];
  }

  [lstNdx drop];
  [clrMapNdx drop];

  fprintf(stdout, "UTMTroutModelSwarm >>>> setFishColorMap >>>> END\n");
  fflush(0);

  return self;
}


/////////////////////////////////////////////////////////////////
//
// createInitialFish
//
// Create the initial lists of trout 
//
////////////////////////////////////////////////////////////////////
- createInitialFish 
{
   BOOL INIT_DATE_FOUND = NO;
   int MAX_COUNT=10000000;
   int counter = 0;
 
   id randCellDist = nil;
   id <NormalDist> lengthDist = nil;
 
   id <ListIndex> initPopLstNdx = nil;
   InitialFishRecord* initialFishRecord = (InitialFishRecord *) nil;

   id aHabitatSpace;
   id <List> polyCellList = nil;
   
   
   fprintf(stdout,"UTMTroutModelSwarm >>>> createInitialFish BEGIN\n");
   fflush(0);

   //
   // set up the distribution that will place the fishes on the grid
   //
   lengthDist = [NormalDist create: modelZone 
                      setGenerator: randGen];
   //
   // read the population files for each species
   //
   [self readPopFiles];

   initPopLstNdx = [initialFishRecordList listBegin: scratchZone];
  
   numFish = 0;

   while(([initPopLstNdx getLoc] != End) && ((initialFishRecord = (InitialFishRecord *) [initPopLstNdx next]) != (InitialFishRecord *) nil)) 
   {
      //
      //Begin species loop
      //
      int numFishNdx;
      id randSelectedCell = nil;
  
      if(initialFishRecord->initTime == [timeManager getTimeTWithDate: popInitDate])
      {
          //
          // If we don't ever make it here, no fish will be initialized
          //
 
          INIT_DATE_FOUND = YES;
      }
      else
      {
           continue;
      }
      
       aHabitatSpace = nil;
       aHabitatSpace = [habitatManager getReachWithName: initialFishRecord->reach];
        
       if(aHabitatSpace == nil)
       {
            //
            // Then skip it and move on
            //
            fprintf(stderr, "WARNING: TroutModelSwarm >>>> createInitialFish >>>> no habitat space with name %s\n", initialFishRecord->reach);
            fflush(0);
            continue;
       }



       polyCellList = [aHabitatSpace getPolyCellList];

       randCellDist = [UniformIntegerDist create: modelZone
                                    setGenerator: randGen
                                   setIntegerMin: 0
                                          setMax: [polyCellList getCount] - 1];
   fprintf(stdout,"UTMTroutModelSwarm >>>> createInitialFish >>>> before lengthDist \n");
   fflush(0);

      [lengthDist setMean: initialFishRecord->meanLength
                setStdDev: initialFishRecord->stdDevLength];


      for(numFishNdx=0; numFishNdx < initialFishRecord->numberOfFish; numFishNdx++)
      {
          id newFish;
          double length;
          FishParams* fishParams = initialFishRecord->fishParams;
          int age = initialFishRecord->age;

          while((length = [lengthDist getDoubleSample]) <= (0.5)*[lengthDist getMean]) 
          {
               continue;
          }

   fprintf(stdout,"UTMTroutModelSwarm >>>> createInitialFish >>>> before newFish\n");
   fflush(0);
          newFish = [self createNewFishWithFishParams: fishParams  
                                       withTroutClass: initialFishRecord->troutClass
                                                  Age: age
                                               Length: length];

          [liveFish addLast: newFish];

          //
          // need to draw for random position
          //
          for(counter=0; counter<=MAX_COUNT; counter++)
          {
	       randSelectedCell = [polyCellList atOffset: [randCellDist getIntegerSample]];

               if(randSelectedCell != nil)
               {
                   if([randSelectedCell getPolyCellDepth] > 0.0)
                   {
                        double aMortFishVelocityV9 = [newFish getFishParams]->mortFishVelocityV9;
                        if([randSelectedCell getPolyCellVelocity] > [newFish getMaxSwimSpeed] * aMortFishVelocityV9)
                        {
                             // Be sure to UNCOMMENT this...
                             //continue;
                        }

                        [randSelectedCell addFish: newFish];
                        [newFish setFishCell: randSelectedCell];
                        numFish++;
                        break;                      //break out of the for statement
                   }
               }
               else
               {
                 continue;
               }
            }

            if(counter >= MAX_COUNT)
            {
                  fprintf(stderr, "ERROR >>>> UTMTroutModelSwarm >>>> createInitialFish >>>> Failed to put fish at nonzero depth cell after %d attempts\n",counter);
                  fflush(0);
                  exit(1);
            }

         }  //for



         //
         // cleanup
         //
            

   }  // while
   fprintf(stdout,"UTMTroutModelSwarm >>>> createInitialFish >>>> after loop\n");
   fflush(0);

   if(!INIT_DATE_FOUND)
   {
        fprintf(stderr, "ERROR: UTMTroutModelSwarm >>>> createInitialFish >>>> No fish were initialized; check the fish initialization\n" 
                                   "       dates in the \"Init Fish\" and the \"Model Setup\" or \n"
                                   "       \"Experiment Setup\" files\n");
        fflush(0);
        exit(1);

    }

  [lengthDist drop];
  [randCellDist drop];

  [initPopLstNdx drop];

  fprintf(stdout,"UTMTroutModelSwarm >>>> createInitialFish >>>> END\n");
  fflush(0);

  return self;

} // createInitialFish




/////////////////////////////////////////////////////
//
// readFishStockingRecords
//
/////////////////////////////////////////////////////
- readFishStockingRecords
{
   FILE* stockFilePtr = NULL;
   id <ListIndex> lstNdx = [speciesSetupList listBegin: scratchZone];
   SpeciesSetup* speciesSetup = (SpeciesSetup *) nil;

   char header1[HCOMMENTLENGTH];
   char date[15];
   int age=0;
   int numOfFish=0;
   double meanLength=0.0;
   double stdDevLength=0.0;

   time_t aStockTime;
   nextFishStockTime = runEndTime; 

   while(([lstNdx getLoc] != End) && ((speciesSetup = (SpeciesSetup *) [lstNdx next]) != (SpeciesSetup *) nil))
   {
       if(strncmp(speciesSetup->stocking, "NoStocking", 10) == 0)
       {
          continue;
       }
      
       if((stockFilePtr = fopen(speciesSetup->stocking, "r")) == NULL) 
       {
             fprintf(stderr, "ERROR: UTMTroutModelSwarm >>>> readFishStockingRecords cannot open file %s \n", speciesSetup->stocking);
             fflush(0);
             exit(1);
       }
    

       fgets(header1,HCOMMENTLENGTH,stockFilePtr);
       fgets(header1,HCOMMENTLENGTH,stockFilePtr);
       fgets(header1,HCOMMENTLENGTH,stockFilePtr);

       while((fscanf(stockFilePtr, "%s%d%d%lf%lf", date,
                                                   &age,
                                                   &numOfFish,
                                                   &meanLength,
                                                   &stdDevLength)) != EOF)
       {
 
            FishStockStruct* fishStockRecord;

            aStockTime = [timeManager getTimeTWithDate: date
                                              withHour: 10
                                            withMinute: 0
                                            withSecond: 0];

              //
              // Skip records that have stock times before
              // the start of a model run.
              //
              if(aStockTime < runStartTime) 
              {  
                 continue;
              }
              
              fishStockRecord = (FishStockStruct *) [ZoneAllocMapper allocBlockIn: modelZone 
                                                                           ofSize: sizeof(FishStockStruct)];
                     
              fishStockRecord->fishStockTime = aStockTime;
	      fishStockRecord->speciesSymbol = speciesSetup->speciesSymbol;
              fishStockRecord->speciesNdx = speciesSetup->speciesIndex;
              fishStockRecord->age = age;
              fishStockRecord->numberOfFishThisAge = numOfFish;
              fishStockRecord->meanLength = meanLength;
              fishStockRecord->stdDevLength = stdDevLength;
              fishStockRecord->troutClass = speciesSetup->troutClass;
              fishStockRecord->fishParams = speciesSetup->fishParams;

              /*
              fprintf(stdout, "%s %d %d %f %f\n", date, age, numOfFish, meanLength, stdDevLength);
              fprintf(stdout, "%ld %s %d %d %d %f %f \n", fishStockRecord->fishStockTime,
	                                                  [fishStockRecord->speciesSymbol getName],
                                                          fishStockRecord->speciesNdx,
                                                          fishStockRecord->age,
                                                          fishStockRecord->numberOfFishThisAge,
                                                          fishStockRecord->meanLength,
                                                          fishStockRecord->stdDevLength);
              fflush(0);
              */



              [fishStockList addLast: (void *) fishStockRecord];
        
              nextFishStockTime = (fishStockRecord->fishStockTime < nextFishStockTime) ? fishStockRecord->fishStockTime : nextFishStockTime;

              //fprintf(stdout, "nextFishStockTime = %ld\n", nextFishStockTime), 
              //fflush(0);
         }
                                  
         fclose(stockFilePtr);
    } 

    [lstNdx drop];

    return self;
}



//////////////////////////////////////////
//
// stock
//
//////////////////////////////////////////
- stock
{
   id <ListIndex> listNdx = nil;
   FishStockStruct* fishStockRecord = (FishStockStruct *) nil;

   int MAX_COUNT=1000000;
   id randCellDist = nil;

   id lengthNormalDist = nil; // this distribution goes out of scope


   int arraySize = [fishStockList getCount];
   time_t nextTimeArray[arraySize];
   int i = 0;

   id aHabitatSpace;
   id <List> polyCellList = nil;

   //fprintf(stdout, "UTMTroutModelSwarm >>>> stock >>>> END\n");
   //fflush(0);


   if([fishStockList getCount] == 0) return self;

   //
   // set up the distribution that will place the fishes on the grid
   //

   lengthNormalDist = [NormalDist create: modelZone 
                      setGenerator: randGen];


   listNdx = [fishStockList listBegin: scratchZone];

   [listNdx setLoc: Start];

   while(([listNdx getLoc] != End) && ((fishStockRecord = (FishStockStruct *) [listNdx next]) != (FishStockStruct *) nil))
   {

          nextTimeArray[i++] = fishStockRecord->fishStockTime;
        
          if(fishStockRecord->fishStockTime == nextFishStockTime)
          {

                int fishNdx;
	       aHabitatSpace = nil;
	       aHabitatSpace = [habitatManager getReachWithName: fishStockRecord->reach];
		
	       if(aHabitatSpace == nil)
	       {
		    //
		    // Then skip it and move on
		    //
		    fprintf(stderr, "WARNING: TroutModelSwarm >>>> stock >>>> no habitat space with name %s\n", fishStockRecord->reach);
		    fflush(0);
		    continue;
	       }



	       polyCellList = [aHabitatSpace getPolyCellList];

	       randCellDist = [UniformIntegerDist create: modelZone
					    setGenerator: randGen
					   setIntegerMin: 0
						  setMax: [polyCellList getCount] - 1];

                //fprintf(stdout, "%ld %s %d %d %d %f %f \n", 
                                      //fishStockRecord->fishStockTime,
	                              //[fishStockRecord->speciesSymbol getName],
                                      //fishStockRecord->speciesNdx,
                                      //fishStockRecord->age,
                                      //fishStockRecord->numberOfFishThisAge,
                                      //fishStockRecord->meanLength,
                                      //fishStockRecord->stdDevLength);
                //fflush(0);
         

                for (fishNdx=0;fishNdx<fishStockRecord->numberOfFishThisAge;fishNdx++)
		{

		    id newFish;
		    double length;
                    id randSelectedCell = nil;
                    int counter = 0;

		    // set properties of the new Trout

                    [lengthNormalDist setMean: fishStockRecord->meanLength
                                    setStdDev: fishStockRecord->stdDevLength];

		    while((length = [lengthNormalDist getDoubleSample]) <= (0.5)*[lengthNormalDist getMean])
                    {
                         ;
                    }

                    newFish = [self createNewFishWithFishParams: fishStockRecord->fishParams  
                                                 withTroutClass: fishStockRecord->troutClass
                                                            Age: fishStockRecord->age
                                                         Length: length];

                   [newFish setStockedFishActivity: Feed];
  
                   [liveFish addLast: newFish];

                    //
		    // need to draw for random position
                    //
		    for(counter=0;counter<=MAX_COUNT;counter++)
		    {
	                randSelectedCell = [polyCellList atOffset: [randCellDist getIntegerSample]];

		        if(randSelectedCell != nil)
		        {
                            //
                            // Min depth changed to 50 SFR 4/7/03
                            //
			    if([randSelectedCell getPolyCellDepth] > 50.0)
			    {
                                double depthLengthRatio;
			        [randSelectedCell addFish: newFish];
                                [newFish setWorld: randSelectedCell];
  
                                //
                                // Initialize fish's depth/length ratio so stranding mort works
                                //
                                depthLengthRatio = [randSelectedCell getPolyCellDepth] / [newFish getFishLength];
                                [newFish setDepthLengthRatio: depthLengthRatio];
  
			         numFish++;  //instance variable

			         break; 
			     }
		         }
		         else
		         {
		           continue;
		         }
		      }
		 
		      if(counter >= MAX_COUNT)
                      {
		           fprintf(stderr, "ERROR: TroutModelSwarm >>>> stock >>>> Failed to put fish at nonzero depth cell after %d attempts\n",counter);
                           fflush(0);
                           exit(1);
                      }
                }
          }
   }


   [listNdx drop];

   [randCellDist drop];
   [lengthNormalDist drop];

   //
   // Now, get the next trout stocking time
   //
   {

       time_t smallestNextFishStockTime = runEndTime;

       for(i = 0;i < arraySize; i++)
       {

           if(nextTimeArray[i] <= nextFishStockTime) continue;

           smallestNextFishStockTime = (smallestNextFishStockTime < nextTimeArray[i]) ?
                                        smallestNextFishStockTime : nextTimeArray[i];

 
       }

       nextFishStockTime = smallestNextFishStockTime;

   }
           
   //fprintf(stdout, "TroutModelSwarm >>>> stock >>>> END\n");
   //fflush(0);

   return self;
}



//////////////////////////////////////////////////////////////
//
// readPopFiles
//
// Comment: this reads the files with initial populations:
//          number, size of fish
/////////////////////////////////////////////////////////////
- readPopFiles
{
  FILE * fptr=NULL;

  SpeciesSetup* speciesSetup = (SpeciesSetup *) nil;

  id <ListIndex> lstNdx = [speciesSetupList listBegin: scratchZone];

  fprintf(stdout, "UTMTroutModelSwarm >>>> readPopFiles >>>> BEGIN\n");
  fflush(0);


  initialFishRecordList = [List create: modelZone];

  while(([lstNdx getLoc] != End) && ((speciesSetup = (SpeciesSetup *) [lstNdx next]) != (SpeciesSetup *) nil))
  {
     char inputString[300];
     InitialFishRecord* initialFishRecord = NULL;

     if((fptr = fopen(speciesSetup->initPopFile, "r")) == NULL)
     {
         fprintf(stderr, "ERROR: TroutModelSwarm >>>> readPopFiles >>>> unable to open initialization file %s\n", speciesSetup->initPopFile);
         fflush(0);
         exit(1);
     }
     
     fgets(inputString, 300, fptr);
     fgets(inputString, 300, fptr);
     fgets(inputString, 300, fptr);
     
     while(fgets(inputString, 300, fptr) != NULL)
     {
          char initDate[12];
          int age; 
          int numberOfFish;
          double meanLength;
          double stdDevLength; 

         initialFishRecord = (InitialFishRecord *) [ZoneAllocMapper allocBlockIn: modelZone
                                                                          ofSize: sizeof(InitialFishRecord)];

         sscanf(inputString, "%s%d%d%lf%lf", initDate,
                                           &age, 
                                           &numberOfFish,
                                           &meanLength,
                                           &stdDevLength); 
      

         initialFishRecord->speciesSymbol = speciesSetup->speciesSymbol;
         initialFishRecord->speciesIndex = speciesSetup->speciesIndex;

         initialFishRecord->fishParams = speciesSetup->fishParams;

         strncpy(initialFishRecord->initDate, initDate, 12);
         
         initialFishRecord->initTime = [timeManager getTimeTWithDate: initDate];
         initialFishRecord->age = age;
         initialFishRecord->numberOfFish = numberOfFish;
         initialFishRecord->meanLength = meanLength;
         initialFishRecord->stdDevLength = stdDevLength;
         initialFishRecord->troutClass = speciesSetup->troutClass;

         [initialFishRecordList addLast: (void *) initialFishRecord];
     }
  
  }

  [lstNdx drop];

  fprintf(stdout, "UTMTroutModelSwarm >>>> readPopFiles >>>> END\n");
  fflush(0);

  return self;

}  // readPopFiles




//////////////////////////////////////////////////////////////////////
//
// buildActions
//
///////////////////////////////////////////////////////////////////////
- buildActions 
{
  [super buildActions];


  //fprintf(stderr,"MODEL SWARM >>>> buildActions begin\n");
  //fflush(0);

  //
  // There is now only one "Action", step, which does all of the real work.
  //

  modelActions = [ActionGroup createBegin: modelZone];
  //[modelActions setDefaultOrder: Sequential];
  modelActions = [modelActions createEnd];
  [modelActions createActionTo: self message: M(step)];


  modelSchedule = [Schedule createBegin: modelZone];
  [modelSchedule setRepeatInterval: 1];
  modelSchedule = [modelSchedule createEnd];

 [modelSchedule at: 0 createAction: modelActions];

  //fprintf(stderr,"MODEL SWARM >>>> buildActions returning\n");
  //fflush(0);


  return self;

}  // buildActions


///////////////////////////////////
//
// updateTkEvents
//
///////////////////////////////////
- updateTkEventsFor: aReach
{
    //
    // Passes message to the observer
    // which in turn passes the message
    // to the experSwarm.
    //
    [observerSwarm updateTkEventsFor: aReach];
    return self;
}

//////////////////////////////////////////////////////
//
// activateIn
//
/////////////////////////////////////////////////////
- activateIn: swarmContext {
  [super activateIn: swarmContext];
  [modelSchedule activateIn: self];

  return [self getActivity];
}


//////////////////////////////////////////
//
// step
//
//////////////////////////////////////////
- step
{
  time_t timeTillDaytimeStarts = (time_t) 0;
  time_t anHour = (time_t) 3600; 

  BOOL moveFish = NO;
  id aHabitatSpace;

  fprintf(stdout,"UTMTroutModelSwarm >>>> step >>>> BEGIN\n");
  fflush(0);

  //
  // First, advance the model clock by one hour
  // if isFirstStep is FALSE 
  //
  if(isFirstStep == TRUE)
  {
      numHoursSinceLastStep = 0;
  }
  else
  { 
     modelTime = [timeManager stepTimeWithControllerObject: self];
     strcpy(modelDate, [timeManager getDateWithTimeT: modelTime]);
     numHoursSinceLastStep++;
  }


  //
  // Second, check to see if the fish should move. This habitat method
  // also updates model variables for whether it is daytime or night,
  // updates hourly flow, and updates daily habitat variables if the
  // current time is midnight.
  //
  id <ListIndex> lstNdx = nil;
  lstNdx = [reachList listBegin: scratchZone];

  while(([lstNdx getLoc] != End) && ((aHabitatSpace = (HabitatSpace *) [lstNdx next]) != (HabitatSpace *) nil)){
    moveFish = [aHabitatSpace shouldFishMoveAt: modelTime];
    fprintf(stdout,"UTMTroutModelSwarm >>>> step >>>> shouldFishMove? %s \n",(moveFish ? "YES" : "NO") );
    fflush(0);
  }

  //
  // Third, if it is midnight, call the method the updates
  // fish variables: age, time till next spawning period.
  //
  if([timeManager getHourWithTimeT: modelTime] == 0)
  {
      [self updateFish];      //increments fish age if date is 1/1
      [self updateReproFuncs];
  }

  
  //
  // Fourth, simulate stocking of hatchery fish, if it is time.
  //
  if(nextFishStockTime <= modelTime)
  {
      [self stock];
  }

  //
  // Fifth, determine if it is the first hour of daytime,
  // if so, conduct trout spawning and and redd actions.
  //
  timeTillDaytimeStarts  = modelTime - [timeManager getTimeTWithDate: [timeManager getDateWithTimeT: modelTime]
						    withHour: (int) [SolarManager getSunriseHour]
						    withMinute: (int)  [SolarManager getSunriseHour]*60
						    withSecond: 0];

  if((timeTillDaytimeStarts  >= (time_t) 0) && (timeTillDaytimeStarts < anHour))
  {
      [liveFish forEach: M(spawn)];

      [reddList forEach: M(survive)];
      [reddList forEach: M(develop)];
      [reddList forEach: M(emerge)];
      [self processEmptyReddList];

      #ifdef REDD_SURV_REPORT
      //
      // Added 19Feb2008
      //
      [self printReddSurvReport]; 
      #endif
  }


  //
  // Sixth, on hours when fish movement occurs (because of a flow change or a switch
  // between daytime and night), the model simulates (1) growth and mortality
  // in the period since the previous movement, (2) updates the habitat to 
  // current conditions, and (3) simulates movment.
  //
  // Mortality and population status output files are written before the
  // habitat update; habitat selection output is written after movement.
  //

  if(moveFish == YES) 
  {
     if(isFirstStep == FALSE)
     {
        [liveFish forEach: M(updateNumHoursSinceLastStep:) : (void *) &numHoursSinceLastStep];
        [liveFish forEach: M(die)];
        [liveFish forEach: M(grow)];
     }

     //
     // These lists must be processed before
     // the fish moves
     //

     [self updateCauseOfDeath];

     [self removeKilledFishFromLiveFishList];

     //
     // sort total population by dominance
     //
     [QSort sortObjectsIn:  liveFish];
     [QSort reverseOrderOf: liveFish];


     //[self printFishPopSummaryFile];

     //
     // Breakout report update
     //
     if(isFirstStep == FALSE)
     {
        [self outputBreakoutReport];
	// Comment the following for now, breakout reporting will need to be fixed later --colin
        //[habitatSpace printCellFishInfo];
     }

     // 
     // The following update method uses
     // the flow obtained in shouldFishMoveAt:
     //
     [habitatManager updateHabitatManagerWithTime: modelTime
                         andWithModelStartFlag: initialDay];

     [self toggleFishForHabSurvUpdate];
     [liveFish forEach: M(move)];

     //[self printTroutDepthUseHisto];
     //[self printTroutVelocityUseHisto];

     //[habitatSpace printAreaDepthHisto];
     //[habitatSpace printAreaVelocityHisto];

     //
     // Finally, re-set the number of hours 
     // since last step.
     //
     numHoursSinceLastStep = 0;


  }    

  if(isFirstStep == TRUE)
  {
      isFirstStep = FALSE;
  }

  fprintf(stdout,"ModelSwarm >>>> step >>>> scenario     = %d\n", scenario);
  fprintf(stdout,"ModelSwarm >>>> step >>>> replicate    = %d\n", replicate);
  fprintf(stdout,"ModelSwarm >>>> step >>>> date         = %s\n", [timeManager getDateWithTimeT: modelTime]);
  fprintf(stdout,"ModelSwarm >>>> step >>>> hour         = %d\n", [timeManager getHourWithTimeT: modelTime]);
  fprintf(stdout,"ModelSwarm >>>> step >>>> numberOfFish = %d\n\n", [liveFish getCount]);
  //[self     printZone: modelZone 
       //withPrintLevel: 1];

  //fprintf(stdout,"ModelSwarm >>>> step >>>> checkParam = %f\n\n", checkParam);

  fprintf(stdout,"UTMTroutModelSwarm >>>> step >>>> END\n");
  fflush(0);

  return self;

}

///////////////////////////////////////
//
// printZone
//
///////////////////////////////////////
-           printZone:(id <Zone>) aZone 
       withPrintLevel: (int) level
{
   id <List> zonePopList = [aZone getPopulation];
   id <ListIndex> ndx = [zonePopList listBegin: scratchZone];
   id obj = nil;
   int printLevel = level;
 
   fprintf(stdout,"UTMTroutModelSwarm >>>> printZones >>>> BEGIN >>>> aZone = %p level = %d\n", aZone, level);
   fflush(0);
   //xprint(aZone);

  while(([ndx getLoc] != End) && ((obj = [ndx next]) != nil))
   {
          Class aClass = Nil;
          Class ZoneClass = objc_get_class("Zone_c");
          char aClassName[20];
          char ZoneClassName[20];

          aClass = object_get_class(obj);

          strncpy(aClassName, class_get_class_name(aClass), 20);   
          strncpy(ZoneClassName, class_get_class_name(ZoneClass), 20);   

          fprintf(stdout,"UTMTroutModelSwarm >>>> printZones >>>> while >>>> obj = %p level = %d\n", obj, level);
          fprintf(stdout,"UTMTroutModelSwarm >>>> printZones >>>> while >>>> aClassName = %s level = %d\n", aClassName, level);
          fflush(0);

	  //xprint(obj);

          if(strncmp(aClassName, "ZoneAllocMapper", 16) == 0)
          {
                //xprint(obj);
                //[obj drop];
                continue;
          }

          if(strncmp(aClassName, ZoneClassName, 20) == 0)
          {
               [self printZone: obj withPrintLevel: ++printLevel];
          } 
    }

   fprintf(stdout,"UTMTroutModelSwarm >>>> printZones >>>> END >>>> aZone = %p level = %d\n", aZone, level);
   fflush(0);

   [ndx drop];

   return self;
}


///////////////////////////////////////
//
// toggleFishForHabSurvUpdate
//
/////////////////////////////////////
- toggleFishForHabSurvUpdate
{
    id <ListIndex> ndx = nil;
    id fish = nil;
    id prevFish = nil;
    BOOL fishGTEMinPiscLength = NO;
    BOOL fishLTMinPiscLength = NO;
    
     
    //fprintf(stdout, "UTMTroutModelsSwarm >>>> toggleFishForHabSurvUpdate >>>> BEGIN\n");
    //fflush(0);

    // The variable toggleFishForHabSurvUpdate is set each day by the model swarm
    // method toggleFishForHabSurvUpdate, part of the updateActions.
    // It is set to yes if this fish is either (a) the smallest
    // piscivorous fish or (b) the last fish. The aquatic predation
    // survival probability needs to be updated when this fish moves. 

    if([liveFish getCount] > 0)
    {
        if((fish = [liveFish getFirst]) != nil)
        {
            if([fish getFishLength] >= minSpeciesMinPiscLength) 
            {
                fishGTEMinPiscLength = YES; 
            }
        }
        if((fish = [liveFish getLast]) != nil)
        {
            if([fish getFishLength] < minSpeciesMinPiscLength) 
            {
                fishLTMinPiscLength = YES; 
            }
        }
    
        if((fishGTEMinPiscLength == YES) && (fishLTMinPiscLength == YES))
        { 
            ndx = [liveFish listBegin: scratchZone];
            while(([ndx getLoc] != End) && ((fish = [ndx next]) != nil))
            {
                if([fish getFishLength] < minSpeciesMinPiscLength) 
                {
                    [prevFish toggleFishForHabSurvUpdate];
                    break;
                }
                prevFish = fish;
            }
            [ndx drop];
        }
        else
        {
            //
            // Let the last fish regardless of length update the 
            // habitat aq pred survival probs -- needed in die
            //
    
            if((fish = [liveFish getLast]) != nil)
            {
               [fish toggleFishForHabSurvUpdate];
            }
        }
   }

   //fprintf(stdout, "UTMTroutModelsSwarm >>>> toggleFishForHabSurvUpdate >>>> END\n");
   //fflush(0);
    
   return self;
}



/////////////////////////////////////////////////////////
//
// addAFish
//
////////////////////////////////////////////////////////////
- addAFish: (UTMTrout *) aTrout 
{
  numFish++;
  [liveFish addLast: aTrout];
  return self;
}


////////////////////////////////////////////////////////////////
//
// getLiveFishList
//
////////////////////////////////////////////////////////////////
- (id <List>) getLiveFishList 
{
  return liveFish;
}


///////////////////////////////////////
//
// addToKilledList
//
///////////////////////////////////////
- addToKilledList: (UTMTrout *) aFish 
{
  [deadFish addLast: aFish];
  [killedFish addLast: aFish];


  return self;
}



////////////////////////////////////////////////////////////
//
// getDeadTroutList
//
////////////////////////////////////////////////////////////
- (id <List>) getDeadTroutList 
{
    return deadFish;
}

///////////////////////////////////
//
// removeKilledFishFromLiveFishList
//
//////////////////////////////////
- removeKilledFishFromLiveFishList
{
   id <ListIndex> ndx = [killedFish listBegin: scratchZone];
   id aFish = nil;

   [ndx setLoc: Start];

   while(([ndx getLoc] != End) && ((aFish = [ndx next]) != nil))
   {
      [liveFish remove: aFish];
   }

   [ndx drop];

   [killedFish removeAll];

   return self;

}


//////////////////////////////////////
//
// addRedd
//
/////////////////////////////////////
- addRedd: (UTMRedd *) aRedd
{
    [reddList addLast: aRedd];   //or should this be add first?

    #ifdef REDD_REPORT
       [aRedd setPrintSummaryFlagToYes]; 
       [aRedd createPrintList];
    #endif

    #ifdef REDD_SURV_REPORT
       [aRedd setPrintMortalityFlagToYes];
       [aRedd createSurvPrintList];
    #endif

    return self;
}

/////////////////////////////////////
//
// getReddList
//
////////////////////////////////////
- (id <List>) getReddList 
{
    return reddList;
}

- (id <List>) getReddRemovedList 
{
  return removedRedds;
}


- addToEmptyReddList: aRedd 
{
  [emptyReddList addLast: aRedd];
  return self;
}

//////////////////////////////////////////////////////////
//
// whenToStop
//
// This is where any methods called at the end of 
// the model run are performed
//
//  Called from the observer swarm 
//
////////////////////////////////////////////////////////
- (BOOL) whenToStop 
{ 
  BOOL STOP;

  if(modelTime >= runEndTime) 
  {
     STOP = YES;
     [self dropFishMortObjs];

     #ifdef REDD_REPORT
        [self printReddReport];
     #endif

     #ifdef REDD_SURV_REPORT
        //
        // This is broken wrt the changes in 
        // the survival manager
        //
        [self printReddSurvReport];
     #endif

     //fprintf(stdout,"UTMTroutModelSwarm >>>> stop >>>>\n");
     //fflush(stdout);

  }
  else
  {
     STOP = NO;
  }

  return STOP;
}



///////////////////////////////////////////////////////
//
// updateFish
//
// We assume that all fish increment their age on Jan 1
//
//////////////////////////////////////////////////////
- updateFish 
{
  BOOL birthday;

  birthday = [timeManager isThisTime: modelTime onThisDay: "1/1"];
 
  [liveFish forEach: M(dailyUpdateWithBirthday:) : (void *) &birthday];  

  return self;

}


- (id <Symbol>) getAgeSymbolForAge: (int) anAge
{

  if(anAge == 0)
  {
    return Age0;
  }
  else if (anAge == 1) 
  {
      return Age1;
  }
  else if (anAge == 2)
  {
     return Age2;
  }
  else if (anAge > 2)
  {
     return Age3Plus;
  }
  else
  {
     [InternalError raiseEvent: "ERROR: UTMTroutModelSwarm >>>> getAgeSymbolForAge >>>> incorrect age %d\n", anAge];
  }

  return (id <Symbol>) self;

}



//////////////////////////////////////////////////////////
//
// getFishMortalitySymbolWithName
//
//////////////////////////////////////////////////////////
- (id <Symbol>) getFishMortalitySymbolWithName: (char *) aName
{

    id <ListIndex> lstNdx;
    id aSymbol = nil;
    id mortSymbol = nil;
    char* symbolName = NULL;

    lstNdx = [fishMortSymbolList listBegin: scratchZone]; 

    while(([lstNdx getLoc] != End) && ((aSymbol = [lstNdx next]) != nil))
    {
        symbolName = (char *) [aSymbol getName];
        
        //if(strncmp(aName, [aSymbol getName], strlen(aName)) == 0) 
        if(strncmp(aName, symbolName, strlen(aName)) == 0) 
        {
           mortSymbol = aSymbol;
           break;
        }

        if(symbolName != NULL)
        {
            [scratchZone free: symbolName];
            symbolName = NULL;
        }

    }
  
    [lstNdx drop];

    if(symbolName != NULL)
    {
        [scratchZone free: symbolName];
        symbolName = NULL;
    }
   

    if(mortSymbol == nil)
    {
        mortSymbol = [Symbol create: modelZone setName: aName];
        [fishMortSymbolList addLast: mortSymbol];
    }

    return mortSymbol;
}


//////////////////////////////////////////////////////////
//
// getReddMortalitySymbolWithName
//
//////////////////////////////////////////////////////////
- (id <Symbol>) getReddMortalitySymbolWithName: (char *) aName
{

    id <ListIndex> lstNdx;
    id aSymbol = nil;
    id mortSymbol = nil;
    char* symbolName = NULL;

    lstNdx = [reddMortSymbolList listBegin: scratchZone]; 

    while(([lstNdx getLoc] != End) && ((aSymbol = [lstNdx next]) != nil))
    {
        symbolName = (char *) [aSymbol getName];
        
        //if(strncmp(aName, [aSymbol getName], strlen(aName)) == 0) 
        if(strncmp(aName, symbolName, strlen(aName)) == 0) 
        {
           mortSymbol = aSymbol;
           break;
        }
     
        if(symbolName != NULL)
        {
            [scratchZone free: symbolName];
            symbolName = NULL;
        }
    }
  
    [lstNdx drop];

    if(symbolName != NULL)
    {
        [scratchZone free: symbolName];
        symbolName = NULL;
    }

    if(mortSymbol == nil)
    {
        mortSymbol = [Symbol create: modelZone setName: aName];
        [reddMortSymbolList addLast: mortSymbol];
    }

    return mortSymbol;
}

////////////////////////////////////////////
//
// getReachSymbolWithName
//
////////////////////////////////////////////
- (id <Symbol>) getReachSymbolWithName: (char *) aName
{
    id <ListIndex> lstNdx;
    id aSymbol = nil;
    id reachSymbol = nil;
    char* reachName = NULL;

    fprintf(stdout, "TroutModelSwarm >>>> getReachSymbolWithName >>>> BEGIN\n");
    fflush(0);

    lstNdx = [reachSymbolList listBegin: scratchZone]; 

    while(([lstNdx getLoc] != End) && ((aSymbol = [lstNdx next]) != nil))
    {
        reachName = (char *) [aSymbol getName];
        if(strncmp(aName, reachName, strlen(aName)) == 0) 
        {
           reachSymbol = aSymbol;
           [scratchZone free: reachName];
           reachName = NULL;
           break;
        }

        if(reachName != NULL) 
        {
           [scratchZone free: reachName];
           reachName = NULL;
        }
    }
  
    [lstNdx drop];

    if(reachSymbol == nil)
    {
        reachSymbol = [Symbol create: modelZone setName: aName];
        [reachSymbolList addLast: reachSymbol];
    }


    fprintf(stdout, "TroutModelSwarm >>>> getReachSymbolWithName >>>> END\n");
    fflush(0);


    return reachSymbol;

}




////////////////////////////////////
//
// updateHabSurvProbs
//
////////////////////////////////////
- updateHabSurvProbs
{
   [reachList forEach: M(updateHabSurvProbForAqPred)];
   return self;
}

//////////////////////////////////////////////////////
//
// createNewFishWithSpeciesIndex
//
/////////////////////////////////////////////////////
- (UTMTrout *) createNewFishWithSpeciesIndex: (int) speciesNdx  
                                  Species: (id <Symbol>) species
                                      Age: (int) age
                                   Length: (double) fishLength 
{

  id newFish;
  id <Symbol> ageSymbol = nil;
  id <InterpolationTable> aCMaxInterpolator = nil;
  id <InterpolationTable> aSpawnDepthInterpolator = nil;
  id <InterpolationTable> aSpawnVelocityInterpolator = nil;
  LogisticFunc* aCaptureLogistic = nil;

  //fprintf(stdout, "TroutModelSwarm >>>> createNewFishWithSpeciesIndex >>>> BEGIN\n");
  //fflush(0);

  //
  // The newFish color is currently being set in the observer swarm
  //

  newFish = [MyTroutClass[speciesNdx] createBegin: modelZone];

  [newFish setFishParams: [fishParamsMap at: species]];

  //
  // set properties of the new Trout
  //

  ((UTMTrout *)newFish)->sex = ([coinFlip getCoinToss] == YES ?  Female : Male);

  //((UTMTrout *)newFish)->randGen = randGen;

  ((UTMTrout *)newFish)->rasterResolutionX = polyRasterResolutionX;
  ((UTMTrout *)newFish)->rasterResolutionY = polyRasterResolutionY;

  [newFish setSpecies: species];
  [newFish setSpeciesNdx: speciesNdx];
  [newFish setAge: age];

  ageSymbol = [self getAgeSymbolForAge: age];
   
  [newFish setAgeSymbol: ageSymbol];

  [newFish setFishLength: fishLength];
  [newFish setFishCondition: 1.0];
  [newFish setFishWeightFromLength: fishLength andCondition: 1.0]; 
  [newFish setTimeTLastSpawned: 0];    //Dec 31 1969

  [newFish calcStarvPaAndPb];

  if(fishColorMap != nil)
  {
     [newFish setFishColor: (Color) *((long *) [fishColorMap at: [newFish getSpecies]])];
  }

  [newFish setTimeManager: timeManager];
  [newFish setModel: (id <UTMTroutModelSwarm>) self];

  aCMaxInterpolator = [cmaxInterpolatorMap at: species];
  aSpawnDepthInterpolator = [spawnDepthInterpolatorMap at: species];
  aSpawnVelocityInterpolator = [spawnVelocityInterpolatorMap at: species];
  aCaptureLogistic = [captureLogisticMap at: species];
  
  [newFish setCMaxInterpolator: aCMaxInterpolator];
  [newFish setSpawnDepthInterpolator: aSpawnDepthInterpolator];
  [newFish setSpawnVelocityInterpolator: aSpawnVelocityInterpolator];
  [newFish setCaptureLogistic: aCaptureLogistic];

  fishCounter++;  // Give each fish a serial number ID
  [newFish setFishID: fishCounter];

  newFish = [newFish createEnd];

  //fprintf(stdout, "TroutModelSwarm >>>> createNewFishWithSpeciesIndex >>>> END\n");
  //fflush(0);
        
  return newFish;
}

//////////////////////////////////////////
//
// processEmptyReddList
//
///////////////////////////////////////////
- processEmptyReddList 
{
  id <ListIndex> emptyReddNdx = nil;
  id nextRedd;

  emptyReddNdx = [emptyReddList listBegin: scratchZone];
  while(([emptyReddNdx getLoc] != End) && ((nextRedd = [emptyReddNdx next]) != nil)) 
  {
     [reddList remove: nextRedd];
     [removedRedds addLast: nextRedd];
  }

  [emptyReddNdx drop];
  [emptyReddList removeAll];

  return self;
}


////////////////////////////////////////////////
//
// createGraphSeq
//
////////////////////////////////////////////////
- createGraphSeq: (id <Symbol>) causeOfDeath 
{
  id graphObj=nil;

  if(mortalityGraph != nil)
  {  
      graphObj = [GraphDataObject createBegin: modelZone];
      graphObj = [graphObj createEnd];

      [graphObj setDataSource: [deathMap at: causeOfDeath]] ;

      [mortalityGraph createSequence: [causeOfDeath getName]  
                        withFeedFrom: graphObj
                         andSelector: @selector(getData)];
                       //andSelector: @selector(getCount)];
                       //andSelector: @selector(getCumSum)];
  }

  return self;
}



////////////////////////////////////////////////////////////////
//
// updateCauseOfDeath
//
//////////////////////////////////////////////////////////////
- updateCauseOfDeath 
{
    id <ListIndex> deadFishNdx=nil;
    id nextDeadFish = nil;
    id causeOfDeath = nil;

    //fprintf(stdout, "TroutModelSwarm >>>> updateCauseOfDeath >>>> BEGIN\n");
    //fflush(0);

    if([killedFish getCount] > 0)
    {
       numberDead +=  [killedFish getCount];

       deadFishNdx = [killedFish listBegin: scratchZone];

       while(([deadFishNdx getLoc] != End) && ((nextDeadFish = [deadFishNdx next]) != nil)) 
       {
           causeOfDeath = [nextDeadFish getCauseOfDeath];

           if(![deathMap containsKey: causeOfDeath])
           {
               int* aDeathCount = (int *)[modelZone alloc: sizeof(int)];
               *aDeathCount = 0;
               [deathMap at: causeOfDeath insert: (void *) aDeathCount];
               [self createGraphSeq: (id <Symbol>) causeOfDeath];
   
           }


           (*((int *) [deathMap at: causeOfDeath]))++;

               /*
               
               {   //For debugging
                   id <MapIndex> mapNdx = nil;
                   id <Symbol> mapKey = nil;
                   int* aDeathCount = (int *) nil;
   
                   mapNdx = [deathMap mapBegin: scratchZone];
                    
                   [mapNdx setLoc: Start];
   
                   while(([mapNdx getLoc] != End) && ((aDeathCount = (int *) [mapNdx next]) != (int *) nil))
                   {

                       mapKey = (id <Symbol>) [mapNdx getKey];
                       if((id <Symbol>) causeOfDeath == (id <Symbol>) mapKey)
                       {
                           //fprintf(stdout, "MODELSWARM >>>>> deathCount\n");
                           //fprintf(stdout, "MODELSWARM >>>>> deathCount\n");
                           //fprintf(stdout, "MODELSWARM >>>>> deathCount causeOfDeath = %s\n", [causeOfDeath getName]) ;
                           //fprintf(stdout, "MODELSWARM >>>>> deathCount mapKey       = %s\n", [mapKey getName]);
                           //fprintf(stdout, "MODELSWARM >>>>> deathCount aDeathCount  = %d\n", *aDeathCount);
                           //fprintf(stdout, "MODELSWARM >>>>> deathCount deathMap at: = %d\n", *((int *) [deathMap at: causeOfDeath]));
                           //fprintf(stdout, "MODELSWARM >>>>> deathCount\n");
                           //fprintf(stdout, "MODELSWARM >>>>> deathCount\n");
                           //fflush(0);
                       }

                   }
                  
                   [mapNdx drop];
               }
               */
          }

          [deadFishNdx drop];

    } //if

    //fprintf(stdout, "TroutModelSwarm >>>> updateCauseOfDeath >>>> END\n");
    //fflush(0);

    return self;
}


///////////////////////////////////
//
// getNumberDead
//
///////////////////////////////////
- (int) getNumberDead 
{
   return numberDead;
}


//////////////////////////////////////////////////////
//
// createNewFishWithFishParams
//
/////////////////////////////////////////////////////
- (UTMTrout *) createNewFishWithFishParams: (FishParams *) aFishParams  
                         withTroutClass: (Class) aTroutClass
                                    Age: (int) age
                                 Length: (float) fishLength 
{
 
   //
   // The newFish color is currently being set in the observer swarm
   //
   UTMTrout* newFish = (UTMTrout *) nil;

   //fprintf(stdout, "UTMTroutModelSwarm >>>> createNewFishWithFishParams... >>>> BEGIN\n");
   //fflush(0);
   

   newFish = [aTroutClass createBegin: modelZone];

   // set properties of the new Trout

  ((UTMTrout *)newFish)->sex = ([coinFlip getCoinToss] == YES ?  Female : Male);


  ((UTMTrout *)newFish)->rasterResolution  = utmRasterResolution;
  ((UTMTrout *)newFish)->rasterResolutionX = utmRasterResolutionX;
  ((UTMTrout *)newFish)->rasterResolutionY = utmRasterResolutionY;

  [newFish setFishParams: aFishParams];
  [newFish setModel: self];
  [newFish setRandGen: randGen];
  [newFish setScenario: scenario];
  [newFish setReplicate: replicate];
  [newFish setTimeManager: timeManager];
  [newFish setHabitatManager: habitatManager];

  if([aFishParams getFishSpecies] == nil)
  {
     fprintf(stderr, "UTMTroutModelSwarm >>>> createNewFishWithFishParams >>>> species is nil\n");
     fflush(0);
     exit(1);
  }

  [newFish setSpecies: [aFishParams getFishSpecies]];
  [newFish setSpeciesNdx: [aFishParams getFishSpeciesIndex]];

  //
  // Used in the breakout reporters
  //
  [newFish  setFishActivitySymbolsWith: Hide
                                  with: Feed];

 
  //
  // Set ages and age symbols
  //
  [newFish setAge: age];
  if(age == 0)
  {
      [newFish setAgeSymbol: Age0];
  }
  else if(age == 1)
  {
     [newFish setAgeSymbol: Age1];
  }
  else if(age == 2)
  {
      [newFish setAgeSymbol: Age2];
  }
  else if(age > 2)
  {
      [newFish setAgeSymbol: Age3Plus];
  }
  else
  {
      fprintf(stderr, "ERROR: UTMTroutModelSwarm >>>> createNewFishWith >>>> improper fish age\n");
      fflush(0);
      exit(1);
  }



  [newFish setFishLength: fishLength];
  [newFish setFishCondition: 1.0];
  [newFish setFishWeightFromLength: fishLength andCondition: 1.0]; 
  [newFish setFishDominance];


  //
  // Set time last spawned to modelTime - 5 years
  //
  [newFish setTimeTLastSpawned: (modelTime - (time_t) 157600000)];    

  [newFish updateMaxSwimSpeed];

  [newFish calcMaxMoveDistance];

  [newFish updateNumHoursSinceLastStep: (void *) &numHoursSinceLastStep];

  
  if(fishColorMap != nil)
  {
      [newFish setFishColor: *((int *) [fishColorMap at: [newFish getSpecies]])];
  }
 

  [newFish calcStarvPaAndPb];


  newFish = [newFish createEnd];
        
  return newFish;
}


- readSpeciesSetupFile
{
  FILE * speciesFP=NULL;
  const char *speciesFile="Species.Setup";
  char headerLine[300];

  int checkNumSpecies = 0;

  int speciesIDX= 0;

  if(numberOfSpecies > 10)
  {
    fprintf(stderr,"ERROR: UTMTroutModelSwarm >>>> readSpeciesSetupFile >>>> Too many species\n");
    fflush(0);
    exit(1);
  }

  if((speciesFP = fopen(speciesFile, "r")) == NULL ) 
  {
    fprintf(stderr,"ERROR: UTMTroutModelSwarm >>>> readSpeciesSetupFile >>>>  unable to open %s\n", speciesFile);
    fflush(0);
    exit(1);
  }
  speciesName  = (char **) [modelZone alloc: numberOfSpecies*sizeof(char *)];
  speciesParameter  = (char **) [modelZone alloc: numberOfSpecies*sizeof(char *)];
  speciesPopFile = (char **) [modelZone alloc: numberOfSpecies*sizeof(char *)];
  speciesColor = (char **) [modelZone alloc: numberOfSpecies*sizeof(char *)];
  speciesStocking = (char **) [modelZone alloc: numberOfSpecies*sizeof(char *)];
  

  speciesSetupList = [List create: modelZone];

  fgets(headerLine,300,speciesFP);  
  fgets(headerLine,300,speciesFP);  
  fgets(headerLine,300,speciesFP);  

  for(speciesIDX=0;speciesIDX<numberOfSpecies;speciesIDX++) {
      speciesName[speciesIDX] = (char *) [modelZone alloc: 200*sizeof(char)];
      speciesParameter[speciesIDX] = (char *) [modelZone alloc: 200*sizeof(char)];
      speciesPopFile[speciesIDX] = (char *) [modelZone alloc: 200*sizeof(char)];
      speciesColor[speciesIDX] = (char *) [modelZone alloc: 200*sizeof(char)];
      speciesStocking[speciesIDX] = (char *) [modelZone alloc: 200*sizeof(char)];

      if(fscanf(speciesFP,"%s%s%s%s%s",speciesName[speciesIDX],
                              speciesParameter[speciesIDX],
                              speciesPopFile[speciesIDX],
                              speciesColor[speciesIDX],
			      speciesStocking[speciesIDX]) != EOF){
         fprintf(stdout, "TroutModelSwarm >>>> readSpeciesSetup >>>> Myfiles are: %s %s %s %s \n", speciesName[speciesIDX],speciesParameter[speciesIDX], speciesPopFile[speciesIDX],speciesStocking[speciesIDX]);
         fflush(0);

         SpeciesSetup* speciesSetup = (SpeciesSetup *) [ZoneAllocMapper allocBlockIn: modelZone
                                                                              ofSize: sizeof(SpeciesSetup)];
         speciesSetup->speciesSymbol = [Symbol create: modelZone
                                              setName: speciesName[speciesIDX]];
         speciesSetup->speciesIndex = speciesIDX;
         strncpy(speciesSetup->fishParamFile, speciesParameter[speciesIDX], 50);
         strncpy(speciesSetup->initPopFile, speciesPopFile[speciesIDX], 50);
         strncpy(speciesSetup->fishColor, speciesColor[speciesIDX], 25);
         strncpy(speciesSetup->stocking, speciesStocking[speciesIDX], 50);
         speciesSetup->troutClass = [objc_get_class(speciesName[speciesIDX]) class];

         [speciesSetupList addLast: (void *) speciesSetup];

         checkNumSpecies++;
      }
   }

   if((checkNumSpecies != numberOfSpecies) || (checkNumSpecies == 0))
   {
      fprintf(stderr, "ERROR: Please check the Species.Setup file and the Model.Setup file and\n ensure that the numberOfSpecies is consistent with the Species.Setup data\n");
      fflush(0);
      exit(1);
   
   } 

   fclose(speciesFP);

   return self;
}


- (id <List>) getSpeciesClassList 
{
  return speciesClassList;
}

- (int) getNumberOfSpecies 
{
  return numberOfSpecies;
}

#ifdef INIT_FISH_REPORT
- printInitialFishReport 
{
  FILE * fishReportPtr=NULL;  
  const char * fishReportFile = "InitialFishTest.rpt";
  id <ListIndex> fishNdx;
  id fish;

  if((fishReportPtr = fopen(fishReportFile,"w+")) == NULL)
  {
     fprintf(stderr, "ERROR: Cannot open %s for writing",fishReportFile);
     fflush(0);
     exit(1);
  }

  fprintf(fishReportPtr,"%-10s\n","Day 1:");
  fprintf(fishReportPtr,"%-10s%-10s%-10s%-13s\n","Species","Sex", "Age","Length");

  if([liveFish getCount] > 0)
  {
     fishNdx = [liveFish listBegin: scratchZone];

     while(([fishNdx getLoc] != End) && ((fish = [fishNdx next]) != nil)) 
     {
        [fish printInfo: fishReportPtr];
     }

     [fishNdx drop];
  }

  if(fishReportPtr != NULL) 
  {
    fclose(fishReportPtr);
    fishReportPtr = NULL;
  }

  return self;
}

#endif






#ifdef REDD_REPORT

/////////////////////////////////////////////////////////
//
// printReddReport
//
//////////////////////////////////////////////////////////
- printReddReport 
{
   FILE *printRptPtr=NULL;
   id <ListIndex> reddListNdx = nil;
   id redd = nil;

   if((printRptPtr = fopen(reddMortalityFile,"w")) == NULL) 
   {
      fprintf(stderr, "ERROR: UTMTroutModelSwarm >>>> printReddReport >>>> Couldn't open %s\n", reddMortalityFile);
      fflush(0);
      exit(1);
   }

   if([removedRedds getCount] > 0) 
   {
      reddListNdx = [removedRedds listBegin: scratchZone];

      while(([reddListNdx getLoc] != End) && ( (redd = [reddListNdx next]) != nil ) ) 
      {
         [redd printReport: printRptPtr];
      }

     [reddListNdx drop];
   }

   if(printRptPtr != NULL)
   {
      fclose(printRptPtr);
      printRptPtr = NULL;
   }

   return self;
}
#endif


#ifdef REDD_SURV_REPORT

//////////////////////////////////////////////////////////
//
// printReddSurvReport
//
/////////////////////////////////////////////////////////
- printReddSurvReport 
{
   FILE *printRptPtr = NULL;
   const char * reddSurvFile = "ReddSurvivalTest.rpt";
   id <ListIndex> reddListNdx = nil;
   id redd = nil;
 
   //fprintf(stdout, "UTMTroutModelSwarm >>>> printReddSurvReport >>>> BEGIN\n");
   //fflush(0);


    if((printRptPtr = fopen(reddSurvFile,"w+")) == NULL) 
    {
       fprintf(stderr, "ERROR: Couldn't open %s\n", reddSurvFile);
       fflush(0);
       exit(1);
    }

    if([removedRedds getCount] > 0) 
    {
       reddListNdx = [removedRedds listBegin: modelZone];

       while(([reddListNdx getLoc] != End) && ((redd = [reddListNdx next]) != nil)) 
       {
         [redd printReddSurvReport: printRptPtr];
       }

       [reddListNdx drop];
    }

    if(printRptPtr != NULL)
    {
       fclose(printRptPtr);
       printRptPtr = NULL;
    }

   //fprintf(stdout, "UTMTroutModelSwarm >>>> printReddSurvReport >>>> END\n");
   //fflush(0);

    return self;
}

#endif






////////////////////////////////////////////////////////////////////////////////////
//
// dropFishMortObjs
//
////////////////////////////////////////////////////////////////////////////////////
- dropFishMortObjs 
{
  if(fishMortalityPtr != NULL) 
  {
      fclose(fishMortalityPtr);
  }

  return self;
}

////////////////////////////////////
//
// getSpeciesSymbolList
//
////////////////////////////////////
- (id <List>) getSpeciesSymbolList
{
   return speciesSymbolList;
}
///////////////////////////////////
//
// getAgeSymbolList
//
///////////////////////////////////
- (id <List>) getAgeSymbolList
{
   return ageSymbolList;
}



//////////////////////////////////////////////////////////
//
////
//////           MODEL TIME_T METHODS
////////
//////////
////////////

/////////////////////////////////////////////////////////
//
// getModelTime
//
/////////////////////////////////////////////////////////
- (time_t) getModelTime 
{
   return modelTime;
}


///////////////////////////////////////////////////
//
// getModelDate
//
///////////////////////////////////////////////////
- (char *) getModelDate
{
    return modelDate;
} 


/////////////////////////////////////////////
//
// getModelHour
//
/////////////////////////////////////////////
- (int) getModelHour
{
    return [timeManager getHourWithTimeT: modelTime];
}


//////////////////////////////////////////////
//
// getNumHoursSinceLastStep
//
////////////////////////////////////////////
- (int) getNumHoursSinceLastStep
{
    return numHoursSinceLastStep;
}
   
////////////////////////////////////////////////////
//
// getModelZone 
//
///////////////////////////////////////////////////
- (id <Zone>) getModelZone 
{
    return modelZone;
}

- (BOOL) getAppendFiles {

  return appendFiles;

}

- (int) getScenario {

  return scenario;

}


- (int) getReplicate {

  return replicate;

}


/////////////////////////////////////////////////////////////////////
//
////           TROUT HISTOGRAMS
//////
////////
//////////
/////////////////////////////////////////////////////////////////////

- openTroutDepthUseFiles {
  id <ListIndex> ndx;
  id species=nil;
  char* depthUseFileName=NULL;
  char* speciesName=NULL;
  size_t fileNameLength=0;

  speciesDepthUseOutStreamMap = [Map create: modelZone];

  ndx = [speciesSymbolList listBegin: modelZone];

  while( ([ndx getLoc] != End) && (( species = [ndx next]) != nil) ) {
      FILE* depthUseFileStream=NULL;

      speciesName = (char *)[species getName];

      fileNameLength = strlen(speciesName) + strlen(fishDepthUseFileName) + 1;

      depthUseFileName = (char *) [modelZone alloc: fileNameLength*sizeof(char)];
      
      strncpy(depthUseFileName, speciesName, strlen(speciesName) + 1);
      strncat(depthUseFileName, "DepthUse.Out", strlen(fishDepthUseFileName) + 1);


      if(appendFiles == NO) {

          if((depthUseFileStream = fopen(depthUseFileName, "w")) == NULL) {
             [InternalError raiseEvent: "Error opening trout depth use file in TroutModelSwarm\n"];
          }

          [self printTroutUseHeaderToStream: depthUseFileStream
                                    withUse: "Depth"];
                            

      }
      else if( (appendFiles == YES) && (scenario == 1) && (replicate == 1) ) {

          if((depthUseFileStream = fopen(depthUseFileName, "w")) == NULL) {
             [InternalError raiseEvent: "Error opening trout depth use file in TroutModelSwarm\n"];
          }

          [self printTroutUseHeaderToStream: depthUseFileStream
                                    withUse: "Depth"];
      }
      else {

          if((depthUseFileStream = fopen(depthUseFileName, "a")) == NULL) {
             [InternalError raiseEvent: "Error opening trout depth use file in TroutModelSwarm\n"];
          }

      }


          [speciesDepthUseOutStreamMap at: species insert: (void *) depthUseFileStream];
          [modelZone free: depthUseFileName];

  }


  [ndx drop];

  return self;

}

//////////////////////////////////////////////////////////////
//
// openTroutVelocityFiles
//
/////////////////////////////////////////////////////////////
- openTroutVelocityUseFiles {

  id <ListIndex> ndx;
  id species=nil;
  char* velocityUseFileName=NULL;
  char* speciesName=NULL;
  size_t fileNameLength=0;

  speciesVelocityUseOutStreamMap = [Map create: modelZone];

  ndx = [speciesSymbolList listBegin: modelZone];

  while( ([ndx getLoc] != End) && (( species = [ndx next]) != nil) ) {
      FILE* velocityUseFileStream=NULL;

      speciesName = (char *)[species getName];

      fileNameLength = strlen(speciesName) + strlen(fishVelocityUseFileName) + 1;

      velocityUseFileName = (char *) [modelZone alloc: fileNameLength*sizeof(char)];
      
      strncpy(velocityUseFileName, speciesName, strlen(speciesName) + 1);
      strncat(velocityUseFileName, "VelocityUse.Out", strlen(fishVelocityUseFileName) + 1);


      if(appendFiles == NO) {

          if((velocityUseFileStream = fopen(velocityUseFileName, "w")) == NULL) {
             [InternalError raiseEvent: "Error opening trout velocity use file in TroutModelSwarm\n"];
          }

          [self printTroutUseHeaderToStream: velocityUseFileStream
                                    withUse: "Velocity"];
                            

      }
      else if( (appendFiles == YES) && (scenario == 1) && (replicate == 1) ) {

          if((velocityUseFileStream = fopen(velocityUseFileName, "w")) == NULL) {
             [InternalError raiseEvent: "Error opening trout velocity use file in TroutModelSwarm\n"];
          }

          [self printTroutUseHeaderToStream: velocityUseFileStream
                                    withUse: "Velocity"];
      }
      else {

          if((velocityUseFileStream = fopen(velocityUseFileName, "a")) == NULL) {
             [InternalError raiseEvent: "Error opening trout velocity use file in TroutModelSwarm\n"];
          }

      }

          [speciesVelocityUseOutStreamMap at: species insert: (void *) velocityUseFileStream];
          [modelZone free: velocityUseFileName];

  }


  [ndx drop];

  return self;

}


- printTroutUseHeaderToStream: (FILE *) aStream 
                      withUse: (char *) aUse {

  char* ageFmt=NULL;
  char* ageOut=NULL;

  int numAges=4;
  int j;
  int binWidth=0;
  int maxBinNumber=0;
  int i;  

  if(strcmp(aUse, "Depth") == 0) {
    binWidth = depthBinWidth;
    maxBinNumber = (unsigned) floor(depthHistoMaxDepth/depthBinWidth);

  fprintf(aStream, "%-14s%-10s%-11s","Date", "Scenario", "Replicate");
  fflush(0);

  for(j=0;j < numAges; j++) {
 
    switch (j) {

      case 0:  ageOut = "Age0Depth";
               ageFmt = "%-9s";
               break;

      case 1:  ageOut = "Age1Depth";
               ageFmt = "%-9s";
               break;

      case 2:  ageOut = "Age2Depth";
               ageFmt = "%-9s";
               break;

      default: ageOut = "Age3PlusDepth";
               ageFmt = "%-13s";
               break;
             
    } //switch


     for(i=0;i < maxBinNumber; i++) {
 
          fprintf(aStream,ageFmt,ageOut);
          fprintf(aStream,"%-5d",(i+1)*binWidth);
          fflush(0);

      } //for i

      fprintf(aStream,">");
      fprintf(aStream,ageFmt,ageOut);
      fprintf(aStream,"%-4d",maxBinNumber*binWidth);
      fflush(0);

  } //for j

  fprintf(aStream, "\n");
  fflush(0);

  }
  else if(strcmp(aUse, "Velocity") == 0) {
    binWidth = velocityBinWidth;
    maxBinNumber = (unsigned) floor(velocityHistoMaxVelocity/velocityBinWidth);

    fprintf(aStream, "%-14s%-10s%-11s","Date", "Scenario", "Replicate");
    fflush(0);

    for(j=0;j < numAges; j++) {
 
    switch (j) {

      case 0:  ageOut = "Age0Velocity";
               ageFmt = "%-12s";
               break;

      case 1:  ageOut = "Age1Velocity";
               ageFmt = "%-12s";
               break;

      case 2:  ageOut = "Age2Velocity";
               ageFmt = "%-12s";
               break;

      default: ageOut = "Age3PlusVelocity";
               ageFmt = "%-16s";
               break;
             
    } //switch


     for(i=0;i < maxBinNumber; i++) {
 
          fprintf(aStream,ageFmt,ageOut);
          fprintf(aStream,"%-5d",(i+1)*binWidth);
          fflush(0);

      } //for i

      fprintf(aStream,">");
      fprintf(aStream,ageFmt,ageOut);
      fprintf(aStream,"%-4d",maxBinNumber*binWidth);
      fflush(0);

  } //for j

  fprintf(aStream, "\n");
  fflush(0);
      



  }
  else 
  {
    fprintf(stderr,  "ERROR: UTMTroutModelSwarm >>>> can't print trout histogram usage header with %s \n", aUse);
    fflush(0);
    exit(1);
  }

  return self;

}


/*
/////////////////////////////////////////////////////////////////
//
// printTroutDepthUseUsage
//
/////////////////////////////////////////////////////////////////

- printTroutDepthUseHisto {
  id <ListIndex> ndx; 
  id <Symbol> species=nil;

  id <List> ageClassList;

  unsigned maxBinNumber = (unsigned) floor(depthHistoMaxDepth/depthBinWidth);
  int i;

  int age0DepthBinNumber;
  int age0DepthBin[maxBinNumber + 1];

  int age1DepthBinNumber;
  int age1DepthBin[maxBinNumber + 1];

  int age2DepthBinNumber;
  int age2DepthBin[maxBinNumber + 1];

  int age3PDepthBinNumber;
  int age3PDepthBin[maxBinNumber + 1];
              
  float cellDepth;           

  id <ListIndex> age0Ndx=nil;
  id <ListIndex> age1Ndx;
  id <ListIndex> age2Ndx;
  id <ListIndex> age3PNdx;

  id trout = nil;


  for(i=0; i <= maxBinNumber; i++) {

     age0DepthBin[i]  = 0.0;
     age1DepthBin[i]  = 0.0;
     age2DepthBin[i] = 0.0;
     age3PDepthBin[i] = 0.0;

  }



  ndx = [speciesSymbolList listBegin: scratchZone];

  while( ([ndx getLoc] != End) && (( species = [ndx next]) != nil) ) {

  fprintf( (FILE *) [speciesDepthUseOutStreamMap at: species], "%-14s", [timeManager getDateWithTimeT: modelTime]);
  fprintf( (FILE *) [speciesDepthUseOutStreamMap at: species], "%-10d%-11d", scenario, replicate);
  fflush(0);

          if( (ageClassList = [[fpm at: species] at: Age0]) != nil) {
              
              age0Ndx = [ageClassList listBegin: scratchZone];
              while( ([age0Ndx getLoc] != End) && (( trout = [age0Ndx next]) != nil) ) {
             
                   cellDepth = [[trout getWorld] getDepth];

                   if(cellDepth < depthHistoMaxDepth) {

                        age0DepthBinNumber = (int) floor(cellDepth/depthBinWidth);
                        age0DepthBin[age0DepthBinNumber] += 1;

                   }
                   else {

                        age0DepthBin[maxBinNumber] += 1;

                   }

              } //while age0Ndx

              [age0Ndx drop];   
  
          } //if Age0
          if( (ageClassList = [[fpm at: species] at: Age1]) != nil) {
              
              age1Ndx = [ageClassList listBegin: scratchZone];
              while( ([age1Ndx getLoc] != End) && (( trout = [age1Ndx next]) != nil) ) {
             
                   cellDepth = [[trout getWorld] getDepth];

                   if(cellDepth < depthHistoMaxDepth) {

                        age1DepthBinNumber = (int) floor(cellDepth/depthBinWidth);
                        age1DepthBin[age1DepthBinNumber] += 1;

                   }
                   else {

                        age1DepthBin[maxBinNumber] += 1;

                   }
                     



              } //while age1Ndx

              [age1Ndx drop];

          } //if Age1
          if( (ageClassList = [[fpm at: species] at: Age2]) != nil) {
              
              age2Ndx = [ageClassList listBegin: scratchZone];
              while( ([age2Ndx getLoc] != End) && (( trout = [age2Ndx next]) != nil) ) {
             
                   cellDepth = [[trout getWorld] getDepth];

                   if(cellDepth < depthHistoMaxDepth) {

                        age2DepthBinNumber = (int) floor(cellDepth/depthBinWidth);
                        age2DepthBin[age2DepthBinNumber] += 1;

                   }
                   else {

                        age2DepthBin[maxBinNumber] += 1;

                   }

              } //while age2Ndx

              [age2Ndx drop];

          } //if Age2
          if( (ageClassList = [[fpm at: species] at: Age3Plus]) != nil) {
              
              age3PNdx = [ageClassList listBegin: scratchZone];
              while( ([age3PNdx getLoc] != End) && (( trout = [age3PNdx next]) != nil) ) {
             
                   cellDepth = [[trout getWorld] getDepth];

                   if(cellDepth < depthHistoMaxDepth) {

                        age3PDepthBinNumber = (int) floor(cellDepth/depthBinWidth);
                        age3PDepthBin[age3PDepthBinNumber] += 1;

                   }
                   else {

                        age3PDepthBin[maxBinNumber] += 1;

                   }


              } //while age3PNdx

              [age3PNdx drop];

          } //if Age3P
          else { 

              [InternalError raiseEvent: "ERROR One of the age class lists is nil in printTroutDepthUsage\n"];
        
         }


        for(i=0;i <= maxBinNumber; i++) {

           fprintf( (FILE *) [speciesDepthUseOutStreamMap at: species],"%-14d", age0DepthBin[i]);
           fflush(0);

        } //for i
        for(i=0;i <= maxBinNumber; i++) {

           fprintf( (FILE *) [speciesDepthUseOutStreamMap at: species],"%-14d", age1DepthBin[i]);
           fflush(0);

         } //for i
         for(i=0;i <= maxBinNumber; i++) {

            fprintf( (FILE *) [speciesDepthUseOutStreamMap at: species],"%-14d", age2DepthBin[i]);
            fflush(0);

         } //for i
         for(i=0;i <= maxBinNumber; i++) {

            fprintf( (FILE *) [speciesDepthUseOutStreamMap at: species],"%-18d", age3PDepthBin[i]);
            fflush(0);

         } //for i

         fprintf( (FILE *) [speciesDepthUseOutStreamMap at: species], "\n");
         fflush(0);
    

 } //while ndx

 [ndx drop];

 return self;

}

*/

/*
- printTroutVelocityUseHisto 
{


  id <ListIndex> ndx; 
  id <Symbol> species=nil;

  id <List> ageClassList;

  unsigned maxBinNumber = (unsigned) floor(velocityHistoMaxVelocity/velocityBinWidth);
  int i;

  int age0VelocityBinNumber;
  int age0VelocityBin[maxBinNumber + 1];

  int age1VelocityBinNumber;
  int age1VelocityBin[maxBinNumber + 1];

  int age2VelocityBinNumber;
  int age2VelocityBin[maxBinNumber + 1];

  int age3PVelocityBinNumber;
  int age3PVelocityBin[maxBinNumber + 1];
              
  float cellVelocity;           

  id <ListIndex> age0Ndx=nil;
  id <ListIndex> age1Ndx;
  id <ListIndex> age2Ndx;
  id <ListIndex> age3PNdx;

  id trout = nil;


  for(i=0; i <= maxBinNumber; i++) {

     age0VelocityBin[i]  = 0.0;
     age1VelocityBin[i]  = 0.0;
     age2VelocityBin[i] = 0.0;
     age3PVelocityBin[i] = 0.0;

  }



  ndx = [speciesSymbolList listBegin: scratchZone];

  while( ([ndx getLoc] != End) && (( species = [ndx next]) != nil) ) {

  fprintf( (FILE *) [speciesVelocityUseOutStreamMap at: species], "%-14s", [timeManager getDateWithTimeT: modelTime]);
  fprintf( (FILE *) [speciesVelocityUseOutStreamMap at: species], "%-10d%-11d", scenario, replicate);
  fflush(0);

          if( (ageClassList = [[fpm at: species] at: Age0]) != nil) {
              
              age0Ndx = [ageClassList listBegin: scratchZone];
              while( ([age0Ndx getLoc] != End) && (( trout = [age0Ndx next]) != nil) ) {
             
                   cellVelocity = [[trout getWorld] getCellVelocity];

                   if(cellVelocity < velocityHistoMaxVelocity) {

                        age0VelocityBinNumber = (int) floor(cellVelocity/velocityBinWidth);
                        age0VelocityBin[age0VelocityBinNumber] += 1;

                   }
                   else {

                        age0VelocityBin[maxBinNumber] += 1;

                   }
                     



              } //while age0Ndx

              [age0Ndx drop];

          } //if Age0
          if( (ageClassList = [[fpm at: species] at: Age1]) != nil) {
              
              age1Ndx = [ageClassList listBegin: scratchZone];
              while( ([age1Ndx getLoc] != End) && (( trout = [age1Ndx next]) != nil) ) {
             
                   cellVelocity = [[trout getWorld] getCellVelocity];

                   if(cellVelocity < velocityHistoMaxVelocity) {

                        age1VelocityBinNumber = (int) floor(cellVelocity/velocityBinWidth);
                        age1VelocityBin[age1VelocityBinNumber] += 1;

                   }
                   else {

                        age1VelocityBin[maxBinNumber] += 1;

                   }
                     

              } //while age1Ndx

              [age1Ndx drop];

          } //if Age1
          if( (ageClassList = [[fpm at: species] at: Age2]) != nil) {
              
              age2Ndx = [ageClassList listBegin: scratchZone];
              while( ([age2Ndx getLoc] != End) && (( trout = [age2Ndx next]) != nil) ) {
             
                   cellVelocity = [[trout getWorld] getCellVelocity];

                   if(cellVelocity < velocityHistoMaxVelocity) {

                        age2VelocityBinNumber = (int) floor(cellVelocity/velocityBinWidth);
                        age2VelocityBin[age2VelocityBinNumber] += 1;

                   }
                   else {

                        age2VelocityBin[maxBinNumber] += 1;

                   }
                     



              } //while age2Ndx

              [age2Ndx drop];

          } //if Age2
          if( (ageClassList = [[fpm at: species] at: Age3Plus]) != nil) {
              
              age3PNdx = [ageClassList listBegin: scratchZone];
              while( ([age3PNdx getLoc] != End) && (( trout = [age3PNdx next]) != nil) ) {
             
                   cellVelocity = [[trout getWorld] getPolyCellVelocity];

                   if(cellVelocity < velocityHistoMaxVelocity) {

                        age3PVelocityBinNumber = (int) floor(cellVelocity/velocityBinWidth);
                        age3PVelocityBin[age3PVelocityBinNumber] += 1;

                   }
                   else {

                        age3PVelocityBin[maxBinNumber] += 1;

                   }
                     

              } //while age3PNdx

              [age3PNdx drop];

          } //if Age3Plus
          else { 

              [InternalError raiseEvent: "ERROR One of the age class lists is nil in printTroutVelocityUsage\n"];
        
         }



        for(i=0;i <= maxBinNumber; i++) {

           fprintf( (FILE *) [speciesVelocityUseOutStreamMap at: species],"%-17d", age0VelocityBin[i]);
           fflush(0);

        } //for i
        for(i=0;i <= maxBinNumber; i++) {

           fprintf( (FILE *) [speciesVelocityUseOutStreamMap at: species],"%-17d", age1VelocityBin[i]);
           fflush(0);

         } //for i
         for(i=0;i <= maxBinNumber; i++) {

            fprintf( (FILE *) [speciesVelocityUseOutStreamMap at: species],"%-17d", age2VelocityBin[i]);
            fflush(0);

         } //for i
         for(i=0;i <= maxBinNumber; i++) {

            fprintf( (FILE *) [speciesVelocityUseOutStreamMap at: species],"%-21d", age3PVelocityBin[i]);
            fflush(0);

         } //for i

         fprintf( (FILE *) [speciesVelocityUseOutStreamMap at: species], "\n");
         fflush(0);
    

 } //while ndx

 [ndx drop];




  return self;

}

*/


////////////////////////////////////////////
//
// getSpeciesSymbolWithName
//
////////////////////////////////////////////
- (id <Symbol>) getSpeciesSymbolWithName: (char *) aName
{
   id <Symbol> speciesSymbol = nil;
   id <ListIndex> ndx = nil;
   BOOL speciesNameFound = NO;
   char* speciesName = NULL;

   if(speciesSymbolList != nil)
   {
       ndx = [speciesSymbolList listBegin: scratchZone];
   }
   else
   {
      fprintf(stderr, "TroutModelSwarm >>>> getSpeciesSymbolWithName >>>> method invoked before instantiateObjects\n");
      fflush(0);
      exit(1);
   }

   while(([ndx getLoc] != End) && ((speciesSymbol = [ndx next]) != nil))  
   {
        speciesName = (char *)[speciesSymbol getName];
        if(strncmp(aName, speciesName, strlen(speciesName)) == 0)
        {
            speciesNameFound = YES;
            [scratchZone free: speciesName];
            speciesName = NULL; 
            break;
        }

        if(speciesName != NULL)
        { 
            [scratchZone free: speciesName];
            speciesName = NULL;
        }
   } 

   if(!speciesNameFound)
   {
       fprintf(stderr, "TroutModelSwarm >>>> getSpeciesSymbolWithName >>>> no species symbol for name %s\n", aName);
       fflush(0);
       exit(1);
   } 

   return speciesSymbol;
}


/////////////////////////////////////////////////////
//
////
//////           REDD REPORTING
////////
/////////
/////////////////////////////////////////////////////


/////////////////////////////////////////////////
//
// openReddReportFilePtr
//
//////////////////////////////////////////////////
- openReddReportFilePtr 
{
  if(reddRptFilePtr == NULL) 
  {
     if(appendFiles == NO) 
     {
        if((reddRptFilePtr = fopen(reddMortalityFile,"w")) == NULL ) 
        {
             fprintf(stderr, "ERROR: UTMTroutModelSwarm >>>> openReddReportFilePtr >>>> Cannot open %s for writing\n", reddMortalityFile);
             fflush(0);
             exit(1);
        }

        fprintf(reddRptFilePtr,"\n\n");
        fprintf(reddRptFilePtr,"SYSTEM TIME:  %s\n", [timeManager getSystemDateAndTime]);
     }
     else if((scenario == 1) && (replicate == 1) && (appendFiles == YES))
     {
        if((reddRptFilePtr = fopen(reddMortalityFile,"w")) == NULL )
        {
             fprintf(stderr, "ERROR: UTMTroutModelSwarm >>>> openReddReportFilePtr >>>> Cannot open %s for writing\n", reddMortalityFile);
             fflush(0);
             exit(1);
        }

        fprintf(reddRptFilePtr,"\n\n");
        fprintf(reddRptFilePtr,"SYSTEM TIME:  %s\n", [timeManager getSystemDateAndTime]);
     }
     else
     {
         if((reddRptFilePtr = fopen(reddMortalityFile,"a")) == NULL )
          {
             fprintf(stderr, "ERROR: UTMTroutModelSwarm >>>> openReddReportFilePtr >>>> Cannot open %s for writing\n", reddMortalityFile);
             fflush(0);
             exit(1);
         }
     }
  }

   if(reddRptFilePtr == NULL)
   {
        fprintf(stderr, "ERROR: UTMTroutModelSwarm >>>> openReddReportFilePtr >>>> Cannot open %s for writing\n", reddMortalityFile);
        fflush(0);
        exit(1);
   }

   return self;
}


/////////////////////////////////////////////////
//
// getReddReportFilePtr
//
//////////////////////////////////////////////////
- (FILE *) getReddReportFilePtr
{
   if(reddRptFilePtr == NULL)
   {
       fprintf(stderr, "ERROR: UTMTroutModelSwarm >>>> getReddReportFilePtr >>>> File %s is not open\n", reddMortalityFile);
       fflush(0);
       exit(1);
   }

   return reddRptFilePtr;
}



///////////////////////////////////////////////////
//
// openReddSummaryFilePtr
//
//////////////////////////////////////////////////
- openReddSummaryFilePtr 
{

  char* formatString = "%-12s%-12s%-12s%-12s%-12s%-12s%-21s%-12s%-12s%-12s%-12s%-12s%-12s%-12s\n";

  if(reddSummaryFilePtr == NULL) 
  {
     if(appendFiles == NO) 
     {
        if((reddSummaryFilePtr = fopen(reddOutputFile,"w")) == NULL)
        {
             fprintf(stderr, "ERROR: UTMTroutModelSwarm >>>> openReddSummaryFilePtr >>>> Cannot open %s for writing\n", reddOutputFile);
             fflush(0);
             exit(1);
        }

        fprintf(reddSummaryFilePtr,"\n");
        fprintf(reddSummaryFilePtr,"SYSTEM TIME:  %s\n", [timeManager getSystemDateAndTime]);
        fprintf(reddSummaryFilePtr,formatString, "Scenario",
                                                  "Replicate",
                                                  "ReddID",
                                                  "Species",
                                                  "CellNo",
                                                  "CreateDate",
                                                  "InitialNumberOfEggs",
                                                  "EmptyDate",
                                                  "Dewatering",
                                                  "Scouring",
                                                  "LowTemp",
                                                  "HiTemp",
                                                  "SuperImp",
                                                  "FryEmerged"); 

     }
     else if((scenario == 1) && (replicate == 1) && (appendFiles == YES))
     {
        if((reddSummaryFilePtr = fopen(reddOutputFile,"w")) == NULL)
        {
             fprintf(stderr, "ERROR: UTMTroutModelSwarm >>>>> openReddSummaryFilePtr >>>> Cannot open %s for writing\n",reddOutputFile);
             fflush(0);
             exit(1);
        }

        fprintf(reddSummaryFilePtr,"\n");
        fprintf(reddSummaryFilePtr,"SYSTEM TIME:  %s\n", [timeManager getSystemDateAndTime]);
        fprintf(reddSummaryFilePtr,formatString, "Scenario",
                                                 "Replicate",
                                                 "ReddID",
                                                 "Species",
                                                 "Transect",
                                                 "CreateDate",
                                                 "InitialNumberOfEggs",
                                                 "EmptyDate",
                                                 "Dewatering",
                                                 "Scouring",
                                                 "LowTemp",
                                                 "HiTemp",
                                                 "SuperImp",
                                                 "FryEmerged"); 

     }
     else 
     {
         if((reddSummaryFilePtr = fopen(reddOutputFile,"a")) == NULL) 
         {
             fprintf(stderr, "ERROR: UTMTroutModelSwarm >>>> openReddSummaryFilePtr >>>> Cannot open %s for appending\n",reddOutputFile);
             fflush(0);
             exit(1);
         }
     }
   }

   if(reddSummaryFilePtr == NULL)
   {
        fprintf(stderr, "ERROR: TroutModelSwarm >>>> openReddSummaryFilePtr >>>> File %s is not open\n", reddOutputFile);
        fflush(0);
        exit(1);
   }

   return self;
}


///////////////////////////////////
//
// getReddSummaryFilePtr 
//
/////////////////////////////////// 
- (FILE *) getReddSummaryFilePtr 
{
   if(reddSummaryFilePtr == NULL)
   {
        fprintf(stderr, "ERROR: TroutModelSwarm >>>> getReddSummaryFilePtr >>>> File %s is not open\n", reddOutputFile);
        fflush(0);
        exit(1);
   }
    
   return reddSummaryFilePtr;
}

/////////////////////////////////////////////
//
// getReddBinomialDist
//
////////////////////////////////////////////
- (id <BinomialDist>) getReddBinomialDist
{
   return reddBinomialDist;
}



//////////////////////////////////////////////////////
//
////
//////        BREAKOUT REPORTERS
////////
//////////
/////////////////////////////////////////////////////


//////////////////////////////////////////////////////
//
// createBreakoutReporters
//
/////////////////////////////////////////////////////
- createBreakoutReporters
{
      fprintf(stdout, "UTMTroutModelSwarm >>>> createBreakoutReporters >>>> BEGIN\n");
      fflush(0);

  BOOL fileOverWrite = TRUE;
  BOOL suppressBreakoutColumns = NO;

  if(appendFiles == TRUE)
  {
     fileOverWrite = FALSE;
  }

  if((scenario != 1) || (replicate != 1))
  {
      suppressBreakoutColumns = YES;
      fileOverWrite = FALSE;
  }
      
  //
  // Fish mortality reporter
  //
  fishMortalityReporter = [BreakoutReporter   createBeginWithCSV: modelZone
                                                  forList: deadFish
                                       //withOutputFilename: "FishMortality.rpt"
                                       withOutputFilename: (char *) fishMortalityFile
                                        withFileOverwrite: fileOverWrite];
					//withColumnWidth: 25];

      //fprintf(stdout, "UTMTroutModelSwarm >>>> createBreakoutReporters >>>> after create begin mortality \n");
      //fflush(0);

  [fishMortalityReporter addColumnWithValueOfVariable: "scenario"
                                        fromObject: self
                                          withType: "int"
                                         withLabel: "Scenario"];

  [fishMortalityReporter addColumnWithValueOfVariable: "replicate"
                                        fromObject: self
                                          withType: "int"
                                         withLabel: "Replicate"];

  [fishMortalityReporter addColumnWithValueOfVariable: "modelDate"
                                        fromObject: self
                                          withType: "string"
                                         withLabel: "ModelDate"];

  [fishMortalityReporter breakOutUsingSelector: @selector(getReachSymbol)
                                withListOfKeys: reachSymbolList];

  [fishMortalityReporter breakOutUsingSelector: @selector(getSpecies)
                                withListOfKeys: speciesSymbolList];

  [fishMortalityReporter breakOutUsingSelector: @selector(getAgeSymbol)
                                withListOfKeys: ageSymbolList];

  [fishMortalityReporter breakOutUsingSelector: @selector(getCauseOfDeath)
                                withListOfKeys: fishMortSymbolList];

  [fishMortalityReporter createOutputWithLabel: "Count"
                                  withSelector: @selector(getFishCount)
                              withAveragerType: "Count"];

  [fishMortalityReporter suppressColumnLabels: suppressBreakoutColumns];

  fishMortalityReporter = [fishMortalityReporter createEnd];

      //fprintf(stdout, "UTMTroutModelSwarm >>>> createBreakoutReporters >>>> after mortality rep\n");
      //fflush(0);

  //
  // Live fish reporter
  //
  liveFishReporter = [BreakoutReporter   createBeginWithCSV: modelZone
                                             forList: liveFish
                                  //withOutputFilename: "LiveFish.rpt"
                                  withOutputFilename: (char *) fishOutputFile
                                   withFileOverwrite: fileOverWrite];
  //withColumnWidth: 25];


  [liveFishReporter addColumnWithValueOfVariable: "scenario"
                                      fromObject: self
                                        withType: "int"
                                       withLabel: "Scenario"];

  [liveFishReporter addColumnWithValueOfVariable: "replicate"
                                      fromObject: self
                                        withType: "int"
                                       withLabel: "Replicate"];

  [liveFishReporter addColumnWithValueOfVariable: "modelDate"
                                      fromObject: self
                                        withType: "string"
                                       withLabel: "ModelDate"];

  [liveFishReporter breakOutUsingSelector: @selector(getReachSymbol)
                           withListOfKeys: reachSymbolList];

  [liveFishReporter breakOutUsingSelector: @selector(getSpecies)
                           withListOfKeys: speciesSymbolList];

  [liveFishReporter breakOutUsingSelector: @selector(getAgeSymbol)
                           withListOfKeys: ageSymbolList];

  [liveFishReporter createOutputWithLabel: "Count"
                             withSelector: @selector(getFishCount)
                         withAveragerType: "Count"];

  [liveFishReporter createOutputWithLabel: "MeanLength"
                             withSelector: @selector(getFishLength)
                         withAveragerType: "Average"];

  [liveFishReporter createOutputWithLabel: "TotalWeight"
                             withSelector: @selector(getFishWeight)
                         withAveragerType: "Total"];

  [liveFishReporter createOutputWithLabel: "MeanWeight"
                             withSelector: @selector(getFishWeight)
                         withAveragerType: "Average"];

  [liveFishReporter suppressColumnLabels: suppressBreakoutColumns];

  liveFishReporter = [liveFishReporter createEnd];

      fprintf(stdout, "UTMTroutModelSwarm >>>> createBreakoutReporters >>>> END\n");
      fflush(0);
  return self;
}

////////////////////////////////////////////
//
// outputBreakoutReport
//
////////////////////////////////////////////
- outputBreakoutReport
{
   //fprintf(stdout, "TroutModelSwarm >>>> outputBreakoutReport >>>> BEGIN\n");
   //fflush(0);

   [liveFishReporter updateByReplacement];
   [liveFishReporter output];

   //[timeHorizonReporter updateByReplacement];
   //[timeHorizonReporter output];

   //
   // Changed from updateByAccumulation to updateByReplacement
   // per request from sfr during mem leak debug. skj 18Jun08
   //
   [fishMortalityReporter updateByReplacement];
   [fishMortalityReporter output];

   //
   // Added the following during memory leak debug
   //
   [deadFish deleteAll];

   //[moveFishReporter updateByReplacement];
   //[moveFishReporter output];

   //fprintf(stdout, "TroutModelSwarm >>>> outputBreakoutReport >>>> END\n");
   //fflush(0);

   return self;
}


////////////////////////////////////////////
//
// setShadeColorMax
//
///////////////////////////////////////////
- setShadeColorMax: (double) aShadeColorMax
{
    id <ListIndex> lstNdx = nil;
    id aHabitatSpace;

    shadeColorMax = aShadeColorMax;
    lstNdx = [reachList listBegin: scratchZone];

    while(([lstNdx getLoc] != End) && ((aHabitatSpace = (HabitatSpace *) [lstNdx next]) != (HabitatSpace *) nil)){
      [aHabitatSpace setShadeColorMax: shadeColorMax];
    }
    return self;
}

///////////////////////////////////////////////////////
//
// switchColorRepFor 
//
///////////////////////////////////////////////////////
- switchColorRepFor: aHabitatSpace
{
    fprintf(stdout, "TroutModelSwarm >>>> switchColorRepFor >>>> BEGIN\n");
    fflush(0);

    if(observerSwarm == nil)
    {
       fprintf(stderr, "WARNING: TroutModelSwarm >>>> switchColorRepFor >>>> observerSwarm is nil >>>> Cannot handle your request\n");
       fflush(0);
    }

    [observerSwarm switchColorRepFor: aHabitatSpace];  


    fprintf(stdout, "TroutModelSwarm >>>> switchColorRepFor >>>> END\n");
    fflush(0);

    return self;
}

/////////////////////////////////////
//
// redrawRaster
//
////////////////////////////////////
- redrawRaster
{
    [observerSwarm redrawRaster];
    return self;
}

/////////////////////////////////////////////////////////////////
//
// getWriteFoodAvailabilityReport
//
//////////////////////////////////////////////////////////////
- (BOOL) getWriteFoodAvailabilityReport {
  return writeFoodAvailabilityReport;
}

/////////////////////////////////////////////////////////////////
//
// getWriteDepthReport
//
//////////////////////////////////////////////////////////////
- (BOOL) getWriteDepthReport {
  return writeDepthReport;
}

/////////////////////////////////////////////////////////////////
//
// getWriteVelocityReport
//
//////////////////////////////////////////////////////////////
- (BOOL) getWriteVelocityReport {
  return writeVelocityReport;
}

/////////////////////////////////////////////////////////////////
//
// getWriteDepthVelocityReport
//
//////////////////////////////////////////////////////////////
- (BOOL) getWriteDepthVelocityReport {
  return writeDepthVelocityReport;
}

/////////////////////////////////////////////////////////////////
//
// getWriteHabitatReport
//
//////////////////////////////////////////////////////////////
- (BOOL) getWriteHabitatReport {
  return writeHabitatReport;
}

/////////////////////////////////////////////////////////////////
//
// getWriteMoveReport
//
//////////////////////////////////////////////////////////////
- (BOOL) getWriteMoveReport {
  return writeMoveReport;
}

/////////////////////////////////////////////////////////////////
//
// getWriteReadyToSpawnReport
//
//////////////////////////////////////////////////////////////
- (BOOL) getWriteReadyToSpawnReport {
  return writeReadyToSpawnReport;
}

/////////////////////////////////////////////////////////////////
//
// getWriteSpawnCellReport
//
//////////////////////////////////////////////////////////////
- (BOOL) getWriteSpawnCellReport {
  return writeSpawnCellReport;
}

/////////////////////////////////////////////////////////////////
//
// getWriteReddSurvReport
//
//////////////////////////////////////////////////////////////
- (BOOL) getWriteReddSurvReport {
  return writeReddSurvReport;
}

/////////////////////////////////////////////////////////////////
//
// getWriteCellFishReport
//
//////////////////////////////////////////////////////////////
- (BOOL) getWriteCellFishReport {
  return writeCellFishReport;
}

/////////////////////////////////////////////////////////////////
//
// getWriteReddMortReport
//
//////////////////////////////////////////////////////////////
- (BOOL) getWriteReddMortReport {
  return writeReddMortReport;
}

/////////////////////////////////////////////////////////////////
//
// getWriteIndividualFishReport
//
//////////////////////////////////////////////////////////////
- (BOOL) getWriteIndividualFishReport {
  return writeIndividualFishReport;
}

/////////////////////////////////////////////////////////////////
//
// getWriteCellCentroidReport
//
//////////////////////////////////////////////////////////////
- (BOOL) getWriteCellCentroidReport {
  return writeCellCentroidReport;
}
//////////////////////////////////////////////////////////
//
// drop
//
//////////////////////////////////////////////////////////
- (void) drop
{
  id <ListIndex> ndx;
  id species=nil;
  FILE* aStream=NULL;

  fprintf(stdout, "UTMTroutModelSwarm >>>> drop >>>> BEGIN\n");
  fflush(0);

  ndx = [speciesSymbolList listBegin: scratchZone];
  while(([ndx getLoc] != End) && (( species = [ndx next]) != nil))
  {
     if(speciesDepthUseOutStreamMap != nil)
     {
	 if((aStream = (FILE *) [speciesDepthUseOutStreamMap at: species]) != NULL)  fclose(aStream);
     }
     if(speciesVelocityUseOutStreamMap != nil)
     {
	 if((aStream = (FILE *) [speciesVelocityUseOutStreamMap at: species]) != NULL)  fclose(aStream);
     }
  }
 
  [ndx drop];


  if(liveFishReporter != nil)
  {
     [liveFishReporter drop];
  }

  if(fishMortalityReporter != nil)
  {
     [fishMortalityReporter drop];
  }

  //if(moveFishReporter != nil)
  //{
     //[moveFishReporter drop];
  //}

  if(timeManager != nil)
  {
      [timeManager drop];
      timeManager = nil;
  }

  [reproLogisticFuncMap deleteAll];
  [reproLogisticFuncMap drop];
  
  //[deathMap deleteAll];
  //[deathMap drop];

  [fishParamsMap deleteAll]; 
  [fishParamsMap drop];

  [liveFish deleteAll];
  [liveFish drop];
  [deadFish deleteAll];
  [deadFish drop];
  [killedFish deleteAll];
  [killedFish drop];


  [reddList deleteAll];
  [reddList drop];
  [emptyReddList deleteAll];
  [emptyReddList drop];
  [removedRedds deleteAll];
  [removedRedds drop];
  [killedRedds deleteAll];
  [killedRedds drop];
  [deadRedds deleteAll];
  [deadRedds drop];
  [speciesSymbolList deleteAll];
  [speciesSymbolList drop];
  [fishActivitySymbolList deleteAll];
  [fishActivitySymbolList drop];
  [ageSymbolList deleteAll];
  [ageSymbolList drop];
  [reddMortSymbolList deleteAll];
  [reddMortSymbolList drop];
  [fishMortSymbolList deleteAll];
  [fishMortSymbolList drop];
  [coinFlip drop];
  [randGen drop];
  [speciesClassList drop];

  [modelZone freeBlock: modelDate blockSize: 15*sizeof(char)];

  if(modelZone != nil)
  {
      //[self     printZone: modelZone 
           //withPrintLevel: 1];
      [modelZone drop];
      modelZone = nil;
  }
  
  [super drop];

  fprintf(stdout, "UTMTroutModelSwarm >>>> drop >>>> BEGIN\n");
  fflush(0);

} //drop




@end



