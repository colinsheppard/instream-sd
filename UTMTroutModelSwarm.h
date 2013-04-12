//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 

#import <objectbase/Swarm.h>
#import <analysis/Averager.h>

#import "UTMTroutModelSwarmP.h"
#import "globals.h"
#import "Rainbow.h"
#import "Brown.h"
#import "UTMRedd.h"
#import "HabitatManager.h"
#import "FishParams.h"
#import "TimeManagerProtocol.h"
#import "ZoneAllocMapper.h"
#import "GraphDataObject.h"
#import "YearShufflerP.h"
#import "BreakoutReporter.h"
#import "LogisticFunc.h"
#import "TroutMortalityCount.h"

//#define INIT_FISH_REPORT
//#define REDD_REPORT            // If Commented out will lose 
                               // main redd output file
//
// The following is broken wrt the changes
// in the survival manager ...
//#define REDD_SURV_REPORT

struct SpeciesSetupStruct {
                              Class troutClass;
                              id <Symbol> speciesSymbol;
                              int speciesIndex;
                              char fishParamFile[50];
                              FishParams* fishParams;
                              char initPopFile[50];
                              char fishColor[25];
                              char stocking[50];
                          };

typedef struct SpeciesSetupStruct SpeciesSetup;

struct FishSetupStruct
       {
           int speciesNdx;
           id <Symbol> mySpecies;
           char date[11];
           time_t initTime;
           int age;
           int number;
           double meanLength;
           double stdDevLength;
           char reach[35];
        };

typedef struct FishSetupStruct TroutInitializationRecord; 

/*struct InitialFishRecordStruct {*/
/*Class troutClass;*/
/*id <Symbol> speciesSymbol;*/
/*int speciesIndex;*/
/*FishParams* fishParams;*/
/*char initDate[12];*/
/*time_t initTime;*/
/*int age; */
/*int numberOfFish;*/
/*double meanLength;*/
/*double stdDevLength; */
/*char reach[35];*/
/*};*/

/*typedef struct InitialFishRecordStruct InitialFishRecord;*/


struct FishStockType {
                           Class troutClass;
                           FishParams* fishParams;
                           time_t fishStockTime;
	                   id <Symbol> speciesSymbol;
                           int speciesNdx;
                           
                           int age;
                           int numberOfFishThisAge;
                           double meanLength;
                           double stdDevLength;
			   char reach[35];
                       };

typedef struct FishStockType FishStockStruct;


@interface UTMTroutModelSwarm: Swarm<UTMTroutModelSwarm>
{
  id <List> speciesClassList;

  int scenario;
  int replicate;

  // Optional Output Flags
  BOOL  writeFoodAvailabilityReport;
  BOOL  writeDepthReport;
  BOOL  writeVelocityReport;
  BOOL  writeDepthVelocityReport;
  BOOL  writeHabitatReport;
  BOOL  writeMoveReport;
  BOOL  writeReadyToSpawnReport;
  BOOL  writeSpawnCellReport;
  BOOL  writeReddSurvReport;
  BOOL  writeCellFishReport;
  BOOL  writeReddMortReport;
  BOOL  writeIndividualFishReport;
  BOOL  writeCellCentroidReport;

@public
  //int rasterResolution;
  //int rasterResolutionX;
  //int rasterResolutionY;
  //char * rasterColorVariable;

@protected
  id <Zone> modelZone;
  id observerSwarm;

  id modelActions;
  id modelSchedule;
  id coinFlip;

  // 
  // FILE OUTPUT
  //
  id <Averager> age0AveLength;
  id <Averager> age1AveLength;
  id <Averager> age2AveLength;
  id <Averager> age3PAveLength;

  FILE* fishMortalityPtr;

