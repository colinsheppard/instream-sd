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
#import "globals.h"
#import "UTMRedd.h"
#import "Trout.h"



@protocol Model
- (id <Zone>) getModelZone;
- createANewFishFrom: aRedd;
- addToKilledList: aFish;
- addRedd: (UTMRedd *) aRedd;
- (id <List>) getReddList;
- (time_t) getModelTime;
- (id <Symbol>) getAgeSymbolForAge: (int) anAge;
- (double) getReproFuncFor: aFish 
                withLength: (double) aLength;

- addToRemovedList: aFish;
@end

@implementation Trout

///////////////////////////////////////////////////////////////
//
// createBegin
//
/////////////////////////////////////////////////////////////
+ createBegin: aZone 
{
  Trout * newTrout;

  //fprintf(stdout, "Trout >>>> createBegin >>>> BEGIN %p \n",aZone);
  //fflush(0);

  newTrout = [super createBegin: aZone];
  newTrout->troutZone = [Zone create: aZone];
  newTrout->causeOfDeath = nil;

  //
  // initialize these 4 per 
  // Green river model formulation spec
  //
  newTrout->netEnergyForFeedingLastPhase = 0.0;
  newTrout->netEnergyForHidingLastPhase = 0.0;
  newTrout->survivalForFeedingLastPhase = 1.0;
  newTrout->survivalForHidingLastPhase = 1.0;


  newTrout->hourlyNetEnergyIfFeed = -LARGEINT;
  newTrout->hourlyNetEnergyIfHide = -LARGEINT;
  newTrout->dailySurvivalIfFeed = -LARGEINT;
  newTrout->dailySurvivalIfHide = -LARGEINT;

  newTrout->currentPhase = DNERROR;
  newTrout->prevPhase = INITPHASE;

  newTrout->isHideCoverAvailable = NO;
  newTrout->hidingCover = NO;

  newTrout->fishDistanceLastMoved = 0.0;
  newTrout->fishCumulativeDistanceMoved = 0.0;

  newTrout->toggledFishForHabSurvUpdate = nil;
  newTrout->imImmortal = NO;
  newTrout->spawner = NO;

    //fprintf(stdout, "Trout >>>> createBegin >>>> newTrout == %p\n", newTrout);
    //fprintf(stdout, "Trout >>>> createBegin >>>> newTrout->fishActivity == %d\n", newTrout->fishActivity);
    //fflush(0);
    //fprintf(stdout, "Trout >>>> createBegin >>>> END\n");
    //fflush(0);

  return newTrout;
}


//////////////////////////////////////////////////////////////////
//
// createEnd
//
//////////////////////////////////////////////////////////////////
- createEnd {
  //fprintf(stdout, "Trout >>>> createEnd >>>> BEGIN\n");
  //fflush(0);

  [super createEnd];

  if (fishParams == nil){
      fprintf(stderr, "ERROR: Trout >>>> createEnd >>>> fishParams is nil\n");
      fflush(0);
      exit(1);
  }
  if (troutRandGen == nil){
      fprintf(stderr, "ERROR: Trout >>>> createEnd >>>> Fish %p doesn't have a troutRandGen.\n", self);
      fflush(0);
      exit(1);
  }else{
    uniformDist = [UniformDoubleDist create: troutZone setGenerator: troutRandGen setDoubleMin: 0.0 setMax: 1.0];
  }


   hourlyDriftConRate = 0.0;
   hourlySearchConRate = 0.0;
   deadOrAlive = "ALIVE";
 
   spawnedThisSeason = NO;

   destCellList = [List create: troutZone];

   //fprintf(stdout, "Trout >>>> createEnd >>>> END\n");
   //fflush(0);
   return self;
}


/////////////////////////////////////////////////////////
//
// setSpeciesIndex
//
////////////////////////////////////////////////////////
- setSpeciesNdx: (int) anIndex 
{
  speciesNdx = anIndex;
  return self;
}

//////////////////////////////////
//
// getFishCount
//
/////////////////////////////////
- (int) getFishCount
{
   return 1;
}

//////////////////////////////////////////////////////
//
// setFishActivitySymbolsWith
//
//////////////////////////////////////////////////////
- setFishActivitySymbolsWith: (id <Symbol>) aHideSymbol
                        with: (id <Symbol>) aFeedSymbol
{
      hideSymbol = aHideSymbol;
      feedSymbol = aFeedSymbol;
      return self;
}

///////////////////////////////////
//
// getReachSymbol
//
// reachSymbol is set in setReach
//
//////////////////////////////////
- (id <Symbol>) getReachSymbol
{
   return [habitatSpace getReachSymbol];
}


///////////////////////////////////////////////////
//
// getFishActivitySymbol
// 
///////////////////////////////////////////////////
- getFishActivitySymbol
{
     if((fishActivitySymbol == hideSymbol) || (fishActivitySymbol == feedSymbol))
     {
          return fishActivitySymbol;
     }

     fprintf(stderr, "Trout >>>> getFishActivitySymbol >>>> unknown fish activity\n");   
     fflush(0);
     exit(1);

     return self;
}   


///////////////////////////////////////////////
//
// setStockedFishActivity
//
// Added 3/31/03 SKJ
//
///////////////////////////////////////////////
- setStockedFishActivity: (id <Symbol>) aSymbol
{
    fishActivitySymbol = aSymbol;

    //
    // I'm guessing we need to set this also...
    //
    fishActivity = FEED;

    return self;

}



//////////////////////////////////////////////
//
// setNewFishActivityToFEED
//
/////////////////////////////////////////////
- setNewFishActivityToFEED
{
    fishActivitySymbol = feedSymbol;
    fishActivity = FEED;
    return self;
}

//////////////////////////////////////////////
//
// resetFishActualDailyIntake
//
/////////////////////////////////////////////
- resetFishActualDailyIntake
{
    fishActualDailyIntake = 0.0;
    return self;
}





////////////////////////////////////////////////////
//
// getFishActivity
//
////////////////////////////////////////////////////
- (int) getFishActivity
{
   /*
    fprintf(stdout, "Trout >>>> getFishActivity >>>> self == %p\n", self);
    fprintf(stdout, "Trout >>>> getFishActivity >>>> fishActivity == %d\n", fishActivity);
    fprintf(stdout, "Trout >>>> getFishActivity >>>> deadOrAlive == %s\n", deadOrAlive);
    fflush(0);
   */
    return (int) fishActivity;
}


/////////////////////////////////////////
//
// getIsFishFeeding
//
/////////////////////////////////////////
- (double) getIsFishFeeding
{
     if(fishActivity == HIDE)
     {
        return 0.0;
     }

     return 1.0;
}   


/////////////////////////////////////////////////////////
//
// getSpeciesIndex
//
////////////////////////////////////////////////////////
- (int) getSpeciesNdx 
{
   return speciesNdx;
}




/////////////////////////////////////////////////////////////////////////////
//
// setFishColor
//
////////////////////////////////////////////////////////////////////////////
- setFishColor: (Color) aColor 
{
  myColor = aColor;
  return self;
}


/////////////////////////////////////////////////////////////
//
// drawSelfOn
//
/////////////////////////////////////////////////////////////
- drawSelfOn: (id <Raster>) aRaster atX: (int) anX Y: (int) aY 
{
  //fprintf(stdout, "Trout >>>> drawSelfOn >>>> BEGIN\n");
  //fprintf(stdout, "Trout >>>> drawSelfOn >>>> myColor = %ld\n", (long) myColor);
  //fflush(0);

  if (age > 0)
  {
  [aRaster fillRectangleX0: anX 
                  Y0: aY
                  X1: anX + age 
                  Y1: aY + ((int) age / 2)
           //    Width: 3 
               Color: myColor];  
  }
  else
  {
  [aRaster drawPointX: anX 
                  Y: aY 
              Color: myColor];  
  }

  //fprintf(stdout, "Trout >>>> drawSelfOn >>>> END\n");
  //fflush(0);

  return self;
}


/////////////////////////////////////////////////////////////////////
//
// tagFish
//
/////////////////////////////////////////////////////////////////////
- tagFish 
{
   [self setFishColor: (Color) TAG_FISH_COLOR];
   return self;
}


/////////////////////////////////////////////////////////////////////////////
//
// setSpecies
//
////////////////////////////////////////////////////////////////////////////
- setSpecies: (id <Symbol>) aSymbol 
{
   species = aSymbol;
   return self;
}


/////////////////////////////////////////////////////////////////////////////
//
// getSpecies
//
////////////////////////////////////////////////////////////////////////////
- (id <Symbol>) getSpecies 
{
  return species;
}


//////////////////////////////////////
//
// getSex
//
///////////////////////////////////////
- (id <Symbol>) getSex
{
   return sex;
}



/////////////////////////////////////////////////////////////////////////////
//
// setAge
//
////////////////////////////////////////////////////////////////////////////
- setAge: (int) anInt 
{
  age = anInt;
  return self;
}

///////////////////////////////////////////////////////////
//
// getAge
//
//////////////////////////////////////////////////////////
- (int) getAge 
{
   return age;
}

- setCell: (FishCell *) aFishCell 
{
  fishCell = aFishCell;
  return self;
}
- (FishCell *) getCell 
{
  return fishCell;
}
/////////////////////////////////////////////////////////////////////////////
//
// setFishID
//
////////////////////////////////////////////////////////////////////////////
- setFishID: (int) anIDNum {
  fishID = anIDNum;
  return self;
}

/////////////////////////////////////////////////////////////////////////////
//
// getFishID
//
////////////////////////////////////////////////////////////////////////////
- (int) getFishID {
  return fishID;
}


/*
///////////////////////////////////////////////////////////
//
// incrementAge
//
///////////////////////////////////////////////////////////
- incrementAge 
{
  ++age;
  ageSymbol = [model getAgeSymbolForAge: age];
  return self;
}
*/


///////////////////////////////////////////////////////////
//
// dailyUpdateWithBirthday
//
///////////////////////////////////////////////////////////
- dailyUpdateWithBirthday: (BOOL *) itsMyBirthday
{
    time_t currentTime = [model getModelTime];

    if(*itsMyBirthday) 
    {
      ++age;
      ageSymbol = [(id <Model>) model getAgeSymbolForAge: age];
    }
    
    if([timeManager isThisTime: (currentTime - 86400) onThisDay: fishParams->fishSpawnEndDate] == YES) 
       {
            spawnedThisSeason = NO;
            //fprintf(stdout, "Trout >>>> dailyUpdateWithBirthday >>>> set spawnedThisSeason to NO\n");
            //fflush(0);
       }

    return self;
}


////////////////////////////////////////////////////
//
// setFishCondition
//
/////////////////////////////////////////////////
- setFishCondition: (double) aCondition 
{
  fishCondition = aCondition;
  return self;
}


/////////////////////////////////////////////////////////////////////
//
// setFishWeightFromLength: andCondition:
// 
////////////////////////////////////////////////////////////////////
- setFishWeightFromLength: (double) aLength andCondition: (double) aCondition 
{
   double fWPA,fWPB;

   fWPA = fishParams->fishWeightParamA;
   fWPB = fishParams->fishWeightParamB;

   fishWeight = aCondition * fWPA * pow(aLength,fWPB);

   return self;
}

/////////////////////////////////////////////////////////////////
//
// getWeightWithIntake
//
//////////////////////////////////////////////////////////////////
- (double) getWeightWithIntake: (double) anEnergyIntake 
{
  double deltaWeight;
  double weight;

  deltaWeight = anEnergyIntake/(fishParams->fishEnergyDensity);
  weight = fishWeight + deltaWeight;

  if(weight > 0.0) 
  {
     return weight;
  }
  else
  {
     return 0.0;
  }
}


////////////////////////////////////////////////////////////////////
//
// getFishWeight
//
////////////////////////////////////////////////////////////////////
- (double) getFishWeight 
{
   return fishWeight;
}

/////////////////////////////////////////////////////////////////////////////
//
// setFishLength
//
////////////////////////////////////////////////////////////////////////////
- setFishLength: (double) aFloat 
{
   fishLength = aFloat;
   fishWeightAtK1 = (fishParams->fishWeightParamA) * pow(fishLength, fishParams->fishWeightParamB);
   return self;
}

////////////////////////////////////////////////////////////////////
//
// getLengthForNewWeight
//
// Updated 8 Aug. 2014 with new, faster method. SFRailsback
//////////////////////////////////////////////////////////////////
- (double) getLengthForNewWeight: (double) aWeight 
{
  //double fishWannabeLength;

  //fishWannabeLength = pow((aWeight/fishParams->fishWeightParamA),1/fishParams->fishWeightParamB);

  if(aWeight <= fishWeightAtK1)
  {
     return fishLength;
  }
  else
  {
    return pow((aWeight/fishParams->fishWeightParamA),1/fishParams->fishWeightParamB);
  }
}


/////////////////////////////////////////////////////////////////////////////
//
//  getFishLength
//
////////////////////////////////////////////////////////////////////////////
- (double) getFishLength 
{
   return fishLength;
}


///////////////////////////////////////////////////////
//
////
//////  get Methods added for the survival manager
///////
////////
///////////////////////////////////////////////////////

///////////////////////////////////////////
//
// getDepthLengthRatio
//
//////////////////////////////////////////
- (double) getDepthLengthRatio
{
    return depthLengthRatio;
}

///////////////////////////////////////////
//
// setDepthLengthRatio:
// used to initialize stocked fish
//////////////////////////////////////////
- setDepthLengthRatio: (double) aDouble 
{
  depthLengthRatio = aDouble;
  return self;

}


///////////////////////////////////////////////
//
// getSwimSpdVelocityRatio
//
///////////////////////////////////////////////
- (double) getSwimSpdVelocityRatio
{
   //return cellSwimSpeed/maxSwimSpeed;
   return swimSpdVelocityRatio;
}




///////////////////////////////////////
//
// toggleFishForHabSurvUpdate
//
///////////////////////////////////////
- toggleFishForHabSurvUpdate
{
   toggledFishForHabSurvUpdate = self;

   return self;
}


///////////////////////////////////////////
//
// getPiscivorousFishDensity
//
///////////////////////////////////////////
- (double) getPiscivorousFishDensity
{
   return [fishCell getPiscivorousFishDensity];
}

///////////////////////////////////////////////////////
//
//       getFishSpawnedThisTime
//
///////////////////////////////////////////////////////
- (BOOL) getFishSpawnedThisTime
{
    BOOL timeSpawnedEqualsModeltime = NO;
    if(timeLastSpawned == [(id <Model>)[[fishCell getSpace] getModel] getModelTime])
    {
        timeSpawnedEqualsModeltime = YES;
    }

    return timeSpawnedEqualsModeltime; 
}



////////////////////////////////////
//
// setModel
//
////////////////////////////////////
- setModel: aModel
{
   model = aModel;
   return self;
}

//////////////////////////////////////////
//
// setFishParams
//
//////////////////////////////////////////
- setFishParams: (FishParams *) aFishParams
{
    fishParams = aFishParams;
    return self;
}

///////////////////////////////////////
//
// getFishParams
//
///////////////////////////////////////
- (FishParams *) getFishParams
{
    return fishParams;
}    


///////////////////////////////
//
// setRandGen
//
//////////////////////////////
- setRandGen: aRandGen
{
    troutRandGen = aRandGen;
    return self;
}


///////////////////////////////
//
// getRandGen
//
//////////////////////////////
- getRandGen
{
    return troutRandGen;
}

///////////////////////////////////////
//
// setScenario
//
///////////////////////////////////////
- setScenario: (int) aScenario
{
   scenario = aScenario;
   return self;
}


