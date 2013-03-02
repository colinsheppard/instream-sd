//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 


/*
 * HabitatSpace consists of a collection of Cells of a regular
 * discrete space.  The Cells can either cover all the points
 * in the underlying space or some subset of those points.  And 
 * each HabitatSpace will consist of a give type of cell.  Each
 * Cell has its center at the point (vector) it 
 * contains.  Indexing into the Cells is done in a regular
 * way through a discrete lattice.  So, if the set of Cells
 * does not fully cover the underlying space, the HabitatSpace will not
 * account for the uncovered points.
 */

#import <random.h>
#import <space.h>
#import <space/Discrete2d.h>
#import <math.h>
#import "ZoneAllocMapper.h"
#import "globals.h"
#import "TimeManagerProtocol.h"
#import "TimeSeriesInputManagerP.h"
#import "UTMInterpolatorFactory.h"
#import "UTMInputData.h"
#import "FishCell.h"

//#define HABITAT_REPORT_ON
//#define VELOCITY_REPORT_ON
//#define DEPTH_REPORT_ON
//#define DEPTH_VEL_RPT
//#define CELL_FISH_INFO

#import "DayPhaseTypes.h"

//enum DayPhaseType { DNERROR = -2, INITPHASE = -1, NIGHT = 0, DAY = 1};

//typedef enum DayPhaseType DayPhase;

@interface UTMHabitatSpace : Discrete2d 
{

  id modelSwarm;
  id <Zone> habitatZone;
  id randGen;

  //
  //THE FOLLOWING VARIABLES ARE INITIALIZED BY habParamFile in the model swarm
  //See instantiateObjects in the model swarm 
  //

  double habSearchProd;
  double habDriftConc;
  double habDriftRegenDist;
  double habLatitude;
  double habPreyEnergyDensity;
  double habFracFlowChangeForMovement;
  double habTwilightLength;

  int habAnglePressJan;
  int habAnglePressFeb;
  int habAnglePressMar;
  int habAnglePressApr;
  int habAnglePressMay;
  int habAnglePressJun;
  int habAnglePressJul;
  int habAnglePressAug;
  int habAnglePressSep;
  int habAnglePressOct;
  int habAnglePressNov;
  int habAnglePressDec;

  double habAngleNightFactor;

@protected

  id <Symbol> DemonicIntrusion;


//
// PRED DENSITY
// needed by AQUATIC SURV PROB
//
  double wettedArea;
  int numPiscivorousFish;
  double piscivorousFishDensity; 
  //
  // TIME
  // 
  id <TimeManager> timeManager;
  time_t modelTime;
  time_t timeStepSize;
  time_t modelStartTime;
  time_t modelEndTime;
  double dayLength;
  char* Date;
  int hour;

  double daytimeStartHour;
  time_t daytimeStartTime;
  
  double daytimeEndHour;
  time_t daytimeEndTime;

  time_t prevTime; //use in getHabitatStateForMoveWith: 


  //
  // REPORT VARIABLES
  //
  BOOL habitatReportFirstWrite;
  BOOL depthReportFirstWrite;
  BOOL velocityReportFirstWrite;
  BOOL depthVelRptFirstTime;     //also used in the cell depth reporting

  //  
  // CELL REPORT VARIABLES
  // 
  BOOL foodReportFirstTime;



  //
  // New Vars for Green River
  //
  double numberOfDaylightHours;
  double numberOfNightHours;

  double flowAtLastMove;
  BOOL flowChangeForMove;
  double meanDailyLogFlow;

  double reachLength; 

  double currentHourlyFlow;

  double changeInDailyFlow;


  double dailyMeanFlow;
  double prevDailyMeanFlow;
  double dailyMeanLogFlow;

  double dailyMaxFlow;
  double nextDailyMaxFlow;
  double prevDailyMaxFlow;
 

  double temperature;
  double turbidity;
 

  DayPhase currentPhase;
  DayPhase phaseOfPrevStep;
  BOOL dayNightPhaseSwitch;

  int anglingPressure;

  //
  // New Survival Manager variables
  //
  int numberOfSpecies;

  //
  // Cell fish info file pointer
  //
  FILE * cellFishInfoFilePtr;


  //
  // UTM
  //


  char reachName[50];
  char utmCellGeomFile[50];
  //char utmFlowFile[50];
  char* utmFlowFile;
  char* utmTemperatureFile;
  char* utmTurbidityFile;
  char* utmCellHabVarsFile;
  //char driftFoodFile[50];
  char* driftFoodFile;
  id <List> listOfUTMInputData;

  int spaceDimX, spaceDimY;

  double minUTMNorthing;
  double maxUTMNorthing;
  double minUTMEasting;
  double maxUTMEasting;

  int maxUTMCellNumber;
  int maxNode;
  double** nodeUTMXArray;
  double** nodeUTMYArray;
  id <List> utmCellList;
  id <ListIndex> utmCellListNdx;

  unsigned int utmSpaceSizeX;
  unsigned int utmSpaceSizeY;

  unsigned int utmPixelsX;
  unsigned int utmPixelsY;

  int utmRasterResolution;
  int utmRasterResolutionX;
  int utmRasterResolutionY;
  char utmRasterColorVariable[35];
  double shadeColorMax;

  UTMInterpolatorFactory* utmInterpolatorFactory; 

  time_t dataStartTime;
  time_t dataEndTime;

  id <TimeSeriesInputManager> flowInputManager;
  id <TimeSeriesInputManager> temperatureInputManager;
  id <TimeSeriesInputManager> turbidityInputManager;
  id <TimeSeriesInputManager> driftFoodInputManager;