  FILE* reddRptFilePtr;
  FILE* reddSummaryFilePtr;


//Mortality counts
  id <Map> deathMap;
  int numberDead;

//
//THE FOLLOWING VARIABLES ARE INITIALIZED BY Model.Setup
//
int    randGenSeed;
int    numberOfSpecies;
char*  habParamFile;

int    runStartYear;
int    runStartDay;
char*  runStartDate;
char*  runEndDate;
char*  fishOutputFile;
char*  fishMortalityFile;
char*  reddOutputFile;
char*  reddMortalityFile;
char*  popInitDate;
int    fileOutputFrequency;
char*  habSetupFile;

//
// HISTOGRAM VARIABLES
//
int depthBinWidth;
int velocityBinWidth;

double depthHistoMaxDepth;
double velocityHistoMaxVelocity;

char* depthAvailabilityFileName;
char* velocityAvailabilityFileName;

char* areaDepthHistoFmtStr;
char* areaVelocityHistoFmtStr;

char* fishDepthUseFileName;
char* fishVelocityUseFileName;


char* tagFishColor;

//
//END VARIABLES INITIALIZED BY Model.Setup
//

//
// MORE HISTOGRAM VARIABLES
//
id <Map> speciesDepthUseOutStreamMap;
id <Map> speciesVelocityUseOutStreamMap;

id fishColorMap;
double shadeColorMax;

id <List> speciesSymbolList;  // List of symbols corresp to species studied
  

/*
 * model parameters -- we don't necessarily need get or set methods
 * for these because we're handling setup from a file.
*/

int numFish;          // number of live trout at any given time
int numAge3PlusFish;  // total of all age3Plus fish
                      // calculated in processAgeClassLists
                      // added for the cuthroat WARNING:
                      // this has *not* been tested for muliple species
double minSpeciesMinPiscLength; 
id fishForHabSurvUpdate;
  
id <List> speciesSetupList;
  

id <TimeManager> timeManager; // manages all the internal time conversions
                                // date in mm/dd/yyyy format
time_t modelTime;  // time_t as measured at noon
char*  modelDate;     // mm/dd/yyyy format
time_t runStartTime;
time_t runEndTime;
int numHoursSinceLastStep;
BOOL isFirstStep;

BOOL firstTime;

BOOL appendFiles;

id <Map> reproLogisticFuncMap;

id mortalityGraph;

// Fish Stocking
time_t nextFishStockTime;
id <List> fishStockList;

//
// FishParameters
//
id <Map> fishParamsMap; //One for each species

//
// Variables added for the breakout reports
//
id <List> liveFish;
id <List> killedFish;
id <List> deadFish;
BreakoutReporter* liveFishReporter;
BreakoutReporter* fishMortalityReporter;
BreakoutReporter* moveFishReporter;
id <List> ageSymbolList;
id <List> fishActivitySymbolList;
id <List> reachSymbolList;


id <List> reddList;
id <List> emptyReddList;
id <List> removedRedds;
id <List> killedRedds;
id <List> deadRedds;


//
// Vars added for the survival manager
//
id <List> fishMortSymbolList;
id <List> reddMortSymbolList;


//
// UTM
//
int utmRasterResolution;
int utmRasterResolutionX;
int utmRasterResolutionY;
char utmRasterColorVariable[35];
time_t dataStartTime;
time_t dataEndTime;

  HabitatManager* habitatManager;

//
// Experiment manager
//
double checkParam;

id <SolarManager> solarManager;

// Stuff from instream 5.0
  int fishCounter;
  int    polyRasterResolutionX;
  int    polyRasterResolutionY;
  char   polyRasterColorVariable[35];
  BOOL initialDay;
  int numberOfReaches;
  double siteLatitude;
  id <List> reachList;
  id <Map> cmaxInterpolatorMap; //One for each species
  id <Map> spawnDepthInterpolatorMap; //One for each species
  id <Map> spawnVelocityInterpolatorMap; //One for each species
  id <BinomialDist> reddBinomialDist;
  char **speciesPopFile;
  double ***speciesPopTable;
  char **speciesParameter;
  BOOL shuffleYears;
  BOOL shuffleYearReplace;
  int shuffleYearSeed;
  id <YearShuffler> yearShuffler;
  char dataEndDate[12];
  int startDay;
  int startMonth;
  int startYear;
  int endDay;
  int endMonth;
  int endYear;
  int numSimDays;
  int simCounter;
  time_t popInitTime;
  id <List> fishInitializationRecords;
  id <List> listOfMortalityCounts;
  id <ListIndex> mortalityCountLstNdx;
}

// Stuff from instream 5.0
- buildFishClass;
- (UTMTrout *) createNewFishWithSpeciesIndex: (int) speciesNdx  
                                  Species: (id <Symbol>) species
                                      Age: (int) age
                                   Length: (double) fishLength;
-   setPolyRasterResolutionX:  (int) aRasterResolutionX
    setPolyRasterResolutionY:  (int) aRasterResolutionY
    setPolyRasterColorVariable:  (char *) aRasterColorVariable;