///////////////////////////////////////
//
// setReplicate
//
///////////////////////////////////////
- setReplicate: (int) aReplicate
{
   replicate = aReplicate;
   return self;
}



///////////////////////////////
//
// setTimeManager
//
//////////////////////////////
- setTimeManager: (id <TimeManager>) aTimeManager
{
     timeManager = aTimeManager;
     return self;
}

///////////////////////////////////////////////////////////////////////
//
// setWorld
//
/////////////////////////////////////////////////////////////////////
- setWorld: (FishCell *) aCell 
{
  fishCell = aCell;
  return self;
}

- (FishCell *) getWorld 
{
  return fishCell;
}


///////////////////////////////////////
//
// setFishCell
//
//////////////////////////////////////
- setFishCell: (FishCell *) aCell
{
    fishCell = aCell;
    habitatSpace = [aCell getSpace];
    return self;
}


////////////////////////////////////////////////
//
// setHabitatSpace
//
///////////////////////////////////////////////
- setHabitatSpace: (HabitatSpace *) aHabSpace
{
    habitatSpace = aHabSpace;
    return self;
}

////////////////////////////////////////////////
//
// setHabitatManager
//
///////////////////////////////////////////////
- setHabitatManager: (HabitatManager *) aHabManager
{
    habitatManager = aHabManager;
    return self;
}




///////////////////////////////////////////////////////////////
//
// getConditionForWeight: andLength:
//
//////////////////////////////////////////////////////////////
- (double) getConditionForWeight: (double) aWeight andLength: (double) aLength 
{
   double condition=LARGEINT;

   condition = aWeight/
     (fishParams->fishWeightParamA*pow(aLength,fishParams->fishWeightParamB)); 

   return condition;
}

- (double) getFishCondition 
{
   return fishCondition;
}

/////////////////////////////////////////////////////////////////
//
// getFracMatureForLength
//
//////////////////////////////////////////////////////////////
- (double) getFracMatureForLength: (double) aLength 
{
  double fmature;

  fmature =  aLength/fishParams->fishSpawnMinLength;

  if(fmature < 1.0) 
  {
     return fmature;
  }
  else 
  {
    return 1.0;
  }

}


/////////////////////////////////////////////////////////////////////////////
//
// getFishShelterArea
//
////////////////////////////////////////////////////////////////////////////
- (double) getFishShelterArea 
{
  return fishLength*fishLength;
}


/////////////////////////////////////////////////////////////////////////////
//
// getFishHidingCoverArea
//
////////////////////////////////////////////////////////////////////////////
- (double) getFishHidingCoverArea 
{
  return fishLength*fishLength;
}


////////////////////////////////////////////////////////
//
// getWorldDepth
//
///////////////////////////////////////////////////////
- (double) getWorldDepth 
{
  return [fishCell getPolyCellDepth];
}

/////////////////////////////////////////////////////
//
// getWorldVelocity
//
/////////////////////////////////////////////////////
- (double) getWorldVelocity 
{
  return [fishCell getPolyCellVelocity];
}


////////////////////////////////////////////////////////
//
// TIME_T METHODS
//
////////////////////////////////////////////////////////
- setTimeTLastSpawned: (time_t) aTime_t 
{
  timeLastSpawned = aTime_t;
  return self;
}

- (time_t) getTimeTLastSpawned 
{
   return timeLastSpawned;
}

- (time_t) getCurrentTimeT 
{
   return  [model getModelTime];
}

- (DayPhase) getCurrentPhase
{
    return currentPhase;
}


- (double) getCellSwimSpeed 
{
   return cellSwimSpeed;    //set in -calcNetEnergyForCell
}




/* Scheduled actions for trout */

/* There are four scheduled actions: spawn, move, grow, and die */

/* spawn may result in the fish moving to another cell */




/////////////////////////////////////////////////////////////////////////////
//
// spawn
//
////////////////////////////////////////////////////////////////////////////
- spawn 
{
  // determine if ready to spawn 
  //    spawning criteria
  //       a) date window
  //       b) female spawner
  //       c) not spawned this year
  //       d) age minimum
  //       e) size minimum
  //       f) condition threshold
  // identify Redd location
  //       a) within moving distance
  //       b) pick cell with highest spawnQuality, where
  //           spawnQuality = spawnDepthSuit * spawnVelocitySuit * spawnGravelArea
  // move to spawning cell
  // make Redd
  //       calculate numberOfEggs
  //       set spawnerLength
  // update lastSpawnDate to today

  id spawnCell;
  id <List> fishList;
  id <ListIndex> fishLstNdx;
  id anotherTrout = nil;

  //fprintf(stdout, "Trout,Spawn,%d,Begin\n", fishID);
  //fflush(0);
  
  //
  // If we're dead we can't spawn
  //
  if(causeOfDeath) 
  {
     return self;
  }
  
  // First, check cells for suitability at current flow (not yet done this time step)
  [self checkSpawnCells];

  if (spawner)
  {
   //fprintf(stdout, "Trout,Spawn,%d,OldSpawner,Cells:,%d\n", fishID, [potentialSpawnCellList getCount]);
   //fflush(0);

  if((spawnCell = [self findCellForNewRedd]) == nil) 
  {
    fprintf(stderr, "ERROR: Trout >>>> spawn >>>> No suitable cell found when creating redd");
    fflush(0);
    exit(1);
  }

  //fprintf(stdout, "Trout >>>> Spawn >>>> before add fish\n");
  //fflush(0);
  [spawnCell addFish: self]; 
  fishCell = spawnCell;

  //fprintf(stdout, "Trout >>>> Spawn >>>> before create redd in cell\n");
  //fflush(0);
  [self createAReddInCell: spawnCell];

  //
  // reduce weight of spawners
  //
  fishWeight = fishWeight * (1.0 - fishParams->fishSpawnWtLossFraction);
  // Condition update added 6 Aug 2014
  fishCondition = [self getConditionForWeight: fishWeight andLength: fishLength];

  timeLastSpawned = [self getCurrentTimeT];
  spawnedThisSeason = YES;
  spawner = NO;

  //
  // Now, find male spawner.
  //
  fishList = [model getLiveFishList]; 

  if(fishList == nil){
     fprintf(stderr, "ERROR: Trout >>>> spawn >>>> fishList is nil\n");
     fflush(0);
     exit(1);
  }

  //
  // Search for first (= largest) eligible
  // male, if there is one.
  //
  fishLstNdx = [fishList listBegin: scratchZone];
  while(([fishLstNdx getLoc] != End) && ((anotherTrout = [fishLstNdx next]) != nil)){
       if([self shouldISpawnWith: anotherTrout]){
           [anotherTrout updateMaleSpawner];
           break;
       }
  }

  [fishLstNdx drop];
  [potentialSpawnCellList removeAll];

  //fprintf(stdout, "Trout,Spawn,%d,EndAfterSpawning\n", fishID);
  //fflush(0);
  return self;

  } // if spawner

  // Do this if not yet ready to spawn
  if ([self readyToSpawn] == NO)
  {
     //#ifdef READY_TO_SPAWN_RPT
	 if ([model getWriteReadyToSpawnReport])
	 {
       [self printReadyToSpawnRpt: NO];
     }
	 //#endif

    //fprintf(stdout, "Trout,Spawn,%d,EndNotSpawning\n",fishID);
    //fflush(0);
    return self;
  } // if not ready to spawn

  // Now, we become a spawner and check cells for a day
  spawner = YES;
  potentialSpawnCellList = [List create: troutZone];

  [fishCell getNeighborsWithin: (maxMoveDistance * 2)
                      withList: potentialSpawnCellList];

  [potentialSpawnCellList addFirst: fishCell];
  // Suitability of these cells will be checked in - checkSpawnCells

   //fprintf(stdout, "Trout,Spawn,%d,NewSpawner,Cells:,%d\n", fishID, [potentialSpawnCellList getCount]);
   //fflush(0);

   //#ifdef READY_TO_SPAWN_RPT
	 if ([model getWriteReadyToSpawnReport])
	 {
       [self printReadyToSpawnRpt: YES];
     }
  //#endif

  return self;
} // - spawn




///////////////////////////////////////////////////////////
//
// readyToSpawn
//
///////////////////////////////////////////////////////////
- (BOOL) readyToSpawn 
{
  time_t currentTime;

  char* fSED;
  char* fSSD;
  double currentTemp = -LARGEINT;

  /* ready?
   *    b) age minimum (fish) <branch>
   *    e) female (fish) <branch>
   *    c) size minimum (fish) <branch>
   *    a) spawned already this year  (fish) <branch>
   *    d) date window (cell) <branch> <msg>
   *    f) flow threshhold (cell) <branch> <msg>
   *    h) temperature (cell) <branch> <msg>
   *    i) steady flows (cell) <branch> <msg>
   *    g) condition threshhold (fish) <calc>
   */



  //
  // If our fishCell is nil we're probably dead
  // and should not have gotten this far in the code
  //
  if(fishCell != nil)
  {
      currentTemp = [fishCell getTemperature];
  }

  if(currentTemp == -LARGEINT)
  {
       fprintf(stderr, "ERROR: Trout >>>> readyToSpawn >>>> currentTemp = %f\n", currentTemp);
       fflush(0);
       exit(1);
  }

  currentTime =  [self getCurrentTimeT];

  fSED = (char *) fishParams->fishSpawnEndDate;
  fSSD = (char *) fishParams->fishSpawnStartDate;

  //
  // USE THIS FOR TESTING
  //
  //if( (age > 1) && (sex == Female)) return YES;


  //
  // AGE
  //
  if (age < fishParams->fishSpawnMinAge)
  {
      return NO;
  }


  //
  // SEX
  //
  if(sex == Male)
  {
     return NO;
  }

       //
       // SIZE
       //
       if (fishLength < fishParams->fishSpawnMinLength) return NO;


       //
       // IN THE WINDOW FOR THIS YEAR?
       //
       if([timeManager isTimeT: currentTime
                  betweenMMDD: fSSD
                      andMMDD: fSED] == NO) 
       { 
                  return NO;
       }

       //
       // Reset of spawnedThis season moved to dailyUpdateWithBirthday
       // SFR 12/29/2014
       //

       //
       // TEMPERATURE
       //
       if((currentTemp < fishParams->fishSpawnMinTemp) || (fishParams->fishSpawnMaxTemp < currentTemp))
       {
           return NO;
       }

       //
       // FLOW THRESHHOLD
       //
       if([fishCell getDailyMeanFlow] > [[fishCell getReach] getHabMaxSpawnFlow])
       {
           return NO;
       }

       //
       // STEADY FLOWS
       //
       if([fishCell getChangeInDailyFlow]/[fishCell getPrevDailyMeanFlow] > fishParams->fishSpawnMaxFlowChange)
       {
           return NO;
       }


       //
       // CONDITION THRESHHOLD
       //
       if(fishCondition <= fishParams->fishSpawnMinCond)
       {
          return NO;
       }


       //
       // SPAWNED THIS SEASON?
       //
       if(spawnedThisSeason == YES)
       {
          return NO;
       }

      //
      // FINALLY TEST AGAINST RANDOM DRAW
      //
      if([uniformDist getDoubleSample] > fishParams->fishSpawnProb)
      {
           return NO;
      }

 
      //
      // IF WE FALL THROUGH ALL THOSE, then YES
      // WE'RE READY TO SPAWN.
      //
      return YES;

   
} // readyToSpawn




/////////////////////////////////////////////
//
// shouldISpawnWith
//
/////////////////////////////////////////////
- (BOOL) shouldISpawnWith: aTrout
{
   if([aTrout getSex] != Male)
   {
       return NO;
   }
   if([aTrout getSpecies] != species)
   {
       return NO;
   }
   if([aTrout getReachSymbol] != [self getReachSymbol])
   {
       return NO;
   }
   if([aTrout getFishLength] < fishParams->fishSpawnMinLength)
   {
       return NO;
   }
   if([aTrout getAge] < fishParams->fishSpawnMinAge)
   {
       return NO;
   }
   if([aTrout getFishCondition] < fishParams->fishSpawnMinCond) 
   {
       return NO;
   }
   if([aTrout getSpawnedThisSeason] == YES) 
   {
       return NO;
   }

   return YES;
}


////////////////////////////////////
//
// updateMaleSpawner
//
///////////////////////////////////       
- updateMaleSpawner 
{
  if(sex != Male)
  {
     fprintf(stderr, "ERROR: Trout >>>> updateMaleSpawner >>>> fish is not male\n");
     fflush(0);
     exit(1);
  }

  spawnedThisSeason = YES;
  fishWeight = fishWeight * (1.0 - fishParams->fishSpawnWtLossFraction);
  // Condition update added 6 Aug 2014
  fishCondition = [self getConditionForWeight: fishWeight andLength: fishLength];

  // fprintf(stdout, "I'm a male and I spawned, with condition: %f\n", fishCondition);
  // fflush(0);

  return self;
}  
       
- (BOOL) getSpawnedThisSeason
{
   return spawnedThisSeason;
}



/////////////////////////////////////////////
//
// findCellForNewRedd
//
////////////////////////////////////////////
- (FishCell *) findCellForNewRedd 
{
  id <ListIndex> cellNdx = nil;
  FishCell* bestCell = (FishCell *) nil;
  FishCell* nextCell = (FishCell *) nil;
  double bestSpawnQuality = 0.0;
  double spawnQuality = -LARGEINT;

  //fprintf(stdout, "Trout >>>> findCellForNewRedd >>>> BEGIN\n");
  //fflush(0);

 #ifdef SPAWN_CELL_RPT
    [self printSpawnCellRpt: potentialSpawnCellList];
 #endif

  cellNdx = [potentialSpawnCellList listBegin: scratchZone];

  while(([cellNdx getLoc] != End) && ((nextCell = [cellNdx next]) != nil))
  {
     spawnQuality = [self getSpawnQuality: nextCell];
 
     if(spawnQuality > bestSpawnQuality) 
     {
        bestSpawnQuality = spawnQuality;
        bestCell = nextCell;
     }
  }

  [cellNdx drop];

  //fprintf(stdout, "Trout,findCellForNewRedd,%d,bestCell quality:,%f\n", fishID, bestSpawnQuality);
  fflush(0);

  // potentialSpawnCellList is cleaned up in -spawn

  //fprintf(stdout, "Trout >>>> findCellForNewRedd >>>> END\n");
  //fflush(0);

  //
  // we test for nil in the calling method
  //

  return bestCell;
}




///////////////////////////////////////
//
// createAReddInCell
//
//////////////////////////////////////
- createAReddInCell: (FishCell *) aCell 
{
  UTMRedd*  newRedd;

  //fprintf(stderr, "Trout >>>> createAReddInCell >>>> BEGIN\n");
  //fflush(0);

  newRedd = [UTMRedd createBegin: [model getZone]];
  [newRedd setTimeManager: timeManager];
  [newRedd setFishParams: fishParams];
  [newRedd setModel: model];
  [newRedd setCell: aCell];
  [newRedd setReddColor: myColor];
  [newRedd setSpecies: species]; 
  [newRedd setReddBinomialDist: [model getReddBinomialDist]];

  [newRedd setNumberOfEggs: fishParams->fishFecundParamA
         * pow(fishLength, fishParams->fishFecundParamB)
         * fishParams->fishSpawnEggViability];

  [newRedd setSpawnerLength: fishLength];

  newRedd = [newRedd createEnd];

  [newRedd setCreateTimeT: [model getModelTime]];

  [aCell addRedd: newRedd];
  [model addRedd: newRedd];

  //fprintf(stderr, "Trout >>>> createAReddInCell >>>> END\n");
  //fflush(0);

  return self;
}