  id <Map> fishParamsMap;
}
+ createBegin: aZone;
- createEnd;

- buildObjects;

- (char *) getReachName;

//
// SET METHODS
//
- setModelSwarm: aModelSwarm;
- getModel;
- setTimeStepSize: (time_t) aTimeStepSize;
- setTimeManager: (id <TimeManager>) aTimeManager;
- setRandGen: aRandGen;
- getRandGen;


- createDemonicIntrusionSymbol;
- (id <Symbol>) getDemonicIntrusionSymbol;


- setNumberOfSpecies: (int) aNumberOfSpecies;


- (time_t) getModelTime;

- setStartTime: (time_t) startTime  // added 3/20/2000
    andEndTime: (time_t) endTime;


- setFishParamsMap: aMap;

// 
// UPDATE
// 
- (BOOL) getFlowChangeForMove;
- (BOOL) shouldFishMoveAt: (time_t) theCurrentTime;
- updateMeanCellDepthAndVelocity: (double) aMeanFlow;
- updateHabitat: (time_t) aModelTime_t;
- updateHabSurvProbForAqPred;
- updateAnglePressureWith: (time_t) aTime;
- updateFishCells;

- (double) getChangeInDailyFlow;
- (double) getCurrentHourlyFlow;
- (double) getReachLength;
- (double) getDailyMeanFlow;
- (double) getPrevDailyMeanFlow;
- (double) getPrevDailyMaxFlow;
- (double) getDailyMaxFlow;
- (double) getNextDailyMaxFlow;
- (double) getTemperature;
- (double) getTurbidity;

- calcDayLength: (time_t) aTime_t;

- (double) getNumberOfDaylightHours;
- (double) getNumberOfNightHours;
- (double) getDaytimeStartHour;
- (time_t) getDaytimeStartTime;
- (double) getDaytimeEndHour;
- (time_t) getDaytimeEndTime;


- (int) getCurrentPhase;
- (int) getPhaseOfPrevStep;
- (BOOL) getDayNightPhaseSwitch;

- (BOOL) getIsItDaytime;


- (double) getHabSearchProd;
- (double) getHabDriftConc;
- (double) getHabDriftRegenDist;
- (double) getHabPreyEnergyDensity;

- (double) getAnglingPressure;
- (double) getHabAngleNightFactor;


#ifdef DEPTH_REPORT_ON
- printCellDepthReport;
#endif

#ifdef VELOCITY_REPORT_ON
- printCellVelocityReport;
#endif

#ifdef HABITAT_REPORT_ON
- printHabitatReport;
#endif

#ifdef DEPTH_VEL_RPT
- printCellAreaDepthVelocityRpt;
#endif

- (BOOL) getFoodReportFirstTime;
- setFoodReportFirstTime: (BOOL) aBool;
- (BOOL) getDepthVelRptFirstTime;
- setDepthVelRptFirstTime: (BOOL) aBool;

//
//  PRED DENSITY
//
- resetNumPiscivorousFish;
- incrementNumPiscivorousFish;
- (double) calcPiscivorousFishDensity;
- (double) getPiscivorousFishDensity;


//
// HISTOGRAM
//
/*
- setAreaDepthBinWidth: (int) aWidth;
- setDepthHistoMaxDepth: (float) aDepth;
- setAreaVelocityBinWidth: (int) aWidth;
- setVelocityHistoMaxVelocity: (float) aVelocity;

- setAreaDepthHistoFmtStr: (char *) aFmtStr;
- setAreaVelocityHistoFmtStr: (char *) aFmtStr;

- openAreaDepthFile: (char *) aFileName;
- openAreaVelocityFile: (char *) aFileName;

- printAreaDepthHisto;
- printAreaVelocityHisto;
*/

- printCellFishInfo;


// 
//  UTM
// 
-    setUTMRasterResolution: (int) aUTMRasterResolution
    setUTMRasterResolutionX: (int) aUTMRasterResolutionX
    setUTMRasterResolutionY: (int) aUTMRasterResolutionY
     setRasterColorVariable: (char *) aRasterColorVariable
           setShadeColorMax: (double) aShadeColorMax;

- setShadeColorMax: (double) aShadeColorMax;

- readUTMHabSetupFile: (char *) aFileName;
- buildUTMCells;
- readUTMCellGeometry;
- createUTMCells;
- createUTMCellCoordStructures;
- createUTMCellPixels;
- calcUTMCellCentroid;
- createUTMAdjacentCells;
- readUTMDataFiles;
- readUTMCellDataFile;
- createUTMInterpolationTables;
- outputCellCentroidRpt;
- outputCellCorners;
- setDataStartTime: (time_t) aDataStartTime
    andDataEndTime: (time_t) aDataEndTime;
- createTimeSeriesInputManagers;

- (id <List>) getUTMCellList;
- (unsigned int) getUTMPixelsX;
- (unsigned int) getUTMPixelsY;

- (int) getSpaceDimX;
- (int) getSpaceDimY;


- probeUTMCellAtX: (int) probedX Y: (int) probedY;
- getUTMCellAtX: (int) anX
              Y: (int) aY;

- probeFishAtX: (int) probedX Y: (int) probedY;

- (id <List>) getNeighborsWithin: (double) aRange 
                              of: refCell 
                        withList: (id <List>) aCellList;

- tagCellNumber: (int) aCellNumber;
- untagCellNumber: (int) aCellNumber;
- untagAllCells;
- switchColorRep;
- updateCells;
- redrawRaster;

- writeDepthsAndVelsToFile: (char *) aDepthVelsFile;

//
// CLEANUP
//
- (void) drop;

@end


