/*
inSTREAM Version 6.0, May 2013.
Individual-based stream trout modeling software. 
Developed and maintained by Steve Railsback, Lang, Railsback & Associates, 
Steve@LangRailsback.com; and Colin Sheppard, critter@stanfordalumni.org.
Development sponsored by US Bureau of Reclamation, EPRI, USEPA, USFWS,
USDA Forest Service, and others.
Version 6.0 sponsored by Argonne National Laboratory and Western
Area Power Administration.
Copyright (C) 2004-2013 Lang, Railsback & Associates.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program (see file LICENSE); if not, write to the
Free Software Foundation, Inc., 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.
*/


#import <math.h>
#import <string.h>
#import <simtools.h>
#import <random.h>
#import "TroutObserverSwarm.h"
#import "FishParams.h"
#import "FishCell.h"
#import "TroutModelSwarm.h"

id <Symbol> Female, Male;  // sex of fish

id <Symbol> *mySpecies;
id <Symbol> Feed, Hide;
Class *MyTroutClass; 
char **speciesName;
char **speciesColor;
char **speciesParameter;
char **speciesPopFile;
char **speciesStocking;

@implementation TroutModelSwarm


///////////////////////
//
// create
//
//////////////////////
+ create: aZone 
{
  TroutModelSwarm * troutModelSwarm;

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
  troutModelSwarm->isFirstStepOfDay = TRUE;

  troutModelSwarm->fishOutputFile = (char *) nil;

  troutModelSwarm->fileOutputFrequency = 1;
  troutModelSwarm->individualFishFile = "Individual_Fish_Out.csv";

  // variables used for tracking LFT data
  troutModelSwarm->resultsAgeThreshold = 1;
  troutModelSwarm->resultsCensusDay = "9/30";
  troutModelSwarm->lftNumAdultTrout = 0.0;
  troutModelSwarm->lftBiomassAdultTrout = 0.0;
  troutModelSwarm->lftNumCensusDays = 0;	

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
  //fprintf(stdout, "TroutModelSwarm >>>> instantiateObjects BEGIN\n"); 
  //fflush(0);
   int numspecies;
   modelZone = [Zone create: globalZone];

  if(numberOfSpecies == 0)
  {
       fprintf(stderr, "ERROR: TroutModelSwarm >>>> instantiateObjects numberOfSpecies is ZERO!\n"); 
       fflush(0);
       exit(1);
  }

  reachSymbolList = [List create: modelZone];

  mySpecies = (id *) [modelZone alloc: numberOfSpecies*sizeof(Symbol)];
  [self readSpeciesSetupFile];

  speciesSymbolList = [List create: modelZone];
  for(numspecies = 0; numspecies < numberOfSpecies; numspecies++ )
  {
    [speciesSymbolList addLast: mySpecies[numspecies] ];
  }


  fishMortSymbolList = [List create: modelZone];
  reddMortSymbolList = [List create: modelZone];

  listOfMortalityCounts = [List create: modelZone];
  [self getFishMortalitySymbolWithName: "DemonicIntrusion"];


  fishParamsMap = [Map create: modelZone];

  [self createFishParameters];
  [self findMinSpeciesPiscLength];

  reachSymbolList = [List create: modelZone];

  fishCounter = 0;

  habitatManager = [HabitatManager createBegin: modelZone];
  [habitatManager instantiateObjects];
  [habitatManager setSiteLatitude: siteLatitude]; 
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

  fprintf(stdout, "TroutModelSwarm >>>> buildObjects >>>> BEGIN\n");
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
      fprintf(stderr, "ERROR: TroutModelSwarm >>>> buildObjects >>>> Check runStartDate and runEndDate in Model.Setup\n");
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
  [self buildFishClass];

  numSimDays = [timeManager getNumberOfDaysBetween: runStartTime and: runEndTime] + 1;
  simHourCounter = 1;

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
  // Create the spaces in which the fish will live
  //
  [habitatManager setTimeManager: timeManager];

  [habitatManager setModelStartTime: (time_t) runStartTime
                         andEndTime: (time_t) runEndTime];

  [habitatManager setDataStartTime: (time_t) dataStartTime
                        andEndTime: (time_t) dataEndTime];

  [habitatManager setFracFlowChangeForMovement: (double) fracFlowChangeForMovement];

  [habitatManager setFracDriftChangeForMovement: (double) fracDriftChangeForMovement];

  //
  // Moved from instantiateObjects 
  //
  [habitatManager setPolyRasterResolutionX:  polyRasterResolutionX
                  setPolyRasterResolutionY:  polyRasterResolutionY
                    setRasterColorVariable:   polyRasterColorVariable
                          setShadeColorMax:  shadeColorMax];

  [habitatManager finishBuildingTheHabitatSpaces];
  
  // if(writeCellFishReport == YES){
      // [habitatManager buildHabSpaceCellFishInfoReporter];
  // }

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


      //fprintf(stdout, "TroutModelSwarm >>>> buildObjects >>>> before speciesSymbolList \n");
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

  //
  // This can only be done once the fish parameter objects have been created
  // and initialized
  //
  cmaxInterpolatorMap = [Map create: modelZone];
  spawnDepthInterpolatorMap = [Map create: modelZone];
  spawnVelocityInterpolatorMap = [Map create: modelZone];
  captureLogisticMap = [Map create: modelZone];
  [self createCMaxInterpolators];
  [self createSpawnDepthInterpolators];
  [self createSpawnVelocityInterpolators];
  [self createCaptureLogistics];

  //
  // Breakout reporters... 
  //
  [self createBreakoutReporters];

  if(writeCellFishReport == YES){
      [habitatManager buildHabSpaceCellFishInfoReporter];
  }

  if(writeIndividualFishReport == YES){
    [self openIndividualFishReportFilePtr];
  }

  if(theColormaps != nil) 
  {
      [self setFishColormap: theColormaps];
  }

  fishInitializationRecords = [List create: modelZone];
  popInitTime = [timeManager getTimeTWithDate: popInitDate];
  [self createInitialFish]; 
  //fprintf(stdout, "TroutModelSwarm >>>> buildObjects >>>> after createInitialFish \n");
  //fflush(0);
  [QSort sortObjectsIn:  liveFish];
  //fprintf(stdout, "TroutModelSwarm >>>> buildObjects >>>> after sort\n");
  //fflush(0);
  [QSort reverseOrderOf: liveFish];
  //fprintf(stdout, "TroutModelSwarm >>>> buildObjects >>>> after reverse\n");
  //fflush(0);

  [self createReproLogistics];
  //fprintf(stdout, "TroutModelSwarm >>>> buildObjects >>>> after createReproLogistics \n");
  //fflush(0);

  reddBinomialDist = [BinomialDist create: modelZone setGenerator: randGen];
  //fprintf(stdout, "TroutModelSwarm >>>> buildObjects >>>> after binomial create\n");
  //fflush(0);

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
  //fprintf(stdout, "TroutModelSwarm >>>> buildObjects >>>> after printInitFishReport\n");
  //fflush(0);

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
  //
  // STOCKING
  //
  nextFishStockTime = (time_t) 0;
  fishStockList = [List create: modelZone];
  [self readFishStockingRecords];

  fprintf(stdout, "TroutModelSwarm >>>> buildObjects >>>> END\n");
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

       //fprintf(stdout, "TroutModelSwarm >>>> createYearShuffler >>>> numSimYears %d\n", numSimYears);
       //fprintf(stdout, "TroutModelSwarm >>>> createYearShuffler >>>> startYear %d endYear %d\n", startYear, endYear);
       //fflush(0);
   }

   return self;
}

///////////////////////////////////////////////
//
// updateMortalityCountWith
//
///////////////////////////////////////////////
- updateMortalityCountWith: aDeadFish
{
   TroutMortalityCount* mortalityCount = nil;
   id <Symbol> causeOfDeath = [aDeadFish getCauseOfDeath];
   BOOL ERROR = YES;

   [mortalityCountLstNdx setLoc: Start];
    while(([mortalityCountLstNdx getLoc] != End) && ((mortalityCount = [mortalityCountLstNdx next]) != nil)){
         if(causeOfDeath == [mortalityCount getMortality]){
             [mortalityCount incrementNumDead];
             ERROR = NO;
             break;
         }
    }

    if(ERROR){
        fprintf(stderr, "TroutModelSwarm >>>> updateMortalityCountWith >>>> mortality source not found in object TroutMortalityCount\n");
        fflush(0);
        exit(1);
    }

   return self;
}

