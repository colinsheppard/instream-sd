//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 





#import <objectbase/SwarmObject.h>
#import <gui.h>
#import <random.h>

#import <math.h>
#import <stdlib.h>

#import "TimeManagerProtocol.h"

#import "UTMCell.h"

@interface FishCell : UTMCell
{
  id space;  // space of which Im a member
  id modelSwarm;
  id <TimeManager> timeManager;
  id randGen;
  int numberOfSpecies;
  int numberOfFish;
  id <List> fishList;
  id <List> reddList;
  id <Map> fishParamsMap;
  id <Map> survMgrMap; 
  id <Map> survMgrReddMap; 
  id <Symbol> ANIMAL;
  id <Symbol> HABITAT;
  BOOL cellDataSet;

  double cellFracSpawn;
  double cellFracShelter;
  double cellShelterArea;
  double shelterAreaAvailable;
  double availableHidingCover;
  BOOL   isShelterAvailable;
  double cellDistToHide;
  double fracHidingCover;
  double driftHourlyCellTotal;
  double searchHourlyCellTotal;
  double hourlyAvailDriftFood;
  double hourlyAvailSearchFood;


  double meanDepth;
  double meanVelocity;

  double shadeColorMax;
  

}

+ create: aZone;
- setSpace: aSpace;
- getSpace;
- setModelSwarm: aModelSwarm;
- setTimeManager: aTimeManager;
- setNumberOfSpecies: (int) aNumber;
- setFishParamsMap: aMap;
- setRandGen: aRandGen;
- getRandGen;
- addFish: aFish;
- removeFish: aFish;
- (id <List>) getFishList;


- getNeighborsWithin: (double) aRange 
            withList: (id <List>) aCellList;

- (id <List>) getListOfAdjacentCells;

- (double) getDistanceTo: aCell;

//SHELTER AREA
- (void) setCellFracShelter: (double) aDouble;
- (void) calcCellShelterArea;
- (BOOL) getIsShelterAvailable;

- setDistanceToHide: (double) aDistance;
- (double) getDistanceToHide;


- calcDailyMeanDepthAndVelocityFor: (double) aMeanFlow;
- (BOOL) isDryAtDailyMeanFlow;

- setCellDataSet: (BOOL) aBool;
- checkCellDataSet;

- initializeSurvProb;

- updateHabitatSurvivalProb; 
- updateReddHabitatSurvProb;
- updateHabSurvProbForAqPred;
- updateFishSurvivalProbFor: aFish;
- updateReddSurvivalProbFor: aRedd;
- (id <List>) getListOfSurvProbsFor: aFish;
- (id <List>) getReddListOfSurvProbsFor: aRedd;
- (double) getTotalKnownNonStarvSurvivalProbFor: aFish;
- (double) getStarvSurvivalFor: aFish;
- (double) getAnglingPressure;
- (int) getCurrentPhase;
- (double) getUTMCellTemperature;
- (double) getUTMCellTurbidity;
- (double) getCurrentHourlyFlow;
- (double) getChangeInDailyFlow; 
- (double) getPiscivorousFishDensity;
- (double) getReachLength;
- (double) getHabAngleNightFactor;

- (void) resetShelterAreaAvailable;
- (double) getShelterAreaAvailable;
- resetHidingCover;
- (BOOL) getIsHidingCoverAvailable;
- (double) getHidingCoverAvailable;
- setCellFracSpawn: (double) aFloat;
- (double) getCellFracSpawn;
- setFracHidingCover: (double) aFracHidingCover;
- moveHere: aFish;
- addRedd: aRedd;
- removeRedd: aRedd;
- (id <List>) getReddList;
- (double) getHabSearchProd;
- (double) getHabDriftConc;
- (double) getHabDriftRegenDist;
- (double) getHabPreyEnergyDensity;
- (int) getPhaseOfPrevStep;
- (BOOL) getDayNightPhaseSwitch;
- (double) getNumberOfDaylightHours;
- (double) getNumberOfNightHours;
-  calcDriftHourlyTotal;
- calcSearchHourlyTotal;
- (double) getHourlyAvailDriftFood;
- (double) getHourlyAvailSearchFood;
- (double) getDailyMeanFlow;
- (double) getPrevDailyMeanFlow;
- (double) getPrevDailyMaxFlow;
- (double) getDailyMaxFlow;
- (double) getNextDailyMaxFlow;
- (void) updateDSCellHourlyTotal;
- (void) resetAvailHourlyTotal;
- (BOOL) getIsItDaytime;
- printCellFishInfo: (void *) filePtr;
- setShadeColorMax: (double) aShadeColorMax;
- tagUTMCell;
- unTagUTMCell;
- untagAllCells;
- toggleColorRep: (double) aShadeColorMax;
- drawSelfOn: (id <Raster>) aRaster;
- depthVelReport: (FILE *) depthVelPtr;
- (void) drop;

@end






