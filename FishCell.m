//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 

#import "HabitatSpace.h"
#import "UTMTroutModelSwarm.h"
#import "UTMTrout.h"
#import "UTMRedd.h"

#import "globals.h"

#import "FishCell.h"

@implementation FishCell

+ create: aZone 
{
  FishCell* fishCell = [super create: aZone];

  fishCell->fishList = [List create: fishCell->cellZone];
  fishCell->reddList = [List create: fishCell->cellZone];
  fishCell->cellDataSet = NO;
  fishCell->numberOfFish = 0;
  return fishCell;
}


/////////////////////////////////////////////////////////////////////
//
// setSpace
//
////////////////////////////////////////////////////////////////////
- setSpace: aSpace 
{
  space = aSpace;
  return self;
}


//////////////////////////////////////////////
//
// getSpace
//
/////////////////////////////////////////////
- getSpace
{
    return space;
}

////////////////////////////////////////////////
//
// setModelSwarm
//
////////////////////////////////////////////////
- setModelSwarm: aModelSwarm
{
   modelSwarm = aModelSwarm;
   return self;
}


/////////////////////////////////////////////
//
// setTimeManager
//
///////////////////////////////////////////
- setTimeManager: aTimeManager
{
    timeManager = aTimeManager;
    return self;
}

- setNumberOfSpecies: (int) aNumber
{
    numberOfSpecies = aNumber;
    return self;
}


////////////////////////////////
//
// setFishParamsMap
//
///////////////////////////////
- setFishParamsMap: aMap
{
    fishParamsMap = aMap;
    return self;
}


/////////////////////////////////
//
// setRandGen
//
/////////////////////////////////
- setRandGen: aRandGen
{
    randGen = aRandGen;
    return self;
}

///////////////////////////////////////
//
// getRandGen
//
// This is used by the super imposition function
// in the survival manager
//
///////////////////////////////////////
- getRandGen
{
   return randGen;
}



/////////////////////////////
//
// addFish
//
/////////////////////////////
- addFish: aFish
{
   [fishList addLast: aFish];
   numberOfFish = [fishList getCount];
   return self;
}

- removeFish: aFish
{
   [fishList remove: aFish];
   numberOfFish = [fishList getCount];
   return self;
}

- (id <List>) getFishList
{
   return fishList;
}

///////////////////////////////////////////////
//
// getNeighborsWithin
//
//////////////////////////////////////////////
- getNeighborsWithin: (double) aRange 
            withList: (id <List>) aCellList
{
  //fprintf(stdout, "FishCell >>>> getNeighborsWithin >>>> BEGIN\n");
  //fflush(0);

  [space getNeighborsWithin: aRange 
                         of: self
                   withList: aCellList];

  //fprintf(stdout, "FishCell >>>> getNeighborsWithin >>>> END\n");
  //fflush(0);

  return self;
}



///////////////////////////////////////////////////////////////
//
// getListOfAdjacentCells
//
// listOfAdjacentCells belongs to super
//
//////////////////////////////////////////////////////////////
- (id <List>) getListOfAdjacentCells 
{
   return listOfAdjacentCells;
}



////////////////////////////////
//
// getDistanceTo
//
///////////////////////////////
- (double) getDistanceTo: aCell
{
   double distance  = 0.0;
   double distanceX = 0.0;
   double distanceY = 0.0;
  
   if(aCell != self)
   {
       distanceX =  utmCenterX - [aCell getUTMCenterX];
       distanceY =  utmCenterY - [aCell getUTMCenterY];
       distance = distanceX*distanceX + distanceY*distanceY;
       distance = sqrt(distance);
   }
   else
   {
      distance = 0.0;
   }
  
   /*
   fprintf(stdout, "FishCell >>>> getDistanceTo >>>> utmCenterX = %f [aCell getUTMCenterX] = %f\n", utmCenterX, [aCell getUTMCenterX]);
   fprintf(stdout, "FishCell >>>> getDistanceTo >>>> utmCenterY = %f [aCell getUTMCenterY] = %f\n", utmCenterY, [aCell getUTMCenterY]);
   fprintf(stdout, "FishCell >>>> getDistanceTo >>>> distanceX = %f\n", distanceX);
   fprintf(stdout, "FishCell >>>> getDistanceTo >>>> distanceY = %f\n", distanceY);
   fprintf(stdout, "FishCell >>>> getDistanceTo >>>> distance = %f\n", distance);
   fflush(0);
   */
   	
   return distance;
}





/////////////////////////////////////
//
// resetShelterAreaAvailable
//
////////////////////////////////////////
- (void) resetShelterAreaAvailable 
{
   shelterAreaAvailable = cellShelterArea;
 
   if(shelterAreaAvailable > 0.0)
   {
       isShelterAvailable = YES;
   }
   else
   {
       isShelterAvailable = NO;
   }
}


//////////////////////////////////
//
// getIsShelterAvailable
//
//////////////////////////////////
- (BOOL) getIsShelterAvailable
{
      return isShelterAvailable;
}




////////////////////////////////////////////////////////
//
// setDistanceToHide
//
///////////////////////////////////////////////////////
- setDistanceToHide: (double) aDistance 
{
  cellDistToHide = aDistance;
  return self;
}


//////////////////////////////////////////////////////
//
// getDistanceToHide
//
/////////////////////////////////////////////////////
- (double) getDistanceToHide 
{
   return cellDistToHide;
}


