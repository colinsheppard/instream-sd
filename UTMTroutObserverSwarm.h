//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 


// The TroutObserverSwarm is a swarm of objects set up to observe a
// Trouts model when the graphical interface is running. The most
// important object is the aTroutModelSwarm, but we also have
// graphical windows and data analysis and stuff.

#import <analysis.h> // EZGraph
#import <simtools/ObjectLoader.h>
#import <simtools.h>
#import <objectbase/Swarm.h>
#import "UTMTroutModelSwarm.h"
#import "globals.h"

@interface UTMTroutObserverSwarm: Swarm
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

//
//END VARIABLES INITIALIZED BY Observer.Setup
//

@protected 


  id displayActions;				// schedule data structs
  id displaySchedule;
  id outputSchedule;

  UTMTroutModelSwarm* troutModelSwarm;	  	// the Swarm we're observing
  char* modelSetupFile;                        // the default is Model.Setup
                                                // this variable can be set 
  id <Zone> obsZone;
  id <ProbeMap> obsProbeMap;

  id <EZGraph> mortalityGraph;

  //
  // UTM
  //
  int   rasterSize;
  int   rasterX;
  int   rasterY;
  int   rasterResolution;
  int   rasterResolutionX;
  int   rasterResolutionY;
  char* rasterColorVariable;
  int   rasterZoomFactor;

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

  int maxShadeDepth;
  int maxShadeVelocity;


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
- switchColorRep;
- redrawRaster;
- buildActions;

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