////////////////////////////////////////////////////////////////////
//
// getSpawnQuality
//
////////////////////////////////////////////////////////////////////
- (double) getSpawnQuality: (FishCell *) aCell 
{
   double spawnQuality;

   //fprintf(stdout, "Trout >>>> getSpawnQuality >>>> BEGIN\n");
   //fflush(0);

   spawnQuality = [self getSpawnDepthSuitFor: [aCell getPolyCellDepth]]
                * [self getSpawnVelSuitFor: [aCell getPolyCellVelocity]]
                * [aCell getPolyCellArea]
                * [aCell getCellFracSpawn]; 

   //fprintf(stdout, "Trout >>>> getSpawnQuality >>>> END\n");
   //fflush(0);

   return spawnQuality;
}

////////////////////////////////////////////////////////////////////
//
// checkSpawnCells
// added 12/16/2014 for new spawning habitat method
////////////////////////////////////////////////////////////////////
- checkSpawnCells 
{
  //fprintf(stdout, "Trout,CheckSpawnCells,%d,Begin\n", fishID);
  //fflush(0);

  if (spawner == NO) 
  {
    //fprintf(stdout, "Trout,CheckSpawnCells,%d,End-NotSpawner\n", fishID);
    //fflush(0);
    return self;
  }
  if ([potentialSpawnCellList getCount] == 0)
  {
	spawner = NO;
	return self;
  }

  id <List> badCellList;
  id <ListIndex> cellNdx = nil;
  FishCell* nextCell = (FishCell *) nil;
  
  //fprintf(stdout, "Trout,CheckSpawnCells,%d,Spawner-Begin,Cells:,%d\n", fishID, [potentialSpawnCellList getCount]);
  //fflush(0);

  badCellList = [List create: troutZone];

  cellNdx = [potentialSpawnCellList listBegin: scratchZone];

  // Identify all the unsuitable cells on the potential spawn cell list
  while(([cellNdx getLoc] != End) && ((nextCell = [cellNdx next]) != nil))
  {
    if ([self getSpawnDepthSuitFor: [nextCell getPolyCellDepth]] < 0.1 
	 || [self getSpawnVelSuitFor: [nextCell getPolyCellVelocity]] < 0.1
	 || [nextCell getCellFracSpawn] <= 0.0)
	[badCellList addFirst: nextCell]; 
  }

  // Now remove them from the spawn cell list
  if ([badCellList getCount] > 0)
  {
    cellNdx = [badCellList listBegin: scratchZone];
    while(([cellNdx getLoc] != End) && ((nextCell = [cellNdx next]) != nil))
	{
    [potentialSpawnCellList remove: nextCell];
	}
  }

  [cellNdx drop];
  [badCellList removeAll];
  [badCellList drop];
  badCellList = nil; 

  //fprintf(stdout, "Trout,CheckSpawnCells,%d,Spawner-End,Cells:,%d\n", fishID, [potentialSpawnCellList getCount]);
  //fflush(0);

   return self; 
}

///////////////////////////////////////////////////////////////
//
// setCMaxInterpolator
//
///////////////////////////////////////////////////////////////
- setCMaxInterpolator: (id <InterpolationTableSD>) anInterpolator
{
   cmaxInterpolator = anInterpolator;
   return self;
}



///////////////////////////////////////////
//
// setSpawnDepthInterpolator
//
//////////////////////////////////////////
- setSpawnDepthInterpolator: (id <InterpolationTableSD>) anInterpolator
{
   spawnDepthInterpolator = anInterpolator;
   return self;
}



////////////////////////////////////////////
//
// setSpawnVelocityInterpolator
//
///////////////////////////////////////////
- setSpawnVelocityInterpolator: (id <InterpolationTableSD>) anInterpolator
{
    spawnVelocityInterpolator = anInterpolator;
    return self;
}

////////////////////////////////////////////////////
//
// setCaptureLogistic
//
////////////////////////////////////////////////////
- setCaptureLogistic: (LogisticFunc *) aLogisticFunc
{
   captureLogistic = aLogisticFunc;
   return self;
}



//////////////////////////////////////////////////////////////////////
//
// getSpawnDepthSuitFor
//
/////////////////////////////////////////////////////////////////////
- (double) getSpawnDepthSuitFor: (double) aDepth 
{
    double sds=LARGEINT;

    //fprintf(stdout, "Trout >>>> getSpawnDepthSuitFor >>>> BEGIN\n");
    //fflush(0);

    if(aDepth >= fishParams->fishSpawnDSuitD5)
    {
      sds = fishParams->fishSpawnDSuitS5;
    }
    else if (aDepth <= fishParams->fishSpawnDSuitD1)
    {
      sds = fishParams->fishSpawnDSuitS1;
    }
    else if (aDepth > fishParams->fishSpawnDSuitD1 && aDepth <= fishParams->fishSpawnDSuitD2)
    {
      sds = [self _interpYBetweenR: fishParams->fishSpawnDSuitS1
		    andS: fishParams->fishSpawnDSuitS2
		    basedOnX: aDepth
		    betweenP: fishParams->fishSpawnDSuitD1
		    andQ: fishParams->fishSpawnDSuitD2];
    }
    else if (aDepth > fishParams->fishSpawnDSuitD2 && aDepth <= fishParams->fishSpawnDSuitD3)
    {
      sds = [self _interpYBetweenR: fishParams->fishSpawnDSuitS2
		    andS: fishParams->fishSpawnDSuitS3
		    basedOnX: aDepth
		    betweenP: fishParams->fishSpawnDSuitD2
		    andQ: fishParams->fishSpawnDSuitD3];
    }
    else if (aDepth > fishParams->fishSpawnDSuitD3 && aDepth <= fishParams->fishSpawnDSuitD4)
    {
      sds = [self _interpYBetweenR: fishParams->fishSpawnDSuitS3
		    andS: fishParams->fishSpawnDSuitS4
		    basedOnX: aDepth
		    betweenP: fishParams->fishSpawnDSuitD3
		    andQ: fishParams->fishSpawnDSuitD4];
    }
    else if (aDepth > fishParams->fishSpawnDSuitD4 && aDepth <= fishParams->fishSpawnDSuitD5)
    {
      sds = [self _interpYBetweenR: fishParams->fishSpawnDSuitS4
		    andS: fishParams->fishSpawnDSuitS5
		    basedOnX: aDepth
		    betweenP: fishParams->fishSpawnDSuitD4
		    andQ: fishParams->fishSpawnDSuitD5];
    }


    //fprintf(stdout, "Trout >>>> getSpawnDepthSuitFor >>>> END\n");
    //fflush(0);

    return sds;
} 




/////////////////////////////////////////////////////////////////////
//
// getSpawnVelSuitFor 
//
/////////////////////////////////////////////////////////////////////
- (double) getSpawnVelSuitFor: (double) aVel 
{
    double svs=LARGEINT;

    //fprintf(stdout, "Trout >>>> getSpawnVelSuitFor >>>> BEGIN\n");
    //fflush(0);

    if (aVel >= fishParams->fishSpawnVSuitV6 )
    {
      svs = fishParams->fishSpawnVSuitS6;
    }
    else if(aVel <= fishParams->fishSpawnVSuitV1)
    {
      svs = fishParams->fishSpawnVSuitS1;
    }
    else if(aVel > fishParams->fishSpawnVSuitV1  && aVel <= fishParams->fishSpawnVSuitV2)
    {
      svs =  [self _interpYBetweenR: fishParams->fishSpawnVSuitS1
                               andS: fishParams->fishSpawnVSuitS2
                           basedOnX: aVel
                           betweenP: fishParams->fishSpawnVSuitV1  
                               andQ: fishParams->fishSpawnVSuitV2];
    }
    else if(aVel > fishParams->fishSpawnVSuitV2  && aVel <= fishParams->fishSpawnVSuitV3)
    {
      svs =  [self _interpYBetweenR: fishParams->fishSpawnVSuitS2
                               andS: fishParams->fishSpawnVSuitS3
                           basedOnX: aVel
                           betweenP: fishParams->fishSpawnVSuitV2  
                               andQ: fishParams->fishSpawnVSuitV3];
    }
    else if(aVel > fishParams->fishSpawnVSuitV3  && aVel <= fishParams->fishSpawnVSuitV4)
    {
      svs =  [self _interpYBetweenR: fishParams->fishSpawnVSuitS3
                               andS: fishParams->fishSpawnVSuitS4
                           basedOnX: aVel
                           betweenP: fishParams->fishSpawnVSuitV3  
                               andQ: fishParams->fishSpawnVSuitV4];
    }
    else if(aVel > fishParams->fishSpawnVSuitV4  && aVel <= fishParams->fishSpawnVSuitV5)
    {
      svs =  [self _interpYBetweenR: fishParams->fishSpawnVSuitS4
                               andS: fishParams->fishSpawnVSuitS5
                           basedOnX: aVel
                           betweenP: fishParams->fishSpawnVSuitV4  
                               andQ: fishParams->fishSpawnVSuitV5];
    }
    else if(aVel > fishParams->fishSpawnVSuitV5  && aVel <= fishParams->fishSpawnVSuitV6)
    {
      svs =  [self _interpYBetweenR: fishParams->fishSpawnVSuitS5
                               andS: fishParams->fishSpawnVSuitS6
                           basedOnX: aVel
                           betweenP: fishParams->fishSpawnVSuitV5  
                               andQ: fishParams->fishSpawnVSuitV6];
    }
    
    //fprintf(stdout, "Trout >>>> getSpawnVelSuitFor >>>> END\n");
    //fflush(0);

    return svs;
}


////////////////////////////////////////////////////////////
//  This just interpolates once you've found the two bounding
// values.
//           y = f(x|x in [p,q], y = {(x-p)/(q-p)}(s-r) + r)
//
//////////////////////////////////////////////////////////////
-(double) _interpYBetweenR: (double) r 
                      andS: (double) s 
                  basedOnX: (double) x
		  betweenP: (double) p 
                      andQ: (double) q 
{
  return (((x-p)/(q-p))*(s-r) + r);
}




//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
//
// Move 
// 
///////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
- move
{
	//fprintf(stdout, "Trout >>>> move >>>> BEGIN\n");
	//fflush(0);
  if(causeOfDeath) 
  {
       return self;
  }


  //fprintf(stdout, "Trout >>>> move >>>> before calcDist\n");
  //fflush(0);
  [self calcMaxMoveDistance];

  //fprintf(stdout, "Trout >>>> move >>>> before get Time Stuff\n");
  //fflush(0);
  numberOfDaylightHours = [fishCell getNumberOfDaylightHours];
  numberOfNightHours = [fishCell getNumberOfNightHours];

  currentPhase = [fishCell getCurrentPhase];
  prevPhase = [fishCell getPhaseOfPrevStep];

  //
  // If day phase switches update memory variables
  // with the values in the temporary memory variables
  // obtained from the previous move cycle
  //
  if([fishCell getDayNightPhaseSwitch])
  {
     netEnergyForFeedingLastPhase = tempNetEnergyIfFeed;
     netEnergyForHidingLastPhase = tempNetEnergyIfHide;

     survivalForFeedingLastPhase = tempSurvivalIfFeed;
     survivalForHidingLastPhase = tempSurvivalIfHide;
  }

  //
  // Initialize the temporary memory variables 
  // to a small number
  //
  tempBestERMForFeed = -LARGEINT;
  tempBestERMForHide = -LARGEINT;

  tempNetEnergyIfFeed = -LARGEINT;
  tempNetEnergyIfHide = -LARGEINT;

  tempSurvivalIfFeed = -LARGEINT;
  tempSurvivalIfHide = -LARGEINT;

  /*
  fprintf(stdout,"TROUT move >>>> numberOfDaylightHours = %f\n", numberOfDaylightHours);
  fprintf(stdout,"TROUT move >>>> numberOfNightHours = %f\n", numberOfNightHours);
  fprintf(stdout,"TROUT move >>>> netEnergyForFeedingLastPhase = %f\n", netEnergyForFeedingLastPhase);
  fprintf(stdout,"TROUT move >>>> netEnergyForHidingLastPhase = %f\n", netEnergyForHidingLastPhase);
  fprintf(stdout,"TROUT move >>>> survivalForFeedingLastPhase = %f\n", survivalForFeedingLastPhase);
  fprintf(stdout,"TROUT move >>>> survivalForHidingLastPhase = %f\n", survivalForHidingLastPhase);
  fprintf(stdout,"TROUT move >>>> currentPhase = %d\n", currentPhase);
  fprintf(stdout,"TROUT move >>>> prevPhase = %d\n", prevPhase);
  fflush(0);
  */

  [self moveToMaximizeExpectedMaturity]; 

  //fprintf(stdout, "Trout >>>> move >>>> END\n");
  //fflush(0);
  return self;
}





///////////////////////////////////////////////////////////////////////
//
// moveToMaximizeExpectedMaturity 
//
// Cleaned up 4/19/2013 SFR to remove redundancies with new KDTree
// implementation of getNeighborsWithin: 
//  
//   "Speed up" that tried to skip cells with high velocity removed 4/2013
//   because it didn't have much benefit.
//  
///////////////////////////////////////////////////////////////////////
- moveToMaximizeExpectedMaturity
{
  id <ListIndex> destNdx = nil;
  FishCell *destCell=nil;
  FishCell *bestDest=nil;
  
  double bestExpectedMaturity=0.0;
  double expectedMaturityAtDest=0.0;

  //fprintf(stdout, "Trout >>>> moveToMaximizeExpectedMaturity >>>> BEGIN\n");
  //fflush(0);

  if(fishCell == nil) 
  {
     fprintf(stderr, "ERROR: Trout >>>> moveToMaximizeExpectedMaturity >>>> Fish %p has no Cell context.\n", self);
     fflush(0);
     exit(1);
  }

  //
  // destCellList must be empty when passed to fishCell.
  //
  if([destCellList getCount] > 0)
  {
     [destCellList removeAll];
  }

  [fishCell getNeighborsWithin: maxMoveDistance
                      withList: destCellList];

  if([destCellList getCount] == 0)
  {
      fprintf(stderr, "ERROR: Trout >>>> moveToMaximizeExpectedMaturity >>>> destCellList is empty\n");
      fflush(0); 
      exit(1);
  }

  destNdx = [destCellList listBegin: scratchZone];
      while (([destNdx getLoc] != End) && ((destCell = [destNdx next]) != nil))
      {
          expectedMaturityAtDest = [self expectedMaturityAt: destCell];

          if (expectedMaturityAtDest > bestExpectedMaturity) 
          {
	      bestExpectedMaturity = expectedMaturityAtDest;
	      bestDest = destCell;
          }
      }  //while destNdx

      [destNdx drop];
      destNdx = nil;

  if(bestDest == nil) 
  { 
       fprintf(stderr, "ERROR: Trout >>>> moveToMaximizeExpectedMaturity >>>> bestDest is nil in TROUT moveToMaximizeExpectedMaturity\n");
       fflush(0);
       exit(1);
  }

  // 
  //  Now, move 
  //
  [self moveTo: bestDest];

  //
  // RESOURCE CLEANUP
  // 
  if(destNdx != nil) 
  {
     [destNdx drop];
  }


  //fprintf(stdout, "Trout >>>> moveToMaximizeExpectedMaturity >>>> END\n");
  //fflush(0);


  return self;
}