- (id <List>) getListOfMortalityCounts
{
   return listOfMortalityCounts;
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
-    setUTMRasterResolutionX: (int) aUTMRasterResolutionX
    setUTMRasterResolutionY:  (int) aUTMRasterResolutionY
  setUTMRasterColorVariable:  (char *) aUTMRasterColorVariable
{
	//fprintf(stdout, "TroutMOdelSwarm >>>> setUTMRasterVars >>>> BEGIN\n");
	//fflush(0);
    utmRasterResolutionX = aUTMRasterResolutionX;
    utmRasterResolutionY = aUTMRasterResolutionY;
    strncpy(utmRasterColorVariable, aUTMRasterColorVariable, 35);

    //fprintf(stdout, "TroutMOdelSwarm >>>> setUTMRasterVars >>>> END\n");
    //fflush(0);
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
   id <ListIndex> lstNdx = nil;
   SpeciesSetup* speciesSetup = (SpeciesSetup *) nil;

   //fprintf(stdout, "TroutMOdelSwarm >>>> createFishParameters >>>> BEGIN\n");
   //fflush(0);


   for(speciesNdx = 0; speciesNdx < numberOfSpecies; speciesNdx++) 
   {
      FishParams* fishParams = [FishParams createBegin:  modelZone];
      [ObjectLoader load: fishParams fromFileNamed: speciesParameter[speciesNdx]];
 
      [fishParams setFishSpeciesIndex: speciesNdx]; 
      [fishParams setFishSpecies: mySpecies[speciesNdx]]; 

      [fishParams setInstanceName: (char *) [mySpecies[speciesNdx] getName]];

      fishParams = [fishParams createEnd];

      #ifdef DEBUG_TROUT_FISHPARAMS
         [fishParams printSelf];
      #endif

      [fishParamsMap at: [fishParams getFishSpecies] insert: fishParams]; 
   }

  lstNdx = [speciesSetupList listBegin: scratchZone];
  while (([lstNdx getLoc] != End) && ((speciesSetup = (SpeciesSetup *) [lstNdx next]) != (SpeciesSetup *) nil)) 
  {
	  speciesSetup->fishParams = [fishParamsMap at: speciesSetup->speciesSymbol];
  }

   //fprintf(stdout, "TroutMOdelSwarm >>>> createFishParameters >>>> END\n");
   //fflush(0);
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

  //fprintf(stdout, "TroutModelSwarm >>>> findMinSpeciesPiscLength >>>> BEGIN\n");
  //fflush(0);

  mapNdx = [fishParamsMap mapBegin: scratchZone];

  while(([mapNdx getLoc] != End) && ((fishParams = (FishParams *) [mapNdx next]) != (FishParams *) nil))
  {
     minSpeciesMinPiscLength =  (minSpeciesMinPiscLength > fishParams->fishPiscivoryLength) ?
                                 fishParams->fishPiscivoryLength  
                                : minSpeciesMinPiscLength;
  }


  [mapNdx drop];

  //fprintf(stdout, "TroutModelSwarm >>>> minSpeciesMinPiscLength = %f\n", minSpeciesMinPiscLength);
  //fflush(0);

  //fprintf(stdout, "TroutModelSwarm >>>> findMinSpeciesPiscLength >>>> END\n");
  //fflush(0);

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

  //fprintf(stdout, "TroutModelSwarm >>>> createReproLogistics >>>> BEGIN\n");
  //fflush(0);
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

  //fprintf(stdout, "TroutModelSwarm >>>> createReproLogistics >>>> biggestFishLength = %f\n", biggestFishLength);
  //fprintf(stdout, "TroutModelSwarm >>>> createReproLogistics >>>> END\n");
  //fflush(0);

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

  // fprintf(stdout, "TroutModelSwarm >>>> updateReproFuncs BEGIN\n");
  // fflush(0);

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

  // fprintf(stdout, "TroutModelSwarm >>>> updateReproFuncs biggestFishLength = %f\n", biggestFishLength);
  // fprintf(stdout, "TroutModelSwarm >>>> updateReproFuncs END\n");
  // fflush(0);

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
	//fprintf(stdout, "ModelSwarm >> getReproFuncFor fish with length: %f returns: %f\n",aLength,
	//	[[reproLogisticFuncMap at: [aFish getSpecies]]
    //                      evaluateFor: aLength] );
	//fflush(0);
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

  //fprintf(stdout, "TroutModelSwarm >>>> setFishColorMap >>>> BEGIN\n");
  //fprintf(stdout, "TroutModelSwarm >>>> setFishColorMap >>>> FISH_COLOR = %d\n", FISH_COLOR);
  //fflush(0);

  while(([clrMapNdx getLoc] != End) && ((aColorMap = [clrMapNdx next]) != nil))
  {
     [aColorMap setColor: FISH_COLOR 
                  ToName: "white"];
  }

  fishColorMap = [Map create: modelZone];

  FISH_COLOR++;


  lstNdx = [speciesSetupList listBegin: scratchZone];
  while (([lstNdx getLoc] != End) && ((speciesSetup = (SpeciesSetup *) [lstNdx next]) != (SpeciesSetup *) nil)) 
  {
      long* fishColor = [modelZone alloc: sizeof(long)];
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
      // fprintf(stdout, "TroutModelSwarm >>>> setFishColorMap >>>> FISH_COLOR = %ld, SPECIES = %s, return=%ld \n", fishColor,[speciesSetup->speciesSymbol getName],*((long *)[fishColorMap at: speciesSetup->speciesSymbol]));
      // fflush(0);
	  
  }

  [lstNdx drop];
  [clrMapNdx drop];

  //fprintf(stdout, "TroutModelSwarm >>>> setFishColorMap >>>> END\n");
  //fflush(0);

  return self;
}


/////////////////////////////////////////////////
//
// createCaptureLogistics
//
/////////////////////////////////////////////////
- createCaptureLogistics
{
  id <Index> mapNdx;
  FishParams* fishParams;

  mapNdx = [fishParamsMap mapBegin: scratchZone];
 
  while(([mapNdx getLoc] != End) && ((fishParams = (FishParams *) [mapNdx next]) != nil))
  {
      //
      // getCellVelocity is not actually used;
      // it is there because the logistic
      // needs an input method. The fish
      // evaluates for velocity/aMaxSwimSpeed
      //
      LogisticFunc* aCaptureLogistic = [LogisticFunc createBegin: modelZone 
                                                 withInputMethod: M(getPolyCellVelocity) 
                                                      usingIndep: fishParams->fishCaptureParam1
                                                             dep: 0.1
                                                           indep: fishParams->fishCaptureParam9
                                                             dep: 0.9];

     [captureLogisticMap at: [fishParams getFishSpecies] insert: aCaptureLogistic]; 
  }

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
   TroutInitializationRecord* initialFishRecord = (TroutInitializationRecord *) nil;

   id aHabitatSpace;
   id <List> polyCellList = nil;
   
   
   //fprintf(stdout,"TroutModelSwarm >>>> createInitialFish BEGIN\n");
   //fflush(0);

   //
   // set up the distribution that will place the fishes on the grid
   //
   lengthDist = [NormalDist create: modelZone 
                      setGenerator: randGen];
   //
   // read the population files for each species
   //
   [self readFishInitializationFiles];

   initPopLstNdx = [fishInitializationRecords listBegin: scratchZone];
  
   numFish = 0;

   while(([initPopLstNdx getLoc] != End) && ((initialFishRecord = (TroutInitializationRecord *) [initPopLstNdx next]) != (TroutInitializationRecord *) nil)) 
   {
     //fprintf(stdout,"TroutModelSwarm >>>> createInitialFish >>>> initialFishRecord loop\n");
     //fflush(0);
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

      [lengthDist setMean: initialFishRecord->meanLength
                setStdDev: initialFishRecord->stdDevLength];


      for(numFishNdx=0; numFishNdx < initialFishRecord->number; numFishNdx++)
      {
        //  FishParams* fishParams = nil;  Not used
          id newFish;
          double length;
          int age = initialFishRecord->age;

          while((length = [lengthDist getDoubleSample]) <= (0.5)*[lengthDist getMean]) 
          {
               continue;
          }

	  //fprintf(stdout,"TroutModelSwarm >>>> createInitialFish >>>> create fish %s age %d length %f \n",[initialFishRecord->mySpecies getName],age,length );
	  //fflush(0);
	  newFish = [self createNewFishWithSpeciesIndex: initialFishRecord->speciesNdx  
                                                   Species: initialFishRecord->mySpecies 
                                                       Age: age
                                                    Length: length ];

	  // Calculate max swim speed, which is needed below but depends on temperature, which it gets from cell
          [newFish setMaxSwimSpeed: [newFish calcMaxSwimSpeedAt: [polyCellList getFirst]]];
	  [liveFish addLast: newFish];
          
	   //   fishParams = [newFish getFishParams];  Not used

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
                             continue;
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
	         fprintf(stderr, "WARNING: TroutModelSwarm >>>> createInitialFish >>>> Failed to put fish in cell with acceptable depth and velocity after %d attempts, for fish with length %f\nWill put fish in any cell with non-zero depth\n", counter, length);
                 fflush(0);
             //
             // So..., if we can't find a cell with BOTH non-zero depth and acceptable velocity
             // just find a cell with non-zero depth and put the fish in it...
             //
             //
			 for(counter=0; counter <= MAX_COUNT; counter++) 
				 {
				 randSelectedCell = [polyCellList atOffset: [randCellDist getIntegerSample]];

				 if(randSelectedCell != nil)
				 {
						 if([randSelectedCell getPolyCellDepth] > 0.0)
				 {
					[randSelectedCell addFish: newFish];
					numFish++;
					break;                      //break out of the for MAX_COUNT statement
				 }
				 }
				 else
				 {
					continue;
				 }

			 } //for MAX_COUNT
           }

	     if(counter >= MAX_COUNT)
             {
	         fprintf(stderr, "ERROR: TroutModelSwarm >>>> createInitialFish >>>> Failed to put fish in cell with non-zero depth after %d attempts\n", counter);
                 fflush(0);
                 exit(1);
             }

        }  //for
   }  // while

   if(!INIT_DATE_FOUND)
   {
        fprintf(stderr, "ERROR: TroutModelSwarm >>>> createInitialFish >>>> No fish were initialized; check the fish initialization\n" 
                                   "       dates in the \"Init Fish\" and the \"Model Setup\" or \n"
                                   "       \"Experiment Setup\" files\n");
        fflush(0);
        exit(1);

    }

  [lengthDist drop];

  if(randCellDist != nil)[randCellDist drop];

  [initPopLstNdx drop];

  //fprintf(stdout,"TroutModelSwarm >>>> createInitialFish >>>> END\n");
  //fflush(0);

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
   char aReach[35];
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
             fprintf(stderr, "ERROR: TroutModelSwarm >>>> readFishStockingRecords cannot open file %s \n", speciesSetup->stocking);
             fflush(0);
             exit(1);
       }
    

       fgets(header1,HCOMMENTLENGTH,stockFilePtr);
       fgets(header1,HCOMMENTLENGTH,stockFilePtr);
       fgets(header1,HCOMMENTLENGTH,stockFilePtr);

       while((fscanf(stockFilePtr, "%s%d%d%lf%lf%s", date,
                                                   &age,
                                                   &numOfFish,
                                                   &meanLength,
                                                   &stdDevLength,
						   aReach)) != EOF)
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
              
              fishStockRecord = (FishStockStruct *) [modelZone alloc: sizeof(FishStockStruct)];
                     
              fishStockRecord->fishStockTime = aStockTime;
	      fishStockRecord->speciesSymbol = speciesSetup->speciesSymbol;
              fishStockRecord->speciesNdx = speciesSetup->speciesIndex;
              fishStockRecord->age = age;
              fishStockRecord->numberOfFishThisAge = numOfFish;
              fishStockRecord->meanLength = meanLength;
              fishStockRecord->stdDevLength = stdDevLength;
              fishStockRecord->troutClass = speciesSetup->troutClass;
              fishStockRecord->fishParams = speciesSetup->fishParams;
	      strncpy(fishStockRecord->reach, aReach, 35);

	      //fprintf(stdout, "TroutModelSwarm >>>> readFishStockingRecords: ");
              //fprintf(stdout, "%s %d %d %f %f\n", date, age, numOfFish, meanLength, stdDevLength);
              //fflush(0);
	      //fprintf(stdout, "TroutModelSwarm >>>> readFishStockingRecords: ");
              //fprintf(stdout, "%ld %s %s %d %d %d %f %f \n", fishStockRecord->fishStockTime,
	                                                  //[fishStockRecord->speciesSymbol getName],
							  //[[fishStockRecord->fishParams getFishSpecies] getName],
                                                          //fishStockRecord->speciesNdx,
                                                          //fishStockRecord->age,
                                                          //fishStockRecord->numberOfFishThisAge,
                                                          //fishStockRecord->meanLength,
                                                          //fishStockRecord->stdDevLength);
              //fflush(0);

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

   id lengthNormalDist = nil;

   //int arraySize = [fishStockList getCount];
   //time_t nextTimeArray[arraySize];
   //int i = 0;

   id aHabitatSpace;
   id <List> polyCellList = nil;

   //fprintf(stdout, "TroutModelSwarm >>>> stock >>>> BEGIN\n");
   //fflush(0);

   if([fishStockList getCount] == 0) return self;


   listNdx = [fishStockList listBegin: scratchZone];

   [listNdx setLoc: Start];

   while(([listNdx getLoc] != End) && ((fishStockRecord = (FishStockStruct *) [listNdx next]) != (FishStockStruct *) nil))
   {

          //nextTimeArray[i++] = fishStockRecord->fishStockTime;
        
          if(fishStockRecord->fishStockTime == modelTime)
          {

                int fishNdx;
	       aHabitatSpace = nil;
	       aHabitatSpace = [habitatManager getReachWithName: fishStockRecord->reach];
		   //
		   // set up the distribution to draw fish lengths
		   //

		   lengthNormalDist = [NormalDist create: modelZone 
							  setGenerator: randGen];

		
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

	       /*
	       fprintf(stdout, "TroutModelSwarm >>>> stock: ");
                fprintf(stdout, "%ld %s %d %d %d %f %f \n", 
                                      fishStockRecord->fishStockTime,
	                              [fishStockRecord->speciesSymbol getName],
                                      fishStockRecord->speciesNdx,
                                      fishStockRecord->age,
                                      fishStockRecord->numberOfFishThisAge,
                                      fishStockRecord->meanLength,
                                      fishStockRecord->stdDevLength);
                fflush(0);
		*/
         

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
				// Calculate max swim speed, which depends on temperature, which it gets from cell
				   [newFish setMaxSwimSpeed: [newFish calcMaxSwimSpeedAt: [polyCellList getFirst]]];

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
		           fprintf(stderr, "ERROR: TroutModelSwarm >>>> stock >>>> Failed to put fish at cell >50 cm deep after %d attempts\n",counter);
                           fflush(0);
                           exit(1);
                      }
                }
          }
   }

   [listNdx drop];
   if(randCellDist != nil)[randCellDist drop];
   if(lengthNormalDist != nil)[lengthNormalDist drop];

   //
   // Now, get the next trout stocking time
   // We no longer need this because we check whether date = a stocking date
   // each day (to make yearshuffler work).
   // {

       // time_t smallestNextFishStockTime = runEndTime;

       // for(i = 0;i < arraySize; i++)
       // {

           // if(nextTimeArray[i] <= nextFishStockTime) continue;

           // smallestNextFishStockTime = (smallestNextFishStockTime < nextTimeArray[i]) ?
                                        // smallestNextFishStockTime : nextTimeArray[i];

 
       // }

       // nextFishStockTime = smallestNextFishStockTime;

   // }
           
   //fprintf(stdout, "TroutModelSwarm >>>> stock >>>> END\n");
   //fflush(0);

   return self;
}


