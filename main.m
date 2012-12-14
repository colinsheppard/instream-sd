//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 


#import <simtools.h>     // initSwarm () and swarmGUIMode
#import <simtoolsgui.h>  // GUISwarm
#import "ExperSwarm.h"
#import "ExperBatchSwarm.h"

// The main() function is the top-level place where everything starts.
// For a typical Swarm simulation, in main() you create a toplevel
// Swarm, let it build and activate, and set it to running.

int
main (int argc, const char **argv)
{
  id theTopLevelSwarm = nil;
  id batchSwarm = nil;

  id experSwarm = nil;


  // Swarm initialization: all Swarm apps must call this first.
  initSwarm (argc, argv);

  // swarmGUIMode is set in initSwarm(). It's set to be 1 if you
  // typed trout -batchmode. Otherwise, it's set to 0.
  
  if (swarmGUIMode == 1)
    {
      // We've got graphics, so make a full ObserverSwarm to get GUI objects
      experSwarm = [ExperSwarm createBegin: globalZone];
      SET_WINDOW_GEOMETRY_RECORD_NAME (experSwarm);
      experSwarm = [experSwarm createEnd];
      [experSwarm buildObjects];
      [experSwarm buildActions];
      [experSwarm activateIn: nil];
      [experSwarm go];
    }
  else {
       fprintf(stdout, "Main >>>> In Batchmode\n");
       fflush(stdout);
      batchSwarm = [ExperBatchSwarm createBegin: globalZone];
      batchSwarm = [batchSwarm createEnd];
      [batchSwarm buildObjects];
      [batchSwarm buildActions];
      [batchSwarm activateIn: nil];
      [batchSwarm go];
  }

  //
  // Old code
  //

  if(0)
  {
      if (swarmGUIMode == 1)
        {
          // We've got graphics, so make a full ObserverSwarm to get GUI objects
          theTopLevelSwarm = [ExperSwarm createBegin: globalZone];
          SET_WINDOW_GEOMETRY_RECORD_NAME (theTopLevelSwarm);
          theTopLevelSwarm = [theTopLevelSwarm createEnd];
          [theTopLevelSwarm buildObjects];
          [theTopLevelSwarm buildActions];
          [theTopLevelSwarm activateIn: nil];
          [theTopLevelSwarm go];
        }
      else {
          (void) fprintf(stderr, "In Batchmode \n");
           fflush(stderr);
          batchSwarm = [ExperBatchSwarm createBegin: globalZone];
          batchSwarm = [batchSwarm createEnd];
          [batchSwarm buildObjects];
          [batchSwarm buildActions];
          [batchSwarm activateIn: nil];
          [batchSwarm go];
      }
  }

  //
  // theTopLevelSwarm has finished processing, so it's time to quit.
  //
  return 0;
}
