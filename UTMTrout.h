//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 



#import "FishParams.h"
#import "UTMHabitatSpace.h"
#import "FishCell.h"
#import "TimeManagerProtocol.h"
#import "SurvMGRProtocol.h"


//#define MOVE_REPORT_ON
//#define MOVE_DISTANCE_REPORT_ON
//#define SURVIVAL_REPORT_ON
//#define SPAWN_REPORT_ON seems to be superceded by SPAWN_CELL_RPT
//#define READY_TO_SPAWN_RPT
//#define SPAWN_CELL_RPT

//#define LOHICELLOUTPUT

#include "FeedStrategy.h"


@interface UTMTrout: SwarmObject
{

  id model;
  id habitatSpace;
  

  id <Symbol> species;
  int speciesNdx;

  FishParams* fishParams;

  id <List> destCellList;

  //
  // Generic Trout properties.
  //
  int   age;
  double fishLength;  // cm
  double fishWeight;  // grams
  double fishDominance;
  double fishCondition;
  double domValue;
  double searchParameter; // cm/hr
  double territorySize;   // cm2
  double shelterArea; //Doesn't mean that a fish has a shelter

  double prevWeight;
  double prevLength;
  double prevCondition;
  

  char * deadOrAlive;
  char * deathCausedBy;
  id <Symbol> causeOfDeath;
  int yearOfDeath;
  int dateOfDeath;

  int dateLastSpawned; 
  int yearLastSpawned;

  FishCell* fishCell;
  Color myColor;
  Color myOldColor;
  unsigned myRasterX, myRasterY;
  unsigned TransectNumber, CellNumber;



// ENERGETICS VARIABLES
// These are set in move

double driftFoodIntake;
double driftNetEnergy;
double searchFoodIntake;
double searchNetEnergy;
double standardResp;
double activeResp;
BOOL  velocityShelter;
BOOL  hidingCover;
double hourlyDriftConRate;
double hourlySearchConRate;
//
// New for TMII paper: iVar for total food consumed per time step.
//
double totalFoodConsumptionThisStep;

double reactiveDistance;
double captureArea;
double cMax;
double cMaxFT;

double starvPa;
double starvPb;

double depthLengthRatio;


//
// TIME HORIZON
//
time_t timeTAtEndOfSpawning;


//
//FEEDING STRATEGY
//
FeedStrategy fishFeedingStrategy;
FeedStrategy cellFeedingStrategy;

//
// FEEDING ACTIVITY
//
FishActivity fishActivity;
id <Symbol> fishActivitySymbol;
id <Symbol> hideSymbol;
id <Symbol> feedSymbol;


double cellSwimSpeed;      //set in calcNetEnergyForCell; used HiVelocity survival
double maxSwimSpeed;      //set in calcNetEnergyForCell; used HiVelocity survival
double fishSwimSpeed;      //used in probe display; the swim speed for our world
double expectedMaturity;
double expectedMaturityForBestCell;
double nonStarvSurvival;
double fishFracMature;
double netEnergyForBestCell;
double netEnergyIntake;
double netEnergyForCell; 

char *feedStrategy;
char *inShelter;
char *inHidingCover;

double maxMoveDistance;

double swimSpdVelocityRatio;

int numHoursSinceLastStep;
double numberOfDaylightHours;
double numberOfNightHours;

BOOL isHideCoverAvailable;

//
// memory variables
//
double netEnergyForFeedingLastPhase;
double netEnergyForHidingLastPhase;
double survivalForFeedingLastPhase;
double survivalForHidingLastPhase;

//
// temporary memory variables
//

double tempBestERMForFeed;
double tempBestERMForHide;

double tempNetEnergyIfFeed;
double tempNetEnergyIfHide;

double tempSurvivalIfFeed;
double tempSurvivalIfHide;


double hourlyNetEnergyIfFeed;
double hourlyNetEnergyIfHide;
double dailySurvivalIfFeed;
double dailySurvivalIfHide;

double dayFeedNightHideERM;
double dayFeedNightFeedERM;
double dayHideNightHideERM;
double dayHideNightFeedERM;

double dailyNonStarveSurvival;
double survivalDay;
double survivalNight;


//
// DayPhase is defined in HabitatSpace.h
//
DayPhase currentPhase;
DayPhase prevPhase;


//
// These values are the result of the ERM
// calculations
//
 
          
//
// TIME
//
id <TimeManager> timeManager;
time_t timeLastSpawned;

time_t timeOfDeath;


BOOL spawnedThisSeason;


//
// Piscivory
//
BOOL iAmPiscivorous;
id toggledFishForHabSurvUpdate;

// probe modifiable properties

@public
  id <Symbol> sex;
  double sensoryRadiusFactor; 