///////////////////////////////////////
//
// readFishInitializationFiles
//
//////////////////////////////////////
- readFishInitializationFiles
{
  FILE * speciesPopFP=NULL;
  int numSpeciesNdx;
  char * header1=(char *) NULL;
  int prevAge = -1;
  char date[11];
  char prevDate[11];
  int age;
  int number;
  double meanLength;
  double stdDevLength;
  char reach[35];
  char prevReach[35];
  char inputString[400];
  char * token;
  char delimiters[5] = " \t\n,";

  int numRecords;
  int recordNdx;

  BOOL POPINITDATEOK = NO;

  //fprintf(stdout,"TroutModelSwarm >>>> readFishInitializationFiles >>>> BEGIN\n");
  //fflush(0);

  for(numSpeciesNdx=0; numSpeciesNdx<numberOfSpecies; numSpeciesNdx++)
  {
      if((speciesPopFP = fopen(speciesPopFile[numSpeciesNdx], "r")) == NULL) 
      {
          fprintf(stderr, "ERROR: TroutModelSwarm >>>> readFishInitializationFiles >>>> Error opening %s \n", speciesPopFile[numSpeciesNdx]);
          fflush(0);
          exit(1);
      }

      header1 = (char *)[scratchZone alloc: HCOMMENTLENGTH*sizeof(char)];

      fgets(header1,HCOMMENTLENGTH,speciesPopFP);
      fgets(header1,HCOMMENTLENGTH,speciesPopFP);
      fgets(header1,HCOMMENTLENGTH,speciesPopFP);

      strcpy(prevDate,"00/00/0000");
      strcpy(prevReach,"NOREACH");

      while(fgets(inputString,400,speciesPopFP) != NULL){
	token =  strtok(inputString,delimiters);
  	[HabitatSpace unQuote: token];
	if(token==NULL){
	  fprintf(stdout, "ERROR: TroutModelSwarm >>>> readFishInitializationFiles >>>> inputString: %s missing value where date expected\n", inputString);
          fflush(0);
	  exit(1);
	}
	strcpy(date,token);
	token =  strtok(NULL,delimiters);
  	[HabitatSpace unQuote: token];
	if(token==NULL){
	  fprintf(stdout, "ERROR: TroutModelSwarm >>>> readFishInitializationFiles >>>> inputString: %s missing value where age expected\n", inputString);
          fflush(0);
	  exit(1);
	}
	age = atoi(token);
	token =  strtok(NULL,delimiters);
  	[HabitatSpace unQuote: token];
	if(token==NULL){
	  fprintf(stdout, "ERROR: TroutModelSwarm >>>> readFishInitializationFiles >>>> inputString: %s missing value where number expected\n", inputString);
          fflush(0);
	  exit(1);
	}
	number = atoi(token);
	token =  strtok(NULL,delimiters);
  	[HabitatSpace unQuote: token];
	if(token==NULL){
	  fprintf(stdout, "ERROR: TroutModelSwarm >>>> readFishInitializationFiles >>>> inputString: %s missing value where mean length expected\n", inputString);
          fflush(0);
	  exit(1);
	}
	meanLength = atof(token);
	token =  strtok(NULL,delimiters);
  	[HabitatSpace unQuote: token];
	if(token==NULL){
	  fprintf(stdout, "ERROR: TroutModelSwarm >>>> readFishInitializationFiles >>>> inputString: %s missing value where std. dev. length expected\n", inputString);
          fflush(0);
	  exit(1);
	}
	stdDevLength = atof(token);
	token =  strtok(NULL,delimiters);
  	[HabitatSpace unQuote: token];
	if(token==NULL){
	  fprintf(stdout, "ERROR: TroutModelSwarm >>>> readFishInitializationFiles >>>> inputString: %s missing value where reach expected\n", inputString);
          fflush(0);
	  exit(1);
	}
	strcpy(reach,token);

           TroutInitializationRecord*  fishRecord;

           fishRecord = (TroutInitializationRecord *) [modelZone alloc: sizeof(TroutInitializationRecord)];

           if(strcmp(prevDate, "00/00/0000") == 0)
           {
              strcpy(prevDate, date);
           }
           if(strcmp(prevReach, "NOREACH") == 0)
           {
              strcpy(prevReach, reach);
           }

           fishRecord->speciesNdx = numSpeciesNdx;
           fishRecord->mySpecies = mySpecies[numSpeciesNdx];
           strncpy(fishRecord->date, date, 11);
           fishRecord->initTime = [timeManager getTimeTWithDate: date];
           if(fishRecord->initTime == popInitTime)
           {
               POPINITDATEOK = YES;
           }
           fishRecord->age = age;
           fishRecord->number = number;
           fishRecord->meanLength = meanLength;
           fishRecord->stdDevLength = stdDevLength;
           strcpy(fishRecord->reach, reach);
           
	   //fprintf(stdout, "TroutModelSwarm >>>> checking fish records >>>>>\n");
	   //fprintf(stdout, "speciesNdx = %d speciesName = %s date = %s initTime = %ld age = %d number = %d meanLength = %f stdDevLength = %f reach = %s popInitTime = %ld \n",
			   //fishRecord->speciesNdx,
			   //[fishRecord->mySpecies getName],
			   //fishRecord->date,
			   //(long) fishRecord->initTime,
			   //fishRecord->age,
			   //fishRecord->number,
			   //fishRecord->meanLength,
			   //fishRecord->stdDevLength,
			   //fishRecord->reach,
			   //(long) popInitTime);
	   //fflush(0);

          if(strcmp(prevReach, reach) == 0)
          {
              if(strcmp(prevDate, date) == 0)
              {
                  if(prevAge >= age) 
                  {
                     fprintf(stderr, "ERROR: TroutModelSwarm >>>> readFishInitializationFiles >>>> Check %s and ensure that fish ages are in increasing order\n",speciesPopFile[numSpeciesNdx]);
                     fflush(0);
                     exit(1);
                  }
 
                  prevAge = age;
              }
              else
              {
                 strcpy(prevDate, date);
                 prevAge = age;
              }
          }
          else
          {
               strcpy(prevReach, reach);
               prevAge = -1;
          }

          [fishInitializationRecords addLast: (void *) fishRecord];
      }

      if(POPINITDATEOK == NO)
      {
           fprintf(stderr, "ERROR: TroutModelSwarm >>>> readFishInitializationFiles >>>> popInitDate not found\n");
           fflush(0);
           exit(1);
      }

     prevAge = -1;

     fclose(speciesPopFP);
  } //for numberOfSpecies

  [scratchZone free: header1];

  numRecords = [fishInitializationRecords getCount];

  for(recordNdx = 0; recordNdx < numRecords; recordNdx++)
  {
       int chkRecordNdx; 

       TroutInitializationRecord* fishRecord = (TroutInitializationRecord *) [fishInitializationRecords atOffset: recordNdx]; 

       for(chkRecordNdx = 0; chkRecordNdx < numRecords; chkRecordNdx++)
       {
       
           TroutInitializationRecord* chkFishRecord = (TroutInitializationRecord *) [fishInitializationRecords atOffset: chkRecordNdx]; 

                   if(fishRecord == chkFishRecord)
                   {
                       continue;
                   }
                   else if(    (fishRecord->mySpecies == chkFishRecord->mySpecies)
                            && (strcmp(fishRecord->date, chkFishRecord->date) == 0) 
                            && (fishRecord->age == chkFishRecord->age)
                            && (strcmp(fishRecord->reach, chkFishRecord->reach) == 0))
                   {
                         fprintf(stderr, "\n\n");
                         fprintf(stderr, "ERROR: TroutModelSwarm >>>> readFishInitializationFiles\n");
                         fprintf(stderr, "ERROR: TroutModelSwarm >>>> readFishInitializationFiles >>>> Multiple records for the following record\n");
                         fprintf(stderr, "speciesName = %s date = %s age = %d number = %d  reach = %s\n",
                                       [fishRecord->mySpecies getName],
                                       fishRecord->date,
                                       fishRecord->age,
                                       fishRecord->number,
                                       fishRecord->reach);
                         fprintf(stderr, "ERROR: TroutModelSwarm >>>> readFishInitializationFiles\n");
                         fflush(0);
                         exit(1);
                   }

       }

       //fprintf(stdout, "speciesNdx = %d speciesName = %s date = %s initTime = %ld age = %d number = %d meanLength = %f stdDevLength = %f reach = %s\n",
                                       //fishRecord->speciesNdx,
                                       //[fishRecord->mySpecies getName],
                                       //fishRecord->date,
                                       //(long) fishRecord->initTime,
                                       //fishRecord->age,
                                       //fishRecord->number,
                                       //fishRecord->meanLength,
                                       //fishRecord->stdDevLength,
                                       //fishRecord->reach);
       //fflush(0);

   }
           

  //fprintf(stdout,"TroutModelSwarm >>>> readFishInitializationFiles >>>> END\n");
  //fflush(0);

  return self;
} 

