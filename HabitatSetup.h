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



#import <objectbase/SwarmObject.h>
#import "PolyInputData.h"


@interface HabitatSetup: SwarmObject
{

  int habIndex;

  char reachName[50];
  id <Symbol> reachSymbol;
  int habDownStreamJunctionNumber;
  int habUpStreamJunctionNumber;
  
  double habReachLengthInCM;

  char habParamFile[50];

  char cellGeomFile[50];
  char hydraulicFile[50];
  char flowFile[50];
  char temperatureFile[50];
  char turbidityFile[50];
  char driftFoodFile[50];
  char cellHabVarsFile[50];

  id <List> listOfPolyInputData;

}

+ createBegin: aZone;
- createEnd;

- setHabitatIndex: (int) anIndex;

- setReachName: (char *) aReachName;
- setReachSymbol: (id <Symbol>) aReachSymbol;

- setHabDStreamJNumber: (int) aJunctionNum;
- setHabUStreamJNumber: (int) aJunctionNum;

- setReachLengthInM: (double) aReachLength;

- setHabParamFile: (char *) aHabParamFile;
- setCellGeomFile: (char *) aCellGeomFile;
- setHydraulicFile: (char *) aHydraulicFile;
- setFlowFile: (char *) aFlowFile;
- setTemperatureFile: (char *) aTemperatureFile;
- setTurbidityFile: (char *) aTemperatureFile;
- setDriftFoodFile: (char *) aDriftFoodFile;
- setCellHabVarsFile: (char *) aCellDataFile;


- (char *) getReachName;
- (id <Symbol>) getReachSymbol;

- (int) getHabDStreamJNumber;
- (int) getHabUStreamJNumber;

- (double) getReachLength;

- (char *) getHabParamFile;
- (char *) getCellGeomFile;
- (char *) getHydraulicFile;
- (char *) getFlowFile;
- (char *) getTemperatureFile;
- (char *) getTurbidityFile;
- (char *) getDriftFoodFile;
- (char *) getCellHabVarsFile;

- (id <List>) getListOfPolyInputData;

- (void) drop;
@end