////////////////////////////////////////////////////////////
//
// calcDailyMeanDepthAndVelocityFor 
//
////////////////////////////////////////////////////////////
- calcDailyMeanDepthAndVelocityFor: (double) aMeanFlow
{
    meanDepth    = [depthInterpolator getValueFor: aMeanFlow];
   
    if(meanDepth < 0.0)
    {
       meanDepth = 0.0;
    }

    meanVelocity = [velocityInterpolator getValueFor: aMeanFlow];
   

    //fprintf(stdout, "FishCell >>>> calcDailyMean .... meanDepth = %f\n", meanDepth);
    //fprintf(stdout, "FishCell >>>> calcDailyMean .... meanVelocity = %f\n", meanVelocity);
    //fflush(0);
 
    return self;
}

/////////////////////////////////////
//
// isDryAtDailyMeanFlow
//
/////////////////////////////////////
- (BOOL) isDryAtDailyMeanFlow
{
   BOOL isDry = NO;

   if(meanDepth <= 0.0)
   {
      isDry = YES;
   }

   return isDry;
}


///////////////////////////////
//
// setCellDataSet
//
//////////////////////////////
- setCellDataSet: (BOOL) aBool
{
    cellDataSet = aBool;
    return self;
}

////////////////////////////
//
// getCellDataSet
//
/////////////////////////////
- checkCellDataSet
{
    if(cellDataSet != YES)
    {
       fprintf(stderr, "ERROR: FishCell >>>> checkCellDataSet >>>> cell data has not been set for fishCell = %d\n", utmCellNumber);
       fflush(0);
       exit(1);
    }


    return self;
}