//////////////////////////////////
//
// moveTo
//
// SET INSTANCE VARIABLES
//
//////////////////////////////////
- moveTo: bestDest 
{

/*
	The following instance variables are set mainly for testing movement calculations
	by probing the fish. HOWEVER (1) netEnergyForBestCell must be set here because it is used in
	-grow, (2) the feeding strategy, hourly food consumption rates, and velocity shelter use 
	must be set here so the destination cell's food and velocity shelter availability can
	be updated accurately when the fish moves (cell method "moveHere"), (3) expectedMaturityAt: bestDest
        must be called to update the fish's activity and depthLengthRatio, so they have the correct
        values when mortality is simulated.

	These variables show the state of the fish when it made its movement decision
	and will not necessarily be equal to the results of the same methods executed at the
	end of a model time step because there will be different numbers of fish in cells etc.
	after -move is completed for all fish.

	These variables must be set BEFORE the fish actually moves to the new cell, so the
	fish is not included in the destination cell's list of contained fish (so the fish 
	does not compete with itself for food).

	It seems inefficient to re-calculate these variables after finding the best destination
	cell, but it is much cleaner and safer this way! 
*/

	//fprintf(stdout, "Trout >>>> moveTo >>>> BEGIN\n");
	//fflush(0);

	
  expectedMaturityForBestCell = [self expectedMaturityAt: bestDest];

  netEnergyForBestCell = [self calcNetEnergyAt: bestDest
                                  withActivity: fishActivity];

  //fprintf(stdout, "\n");
  //fprintf(stdout, "TROUT >>>> moveTo >>>> netEnergyForBestCell = %f\n", netEnergyForBestCell);
  //fprintf(stdout, "TROUT >>>> moveTo >>>> tempNetEnergyIfFeed = %f\n", tempNetEnergyIfFeed);
  //fprintf(stdout, "TROUT >>>> moveTo >>>> tempNetEnergyIfHide = %f\n", tempNetEnergyIfHide);
  //fprintf(stdout, "TROUT >>>> moveTo >>>> tempBestERMForFeed = %f\n", tempBestERMForFeed);
  //fprintf(stdout, "TROUT >>>> moveTo >>>> tempBestERMForHide = %f\n", tempBestERMForHide);
  //if(fishActivity == FEED)
  //fprintf(stdout, "TROUT >>>> moveTo >>>> fishActivity = FEED\n");
  //if(fishActivity == HIDE)
  //fprintf(stdout, "TROUT >>>> moveTo >>>> fishActivity = HIDE\n");
  //if(fishFeedingStrategy == DRIFT)
  //fprintf(stdout, "TROUT >>>> moveTo >>>> cellFeedingStrategy = DRIFT\n");
  //if(fishFeedingStrategy == SEARCH)
  //fprintf(stdout, "TROUT >>>> moveTo >>>> cellFeedingStrategy = SEARCH\n");
  //if(fishFeedingStrategy == HIDE)
  //fprintf(stdout, "TROUT >>>> moveTo >>>> cellFeedingStrategy = HIDE\n");
  //fprintf(stdout, "TROUT >>>> moveTo >>>> cellFeedingStrategy = %d\n", cellFeedingStrategy);
  //fprintf(stdout, "\n");
  //fflush(0);
  

  captureArea = [self calcCaptureArea: bestDest];
  //cMax = [self calcCmax: [bestDest getTemperature] ];
  cMaxFT = [cmaxInterpolator getValueFor: [bestDest getTemperature]];
  detectDistance = [self calcDetectDistanceAt: bestDest]; 
  driftFoodIntake = [self calcDriftFoodIntakeAt: bestDest];
  driftNetEnergy = [self calcDriftNetEnergyAt: bestDest];
  searchFoodIntake = [self calcSearchFoodIntakeAt: bestDest];
  searchNetEnergy = [self calcSearchNetEnergyAt: bestDest];

  //
  // Added 3/12/02 skj. depthLengthRatio needs to be updated BEFORE 
  // nonStarvSurvival
  // Commented out because depthLengthRatio is calculated in
  // expectedMaturityAt:
  //depthLengthRatio = [bestDest getPolyCellDepth]/fishLength;

  
  nonStarvSurvival = [self getNonStarvSPAt: bestDest
                              withActivity: fishActivity];

  fishFeedingStrategy = cellFeedingStrategy; //cellFeedingStrategy is set in -calcNetEnergyForCell

  fishSwimSpeed = [self getSwimSpeedAt: bestDest forStrategy: fishFeedingStrategy]; // For probes & opt. output

  activeResp = [self calcActivityRespirationAt: bestDest 
                                 withSwimSpeed: fishSwimSpeed];

  
  
  //if(fishFeedingStrategy == DRIFT)
  //fprintf(stdout, "TROUT >>>> moveTo >>>> fishFeedingStrategy = DRIFT\n");
  //if(fishFeedingStrategy == SEARCH)
  //fprintf(stdout, "TROUT >>>> moveTo >>>> fishFeedingStrategy = SEARCH\n");
  //if(fishFeedingStrategy == HIDE)
  //fprintf(stdout, "TROUT >>>> moveTo >>>> fishFeedingStrategy = HIDE\n");
  //fprintf(stdout, "TROUT >>>> moveTo >>>> fishFeedingStrategy = %d\n", fishFeedingStrategy);
  //fflush(0);
  



   //
   // Deplete the cell's food and shelter resources
   // used up by the fish, and decide whether fish is piscivorous
   // (which depends on whether it feeds)
   //

   switch(fishFeedingStrategy) 
   {
     case DRIFT: 

        hourlyDriftConRate = driftFoodIntake;

        hourlySearchConRate = 0.0;
        feedStrategy = "DRIFT";
        inHidingCover = "NO";
        hidingCover = NO;

        velocityShelter = [self getIsShelterAvailable: bestDest];
                if(velocityShelter == YES) {
                      inShelter = "YES";   //Probe Variable
                }
                else {
                      inShelter = "NO";
                }

        break;
     
     case SEARCH:

         hourlySearchConRate = searchFoodIntake;

         hourlyDriftConRate  = 0.0;
         velocityShelter = NO; 
         inShelter = "NO"; //Probe Variable
         inHidingCover = "NO";
         hidingCover = NO;
         feedStrategy = "SEARCH";  //Probe Variable

		break;

     case HIDE:

         hourlyDriftConRate = 0.0;
         hourlySearchConRate = 0.0;
         velocityShelter = NO; 
         feedStrategy = "HIDE";  //Probe Variable
         inShelter = "NO"; //Probe Variable

         hidingCover = [bestDest getIsHidingCoverAvailable];

         if(hidingCover == YES) 
         {
              inHidingCover = "YES";   //Probe Variable
         }
         else 
         {
              inHidingCover = "NO";
         }

         break;

        default: fprintf(stderr, "ERROR: Trout >>>> moveToBestDest >>>> Fish has no feeding strategy\n");
                 fflush(0);
                 exit(1);
                 break;
    }


    //
    // Added for breakout report 3/8/2002
    //
    if(fishActivity == HIDE)
    {
       fishActivitySymbol = hideSymbol;
    }
    else if(fishActivity == FEED)
    {
       fishActivitySymbol = feedSymbol;
    }

    //
    // New distance moved vars
    //
    fishDistanceLastMoved = [fishCell getDistanceTo: bestDest];
    fishCumulativeDistanceMoved += fishDistanceLastMoved;


//PRINT THE MOVE REPORT
  if([model getWriteMoveReport] == YES){
    [self moveReport: bestDest];
  }

#ifdef MOVE_DISTANCE_REPORT_ON
   [self moveDistanceReport: bestDest];
#endif


//THEN WE MOVE

   [fishCell removeFish: self];
   [bestDest moveHere: self]; 
   // fishCell = bestDest;  Done by cell in addFish

   CellNumber = [bestDest getPolyCellNumber];
   
   // Now that we're in the new reach, update pisciv. fish density
  iAmPiscivorous = NO;

  if(fishActivity == FEED)
    {
		if(fishLength >= fishParams->fishPiscivoryLength)
		{
			iAmPiscivorous = YES;
			[habitatSpace incrementNumPiscivorousFish];
		}
    }

	// The variable toggledFishForHabSurvUpdate is set each day by the model swarm
	// method setUpdateAqPredToYes, part of the updateActions.
	// It is set to yes if this fish is either (a) the smallest
	// piscivory-length fish or (b) the last fish. The aquatic predation
	// survival probabilities in all reaches need to be updated when this fish moves. 
    if(toggledFishForHabSurvUpdate == self)
    {
		//fprintf(stdout, "TROUT >>>> moveTo >>>> I triggered aq pred update with length = %f\n", fishLength);
		//fflush(0);
       [habitatManager updateAqPredProbs];
	   // Now untoggle myself
	   toggledFishForHabSurvUpdate = nil;
    }




   //fprintf(stdout, "Trout >>>> moveTo >>>> END\n");
   //fflush(0);

  return self;


}
///////////////////////////////////////////////////////////////////////////
// End of Move
//////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////
//
// expectedMaturityAt
//
// FishActivity has the following values:
// FEED = -2, HIDE = -1, DRIFT = 0, SEARCH = 1
//
/////////////////////////////////////////////////////////////////
- (double) expectedMaturityAt: (FishCell *) aCell 
{ 

 // Exclude dry cells unless they are fish's current cell
 if([aCell getPolyCellDepth] <= 0.0 && aCell != fishCell) {
	return -1.0;
 }
 
 // Update standard resp. and CMax. CMax is re-calculated each time because
 // it is temperature-dependent and hence could differ among reaches.
 [self calcStandardRespirationAt: aCell];
 [self calcCmax: [aCell getTemperature]];

  FishActivity bestActivityForCell = HIDE;
  double bestERMForCell = -LARGEINT;

  depthLengthRatio = [aCell getPolyCellDepth]/fishLength;


  hourlyNetEnergyIfFeed = [self calcNetEnergyAt: aCell
                                   withActivity: FEED];

  hourlyNetEnergyIfHide = [self calcNetEnergyAt: aCell
                                   withActivity: HIDE];

  dailySurvivalIfFeed = [self     getNonStarvSPAt: aCell
                                     withActivity: FEED];

  dailySurvivalIfHide = [self     getNonStarvSPAt: aCell
                                     withActivity: HIDE];

  if(currentPhase == DAY)
  {
 
      //
      //  DAY FEED, NIGHT HIDE
      //

      dayFeedNightHideERM = [self calcESWithNetEnergyDay: hourlyNetEnergyIfFeed
                                        andNetEnergyNight: netEnergyForHidingLastPhase
                                           andSurvivalDay: dailySurvivalIfFeed 
                                         andSurvivalNight: survivalForHidingLastPhase
                                                 withCell: aCell];


   
      if(dayFeedNightHideERM > bestERMForCell)
      {
          bestERMForCell = dayFeedNightHideERM;
          bestActivityForCell = FEED;
      }

      if(dayFeedNightHideERM > tempBestERMForFeed)
      {
         tempBestERMForFeed = dayFeedNightHideERM;
         tempNetEnergyIfFeed = hourlyNetEnergyIfFeed;
         tempSurvivalIfFeed = dailySurvivalIfFeed;
      }


      //
      //  DAY FEED, NIGHT FEED
      //


      dayFeedNightFeedERM = [self calcESWithNetEnergyDay: hourlyNetEnergyIfFeed
                                     andNetEnergyNight: netEnergyForFeedingLastPhase
                                        andSurvivalDay: dailySurvivalIfFeed 
                                      andSurvivalNight: survivalForFeedingLastPhase
                                              withCell: aCell];


      if(dayFeedNightFeedERM > bestERMForCell)
      {
         bestERMForCell = dayFeedNightFeedERM;
         bestActivityForCell = FEED;
         
      }
     
      if(dayFeedNightFeedERM > tempBestERMForFeed)
      {
         tempBestERMForFeed = dayFeedNightFeedERM;
         tempNetEnergyIfFeed = hourlyNetEnergyIfFeed;
         tempSurvivalIfFeed = dailySurvivalIfFeed;
      }


      //
      //  DAY HIDE, NIGHT HIDE
      //

      dayHideNightHideERM = [self calcESWithNetEnergyDay: hourlyNetEnergyIfHide
                                     andNetEnergyNight: netEnergyForHidingLastPhase
                                        andSurvivalDay: dailySurvivalIfHide 
                                      andSurvivalNight: survivalForHidingLastPhase
                                              withCell: aCell];

      if(dayHideNightHideERM > bestERMForCell)
      {
          bestERMForCell = dayHideNightHideERM;
          bestActivityForCell = HIDE;
      }
     
      if(dayHideNightHideERM > tempBestERMForHide)
      {
         tempBestERMForHide = dayHideNightHideERM;
         tempNetEnergyIfHide = hourlyNetEnergyIfHide;
         tempSurvivalIfHide = dailySurvivalIfHide;
      }


      //
      //  DAY HIDE, NIGHT FEED
      //

      dayHideNightFeedERM = [self calcESWithNetEnergyDay: hourlyNetEnergyIfHide
                                     andNetEnergyNight: netEnergyForFeedingLastPhase
                                        andSurvivalDay: dailySurvivalIfHide 
                                      andSurvivalNight: survivalForFeedingLastPhase 
                                              withCell: aCell];


   
      if(dayHideNightFeedERM > bestERMForCell)
      {
          bestERMForCell = dayHideNightFeedERM;
          bestActivityForCell = HIDE;
      }

      if(dayHideNightFeedERM > tempBestERMForHide)
      {
         tempBestERMForHide = dayHideNightFeedERM;
         tempNetEnergyIfHide = hourlyNetEnergyIfHide;
         tempSurvivalIfHide = dailySurvivalIfHide;
      }



  }
  else if(currentPhase == NIGHT)
  {
 
      //
      //  DAY FEED, NIGHT HIDE 
      //

      dayFeedNightHideERM = [self calcESWithNetEnergyDay: netEnergyForFeedingLastPhase 
                                        andNetEnergyNight: hourlyNetEnergyIfHide 
                                           andSurvivalDay: survivalForFeedingLastPhase
                                         andSurvivalNight: dailySurvivalIfHide 
                                                 withCell: aCell];
   
      if(dayFeedNightHideERM > bestERMForCell)
      {
         bestERMForCell = dayFeedNightHideERM;
         bestActivityForCell = HIDE;
      }

      if(dayFeedNightHideERM > tempBestERMForHide)
      {
         tempBestERMForHide = dayFeedNightHideERM;
         tempNetEnergyIfHide = hourlyNetEnergyIfHide;
         tempSurvivalIfHide = dailySurvivalIfHide;
      }


      //
      //  DAY FEED, NIGHT FEED
      //

      dayFeedNightFeedERM = [self calcESWithNetEnergyDay: netEnergyForFeedingLastPhase 
                                        andNetEnergyNight: hourlyNetEnergyIfFeed 
                                           andSurvivalDay: survivalForFeedingLastPhase
                                         andSurvivalNight: dailySurvivalIfFeed
                                                 withCell: aCell];
   
      if(dayFeedNightFeedERM > bestERMForCell)
      {
         bestERMForCell = dayFeedNightFeedERM;
         bestActivityForCell = FEED;
      }

      if(dayFeedNightFeedERM > tempBestERMForFeed)
      {
         tempBestERMForFeed = dayFeedNightFeedERM;
         tempNetEnergyIfFeed = hourlyNetEnergyIfFeed;
         tempSurvivalIfFeed = dailySurvivalIfFeed;
      }

      //
      //  DAY HIDE, NIGHT HIDE
      //
      dayHideNightHideERM = [self calcESWithNetEnergyDay: netEnergyForHidingLastPhase 
                                        andNetEnergyNight: hourlyNetEnergyIfHide 
                                           andSurvivalDay: survivalForHidingLastPhase
                                         andSurvivalNight: dailySurvivalIfHide
                                                 withCell: aCell];


   
      if(dayHideNightHideERM > bestERMForCell)
      {
          bestERMForCell = dayHideNightHideERM;
          bestActivityForCell = HIDE;
      }
      
      if(dayHideNightHideERM > tempBestERMForHide)
      {
         tempBestERMForHide = dayHideNightHideERM;
         tempNetEnergyIfHide = hourlyNetEnergyIfHide;
         tempSurvivalIfHide = dailySurvivalIfHide;
      }



      //
      //  DAY HIDE, NIGHT FEED
      //
      dayHideNightFeedERM = [self calcESWithNetEnergyDay: netEnergyForHidingLastPhase 
                                        andNetEnergyNight: hourlyNetEnergyIfFeed 
                                           andSurvivalDay: survivalForHidingLastPhase
                                         andSurvivalNight: dailySurvivalIfFeed
                                                 withCell: aCell];


   
      if(dayHideNightFeedERM > bestERMForCell)
      {
         bestERMForCell = dayHideNightFeedERM;
         bestActivityForCell = FEED;
      }      

      if(dayHideNightFeedERM > tempBestERMForFeed)
      {
         tempBestERMForFeed = dayHideNightFeedERM;
         tempNetEnergyIfFeed = hourlyNetEnergyIfFeed;
         tempSurvivalIfFeed = dailySurvivalIfFeed;
      }





  }


 
  /*
  fprintf(stdout, "\n");
  fprintf(stdout, "TROUT >>>> expectedMaturityAt >>>> bestERMForCell = %f\n", bestERMForCell);
  fprintf(stdout, "TROUT >>>> expectedMaturityAt >>>> tempBestERMForFeed = %f\n", tempBestERMForFeed);
  fprintf(stdout, "TROUT >>>> expectedMaturityAt >>>> tempBestERMForHide = %f\n", tempBestERMForHide);
  fprintf(stdout, "TROUT >>>> expectedMaturityAt >>>> tempNetEnergyIfFeed = %f\n", tempNetEnergyIfFeed);
  fprintf(stdout, "TROUT >>>> expectedMaturityAt >>>> tempNetEnergyIfHide = %f\n", tempNetEnergyIfHide);
  fprintf(stdout, "TROUT >>>> expectedMaturityAt >>>> tempSurvivalIfFeed = %f\n", tempSurvivalIfFeed);
  fprintf(stdout, "TROUT >>>> expectedMaturityAt >>>> tempSurvivalIfHide = %f\n", tempSurvivalIfHide);
  fprintf(stdout, "\n");
  fflush(0);
  */
 



  //
  // set instance var fishActivity
  //

  fishActivity = bestActivityForCell;

  return bestERMForCell;

}


