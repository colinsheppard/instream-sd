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

#import <objectbase.h>
#import <analysis.h>
#import <simtools/ObjectLoader.h>
#import <simtools.h>
#import "TroutModelSwarm.h"
#import "globals.h"

@interface UTMTroutBatchSwarm: Swarm
{
  char* modelSetupFile;

  BOOL finished;

  id <Schedule> batchSchedule;

  id <Activity> modelActivity;

  id outputSchedule;

  TroutModelSwarm *troutModelSwarm;	  	// the Swarm we're observing
  id <Zone> obsZone;



  //
  // These have no effect in the model run but utmRasterResolution*
  // are necessary in the utmCells. So read in the Observer.Setup 
  //
  int utmRasterSize;
  int utmRasterX;
  int utmRasterY;
  int rasterResolutionX;
  int rasterResolutionY;
  char* rasterColorVariable;
  int    rasterOutputFrequency;
  int    displayFrequency;				// one parameter: update freq
  char*  takeRasterPictures;

  char* tagFishColor;
  char* tagCellColor;
  char* dryCellColor;

  int maxShadeDepth;
  int maxShadeVelocity;


@public
  int modelNumber;

}

// Methods overriden to make the Swarm.

+ createBegin: aZone;
- createEnd;

- (id) getModel;

- objectSetup;
- buildObjects;
- buildActions;

- activateIn: swarmContext;
- checkToStop;
- (BOOL) areYouFinishedYet;
- setModelNumberTo: (int) anInt;
- iAmAlive;
- (void) drop;

- (id <Swarm>) getModelSwarm;

@end