////////////////////////////////////////////////
//
// initializeSurvProb
//
////////////////////////////////////////////////
- initializeSurvProb 
{
  id <MapIndex> fpNdx = nil;
  FishParams* fishParams = (FishParams *) nil;

  //fprintf(stdout, "Cell >>>> initializeSurvProb >>>> BEGIN\n");
  //fflush(0);

  fpNdx = [fishParamsMap mapBegin: scratchZone];

  survMgrMap = [Map create: cellZone];
  survMgrReddMap = [Map create: cellZone];

  while(([fpNdx getLoc] != End) && ((fishParams = (FishParams *) [fpNdx next]) != (FishParams *) nil))
  {
     id <SurvMGR> survMgr;
     id <Symbol> species = [fishParams getFishSpecies];
     survMgr = [SurvMGR     createBegin: cellZone
                      withHabitatObject: self];

     [survMgrMap at: species  insert: survMgr];

     ANIMAL = [survMgr getANIMALSYMBOL];
     HABITAT = [survMgr getHABITATSYMBOL];
 

     //
     // Velocity survival
     //

     // Please note -- IF the formulation for high velocity mortality is changed,
     //                corresponding changes are needed in [trout moveToMaximizeExpectedMaturity]
     //                for separating "good" and "bad" destination cells, and for
     //                deciding whether to calculate EM for "bad" destination cells.
     //

     [survMgr addPROBWithSymbol: [modelSwarm getFishMortalitySymbolWithName: "Velocity"]
             withType: "LimitingFunctionProb"
       withAgentKnows: YES
      withIsStarvProb: NO];


     [survMgr addLogisticFuncToProbWithSymbol:  [modelSwarm getFishMortalitySymbolWithName: "Velocity"]
            withInputObjectType: ANIMAL
                 withInputSelector: M(getSwimSpdVelocityRatio)
                     withXValue1: fishParams->mortFishVelocityV9 
                     withYValue1: UPPER_LOGISTIC_DEPENDENT
                     withXValue2: fishParams->mortFishVelocityV1 
                     withYValue2: LOWER_LOGISTIC_DEPENDENT];


     [survMgr addBoolSwitchFuncToProbWithSymbol:  [modelSwarm getFishMortalitySymbolWithName: "Velocity"]
                       withInputObjectType: ANIMAL
                            withInputSelector: M(getAmIInHidingCover)
                               withYesValue: fishParams->mortFishVelocityHideFactor 
                                withNoValue: 0.0];


     //
     // Stranding
     //
     [survMgr addPROBWithSymbol:  [modelSwarm getFishMortalitySymbolWithName: "Stranding"]
             withType: "SingleFunctionProb"
       withAgentKnows: YES
      withIsStarvProb: NO];


     [survMgr addLogisticFuncToProbWithSymbol: [modelSwarm getFishMortalitySymbolWithName: "Stranding"]
            withInputObjectType: ANIMAL
                 withInputSelector: M(getDepthLengthRatio)
                     withXValue1: fishParams->mortFishStrandD1
                     withYValue1: LOWER_LOGISTIC_DEPENDENT
                     withXValue2: fishParams->mortFishStrandD9
                     withYValue2: UPPER_LOGISTIC_DEPENDENT];

     //
     // Spawning
     //
     [survMgr addPROBWithSymbol: [modelSwarm getFishMortalitySymbolWithName: "Spawning"]
             withType: "SingleFunctionProb"
       withAgentKnows: NO
      withIsStarvProb: NO];

     [survMgr addBoolSwitchFuncToProbWithSymbol: [modelSwarm getFishMortalitySymbolWithName: "Spawning"]
                       withInputObjectType: ANIMAL
                            withInputSelector: M(getFishSpawnedThisTime)
                               withYesValue: fishParams->mortFishSpawn 
                                withNoValue: 1.0];


     //
     // Aquatic Predation
     // 
     [survMgr addPROBWithSymbol: [modelSwarm getFishMortalitySymbolWithName: "AquaticPredation"] 
             withType: "LimitingFunctionProb"
       withAgentKnows: YES
      withIsStarvProb: NO];


     [survMgr addBoolSwitchFuncToProbWithSymbol: [modelSwarm getFishMortalitySymbolWithName: "AquaticPredation"] 
          withInputObjectType: HABITAT 
               withInputSelector: M(getCurrentPhase)
               //withInputSelector: M(getPhaseOfPrevStep)
                  withYesValue: fishParams->mortFishAqPredDayMin
                   withNoValue: fishParams->mortFishAqPredNightMin];


     [survMgr addBoolSwitchFuncToProbWithSymbol: [modelSwarm getFishMortalitySymbolWithName: "AquaticPredation"] 
          withInputObjectType: ANIMAL 
               withInputSelector: M(getAmIInHidingCover)
                  withYesValue: fishParams->mortFishAqPredCoverFactor
                   withNoValue: 0.0];



     [survMgr addLogisticFuncToProbWithSymbol: [modelSwarm getFishMortalitySymbolWithName: "AquaticPredation"] 
            withInputObjectType: HABITAT
                 withInputSelector: M(getUTMCellDepth)
                     withXValue1: fishParams->mortFishAqPredD9
                     withYValue1: UPPER_LOGISTIC_DEPENDENT
                     withXValue2: fishParams->mortFishAqPredD1
                     withYValue2: LOWER_LOGISTIC_DEPENDENT];



     [survMgr addLogisticFuncToProbWithSymbol: [modelSwarm getFishMortalitySymbolWithName: "AquaticPredation"] 
            withInputObjectType: HABITAT
                 withInputSelector: M(getUTMCellTemperature)
                     withXValue1: fishParams->mortFishAqPredT9
                     withYValue1: UPPER_LOGISTIC_DEPENDENT
                     withXValue2: fishParams->mortFishAqPredT1
                     withYValue2: LOWER_LOGISTIC_DEPENDENT];


     /*
     [survMgr addLogisticFuncToProbWithSymbol: [modelSwarm getFishMortalitySymbolWithName: "AquaticPredation"] 
            withInputObjectType: HABITAT
                 withInputSelector: M(getPiscivorousFishDensity)
                     withXValue1: fishParams->mortFishAqPredA9
                     withYValue1: UPPER_LOGISTIC_DEPENDENT
                     withXValue2: fishParams->mortFishAqPredA1
                     withYValue2: LOWER_LOGISTIC_DEPENDENT];
     */

     [survMgr addLogisticFuncToProbWithSymbol: [modelSwarm getFishMortalitySymbolWithName: "AquaticPredation"] 
            withInputObjectType: ANIMAL
                 withInputSelector: M(getFishLength)
                     withXValue1: fishParams->mortFishAqPredL1
                     withYValue1: LOWER_LOGISTIC_DEPENDENT
                     withXValue2: fishParams->mortFishAqPredL9
                     withYValue2: UPPER_LOGISTIC_DEPENDENT];




     [survMgr addLogisticFuncToProbWithSymbol: [modelSwarm getFishMortalitySymbolWithName: "AquaticPredation"] 
            withInputObjectType: HABITAT
                 withInputSelector: M(getUTMCellTurbidity)
                     withXValue1: fishParams->mortFishAqPredU1
                     withYValue1: LOWER_LOGISTIC_DEPENDENT
                     withXValue2: fishParams->mortFishAqPredU9
                     withYValue2: UPPER_LOGISTIC_DEPENDENT];



    //
    // Terrestial predation
    //
     [survMgr addPROBWithSymbol: [modelSwarm getFishMortalitySymbolWithName: "TerrestialPredation"] 
             withType: "LimitingFunctionProb"
       withAgentKnows: YES
      withIsStarvProb: NO];


     [survMgr addBoolSwitchFuncToProbWithSymbol: [modelSwarm getFishMortalitySymbolWithName: "TerrestialPredation"] 
          withInputObjectType: HABITAT 
               withInputSelector: M(getCurrentPhase)
               //withInputSelector: M(getPhaseOfPrevStep)
                  withYesValue: fishParams->mortFishTerrPredDayMin
                   withNoValue: fishParams->mortFishTerrPredNightMin];



     [survMgr addBoolSwitchFuncToProbWithSymbol: [modelSwarm getFishMortalitySymbolWithName: "TerrestialPredation"] 
          withInputObjectType: ANIMAL 
               withInputSelector: M(getAmIInHidingCover)
                  withYesValue: fishParams->mortFishTerrPredCoverFactor
                   withNoValue: 0.0];


     [survMgr addLogisticFuncToProbWithSymbol: [modelSwarm getFishMortalitySymbolWithName: "TerrestialPredation"] 
            withInputObjectType: HABITAT
                 withInputSelector: M(getUTMCellDepth)
                     withXValue1: fishParams->mortFishTerrPredD1
                     withYValue1: LOWER_LOGISTIC_DEPENDENT
                     withXValue2: fishParams->mortFishTerrPredD9
                     withYValue2: UPPER_LOGISTIC_DEPENDENT];

     [survMgr addLogisticFuncToProbWithSymbol: [modelSwarm getFishMortalitySymbolWithName: "TerrestialPredation"] 
            withInputObjectType: HABITAT
                 withInputSelector: M(getUTMCellVelocity)
                     withXValue1: fishParams->mortFishTerrPredV1
                     withYValue1: LOWER_LOGISTIC_DEPENDENT
                     withXValue2: fishParams->mortFishTerrPredV9
                     withYValue2: UPPER_LOGISTIC_DEPENDENT];

     [survMgr addLogisticFuncToProbWithSymbol: [modelSwarm getFishMortalitySymbolWithName: "TerrestialPredation"] 
            withInputObjectType: ANIMAL
                 withInputSelector: M(getFishLength)
                     withXValue1: fishParams->mortFishTerrPredL9
                     withYValue1: UPPER_LOGISTIC_DEPENDENT
                     withXValue2: fishParams->mortFishTerrPredL1
                     withYValue2: LOWER_LOGISTIC_DEPENDENT];

     [survMgr addLogisticFuncToProbWithSymbol: [modelSwarm getFishMortalitySymbolWithName: "TerrestialPredation"] 
            withInputObjectType: HABITAT
                 withInputSelector: M(getUTMCellTurbidity)
                     withXValue1: fishParams->mortFishTerrPredT1
                     withYValue1: LOWER_LOGISTIC_DEPENDENT
                     withXValue2: fishParams->mortFishTerrPredT9
                     withYValue2: UPPER_LOGISTIC_DEPENDENT];

     [survMgr addLogisticFuncToProbWithSymbol: [modelSwarm getFishMortalitySymbolWithName: "TerrestialPredation"] 
            withInputObjectType: HABITAT
                 withInputSelector: M(getDistanceToHide)
                     withXValue1: fishParams->mortFishTerrPredH9
                     withYValue1: UPPER_LOGISTIC_DEPENDENT
                     withXValue2: fishParams->mortFishTerrPredH1
                     withYValue2: LOWER_LOGISTIC_DEPENDENT];




    //
    // Poor condition
    //

     [survMgr addPROBWithSymbol: [modelSwarm getFishMortalitySymbolWithName: "PoorCondition"] 
             withType: "SingleFunctionProb"
       withAgentKnows: YES
      withIsStarvProb: YES];

     [survMgr addLogisticFuncToProbWithSymbol: [modelSwarm getFishMortalitySymbolWithName: "PoorCondition"] 
            withInputObjectType: ANIMAL
                 withInputSelector: M(getFishCondition)
                     withXValue1: fishParams->mortFishConditionK1
                     withYValue1: LOWER_LOGISTIC_DEPENDENT
                     withXValue2: fishParams->mortFishConditionK9
                     withYValue2: UPPER_LOGISTIC_DEPENDENT];



     //
     // Angling 
     //
      [survMgr addPROBWithSymbol: [modelSwarm getFishMortalitySymbolWithName: "Angling"] 
                        withType: "CustomProb"
                  withAgentKnows: NO
                 withIsStarvProb: NO];

      
     [survMgr addLogisticFuncToProbWithSymbol: [modelSwarm getFishMortalitySymbolWithName: "Angling"] 
            withInputObjectType: ANIMAL
                 withInputSelector: M(getFishLength)
                     withXValue1: fishParams->mortFishAngleL1
                     withYValue1: LOWER_LOGISTIC_DEPENDENT
                     withXValue2: fishParams->mortFishAngleL9
                     withYValue2: UPPER_LOGISTIC_DEPENDENT];

     
//
// Hooking
//
     

      [survMgr addPROBWithSymbol: [modelSwarm getFishMortalitySymbolWithName: "Hooking"] 
                       withType: "CustomProb"
                 withAgentKnows: NO
                withIsStarvProb: NO];
 

      
     [survMgr setLogisticFuncLimiterTo: 20.0];

     //[survMgr setTestOutputOnWithFileName: "SurvMgrOut.Out"];
     survMgr = [survMgr createEnd];


    } //for fish survivals



  [fpNdx setLoc: Start];

  while(([fpNdx getLoc] != End) && ((fishParams = (FishParams *) [fpNdx next]) != nil))
  {
      id <SurvMGR> survMgr;
      id <Symbol> species = [fishParams getFishSpecies];
 
      survMgr = [SurvMGR     createBegin: cellZone
                       withHabitatObject: self];

      [survMgrReddMap at: species insert: survMgr];

      ANIMAL = [survMgr getANIMALSYMBOL];
      HABITAT = [survMgr getHABITATSYMBOL];

      //
      // Redd survivals
      //

      //
      // Redd Dewater Survival Function
      //

     
      [survMgr addPROBWithSymbol: [modelSwarm getReddMortalitySymbolWithName: "ReddDewaterSP"] 
                       withType:  "SingleFunctionProb"
                 withAgentKnows: YES
                withIsStarvProb: NO];
  
     [survMgr addBoolSwitchFuncToProbWithSymbol: [modelSwarm getReddMortalitySymbolWithName: "ReddDewaterSP"] 
                       withInputObjectType: HABITAT
                            withInputSelector: M(isDryAtDailyMeanFlow)
                               withYesValue: fishParams->mortReddDewaterSurv 
                                withNoValue: 1.0];
      

      /*
      //
      // Redd Scour Survival Function  
      //
      [survMgr addPROBWithSymbol: [modelSwarm getReddMortalitySymbolWithName: "ReddScourSP"] 
                       withType: "CustomProb"
                 withAgentKnows: YES
                withIsStarvProb: NO];
  
   
      [survMgr addCustomFuncToProbWithSymbol: [modelSwarm getReddMortalitySymbolWithName: "ReddScourSP"] 
                              withClassName: "ReddScourFunc"
                          withInputObjectType: ANIMAL
                               withInputSelector: M(getWorld)];
      
      */
     
      //
      // Redd Lo Temp Survival Function  
      //
      [survMgr addPROBWithSymbol: [modelSwarm getReddMortalitySymbolWithName: "ReddLoTempSP"] 
              withType: "SingleFunctionProb"
        withAgentKnows: YES
       withIsStarvProb: NO];


      [survMgr addLogisticFuncToProbWithSymbol: [modelSwarm getReddMortalitySymbolWithName: "ReddLoTempSP"] 
             withInputObjectType: HABITAT
                  withInputSelector: M(getUTMCellTemperature)
                      withXValue1: fishParams->mortReddLoTT1
                      withYValue1: LOWER_LOGISTIC_DEPENDENT
                      withXValue2: fishParams->mortReddLoTT9
                      withYValue2: UPPER_LOGISTIC_DEPENDENT];

      //
      // Redd Hi Temp Survival Function
      //

       [survMgr addPROBWithSymbol: [modelSwarm getReddMortalitySymbolWithName: "ReddHiTempSP"] 
                   withType: "SingleFunctionProb"
             withAgentKnows: YES
            withIsStarvProb: NO];
     

       [survMgr addLogisticFuncToProbWithSymbol: [modelSwarm getReddMortalitySymbolWithName: "ReddHiTempSP"] 
             withInputObjectType: HABITAT
                  withInputSelector: M(getUTMCellTemperature)
                      withXValue1: fishParams->mortReddHiTT9
                      withYValue1: UPPER_LOGISTIC_DEPENDENT
                      withXValue2: fishParams->mortReddHiTT1
                      withYValue2: LOWER_LOGISTIC_DEPENDENT];

      //
      // Redd Super Imposition Survival Function
      //
      [survMgr addPROBWithSymbol: [modelSwarm getReddMortalitySymbolWithName: "ReddSuperImpSP"] 
                       withType: "CustomProb"
                 withAgentKnows: YES
                withIsStarvProb: NO];
  
   
      [survMgr addCustomFuncToProbWithSymbol: [modelSwarm getReddMortalitySymbolWithName: "ReddSuperImpSP"] 
                               withClassName: "ReddSuperImpFunc"
                         withInputObjectType: ANIMAL
                           withInputSelector: M(getWorld)];
     

     [survMgr setLogisticFuncLimiterTo: 20.0];
     survMgr = [survMgr createEnd];

     //[survMgr setTestOutputOnWithFileName: "ReddSurvMgr.Out"];
  }


  [fpNdx drop];

  //fprintf(stdout, "Cell >>>> initializeSurvProb >>>> END\n");
  //fflush(0);

  return self;
}