//////////////////////////////////////////////////////////////////////
//
// buildActions
//
///////////////////////////////////////////////////////////////////////
- buildActions 
{
  [super buildActions];


  fprintf(stderr,"MODEL SWARM >>>> buildActions begin\n");
  fflush(0);

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

 fprintf(stderr,"MODEL SWARM >>>> buildActions returning\n");
 fflush(0);


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
  time_t newYearTime = (time_t) 0;

  BOOL moveFish = NO;
  id aHabitatSpace;

  //fprintf(stdout,"TroutModelSwarm >>>> step >>>> BEGIN\n");
  //fflush(0);

  //
  // First, advance the model clock by one hour
  // if isFirstStep is FALSE 
  // If it is midnight and we're shuffling years, check whether
  // it's time to jump to a new year
  //
  if(isFirstStep == TRUE)
  {
      numHoursSinceLastStep = 0;
  }
  else
  { 
     modelTime = [timeManager stepTimeWithControllerObject: self];
	 if(shuffleYears == YES && [timeManager getHourWithTimeT: modelTime] == 0)
	  {
			newYearTime = [yearShuffler checkForNewYearAt: modelTime];

          if(newYearTime != modelTime)
          {
              [timeManager setCurrentTime: newYearTime];
              modelTime = newYearTime;
          }
	  }

     strcpy(modelDate, [timeManager getDateWithTimeT: modelTime]);
     numHoursSinceLastStep++;
  }

  //fprintf(stdout,"TroutModelSwarm >>>> step >>>> Date: %s \n",modelDate);
  //fflush(0);
  //
  // Second, check to see if the fish should move. This habitat method
  // also updates model variables for whether it is daytime or night,
  // updates hourly flow, and updates daily habitat variables if the
  // current time is midnight.
  //

  id <ListIndex> lstNdx = nil;
  lstNdx = [reachList listBegin: scratchZone];

  while(([lstNdx getLoc] != End) && ((aHabitatSpace = (HabitatSpace *) [lstNdx next]) != (HabitatSpace *) nil)){
    if ([aHabitatSpace shouldFishMoveAt: modelTime])
	{
		moveFish = YES;  // Any reach can trigger movement
	}
    //fprintf(stdout,"TroutModelSwarm >>>> step >>>> shouldFishMove? %s \n",(moveFish ? "YES" : "NO") );
    //fflush(0);
  }

  //
  // Third, if it is midnight, call the method that updates
  // fish variables: age, time till next spawning period.
  // Update the logistic functions for Reproductive Maturity.
  // Write Limiting Factors Tool output if it's a census day
  if([timeManager getHourWithTimeT: modelTime] == 0)
  {
      [self updateFish];      //increments fish age if date is 1/1
      [self updateReproFuncs];
	  [self updateLFTOutput];
  }

  //
  // Fourth, simulate stocking of hatchery fish, if it is time.
  //
  if([timeManager getHourWithTimeT: modelTime] == 10)
  {
  //fprintf(stdout,"TroutModelSwarm >>>> step >>>> before stock\n");
  //fflush(0);
      [self stock];
  }

  //
  // Fifth, determine if it is the first hour of daytime,
  // if so, conduct trout spawning and and redd actions.
  // Also reset the fishs' daily total consumption to zero.
  //
  timeTillDaytimeStarts  = modelTime - [[reachList getFirst] getDaytimeStartTime];
 
  if((timeTillDaytimeStarts  >= (time_t) 0) && (timeTillDaytimeStarts < anHour))
  {
      [liveFish forEach: M(spawn)];
      [reddList forEach: M(survive)];
      [reddList forEach: M(develop)];
      [reddList forEach: M(emerge)];
      [self processEmptyReddList];

      [liveFish forEach: M(resetFishActualDailyIntake)];

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

  //fprintf(stdout,"TroutModelSwarm >>>> step >>>> before moveFish: %s \n", (moveFish==YES)?"YES":"NO");
  //fflush(0);
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
     // sort total population by length
     //
     [QSort sortObjectsIn:  liveFish];
     [QSort reverseOrderOf: liveFish];


     //[self printFishPopSummaryFile];

     //
     // Breakout report update
	 // Starting 8/29/2016, this is done only on first step of day
	 // unless fileOutputFrequency is 1
     //
     if(isFirstStep == FALSE)
     {
      //fprintf(stdout,"TroutModelSwarm >>>> step >>>> before breakout report\n");
      //fflush(0);
	  if(([timeManager getNumberOfDaysBetween: runStartTime and: modelTime] % fileOutputFrequency) == 0)
	   {
		   if((isFirstStepOfDay == TRUE) || (fileOutputFrequency == 1))
		   {
			[self outputBreakoutReport];
			isFirstStepOfDay = FALSE;
		   }
       }
	  else
	  {
		  isFirstStepOfDay = TRUE;
	  }
	 }

      //fprintf(stdout,"TroutModelSwarm >>>> step >>>> before update hab manager\n");
      //fflush(0);
     [habitatManager updateHabitatManagerWithTime: modelTime
                         andWithModelStartFlag: initialDay];


      //fprintf(stdout,"TroutModelSwarm >>>> step >>>> before toggle and move\n");
      //fflush(0);
     [self toggleFishForHabSurvUpdate];
     [liveFish forEach: M(move)];

	 // Added 16 Dec 2014 for new spawning habitat method
	 [liveFish forEach: M(checkSpawnCells)];

	 //Optional outputs -- Need to be after habitatManager update:
		if(writeCellFishReport == YES){
			[habitatManager outputCellFishInfoReport];
		}
     //
     // Finally, re-set the number of hours 
     // since last step.
     //
     numHoursSinceLastStep = 0;

	 // Output to terminal once per step
	fprintf(stdout,"Scenario: %d, Replicate: %d, Date: %s, Hour: %d, Live fish: %d\n", 
	scenario,replicate, [timeManager getDateWithTimeT: modelTime], 
	[timeManager getHourWithTimeT: modelTime], [liveFish getCount]);
	fflush(0);

  }    

  if(isFirstStep == TRUE)
  {
      isFirstStep = FALSE;
  }


  //[self     printZone: modelZone 
       //withPrintLevel: 1];

  //fprintf(stdout,"ModelSwarm >>>> step >>>> checkParam = %f\n\n", checkParam);

  //fprintf(stdout,"TroutModelSwarm >>>> step >>>> END\n");
  //fflush(0);

  return self;

}

