//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 




#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#import <math.h>
#import <random.h>
#import <simtoolsgui.h>
#import "globals.h"
#import "UTMHabitatSpace.h"
#import "UTMTroutModelSwarm.h"


@implementation UTMHabitatSpace
+ createBegin: aZone 
{
  UTMHabitatSpace* habitatSpace;
 
  habitatSpace = [super createBegin: aZone];

  habitatSpace->habitatZone = [Zone create: aZone];

  habitatSpace->flowChangeForMove = NO;
  habitatSpace->flowAtLastMove = -LARGEINT;
  habitatSpace->prevTime = 0;
  habitatSpace->numberOfDaylightHours = 0;
  habitatSpace->numberOfNightHours = 0;

  //habitatSpace->currentPhase = DNERROR;
  habitatSpace->currentPhase = NIGHT;
  habitatSpace->phaseOfPrevStep = DNERROR;

  habitatSpace->numberOfSpecies = -1;
  habitatSpace->piscivorousFishDensity = 0.0;

  habitatSpace->driftFoodFile = (char *) [habitatSpace->habitatZone alloc: 51 * sizeof(char)];
  habitatSpace->utmFlowFile = (char *) [habitatSpace->habitatZone alloc: 51 * sizeof(char)];
  habitatSpace->utmTemperatureFile = (char *) [habitatSpace->habitatZone alloc: 51 * sizeof(char)];
  habitatSpace->utmTurbidityFile = (char *) [habitatSpace->habitatZone alloc: 51 * sizeof(char)];
  habitatSpace->utmCellHabVarsFile = (char *) [habitatSpace->habitatZone alloc: 51 * sizeof(char)];

  return habitatSpace;
 
}

/////////////////////////////////////////////
//
// createEnd
//
////////////////////////////////////////////
- createEnd 
{
  //
  // We're not really using the lattice,
  // so don't allocate any memory for it.
  // Also don't makeOffsets.
  // 
  //[super createEnd];
  //
  //CREATE_ARCHIVED_PROBE_DISPLAY (self);

  return self;
}

////////////////////////////////////////////////
//
// buildObjects
//
///////////////////////////////////////////////
- buildObjects 
{
  
    habitatReportFirstWrite = YES;
    depthReportFirstWrite = YES;
    velocityReportFirstWrite = YES;
    depthVelRptFirstTime=YES;
   
    foodReportFirstTime = YES;

    Date = (char *) [habitatZone allocBlock: 12*sizeof(char)];

    return self;
}


/////////////////////////////////////////////
//
// getReachName
//
///////////////////////////////////////////
- (char *) getReachName
{
    return reachName;
}


////////////////////////////////////////////////
//
////        SET METHODS
//////
////////
//////////
////////////////////////////////////////////////



///////////////////////////////////////////////////////////////
//
// setModelSwarm
//
//////////////////////////////////////////////////////////////
- setModelSwarm: aModelSwarm 
{
  modelSwarm = aModelSwarm;
  return self;
}


///////////////////////////////
//
// setTimeManager
//
///////////////////////////////
- setTimeManager: (id <TimeManager>) aTimeManager
{
   timeManager = aTimeManager;
   return self;
}


////////////////////////////////////////
//
// setTimeStepSize (seconds)
//
////////////////////////////////////////
- setTimeStepSize: (time_t) aTimeStepSize
{
   timeStepSize = aTimeStepSize;
   return self;
}


////////////////////////////////////////
//
// setRandGen
//
/////////////////////////////////////
- setRandGen: aRandGen
{
    randGen = aRandGen;
    return self;
}


/////////////////////////////////////
//
// getRandGen
//
///////////////////////////////////
- getRandGen
{
     return randGen;
}



////////////////////////////////////////////////////////////
//
// getModel
//
///////////////////////////////////////////////////////////
- getModel 
{
  return modelSwarm;
}



/////////////////////////////////////////////////
//
// setNumberOfSpecies
//
////////////////////////////////////////////////
- setNumberOfSpecies: (int) aNumberOfSpecies
{
   numberOfSpecies = aNumberOfSpecies;

   return self;

}


////////////////////////////////////////////////
//
// getHabSearchProd
//
////////////////////////////////////////////////
- (double) getHabSearchProd {
  return habSearchProd;
}




/////////////////////////////////////////////////////////
//
// getHabDriftConc
//
/////////////////////////////////////////////////////////
- (double) getHabDriftConc 
{
  return habDriftConc;
}

///////////////////////////////////////////////////
//
// getHabDriftRegenDist
//
/////////////////////////////////////////////////
- (double) getHabDriftRegenDist 
{
   return habDriftRegenDist;
}

//////////////////////////////////////////////////////////
//
// getHabPreyEnergyDensity
//
/////////////////////////////////////////////////////////
- (double) getHabPreyEnergyDensity 
{
  return habPreyEnergyDensity;
}



////////////////////////////////////////////////////
//
// getAnglingPressure
//
///////////////////////////////////////////////////
- (double) getAnglingPressure
{
   return anglingPressure;
}


/////////////////////////////////////////////
//
// getHabAngleNightFactor
//
////////////////////////////////////////////
- (double) getHabAngleNightFactor
{
    return habAngleNightFactor;
}


//////////////////////////////////////////////
//
// calcDayLength
//
// This works with julian date = 366
// but will be off by half a minute or so...
//
/////////////////////////////////////////////
- calcDayLength: (time_t) aTime_t 
{
  double delta;
  int date;

  // 
  // Added for Version 3 with diurnal movement
  //
  double startHour;
  double startMinute;
  double endHour;
  double endMinute;

  date = [timeManager getJulianDayWithTimeT: aTime_t]; 

  delta = (23.45/180)*PI*cos((2*PI/365)*(173-date));
  dayLength = 24.0 - 2.0*((12.0/PI)*acos(tan(PI*habLatitude/180.0)*tan(delta)));

  numberOfDaylightHours = dayLength + (2 * habTwilightLength);
  numberOfNightHours = 24 - numberOfDaylightHours;

  daytimeStartHour = 12 - (numberOfDaylightHours/2.0);
  daytimeEndHour = 12 + (numberOfDaylightHours/2.0);

  startMinute = modf(daytimeStartHour, &startHour);
  startMinute = 60*startMinute + 0.5;

  endMinute = modf(daytimeEndHour, &endHour);
  endMinute = 60*endMinute + 0.5;

  daytimeStartTime = [timeManager getTimeTWithDate: [timeManager getDateWithTimeT: aTime_t]
                                          withHour: (int) startHour
                                        withMinute: (int) startMinute
                                        withSecond: 0];

  daytimeEndTime = [timeManager getTimeTWithDate: [timeManager getDateWithTimeT: aTime_t]
                                          withHour: (int) endHour
                                        withMinute: (int) endMinute
                                        withSecond: 0];


  //fprintf(stdout,"HABITAT >>>> startHour = %d startMinute = %d\n",
                              //(int) startHour, (int) startMinute);
  //fprintf(stdout,"HABITAT >>>> endHour = %d endMinute = %d\n",
                              //(int) endHour, (int) endMinute);
  //fflush(0); 



return self;
}



//////////////////////////////////
//
// getDaytime*
//
/////////////////////////////////

- (double) getDaytimeStartHour
{

  return daytimeStartHour;

}

- (time_t) getDaytimeStartTime
{

  return daytimeStartTime;

}

- (double) getDaytimeEndHour
{

    return daytimeEndHour;

}

- (time_t) getDaytimeEndTime
{

    return daytimeEndTime;

}


//////////////////////////////////
//
// getNumberOfDaylightHours
//
//////////////////////////////////
- (double) getNumberOfDaylightHours
{
    return numberOfDaylightHours;
}


///////////////////////////////
//
// getNumberOfNightHours
//
///////////////////////////////
- (double) getNumberOfNightHours
{
    return numberOfNightHours;
}


///////////////////////////////
//
// getCurrentPhase
//
///////////////////////////////
- (int) getCurrentPhase
{
    return currentPhase;
}


/////////////////////////////////
//
// getPhaseOfPrevStep
// 
/////////////////////////////////
- (int) getPhaseOfPrevStep
{
   return phaseOfPrevStep;
}


/////////////////////////////////
//
// getDayNightPhaseSwitch
// 
/////////////////////////////////
- (BOOL) getDayNightPhaseSwitch
{
   return dayNightPhaseSwitch;
}


///////////////////////////////////////
//
// getIsItDaytime
//
//////////////////////////////////////
- (BOOL) getIsItDaytime
{
    BOOL isItDaytime = (BOOL) currentPhase;

    if((isItDaytime == YES) || (isItDaytime == NO))
    {
        return isItDaytime;
    }

    fprintf(stderr, "ERROR: UTMHabitatSpace >>>> getIsItDayTime >>>> currentPhase = %d\n", (int) currentPhase);
    fflush(0);
    exit(1);

    
    return isItDaytime;

}



///////////////////////////////////////
//
// getFlowChangeForMove
//
///////////////////////////////////////
- (BOOL) getFlowChangeForMove
{
  if((currentHourlyFlow > (flowAtLastMove * (1.0 + habFracFlowChangeForMovement)))
     || (currentHourlyFlow < (flowAtLastMove * (1.0 - habFracFlowChangeForMovement))))
  {
      flowChangeForMove = YES;
  }
  else
  {
      flowChangeForMove = NO;
  }

  return flowChangeForMove;

}