- updateTkEventsFor: aReach;
- (id <BinomialDist>) getReddBinomialDist;
- (id <Symbol>) getSpeciesSymbolWithName: (char *) aName;
- (id <List>) getSpeciesSymbolList;
- (id <List>) getAgeSymbolList;
- (id <List>) getSpeciesClassList;
- (int) getNumberOfSpecies;
- createYearShuffler;
- readFishInitializationFiles;
- createCMaxInterpolators;
- createSpawnDepthInterpolators;
- createSpawnVelocityInterpolators;
- (HabitatManager *) getHabitatManager;
- toggleCellsColorRepIn: aHabitatSpace;
- (id <List>) getListOfMortalityCounts;
- updateMortalityCountWith: aDeadFish;



+ create: aZone;

- setObserverSwarm: anObserverSwarm;

- instantiateObjects;

- buildObjectsWith: theColormaps
          andWith: (double) aShadeColorMax;

-    setUTMRasterResolutionX:  (int) aUTMRasterResolutionX
    setUTMRasterResolutionY:  (int) aUTMRasterResolutionY
  setUTMRasterColorVariable:  (char *) aUTMRasterColorVariable;

- setMortalityGraph: (id) aGraph;

- activateIn: swarmContext;

- createInitialFish;
- createFishParameters;
- findMinSpeciesPiscLength;

//
// REPRO LOGISTIC
//
- createReproLogistics;
- updateReproFuncs;
- (double) getReproFuncFor: aFish 
                withLength: (double) aLength;

- buildActions;


//
// FISH STOCKING
//
- readFishStockingRecords;
- stock;






//
// GET METHODS
//
- getRandGen;
- (id <Zone>) getModelZone;

- addRedd: (UTMRedd *) aRedd;
- (id <List>) getReddList;
- (id <List>) getReddRemovedList;
- processEmptyReddList;

- (int) getNumberDead;


//- (int) getCountOfAge2PlusFish;
//- (int) getCountOfAge3PlusFish;



- addAFish: (UTMTrout *) aTrout;
- (id <List>) getLiveFishList;
- (id <List>) getDeadTroutList;
- removeKilledFishFromLiveFishList;


- addToKilledList: (UTMTrout *) aFish;
- addToEmptyReddList: aRedd;
- processEmptyReddList;

- (BOOL) getAppendFiles;
- (int) getScenario;
- (int) getReplicate;


#if (DEBUG_LEVEL > 0)
- iAmAlive: (const char *) string;
#endif


//
// DATE TIME HANDLING/RELATED  METHODS
//

- (time_t) getModelTime;
- (char *) getModelDate;
- (int) getModelHour;


//
// ACTIONS
//
- step;

-           printZone:(id <Zone>) aZone 
       withPrintLevel: (int) level;

- toggleFishForHabSurvUpdate;

- (int) getNumHoursSinceLastStep;

- createGraphSeq: (id <Symbol>) causeOfDeath;
- updateCauseOfDeath;
- updateFish;
- (id <Symbol>) getAgeSymbolForAge: (int) anAge;
- (id <Symbol>) getFishMortalitySymbolWithName: (char *) aName;
- (id <Symbol>) getReddMortalitySymbolWithName: (char *) aName;
- (id <Symbol>) getReachSymbolWithName: (char *) aName;

- (BOOL) whenToStop;


//- getCountOfTotPopList;

- (UTMTrout *) createNewFishWithFishParams: (FishParams *) aFishParams  
                         withTroutClass: (Class) aTroutClass
                                    Age: (int) age
                                 Length: (float) fishLength;

- setFishColormap: theColormaps;
- readSpeciesSetupFile;

- (id <List>) getSpeciesClassList;
- (int) getNumberOfSpecies;


#ifdef INIT_FISH_REPORT
- printInitialFishReport;
#endif

#ifdef REDD_REPORT
- printReddReport;
#endif

#ifdef REDD_SURV_REPORT
- printReddSurvReport;
#endif

- openReddReportFilePtr;
- (FILE *) getReddReportFilePtr;

- openReddSummaryFilePtr;
- (FILE *) getReddSummaryFilePtr;




- dropFishMortObjs;


//
// HISTOGRAM METHODS
//
//- printTroutDepthUseHisto;
//- printTroutVelocityUseHisto;
- openTroutDepthUseFiles;
- openTroutVelocityUseFiles;

- printTroutUseHeaderToStream: (FILE *) aStream 
                      withUse: (char *) aUse;



- createBreakoutReporters;
- outputBreakoutReport;

- setShadeColorMax: (double) aShadeColorMax inHabitatSpace: aHabitatSpace;
- switchColorRepFor: aHabitatSpace;
- redrawRaster;

- (void) drop;

@end