/////////////////////////////////////////////////////
//
// updateHabitatSurvivalProb
//
/////////////////////////////////////////////////////
- updateHabitatSurvivalProb 
{
  [survMgrMap forEach: M(updateForHabitat)];

  return self;
}


//////////////////////////////////////////////
//
// updateReddHabitatSurvProb
//
////////////////////////////////////////////
- updateReddHabitatSurvProb
{
  [survMgrReddMap forEach: M(updateForHabitat)];
  return self;
}


//////////////////////////////////
//
// updateHabSurvProbForAqPred
//
/////////////////////////////////
- updateHabSurvProbForAqPred
{
  [survMgrMap forEach: M(updateForHabitat)];

  return self;
}


/////////////////////////////////////
//
// updateFishSurvivalProbFor
//
/////////////////////////////////////
- updateFishSurvivalProbFor: aFish
{
   [[survMgrMap at: [aFish getSpecies]] 
          updateForAnimal: aFish]; 

   return self;
}


- updateReddSurvivalProbFor: aRedd
{
   [[survMgrReddMap at: [aRedd getSpecies]] updateForAnimal: aRedd]; 

   return self;
}



//////////////////////////////////////////
//
//(id <List>) getListOfSurvProbsFor: aFish
//
//////////////////////////////////////////
- (id <List>) getListOfSurvProbsFor: aFish
{
   return [[survMgrMap at: [aFish getSpecies]] getListOfSurvProbsFor: aFish]; 
}