/////////////////////////////////////////////////
//
// shouldFishMoveAt
//
// This method has three functions: it tells the
// model whether movement should occur at the 
// current time, it updates whether it is day or
// night and it updates daily habitat variables 
// every midnight.
// This method is executed every hour.
//
/////////////////////////////////////////////////
- (BOOL) shouldFishMoveAt: (time_t) theCurrentTime
{
   BOOL flowMove = NO;
   BOOL simStartMove = NO;

   dayNightPhaseSwitch = FALSE;

   //fprintf(stderr, "HABITATSPACE >>>> shouldFishMoveAt >>>> BEGIN\n");
   //fflush(0);

   currentHourlyFlow = [flowInputManager getValueForTime: theCurrentTime];
   habDriftConc      = [driftFoodInputManager getValueForTime: theCurrentTime];

   //
   // First, do the stuff the happens every midnight
   //
   if([timeManager getHourWithTimeT: theCurrentTime] == 0)
   {
        [self calcDayLength: theCurrentTime];

        temperature = [temperatureInputManager getValueForTime: theCurrentTime];
        turbidity = [turbidityInputManager getValueForTime: theCurrentTime];
  
        prevDailyMeanFlow = dailyMeanFlow;

        dailyMeanFlow =  [flowInputManager getMeanValueWithStartTime: theCurrentTime
                                                       withEndTime: (theCurrentTime + 82800)];

        dailyMaxFlow = [flowInputManager getMaxValueWithStartTime: theCurrentTime
                                                      withEndTime: (theCurrentTime + 82800)]; 

        changeInDailyFlow = sqrt(pow(dailyMeanFlow - prevDailyMeanFlow,2)); 
        nextDailyMaxFlow = [flowInputManager getMaxValueWithStartTime: (theCurrentTime + 86400)
                                                      withEndTime: (theCurrentTime + 86400 + 82800)]; 

        [self updateMeanCellDepthAndVelocity: dailyMeanFlow]; 
   }

   //
   // Initialize stuff for the start of the simulation, assuming the
   // simulation starts at midnight. Force fish movement to occur at
   // the start of sim.
   //
   if(theCurrentTime == modelStartTime)
   {
       if([timeManager getHourWithTimeT: theCurrentTime] != 0)
       {
           fprintf(stderr, "ERROR: HabitatSpace >>>> shouldFishMoveAt >>>> Simulation startStartTime is not midnight\n");
           fflush(0);
           exit(1);
       }

       //currentPhase = NIGHT;
       //phaseOfPrevStep = NIGHT;
       dayNightPhaseSwitch = FALSE;
       simStartMove = YES;
   }
   else
   {
       //
       // Otherwise, update day/night phases and see if movement
       // is triggered by a switch between day and night
       //   
       if(currentPhase == NIGHT)
       {
          //
          // Switch night->day
          //
          if(   (daytimeStartTime <= theCurrentTime) 
             && (daytimeEndTime > theCurrentTime))
          {
              //currentPhase = DAY;  
              //phaseOfPrevStep = NIGHT;
              dayNightPhaseSwitch = TRUE;
          }
       }
       else if(currentPhase == DAY)
       {

           //
           // Switch day->night
           // 
           if(daytimeEndTime <= theCurrentTime) 
           {
              //currentPhase = NIGHT;
              //phaseOfPrevStep = DAY;
              dayNightPhaseSwitch = TRUE;
           }
        }
        else
        {
            fprintf(stderr, "ERROR: HabitatSpace >>>> shouldFishMoveAt >>>> No currentPhase at model time Date %s hour %d\n", [timeManager getDateWithTimeT: theCurrentTime], [timeManager getHourWithTimeT: theCurrentTime]); 
            fflush(0);
            exit(1);
        }
    }         
   
    //
    // Now, see if movement is triggered by a flow change
    //  
    flowMove = [self getFlowChangeForMove];

    //
    // Return YES if anything triggered movement
    //
    if (dayNightPhaseSwitch || flowMove || simStartMove)
    {
       flowAtLastMove = currentHourlyFlow; 
    }

    return (dayNightPhaseSwitch || flowMove || simStartMove);
}


/////////////////////////////////////////////////////////////////////////
//
// updateMeanCellDepthAndVelocity
//
// Set the mean depth and velocities in each cell
//
///////////////////////////////////////////////////////////////////////
-  updateMeanCellDepthAndVelocity: (double) aMeanFlow 
{
    id <ListIndex> lstNdx = nil;
    FishCell* fishCell = (FishCell *) nil;

    lstNdx = [utmCellList listBegin: scratchZone];

    while(([lstNdx getLoc] != End) && ((fishCell = (FishCell *) [lstNdx next]) != (FishCell *) nil))
    {
         [fishCell calcDailyMeanDepthAndVelocityFor: aMeanFlow];
    }

    [lstNdx drop];


    return self;
}


///////////////////////////////////////////////////////////////////////
//
// updateHabitat
//
//////////////////////////////////////////////////////////////////////
- updateHabitat: (time_t) aTime 
{
  char *modelDate;
  time_t timeForDate;

  //fprintf(stdout, "UTMHabitatSpace >>>> updateHabitat >>>> BEGIN\n");
  //fflush(0);

  modelTime = aTime;
  modelDate = [timeManager getDateWithTimeT: modelTime];
  strncpy(Date, modelDate, strlen(modelDate) + 1);

  timeForDate = [timeManager getTimeTWithDate: Date];

  hour = [timeManager getHourWithTimeT: modelTime];

  //
  // Update the fish Cells
  //
  [self updateFishCells];

  //
  // Calculate the total wetted area of the cells
  //
  {
     id <ListIndex> ndx = [utmCellList listBegin: scratchZone];
     FishCell* fishCell = (FishCell *) nil;

     wettedArea = 0.0;

     while(([ndx getLoc] != End) && ((fishCell = (FishCell *) [ndx next]) != (FishCell *) nil))
     {
          if([fishCell getUTMCellDepth] > 0.0)
          {
             wettedArea += [fishCell getUTMCellArea];
          }
     }

     [ndx drop];
  }  

  //
  // The following has to be done before 
  // the cells update their survival probablities;
  // piscivorousFishDensity is a habitatSpace variable
  //
  // The fish now invoke this...
  //
  //[self calcPiscivorousFishDensity];

  if((currentPhase == DAY) && (dayNightPhaseSwitch == TRUE))
  {
     currentPhase = NIGHT;
  }
  else if((currentPhase == NIGHT) && (dayNightPhaseSwitch == TRUE))
  {
     currentPhase = DAY;
  }

  [self updateAnglePressureWith: modelTime];

  [utmCellList forEach: M(updateHabitatSurvivalProb)];
  [utmCellList forEach: M(updateDSCellHourlyTotal)];
  [utmCellList forEach: M(resetAvailHourlyTotal)];
  [utmCellList forEach: M(resetShelterAreaAvailable)];
  [utmCellList forEach: M(resetHidingCover)];


#ifdef HABITAT_REPORT_ON
  [self printHabitatReport];
#endif  

#ifdef VELOCITY_REPORT_ON
  [self printCellVelocityReport];
#endif  

#ifdef DEPTH_REPORT_ON
  [self printCellDepthReport];
#endif  

#ifdef DEPTH_VEL_RPT
  [self printCellAreaDepthVelocityRpt];
#endif


  //fprintf(stdout, "UTMHabitatSpace >>>> updateHabitat >>>> END\n");
  //fflush(0);

  return self;
}


////////////////////////////////////////
//
// updateHabSurvProbForAqPred
//
////////////////////////////////////////
- updateHabSurvProbForAqPred
{
   [utmCellList forEach: M(updateHabSurvProbForAqPred)];

   return self;
}


/////////////////////////////////////////////
//
// updateAnglePressureWith
//
////////////////////////////////////////////
- updateAnglePressureWith: (time_t) aTime
{
   int month = [timeManager getMonthWithTimeT: aTime];
  
   switch(month)
   {
       case 1:  anglingPressure = habAnglePressJan;
                break;
       case 2:  anglingPressure = habAnglePressFeb;
                break;
       case 3:  anglingPressure = habAnglePressMar;
                break;
       case 4:  anglingPressure = habAnglePressApr;
                break;
       case 5:  anglingPressure = habAnglePressMay;
                break;
       case 6:  anglingPressure = habAnglePressJun;
                break;
       case 7:  anglingPressure = habAnglePressJul;
                break;
       case 8:  anglingPressure = habAnglePressAug;
                break;
       case 9:  anglingPressure = habAnglePressSep;
                break;
       case 10: anglingPressure = habAnglePressOct;
                break;
       case 11: anglingPressure = habAnglePressNov;
                break;
       case 12: anglingPressure = habAnglePressDec;
                break;
       default: fprintf(stderr, "ERROR: HabitatSpace >>>> updateAnglePressure >>>> erroneous month\n");
                fflush(0);
                exit(1);
                break;

   }

   if(currentPhase == NIGHT)
   {
         //anglingPressure *= habAnglePressNightFactor;
         anglingPressure *= habAngleNightFactor;
   }


   return self;

}


//////////////////////////////////////////////////////
//
// updateFishCells
//
//////////////////////////////////////////////////////
- updateFishCells
{
   id <ListIndex> ndx = [utmCellList listBegin: scratchZone];
   FishCell* fishCell = nil;

   //fprintf(stdout, "HabitatSpace >>>> updateFishCells >>>> BEGIN\n");
   //fflush(0);

   while(([ndx getLoc] != End) && ((fishCell = [ndx next]) != nil))
   {
       [fishCell updateUTMCellVelocityWith: currentHourlyFlow];
       [fishCell updateUTMCellDepthWith: currentHourlyFlow];
   }

   [ndx drop];

   //fprintf(stdout, "HabitatSpace >>>> updateFishCells >>>> END\n");
   //fflush(0);

   return self;
}


//////////////////////////////////////// 
//
// getModelTime
//
////////////////////////////////////////
-(time_t) getModelTime 
{
   return modelTime;
}


////////////////////////////////////////////////////////////////
//
// getTemperature
//
///////////////////////////////////////////////////////////////
- (double) getTemperature 
{
  //fprintf(stdout, "UTMHabitatSpace >>>> getTemperature >>>> temperature = %f\n", temperature);
  //fflush(0);
  return temperature;
}

////////////////////////////////////////////////////////////////
//
// getTurbidity
//
///////////////////////////////////////////////////////////////
- (double) getTurbidity 
{
     return turbidity;
}



///////////////////////////////////////////////////////////
//
// getChangeInDailyFlow
//
//////////////////////////////////////////////////////////
- (double) getChangeInDailyFlow 
{
  return changeInDailyFlow;
}


//////////////////////////////////////////////////////////////
//
// getCurrentHourlyFlow
//
///////////////////////////////////////////////////////////
- (double) getCurrentHourlyFlow 
{
   return currentHourlyFlow;
}



/////////////////////////////////////
//
// getReachLength
//
/////////////////////////////////////
- (double) getReachLength
{
   return reachLength;
}


//////////////////////////////////////
//
// getDailyMeanFlow
//
/////////////////////////////////////
- (double) getDailyMeanFlow
{
    return dailyMeanFlow;
}

///////////////////////////////////
//
// getPrevDailyMeanFlow
//
///////////////////////////////////
- (double) getPrevDailyMeanFlow
{
   return prevDailyMeanFlow;
}

/////////////////////////////////////////
//
// getPrevDailyMaxFlow
//
/////////////////////////////////////////
- (double) getPrevDailyMaxFlow
{
   return prevDailyMaxFlow;
}


///////////////////////////////////////
//
// getDailyMaxFlow
//
//////////////////////////////////////
- (double) getDailyMaxFlow
{
   return dailyMaxFlow;
}


////////////////////////////////////////
//
// getNextDailyMaxFlow
//
////////////////////////////////////////
- (double) getNextDailyMaxFlow
{
    return nextDailyMaxFlow;
}




/////////////////////////////////////////////
//
// setStartTime:andEndTime
//
/////////////////////////////////////////////
- setStartTime: (time_t) startTime  andEndTime: (time_t) endTime {

  modelStartTime = startTime;
  modelEndTime = endTime;

  return self;

}


////////////////////////////////////
//
// setFishParamsMap
//
////////////////////////////////////
- setFishParamsMap: aMap
{
    fishParamsMap = aMap;
    return self;
}


- createDemonicIntrusionSymbol
{
  DemonicIntrusion = [Symbol create: habitatZone setName: "DemonicIntrusion"];
  return self;
}


- (id <Symbol>) getDemonicIntrusionSymbol 
{
  return DemonicIntrusion;
}


///////////////////////////////////////////////////////////////////
//
////              CELL REPORT METHODS
////// 
////////
///////////////////////////////////////////////////////////////////

- (BOOL) getFoodReportFirstTime 
{
   return foodReportFirstTime;
}

- setFoodReportFirstTime: (BOOL) aBool 
{
  foodReportFirstTime = aBool;
  return self;
}

- (BOOL) getDepthVelRptFirstTime
{
  return depthVelRptFirstTime;
}