///////////////////////////////////////
//
// printZone
// Commented out 4/29/2013 SFR
///////////////////////////////////////
/*
-           printZone:(id <Zone>) aZone 
       withPrintLevel: (int) level
{
   id <List> zonePopList = [aZone getPopulation];
   id <ListIndex> ndx = [zonePopList listBegin: scratchZone];
   id obj = nil;
   int printLevel = level;
 
   fprintf(stdout,"TroutModelSwarm >>>> printZones >>>> BEGIN >>>> aZone = %p level = %d\n", aZone, level);
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

          fprintf(stdout,"TroutModelSwarm >>>> printZones >>>> while >>>> obj = %p level = %d\n", obj, level);
          fprintf(stdout,"TroutModelSwarm >>>> printZones >>>> while >>>> aClassName = %s level = %d\n", aClassName, level);
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

   fprintf(stdout,"TroutModelSwarm >>>> printZones >>>> END >>>> aZone = %p level = %d\n", aZone, level);
   fflush(0);

   [ndx drop];

   return self;
}
*/
/////////////////////////////////////////////////////////
//
// toggleCellsColorRepIn
//
//////////////////////////////////////////////////////////
- toggleCellsColorRepIn: aHabitatSpace
{
      [habitatManager setShadeColorMax: shadeColorMax
                       inHabitatSpace:  aHabitatSpace];
      [habitatManager toggleCellsColorRepIn: aHabitatSpace];
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
    
     
    //fprintf(stdout, "TroutModelSwarm >>>> toggleFishForHabSurvUpdate >>>> BEGIN\n");
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
              //  fprintf(stdout, "TroutModelSwarm >>>> toggleFishForHabSurvUpdate >>>> length: %f\n",[fish getFishLength]);
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

   //fprintf(stdout, "TroutModelSwarm >>>> toggleFishForHabSurvUpdate >>>> END\n");
   //fflush(0);
    
   return self;
}



