//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 


#import "globals.h"
#import "HabitatSpace.h"
#import "FishCell.h"
#import "TimeManagerProtocol.h"
#import "SurvMGRProtocol.h"
#import "FishParams.h"
#import "ZoneAllocMapper.h"

@interface UTMRedd: SwarmObject
{
  id reddZone;
  id model;
  FishParams* fishParams;

  id <Symbol> species;
  char speciesName[35];
  int speciesNdx;

  id <TimeManager> timeManager;
  time_t createTime;

  //
  // generic Redd properties.
  //

  int superimpCount;

  int    numberOfEggs;
  int    initialNumberOfEggs;
  int    numEggsToEmerge;    // Number of eggs to turn into new fish today
  int    emergeDays;         // number of days since fully developed

  double  fracDeveloped;   // range [0-1] - used to determine emergence of new fish
  double  spawnerLength;      // cm
  
  int numberOfEggsLostToDewatering;
  int numberOfEggsLostToScouring;
  int numberOfEggsLostToLowTemp;
  int numberOfEggsLostToHiTemp;
  int numberOfEggsLostToSuperimp;

  id <NormalDist> reddNormalDist;
  id <BinomialDist> reddBinomialDist;
  

  FishCell* myCell;
  int cellNumber;
  Color myColor;
  unsigned myRasterX, myRasterY;


  id <List> printList;
  id <List> survPrintList;

  char* summaryString;

  BOOL printSummaryFlag;
  BOOL printMortalityFlag;

}


+ createBegin: aZone;
- createEnd;

- setTimeManager: (id <TimeManager>) aTimeManager;
- setReddBinomialDist: (id <BinomialDist>) aBinomialDist;
- setModel: aModel;
- setFishParams: (FishParams *) aFishParams;
- (FishParams *) getFishParams;
- setCell: (FishCell *) aCell;
- (FishCell *)getCell;



- drawSelfOn: (id <Raster>) aRaster;

- setReddColor: (Color) aColor;
- (Color) getReddColor;

- setCreateTimeT: (time_t) aCreateTime;
- (time_t) getCreateTimeT;
- (time_t) getCurrentTimeT;


- setSpecies: (id <Symbol>) aSymbol;
- (id <Symbol>) getSpecies;
- (int) getSpeciesNdx;
- setNumberOfEggs: (int) anInt;
- setSpawnerLength: (double) aDouble;
- (double) getSpawnerLength;
- setPercentDeveloped: (double) aPercent;

//
// BASIC REDD DAILY ROUTINES
//
- survive;
- develop;
- emerge;
- removeWhenEmpty;
- turnMyselfIntoAFish;

// Report Methods

- setPrintSummaryFlagToYes;
- setPrintMortalityFlagToYes;

- printReport;
- createPrintString: (int) eggsLostToDewatering
                   : (int) eggsLostToScouring
                   : (int) eggsLostToLowTemp
                   : (int) eggsLostToHiTemp
                   : (int) eggsLostToSuperimp
                   : (time_t) aModelTime_t;

				   - createSurvPrintStringWithDewaterSF: (double) aDewaterSF
                         withScourSF: (double) aScourSF
                        withLoTempSF: (double) aLoTempSF
                        withHiTempSF: (double) aHiTempSF
                      withSuperimpSF: (double) aSuperimpSF;

//
// The following are broken wrt the changes
// in the survival manager...
//
- printReddSurvReport: (FILE *) printRptPtr;
//- createSurvPrintString: (double) reddLoTempSF;
- createSurvPrintString;
//
//

// for instream 5.0
- setRasterX: (unsigned) anX;
- setRasterY: (unsigned) aY;

- createReddSummaryStr;
- printReddSummary;

- (double) getADouble;

- (void) drop;
@end