- setDepthVelRptFirstTime: (BOOL) aBool
{
   depthVelRptFirstTime = aBool;
   return self;
}


////////////////////////////////////////////////////////////////////
//
////                       
//////              PRED DENSITY
///////
/////////
//////////
////////////////////////////////////////////////////////////////////

///////////////////////////////
//
// resetNumPiscFish
//
//////////////////////////////
- resetNumPiscivorousFish
{
   numPiscivorousFish = 0;
   return self;
}


////////////////////////////////////
//
// incrementNumPiscivorousFish
//
///////////////////////////////////
- incrementNumPiscivorousFish
{
    numPiscivorousFish++;
    return self;
}

//////////////////////////////////////////////////
//
// calcPiscivorousFishDensity
//
//////////////////////////////////////////////////
- (double) calcPiscivorousFishDensity
{
    piscivorousFishDensity = 0.0;

    /*
    if(wettedArea <= 0.0)
    {
       piscivorousFishDensity = 0.0;
    }
    else
    {
        piscivorousFishDensity = numPiscivorousFish/wettedArea;
    }
    */

    return piscivorousFishDensity; 
}



//////////////////////////////////////////////////////////////////
//
// getPiscivorousFishDensity
//
//////////////////////////////////////////////////////////////////
- (double) getPiscivorousFishDensity
{
   return piscivorousFishDensity;
}



/////////////////////////////////////////////////////////////////
//
////            HISTOGRAM OUTPUT
//////
////////     Note: the set and open messages are sent from the
//////////         *Observer* Swarm NOT the model swarm
////////////
/////////////////////////////////////////////////////////////////
- printCellFishInfo 
{
  #ifdef CELL_FISH_INFO

  //
  // Print the Cell fish info before the habitat space is updated
  // and after the fish have performed all of their 
  // daily actions
  //
  if(cellFishInfoFilePtr == NULL)
  {
     char* file = "CellFishInfo.Out";
     const char* format = "%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-17s%-17s%-17s%-5s%-5s%-5s%-5s\n"; 

     if([modelSwarm getAppendFiles] == NO)
     {
        if((cellFishInfoFilePtr = fopen(file, "w")) == NULL)
        {
               fprintf(stderr, "ERROR: HabitatSpace >>>> printCellFishInfo >>>> Cannot open %s \n", file);
               fflush(0);
               exit(1);
        }

        fprintf(cellFishInfoFilePtr, "System Date And Time  %s \n", [timeManager getSystemDateAndTime]); 
        fprintf(cellFishInfoFilePtr, "This file reports only fish that are feeding: ACTIVITY = DRIFT or SEARCH; see cell.m to modify\n");
        fprintf(cellFishInfoFilePtr, "\n");
        fprintf(cellFishInfoFilePtr, format, "Date",
                                             "Hour",
                                             "Phase",
                                             "CellNumber",
                                             "Area",
                                             "Depth",
                                             "Velocity",
                                             "CellDistToHide",
                                             "CellFracShelter",
                                             "FracHidingCover",
                                             "CellFracSpawn",
                                             "Age0",
                                             "Age1",
                                             "Age2",
                                             "Age3P");
        fflush(cellFishInfoFilePtr);
     }
     else if(([modelSwarm getAppendFiles] == YES) && ([modelSwarm getScenario] == 1) && ([modelSwarm getReplicate] == 1))
     {
        if((cellFishInfoFilePtr = fopen(file, "w")) == NULL)
        {
             fprintf(stderr, "ERROR: HabitatSpace >>>> printCellFishInfo >>>> Cannot open %s \n", file);
             fflush(0);
             exit(1);
        }

            fprintf(cellFishInfoFilePtr, "System Date And Time  %s \n", [timeManager getSystemDateAndTime]); 
            fprintf(cellFishInfoFilePtr, "Scenario = %d Replicate = %d\n", [modelSwarm getScenario], [modelSwarm getReplicate]); 
            fprintf(cellFishInfoFilePtr, format, "Date",
                                                 "Hour",
                                                 "Phase",
                                                 "CellNumber",
                                                 "Area",
                                                 "Depth",
                                                 "Velocity",
                                                 "CellDistToHide",
                                                 "CellFracShelter",
                                                 "FracHidingCover",
                                                 "CellFracSpawn",
                                                 "Age0",
                                                 "Age1",
                                                 "Age2",
                                                 "Age3P");
           fflush(cellFishInfoFilePtr);
     }
     else
     {
        if((cellFishInfoFilePtr = fopen(file, "a")) == NULL)
        {
            fprintf(stderr, "ERROR: HabitatSpace >>>> printCellFishInfo >>>> Cannot open %s \n", file);
            fflush(0);
            exit(1);
        }
      
        fprintf(cellFishInfoFilePtr, "\n"); 
        fprintf(cellFishInfoFilePtr, "\n"); 
        fprintf(cellFishInfoFilePtr, "Scenario = %d Replicate = %d\n", [modelSwarm getScenario], [modelSwarm getReplicate]); 
        fprintf(cellFishInfoFilePtr, "\n"); 
        fflush(cellFishInfoFilePtr);
     }
  }

  if(cellFishInfoFilePtr != NULL)
  {
      [utmCellList forEach: M(printCellFishInfo:): (void *) cellFishInfoFilePtr];
  }

  #endif  

  return self;
}



/*********************************************
*
*
*   UTM 
*
*
*
**********************************************/
-    setUTMRasterResolution: (int) aUTMRasterResolution
    setUTMRasterResolutionX: (int) aUTMRasterResolutionX
    setUTMRasterResolutionY: (int) aUTMRasterResolutionY
     setRasterColorVariable: (char *) aRasterColorVariable
           setShadeColorMax: (double) aShadeColorMax
{

  utmRasterResolution = aUTMRasterResolution;
  utmRasterResolutionX = aUTMRasterResolutionX;
  utmRasterResolutionY = aUTMRasterResolutionY;
  strncpy(utmRasterColorVariable, aRasterColorVariable, 35);
  shadeColorMax = aShadeColorMax;

  //fprintf(stdout, "HabitatSpace >>>> setUTMRaster ... >>>> utmRasterResolution = %d\n", utmRasterResolution);
  //fprintf(stdout, "HabitatSpace >>>> setUTMRaster ... >>>> utmRasterResolutionX = %d\n", utmRasterResolutionX);
  //fprintf(stdout, "HabitatSpace >>>> setUTMRaster ... >>>> utmRasterResolutionY = %d\n", utmRasterResolutionY);
  //fprintf(stdout, "HabitatSpace >>>> setUTMRaster ... >>>> utmRasterColorVariable = %s\n", utmRasterColorVariable);
  //fflush(0);

  return self;
}


/////////////////////////////////////////
//
// setShadeColorMax
//
//////////////////////////////////////////
- setShadeColorMax: (double) aShadeColorMax
{
  shadeColorMax = aShadeColorMax;
  return self;
}

//////////////////////////////////////////////
//
// readUTMHabSetupFile 
//
/////////////////////////////////////////////
- readUTMHabSetupFile: (char *) aFileName
{
   FILE* fptr = NULL;
   char header[300];
   char varName[50];
   char var[50];

   fprintf(stdout, "HabitatSpace >>>> readUTMHabSetupFile >>>> BEGIN\n");
   fflush(0);
 
   if((fptr = fopen(aFileName, "r")) == NULL)
   {
      fprintf(stderr, "ERROR: HabitatSpace >>>> readUPMHabSetupFile >>>> unable to open file named %s\n", aFileName);
      fflush(0);
      exit(1);
   }
 
   listOfUTMInputData = [List create: habitatZone];

   fgets(header, 300, fptr);
   fgets(header, 300, fptr);
   fgets(header, 300, fptr);


   //driftFoodFile = (char *) [habitatZone alloc: 51 * sizeof(char)];


   while(fscanf(fptr,"%s%s", varName, var) != EOF)
   {
        if(strcmp(varName, "reachName") == 0)
        {
           strncpy(reachName, var, 50);
        }
         
        if(strcmp(varName, "cellGeomFile") == 0)
        {
           strncpy(utmCellGeomFile, var, 50);
        }
         
        if(strcmp(varName, "flowFile") == 0)
        {
           strncpy(utmFlowFile, var, 50);
        }
         
        if(strcmp(varName, "temperatureFile") == 0)
        {
           strncpy(utmTemperatureFile, var, 50);
        }
         
        if(strcmp(varName, "turbidityFile") == 0)
        {
           strncpy(utmTurbidityFile, var, 50);
        }
         
        if(strcmp(varName, "cellHabVarsFile") == 0)
        {
           strncpy(utmCellHabVarsFile, var, 50);
        }
         
        if(strcmp(varName, "driftFoodFile") == 0)
        {
           strncpy(driftFoodFile, var, 50);
        }

        if(strcmp(varName, "reachLength") == 0)
        {
           reachLength = atof(var);
           reachLength = 100*reachLength; //Convert to cm
        }
 
        if(strcmp(varName, "reachFlow") == 0)
        {
           UTMInputData* utmInputData = [UTMInputData create: habitatZone];
           
           [listOfUTMInputData addLast: utmInputData];

           double reachFlow = atof(var);

           [utmInputData setUTMFlow: reachFlow];

           //
           // Read another line of input
           // Should be a velocity data file
           //
           fscanf(fptr,"%s %s", varName, var);
           
           if(strcmp(varName, "reachVelocityFile") != 0)
           {
               fprintf(stderr, "ERROR: HabitatSpace >>>> readUTMHabSetupFile >>>> velocity and depth files out of order\n");
               fflush(0);
               exit(1);
           }
           [utmInputData  setUTMVelocityDataFile: var];;

           //
           // Read another line of input
           // Should be a flow data file
           //
           fscanf(fptr,"%s %s", varName, var);
           if(strcmp(varName, "reachDepthFile") != 0)
           {
               fprintf(stderr, "ERROR: HabitatSpace >>>> readUTMHabSetupFile >>>> velocity and depth files out of order\n");
               fflush(0);
               exit(1);
           }

           [utmInputData  setUTMDepthDataFile: var];

        }
   } //while

   fprintf(stdout, "HabitatSpace >>>> readUTMHabSetupFile >>>> END\n");
   fflush(0);


   return self;
}


//////////////////////////////////////////////
//
// buildUTMCells
//
/////////////////////////////////////////////
- buildUTMCells
{
    fprintf(stdout, "HabitatSpace >>>> buildUTMCells >>>> BEGIN\n");
    fflush(0);

    utmCellList = [List create: habitatZone];
   
    [self readUTMCellGeometry];
    [self createUTMCells];
    [self createUTMCellCoordStructures];
    [self createUTMCellPixels];
    [self calcUTMCellCentroid];
    [self createUTMAdjacentCells];
    [self outputCellCentroidRpt];
    [self outputCellCorners];
    [self readUTMDataFiles];
    [self readUTMCellDataFile];
    [self createUTMInterpolationTables];

    fprintf(stdout, "HabitatSpace >>>> buildUTMCells >>>> END\n");
    fflush(0);
   

    return self;
}