  id troutRandGen;
  id dieDist;
  id spawnDist;

  int rasterResolution;
  int rasterResolutionX;
  int rasterResolutionY;



//
// Variables added for the survival manager 4/6/01
//
  id <Map> probMap;
  id <UniformDoubleDist> uniformDist;
  
  unsigned int timesHooked;


//
// Variables added for the Move Distance Report
//
int scenario;
int replicate;


//
// Variables added for the breakout report
//
id <Symbol> ageSymbol;

double fishDistanceLastMoved;
double fishCumulativeDistanceMoved;

//
// Lists added for destination cells
//
id <List> goodDestCellList;
id <List> badDestCellList;


}

+ createBegin: aZone;
- createEnd;



//
// SET METHODS
//
- setModel: aModel;
- setFishParams: (FishParams *) aFishParams;
- (FishParams *) getFishParams;
- setRandGen: aRandGen;
- getRandGen;
- setScenario: (int) aScenario;
- setReplicate: (int) aReplicate;
- setTimeManager: (id <TimeManager>) aTimeManager;

- setWorld: (FishCell *) aCell;
- (FishCell *) getWorld;
- setFishCell: (FishCell *) aCell;
- setHabitatSpace: (UTMHabitatSpace *) aHabSpace;

- setSpeciesNdx: (int) anIndex;
- (int) getSpeciesNdx;
- (id <Symbol>) getSpecies;
- setSpecies: (id <Symbol>) aSymbol;

- setFishActivitySymbolsWith: (id <Symbol>) aHideSymbol
                        with: (id <Symbol>) aFeedSymbol;
- getFishActivitySymbol;
- (int) getFishActivity;
- (double) getIsFishFeeding;

- setStockedFishActivity: (id <Symbol>) aSymbol;


//
// This is used to set a fish's activity, 
// newly created from a redd, to FEED
//
- setNewFishActivityToFEED;


- setDepthLengthRatio: (double) aDouble;



- setAge: (int) anInt;
- (int) getAge;
//- incrementAge;
- dailyUpdateWithBirthday: (BOOL *) itsMyBirthday;


- setFishCondition: (double) aCondition;
- (double) getFishCondition;

- setFishWeightFromLength: (double) aLength andCondition: (double) aCondition;
- setFishLength: (double) aFloat;
- setFishDominance;
- (double) getFishDominance;

- (id <Symbol>) getCauseOfDeath;
- (time_t) getTimeOfDeath;

//
// added to implement the survival manager
//
- (BOOL) diedOf: (char *) aMortalitySource;

- setTimesHooked: (unsigned int) aNumberOfTimesHooked;
- (unsigned int) getTimesHooked;


- drawSelfOn: (id <Raster>) aRaster atX: (int) anX Y: (int) aY;
- setFishColor: (Color) aColor;
- tagFish;

- (double) getFishShelterArea;

- (double) getWorldDepth;
- (double) getWorldVelocity;

- (double) getWeightWithIntake: (double) anEnergyIntake;
- (double) getLengthForNewWeight: (double) aWeight;
- (double) getDominanceForLength: (double) aLength;
- (double) getFracMatureForLength: (double) aLength;

- (double) getConditionForWeight: (double) aWeight andLength: (double) aLength;

- (double) getTotalFoodCons;



//
// Modified for Green river
//
- (double) expectedMaturityAt: (FishCell *) aCell;

- (double) calcESWithNetEnergyDay: (double) aDayHourlyNetEnergy
                 andNetEnergyNight: (double) aNightHourlyNetEnergy
                    andSurvivalDay: (double) aSurvivalDay
                  andSurvivalNight: (double) aSurvivalNight
                          withCell: (FishCell *) aCell;
                  
                   


- (time_t) getCurrentTimeT;
- (DayPhase) getCurrentPhase;
- (double) getCellSwimSpeed;

- setTimeTLastSpawned: (time_t) aTimeT;
- (time_t) getTimeTLastSpawned;
- (BOOL) readyToSpawn;
- (FishCell *) findCellForNewRedd;
- createAReddInCell: (FishCell *) aCell;

- (double) getSpawnQuality: (FishCell *) aCell;
- (double) getSpawnDepthSuitFor: (double) aDepth;
- (double) getSpawnVelSuitFor: (double) aVel;