//////////////////////////////////////////
//
//(id <List>) getReddListOfSurvProbsFor: aRedd
//
//////////////////////////////////////////
- (id <List>) getReddListOfSurvProbsFor: aRedd
{
   return [[survMgrReddMap at: [aRedd getSpecies]] getListOfSurvProbsFor: aRedd]; 
}



- (double) getTotalKnownNonStarvSurvivalProbFor: aFish
{
  return  [[survMgrMap at: [aFish getSpecies]] getTotalKnownNonStarvSurvivalProbFor: aFish];
}



- (double) getStarvSurvivalFor: aFish
{
   return [[survMgrMap at: [aFish getSpecies]] getStarvSurvivalFor: aFish]; 
}


/////////////////////////////////////////
//
// getCurrentPhase
//
////////////////////////////////////////
- (int) getCurrentPhase
{
    return [space getCurrentPhase];
}

///////////////////////////////////
//
// getUTMCellTemperature
//
//////////////////////////////////
- (double) getUTMCellTemperature
{
    double temperature = [space getTemperature];
    return temperature;
}


///////////////////////////////////
//
// getUTMCellTurbidity
//
//////////////////////////////////
- (double) getUTMCellTurbidity
{
    return [space getTurbidity];
}

///////////////////////////////////////////
//
// getCurrentHourlyFlow
//
/////////////////////////////////////////
- (double) getCurrentHourlyFlow 
{
  return [space getCurrentHourlyFlow];
}


////////////////////////////////////////////////////////////////////
//
// getChangeInDailyFlow
//
////////////////////////////////////////////////////////////////////
- (double) getChangeInDailyFlow 
{
  return [space getChangeInDailyFlow];
}



//////////////////////////////////////
//
// getPiscivorousFishDensity
//
//////////////////////////////////////
- (double) getPiscivorousFishDensity
{
    return [space getPiscivorousFishDensity]; 
}


//////////////////////////////////////////
//
// getReachLength
//
//////////////////////////////////////////
- (double) getReachLength
{
    return [space getReachLength];
}



/////////////////////////////////////
//
// getHabAngleNightFactor
//
///////////////////////////////////
- (double) getHabAngleNightFactor
{
    return [space getHabAngleNightFactor];
}