////////////////////////////////////
//
// readUTMCellGeometry
//
///////////////////////////////////
- readUTMCellGeometry
{
    FILE* utmDataFPTR = NULL;
    char* dataFile = utmCellGeomFile;
    char inputString[200];
    char dataString[200];
    char* leadToken;
    char lineType[4];
    int utmCellNumber;
    int cornerNode1;
    int cornerNode2;
    int cornerNode3;
    int cornerNode4;
    int midPointNode1;
    int midPointNode2;
    int midPointNode3;
    int midPointNode4;
    int garbage1;
    double garbage2;

    int prevNode = 0;
    int node;
    double utmX;
    double utmY;
    double utmZ;


    fprintf(stderr, "HabitatSpace >>>> readUTMCellGeometry >>>> BEGIN\n");
    fflush(0);

    if((utmDataFPTR = fopen(dataFile, "r")) == NULL)
    {
         fprintf(stderr, "ERROR: HabitatSpace >>>> readUTMCellGeometry >>>> unable to open %s for reading\n", dataFile);
         fflush(0);
         exit(1);
    }

    maxUTMCellNumber = -1;
    maxNode = -1;
    while(fgets(inputString,200,utmDataFPTR) != NULL)
    {

         strncpy(dataString, inputString, 200);

         leadToken = strtok(inputString, " 	");
        
         if(strncmp(leadToken, "GE", 2) == 0)
         {
             FishCell* utmCell = nil;
             int numberOfNodes = 4;

             sscanf(dataString, "%s %d %d %d %d %d %d %d %d %d %d %lf", lineType,
                                                                        &utmCellNumber,
                                                                        &cornerNode1,
                                                                        &midPointNode1,
                                                                        &cornerNode2,
                                                                        &midPointNode2,
                                                                        &cornerNode3,
                                                                        &midPointNode3,
                                                                        &cornerNode4,
                                                                        &midPointNode4,
                                                                        &garbage1,
                                                                        &garbage2);

             /*
             fprintf(stdout, "%s %d %d %d %d %d %d %d %d %d %d %f\n", lineType, 
                                                                      utmCellNumber,
                                                                      cornerNode1,
                                                                      cornerNode2,
                                                                      cornerNode3,
                                                                      cornerNode4,
                                                                      midPointNode1,
                                                                      midPointNode2,
                                                                      midPointNode3,
                                                                      midPointNode4,
                                                                      garbage1,
                                                                      garbage2);
             fflush(0);
             */
         
             maxUTMCellNumber = (maxUTMCellNumber > utmCellNumber) ? maxUTMCellNumber : utmCellNumber;

             if(cornerNode1 == 0)
             {
                 numberOfNodes = 3;
             }
             if(cornerNode2 == 0)
             {
                 numberOfNodes = 3;
             }
             if(cornerNode3 == 0)
             {
                 numberOfNodes = 3;
             }
             if(cornerNode4 == 0)
             {
                 numberOfNodes = 3;
             }

             
             utmCell = [FishCell create: habitatZone]; 
             [utmCell setUTMCellNumber: utmCellNumber];
             [utmCell setNumberOfNodes: numberOfNodes];
             [utmCell setCornerNodesWith: cornerNode1
                             cornerNode2: cornerNode2
                             cornerNode3: cornerNode3
                             cornerNode4: cornerNode4];

             [utmCell setMidPointNodesWith: midPointNode1
                             midPointNode2: midPointNode2
                             midPointNode3: midPointNode3
                             midPointNode4: midPointNode4];

             [utmCellList addLast: utmCell];
             
         }
         else if(strncmp(leadToken, "GNN", 3) == 0)
         {
             sscanf(dataString, "%s %d %lf %lf %lf", lineType,
                                                      &node,
                                                      &utmX,
                                                      &utmY,
                                                      &utmZ);

             maxNode = (maxNode > node) ? maxNode : node;
         }
    }

    rewind(utmDataFPTR);


    //
    // Changed maxnode --> maxNode + 1 6jun08 skj
    //

    /*
    nodeUTMXArray = (double **) [ZoneAllocMapper allocBlockIn: habitatZone
                                                      ofSize: (size_t) (maxNode + 1) * sizeof(double)];
    nodeUTMYArray = (double **) [ZoneAllocMapper allocBlockIn: habitatZone
                                                      ofSize: (size_t) (maxNode + 1) * sizeof(double)];
    nodeUTMXArray[0] = (double *) [ZoneAllocMapper allocBlockIn: habitatZone
                                                            ofSize: sizeof(double)];
    nodeUTMYArray[0] = (double *) [ZoneAllocMapper allocBlockIn: habitatZone
                                                            ofSize: sizeof(double)];
    */

    nodeUTMXArray    = (double **) calloc((maxNode + 1), sizeof(double *));
    nodeUTMXArray[0] = (double *) calloc(1, sizeof(double));
    nodeUTMYArray    = (double **) calloc((maxNode + 1), sizeof(double *));
    nodeUTMYArray[0] = (double *) calloc(1, sizeof(double));

    nodeUTMXArray[0][0] = -1;
    nodeUTMYArray[0][0] = -1;


    while(fgets(inputString,200,utmDataFPTR) != NULL)
    {

         strncpy(dataString, inputString, 200);

         leadToken = strtok(inputString, " 	");
        
         if(strncmp(leadToken, "GNN", 3) == 0)
         {

              sscanf(dataString, "%s %d %lf %lf %lf", lineType,
                                                       &node,
                                                       &utmX,
                                                       &utmY,
                                                       &utmZ);

              utmX = 100.0 * utmX;
              utmY = 100.0 * utmY;
              utmZ = 100.0 * utmZ;

              //
              // utmZ is garbage
              //

              if((node - prevNode) == 1)
              {
                 /*
                  nodeUTMXArray[node] = (double *) [ZoneAllocMapper allocBlockIn: habitatZone
                                                                          ofSize: sizeof(double)];
                  nodeUTMYArray[node] = (double *) [ZoneAllocMapper allocBlockIn: habitatZone
                                                                          ofSize: sizeof(double)];
                  */

                  nodeUTMXArray[node] = (double *) calloc(1, sizeof(double));
                  nodeUTMYArray[node] = (double *) calloc(1, sizeof(double));

                  nodeUTMXArray[node][0] = utmX;
                  nodeUTMYArray[node][0] = utmY;
              }
              else
              {
                  int i;
                  for(i = prevNode + 1; i < node; ++i)
                  {
                      /*
                      nodeUTMXArray[i] = (double *) [ZoneAllocMapper allocBlockIn: habitatZone
                                                                           ofSize: sizeof(double)];
                      nodeUTMYArray[i] = (double *) [ZoneAllocMapper allocBlockIn: habitatZone
                                                                           ofSize: sizeof(double)];
                      */

                      nodeUTMXArray[i] = (double *) calloc(1, sizeof(double));
                      nodeUTMYArray[i] = (double *) calloc(1, sizeof(double));

                      nodeUTMXArray[i][0] = -1;
                      nodeUTMYArray[i][0] = -1;
                  }

                  /*
                  nodeUTMXArray[node] = (double *) [ZoneAllocMapper allocBlockIn: habitatZone
                                                                          ofSize: sizeof(double)];
                  nodeUTMYArray[node] = (double *) [ZoneAllocMapper allocBlockIn: habitatZone
                                                                          ofSize: sizeof(double)];
                  */

                  nodeUTMXArray[node] = (double *) calloc(1, sizeof(double));
                  nodeUTMYArray[node] = (double *) calloc(1, sizeof(double));
                  nodeUTMXArray[node][0] = utmX;
                  nodeUTMYArray[node][0] = utmY;

              }

                 
               /*
                  fprintf(stdout, "HabitatSpace >>>> readUTMCellGeometry >>>> maxNode = %d\n", maxNode);
                  fprintf(stdout, "HabitatSpace >>>> readUTMCellGeometry >>>> prevNode = %d\n", prevNode);
                  fprintf(stdout, "HabitatSpace >>>> readUTMCellGeometry >>>> node = %d\n", node);
                  fprintf(stdout, "HabitatSpace >>>> readUTMCellGeometry >>>> nodeUTMXArray = %p\n", nodeUTMXArray);
                  fprintf(stdout, "HabitatSpace >>>> readUTMCellGeometry >>>> nodeUTMXArray[node] = %p\n", nodeUTMXArray[node]);
                  fprintf(stdout, "HabitatSpace >>>> readUTMCellGeometry >>>> nodeUTMXArray[node][0] = %f\n", nodeUTMXArray[node][0]);
                  fflush(0);
                */
                  
              prevNode = node; 

         }
    }

    fclose(utmDataFPTR);

    //
    // Calculate the min and max UTM Coordinates
    //
    {
       int i;
       
       maxUTMEasting = 0.0;
       maxUTMNorthing = 0.0;
       for(i = 0; i <= maxNode; ++i)
       {
           if(nodeUTMXArray[i][0] != -1)
           {
               maxUTMEasting = (maxUTMEasting >= nodeUTMXArray[i][0]) ?
                                        maxUTMEasting : nodeUTMXArray[i][0];
           }
           if(nodeUTMYArray[i][0] != -1)
           {
               maxUTMNorthing = (maxUTMNorthing >= nodeUTMYArray[i][0]) ?
                                        maxUTMNorthing : nodeUTMYArray[i][0];
           }
       }


       minUTMEasting = maxUTMEasting;
       minUTMNorthing = maxUTMNorthing;
       for(i = 0; i <= maxNode; ++i)
       {
           if(nodeUTMXArray[i][0] != -1)
           {
               minUTMEasting = (minUTMEasting <= nodeUTMXArray[i][0]) ?
                                        minUTMEasting : nodeUTMXArray[i][0];
           }
           if(nodeUTMYArray[i][0] != -1)
           {
               minUTMNorthing = (minUTMNorthing <= nodeUTMYArray[i][0]) ?
                                        minUTMNorthing : nodeUTMYArray[i][0];
           }
       }
    }


    //reachLength = 
     
    utmSpaceSizeX = (unsigned int) (maxUTMEasting - minUTMEasting) + 0.5;
    utmSpaceSizeY = (unsigned int) (maxUTMNorthing - minUTMNorthing) + 0.5;

    utmPixelsX = utmSpaceSizeX;
    utmPixelsY = utmSpaceSizeY;

    spaceDimX = utmSpaceSizeX;
    spaceDimY = utmSpaceSizeY;

    /*
    fprintf(stdout, "HabitatSpace >>>> readUTMCellGeometry minUTMNorthing = %f\n", minUTMNorthing);
    fprintf(stdout, "HabitatSpace >>>> readUTMCellGeometry maxUTMNorthing = %f\n", maxUTMNorthing);
    fprintf(stdout, "HabitatSpace >>>> readUTMCellGeometry minUTMEasting = %f\n", minUTMEasting);
    fprintf(stdout, "HabitatSpace >>>> readUTMCellGeometry maxUTMEasting = %f\n", maxUTMEasting);
    fprintf(stdout, "HabitatSpace >>>> readUTMCellGeometry utmSpaceSizeX = %d\n", utmSpaceSizeX);
    fprintf(stdout, "HabitatSpace >>>> readUTMCellGeometry utmSpaceSizeY = %d\n", utmSpaceSizeY);
    fflush(0);
    */
 
    if(0)
    {
       int i;

       for(i = 0; i <= maxNode; ++i)
       {
            fprintf(stdout, "HabitatSpace >>>> readUTMCellGeometry nodeUTMXArray[%d][0] = %f\n", i, nodeUTMXArray[i][0]);
            fprintf(stdout, "HabitatSpace >>>> readUTMCellGeometry nodeUTMYArray[%d][0] = %f\n", i, nodeUTMYArray[i][0]);
            fflush(0);
       }
       exit(0);
    }



    fprintf(stderr, "HabitatSpace >>>> readUTMCellGeometry >>>> END\n");
    fflush(0);

    //exit(0);

    return self;
}