//////////////////////////////////////////////////////////////
//
//
// calcESWithNetEnergyDay:
//       andNetEnergyNight:
//          andSurvivalDay: 
//        andSurvivalNight:
//
/////////////////////////////////////////////////////////////
- (double) calcESWithNetEnergyDay: (double) aDayHourlyNetEnergy
                 andNetEnergyNight: (double) aNightHourlyNetEnergy
                    andSurvivalDay: (double) aSurvivalDay
                  andSurvivalNight: (double) aSurvivalNight
                          withCell: (FishCell *) aCell
{
  double ES;
  double starvSurvival = 0;
  double weightAtTForCell;
  double lengthAtTForCell; 
  double conditionAtTForCell; 
  double Kt, KT, a, b;

  double aNetEnergy;
  double aDailyNonStarvSurvival;

  double aDailyGrowth;

  double reproSuccessFunc;

  //fprintf(stdout, "Trout >>>> calcES... >>>> BEGIN\n");
  //fflush(0);

  aNetEnergy =   (aDayHourlyNetEnergy * numberOfDaylightHours)
               + (aNightHourlyNetEnergy * numberOfNightHours);


  aDailyGrowth = (aNetEnergy/(fishParams->fishEnergyDensity));
  aDailyNonStarvSurvival = ((aSurvivalDay * numberOfDaylightHours)
                             + (aSurvivalNight * numberOfNightHours))/24.0;

  aDailyNonStarvSurvival = ((aSurvivalDay * numberOfDaylightHours)
                            + (aSurvivalNight * numberOfNightHours))/24.0;

  weightAtTForCell = fishWeight + (fishParams->fishFitnessHorizon * aDailyGrowth);

  if (weightAtTForCell < 0.0) 
  {
      weightAtTForCell = 0.0;
  }

  lengthAtTForCell = [self getLengthForNewWeight: weightAtTForCell];

  conditionAtTForCell = [self getConditionForWeight: weightAtTForCell andLength: lengthAtTForCell];

  if(fabs(fishCondition - conditionAtTForCell) < 0.001) 
  {
     starvSurvival = [aCell getStarvSurvivalFor: self];
  }
  else 
  {
     a = starvPa;
     b = starvPb;
     Kt = fishCondition;  //current fish condition
     KT = conditionAtTForCell;
     starvSurvival =  (1/a)*(log((1+exp(a*KT+b))/(1+exp(a*Kt+b))))/(KT-Kt); 
  }  

  reproSuccessFunc = [model getReproFuncFor: self
                                 withLength: lengthAtTForCell];

  ES = pow((starvSurvival * aDailyNonStarvSurvival), fishParams->fishFitnessHorizon) * reproSuccessFunc;
  
  //fprintf(stdout, "Trout >>>> calcES... >>>> END\n");
  //fflush(0);
 
  return ES;
}


/////////////////////////////////////////////////////////////////////////
//
// grow  
//
// Comment: Grow is the third action taken by fish in their daily routine
//
////////////////////////////////////////////////////////////////////////
- grow 
{

  double intakeDuringActivity;
  double energyLossDuringPenalty;

  prevWeight = fishWeight;
  prevLength = fishLength;
  prevCondition = fishCondition;

  totalFoodConsumptionThisStep = 0.0;

  //fprintf(stdout, "Trout >>>> grow >>>> BEGIN\n");
  //fflush(0);
  if(causeOfDeath) 
  {
      return self;
  }
  

  if(fishDistanceLastMoved > 0.0)
  {
      if(fishParams->fishMovePenaltyTime < 0.0)
      {
           fprintf(stderr, "ERROR: Trout >>>> grow >>>> fishMovePenaltyTime is less than zero\n");
           fflush(stderr);
           exit(1);
      }

      if(numHoursSinceLastStep - fishParams->fishMovePenaltyTime > 0.0)
      {
          intakeDuringActivity = netEnergyForBestCell * (numHoursSinceLastStep - fishParams->fishMovePenaltyTime);

//
//  Added for TMII paper: total food consumption
//
          totalFoodConsumptionThisStep = (hourlyDriftConRate + hourlySearchConRate) * (numHoursSinceLastStep - fishParams->fishMovePenaltyTime);
      }
      else 
      {
          intakeDuringActivity = 0.0;
      }      
       

      if(numHoursSinceLastStep < fishParams->fishMovePenaltyTime)
      {
            energyLossDuringPenalty = numHoursSinceLastStep * [self calcTotalRespirationAt: fishCell withSwimSpeed: [fishCell getPolyCellVelocity]];
      }
      else
      {
            energyLossDuringPenalty = fishParams->fishMovePenaltyTime * [self calcTotalRespirationAt: fishCell withSwimSpeed: [fishCell getPolyCellVelocity]];
      }



      fishWeight = [self getWeightWithIntake: (intakeDuringActivity - energyLossDuringPenalty)];

  }  // fishDistanceLastMoved
  else
  {
      fishWeight = [self getWeightWithIntake: (netEnergyForBestCell * numHoursSinceLastStep)];
//
//  Added for TMII paper: total food consumption
//
      totalFoodConsumptionThisStep = (hourlyDriftConRate + hourlySearchConRate) * (numHoursSinceLastStep);
  }


  fishLength = [self getLengthForNewWeight: fishWeight];
  fishCondition = [self getConditionForWeight: fishWeight andLength: fishLength];
  fishFracMature = [self getFracMatureForLength: fishLength];
  // New for new getLengthForNewWeight  8 Aug 2014
  if(fishLength > prevLength)
  {
    fishWeightAtK1 = (fishParams->fishWeightParamA) * pow(fishLength, fishParams->fishWeightParamB);
  }

  //  Added to implement cMax:
  fishActualDailyIntake += totalFoodConsumptionThisStep;

  //
  // Added 6/13/2001 SKJ because swim speed changes when fish grow
  //
  
  maxSwimSpeed = [self calcMaxSwimSpeedAt: fishCell];

  
  //fprintf(stdout, "Trout >>>> grow >>>> END\n");
  //fflush(0);


  return self;
}


/////////////////////////////////////////////////////////////////////////////////////////
//
// die
// Comment: Die is the fourth action taken by fish in their daily routine 
//
////////////////////////////////////////////////////////////////////////////////////////
- die 
{
    //fprintf(stdout, "Trout >>>> die >>>> BEGIN\n");
    //fflush(0);

    if(imImmortal == YES)
    {
        return self;
    }

    //
    // if numHoursSinceLastStep < 1 crash and burn...
    //
    if(numHoursSinceLastStep < 1)
    {
         fprintf(stderr, "ERROR: Trout >>>> die >>>> numHoursSinceLastStep is < 1\n");
         fflush(0);
         exit(1);
    }

    #ifdef SURVIVAL_REPORT_ON
     //
     // printSurvivalReport needs to be fixed 
     // so that it can use the survival manager.
     //
     [self printSurvivalReport];
    #endif


    //
    // if we are already dead 
    // just return
    //
    if(causeOfDeath) return self;

    //
    // Begin code for the survival manager 
    //

    /*
           The mortality risks in the probMap are defined in Cell.m
           where the survival manager is set up. They occur in this 
           order:
               0. High temperature
			   1. High Velocity
               2. Stranding
               3. Aquatic predation
               4. Terrestial Predation
               5. Poor Condition
               6. Angling
               7. Hooking

            Angling and hooking mortality must be treated separately because 
            they already consider the number of hours being modeled; the other
            risks are modeled using 1-day survival probabilities.

     */

    {
       
       id <List> listOfSurvProbs;
       id <ListIndex> lstNdx;
       id <SurvProb> aProb;
       int survCount = 0;
       
       [fishCell updateFishSurvivalProbFor: self];
       
       listOfSurvProbs = [fishCell getListOfSurvProbsFor: self]; 

       lstNdx = [listOfSurvProbs listBegin: scratchZone];
     
       while(([lstNdx getLoc] != End) && ((aProb = [lstNdx next]) != nil))
       {
           // fprintf(stdout, "Trout >>>> die >>>> probName = %s survCount = %d\n", [aProb getName], survCount);
           // fflush(0);

           if(survCount < 6)
           {
               if([uniformDist getDoubleSample]  >  pow([aProb getSurvivalProb], (((double) numHoursSinceLastStep)/24.0)))
               {
                   char* deathName = (char *) [[aProb getProbSymbol] getName];
                   size_t strLen = strlen(deathName) + 1;
  
                   causeOfDeath = [aProb getProbSymbol];

                   deathCausedBy = (char *) [troutZone alloc: strLen*sizeof(char)];
                   strncpy(deathCausedBy, deathName, strLen);

                   deadOrAlive = "DEAD";
                   timeOfDeath = [self getCurrentTimeT]; 
                   [model addToKilledList: self];
                   [fishCell removeFish: self];
                   fishCell = nil;

                   break;
               }
           }
           else
           {
           // fprintf(stdout, "Trout >>>> die >>>> probName = %s survCount = %d\n", [aProb getName], survCount);
           // fflush(0);
               if([uniformDist getDoubleSample]  >  [aProb getSurvivalProb])
               {
                   char* deathName = (char *) [[aProb getProbSymbol] getName];
                   size_t strLen = strlen(deathName) + 1;
  
                   causeOfDeath = [aProb getProbSymbol];

                   deathCausedBy = (char *) [troutZone alloc: strLen*sizeof(char)];
                   strncpy(deathCausedBy, deathName, strLen);

                   deadOrAlive = "DEAD";
                   timeOfDeath = [self getCurrentTimeT]; 
                   [model addToKilledList: self];
                   [fishCell removeFish: self];
                   fishCell = nil;

                   break;

                }
           }
 
           survCount++;         

       } //while

        [lstNdx drop];
    }

    //
    // End code for the survival manager
    //
    //fprintf(stdout, "TROUT >>>> die >>>> END\n");
    //fflush(0);


    return self;

}

////////////////////////////////////////////////////////
//
// killFish AKA
// deathByDemonicIntrusion
//
////////////////////////////////////////////////////////
- killFish 
{
       //
       // if we are already dead 
       // just return
       //
       if(causeOfDeath) return self;

       //[(id <Model>)[[fishCell getSpace] getModel] addToKilledList: self];

       //causeOfDeath = [[fishCell getSpace] getDemonicIntrusionSymbol];
       deathCausedBy = "DemonicIntrusion";

       deadOrAlive = "DEAD";

       timeOfDeath = [self getCurrentTimeT]; 

       //
       // Moved this line here 3/28/03 SKJ
       //
       //[(id <Model>)[[fishCell getSpace] getModel] addToKilledList: self];
       [model addToKilledList: self];

       //[fishCell removeFish: self];
       fishCell = nil;

       return self;
}


///////////////////////////////////////////////
//
// getCauseOfDeath
//
//////////////////////////////////////////
- (id <Symbol>) getCauseOfDeath 
{
   return causeOfDeath;
}

//////////////////////////////////////////////////
//
// getTimeOfDeath
//
/////////////////////////////////////////////////
- (time_t) getTimeOfDeath 
{
  return timeOfDeath;
}



///////////////////////////////////////////////////////
//
// DiedOfCause
//
///////////////////////////////////////////////////////
- (BOOL) diedOf: (char *) aMortalitySource 
{
   if(strncmp(aMortalitySource, [causeOfDeath getName], strlen(aMortalitySource)) == 0) 
   {
        return YES;
   }
  
   return NO;
}


- setTimesHooked: (unsigned int) aNumberOfTimesHooked
{
     timesHooked = aNumberOfTimesHooked;

     /*
     fprintf(stderr, "TROUT >>>> timesHooked\n");
     fprintf(stderr, "TROUT >>>> timesHooked = %d\n", timesHooked);
     fprintf(stderr, "TROUT >>>> timesHooked\n");
     fflush(0);
     */

     return self;
}
    
- (unsigned int) getTimesHooked
{
   return timesHooked;
}


////////////////////////////////////////////////////////////////////////////////////////////
//
// compare
// Comment: Needed by QSort in TroutModelSwarm method: buildTotalTroutPopList
///////////////////////////////////////////////////////////////////////////////
- (int) compare: (Trout *) aFish 
{
  double otherFishLength;
  otherFishLength = [aFish getFishLength];

  if (fishLength > otherFishLength)
  {
    return 1;
  }
  else if(fishLength == otherFishLength)
  {
    return 0;
  }
  else
  {
    return -1;
  }
}