//////////////////////////////////////////////////////////////////
//
// setCellFracShelter
//
//////////////////////////////////////////////////////////////////
- (void) setCellFracShelter: (double) aDouble 
{
    cellFracShelter = aDouble;
}


/////////////////////////////////////////////////////////////////
//
// calcCellShelterArea
//
////////////////////////////////////////////////////////////////
- (void) calcCellShelterArea 
{
    cellShelterArea = utmCellArea*cellFracShelter;
}


////////////////////////////////////
//
// getShelterAreaAvailable 
//
////////////////////////////////////
- (double) getShelterAreaAvailable 
{
    return shelterAreaAvailable;
}



////////////////////////////////////
//
// resetHidingCover
//
////////////////////////////////////
- resetHidingCover
{
   availableHidingCover = utmCellArea * fracHidingCover;
   return self;

}


//////////////////////////////////////
//
// getIsHidingCoverAvailable
//
//////////////////////////////////////
- (BOOL) getIsHidingCoverAvailable
{
    BOOL isHidingCoverAvailable = NO;

    if(availableHidingCover > 0.0) 
    {
        isHidingCoverAvailable = YES;
    }
  
    return isHidingCoverAvailable;
}


/////////////////////////////////////////
//
// getHidingCoverAvailable
//
////////////////////////////////////////
- (double) getHidingCoverAvailable
{
    return availableHidingCover;  
}   

//////////////////////////////////////////////////////////////////
//
// setCellFracSpawn
//
//////////////////////////////////////////////////////////////////
- setCellFracSpawn: (double) aDouble 
{
     cellFracSpawn = aDouble;
     return self;
}





////////////////////////////////////////////////////////////////////
//
// getCellFracSpawn
//
////////////////////////////////////////////////////////////////////
- (double) getCellFracSpawn 
{
     return cellFracSpawn;
}



/////////////////////////////////////////////////
//
// setFracHidingCover
//
////////////////////////////////////////////////
- setFracHidingCover: (double) aFracHidingCover
{
   fracHidingCover = aFracHidingCover;
   return self;
}





/////////////////////////////////////////////////////////////
//
// moveHere
//
/////////////////////////////////////////////////////////////
- moveHere: aFish 
{
  //
  //in Hiding cover
  //
  if(availableHidingCover > 0.0)
  {
        if([aFish getAmIInHidingCover] == YES)
        {
           availableHidingCover -= [aFish getFishHidingCoverArea];
        }
        if(availableHidingCover < 0.0)
        {
           availableHidingCover = 0.0;
        }
  }      


  //
  // sheltered?
  //
  if(shelterAreaAvailable > 0.0 ) 
  {
      if([aFish getAmIInAShelter] == YES ) 
      {
             shelterAreaAvailable -= [aFish getFishShelterArea];
      }
      if(shelterAreaAvailable < 0.0) 
      {
         shelterAreaAvailable = 0.0;
      }
  }

  hourlyAvailDriftFood -= [aFish getHourlyDriftConRate];
  hourlyAvailSearchFood -= [aFish getHourlySearchConRate];

  
  [self addFish: aFish];

#ifdef REPORT_ON
  [self foodAvailAndConInCell: aFish];
#endif

  return self;
}


///////////////////////////////////////////////////////////////
//
// addRedd
//
//
// addRedd has a different functionality from addFish.  Since
// redds don't move around like fish, they spend their entire
// life in once cell.  So, an "addredd" only occurs after the
// creation of a new redd. 
//
// NOTE: The new Redd MUST BE add to the BEGINNING of the
//       reddIContain List in order to make the SUPER-IMPOSITION
//       function work.
//
//
///////////////////////////////////////////////////////////////
- addRedd: aRedd 
{
  [reddList addFirst: aRedd];
  return self;
}



/////////////////////////////////////////////////////////////
//
// removeRedd
//
/////////////////////////////////////////////////////////////
- removeRedd: aRedd 
{
   [reddList remove: aRedd];
   return self;
}


///////////////////////////////////////////
//
// getReddList
//
///////////////////////////////////////////
- (id <List>) getReddList
{
    return reddList;
}

////////////////////////////////////////////////
//
// getHabSearchProd
//
////////////////////////////////////////////////
- (double) getHabSearchProd 
{
    return [space getHabSearchProd];
}



//////////////////////////////////////////////
//
// getHabDriftConc
//
/////////////////////////////////////////////
- (double) getHabDriftConc 
{
    return [space getHabDriftConc];
}

/////////////////////////////////////////
//
// getHabDriftRegenDist
//
/////////////////////////////////////////
- (double) getHabDriftRegenDist 
{
   return [space getHabDriftRegenDist];
}

//////////////////////////////////////////////////////////
//
// getHabPreyEnergyDensity
//
/////////////////////////////////////////////////////////
- (double) getHabPreyEnergyDensity 
{
    return [space getHabPreyEnergyDensity];
}



////////////////////////////
//
// getPhaseOfPrevStep
//
////////////////////////////
- (int) getPhaseOfPrevStep
{
   return [space getPhaseOfPrevStep];
}

//////////////////////////////
//
// getDayNightPhaseSwitch
//
//////////////////////////////
- (BOOL) getDayNightPhaseSwitch
{
    return [space getDayNightPhaseSwitch];
}


///////////////////////////////
//
// getNumberOfDaylightHours
//
///////////////////////////////
- (double) getNumberOfDaylightHours
{
    return [space getNumberOfDaylightHours];
}

///////////////////////////////
//
// getNumberOfNightHours
//
///////////////////////////////
- (double) getNumberOfNightHours
{
    return [space getNumberOfNightHours];
}