/////////////////////////////////////////////////////////
//
// createUTMCells
//
////////////////////////////////////////////////////////
- createUTMCells
{
   id <ListIndex> utmCellNdx = nil;
   FishCell* utmCell = nil;

   //FILE* outPtr = fopen("OutFile", "w");

   fprintf(stdout, "UTMHabitatSpace >>>> createUTMCells >>>> BEGIN\n");
   fflush(0);

   if(utmCellList == nil)
   {
       fprintf(stderr, "ERROR: UTMHabitatSpace >>>> createUTMCells >>>> utmCellList is nil\n");
       fflush(0);
       exit(1);
   }

   utmCellNdx = [utmCellList listBegin: scratchZone];

   while(([utmCellNdx getLoc] != End) && ((utmCell = [utmCellNdx next]) != nil))
   {

       int cornerNode1;
       int cornerNode2;
       int cornerNode3;
       int cornerNode4;

       double cornerNode1UTMX;
       double cornerNode1UTMY;
       double cornerNode2UTMX;
       double cornerNode2UTMY;
       double cornerNode3UTMX;
       double cornerNode3UTMY;
       double cornerNode4UTMX;
       double cornerNode4UTMY;

       int midPointNode1;
       int midPointNode2;
       int midPointNode3;
       int midPointNode4;

       double midPointNode1UTMX;
       double midPointNode1UTMY;
       double midPointNode2UTMX;
       double midPointNode2UTMY;
       double midPointNode3UTMX;
       double midPointNode3UTMY;
       double midPointNode4UTMX;
       double midPointNode4UTMY;


       cornerNode1 = [utmCell getCornerNode1];
       cornerNode2 = [utmCell getCornerNode2];
       cornerNode3 = [utmCell getCornerNode3];
       cornerNode4 = [utmCell getCornerNode4];

       if(cornerNode1 != 0)
       {
          cornerNode1UTMX = nodeUTMXArray[cornerNode1][0];
          cornerNode1UTMY = nodeUTMYArray[cornerNode1][0];
          [utmCell setCorner1UTMEasting:  cornerNode1UTMX];
          [utmCell setCorner1UTMNorthing: cornerNode1UTMY];
       }
       if(cornerNode2 != 0)
       {
           cornerNode2UTMX = nodeUTMXArray[cornerNode2][0];
           cornerNode2UTMY = nodeUTMYArray[cornerNode2][0];
           [utmCell setCorner2UTMEasting:  cornerNode2UTMX];
           [utmCell setCorner2UTMNorthing: cornerNode2UTMY];
       }
       if(cornerNode3 != 0)
       {
           cornerNode3UTMX = nodeUTMXArray[cornerNode3][0];
           cornerNode3UTMY = nodeUTMYArray[cornerNode3][0];
           [utmCell setCorner3UTMEasting:  cornerNode3UTMX];
           [utmCell setCorner3UTMNorthing: cornerNode3UTMY];
       }
       if(cornerNode4 != 0)
       {
           cornerNode4UTMX = nodeUTMXArray[cornerNode4][0];
           cornerNode4UTMY = nodeUTMYArray[cornerNode4][0];
           [utmCell setCorner4UTMEasting:  cornerNode4UTMX];
           [utmCell setCorner4UTMNorthing: cornerNode4UTMY];
       }

       midPointNode1 = [utmCell getMidPointNode1];
       midPointNode2 = [utmCell getMidPointNode2];
       midPointNode3 = [utmCell getMidPointNode3];
       midPointNode4 = [utmCell getMidPointNode4];

       midPointNode1UTMX = nodeUTMXArray[midPointNode1][0];
       midPointNode1UTMY = nodeUTMYArray[midPointNode1][0];
       midPointNode2UTMX = nodeUTMXArray[midPointNode2][0];
       midPointNode2UTMY = nodeUTMYArray[midPointNode2][0];
       midPointNode3UTMX = nodeUTMXArray[midPointNode3][0];
       midPointNode3UTMY = nodeUTMYArray[midPointNode3][0];
       midPointNode4UTMX = nodeUTMXArray[midPointNode4][0];
       midPointNode4UTMY = nodeUTMYArray[midPointNode4][0];


       /*
       
       fprintf(outPtr, "%d (%d %f %f) (%d %f %f) (%d %f %f) (%d %f %f) (%d %f %f) (%d %f %f) (%d %f %f) (%d %f %f) \n", cellNumber,  
                                                               cornerNode1,
                                                               cornerNode1UTMX,
                                                               cornerNode1UTMY,
                                                               cornerNode2,
                                                               cornerNode2UTMX,
                                                               cornerNode2UTMY,
                                                               cornerNode3,
                                                               cornerNode3UTMX,
                                                               cornerNode3UTMY,
                                                               cornerNode4,
                                                               cornerNode4UTMX,
                                                               cornerNode4UTMY,

                                                               midPointNode1,
                                                               midPointNode1UTMX,
                                                               midPointNode1UTMY,
                                                               midPointNode2,
                                                               midPointNode2UTMX,
                                                               midPointNode2UTMY,
                                                               midPointNode3,
                                                               midPointNode3UTMX,
                                                               midPointNode3UTMY,
                                                               midPointNode4,
                                                               midPointNode4UTMX,
                                                               midPointNode4UTMY);

       fflush(outPtr);
       */


   }

   //fclose(outPtr);

   if((utmRasterResolution <= 0) || (utmRasterResolutionX <= 0) || (utmRasterResolutionY <= 0))
   {
       fprintf(stdout, "ERROR: UTMHabitatSpace >>>> createUTMCells >>>> check utmRasterResolution varaiables\n");
       fflush(0);
       exit(1);
   }

   [utmCellNdx setLoc: Start];
   while(([utmCellNdx getLoc] != End) && ((utmCell = [utmCellNdx next]) != nil))
   {
       unsigned int corner1DisplayX;
       unsigned int corner1DisplayY;
       unsigned int corner2DisplayX;
       unsigned int corner2DisplayY;
       unsigned int corner3DisplayX;
       unsigned int corner3DisplayY;
       unsigned int corner4DisplayX;
       unsigned int corner4DisplayY;

       [utmCell setMinUTMEasting: minUTMEasting];
       [utmCell setMaxUTMNorthing: maxUTMNorthing];

       corner1DisplayX = (unsigned int) ([utmCell getCorner1UTMEasting] - minUTMEasting) + 0.5;
       corner1DisplayX = corner1DisplayX/utmRasterResolutionX + 0.5;
       corner1DisplayY = (unsigned int) (maxUTMNorthing - [utmCell getCorner1UTMNorthing]) + 0.5;
       corner1DisplayY = corner1DisplayY/utmRasterResolutionY + 0.5;

       corner2DisplayX = (unsigned int) ([utmCell getCorner2UTMEasting] - minUTMEasting) + 0.5;
       corner2DisplayX = corner2DisplayX/utmRasterResolutionX + 0.5;
       corner2DisplayY = (unsigned int) (maxUTMNorthing - [utmCell getCorner2UTMNorthing]) + 0.5;
       corner2DisplayY = corner2DisplayY/utmRasterResolutionY + 0.5;

       corner3DisplayX = (unsigned int) ([utmCell getCorner3UTMEasting] - minUTMEasting) + 0.5;
       corner3DisplayX = corner3DisplayX/utmRasterResolutionX + 0.5;
       corner3DisplayY = (unsigned int) (maxUTMNorthing - [utmCell getCorner3UTMNorthing]) + 0.5;
       corner3DisplayY = corner3DisplayY/utmRasterResolutionY + 0.5;

       corner4DisplayX = (unsigned int) ([utmCell getCorner4UTMEasting] - minUTMEasting) + 0.5;
       corner4DisplayX = corner4DisplayX/utmRasterResolutionX + 0.5;
       corner4DisplayY = (unsigned int) (maxUTMNorthing - [utmCell getCorner4UTMNorthing]) + 0.5;
       corner4DisplayY = corner4DisplayY/utmRasterResolutionY + 0.5;


       [utmCell setCorner1DisplayX: corner1DisplayX];
       [utmCell setCorner1DisplayY: corner1DisplayY];
   
       [utmCell setCorner2DisplayX: corner2DisplayX];
       [utmCell setCorner2DisplayY: corner2DisplayY];

       [utmCell setCorner3DisplayX: corner3DisplayX];
       [utmCell setCorner3DisplayY: corner3DisplayY];

       [utmCell setCorner4DisplayX: corner4DisplayX];
       [utmCell setCorner4DisplayY: corner4DisplayY];
       
       [utmCell setUTMRasterResolution: utmRasterResolution];
       [utmCell setUTMRasterResolutionX: utmRasterResolutionX];
       [utmCell setUTMRasterResolutionY: utmRasterResolutionY];
       [utmCell setUTMRasterColorVariable: utmRasterColorVariable];
       [utmCell setShadeColorMax: shadeColorMax];

       //
       // build the objects the cells will need.
       //
      
       [utmCell setSpace: self];
       [utmCell setModelSwarm: modelSwarm];
       [utmCell setTimeManager: timeManager];
       [utmCell setRandGen: randGen];
       [utmCell setNumberOfSpecies: numberOfSpecies];
       [utmCell setFishParamsMap: fishParamsMap];
       [utmCell initializeSurvProb];

       [utmCell setMinDisplayX: 0];
       [utmCell setMaxDisplayX: utmSpaceSizeX];
       [utmCell setMinDisplayY: 0];
       [utmCell setMaxDisplayY: utmSpaceSizeY];
       
       
   }

   [utmCellNdx drop];

   //
   // DO NOT drop this index.
   //
   utmCellListNdx = [utmCellList listBegin: habitatZone];

   fprintf(stdout, "HabitatSpace >>>> createUTMCells >>>> END\n");
   fflush(0);

   return self;
}



////////////////////////////////////////
//
// createUTMCellCoordStructures
//
////////////////////////////////////////
- createUTMCellCoordStructures
{
    fprintf(stdout, "HabitatSpace >>>> createUTMCellCoordStructures >>>> BEGIN\n");
    fflush(0);

    [utmCellList forEach: M(createUTMCellCoordStructures)];
   
    fprintf(stdout, "HabitatSpace >>>> createUTMCellCoordStructures >>>> END\n");
    fflush(0);
 
    return self;

}

////////////////////////////////////
//
// createUTMCellPixels;
//
///////////////////////////////////
- createUTMCellPixels
{
    fprintf(stdout, "HabitatSpace >>>> createUTMCellPixels >>>> BEGIN\n");
    fflush(0);

    [utmCellList forEach: M(createUTMCellPixels)];

    fprintf(stdout, "HabitatSpace >>>> createUTMCellPixels >>>> END\n");
    fflush(0);

    return self;
}