-(double) _interpYBetweenR: (double) r andS: (double) s basedOnX: (double) x
		 betweenP: (double) p andQ: (double) q;


//SCHEDULED ACTIVITIES
- spawn;
- move;
- grow;
- die;

- killFish;



- moveToMaximizeExpectedMaturity;
- moveTo: bestDest;





//SURVIVAL 
- (double) getNonStarvSPAt: (id) aCell
              withActivity: (FishActivity) aFishActivity;

- calcStarvPaAndPb;



- (double) getFishWeight;
- (double) getFishLength;


//
// Methods added for the survival manager
//
- (double) getDepthLengthRatio;
- (double) getSwimSpdVelocityRatio;
- (BOOL) getFishSpawnedThisTime;

- toggleFishForHabSurvUpdate;
- (double) getPiscivorousFishDensity; // Pass through to the cell


- (int) compare: (UTMTrout *) aFish; //needed for the QSort in TroutModelSwarm

//FISH FEEDING AND ENERGETICS METHODS

- updateNumHoursSinceLastStep: (int *) aNumHours;



// FOOD INTAKE: DRIFT FEEDING STRATEGY

- (double) calcReactDistance: (FishCell *) aCell;
- (double) calcCaptureArea: (FishCell *) aCell;
- (double) calcDriftIntake: (FishCell *) aCell;


//FOOD INTAKE: ACTIVE FEEDING STRATEGY

- updateMaxSwimSpeed;
- (double) getMaxSwimSpeed;
- (double) calcSearchIntakeAt: (FishCell *) aCell;


//FOOD INTAKE: MAXIMUM CONSUMPTION

//- (double) calcCmax: (double) aTemperature;
- calcCmax;
- (double) calcCmaxTempFunction: (double) aTemperature;


// FOOD INTAKE: FOOD AVAILABILITY



//RESPIRATION COSTS

//- (double) calcStandardRespiration: (FishCell *) aCell;
- calcStandardRespiration;
- (double) calcActivityRespirationAt: (FishCell *) aCell withSwimSpeed: (double) aSpeed;
- (double) calcTotalRespirationAt: (FishCell *) aCell withSwimSpeed: (double) aSpeed; 


// FEEDING STRATEGY SELECTION, NET ENERGY BENEFITS, AND GROWTH

- (double) calcDriftNetEnergyAt: (FishCell *) aCell;
- (BOOL) getIsShelterAvailable: (FishCell *) aCell;
- (BOOL) getAmIInAShelter;
- (BOOL) getAmIInHidingCover;
- (double) getFishHidingCoverArea;



- (double) calcSearchNetEnergyAt: (FishCell *) aCell; 

//
// Modified from original for Green river
//
- (double) calcNetEnergyAt: (FishCell *) aCell
             withActivity: (FishActivity) aFishActivity;
                      
- (double) calcFeedingNetEnergyForCell: (FishCell *) aCell;

- (double) calcSearchFoodIntakeAt: (FishCell *) aCell;
- (double) calcDriftFoodIntakeAt: (FishCell *) aCell;

- (double) getHourlyDriftConRate;
- (double) getHourlySearchConRate;
- (int) getFishFeedingStrategy;

- (double) getSwimSpeedAt: (FishCell *) aCell forStrategy: (int) aFeedStrategy;


- calcMaxMoveDistance;




//REPORTS
#ifdef MOVE_REPORT_ON
- moveReport: (FishCell *)  aCell;
#endif

#ifdef MOVE_DISTANCE_REPORT_ON
- moveDistanceReport: (FishCell *)  aCell;
#endif

#ifdef SURVIVAL_REPORT_ON
- printSurvivalReport;
#endif
#ifdef SPAWN_REPORT_ON
- printSpawnReport: aCell;
#endif

#ifdef READY_TO_SPAWN_RPT
- printReadyToSpawnRpt: (BOOL) readyToSpawn;
#endif

#ifdef SPAWN_CELL_RPT
- printSpawnCellRpt: (id <List>) spawnCellList;
#endif



// Called from the model Swarm
- printInfo: (FILE *) fpmReportPtr;

//
// Methods for the break out report
//
- setAgeSymbol: (id <Symbol>) anAgeSymbol;
- (id <Symbol>) getAgeSymbol;
- getFish;
- (int) getMyCount;
- (double) getFishCumulativeDistanceMoved;


- removeFish;
- (void) drop;

@end