/////////////////////////////////////////////
//
// calcDriftHourlyTotal
//
////////////////////////////////////////////
-  calcDriftHourlyTotal 
{
    driftHourlyCellTotal = 3600*utmCellArea*utmCellDepth*utmCellVelocity*[space getHabDriftConc]/[space getHabDriftRegenDist];
    return self;
}


////////////////////////////////////////////
//
// calcSearchHourlyTotal
//
//////////////////////////////////////////////
- calcSearchHourlyTotal 
{
    searchHourlyCellTotal = utmCellArea*[space getHabSearchProd];
    return self;
}


//////////////////////////////////////////
//
// getHourlyAvailDriftFood
//
////////////////////////////////////////
- (double) getHourlyAvailDriftFood 
{
   return hourlyAvailDriftFood;
}

//////////////////////////////////////////
//
// getHourlyAvailSearchFood
//
////////////////////////////////////////
- (double) getHourlyAvailSearchFood 
{
   return hourlyAvailSearchFood;
}

//////////////////////////////////
//
// updateDSCellHourlyTotal
//
//////////////////////////////////
- (void) updateDSCellHourlyTotal 
{
  [self calcDriftHourlyTotal];
  [self calcSearchHourlyTotal];
}


/////////////////////////////////////
//
//resetAvailHourlyTotal
//
//////////////////////////////////////
- (void) resetAvailHourlyTotal 
{
    hourlyAvailDriftFood = driftHourlyCellTotal;
    hourlyAvailSearchFood = searchHourlyCellTotal;
}




///////////////////////////////////////
//
// getAnglingPressure
//
///////////////////////////////////////
- (double) getAnglingPressure
{
    return [space getAnglingPressure];
}


//////////////////////////////////////
//
// getDailyMeanFlow
//
/////////////////////////////////////
- (double) getDailyMeanFlow
{
     return [space getDailyMeanFlow];
}

////////////////////////////////////
//
// getPrevDailyMeanFlow
//
////////////////////////////////////
- (double) getPrevDailyMeanFlow
{
    return [space getPrevDailyMeanFlow];
}


/////////////////////////////////////
//
// getPrevDailyMaxFlow
//
/////////////////////////////////////
- (double) getPrevDailyMaxFlow
{
    return [space getPrevDailyMaxFlow];
}


//////////////////////////////////////
//
// getDailyMaxFlow
//
//////////////////////////////////////
- (double) getDailyMaxFlow
{
   return [space getDailyMaxFlow];
}


//////////////////////////////////////
//
// getNextDailyMaxFlow
//
///////////////////////////////////////
- (double) getNextDailyMaxFlow
{
   return [space getNextDailyMaxFlow];
}



////////////////////////////////
//
// getIsItDaytime
//
////////////////////////////////
- (BOOL) getIsItDaytime
{
   return [space getIsItDaytime];
}



////////////////////////////////////////////////////
//
// printCellFishInfo
//
////////////////////////////////////////////////////
- printCellFishInfo: (void *) filePtr 
{
  int age;
  int age0=0;
  int age1=0;
  int age2=0;
  int age3P=0;

  id <ListIndex> ndx=nil;
  id fish=nil;
    
  time_t modelTime = [space getModelTime];
  char date[12];
  int hour;

  int aPhase = (int) [space getCurrentPhase];
  int fishActivity = -5;

  const char* format = "%-15s%-15d%-15d%-15d%-15f%-15f%-15f%-15f%-17f%-17f%-17f%-5d%-5d%-5d%-5d\n";

  if(utmCellDepth <= 0) 
  {
      return self;
  }

  strncpy(date, [timeManager getDateWithTimeT: modelTime], 11);
  hour = [timeManager getHourWithTimeT: modelTime];

  ndx = [fishList listBegin: scratchZone];
  while(([ndx getLoc] != End) && ((fish = [ndx next]) != nil)) 
  {
        fishActivity = (int) [fish getFishActivity];   

        //fprintf(stderr, "Cell >>>> printCellFishInfo >>>> transectNumber = %d cellNumber = %d fishActivity = %d \n", transectNumber, cellNumber, fishActivity);
        //fflush(0);

        //
        // Only look at fish that have activity FEED = -2
        // skj 4/28/2003
        //
        if(fishActivity == -1)
        {
            continue;
        } 

        age = [fish getAge];

        switch(age)
        {

          case 0: age0++;
                  break;
 
          case 1: age1++;
                  break;

          case 2: age2++;
                  break;

          case 3:
          default: age3P++;
                   break;

        }

   }

   [ndx drop];


   fprintf((FILE *) filePtr, format, date,
                                     hour,
                                     aPhase,
                                     utmCellNumber,
                                     utmCellArea,
                                     utmCellDepth,
                                     utmCellVelocity,
                                     cellDistToHide,
                                     cellFracShelter,
                                     fracHidingCover,
                                     cellFracSpawn,
                                     age0,
                                     age1,
                                     age2,
                                     age3P);
  fflush((FILE *) filePtr);

  return self;

}


////////////////////////////////////////////
//
// tagUTMCell
//
//////////////////////////////////////////
- tagUTMCell
{
    [super tagUTMCell];
    [space redrawRaster];
    return self;
}

/////////////////////////////////////////
//
// unTagUTMCell
//
////////////////////////////////////////
- unTagUTMCell
{
    [super unTagUTMCell];
    [space redrawRaster];
    return self;
}

//////////////////////////////////////////////
//
// untagAllCells
//
//////////////////////////////////////////////
- untagAllCells
{
    [super unTagUTMCell];
    return self;
}

////////////////////////////////////////////
//
// setShadeColorMax
//
/////////////////////////////////////////////
- setShadeColorMax: (double) aShadeColorMax
{
   shadeColorMax = aShadeColorMax;
   return self;
}