////////////////////////////////
//
// calcUTMCellCentroid
//
////////////////////////////////
- calcUTMCellCentroid
{
    fprintf(stdout, "HabitatSpace >>>> createUTMCellCentroid >>>> BEGIN\n");
    fflush(0);

    [utmCellList forEach: M(calcUTMCellCentroid)];

    fprintf(stdout, "HabitatSpace >>>> createUTMCellCentroid >>>> END\n");
    fflush(0);

    return self;
}


///////////////////////////////////////
//
// createUTMAdjacentCells
//
//////////////////////////////////////
- createUTMAdjacentCells
{
    fprintf(stdout, "HabitatSpace >>>> createUTMAdjacentCells >>>> BEGIN\n");
    fflush(0);

    id <ListIndex> ndx = [utmCellList listBegin: scratchZone];

    [utmCellList forEach: M(createUTMAdjacentCellsFrom:) :ndx];

    fprintf(stdout, "HabitatSpace >>>> createUTMAdjacentCells >>>> END\n");
    fflush(0);

    [ndx drop];

    return self;
}

///////////////////////////////////
//
// readUTMDataFiles
// 
//////////////////////////////////
- readUTMDataFiles
{
    id <ListIndex> ndx = nil;
    UTMInputData* utmInputData = nil;
 
    fprintf(stdout, "HabitatSpace >>>> readUTMDataFiles >>>> BEGIN\n");
    fflush(0);

    ndx = [listOfUTMInputData listBegin: scratchZone];

    while(([ndx getLoc] != End) && ((utmInputData = [ndx next]) != nil))
    {
         [utmInputData createVelocityArray];
         [utmInputData createDepthArray];
    }
 
    [ndx drop];    

    fprintf(stdout, "HabitatSpace >>>> readUTMDataFiles >>>> END\n");
    fflush(0);

    return self;
}



//////////////////////////////////
//
// readUTMCellDataFile
//
/////////////////////////////////
- readUTMCellDataFile
{
    int cellNumber     = 0;
    double fracShelter = 0.0;
    double distToHide  = 0.0;
    double fracSpawn   = 0.0;
    double fracHiding  = 0.0;

    FishCell* fishCell = (FishCell *) nil;

    char inputString[200];

    FILE* utmDataFPTR = NULL;

    fprintf(stdout, "HabitatSpace >>>> readUTMCellDataFile >>>> BEGIN\n");
    fflush(0);

    if((utmDataFPTR = fopen(utmCellHabVarsFile, "r")) == NULL)
    {
         fprintf(stderr, "ERROR: HabitatSpace >>>> readUTMCellDataFile >>>> unable to open %s for reading\n", utmCellHabVarsFile);
         fflush(0);
         exit(1);
    }

    
    if(utmCellListNdx == nil)
    {
         fprintf(stderr, "ERROR: HabitatSpace >>>> readUTMCellDataFile >>>> utmCellListNdx is nil\n");
         fflush(0);
         exit(1);
    }

    //
    // Read in the data
    //

    fgets(inputString,200,utmDataFPTR);
    fgets(inputString,200,utmDataFPTR);
    fgets(inputString,200,utmDataFPTR);

    while(fgets(inputString,200,utmDataFPTR) != NULL)
    {
       sscanf(inputString, "%d %lf %lf %lf %lf", &cellNumber,
                                                 &fracShelter,
                                                 &distToHide,
                                                 &fracSpawn,
                                                 &fracHiding);

       [utmCellListNdx setLoc: Start];

       distToHide = 100.0*distToHide;

       while(([utmCellListNdx getLoc] != End) && ((fishCell = (FishCell *) [utmCellListNdx next]) != (FishCell *) nil))
       {
            if([fishCell getUTMCellNumber] == cellNumber)
            {
               [fishCell setCellFracShelter: fracShelter];
               [fishCell setDistanceToHide: distToHide];
               [fishCell setCellFracSpawn: fracSpawn];
               [fishCell setFracHidingCover: fracHiding];
               [fishCell setCellDataSet: YES];

               [fishCell calcCellShelterArea];
            }
       }
    }
          
    //
    // When done ...
    //
    
    fclose(utmDataFPTR);

    [utmCellListNdx setLoc: Start];

    while(([utmCellListNdx getLoc] != End) && ((fishCell = [utmCellListNdx next]) != nil))
    {
         [fishCell checkCellDataSet];
    }

    //
    // Do not drop utmCellListNdx
    //


    fprintf(stdout, "HabitatSpace >>>> readUTMCellDataFile >>>> END\n");
    fflush(0);

    return self;
}


/////////////////////////////////////////
//
// createUTMInterpolationTables
//
/////////////////////////////////////////
- createUTMInterpolationTables
{
    id <ListIndex> ndx = [utmCellList listBegin: scratchZone];
    UTMCell* utmCell = nil;

    fprintf(stdout, "HabitatSpace >>>> createUTMInterpolationTables >>>> BEGIN\n");
    fflush(0);

    //
    // Sort the flows from smallest to largest
    //
    [QSort sortObjectsIn: listOfUTMInputData using: M(compareFlows:)];

    utmInterpolatorFactory = [UTMInterpolatorFactory create: habitatZone];
    [utmInterpolatorFactory setListOfUTMInputData: listOfUTMInputData];
    
    while(([ndx getLoc] != End) && ((utmCell = [ndx next]) != nil))
    {
          [utmInterpolatorFactory setUTMCell: utmCell];
          [utmInterpolatorFactory createUTMVelocityInterpolator];
          [utmInterpolatorFactory createUTMDepthInterpolator];
    }
 
    [ndx setLoc: Start];

    while(([ndx getLoc] != End) && ((utmCell = [ndx next]) != nil))
    {
          [utmInterpolatorFactory setUTMCell: utmCell];
          [utmInterpolatorFactory updateUTMVelocityInterpolator];
          [utmInterpolatorFactory updateUTMDepthInterpolator];
    }


    [ndx drop];

    fprintf(stdout, "HabitatSpace >>>> createUTMInterpolationTables >>>> END\n");
    fflush(0);

    return self;
}

/////////////////////////////////////////////
//
// outputCellCentroidRpt
//
/////////////////////////////////////////////
- outputCellCentroidRpt
{
    FILE* fptr = NULL;
    const char* fileName = "CellCentroids.rpt";
    id <ListIndex> ndx = nil;
    FishCell* fishCell = nil;

    const char* headerFmt = "%-14s%-24s%-24s\n";
    const char* dataFmt = "%-14d%-24f%-24f\n";

    fprintf(stdout, "UTMHabitatSpace >>>> outputCellCentroidRpt >>>> BEGIN\n");
    fflush(0);

    if((fptr = fopen(fileName, "w")) == NULL)
    {
        fprintf(stdout, "ERROR: UTMHabitatSpace >>>> outputCellCentroidRpt >>>> Unable to open file %s for writing\n", fileName);
        fflush(0);
        exit(1);
    } 

    ndx = [utmCellList listBegin: scratchZone];

    fprintf(fptr, "Cell centroid UTM coordinates for HabitatSpace : %s System date and time: %s\n\n", "HabitatSpace", [timeManager getSystemDateAndTime]); 
    fprintf(fptr, headerFmt, "CellNumber", "CentroidX", "CentroidY"); 
    fflush(fptr);

    while(([ndx getLoc] != End) && ((fishCell = [ndx next]) != nil))
    {
        int utmCellNumber = [fishCell getUTMCellNumber];
        double utmCenterX = [fishCell getUTMCenterX]/100.0;
        double utmCenterY = [fishCell getUTMCenterY]/100.0;

        fprintf(fptr, dataFmt, utmCellNumber,
                               utmCenterX,
                               utmCenterY);
        fflush(fptr);
    }

    fclose(fptr);
    [ndx drop];

    fprintf(stdout, "UTMHabitatSpace >>>> outputCellCentroidRpt >>>> END\n");
    fflush(0);

    return self;
}

/////////////////////////////////////////////
//
// outputCellCornersRpt
//
/////////////////////////////////////////////
- outputCellCorners
{
    FILE* fptr = NULL;
    const char* fileName = "CellCorners.rpt";
    id <ListIndex> ndx = nil;
    FishCell* fishCell = nil;

    const char* headerFmt = "%-14s%-24s%-24s%-24s%-24s%-24s%-24s%-24s%-24s\n";
    const char* dataFmt = "%-14d%-24f%-24f%-24f%-24f%-24f%-24f%-24f%-24f\n";

    fprintf(stdout, "UTMHabitatSpace >>>> outputCellCorners >>>> BEGIN\n");
    fflush(0);

    if((fptr = fopen(fileName, "w")) == NULL)
    {
        fprintf(stdout, "ERROR: UTMHabitatSpace >>>> outputCellCorners >>>> Unable to open file %s for writing\n", fileName);
        fflush(0);
        exit(1);
    } 

    ndx = [utmCellList listBegin: scratchZone];

    fprintf(fptr, "Cell corner UTM coordinates for HabitatSpace: %s System date and time: %s\n\n", "HabitatSpace", [timeManager getSystemDateAndTime]); 
    fprintf(fptr, headerFmt, "CellNumber", "Corner1X", "Corner1Y", "Corner2X", "Corner2Y", "Corner3X", "Corner3Y", "Corner4X", "Corner4Y");
    fflush(fptr);

    while(([ndx getLoc] != End) && ((fishCell = [ndx next]) != nil))
    {
        int utmCellNumber = [fishCell getUTMCellNumber];
        double corner1UTMEasting = [fishCell getCorner1UTMEasting]/100.0;
        double corner1UTMNorthing = [fishCell getCorner1UTMNorthing]/100.0;
        double corner2UTMEasting = [fishCell getCorner2UTMEasting]/100.0;
        double corner2UTMNorthing = [fishCell getCorner2UTMNorthing]/100.0;
        double corner3UTMEasting = [fishCell getCorner3UTMEasting]/100.0;
        double corner3UTMNorthing = [fishCell getCorner3UTMNorthing]/100.0;
        double corner4UTMEasting = [fishCell getCorner4UTMEasting]/100.0;
        double corner4UTMNorthing = [fishCell getCorner4UTMNorthing]/100.0;

        fprintf(fptr, dataFmt, utmCellNumber,
                               corner1UTMEasting,
                               corner1UTMNorthing,
                               corner2UTMEasting,
                               corner2UTMNorthing,
                               corner3UTMEasting,
                               corner3UTMNorthing,
                               corner4UTMEasting,
                               corner4UTMNorthing);
        fflush(fptr);
    }

    fclose(fptr);
    [ndx drop];

    fprintf(stdout, "UTMHabitatSpace >>>> outputCellCorners >>>> END\n");
    fflush(0);

    return self;
}

/////////////////////////////////////////////
//
// setDataStartTime:andDataEndTime
//
/////////////////////////////////////////////
- setDataStartTime: (time_t) aDataStartTime
    andDataEndTime: (time_t) aDataEndTime
{
    dataStartTime = aDataStartTime;
    dataEndTime = aDataEndTime;

    return self;
}

