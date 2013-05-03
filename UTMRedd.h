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


#import "globals.h"
#import "HabitatSpace.h"
#import "FishCell.h"
#import "TimeManagerProtocol.h"
#import "SurvMGRProtocol.h"
#import "FishParams.h"
//#import "ZoneAllocMapper.h"

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