//////////////////////////////////////////
//
// toggleColorRep
//
//////////////////////////////////////////
- toggleColorRep: (double) aShadeColorMax
{
   if(strncmp(rasterColorVariable, "depth",5) == 0)
   {
       strncpy(rasterColorVariable, "velocity", 9);
   }
   else if(strncmp(rasterColorVariable, "velocity",8) == 0)
   {
       strncpy(rasterColorVariable, "depth", 6);
   }
   else
   {
       fprintf(stderr, "ERROR: FishCell >>>> toggleColorRep >>>> incorrect rasterColorVariable\n");
       fflush(0);
       exit(1);
   }

   shadeColorMax = aShadeColorMax;

   return self;
}

/////////////////////////////////////////////////////////////////////
//
// drawSelfOn
//
/////////////////////////////////////////////////////////////////////
- drawSelfOn: (id <Raster>) aRaster 
{
  int maxIndex;
  double colorVariable = 0.0;
  double colorRatio;
  int i;

  //fprintf(stdout, "UTMCell >>>> drawSelfOn >>>> BEGIN\n");
  //fflush(0);

  //
  // don't call super, do all of the work here 
  //

   if(rasterColorVariable == NULL)
   {
       fprintf(stderr, "ERROR: UTMCell >>>> drawSelfOn >>>> rasterColorVariable has not been set\n");
       fflush(0);
       exit(1);
   }

   if(strcmp("depth",rasterColorVariable) == 0) 
   {
        colorVariable = utmCellDepth; 
   }
   else if(strcmp("velocity",rasterColorVariable) == 0) 
   {
       colorVariable = utmCellVelocity; 
   }
   else 
   {
         fprintf(stderr, "ERROR: Unknown rasterColorVariable value = %s\n",rasterColorVariable);
         fflush(0);
         exit(1);
   }

   colorRatio = colorVariable/shadeColorMax; 

   maxIndex = (int) shadeColorMax;

   if(colorVariable == 0.0) 
   {
      interiorColor = UTMBOUNDARYCOLOR;
   }
   else
   {  
       for(i = 0; i < maxIndex; i++)
       {
           double aColorFrac =  1.0 - (double) (maxIndex - 1.0 - i)/((double) (maxIndex - 1.0));
   
           interiorColor = i;
    
           if(colorRatio < aColorFrac)
           {
              break;
           }
       }
   }

   if(tagCell)
   {
      interiorColor = TAG_CELL_COLOR;
   }

   for(i = 0;i < pixelCount; i++)
   {
       [aRaster drawPointX: utmCellPixels[i]->pixelX 
                         Y: utmCellPixels[i]->pixelY 
                     Color: interiorColor];
   }

   for(i = 1; i <= numberOfNodes; i++) 
   { 
       [aRaster lineX0: displayPointArray[i - 1]->x
                    Y0: displayPointArray[i - 1]->y
                    X1: displayPointArray[i % numberOfNodes]->x
                    Y1: displayPointArray[i % numberOfNodes]->y
                 Width: 1
                 Color: UTMBOUNDARYCOLOR];
   }
  
   if([fishList getCount] > 0)
   {
       id <ListIndex> ndx;
       ndx = [fishList listBegin: scratchZone];
       UTMTrout* fish = nil;

       while(([ndx getLoc] != End) && ((fish = [ndx next]) != nil))
       {    
           [fish drawSelfOn: aRaster 
                        atX: displayCenterX 
                          Y: displayCenterY];
       }
  
       [ndx drop];
   }
 
   if([reddList getCount] > 0);
   {
        id <ListIndex> ndx = [reddList listBegin: scratchZone];
        UTMRedd* redd = nil;
 
        while(([ndx getLoc] != End) && ((redd = [ndx next]) != nil)) 
        {
             [redd drawSelfOn: aRaster
                          atX: displayCenterX 
                            Y: displayCenterY];
             }
        [ndx drop];
  }

  return self;
}


////////////////////////////////////////////////
//
// depthVelReport
//
////////////////////////////////////////////////
- depthVelReport: (FILE *) depthVelPtr 
{
   char date[12];
   int hour = 0;
   time_t modelTime = [space getModelTime];

   if([space getDepthVelRptFirstTime] == YES)
   {
        fprintf(depthVelPtr,"%-15s%-6s%-8s%-16s%-16s%-16s%-16s\n", "Date",
                                                              "Hour",
                                                              "CellNo",
                                                              "CellArea",
                                                              "RiverFlow",
                                                              "Depth",
                                                              "Velocity");

   }

   if(utmCellDepth != 0) 
   {
       sprintf(date, "%s", [timeManager getDateWithTimeT: modelTime]),
       hour = [timeManager getHourWithTimeT: modelTime];
       fprintf(depthVelPtr,"%-15s%-6d%-8d%-16f%-16f%-16f%-16f\n", date,
                                                         hour,
                                                         utmCellNumber,
                                                         utmCellArea,
                                                         [space getCurrentHourlyFlow],
                                                         utmCellDepth,
                                                         utmCellVelocity);
   }
 
   [space setDepthVelRptFirstTime: NO];

   return self;
}


//////////////////////////////
//
// drop
//
/////////////////////////////
- (void) drop
{
    //fprintf(stdout, "FishCell >>>> drop >>>> BEGIN\n");
    //fflush(0);

   [fishList drop];
   [reddList drop];
   [survMgrMap deleteAll];
   [survMgrMap drop];
   [survMgrReddMap deleteAll];
   [survMgrReddMap drop];
   [super drop];

    //fprintf(stdout, "FishCell >>>> drop >>>> END\n");
    //fflush(0);
}

@end