///////////////////////////////////////////////
//
// createTimeSeriesInputManagers
//
///////////////////////////////////////////////
- createTimeSeriesInputManagers
{
   fprintf(stdout, "UTMHabitatSpace >>>> createTimeSeriesInputManagers >>>> BEGIN\n");
   fflush(0);
   
   flowInputManager = [TimeSeriesInputManager  createBegin: habitatZone
                                              withDataType: "HOURLY"
                                             withInputFile: utmFlowFile
                                           withTimeManager: timeManager
                                             withStartTime: dataStartTime
                                               withEndTime: dataEndTime
                                             withCheckData: NO];

   flowInputManager = [flowInputManager createEnd];

   temperatureInputManager = [TimeSeriesInputManager  createBegin: habitatZone
                                                     withDataType: "DAILY"
                                                    withInputFile: utmTemperatureFile
                                                  withTimeManager: timeManager
                                                    withStartTime: dataStartTime
                                                      withEndTime: dataEndTime
                                                    withCheckData: NO];

   temperatureInputManager = [temperatureInputManager createEnd];

   turbidityInputManager = [TimeSeriesInputManager  createBegin: habitatZone
                                                   withDataType: "DAILY"
                                                  withInputFile: utmTurbidityFile
                                                withTimeManager: timeManager
                                                  withStartTime: dataStartTime
                                                    withEndTime: dataEndTime
                                                  withCheckData: NO];

   turbidityInputManager = [turbidityInputManager createEnd];

   driftFoodInputManager = [TimeSeriesInputManager  createBegin: habitatZone
                                                   withDataType: "HOURLY"
                                                  withInputFile: driftFoodFile
                                                withTimeManager: timeManager
                                                  withStartTime: dataStartTime
                                                    withEndTime: dataEndTime
                                                  withCheckData: NO];

   driftFoodInputManager = [driftFoodInputManager createEnd];

   fprintf(stdout, "UTMHabitatSpace >>>> createTimeSeriesInputManagers >>>> END\n");
   fflush(0);

    return self;
}




/////////////////////////////
//
// getUTMCellList
//
///////////////////////////////
- (id <List>) getUTMCellList
{
    return utmCellList;
}


///////////////////////////////
//
// getUTMPixelsX
// 
///////////////////////////////
- (unsigned int) getUTMPixelsX
{
    return utmPixelsX;
}


////////////////////////////////
//
// getUTMPixelsY
//
///////////////////////////////
- (unsigned int) getUTMPixelsY
{
     return utmPixelsY;
}


////////////////////////////////
//
// getSpaceDimX
//
///////////////////////////////
- (int) getSpaceDimX 
{
   return spaceDimX;
}

////////////////////////////////
//
// getSpaceDimY
//
///////////////////////////////
- (int) getSpaceDimY 
{
   return spaceDimY;
}


///////////////////////////////////////////////////////////////////////////
//
// probeUTMCellAtX:Y
//
//////////////////////////////////////////////////////////////////////////
#import <simtoolsgui.h>
- probeUTMCellAtX: (int) probedX Y: (int) probedY 
{
  id <ListIndex> lstNdx = nil;
  id utmCell=nil;

  /*
  fprintf(stdout, "UTMHabitatSpace >>>> probeUTMCellAtX:Y >>>> BEGIN\n");
  fprintf(stdout, "UTMHabitatSpace >>>> probeUTMCellAtX:Y >>>> probedX = %d\n", probedX);
  fprintf(stdout, "UTMHabitatSpace >>>> probeUTMCellAtX:Y >>>> probedY = %d\n", probedY);
  fflush(0);
  */


  lstNdx = [utmCellList listBegin: scratchZone];

  while(([lstNdx getLoc] != End) && ((utmCell = [lstNdx next]) != nil))
  {
        if([utmCell containsRasterX: probedX 
                         andRasterY: probedY])
        {
             break;
        }
  }

  [lstNdx drop];

  if(utmCell != nil)
  {
      CREATE_ARCHIVED_PROBE_DISPLAY (utmCell);
  }

  //fprintf(stdout, "UTMHabitatSpace >>>> probeUTMCellAtX:Y >>>> END\n");
  //fflush(0);

  return self;
}





/////////////////////////////////////
//
// getUTMCellAtX
//
/////////////////////////////////////
- getUTMCellAtX: (int) anX
              Y: (int) aY
{

  id <ListIndex> lstNdx = nil;
  id utmCell=nil;

  lstNdx = [utmCellList listBegin: scratchZone];

  while(([lstNdx getLoc] != End) && ((utmCell = [lstNdx next]) != nil))
  {
        if([utmCell containsRasterX: anX 
                         andRasterY: aY])
        {
             break;
        }
  }

  [lstNdx drop];

  return utmCell;
}


////////////////////////////////////////////////
//
// probeFishAtX
//
////////////////////////////////////////////////
- probeFishAtX: (int) probedX Y: (int) probedY 
{
  FishCell*  fishCell = nil;
  UTMTrout* fish = (UTMTrout *) nil;
  UTMRedd* redd = (UTMRedd *) nil;
  id <ListIndex> fishNdx = nil;
  id <ListIndex> reddNdx = nil;

   //
   // get the fishCell
   //
   fishCell = [self getUTMCellAtX: probedX Y: probedY];

   if(fishCell != nil)
   {
       fishNdx = [[fishCell getFishList] listBegin: scratchZone];
       while(([fishNdx getLoc] != End) && ((fish = [fishNdx next]) != nil)) 
       {
         //
         // At this time this will create a a probe display for each fish in the Cell
         //
         CREATE_PROBE_DISPLAY(fish);
      }

      [fishNdx drop];

      reddNdx = [[fishCell getReddList] listBegin: scratchZone];
      while(([reddNdx getLoc] != End) && ((redd = [reddNdx next]) != nil)) 
      {
         //
         // At this time this will create a a probe display for each redd in the Cell
         //
         CREATE_PROBE_DISPLAY(redd);
      }

      [reddNdx drop];
  }

  return self;
}



////////////////////////////////////////////////////////////////////////
//
// getNeighborsWithin
//
// Comment: List of neighbors does not include self
//
///////////////////////////////////////////////////////////////////////
- (id <List>) getNeighborsWithin: (double) aRange 
                              of: refCell 
                        withList: (id <List>) aCellList
{
  id <ListIndex> cellNdx;
  id tempCell;
  id <List> listOfCellsWithinRange = aCellList;
  id <List> adjacentCells = [refCell getListOfAdjacentCells];
  int adjacentCellCount;

  double utmRefCenterX = [refCell getUTMCenterX];
  double utmRefCenterY = [refCell getUTMCenterY];

  double utmDist = 0.0;

  cellNdx = [utmCellList listBegin: scratchZone];

  //fprintf(stdout, "HabitatSpace >>>> getNeigborsWithin >>>> BEGIN\n");
  //fflush(0);

  if(listOfCellsWithinRange == nil)
  {
      fprintf(stderr, "ERROR: HabitatSpace >>>> getNeighborsWithin >>>> listOfCellsWithinRange is nil\n");
      fflush(0);
      exit(1);
  }
  if([listOfCellsWithinRange getCount] != 0)
  {
      // 
      // The list from the fish must be empty
      //
      fprintf(stderr, "ERROR: HabitatSpace >>>> getNeighborsWithin >>>> listOfCellsWithinRange is not empty\n");
      fflush(0);
      exit(1);
  }

  if(adjacentCells == nil)
  {
      fprintf(stderr, "ERROR: HabitatSpace >>>> getNeighborsWithin >>>> adjacentCells is nil\n");
      fflush(0);
      exit(1);
  }

  adjacentCellCount = [adjacentCells getCount];

  if(adjacentCellCount == 0)
  {
      // 
      // The list of adjacent cells shouldn't be empty
      //
      fprintf(stderr, "ERROR: HabitatSpace >>>> getNeighborsWithin >>>> adjacentCells is empty\n");
      fflush(0);
      exit(1);
  }

  while(([cellNdx getLoc] != End) && ((tempCell = [cellNdx next]) != nil)) 
  {
     double utmCenterX;
     double utmCenterY;

     double utmCenterDiffSquareX;
     double utmCenterDiffSquareY;

     
     if(refCell == tempCell)
     {
         continue;
     }

     utmCenterX = [tempCell getUTMCenterX];
     utmCenterY = [tempCell getUTMCenterY];

     utmCenterDiffSquareX = (utmCenterX - utmRefCenterX);
     utmCenterDiffSquareY = (utmCenterY - utmRefCenterY);

     utmCenterDiffSquareX = utmCenterDiffSquareX * utmCenterDiffSquareX;
     utmCenterDiffSquareY = utmCenterDiffSquareY * utmCenterDiffSquareY;

     utmDist = sqrt(utmCenterDiffSquareX + utmCenterDiffSquareY); 
   
     if(utmDist <= aRange)
     {
        [listOfCellsWithinRange addLast: tempCell];
     }

  }
        
  //
  // Now, ensure listOfCellsWithinRange contains refCell's
  // adjacentCells
  //
  {
     int i;
     for(i = 0; i < adjacentCellCount; i++)
     {
         FishCell* adjacentCell = [adjacentCells atOffset: i]; 
         if([listOfCellsWithinRange contains: adjacentCell] == NO)
         {
            [listOfCellsWithinRange addLast: adjacentCell];
         }
     } 
  }

  [cellNdx drop];

  //fprintf(stdout, "HabitatSpace >>>> getNeigborsWithin >>>> END\n");
  //fflush(0);

  return listOfCellsWithinRange;
}


///////////////////////////////////////
//
// tagCellNumber
//
//////////////////////////////////////
- tagCellNumber: (int) aCellNumber
{
   id <ListIndex> lstNdx = [utmCellList listBegin: scratchZone];
   FishCell* fishCell = nil;

   while(([lstNdx getLoc] != End) && ((fishCell = [lstNdx next]) != nil))
   {
         if(aCellNumber == [fishCell getUTMCellNumber])
         {
              [fishCell tagUTMCell];
              break;
         }
   }
        
   [lstNdx drop];

   [modelSwarm redrawRaster];

   return self;
}

///////////////////////////////////////
//
// untagCellNumber
//
//////////////////////////////////////
- untagCellNumber: (int) aCellNumber
{
   id <ListIndex> lstNdx = [utmCellList listBegin: scratchZone];
   FishCell* fishCell = nil;

   while(([lstNdx getLoc] != End) && ((fishCell = [lstNdx next]) != nil))
   {
         if(aCellNumber == [fishCell getUTMCellNumber])
         {
              [fishCell unTagUTMCell];
              break;
         }
   }
        
   [lstNdx drop];

   [modelSwarm redrawRaster];

   return self;
}

/////////////////////////////////////////////
//
// untagAllCells
//
////////////////////////////////////////////
- untagAllCells
{
     [utmCellList forEach: M(untagAllCells)];
     [modelSwarm redrawRaster];
     return self;
}



/////////////////////////////////////
//
// redrawRaster
//
//////////////////////////////////////
- redrawRaster
{
    [modelSwarm redrawRaster];
    return self;
}