//////////////////////////////////////////////////////////
//
// getNonStarvSPAt
//
//  This method is used in MOVE to define the non-starvation
//  risks that the fish uses to make its movement decision.
//  These are the fish's PERCEIVED risks, and do not
//  necessarily have to be the real mortality risks used
//  in -die, as they currently are.
//
////////////////////////////////////////////////////////////
- (double) getNonStarvSPAt: (id) aCell
          withActivity: (FishActivity) aFishActivity 
{
  double aNonStarvSP = 1;
  double aMaxSwimSpeed = [self calcMaxSwimSpeedAt: aCell];


  //
  // Temporarily set instance variable for whether fish is
  // hiding
  //
  //
  // The instance variable swimSpdCVelocityRatio is also set her
  // for use in high velocity survival. This ratio is assumed equal
  // to cell velocity over max swimspeed for hiding fish; for 
  // feeding fish it may b reduced due to use of velocity shelters.
  // (The benefit of hiding cover is factored into the survival
  // probability separately.)
  //

  hidingCover = NO;

  if(aFishActivity == HIDE)
  {
      fishActivity = HIDE;
      if([aCell getIsHidingCoverAvailable]) hidingCover = YES;
      swimSpdVelocityRatio = [aCell getPolyCellVelocity]/aMaxSwimSpeed;
       // fprintf(stdout, "Trout >>>> HIDING >>>> ratio = %f maxSwimSpeed = %f\n", swimSpdVelocityRatio,maxSwimSpeed);
       // fflush(0);
  }
  else 
  {
      fishActivity = FEED;
      swimSpdVelocityRatio = cellSwimSpeed/aMaxSwimSpeed;
       // fprintf(stdout, "Trout >>>> FEEDING >>>> ratio = %f\n", swimSpdVelocityRatio);
       // fflush(0);
 
  }

  [aCell updateFishSurvivalProbFor: self];

  aNonStarvSP = [aCell getTotalKnownNonStarvSurvivalProbFor: self];

  return aNonStarvSP; 
}



//////////////////////////////////////////////////
//
// calcStarvPaAndPb
//
/////////////////////////////////////////////////
- calcStarvPaAndPb
{
  double x1 = fishParams->mortFishConditionK1;
  double x2 = fishParams->mortFishConditionK9;

  double y1 = LOWER_LOGISTIC_DEPENDENT;
  double y2 = UPPER_LOGISTIC_DEPENDENT;

  double u, v;

  if(x1 == x2)
  {
      fprintf(stderr, "Trout >>>> calcStarvPaAndPb... >>>> the independent variables mortFishConditionK1 and mortFishConditionK9 are equal\n");
      fflush(0);
      exit(1);
  }
  if((y1 == 1.0) || (y2 == 1.0))
  {
      fprintf(stderr, "Trout >>>> calcStarvPaAndPb... >>>> the dependent variables LOWER_LOGISTIC_DEPENDENT or LOWER_LOGISTIC_DEPENDENT equal 1.0\n");
      fflush(0);
      exit(1);
  }

  u = log(y1/(1.0-y1));
  v = log(y2/(1.0-y2));

  starvPa = (u - v)/(x1-x2);
  starvPb = u - starvPa*x1;

  return self;
}




////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////
//
//FISH FEEDING AND ENERGETICS
//
///////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////
- updateNumHoursSinceLastStep: (int *) aNumHours
{
   //fprintf(stderr, "TROUT >>>> updateNumHoursSinceLastStep \n");
   //fflush(0);

   numHoursSinceLastStep = *(int *)aNumHours;

   return self;
}

//////////////////////////////////////////
//
// FOOD INTAKE: DRIFT FEEDING STRATEGY
//
//
///////////////////////////////////////
/////////////////////////////////
//
// calcDriftIntake
// Comment: Intake = hourly rate 
//
// Replaced with method from inSTREAM Version 5 4/2013 SFR
/////////////////////////////////
- (double) calcDriftIntake: (FishCell *) aCell 
{
  double aDriftIntake;
  double aCaptureArea;
  double aCaptureSuccess;

  aCaptureArea = [self calcCaptureArea: aCell];
  aCaptureSuccess = [self calcCaptureSuccess: aCell];


  aDriftIntake =   [aCell getHabDriftConc] 
                 * [aCell getPolyCellVelocity]
                 * aCaptureArea 
                 * aCaptureSuccess
                 * 3600.0;

  return aDriftIntake;

}

///////////////////////////////////////////
//
//calcCaptureArea
//
// Replaced with method from inSTREAM Version 5 4/2013 SFR
//
//////////////////////////////////////////
- (double) calcCaptureArea: (FishCell *) aCell 
{
   double aCaptureArea;
   double depth;
   double minValue=0.0;
   double aDetectDistance = [self calcDetectDistanceAt: aCell];

   depth = [aCell getPolyCellDepth];
   minValue = (aDetectDistance < depth) ? detectDistance : depth;
   aCaptureArea = 2.0*aDetectDistance*minValue;

   return aCaptureArea;
}

//////////////////////////////////////////////////////////////
//
// calcDetectDistanceAt
//
// We do this for each cell because a fish may be looking 
// at cell that is in a reach different than the one a fish
// is currently in
//
//  Effect of night included here.
//////////////////////////////////////////////////////////////
- (double)  calcDetectDistanceAt: (FishCell *) aCell
{
   double habTurbidity;
   double turbidityFunction = 1.0;
   double aDetectDistance;
   double expFunction = -LARGEINT;
   double fishTurbidThreshold = fishParams->fishTurbidThreshold;

   if(aCell == nil)
   {
      fprintf(stderr, "ERROR: Trout >>>> calcDetectDistance >>>> aCell is nil\n");
      fflush(0);
      exit(1);
   }

   //
   // getTurbidity is a pass through to the habitatSpace 
   //
   habTurbidity = [aCell getTurbidity];

   //
   // The following if block modified 4/13/06 SKJ
   //
   if(habTurbidity > fishTurbidThreshold)
   {
      expFunction = exp(fishParams->fishTurbidExp * (habTurbidity - fishTurbidThreshold));
      
      turbidityFunction = (expFunction >= fishParams->fishTurbidMin) ? expFunction 
                                                                     : fishParams->fishTurbidMin;
   }

   aDetectDistance =   (fishParams->fishDetectDistParamA 
                     + (fishLength * fishParams->fishDetectDistParamB))
                     * turbidityFunction;
					 
	// Effect of night on drift detection
   if(currentPhase == NIGHT)
   {
      aDetectDistance *= fishParams->fishSearchNightFactor;
   }
 
   return aDetectDistance;
}


///////////////////////////////////////////////
//
// calcCaptureSuccess
//
//////////////////////////////////////////////
- (double) calcCaptureSuccess: (FishCell *) aCell
{
   double aCaptureSuccess;
   double velocity = 0.0;
   double aMaxSwimSpeed = [self calcMaxSwimSpeedAt: aCell];
   
   if(captureLogistic == nil)
   {
      fprintf(stderr, "ERROR: Trout >>>> calcCaptureSuccess >>>> captureLogistic is nil\n");
      fflush(0);
      exit(1);
   }

   if(aCell == nil)
   {
      fprintf(stderr, "ERROR: Trout >>>> calcCaptureSuccess >>>> aCell is nil\n");
      fflush(0);
      exit(1);
   }

   velocity = [aCell getPolyCellVelocity];

   aCaptureSuccess = [captureLogistic evaluateFor: (velocity/aMaxSwimSpeed)];

   return aCaptureSuccess;
}


/////////////////////////////////////////
//
//
// FOOD INTAKE: ACTIVE SEARCHING STRATEGY
//
//
////////////////////////////////////////
//
// calcMaxSwimSpeedAt:
//
// updateMaxSwimSpeed replaced with inSTREAM 5 method, SFR 4/2013
//
///////////////////////////////////////
- (double) calcMaxSwimSpeedAt: (FishCell *) aCell 
{
  double fMSPA = fishParams->fishMaxSwimParamA;
  double fMSPB = fishParams->fishMaxSwimParamB;
  double fMSPC = fishParams->fishMaxSwimParamC;
  double fMSPD = fishParams->fishMaxSwimParamD;
  double fMSPE = fishParams->fishMaxSwimParamE;
  double T = [aCell getTemperature];
  double aMaxSwimSpeed;

  //fprintf(stdout, "Trout >>>> calcMaxSwimSpeedAt >>>> temperature = %f \n", T);
  //fflush(0);

  aMaxSwimSpeed =   (fMSPA*fishLength + fMSPB)
                 * (fMSPC*T*T + fMSPD*T + fMSPE);

  if(aMaxSwimSpeed <= 0.0)
  {
      fprintf(stderr, "ERROR: Trout >>>> calcMaxSwimSpeed >>>> aMaxSwimSpeed is less than or equal to 0\n");
      fflush(0); 
      exit(1); 
  }

  return aMaxSwimSpeed;
} 


- (double) getMaxSwimSpeed
{
   return maxSwimSpeed;
}

- setMaxSwimSpeed: (double) aSwimSpeed 
{
  maxSwimSpeed = aSwimSpeed;
  return self;
}

////////////////////////////////////////////////////
//
//calcSearchIntakeAt
//
///////////////////////////////////////////////////
- (double) calcSearchIntakeAt: (FishCell *) aCell 
{
  double aSearchIntake;
  double fSA;
  double velocity=0.0;
  double habSearchProd=0.0;
  double aMaxSwimSpeed = [self calcMaxSwimSpeedAt: aCell];
  
  fSA = fishParams->fishSearchArea;

  velocity = [aCell getPolyCellVelocity];
  habSearchProd = [aCell getHabSearchProd];
 
  if(velocity > aMaxSwimSpeed) 
  {
     aSearchIntake = 0.0;
  }
  else 
  {
     aSearchIntake = habSearchProd * fSA * (aMaxSwimSpeed - velocity)/aMaxSwimSpeed;
  }

  if(currentPhase == NIGHT)
  {
      aSearchIntake *= fishParams->fishSearchNightFactor;
  }

  return aSearchIntake;
}


///////////////////////////////////////////////////////
//
//
//FOOD INTAKE: MAXIMUM CONSUMPTION
//
//
//////////////////////////////////////////////////////////
//calcCmax
//
// Note that in inSTREAM 6.0 CMax is a DAILY maximum consumption rate
// The CMax equations & parameters calc max DAILY, not hourly. 
// 
///////////////////////////////////////////////////////////
- calcCmax: (double) aTemperature 
{
  double fCPA,fCPB;
  double cmaxTempFunction;

  fCPA = fishParams->fishCmaxParamA;
  fCPB = fishParams->fishCmaxParamB;

  if(isnan(aTemperature) || isinf(aTemperature))
  {
     fprintf(stderr, "ERROR: Trout >>>> calcCmax >>>> an nan or inf occurred\n");
     fprintf(stderr, "ERROR: Trout >>>> calcCmax >>>> temperature = %f\n", aTemperature);
     fflush(0);
     exit(1);
  } 

  cmaxTempFunction = [cmaxInterpolator getValueFor: aTemperature];
  //
  //Note the  instance variables cMax and fishWeight in the following
  //
  cMax = (fCPA * pow(fishWeight,(1+fCPB)) * cmaxTempFunction);

  return self;

}

///////////////////////////////////////////
//
//
// FOOD INTAKE: FOOD AVAILABILITY
//
//
//
// RESPIRATION COSTS
//
///////////////////////////////////////////////////////
//
// calcStandardRespirationAt:
//
// Note: this now returns an HOURLY respiration rate.
// The parameters are for daily standard respiration.
// We divide the daily rate by 24 to get an hourly rate.
//
////////////////////////////////////////////////////////
- calcStandardRespirationAt: (FishCell *) aCell
{
  double fRPA=0.0,fRPB=0.0,fRPC=0.0;
  double temperature;

  if(aCell == nil)
  {
     fprintf(stderr, "ERROR: Trout >>>> calcStandardRespirationAt >>>> aCell is nil\n");
     fflush(0);
     exit(1);
  }

  temperature = [aCell getTemperature];

  fRPA = fishParams->fishRespParamA;
  fRPB = fishParams->fishRespParamB;
  fRPC = fishParams->fishRespParamC;

  //
  //Note the instance variables fishWeight and standardResp
  //
  standardResp = (fRPA * pow(fishWeight,fRPB) * exp(fRPC*temperature))/24.0;

  return self;

}
  

///////////////////////////////////////////////////////////
//
// calcActivityRespiration
//
// Note: this now returns an HOURLY activity respiration rate.
//
///////////////////////////////////////////////////////////
- (double) calcActivityRespirationAt: (FishCell *) aCell withSwimSpeed: (double) aSpeed 
{
  double aRespActivity;
  double fRPD;

  fRPD = fishParams->fishRespParamD;

  if(aSpeed > 0.0)
  {
      aRespActivity = (exp(fRPD*aSpeed) - 1.0) * standardResp;
  }
  else 
  {
      aRespActivity = 0.0; 
  }

  return aRespActivity;
}


//////////////////////////////////////////////////////
//
// calcTotalRespirationAt
//
//////////////////////////////////////////////////////
- (double) calcTotalRespirationAt: (FishCell *) aCell 
                    withSwimSpeed: (double) aSpeed 
{
  return [self calcActivityRespirationAt: aCell withSwimSpeed: aSpeed] + standardResp;
}


////////////////////////////////////////////////////////////////
//
//
// FEEDING STRATEGY SELECTION, NET ENERGY BENEFITS, AND GROWTH
//
//
////////////////////////////////////////////////////////////////
//
// calcDriftFoodIntakeAt
//
// Note: this now returns an HOURLY food intake
//
///////////////////////////////////////////////////////////////
- (double) calcDriftFoodIntakeAt: (FishCell *) aCell
{
   double aDriftFoodIntake;
   double anAvailableFood;
   double minvalue=0.0;

   anAvailableFood = [aCell getHourlyAvailDriftFood]; 
 
   //
   // The actual hourly drift intake is the minimum of the potential 
   // intake (in absence of competition), the food available in the cell,
   // and CMax.
   //

   minvalue = [self calcDriftIntake: aCell];
 
   if(anAvailableFood < minvalue) 
   {
       minvalue = anAvailableFood;
   }
   if((cMax - fishActualDailyIntake) < minvalue) 
   {
      minvalue = (cMax - fishActualDailyIntake);
   }

   aDriftFoodIntake = minvalue;

   if(aDriftFoodIntake < 0.0) // This can happen because cMax changes with weight, among reaches
   {
        // fprintf(stderr, "Warning: Trout >>>> calcDriftFoodIntakeAt: Negative drift food intake\n");
        // fprintf(stderr, "calcDriftIntake: %f availableDrift: %f cMax: %f fishActualIntake: %f drift intake: %f\n",
		                // [self calcDriftIntake: aCell], anAvailableFood, cMax, fishActualDailyIntake, minvalue);
        // fflush(0);
	 
	    aDriftFoodIntake = 0.0;
    }

   return aDriftFoodIntake; 
}


////////////////////////////////////////////////
//
// calcDriftNetEnergyAt
//
// Note: this now returns an HOURLY net energy
//
//////////////////////////////////////////////////
- (double) calcDriftNetEnergyAt: (FishCell *) aCell 
{
  double aDriftNetEnergy;   
 
  aDriftNetEnergy = ([self calcDriftFoodIntakeAt: aCell] * [aCell getHabPreyEnergyDensity])
                         - [self calcTotalRespirationAt: aCell withSwimSpeed:
                           [self getSwimSpeedAt: aCell forStrategy: DRIFT]];

  return aDriftNetEnergy;
}

