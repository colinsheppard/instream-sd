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

#import "BreakoutReporter.h"

#import "LogisticFunc.h"

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


struct InitialFishRecordStruct {
                                  Class troutClass;
                                  id <Symbol> speciesSymbol;
                                  int speciesIndex;
                                  FishParams* fishParams;
                                  char initDate[12];
                                  time_t initTime;
                                  int age; 
                                  int numberOfFish;
                                  double meanLength;
                                  double stdDevLength; 
                               };

typedef struct InitialFishRecordStruct InitialFishRecord;


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
                       };

typedef struct FishStockType FishStockStruct;


@interface UTMTroutModelSwarm: Swarm<UTMTroutModelSwarm>
{
  id <List> speciesClassList;

  int scenario;
  int replicate;

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
  

HabitatSpace* habitatSpace;        // discrete2d of Partitions

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
id <List> initialFishRecordList;
  

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
BreakoutReporter* deadFishReporter;
BreakoutReporter* moveFishReporter;
id <List> ageSymbolList;
id <List> fishActivitySymbolList;


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

// Stuff from instream 5.0
  int    polyRasterResolutionX;
  int    polyRasterResolutionY;
  char   polyRasterColorVariable[35];
  BOOL initialDay;
  int numberOfReaches;
  id <List> reachList;
}

+ create: aZone;

- setObserverSwarm: anObserverSwarm;

- instantiateObjects;

- buildObjectsWith: theColormaps
          andWith: (double) aShadeColorMax;

-    setUTMRasterResolution:  (int) aUTMRasterResolution
    setUTMRasterResolutionX:  (int) aUTMRasterResolutionX
    setUTMRasterResolutionY:  (int) aUTMRasterResolutionY
  setUTMRasterColorVariable:  (char *) aUTMRasterColorVariable;

- setMortalityGraph: (id) aGraph;

- activateIn: swarmContext;

- createInitialFish;
- readPopFiles;
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



- (HabitatSpace *) getHabitatSpace;

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
- (int) getCurrentPhase;




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



- buildBreakoutReporters;
- outputBreakoutReport;

- setShadeColorMax: (double) aShadeColorMax;
- switchColorRep;
- updateCells;
- redrawRaster;

- (void) drop;

@end