#ifdef HABITAT_REPORT_ON
///////////////////////////////////////
//
// printHabitatReport
//
///////////////////////////////////////
- printHabitatReport 
{
  FILE* reportPtr=NULL;
  const char* fileName = "HabitatTest.rpt";
  double aFlow = 0.0;
  int currentHour = [timeManager getHourWithTimeT: modelTime]; 
  
  if(habitatReportFirstWrite == YES) 
  {
      if((reportPtr = fopen(fileName,"w")) == NULL)
      {
           fprintf(stderr, "ERROR: UTMHabitatSpace >>>> printHabitatReport >>>> Cannot open file %s\n", fileName);
           fflush(0);
           exit(1);
      }

      //
      // Print the header the first time only...
      //
      fprintf(reportPtr,"%-12s%-12s%-12s%-12s%-12s%-12s%-12s\n","Date",
                                                      "CurrentHour",
                                                      "DayLength",
                                                      "Flow",
                                                      "Temperature",
                                                      "Turbidity",
                                                      "HabDriftConc");
      fflush(reportPtr);
  }


  if(habitatReportFirstWrite == NO) 
  {
    if((reportPtr = fopen(fileName,"a")) == NULL)
    {
         fprintf(stderr, "ERROR: UTMHabitatSpace >>>> printHabitatReport >>>> Cannot open file %s", fileName);
         fflush(0);
         exit(1);
    }
  }

  aFlow = [flowInputManager getValueForTime: modelTime];

  fprintf(reportPtr,"%-12s%-12d%-12f%-12f%-12f%-12f%-12E\n",[timeManager getDateWithTimeT: modelTime], 
                                                  currentHour,
                                                  dayLength, 
                                                  aFlow, 
                                                  temperature, 
                                                  turbidity,
                                                  habDriftConc);
  fflush(reportPtr);
   

  habitatReportFirstWrite = NO;

  fclose(reportPtr);

  return self;
}
#endif



#ifdef VELOCITY_REPORT_ON
///////////////////////////////////
//
// printCellVelocityReport 
//
//////////////////////////////////
- printCellVelocityReport 
{
  FILE * reportPtr=NULL;
  const char *fileName = "CellFlowVelocityTest.rpt";

  id <ListIndex> cellNdx;
  FishCell* nextCell = (FishCell *) nil;
  int cellNo;

  double myRiverFlow;
  double velocity;

  BOOL loopFirstTime=YES;

  if(velocityReportFirstWrite == YES) 
  {
      if((reportPtr = fopen(fileName,"w+")) == NULL ) 
      {
          fprintf(stderr, "ERROR: UTMHabitatSpace >>>> printCellVelocityReport >>>> Cannot open file %s", fileName);
          fflush(0);
          exit(1);
      }

      //fprintf(reportPtr,"%-12s%-12s%-12s\n","CellNumber", "RiverFlow", "CellVelocities:");
      //fflush(reportPtr);
  }

  if(velocityReportFirstWrite == NO) 
  {
     if((reportPtr = fopen(fileName,"a")) == NULL)
     {
        fprintf(stderr, "ERROR: UTMHabitatSpace >>>> printCellVelocityReport >>>> Cannot open file %s", fileName);
        fflush(0);
        exit(1);
     }
  }

  fprintf(reportPtr, "\n\n\n");
  fflush(reportPtr);

  cellNdx = [utmCellList listBegin: scratchZone];
  while(([cellNdx getLoc] != End) && ((nextCell = (FishCell *)[cellNdx next]) != (FishCell *) nil)) 
  {
       cellNo   =    [nextCell getUTMCellNumber];
       myRiverFlow = [nextCell getCurrentHourlyFlow];  //this is the habitatSpace's currentHourlyFlow
       velocity    = [nextCell getUTMCellVelocity];

       if(loopFirstTime == YES) 
       {
          fprintf(reportPtr,"%-12s: %f\n", "RiverFlow", myRiverFlow);
          fflush(reportPtr);
          fprintf(reportPtr,"%-12s%-12s\n", "CellNumber", "CellVelocity");
          fflush(reportPtr);
          loopFirstTime = NO;
       }

       fprintf(reportPtr,"%-12d%-12f\n", cellNo, velocity);
       fflush(reportPtr);
  }


  [cellNdx drop];
  fclose(reportPtr);

  velocityReportFirstWrite = NO;

  return self;
}
#endif




#ifdef DEPTH_VEL_RPT
/////////////////////////////////////
//
// printCellAreaDepthVelocityRpt 
//
/////////////////////////////////////
- printCellAreaDepthVelocityRpt 
{
  FILE* depthVelPtr = NULL;
  const char* depthVelFile = "CellDepthAreaVelocity.rpt";

  if(depthVelRptFirstTime == YES)
  {
     if((depthVelPtr = fopen(depthVelFile, "w")) == NULL) 
     {
         fprintf(stderr, "ERROR: UTMHabitatSpace >>>> printCellAreaDepthVelocityRpt >>>> Cannot open %s for writing\n", depthVelFile);
         fflush(0);
         exit(1);
     }
  }

  if(depthVelRptFirstTime == NO) 
  {
      if((depthVelPtr = fopen(depthVelFile,"a")) == NULL) 
      {
          fprintf(stderr, "ERROR: UTMHabitatSpace >>>> printCellAreaDepthVelocityRpt >>>> Cannot open %s for writing\n", depthVelFile);
          fflush(0);
          exit(1);
      }
  }

  [utmCellList forEach: M(depthVelReport:) : (void *) depthVelPtr];

  fclose(depthVelPtr);

  depthVelRptFirstTime = NO;

  return self;
}

#endif


#ifdef DEPTH_REPORT_ON
///////////////////////////////
//
// printCellDepthReport
//
///////////////////////////////
- printCellDepthReport 
{
  FILE * reportPtr=NULL;
  const char *fileName = "CellFlowDepthTest.rpt";

  BOOL loopFirstTime=YES;

  id <ListIndex> cellNdx;
  id nextCell;
  int cellNo;
  double myRiverFlow;
  double depth;

  if(depthReportFirstWrite == YES) 
  {
      if( (reportPtr = fopen(fileName,"w+")) == NULL ) 
      {
          fprintf(stderr, "ERROR: UTMHabitatSpace >>>> printCellDepthReport >>>> Cannot open file %s\n", fileName);
          fflush(0);
          exit(1);
      }
      //fprintf(reportPtr,"%-12s%-12s\n", "RiverFlow", "CellDepths:");
      //fflush(reportPtr);
  }

  if(depthReportFirstWrite == NO) 
  {
      if((reportPtr = fopen(fileName,"a")) == NULL)
      {
          fprintf(stderr, "ERROR: UTMHabitatSpace >>>> printCellDepthReport >>>> Cannot open file %s\n", fileName);
          fflush(0);
          exit(1);
      }
  }

  cellNdx = [utmCellList listBegin: [self getZone]];
  while(([cellNdx getLoc] != End) && ((nextCell = [cellNdx next]) != nil)) 
  {
       cellNo   =    [nextCell getUTMCellNumber];
       myRiverFlow = [nextCell getCurrentHourlyFlow];  //this is the habitatSpace's currentHourlyFlow
       depth    =    [nextCell getUTMCellDepth];

       if(loopFirstTime == YES) 
       {
          fprintf(reportPtr,"%-12s: %f\n", "RiverFlow", myRiverFlow);
          fflush(reportPtr);
          fprintf(reportPtr,"%-12s%-12s\n", "CellNumber", "CellDepths");
          fflush(reportPtr);
          loopFirstTime = NO;
       }

       fprintf(reportPtr,"%-12d%-12f\n", cellNo, depth);
       fflush(reportPtr);
  }
      
  [cellNdx drop];
  fclose(reportPtr);

  depthReportFirstWrite = NO;

  return self;
}
#endif




//////////////////////////////////////////
//
// switchColorRep
//
//////////////////////////////////////////
- switchColorRep
{
    //
    // Tell the model swarm to tell the observerSwarm 
    // to change from velocity colormap to depth colormap
    // or vice versa
    //
    
    [modelSwarm switchColorRep];

    return self;
}


////////////////////////////////////////////////
//
// updateCells
//
//////////////////////////////////////////////
- updateCells
{
    id <ListIndex> lstNdx = [utmCellList listBegin: scratchZone];
    FishCell* fishCell = nil;
    while(([lstNdx getLoc] != End) && ((fishCell = [lstNdx next]) != nil))
    {
        [fishCell toggleColorRep: shadeColorMax];
    }

    [lstNdx drop];
    return self;
}
     
//////////////////////////////////////////////////
//
// writeDepthsAndVelsToFile
//
//////////////////////////////////////////////////
- writeDepthsAndVelsToFile: (char *) aDepthVelsFile
{
    FILE* fptr = NULL;
    id <ListIndex> lstNdx = [utmCellList listBegin: scratchZone];
    FishCell* aFishCell = nil;

    //fprintf(stdout, "UTMHabitatSpace >>>>  writeDepthsAndVelsToFile >>>> BEGIN\n");
    //fflush(0);

     if((fptr = fopen(aDepthVelsFile, "w")) == NULL)
     { 
        fprintf(stderr, "WARNING: UTMHabitatSpace >>>> writeDepthsAndVelsToFile >>>> unable to write to file %s\n", aDepthVelsFile);
        fflush(0);
        return self;
     }

     fprintf(fptr, "System Date & Time: %s\n", [timeManager getSystemDateAndTime]);
     fprintf(fptr, "CurrentFlow: %f\n", currentHourlyFlow);
     fprintf(fptr, "%-14s%-14s%-14s\n", "CellNumber", "Depth", "Velocity"); 
     fflush(fptr);
    
     while(([lstNdx getLoc] != End) && ((aFishCell = [lstNdx next]) != nil))
     {
              
        fprintf(fptr, "%-14d%-14.1f%-14.1f\n", [aFishCell getUTMCellNumber],
                                               [aFishCell getUTMCellDepth], 
                                               [aFishCell getUTMCellVelocity]);
        fflush(fptr);
    }   

    fprintf(fptr, "\n\n"),
    fflush(fptr);

    [lstNdx drop];
    fclose(fptr);

    //fprintf(stdout, "UTMHabitatSpace >>>>  writeDepthsAndVelsToFile >>>> END\n");
    //fflush(0);

    return self;
}

/////////////////////////////////////////////////
//
////       CLEANUP
//////
////////
/////////
////////////////////////////////////////////////
- (void) drop 
{
    int i;

    fprintf(stdout, "UTMHabitatSpace >>>> drop >>>> BEGIN\n");
    fflush(0);

     //fclose(areaDepthFileStream);
     //fclose(areaVelocityFileStream);

     [habitatZone freeBlock: Date blockSize: 12*sizeof(char)];
     [habitatZone free: driftFoodFile];

     for(i = 0; i < maxNode ; i++)
     {
         free(nodeUTMXArray[i]);
         free(nodeUTMYArray[i]);
     }     

      free(nodeUTMXArray);
      free(nodeUTMYArray);

    [utmInterpolatorFactory drop];
    utmInterpolatorFactory = nil;

    //
    // drop all of the fish cells
    //
    [utmCellListNdx drop];
    [utmCellList deleteAll];
    [utmCellList drop];

    [listOfUTMInputData deleteAll];
    [listOfUTMInputData drop];

    [habitatZone drop];

    fprintf(stdout, "UTMHabitatSpace >>>> drop >>>> END\n");
    fflush(0);
}



@end