//////////////////////////////////////////////
//
//getSwimSpeedAt
//
//////////////////////////////////////////////
- (double) getSwimSpeedAt: (FishCell *) aCell
              forStrategy: (int) aFeedStrategy 
{
  if(([self getIsShelterAvailable: aCell] == YES) && (aFeedStrategy == DRIFT))
  {
      return ([aCell getPolyCellVelocity] * [aCell getHabShelterSpeedFrac]); 
     
  }
  else if(aFeedStrategy == HIDE)
  {
      return 0.0;
  }
  else
  {
     return [aCell getPolyCellVelocity];
  }

}


///////////////////////////////////////
//
// getIsShelterAvailable
//
////////////////////////////////////
- (BOOL) getIsShelterAvailable: (FishCell *) aCell 
{
   if([aCell getShelterAreaAvailable] > 0.0) 
   {
      return YES;
   }
   else 
   {
      return NO;
   }
}

/////////////////////////
//
//getAmIInAShelter 
//
/////////////////////////
- (BOOL) getAmIInAShelter 
{
   return velocityShelter;
}



///////////////////////////////
//
// getAmIInHidingCover
//
///////////////////////////////
- (BOOL) getAmIInHidingCover
{
   return hidingCover;
}




/////////////////////////////////////////////////
//
// calcSearchFoodIntakeAt
//
// Note: this now returns an HOURLY food intake
//
/////////////////////////////////////////////////
- (double) calcSearchFoodIntakeAt: (FishCell *) aCell
{
   double aSearchFoodIntake;
   double anAvailableSearchFood;
   double minvalue=0.0;
   
   if([aCell getPolyCellDepth] <= 0.0)  //This could happen if no wet cells are nearby
   {
	return 0.0;
	}

   anAvailableSearchFood = [aCell getHourlyAvailSearchFood];
 
  //
  // aSearchFoodIntake is the minimum 
  // of anAvailableSearchFood and cMax
  //
   minvalue = [self calcSearchIntakeAt: aCell];
 
   if(anAvailableSearchFood < minvalue) 
   {
      minvalue = anAvailableSearchFood;
   }
   if((cMax - fishActualDailyIntake) < minvalue) 
   {
      minvalue = (cMax - fishActualDailyIntake);
   }

   aSearchFoodIntake = minvalue;
   
   if(aSearchFoodIntake < 0.0) // This can happen because cMax changes with weight, among reaches
   {
        // fprintf(stderr, "Warning: Trout >>>> calcSearchFoodIntakeAt: Negative search food intake\n");
        // fprintf(stderr, "calcSearchIntake: %f availableSearch: %f cMax: %f fishActualIntake: %f search intake: %f\n",
		                // [self calcSearchIntakeAt: aCell], anAvailableSearchFood, cMax, fishActualDailyIntake, minvalue);
		
		aSearchFoodIntake = 0.0;
  //      exit(1);
    }

   return aSearchFoodIntake;
}




/////////////////////////////////////////////////////////
//
// calcSearchNetEnergyAt
//
// Note: this now returns an HOURLY net energy
//
/////////////////////////////////////////////////////
- (double) calcSearchNetEnergyAt: (FishCell *) aCell 
{
   double aSearchNetEnergy;   

   aSearchNetEnergy = ([self calcSearchFoodIntakeAt: aCell] * [aCell getHabPreyEnergyDensity] )
                          - [self calcTotalRespirationAt: aCell withSwimSpeed: 
                                      [self getSwimSpeedAt: aCell forStrategy: SEARCH]];

   return aSearchNetEnergy;

}


//////////////////////////////////////////////////////////
//
// calcFeedingNetEnergyForCell
//
// Note: this now returns an HOURLY net energy
//
//////////////////////////////////////////////////////////
- (double) calcFeedingNetEnergyForCell: (FishCell *) aCell 
{
   double aNetEnergy=0.0;
   double aSearchNetEnergy, aDriftNetEnergy;

   aDriftNetEnergy = [self calcDriftNetEnergyAt: aCell];
   aSearchNetEnergy = [self calcSearchNetEnergyAt: aCell];
   
 //
 // Select the most profitable feeding strategy
 //
       if(aDriftNetEnergy >= aSearchNetEnergy)
       {
           aNetEnergy = aDriftNetEnergy;
           cellFeedingStrategy = DRIFT;
       }
       else 
       {
           aNetEnergy = aSearchNetEnergy;
           cellFeedingStrategy = SEARCH;
       }   

   //
   // cellSwimSpeed is used by hi velocity survival
   //
   cellSwimSpeed = [self getSwimSpeedAt: aCell forStrategy: cellFeedingStrategy];   
  
   return aNetEnergy;
}

//////////////////////////////////////////////
//
// calcNetEnergyAt:withActivity:
//
/////////////////////////////////////////////
- (double) calcNetEnergyAt: (FishCell *) aCell 
             withActivity: (FishActivity) aFishActivity
{
   double aNetEnergy=0.0;

   if(aFishActivity == FEED)
   {
       //
       // This also sets the cellFeedingStrategy 
       // when feeding
       //
       aNetEnergy = [self calcFeedingNetEnergyForCell: aCell]; 
   }
   else if(aFishActivity == HIDE)
   {
       aNetEnergy = standardResp;
   
       aNetEnergy = -aNetEnergy;

       cellFeedingStrategy = HIDE;
   }
   else
   {
        fprintf(stderr, "ERROR: Trout >>>> calcNetEnergyAt: withStrategy: incorrect feed Strategy\n");
        fflush(0);
        exit(1);
   }

   return aNetEnergy;
}
   


- (int) getFishFeedingStrategy 
{
  return fishFeedingStrategy;
}

- (double) getHourlyDriftConRate 
{
   return hourlyDriftConRate;
}

- (double) getHourlySearchConRate 
{
   return  hourlySearchConRate;
}




///////////////////////////////////////////////////
//
// calcMaxMoveDistance
//
///////////////////////////////////////////////////
- calcMaxMoveDistance 
{
  maxMoveDistance =   fishParams->fishMoveDistParamA
                    * pow(fishLength, fishParams->fishMoveDistParamB);

  return self;
}

///////////////////////////////
//
// makeMeImmortal
//
//////////////////////////////
- makeMeImmortal
{
   if(imImmortal == NO)
   {
       imImmortal = YES;
   }

   return self;
}



///////////////////////////////////////////////////////////////
//
// moveReport
//
//////////////////////////////////////////////////////////////
- moveReport: (FishCell *) aCell 
{
  FILE *mvRptPtr=NULL;
  const char *mvRptFName = "MoveTest.rpt";
  static int mR=0;
  double velocity, depth, temp, turbidity, availableDrift, availableSearch;
  double captureSuccess; 
  const char *mySpecies;

  char date[12];
  int hour;

  time_t modelTime = [(id <Model>) model getModelTime];
  
  int cellNo = [aCell getPolyCellNumber];
  double shelterAreaAvailable = [aCell getShelterAreaAvailable];
  double hidingCoverAvailable = [aCell getHidingCoverAvailable];

  velocity = [aCell getPolyCellVelocity];
  depth    = [aCell getPolyCellDepth];
  temp    = [aCell getTemperature];
  turbidity = [aCell getTurbidity];
  availableDrift = [aCell getHourlyAvailDriftFood];
  availableSearch = [aCell getHourlyAvailSearchFood];
  captureSuccess = [self calcCaptureSuccess: aCell];

  strncpy(date, [timeManager getDateWithTimeT: modelTime], 12);
  hour = [timeManager getHourWithTimeT: modelTime];


  //
  // Cell variables: cell id, Cell no., available hiding cover, 
  // Fish variables: output memory variables, 
  //                 day or night
  //int numHoursSinceLastStep;
  //
  //double netEnergyForFeedingLastPhase;
  //double netEnergyForHidingLastPhase;
  //double survivalForFeedingLastPhase;
  //double survivalForHidingLastPhase;

  //double hourlyNetEnergyIfFeed;
  //double hourlyNetEnergyIfHide;
  //double dailySurvivalIfFeed;
  //double dailySurvivalIfHide;

  //double dayFeedNightHideERM;
  //double dayFeedNightFeedERM;
  //double dayHideNightHideERM;
  //double dayHideNightFeedERM;



  mySpecies = [[self getSpecies]  getName];

  if( mR == 0) 
  {
      if((mvRptPtr = fopen(mvRptFName,"w+")) != NULL ) 
      {

     fprintf(mvRptPtr,"%-15s%-15s%-15s%-15s%-15s%-15s%-19s%-19s%-15s%-15s%-15s%-15s%-15s%-15s%-23s%-15s%-23s%-15s%-15s%-15s%-15s%-30s%-30s%-30s%-30s%-30s%-30s%-30s%-30s%-30s%-30s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-17s%-19s%-15s%-15s%-17s\n",
                                                            "Date",
                                                            "Hour",
                                                            "FishID",
                                                            "Species",
                                                            "BESTDEST",
                                                            "CELLNO",
                                                            "SHELTERAREAAVAIL",
                                                            "HIDINGCOVERAVAIL",
							    "VELOCITY",
							    "DEPTH",
							    "TEMP",
                                                            "TURBIDITY",
							    "AVAIL_DRIFT",
							    "AVAIL_SEARCH",
                                                            "NumHoursSinceLastStep",
                                                            "CurrentPhase",
                                                            "NumberofDaylightHours",
							    "fishLength",
							    "fishWeight",
							    "captureSuccess",
							    "fishSwimSpeed",
                                                            "NetEnergyForFeedingLastPhase",
                                                            "NetEnergyForHidingLastPhase",
                                                            "SurvivalForFeedingLastPhase",
                                                            "SurvivalForHidingLastPhase",
// not updated                                              "HourlyNetEnergyIfFeed",
// not updated                                              "HourlyNetEnergyIfHide",
                                                            "DailySurvivalIfFeed",
                                                            "DailySurvivalIfHide",
                                                            "DayFeedNightHideERM",
                                                            "DayFeedNightFeedERM",
                                                            "DayHideNightHideERM",
                                                            "DayHideNightFeedERM",
							    "detectDistance",
							    "cMax",       
							    "cMaxFT",       
							    "standardResp",
							    "activeResp", 
							    "inShelter", 
                                                            "inHidingCover",
							    "driftNetEnergy",
							    "searchNetEnergy",
							    "feedStrategy",
							    "nonStarvSurv",
							    "dailyIntake",
							    "ntEnrgyFrBstCll");
     mR++;
 fclose(mvRptPtr);
}
else 
{
  fprintf(stderr, "ERROR: Cannot open %s for writing\n", mvRptFName);
  fflush(0);
  exit(1);
}

}

  if((mvRptPtr = fopen(mvRptFName,"a")) == NULL) 
  {
     fprintf(stderr, "ERROR: Cannot open %s for appending\n",mvRptFName);
     fflush(0);
     exit(1);

  }
  fprintf(mvRptPtr, "%-15s%-15d%-15p%-15s%-15p%-15d%-19E%-19E%-15E%-15E%-15E%-15E%-15E%-15E%-23d%-15d%-23f%-15E%-15E%-15E%-15E%-30E%-30E%-30E%-30E%-30E%-30E%-30E%-30E%-30E%-30E%-15E%-15E%-15E%-15E%-15E%-15s%-15s%-17E%-19E%-15s%-15E%-15E%-15E\n",
                                                   date,
                                                   hour,
                                                   self,
												   mySpecies,
                                                   aCell,
                                                   cellNo,
                                                   shelterAreaAvailable,
                                                   hidingCoverAvailable,
						   velocity,
						   depth,
 						   temp,
                                                   turbidity,
						   availableDrift,
						   availableSearch,
                                                   numHoursSinceLastStep,
                                                   currentPhase,
                                                   numberOfDaylightHours,
						   fishLength,
						   fishWeight,
						  captureSuccess,
							fishSwimSpeed,
                                                   netEnergyForFeedingLastPhase,
                                                   netEnergyForHidingLastPhase,
                                                   survivalForFeedingLastPhase,
                                                   survivalForHidingLastPhase,
// not updated                                     hourlyNetEnergyIfFeed,
// not updated                                     hourlyNetEnergyIfHide,
                                                   dailySurvivalIfFeed,
                                                   dailySurvivalIfHide,
                                                   dayFeedNightHideERM,
                                                   dayFeedNightFeedERM,
                                                   dayHideNightHideERM,
                                                   dayHideNightFeedERM,
						   detectDistance,
						   cMax,
						   cMaxFT,
						   standardResp,
						   activeResp,
						   inShelter,
                                                   inHidingCover,
						   driftNetEnergy,
						   searchNetEnergy,
						   feedStrategy,
						   nonStarvSurvival,
						   fishActualDailyIntake,
						   netEnergyForBestCell);



fclose(mvRptPtr);
return self;

}


#ifdef MOVE_DISTANCE_REPORT_ON

///////////////////////////////////////////////////////////////
//
// moveDistanceReport
//
//////////////////////////////////////////////////////////////
- moveDistanceReport: (FishCell *) aCell 
{
  FILE *mvDistanceRptPtr=NULL;
  const char *mvDistanceRptFName = "MoveDistance.rpt";
  static int mDR=0;
  const char *mySpecies;

  char date[12];
  int hour;

  time_t modelTime = [(id <Model>) model getModelTime];

  strncpy(date, [timeManager getDateWithTimeT: modelTime], 12);
  hour = [timeManager getHourWithTimeT: modelTime];


  mySpecies = [[self getSpecies]  getName];

  //
  // Write the header once...
  //
  if(mDR == 0) 
  {
     if((mvDistanceRptPtr = fopen(mvDistanceRptFName,"w+")) != NULL )
     {
          fprintf(mvDistanceRptPtr,"%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s\n",
                                  "Scenario",
                                  "Replicate",
                                  "Date",
                                  "Hour",
                                  "CurrentPhase",
                                  "Flow",
                                  "FishID",
                                  "Species",
                                  "Age",
                                  "Length",
                                  "DistanceMoved");


         mDR++;
         fclose(mvDistanceRptPtr);
    }
    else 
    {
        fprintf(stderr, "ERROR: Trout >>>>> Cannot open %s for writing\n", mvDistanceRptFName);
        fflush(0);
        exit(1);
    }

  }

  if((mvDistanceRptPtr = fopen(mvDistanceRptFName,"a")) == NULL) 
  {
        fprintf(stderr, "ERROR: Cannot open %s for appending",mvDistanceRptFName);
        fflush(0);
        exit(1);
  }

  fprintf(mvDistanceRptPtr,"%-15d%-15d%-15s%-15d%-15d%-15f%-15p%-15s%-15d%-15f%-15f\n",
                              scenario,
                              replicate,
                              date,
                              hour,
                              currentPhase,
                              [aCell getRiverFlow],
                              self,
                              mySpecies,
                              age,
                              fishLength,
                              fishDistanceLastMoved);


   fclose(mvDistanceRptPtr);

   return self;
}

#endif



#ifdef SURVIVAL_REPORT_ON

//
// This needs to be fixed so that it
// can use the survival manager.
//


