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



#import <simtools.h>

#import "TimeManagerProtocol.h"
#import "HabitatSetup.h"
#import "HabitatSpace.h"
#import "TroutModelSwarmP.h"
#import "globals.h"
#import "PolyInputData.h"

@interface HabitatManager: SwarmObject
{

id <TroutModelSwarm> model;
id <Zone> habManagerZone;
double siteLatitude;

int numHabitatSpaces;

int numberOfSpecies;
id <Map> fishParamsMap;

//
// Time variables
//
id <TimeManager> timeManager;
time_t modelTime;
char modelDate[12];
time_t runStartTime;
time_t runEndTime;
time_t dataStartTime;
time_t dataEndTime;



id <List> habitatSetupList;
id <List> habitatSpaceList;
id <ListIndex> habitatSpaceNdx;

char* rasterColorVariable;
int rasterResolutionX;
int rasterResolutionY;


//  
//  Poly CELLS
//  
int polyRasterResolutionX;
int polyRasterResolutionY;
char polyRasterColorVariable[35];
double shadeColorMax;

double habFracFlowChangeForMovement;
double habFracDriftChangeForMovement;

}


+ createBegin: aZone;
- createEnd;

- instantiateObjects;
- setModel: aModel;
- setTimeManager: (id <TimeManager>) aTimeManager;
- setModelStartTime: (time_t) aRunStartTime
         andEndTime: (time_t) aRunEndTime;

- setDataStartTime: (time_t) aDataStartTime
        andEndTime: (time_t) aDataEndTime;
		
- setFracFlowChangeForMovement: (double) aFraction;
- setFracDriftChangeForMovement: (double) aFraction;

- setSiteLatitude: (double) aLatitude;

- (int) getNumberOfHabitatSpaces;
- getHabitatSpaceList;
- getReachWithName: (char *) aReachName;

- readReachSetupFile: (char *) aReachSetupFile;


- setNumberOfSpecies: (int) aNumberOfSpecies;
- setFishParamsMap: (id <Map>) aMap;


-   setPolyRasterResolutionX: (int) aPolyRasterResolutionX
    setPolyRasterResolutionY: (int) aPolyRasterResolutionY
     setRasterColorVariable:  (char *) aRasterColorVariable
           setShadeColorMax:  (double) aShadeColorMax;

- updateHabitatManagerWithTime: (time_t) aTime
         andWithModelStartFlag: (BOOL) aStartFlag;

-  setShadeColorMax: (double) aShadeColorMax
     inHabitatSpace: aHabitatSpace;
- toggleCellsColorRepIn: aHabitatSpace;

- instantiateHabitatSpacesInZone: (id <Zone>) aZone;
- finishBuildingTheHabitatSpaces;
- buildHabSpaceCellFishInfoReporter;
- buildReachJunctions;

//
// UPDATE AQUATIC PREDATION AFTER LAST PISCIV FISH HAS MOVED
//
- updateAqPredProbs;

// 
// FILE OUTPUT
//
- outputCellFishInfoReport;


- printCellDepthReport;

- printCellVelocityReport;

- printHabitatReport;

- printCellAreaDepthVelocityRpt;

- (void) drop;

@end