/////////////////////////////////////////////////////////
//
// addAFish
//
////////////////////////////////////////////////////////////
- addAFish: (Trout *) aTrout 
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
- addToKilledList: (Trout *) aFish 
{
  [deadFish addLast: aFish];
  [killedFish addLast: aFish];

  [self updateMortalityCountWith: aFish];

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
  BOOL STOP = NO;
  
     // fprintf(stdout,"TroutModelSwarm >>>> whenToStop >>>>\n");
     // fflush(stdout);

  if(simHourCounter >= (numSimDays * 24))  
  {
     STOP = YES;
	 [self writeLFTOutput];
     [self dropFishMortObjs];
	 
     #ifdef REDD_REPORT
        [self printReddReport];
     #endif

    if(writeReddSurvReport == YES){
      [self printReddSurvReport];
    }

     //fprintf(stdout,"TroutModelSwarm >>>> stop >>>>\n");
     //fflush(stdout);

  }
  else
  {
    STOP = NO;
    simHourCounter++;
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
     [InternalError raiseEvent: "ERROR: TroutModelSwarm >>>> getAgeSymbolForAge >>>> incorrect age %d\n", anAge];
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

    TroutMortalityCount* mortalityCount = nil;
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

        mortalityCount = [TroutMortalityCount createBegin: modelZone
                                       withMortality: mortSymbol];
        [listOfMortalityCounts addLast: mortalityCount];

        if(mortalityCountLstNdx != nil)
        {
            [mortalityCountLstNdx drop];
        }
        mortalityCountLstNdx = [listOfMortalityCounts listBegin: modelZone];
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

    //fprintf(stdout, "TroutModelSwarm >>>> getReachSymbolWithName >>>> BEGIN\n");
    //fflush(0);

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


    //fprintf(stdout, "TroutModelSwarm >>>> getReachSymbolWithName >>>> END\n");
    //fflush(0);

    return reachSymbol;
}


//////////////////////////////////////////////////////
//
// buildFishClass
//
/////////////////////////////////////////////////////
- buildFishClass 
{
   int i;

   MyTroutClass = (Class *) [modelZone alloc: numberOfSpecies*sizeof(Class)];

   speciesClassList = [List create: modelZone]; 

   for(i=0;i<numberOfSpecies;i++) 
   {
        if(objc_lookup_class(speciesName[i]) == Nil)
        {
            fprintf(stderr, "ERROR: TroutModelSwarm >>>> buildFishClass >>>> can't find class for %s\n", speciesName[i]);
            fflush(0);
            exit(1);
        }  

       MyTroutClass[i] = [objc_get_class(speciesName[i]) class];
       [speciesClassList addLast: MyTroutClass[i]];
   }

   return self;
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

/////////////////////////////////////////
//
// createCMaxInterpolators
//
/////////////////////////////////////////
- createCMaxInterpolators
{
  id <MapIndex> mapNdx;
  FishParams* fishParams;

  mapNdx = [fishParamsMap mapBegin: scratchZone];
 
  while(([mapNdx getLoc] != End) && ((fishParams = (FishParams *) [mapNdx next]) != nil))
  {
     id <InterpolationTableSD> cmaxInterpolationTable = [InterpolationTableSD create: modelZone];

     [cmaxInterpolationTable addX: fishParams->fishCmaxTempT1 Y: fishParams->fishCmaxTempF1];
     [cmaxInterpolationTable addX: fishParams->fishCmaxTempT2 Y: fishParams->fishCmaxTempF2];
     [cmaxInterpolationTable addX: fishParams->fishCmaxTempT3 Y: fishParams->fishCmaxTempF3];
     [cmaxInterpolationTable addX: fishParams->fishCmaxTempT4 Y: fishParams->fishCmaxTempF4];
     [cmaxInterpolationTable addX: fishParams->fishCmaxTempT5 Y: fishParams->fishCmaxTempF5];
     [cmaxInterpolationTable addX: fishParams->fishCmaxTempT6 Y: fishParams->fishCmaxTempF6];
     [cmaxInterpolationTable addX: fishParams->fishCmaxTempT7 Y: fishParams->fishCmaxTempF7];

     [cmaxInterpolatorMap at: [fishParams getFishSpecies] insert: cmaxInterpolationTable]; 
  }

  return self;
}

////////////////////////////////////////////////
//
// createSpawnDepthInterpolators
//
////////////////////////////////////////////////
- createSpawnDepthInterpolators
{
  id <Index> mapNdx;
  FishParams* fishParams;

  mapNdx = [fishParamsMap mapBegin: scratchZone];
 
  while(([mapNdx getLoc] != End) && ((fishParams = (FishParams *) [mapNdx next]) != nil))
  {
     id <InterpolationTableSD> spawnDepthInterpolationTable = [InterpolationTableSD create: modelZone];

     [spawnDepthInterpolationTable addX: fishParams->fishSpawnDSuitD1 Y: fishParams->fishSpawnDSuitS1];
     [spawnDepthInterpolationTable addX: fishParams->fishSpawnDSuitD2 Y: fishParams->fishSpawnDSuitS2];
     [spawnDepthInterpolationTable addX: fishParams->fishSpawnDSuitD3 Y: fishParams->fishSpawnDSuitS3];
     [spawnDepthInterpolationTable addX: fishParams->fishSpawnDSuitD4 Y: fishParams->fishSpawnDSuitS4];
     [spawnDepthInterpolationTable addX: fishParams->fishSpawnDSuitD5 Y: fishParams->fishSpawnDSuitS5];

     [spawnDepthInterpolatorMap at: [fishParams getFishSpecies] insert: spawnDepthInterpolationTable]; 
  }

  return self;
}


////////////////////////////////////////////
//
// createSpawnVelocityInterpolators
//
///////////////////////////////////////////
- createSpawnVelocityInterpolators
{
  id <Index> mapNdx;
  FishParams* fishParams;

  mapNdx = [fishParamsMap mapBegin: scratchZone];
 
  while(([mapNdx getLoc] != End) && ((fishParams = (FishParams *) [mapNdx next]) != nil))
  {
     id <InterpolationTableSD> spawnVelocityInterpolationTable = [InterpolationTableSD create: modelZone];

     [spawnVelocityInterpolationTable addX: fishParams->fishSpawnVSuitV1 Y: fishParams->fishSpawnVSuitS1];
     [spawnVelocityInterpolationTable addX: fishParams->fishSpawnVSuitV2 Y: fishParams->fishSpawnVSuitS2];
     [spawnVelocityInterpolationTable addX: fishParams->fishSpawnVSuitV3 Y: fishParams->fishSpawnVSuitS3];
     [spawnVelocityInterpolationTable addX: fishParams->fishSpawnVSuitV4 Y: fishParams->fishSpawnVSuitS4];
     [spawnVelocityInterpolationTable addX: fishParams->fishSpawnVSuitV5 Y: fishParams->fishSpawnVSuitS5];
     [spawnVelocityInterpolationTable addX: fishParams->fishSpawnVSuitV6 Y: fishParams->fishSpawnVSuitS6];

     [spawnVelocityInterpolatorMap at: [fishParams getFishSpecies] insert: spawnVelocityInterpolationTable]; 
  }

  return self;
}


//////////////////////////////////////////////////////
//
// createNewFishWithSpeciesIndex
//
/////////////////////////////////////////////////////
- (Trout *) createNewFishWithSpeciesIndex: (int) speciesNdx  
                                  Species: (id <Symbol>) species
                                      Age: (int) age
                                   Length: (double) fishLength 
{

  id newFish;
  id <Symbol> ageSymbol = nil;
  id <InterpolationTableSD> aCMaxInterpolator = nil;
  id <InterpolationTableSD> aSpawnDepthInterpolator = nil;
  id <InterpolationTableSD> aSpawnVelocityInterpolator = nil;
  LogisticFunc* aCaptureLogistic = nil;

  //fprintf(stdout, "TroutModelSwarm >>>> createNewFishWithSpeciesIndex >>>> BEGIN\n");
  //fflush(0);

  //
  // The newFish color is currently being set in the observer swarm
  //
  //fprintf(stdout, "TroutModelSwarm >>>> createNewFishWithSpeciesIndex >>>> fishParams >> fishSpecies %s species index %d arry len %d \n",[species getName], speciesNdx, numberOfSpecies);
  //fflush(0);

  newFish = [MyTroutClass[speciesNdx] createBegin: modelZone];

  [newFish setFishParams: [fishParamsMap at: species]];

  //
  // set properties of the new Trout
  //

  ((Trout *)newFish)->sex = ([coinFlip getCoinToss] == YES ?  Female : Male);

  //((Trout *)newFish)->randGen = randGen;


  [newFish setSpecies: species];
  [newFish setSpeciesNdx: speciesNdx];
  [newFish setAge: age];
  [newFish setHabitatManager: habitatManager];

  ageSymbol = [self getAgeSymbolForAge: age];
   
  [newFish setAgeSymbol: ageSymbol];

  [newFish setFishLength: fishLength];
  [newFish setFishCondition: 1.0];
  [newFish setFishWeightFromLength: fishLength andCondition: 1.0]; 
  //
  // Set time last spawned to modelTime - 5 years
  //
  [newFish setTimeTLastSpawned: (modelTime - (time_t) 157600000)];    

  [newFish calcStarvPaAndPb];

 // [newFish updateMaxSwimSpeed]; This is now done at createInitialFish because it depends on the cell

  [newFish calcMaxMoveDistance];

  [newFish updateNumHoursSinceLastStep: (void *) &numHoursSinceLastStep];

  if(fishColorMap != nil){
    //fprintf(stdout, "TroutModelSwarm >>>> createNewFishWithSpeciesIndex >>>> before setFishColor %s color %d \n",[[newFish getSpecies] getName], *((long *)[fishColorMap at: [newFish getSpecies]]));
    //fflush(0);
    [newFish setFishColor: (Color) *((long *) [fishColorMap at: [newFish getSpecies]])];
  }

  [newFish setTimeManager: timeManager];
  [newFish setModel: (id <TroutModelSwarm>) self];
  [newFish setRandGen: randGen];

  aCMaxInterpolator = [cmaxInterpolatorMap at: species];
  aSpawnDepthInterpolator = [spawnDepthInterpolatorMap at: species];
  aSpawnVelocityInterpolator = [spawnVelocityInterpolatorMap at: species];
   aCaptureLogistic = [captureLogisticMap at: species];
 
  [newFish setCMaxInterpolator: aCMaxInterpolator];
  [newFish setSpawnDepthInterpolator: aSpawnDepthInterpolator];
  [newFish setSpawnVelocityInterpolator: aSpawnVelocityInterpolator];
  [newFish setCaptureLogistic: aCaptureLogistic];
  
  [newFish resetFishActualDailyIntake];

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
- (Trout *) createNewFishWithFishParams: (FishParams *) aFishParams  
                         withTroutClass: (Class) aTroutClass
                                    Age: (int) age
                                 Length: (float) fishLength 
{
  id <Symbol> aSpecies;
  
   //
   // The newFish color is currently being set in the observer swarm
   //
   Trout* newFish = (Trout *) nil;

   //fprintf(stdout, "TroutModelSwarm >>>> createNewFishWithFishParams... >>>> BEGIN\n");
   //fflush(0);
   
   newFish = [aTroutClass createBegin: modelZone];

   // set properties of the new Trout

  ((Trout *)newFish)->sex = ([coinFlip getCoinToss] == YES ?  Female : Male);


  [newFish setFishParams: aFishParams];
  [newFish setModel: self];
  [newFish setRandGen: randGen];
  [newFish setScenario: scenario];
  [newFish setReplicate: replicate];
  [newFish setTimeManager: timeManager];
  [newFish setHabitatManager: habitatManager];

  if([aFishParams getFishSpecies] == nil)
  {
     fprintf(stderr, "TroutModelSwarm >>>> createNewFishWithFishParams >>>> species is nil\n");
     fflush(0);
     exit(1);
  }else{
     //fprintf(stdout, "TroutModelSwarm >>>> createNewFishWithFishParams >>>> species is %s \n",[[aFishParams getFishSpecies] getName]);
     //fflush(0);
  }

  aSpecies = [aFishParams getFishSpecies];
  [newFish setSpecies: aSpecies];
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
  [newFish setAgeSymbol: [self getAgeSymbolForAge: age]];

  [newFish setFishLength: fishLength];
  [newFish setFishCondition: 1.0];
  [newFish setFishWeightFromLength: fishLength andCondition: 1.0]; 

  //
  // Set time last spawned to modelTime - 5 years
  //
  [newFish setTimeTLastSpawned: (modelTime - (time_t) 157600000)];    

  //[newFish updateMaxSwimSpeed]; This must now be done later because it depends on the cell
  [newFish setCMaxInterpolator: [cmaxInterpolatorMap at: aSpecies]];
  [newFish setSpawnDepthInterpolator: [spawnDepthInterpolatorMap at: aSpecies]];
  [newFish setSpawnVelocityInterpolator: [spawnVelocityInterpolatorMap at: aSpecies]];
  [newFish setCaptureLogistic: [captureLogisticMap at: aSpecies]];
 
  [newFish resetFishActualDailyIntake];

  [newFish calcMaxMoveDistance];

  [newFish updateNumHoursSinceLastStep: (void *) &numHoursSinceLastStep];

  
  if(fishColorMap != nil)
  {
      [newFish setFishColor: *((long *) [fishColorMap at: [newFish getSpecies]])];
  }
 

  [newFish calcStarvPaAndPb];
  [newFish resetFishActualDailyIntake];
  fishCounter++;  // Give each fish a serial number ID
  [newFish setFishID: fishCounter];

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

  fprintf(stdout, "TroutModelSwarm >>>> readSpeciesSetup >>>> BEGIN\n");
  fflush(0);

  if(numberOfSpecies > 10)
  {
    fprintf(stderr,"ERROR: TroutModelSwarm >>>> readSpeciesSetupFile >>>> Too many species\n");
    fflush(0);
    exit(1);
  }

  if((speciesFP = fopen(speciesFile, "r")) == NULL ) 
  {
    fprintf(stderr,"ERROR: TroutModelSwarm >>>> readSpeciesSetupFile >>>>  unable to open %s\n", speciesFile);
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
	      //fprintf(stdout, "TroutModelSwarm >>>> readSpeciesSetup >>>> Myfiles are: %s %s %s %s \n", speciesName[speciesIDX],speciesParameter[speciesIDX], speciesPopFile[speciesIDX],speciesStocking[speciesIDX]);
	      //fflush(0);

         SpeciesSetup* speciesSetup = (SpeciesSetup *) [modelZone alloc: sizeof(SpeciesSetup)];
         speciesSetup->speciesSymbol = [Symbol create: modelZone
                                              setName: speciesName[speciesIDX]];
	 mySpecies[speciesIDX] = speciesSetup->speciesSymbol;
         speciesSetup->speciesIndex = speciesIDX;
         strncpy(speciesSetup->fishParamFile, speciesParameter[speciesIDX], 50);
         strncpy(speciesSetup->initPopFile, speciesPopFile[speciesIDX], 50);
         strncpy(speciesSetup->fishColor, speciesColor[speciesIDX], 25);
         strncpy(speciesSetup->stocking, speciesStocking[speciesIDX], 50);
         speciesSetup->troutClass = [objc_get_class(speciesName[speciesIDX]) class];

         [speciesSetupList addLast: (void *) speciesSetup];

         checkNumSpecies++;
	 //fprintf(stdout, "TroutModelSwarm >>>> readSpeciesSetup >>>> speciesSymbol %s \n", [speciesSetup->speciesSymbol getName]);
	 //fflush(0);
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
      fprintf(stderr, "ERROR: TroutModelSwarm >>>> printReddReport >>>> Couldn't open %s\n", reddMortalityFile);
      fflush(0);
      exit(1);
   }

   if([removedRedds getCount] > 0) 
   {
      reddListNdx = [removedRedds listBegin: scratchZone];

      while(([reddListNdx getLoc] != End) && ( (redd = [reddListNdx next]) != nil ) ) 
      {
         [redd printReport];
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


/////////////////////////////////////////////////
//
// openIndividualFishReportFilePtr
//
//////////////////////////////////////////////////
- openIndividualFishReportFilePtr {
  if(individualFishFilePtr == NULL){
     if ((appendFiles == NO) && (scenario == 1) && (replicate == 1)){
        if((individualFishFilePtr = fopen(individualFishFile,"w")) == NULL ) {
            fprintf(stderr, "ERROR: TroutModelSwarm >>>> openIndividualFishReportFilePtr >>>> Cannot open %s for writing\n",individualFishFile);
            fflush(0);
            exit(1);
        }
        fprintf(individualFishFilePtr,"\n\n");
        fprintf(individualFishFilePtr,"SYSTEM TIME:  %s\n", [timeManager getSystemDateAndTime]);
        fprintf(individualFishFilePtr,"Scenario,Replicate,Model Date,Hour,Fish ID,Reach,Cell #,Species,Age,Length,Weight,Condition\n");
     }else if((scenario == 1) && (replicate == 1) && (appendFiles == YES)){
        if((individualFishFilePtr = fopen(individualFishFile,"a")) == NULL){
            fprintf(stderr, "ERROR: TroutModelSwarm >>>> openIndividualFishReportFilePtr >>>> Cannot open %s for writing\n",individualFishFile);
            fflush(0);
            exit(1);
        }
        fprintf(individualFishFilePtr,"\n\n");
        fprintf(individualFishFilePtr,"SYSTEM TIME:  %s\n", [timeManager getSystemDateAndTime]);
        fprintf(individualFishFilePtr,"Scenario,Replicate,Model Date,Hour,Fish ID,Reach,Cell #,Species,Age,Length,Weight,Condition\n");
     }else{ // Not the first replicate or scenario, so no header 
         if((individualFishFilePtr = fopen(individualFishFile,"a")) == NULL){
            fprintf(stderr, "ERROR: TroutModelSwarm >>>> openIndividualFishReportFilePtr >>>> Cannot open %s for appending\n",individualFishFile);
            fflush(0);
            exit(1);
         }
     }
  }
  if(individualFishFilePtr == NULL){
     fprintf(stderr, "ERROR: TroutModelSwarm >>>> openIndividualFishReportFilePtr >>>> File %s is not open\n",individualFishFile);
     fflush(0);
     exit(1);
  }
  return self;
}
//////////////////////////////////////////////////////////
////
//// printIndividualFishReport
////
///////////////////////////////////////////////////////////
- printIndividualFishReport { 
  id <ListIndex> fishListNdx;
  id aFish;
  int theHour = [timeManager getHourWithTimeT: modelTime];

  if((individualFishFilePtr = fopen(individualFishFile,"a")) != NULL) {
    if([liveFish getCount] != 0) {
      fishListNdx = [liveFish listBegin: modelZone];

      while(([fishListNdx getLoc] != End) && ((aFish = [fishListNdx next]) != nil)){
	fprintf(individualFishFilePtr,"%d,%d,%s,%d,%d,%s,%d,%s,%d,%f,%f,%f\n",
	    scenario,
	    replicate,
	    modelDate,
		theHour,
	    [aFish getFishID],
	    [[aFish getReachSymbol] getName],
	    [[aFish getCell] getPolyCellNumber], 
	    [[aFish getSpecies] getName],
	    [aFish getAge],
	    [aFish getFishLength],
	    [aFish getFishWeight],
	    [aFish getFishCondition]);
      }
      [fishListNdx drop];
    }
  } else {
    fprintf(stderr, "ERROR: TroutModelSwarm >>>> printIndividualFishReport >>>> Couldn't open output file\n");
    fflush(0);
    exit(1);
  }
  fclose(individualFishFilePtr);
  return self;
}


//////////////////////////////////////////////////////////
//
// printReddSurvReport
//
/////////////////////////////////////////////////////////
- printReddSurvReport { 
    FILE *printRptPtr=NULL;
    const char * reddSurvFile = "Redd_Survival_Test_Out.csv";
    id <ListIndex> reddListNdx;
    id redd;

    if((printRptPtr = fopen(reddSurvFile,"w+")) != NULL){
        if([[self getReddRemovedList] getCount] != 0){
            reddListNdx = [removedRedds listBegin: modelZone];

            while(([reddListNdx getLoc] != End) && ((redd = [reddListNdx next]) != nil)){
               [redd printReddSurvReport: printRptPtr];
            }
            [reddListNdx drop];
        }
   }else{
       fprintf(stderr, "ERROR: TroutModelSwarm >>>> printReddSurvReport >>>> Couldn't open %s\n", reddSurvFile);
       fflush(0);
       exit(1);
   }
   fclose(printRptPtr);
   return self;
}


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
             fprintf(stderr, "ERROR: TroutModelSwarm >>>> openReddReportFilePtr >>>> Cannot open %s for writing\n", reddMortalityFile);
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
             fprintf(stderr, "ERROR: TroutModelSwarm >>>> openReddReportFilePtr >>>> Cannot open %s for writing\n", reddMortalityFile);
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
             fprintf(stderr, "ERROR: TroutModelSwarm >>>> openReddReportFilePtr >>>> Cannot open %s for writing\n", reddMortalityFile);
             fflush(0);
             exit(1);
         }
     }
  }

   if(reddRptFilePtr == NULL)
   {
        fprintf(stderr, "ERROR: TroutModelSwarm >>>> openReddReportFilePtr >>>> Cannot open %s for writing\n", reddMortalityFile);
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
       fprintf(stderr, "ERROR: TroutModelSwarm >>>> getReddReportFilePtr >>>> File %s is not open\n", reddMortalityFile);
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
- openReddSummaryFilePtr {

  if(reddSummaryFilePtr == NULL) {
     if((appendFiles == NO)  && (scenario == 1) && (replicate == 1)){
        if((reddSummaryFilePtr = fopen(reddOutputFile,"w")) == NULL){
             fprintf(stderr, "ERROR: TroutModelSwarm >>>> openReddSummaryFilePtr >>>> Cannot open %s for writing\n", reddOutputFile);
             fflush(0);
             exit(1);
        }
        fprintf(reddSummaryFilePtr,"\n");
        fprintf(reddSummaryFilePtr,"SYSTEM TIME:  %s\n", [timeManager getSystemDateAndTime]);
        fprintf(reddSummaryFilePtr,"%s", "Scenario,Replicate,ReddID,Species,CellNo,CreateDate,InitialNumberOfEggs,EmptyDate,Dewatering,Scouring,LowTemp,HiTemp,Superimp,FryEmerged\n"); 
     }else if((scenario == 1) && (replicate == 1) && (appendFiles == YES)){
        if((reddSummaryFilePtr = fopen(reddOutputFile,"w")) == NULL){
             fprintf(stderr, "ERROR: TroutModelSwarm >>>>> openReddSummaryFilePtr >>>> Cannot open %s for writing\n",reddOutputFile);
             fflush(0);
             exit(1);
        }
        fprintf(reddSummaryFilePtr,"\n");
        fprintf(reddSummaryFilePtr,"SYSTEM TIME:  %s\n", [timeManager getSystemDateAndTime]);
        fprintf(reddSummaryFilePtr,"%s", "Scenario,Replicate,ReddID,Species,CellNo,CreateDate,InitialNumberOfEggs,EmptyDate,Dewatering,Scouring,LowTemp,HiTemp,Superimp,FryEmerged"); 
     }else {
         if((reddSummaryFilePtr = fopen(reddOutputFile,"a")) == NULL) {
             fprintf(stderr, "ERROR: TroutModelSwarm >>>> openReddSummaryFilePtr >>>> Cannot open %s for appending\n",reddOutputFile);
             fflush(0);
             exit(1);
         }
     }
   }
   if(reddSummaryFilePtr == NULL){
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
      fprintf(stdout, "TroutModelSwarm >>>> createBreakoutReporters >>>> BEGIN\n");
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

      //fprintf(stdout, "TroutModelSwarm >>>> createBreakoutReporters >>>> after create begin mortality \n");
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

  [fishMortalityReporter addColumnWithValueFromSelector: @selector(getModelHour)
                                        fromObject: (id) self
                                          withType: "long"
                                         withLabel: "ModelHour"];

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

      //fprintf(stdout, "TroutModelSwarm >>>> createBreakoutReporters >>>> after mortality rep\n");
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

  [liveFishReporter addColumnWithValueFromSelector: @selector(getModelHour)
                                        fromObject: (id) self
                                          withType: "long"
                                         withLabel: "ModelHour"];

  [liveFishReporter addColumnWithValueOfVariable: "currentPhase"
                                      fromObject: (id) [reachList getFirst]
                                        withType: "int" 
                                       withLabel: "PhaseOfPrevStep"];

  [liveFishReporter addColumnWithValueOfVariable: "numHoursSinceLastStep"
                                      fromObject: (id) self
                                        withType: "int" 
                                       withLabel: "HoursInPrevStep"];

  [liveFishReporter addColumnWithValueOfVariable: "currentHourlyFlow"
                                      fromObject: (id) [reachList getFirst]
                                        withType: "double" 
                                       withLabel: "FlowIn1stReach"];

  [liveFishReporter addColumnWithValueOfVariable: "temperature"
                                      fromObject: (id) [reachList getFirst]
                                        withType: "double" 
                                       withLabel: "TemperatureIn1stReach"];
 
  [liveFishReporter breakOutUsingSelector: @selector(getReachSymbol)
                           withListOfKeys: reachSymbolList];

  [liveFishReporter breakOutUsingSelector: @selector(getSpecies)
                           withListOfKeys: speciesSymbolList];

  [liveFishReporter breakOutUsingSelector: @selector(getAgeSymbol)
                           withListOfKeys: ageSymbolList];

  [liveFishReporter createOutputWithLabel: "Count"
                             withSelector: @selector(getFishCount)
                         withAveragerType: "Count"];

  [liveFishReporter createOutputWithLabel: "FractionFeedingPrevStep"
                             withSelector: @selector(getIsFishFeeding)
                         withAveragerType: "Average"];

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

      fprintf(stdout, "TroutModelSwarm >>>> createBreakoutReporters >>>> END\n");
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

   if(writeIndividualFishReport == YES){
      [self printIndividualFishReport];
   }

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
          inHabitatSpace: aHabitatSpace
{
    shadeColorMax = aShadeColorMax;
    [habitatManager setShadeColorMax: shadeColorMax
                      inHabitatSpace: aHabitatSpace];
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

- (HabitatManager *) getHabitatManager{
  return habitatManager;
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

///////////////////////////////////////////////
//
// updateLFTOutput
//
///////////////////////////////////////////////

- updateLFTOutput{
  // First determine if the current day is a census day
  if([timeManager isThisTime: modelTime onThisDay: resultsCensusDay] && !([timeManager getTimeTWithDate: runStartDate] == modelTime)){
    //
    //fprintf(stdout, "TroutModelSwarm >>>> writeLFTOutput >>>> Current day %s, Census day %s, runStartDate %s \n",[timeManager getDateWithTimeT: modelTime],resultsCensusDay,runStartDate);
    //fflush(0);

    id <ListIndex> liveFishNdx;
    id nextLiveFish = nil;

    liveFishNdx = [liveFish listBegin: scratchZone];
    while (([liveFishNdx getLoc] != End) && ((nextLiveFish = [liveFishNdx next]) != nil)){
        if([nextLiveFish getAge] >= resultsAgeThreshold){
	  lftNumAdultTrout = lftNumAdultTrout + 1.0;
	  lftBiomassAdultTrout = lftBiomassAdultTrout + [nextLiveFish getFishWeight];
        }
     }
    [liveFishNdx drop];
    lftNumCensusDays++;	
  }
    return self;
}

///////////////////////////////////////////////
//
// writeLFTOutput
//
///////////////////////////////////////////////

- writeLFTOutput{
  const char * lftOutputFile = "LFT_Output.rpt";
  double meanNumAdults, meanBiomass;

  if(lftOutputFilePtr == NULL) {
     if ((scenario == 1) && (replicate == 1)){
        if((lftOutputFilePtr = fopen(lftOutputFile,"w")) == NULL ){
            fprintf(stderr, "ERROR: TroutModelSwarm >>>> writeLFTOutput >>>> Cannot open %s for writing\n",lftOutputFile);
            fflush(0);
            exit(1);
        }
        fprintf(lftOutputFilePtr,"Limiting factors tool output file\n");
        fprintf(lftOutputFilePtr,"SYSTEM TIME:  %s\n", [timeManager getSystemDateAndTime]);
        fprintf(lftOutputFilePtr,"Scenario,Replicate,Census Date,Mean Number of Adults,Mean Biomass of All Adults\n");
     }else{ // Not the first replicate or scenario, so no header 
         if((lftOutputFilePtr = fopen(lftOutputFile,"a")) == NULL){
            fprintf(stderr, "ERROR: TroutModelSwarm >>>> writeLFTOutput >>>> Cannot open %s for appending\n",lftOutputFile);
            fflush(0);
            exit(1);
         }
     }
  }
  if(lftOutputFilePtr == NULL){
      fprintf(stderr, "ERROR: TroutModelSwarm >>>> writeLFTOutput >>>> File %s is not open\n",lftOutputFile);
      fflush(0);
      exit(1);
  }
  if(lftNumCensusDays <= 0){
    meanNumAdults = -9999.0;
    meanBiomass = -9999.0;
  }else{
    meanNumAdults = lftNumAdultTrout / lftNumCensusDays;
    meanBiomass = lftBiomassAdultTrout / lftNumCensusDays;
  }
  fprintf(lftOutputFilePtr,"%d\t%d\t%s\t%f\t%f\n", 
    scenario, 
    replicate, 
    resultsCensusDay,
    meanNumAdults,
    meanBiomass);
  return self;
}



//////////////////////////////////////////////////////////
//
// drop
//
//////////////////////////////////////////////////////////
- (void) drop
{
  //id <ListIndex> ndx;
  //id species=nil;
  //FILE* aStream=NULL;

  fprintf(stdout, "TroutModelSwarm >>>> drop >>>> BEGIN\n");
  fflush(0);

  // ndx = [speciesSymbolList listBegin: scratchZone];
  // while(([ndx getLoc] != End) && (( species = [ndx next]) != nil))
  // {
     // if(speciesDepthUseOutStreamMap != nil)
     // {
	 // if((aStream = (FILE *) [speciesDepthUseOutStreamMap at: species]) != NULL)  fclose(aStream);
     // }
     // if(speciesVelocityUseOutStreamMap != nil)
     // {
	 // if((aStream = (FILE *) [speciesVelocityUseOutStreamMap at: species]) != NULL)  fclose(aStream);
     // }
  // }
 
  // [ndx drop];


  if(lftOutputFilePtr != NULL){
      fclose(lftOutputFilePtr);
  }
  if(reddSummaryFilePtr != NULL){
      fclose(reddSummaryFilePtr);
  }
  if(reddRptFilePtr != NULL){
      fclose(reddRptFilePtr);
  }

  if(timeManager){
      [timeManager drop];
      timeManager = nil;
  }

  if(fishColorMap)
  {
       id <MapIndex> mapNdx = [fishColorMap mapBegin: scratchZone];
       long* aFishColor = (long *) nil;
 
       while(([mapNdx getLoc] != End) && ((aFishColor = (long *) [mapNdx next]) != (long *) nil))
       {
            [modelZone free: aFishColor];
       }

       [mapNdx drop];
       [fishColorMap drop];
   }

  //if(moveFishReporter != nil)
  //{
     //[moveFishReporter drop];
  //}

  if(randGen){
      [randGen drop]; 
      randGen = nil;
  }

  if(coinFlip){
   [coinFlip drop];
   coinFlip = nil;
  }

  // New stuff copied from instream-5 5/8/2013
  if(modelZone != nil){
      int speciesIDX = 0;
 
//  Don't try "reachList deleteAll" before this!
      if(habitatManager){
          [habitatManager drop];
          habitatManager = nil;
      }

  [modelZone free: mySpecies];
  [modelZone freeBlock: modelDate blockSize: 15*sizeof(char)];

      for(speciesIDX=0;speciesIDX<numberOfSpecies;speciesIDX++) {
          [modelZone free: speciesName[speciesIDX]];
          [modelZone free: speciesParameter[speciesIDX]];
          [modelZone free: speciesPopFile[speciesIDX]];
          [modelZone free: speciesColor[speciesIDX]];
      }

      [modelZone free: speciesName];
      [modelZone free: speciesParameter];
      [modelZone free: speciesPopFile];
      [modelZone free: speciesColor];

      [modelZone free: MyTroutClass];

      //
      // drop interpolation tables
      //
    [spawnVelocityInterpolatorMap deleteAll];
    [spawnVelocityInterpolatorMap drop];
    spawnVelocityInterpolatorMap = nil;
    [spawnDepthInterpolatorMap deleteAll];
    [spawnDepthInterpolatorMap drop];
    spawnDepthInterpolatorMap = nil;
    [cmaxInterpolatorMap deleteAll];
    [cmaxInterpolatorMap drop];
    cmaxInterpolatorMap = nil;
     //
     // End drop interpolation tables
     //
     // drop capture logistics
     //
    [captureLogisticMap deleteAll];
    [captureLogisticMap drop];
    captureLogisticMap = nil;
     //
     // drop capture logistics
     //

    [reproLogisticFuncMap deleteAll];
    [reproLogisticFuncMap drop];
    reproLogisticFuncMap = nil;

  //  [deathMap deleteAll]; The structures on this list do not 
  //  respond to "drop", which deleteAll tries to execute
    [deathMap drop];
    deathMap = nil;

	[mortalityCountLstNdx drop];
     mortalityCountLstNdx = nil;
  
     [listOfMortalityCounts deleteAll];
     [listOfMortalityCounts drop];
      listOfMortalityCounts = nil; 

     [liveFish deleteAll];
     [liveFish drop];
     liveFish = nil;
	 
     [modelActions drop];
     modelActions = nil;

     [modelSchedule drop];
     modelSchedule = nil;
      
     [reddBinomialDist drop];
     reddBinomialDist = nil;
        
     [deadFish deleteAll];
     [deadFish drop];
     deadFish = nil;

     [killedFish deleteAll];
     [killedFish drop];
     killedFish = nil;

     //[fishStockList deleteAll]; can't drop these
     [fishStockList drop];
     fishStockList = nil;

     [reddList deleteAll];
     [reddList drop];
     reddList = nil;

     [emptyReddList deleteAll];
     [emptyReddList drop];
     emptyReddList = nil;

     [removedRedds deleteAll];
     [removedRedds drop];
     removedRedds = nil;

     [killedRedds deleteAll];
     [killedRedds drop];
     killedRedds = nil;

     [deadRedds deleteAll];
     [deadRedds drop];
     deadRedds = nil;

     //[speciesSetupList deleteAll]; Can't drop these
     [speciesSetupList drop];
     speciesSetupList = nil;
     [speciesClassList drop];
     speciesClassList = nil;
     [fishInitializationRecords drop];
     fishInitializationRecords = nil;

     [speciesSymbolList deleteAll];
     [speciesSymbolList drop];
     speciesSymbolList = nil;

//     [reachList deleteAll];
//     [reachList drop];
     reachList = nil;

     [reachSymbolList deleteAll];
     [reachSymbolList drop];
     reachSymbolList = nil;

     [fishMortSymbolList deleteAll];
     [fishMortSymbolList drop];
     fishMortSymbolList = nil;

     [reddMortSymbolList deleteAll];
     [reddMortSymbolList drop];
     reddMortSymbolList = nil;

     [ageSymbolList deleteAll];
     [ageSymbolList drop];
     ageSymbolList = nil;

     [fishActivitySymbolList deleteAll];
     [fishActivitySymbolList drop];
     fishActivitySymbolList = nil;

	   //[Male drop];
     Male = nil;
     //[Female drop];
     Female = nil;

     if(yearShuffler != nil){
          [yearShuffler drop];
          yearShuffler = nil;
     }

     [fishMortalityReporter drop];
     fishMortalityReporter = nil;

     [liveFishReporter drop];
     liveFishReporter = nil;

     //
     // Drop the fishParams
     //
    [fishParamsMap deleteAll];
    [fishParamsMap drop];
    fishParamsMap = nil;



 //    [self outputModelZone: modelZone];

     [modelZone drop];
     modelZone = nil;

//     fprintf(stdout, "TroutModelSwarm >>>> drop >>>> dropping modelZone >>>> END\n");
//     fflush(0);
  }
  

/*  
	 [reddBinomialDist drop];
	 reddBinomialDist = nil;
        
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
  [speciesClassList drop];

  [modelZone freeBlock: modelDate blockSize: 15*sizeof(char)];

  if(modelZone != nil)
  {
      //[self     printZone: modelZone 
           //withPrintLevel: 1];
      [modelZone drop];
      modelZone = nil;
  }
*/  
  [super drop];

  fprintf(stdout, "TroutModelSwarm >>>> drop >>>> END\n");
  fflush(0);

} //drop




@end