//////////////////////////////////////////////////////////////////
//
// printSurvivalReport
//
/////////////////////////////////////////////////////////////////
- printSurvivalReport 
{
   FILE * survReportPtr=NULL;
   const char * survivalReport = "SurvivalTest.rpt";
   static BOOL survReportFirstTime=YES;

   id <List> listOfSurvProbs;
   id <ListIndex> lstNdx;
   double velocitySurvProb = 0.0;
   double strandingSurvProb = 0.0;
   double spawnSurvProb = 0.0;
   double aqPredationSurvProb = 0.0;
   double terrPredationSurvProb = 0.0;
   double poorConditionSurvProb = 0.0;
   double anglingSurvProb = 0.0;
   double hookingSurvProb = 0.0;

   if(causeOfDeath)
   { 
      return self;
   }

   

       
   [fishCell updateFishSurvivalProbFor: self];
       
   listOfSurvProbs = [fishCell getListOfSurvProbsFor: self]; 

   lstNdx = [listOfSurvProbs listBegin: scratchZone];

   /*
           The mortality risks in the probMap are defined in Cell.m
           where the survival manager is set up. They occure in this 
           order:
               0. High Velocity
               1. Stranding
               2. Spawning
               3. Aquatic predation
               4. Terrestial Predation
               5. Poor Condition
               6. Angling
               7. Hooking

            Angling and hooking mortality must be treated separately because 
            they already consider the number of hours being modeled; the other
            risks are modeled using 1-day survival probabilities.
     */

     velocitySurvProb = [[listOfSurvProbs atOffset: 0] getSurvivalProb];
     strandingSurvProb = [[listOfSurvProbs atOffset: 1] getSurvivalProb];
     spawnSurvProb = [[listOfSurvProbs atOffset: 2] getSurvivalProb];
     aqPredationSurvProb = [[listOfSurvProbs atOffset: 3] getSurvivalProb];
     terrPredationSurvProb = [[listOfSurvProbs atOffset: 4] getSurvivalProb];
     poorConditionSurvProb = [[listOfSurvProbs atOffset: 5] getSurvivalProb];
     anglingSurvProb = [[listOfSurvProbs atOffset: 6] getSurvivalProb];
     hookingSurvProb = [[listOfSurvProbs atOffset: 7] getSurvivalProb];


     if(survReportFirstTime == YES) 
     {
	 if((survReportPtr = fopen(survivalReport, "w+")) == NULL) 
         {
	    fprintf(stderr, "ERROR: Trout >>>> printSurvivalReport >>>> Cannot open %s for writing\n",survivalReport);
            fflush(0);
            exit(1);
	 }
     
     fprintf(survReportPtr, "%-30s%-65s%-95s%-35s%-150s%-165s%-45s%-145s%-15s\n", " ", "Velocity:", "Stranding:", "Spawning:", "Aquatic Predation:", "Terrestial Predation:", "Poor Condition:", "Angling:", "Hooking:");
     fflush(survReportPtr);
   

     fprintf(survReportPtr,"%-15s%-15s%-25s%-20s%-20s%-15s%-15s%-25s%-20s%-20s%-20s%-15s%-15s%-20s%-15s%-20s%-25s%-15s%-20s%-20s%-20s%-20s%-20s%-20s%-20s%-20s%-20s%-25s%-20s%-25s%-15s%-25s%-20s%-15s%-15s%-15s%-20s%-20s%-15s\n",
                                                    "Species",
						    "ID",
     //VelocitySurvProb:
                                                    "SwimSpdVelocityRatio",
                                                    "HidingCover",
                                                    "VelocitySurvProb", 
     //StrandingSurvProb:
                                                    "PolyCellDepth",
                                                    "FishLength",
                                                    "CellDepth/FishLength",
                                                    "DepthLengthRatio",
                                                    "StrandingSurvProb",
     //SpawnSurvProb:
                                                    "FishSpawnedThisTime",
                                                    "SpawnSurvProb",
     //AqPredationSurvProb:
                                                    "CurrentPhase", 
                                                    "AmIInHidingCover",	
                                                    "PolyCellDepth",
                                                    "PolyCellTemperature",
                                                    "PiscivorousFishDensity",
                                                    "FishLength",
                                                    "PolyCellTurbidity",
                                                    "AqPredationSurvProb",
    //TerrestialPredation:
                                                    "CurrentPhase",
                                                    "AmIInHidingCover",
                                                    "PolyCellDepth",
                                                    "PolyCellVelocity",
                                                    "FishLength",
                                                    "PolyCellTurbidity",
                                                    "DistanceToHide",
                                                    "TerrPredationSurvProb",
    //PoorCondition:
                                                    "FishCondition",
                                                    "PoorConditionSurvProb",
    //Angling     
                                                    "FishLength",
                                                    "MortFishAngleSuccess",
                                                    "AnglingPressure",
                                                    "ReachLength",
                                                    "NumHours",
                                                    "CurrentPhase",
                                                    "HabAngleNightFactor",
                                                    "AnglingSurvProb",
                                                    "HookingSurvProb");


     fflush(survReportPtr);


     }
     if(survReportFirstTime == NO) 
     {
	 if((survReportPtr = fopen(survivalReport, "a")) == NULL) 
         {
	    fprintf(stderr, "ERROR: Trout >>>> printSurvivalReport >>>> Cannot open %s for writing\n",survivalReport);
            fflush(0);
            exit(1);
	 }
     }

    fprintf(survReportPtr,"%-15s%-15p%-25E%-20E%-20E%-15E%-15E%-25E%-20E%-20E%-20E%-15E%-15E%-20E%-15E%-20E%-25E%-15E%-20E%-20E%-20E%-20E%-20E%-20E%-20E%-20E%-20E%-25E%-20E%-25E%-15E%-25E%-20E%-15E%-15d%-15E%-20E%-20E%-15E\n",
					           [species getName],
                                                   self,
                                                   [self getSwimSpdVelocityRatio],
                                                   (double) [self getAmIInHidingCover], 
                                                   velocitySurvProb,
                                                   [fishCell getPolyCellDepth],
                                                   [self getFishLength],
                                                   [fishCell getPolyCellDepth]/[self getFishLength],
                                                   [self getDepthLengthRatio],
                                                   strandingSurvProb,
                                                   (double) [self getFishSpawnedThisTime],
                                                    spawnSurvProb,
                                                   (double) [fishCell getCurrentPhase], 
                                                   (double) [self getAmIInHidingCover],
                                                   [fishCell getPolyCellDepth],
                                                   [fishCell getTemperature],
                                                   [self getPiscivorousFishDensity],
                                                   [self getFishLength],
                                                   [fishCell getTurbidity],
                                                   aqPredationSurvProb, 
                                                   (double) [fishCell getCurrentPhase],
                                                   (double) [self getAmIInHidingCover],
                                                   [fishCell getPolyCellDepth],
                                                   [fishCell getPolyCellVelocity],
                                                   [self getFishLength],
                                                   [fishCell getTurbidity],
                                                   [fishCell getDistanceToHide],
                                                   terrPredationSurvProb,
                                                   [self getFishCondition],
                                                   poorConditionSurvProb, 
                                                   [self getFishLength],
                                                   fishParams->mortFishAngleSuccess,
                                                   [fishCell getAnglingPressure],
                                                   [fishCell getReachLength],
                                                   numHoursSinceLastStep,
                                                   (double) [fishCell getCurrentPhase],
                                                   (double) [fishCell getHabAngleNightFactor],
                                                   anglingSurvProb,
                                                   hookingSurvProb); 

    fflush(survReportPtr);

    survReportFirstTime = NO;

    if(survReportPtr != NULL) 
    {
       fclose(survReportPtr);
    }

    [lstNdx drop];

return self;

}

#endif



#ifdef SPAWN_REPORT_ON

///////////////////////////////////////////////////////////////
//
// printSpawnReport
//
///////////////////////////////////////////////////////////////

- printSpawnReport: aCell 
{
   FILE * spawnReportPtr=NULL;
   const char * spawnReport = "SpawnTest.rpt";
   static BOOL spawnReportFirstTime=YES;

     if( spawnReportFirstTime == YES ) {
	 if( (spawnReportPtr = fopen(spawnReport, "w+")) == NULL ) {
	    [InternalError raiseEvent:"ERROR: Cannot open %s for writing",spawnReport];
	 }
      fprintf(spawnReportPtr,"%-15s%-15s%-15s%-15s%-15s%-15s%-15s\n","Depth",
                                                                   "Velocity",
                                                                  "Cell Area",
                                                                  "fracSpawn",
                                                              "SpawnDepthSuit",
                                                               "SpawnVelSuit",
                                                               "spawnQuality");
     }

     if(spawnReportFirstTime == NO) {
	 if( (spawnReportPtr = fopen(spawnReport, "a")) == NULL ) {
	      fprintf(stderr, "ERROR: Cannot open %s for writing",spawnReport);
              fflush(0);
              exit(1);
	 }

     }

   fflush(0);

   spawnReportFirstTime = NO;

   if(spawnReportPtr != NULL) 
   {
     fclose(spawnReportPtr);
   }

   return self;
}

#endif



//////////////////////////////////////////////////////////////
//
// printInfo
//
// Called only once from the model swarm on the first
// day before any thing happens to the fish
//
///////////////////////////////////////////////////////////////
- printInfo: (FILE *) fpmReportPtr 
{ 
  fprintf(fpmReportPtr,"%-10s%-10s%-10d%-13f\n",[species getName], [sex getName], age, fishLength);
  fflush(fpmReportPtr);
  return self;
}


//#ifdef READY_TO_SPAWN_RPT
///////////////////////////////////////////////////////////
//
// printReadyToSpawnRpt
//
///////////////////////////////////////////////////////////
- printReadyToSpawnRpt: (BOOL) readyToSpawn 
{
  FILE * spawnReportPtr=NULL; 
  const char * readyToSpawnFile = "Ready_To_Spawn.rpt"; 
 
  static BOOL firstRTSTime=YES;

  char * readyTSString = "NO";

  //int currentDateDiff;

  time_t currentTime = (time_t) 0;

  int fishSpawnDateDiff;

  char *lastSpawnDate = (char *) NULL;  

  int   fSED;
  int   fSSD;

  if(readyToSpawn == YES) 
  {
     readyTSString = "YES";
  }

  if(firstRTSTime == YES) 
  {
     if((spawnReportPtr = fopen(readyToSpawnFile,"w+")) == NULL)
     {
         fprintf(stderr, "ERROR: Trout >>>> Cannot open %s for writing",readyToSpawnFile);
         fflush(0);
         exit(1);
     }

     fprintf(spawnReportPtr,"%-15s%-12s%-4s%-9s%-12s%-15s%-18s%-12s%-12s%-20s%-15s%-12s\n","Date",
                                                                        "Species",
                                                                        "Age",
                                                                        "Sex",
                                                                        "Temperature",
                                                                        "DailyMeanFlow",
                                                                        "ChangeInDailyFlow",
                                                                        "FishLength",
                                                                        "Condition",
                                                                        "SpawnedThisSeason",
                                                                        "LastSpawnDate",
                                                                        "ReadyToSpawn");
  }
  if(firstRTSTime == NO) 
  {
     if((spawnReportPtr = fopen(readyToSpawnFile,"a")) == NULL) 
     {
         fprintf(stderr, "ERROR: Cannot open %s for writing",readyToSpawnFile);
         fflush(0);
         exit(1);
     }
  }

  lastSpawnDate = [[self getZone] alloc: 12*sizeof(char)];

  currentTime = [self getCurrentTimeT];

  fSED  = [timeManager getJulianDayWithDay: (char *) fishParams->fishSpawnEndDate];
  fSSD  = [timeManager getJulianDayWithDay: (char *) fishParams->fishSpawnStartDate];

  if((fishSpawnDateDiff = ( fSED - fSSD )) < 0) 
  {
        fishSpawnDateDiff = (365 - fSSD) + fSED;         
  }
 

  if(timeLastSpawned > (time_t) 0)
  {
       strncpy(lastSpawnDate, [timeManager getDateWithTimeT: timeLastSpawned], 12);
       // currentDateDiff = [timeManager getNumberOfDaysBetween: timeLastSpawned
                                                         // and: currentTime];
  } 
  else 
  {
         strncpy(lastSpawnDate, "00/00/0000", (size_t) 12);
        // currentDateDiff = -1;
  }

  fprintf(spawnReportPtr,"%-15s%-12s%-4d%-9s%-12f%-15f%-18f%-12f%-12f%-20d%-15s%-12s\n",
                         [timeManager getDateWithTimeT: currentTime],
                                                   [species getName],
                                                                 age,
                                                       [sex getName],
                                    [fishCell getTemperature],
                                             [fishCell getDailyMeanFlow],
                                            [fishCell getChangeInDailyFlow],
                                                          fishLength,
                                                       fishCondition,
                                                       (int) spawnedThisSeason,
                                                       lastSpawnDate,
                                                       readyTSString);

   firstRTSTime = NO;

   fclose(spawnReportPtr);
   return self;
} 
//#endif


#ifdef SPAWN_CELL_RPT
- printSpawnCellRpt: (id <List>) spawnCellList 
{
  FILE * spawnCellRptPtr=NULL;
  const char * spawnCellFile = "Spawn_Cell.rpt";
  static BOOL spawnCellFirstTime = YES;

  id <ListIndex> cellListNdx=nil;
  id  aCell=nil;

  if(spawnCellFirstTime == YES) 
  {
      if((spawnCellRptPtr = fopen(spawnCellFile,"w+")) == NULL) 
      {
           fprintf(stderr, "ERROR: Cannont open report file %s for writing", spawnCellFile);
           fflush(0);
           exit(1);
      }

      fprintf(spawnCellRptPtr,"%-15s%-15s%-15s%-15s%-15s%-15s%-15s\n","Depth",
                                                                     "Velocity",
                                                                     "Area",
                                                                     "fracSpawn",
                                                                     "DepthSuit",
                                                                     "VelSuit",
                                                                     "spawnQuality");
      fflush(spawnCellRptPtr);
  }

  if(spawnCellFirstTime == NO) 
  {
       if((spawnCellRptPtr = fopen(spawnCellFile,"a")) == NULL)
       {
           fprintf(stderr, "ERROR: Cannont open report file %s for writing", spawnCellFile);
           fflush(0);
           exit(1);
       }
  }

  cellListNdx = [spawnCellList listBegin: [self getZone]];

  while(([cellListNdx getLoc] != End) && ((aCell = [cellListNdx next]) != nil))
  {
    
      fprintf(spawnCellRptPtr,"%-15f%-15f%-15f%-15f%-15f%-15f%-15f\n",[aCell getPolyCellDepth],
                                                              [aCell getPolyCellVelocity],
                                                                    [aCell getPolyCellArea],
                                                             [aCell getCellFracSpawn],
                                       [self getSpawnDepthSuitFor: [aCell getPolyCellDepth] ],
                                  [self getSpawnVelSuitFor: [aCell getPolyCellVelocity] ],
                                                     [self getSpawnQuality: aCell]); 

      
  }  
 
  [cellListNdx drop];
  fclose(spawnCellRptPtr);
  spawnCellFirstTime = NO;

   return self;
}

#endif


- setAgeSymbol: (id <Symbol>) anAgeSymbol
{
    ageSymbol = anAgeSymbol;
    return self;
}
   
- (id <Symbol>) getAgeSymbol
{
    return ageSymbol;
}


- getFish
{
   return self;
}

- (int) getMyCount
{
   return 1;
}

- (double) getFishCumulativeDistanceMoved
{
    return fishCumulativeDistanceMoved;
}

- (double) getTotalFoodCons;
{
    return totalFoodConsumptionThisStep;
}



- removeFish
{
   [model addToRemovedList: self];
   return self;
} 


- (void) drop
{

     [uniformDist drop];

     [destCellList drop];
     destCellList = nil; 

	 if(potentialSpawnCellList != nil) 
     {
      [potentialSpawnCellList drop];
     }

     if(causeOfDeath != nil)
     {
         [troutZone free: deathCausedBy];
         deathCausedBy = NULL;
     }

     [troutZone drop];
     troutZone = nil;

    [super drop];
     self = nil;

}

@end





