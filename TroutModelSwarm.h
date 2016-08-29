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

#import <objectbase/Swarm.h>
#import <analysis/Averager.h>

#import "TroutModelSwarmP.h"
#import "globals.h"
#import "Rainbow.h"
#import "Brown.h"
#import "UTMRedd.h"
#import "HabitatManager.h"
#import "FishParams.h"
#import "TimeManagerProtocol.h"
//#import "ZoneAllocMapper.h"
#import "GraphDataObject.h"
#import "YearShufflerP.h"
#import "BreakoutReporter.h"
#import "LogisticFunc.h"
#import "TroutMortalityCount.h"

//#define INIT_FISH_REPORT
//#define REDD_REPORT            // If Commented out will lose 
                               // main redd output file

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


@interface TroutModelSwarm: Swarm<TroutModelSwarm>
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
  FILE * lftOutputFilePtr;
  FILE * individualFishFilePtr;


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
const char*  individualFishFile;
char*  popInitDate;
int    fileOutputFrequency;
double fracFlowChangeForMovement;
double fracDriftChangeForMovement;
char* tagFishColor;

// Set by Limiting Factors Tool 
int	    resultsAgeThreshold;
char*	    resultsCensusDay;

//
//END VARIABLES INITIALIZED BY Model.Setup
//

  //// NEW VARIABLES CONTROLLED BY OR USED BY LIMITING FACTOR TOOL
  double lftNumAdultTrout;	  // Total number of all adult trout with age >= resultsAgeThreshold, summed across every resultsCensusDay
  double lftBiomassAdultTrout;	  // Total weight of all adult trout with age >= resultsAgeThreshold, summed across every resultsCensusDay
  int lftNumCensusDays;		  // Number of census days, used to calculate average of the above to metrics 

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
BOOL isFirstStepOfDay;  // Added to write output only once per day
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
id <Map> captureLogisticMap; //One for each species

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

id <Symbol> Age0;
id <Symbol> Age1;
id <Symbol> Age2;
id <Symbol> Age3Plus;
 
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
  int simHourCounter;
  time_t popInitTime;
  id <List> fishInitializationRecords;
  id <List> listOfMortalityCounts;
  id <ListIndex> mortalityCountLstNdx;
}

// Stuff from instream 5.0
- buildFishClass;
- (Trout *) createNewFishWithSpeciesIndex: (int) speciesNdx  
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
- createCaptureLogistics;

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

- updateLFTOutput;
- writeLFTOutput;

- (BOOL) getWriteIndividualFishReport;

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



- addAFish: (Trout *) aTrout;
- (id <List>) getLiveFishList;
- (id <List>) getDeadTroutList;
- removeKilledFishFromLiveFishList;


- addToKilledList: (Trout *) aFish;
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

// Commented out; obsolete
//-           printZone:(id <Zone>) aZone 
//       withPrintLevel: (int) level;

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

- (Trout *) createNewFishWithFishParams: (FishParams *) aFishParams  
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

- printReddSurvReport;

- openIndividualFishReportFilePtr;
- printIndividualFishReport;


- dropFishMortObjs;


- createBreakoutReporters;
- outputBreakoutReport;

- setShadeColorMax: (double) aShadeColorMax inHabitatSpace: aHabitatSpace;
- switchColorRepFor: aHabitatSpace;
- redrawRaster;

- (void) drop;

@end

