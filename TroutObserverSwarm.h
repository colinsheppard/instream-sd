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


// The TroutObserverSwarm is a swarm of objects set up to observe a
// Trouts model when the graphical interface is running. The most
// important object is the aTroutModelSwarm, but we also have
// graphical windows and data analysis and stuff.

#import <analysis.h> // EZGraph
#import <simtools/ObjectLoader.h>
#import <simtools.h>
#import <objectbase/Swarm.h>
#import "TroutModelSwarm.h"
#import "globals.h"

@interface TroutObserverSwarm: Swarm
{
  id <ProbeMap> probeMap;
  BOOL finished;

  id <ProbeMap> habitatProbeMap;

  id <Activity> myActivity;
  id <Activity> modelActivity;

  id experSwarm;

@public
  //
  //THE FOLLOWING VARIABLES ARE INITIALIZED BY Observer.Setup
  //
  int    rasterOutputFrequency;
  int    displayFrequency;				// one parameter: update freq
  char*  takeRasterPictures;
  int   rasterResolutionX;
  int   rasterResolutionY;
  char* rasterColorVariable;

//
//END VARIABLES INITIALIZED BY Observer.Setup
//

@protected 


  id displayActions;				// schedule data structs
  id displaySchedule;
  id outputSchedule;

  TroutModelSwarm* troutModelSwarm;	  	// the Swarm we're observing
  char* modelSetupFile;                        // the default is Model.Setup
                                                // this variable can be set 
  id <Zone> obsZone;
  id <ProbeMap> obsProbeMap;

  //
  // UTM
  //
  int   rasterSize;
  int   rasterX;
  int   rasterY;
  
  char toggleColorVariable[10];

  id <Colormap> utmColormap;			// allocate colours
  id <Colormap> depthColormap;
  id <Colormap> velocityColormap;
  id <Symbol> Depth;
  id <Symbol> Velocity;
  id <Symbol> currentRepresentation;
  id <Map> utmColorMaps;

  id <ZoomRaster> utmWorldRaster;		// 2d display widget
  id <Object2dDisplay> polyCellDisplay;	        // display the trout

  char* tagFishColor;
  char* tagCellColor;

  int maxShadeDepth;
  int maxShadeVelocity;

// From instream 5.0
  id <List> habCellDisplayList;       // display the trout
  id <Map> habitatRasterMap;
  id <List> habitatRasterList;	       // 2d display widgets
  id <Map> habColormapMap;
  id <Map> habCellDisplayMap;
  int polyRasterX;
  int polyRasterY;
  double shadeColorMax;
  id <EZBin> populationHisto;
  id <EZBin> velocityHisto;
  id <EZBin> depthHisto;
  

  id <EZGraph> mortAgeClassGraph;
  id <EZBin> mortAgeClassHist;
  id <EZGraph> mortalityGraph;


@public
  int modelNumber;
}

+ create: aZone;

- setExperSwarm: anExperSwarm;
- (id) getModel;

- buildProbesIn: aZone;
- buildFishProbes;

- objectSetup;
- buildObjects;
- switchColorRepFor: aHabitatSpace;
- redrawRasterFor: aHabitatSpace;
- buildActions;
- updateTkEventsFor: aHabitatSpace;

- activateIn: swarmContext;
- _update_;
- checkToStop;
- (BOOL) areYouFinishedYet;
- setModelNumberTo: (int) anInt;
- (void) writeFrame;
- iAmAlive;
- (id <ZoomRaster>) getWorldRaster;
- (id <Swarm>) getModelSwarm;
- (void) drop;


@end
