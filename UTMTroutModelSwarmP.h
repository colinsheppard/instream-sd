/*
inSTREAM Version 5.0, February 2012.
Individual-based stream trout modeling software. 
Developed and maintained by Steve Railsback, Lang, Railsback & Associates, 
Steve@LangRailsback.com; Colin Sheppard, critter@stanfordalumni.org; and
Steve Jackson, Jackson Scientific Computing, McKinleyville, California.
Development sponsored by US Bureau of Reclamation, EPRI, USEPA, USFWS,
USDA Forest Service, and others.
Copyright (C) 2004-2012 Lang, Railsback & Associates.

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



#include <time.h>
#include <objectbase.h>

@protocol UTMTroutModelSwarm

- (time_t)getModelTime;
- addToEmptyReddList: aRedd;
- addAFish: aTrout;
- (id <List>) getLiveFishList;
- (BOOL) getAppendFiles;
- (int) getScenario;
- (int) getReplicate;
- (FILE *) getReddSummaryFilePtr;
- (FILE *) getReddReportFilePtr;


//- createANewFishFrom: aRedd;
- addToKilledList: aFish;
- (id <List>) getReddList;

- (int) getNumberOfSpecies;
- (id <Zone>) getModelZone;

- (id <Symbol>) getFishMortalitySymbolWithName: (char *) aName;
- (id <Symbol>) getReddMortalitySymbolWithName: (char *) aName;
- (id <Symbol>) getAgeSymbolForAge: (int) anAge;
//- (id <BinomialDist>) getReddBinomialDist;

- (int) getNumHoursSinceLastStep;

- switchColorRepFor: aHabitatSpace;

- (id <List>) getAgeSymbolList;
- (id <List>) getSpeciesSymbolList;

- createNewFishWithSpeciesIndex: (int) speciesNdx  
                        Species: (id <Symbol>) species
                            Age: (int) age
                         Length: (double) fishLength;
- (id <Symbol>) getSpeciesSymbolWithName: (char *) aName;
- (id <Symbol>) getReachSymbolWithName: (char *) aName;
- getReddBinomialDist;
- updateTkEventsFor: aReach;
- updateHabSurvProbs;
- (BOOL) getWriteFoodAvailabilityReport;
- (BOOL) getWriteDepthReport;
- (BOOL) getWriteVelocityReport;
- (BOOL) getWriteDepthVelocityReport;
- (BOOL) getWriteHabitatReport;
- (BOOL) getWriteMoveReport;
- (BOOL) getWriteReadyToSpawnReport;
- (BOOL) getWriteSpawnCellReport;
- (BOOL) getWriteReddSurvReport;
- (BOOL) getWriteCellFishReport;
- (BOOL) getWriteReddMortReport;
- (BOOL) getWriteIndividualFishReport;
- (BOOL) getWriteCellCentroidReport;
@end

@class UTMTroutModelSwarm;
