//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 

#import <collections.h>
#import <objectbase.h>
#import <gui.h>

#import "UTMTroutBatchSwarm.h"


@implementation UTMTroutBatchSwarm

//////////////////////////////////////////////
//
// createBegin
//
//////////////////////////////////////////
+ createBegin: aZone
{
  return [super createBegin: aZone];
}


////////////////////////////////////////////////////////////
//
// createEnd
//
//////////////////////////////////////////////////////
- createEnd
{
  UTMTroutBatchSwarm* obj;

  obj = [super createEnd];

  obj->finished=NO;

  return obj;
}



/////////////////////////////////////////////////////////////////
//
// getModel
//
//////////////////////////////////////////////////////////////
- getModel 
{
  return troutModelSwarm;
}


///////////////////////////////////////
//
// objectSetup
//
//////////////////////////////////////
- objectSetup 
{
  fprintf(stdout, "UTMTroutBatchSwarm >>>> objectSetup >>>> BEGIN\n");
  fflush(0);

  obsZone = [Zone create: [self getZone]];
  troutModelSwarm = [TroutModelSwarm create: obsZone];

  [troutModelSwarm setPolyRasterResolutionX:  rasterResolutionX
                   setPolyRasterResolutionY:  rasterResolutionY 
                 setPolyRasterColorVariable:  rasterColorVariable];

  //fprintf(stdout,"modelSetupFile = %s \n", modelSetupFile);
  //fflush(stdout);


  if(modelSetupFile != NULL)
  {
     [ObjectLoader load: troutModelSwarm fromFileNamed: modelSetupFile];
  }
  else 
  {
     [ObjectLoader load: troutModelSwarm fromFileNamed: "Model.Setup"];
  }

  [troutModelSwarm instantiateObjects];

  fprintf(stdout, "UTMTroutBatchSwarm >>>> objectSetup >>>> END\n");
  fflush(0);
  return self;
}




- buildObjects
 {
  [super buildObjects];

  [troutModelSwarm buildObjectsWith: nil
                            andWith: 1.0]; 

  return self;
}  


- buildActions 
{
  [super buildActions];
  [troutModelSwarm buildActions];

  batchSchedule = [Schedule createBegin: obsZone];
  [batchSchedule setRepeatInterval: 1];
  batchSchedule = [batchSchedule createEnd];
  [batchSchedule at: 0 createActionTo: self message: M(checkToStop)];
  
  return self;

}  

- activateIn:  swarmContext 
{
  [super activateIn: swarmContext];
  modelActivity = [troutModelSwarm activateIn: self];
  [batchSchedule activateIn: self];
  return [self getActivity];
}

- checkToStop 
{
  if([troutModelSwarm whenToStop] == YES)
  {

    finished = YES;
   
    modelActivity = nil;

    [[self getActivity] stop];
 
    fprintf(stdout,"\nStop date achieved\n");
    fflush(0);
  }

  return self;
}



- (BOOL) areYouFinishedYet 
{
  return finished;
}

- setModelNumberTo: (int) anInt 
{
  modelNumber = anInt;
  return self;
}


- iAmAlive 
{
  static int iveBeenCalled=0;
  iveBeenCalled++;
  fprintf(stdout, "TroutBatchSwarm is alive. (%d)\n", iveBeenCalled); 
  fflush(0);
  return self;
}

- (void) drop 
{
  fprintf(stdout,"TroutBatchSwarm >>>> drop >>>> BEGIN\n");
  fflush(0);



  if(troutModelSwarm != nil) 
  {
      [troutModelSwarm drop];
      troutModelSwarm = nil;
  }

  fprintf(stdout,"TroutBatchSwarm >>>> drop >>>> after troutModelSwarm drop\n");
  fflush(0);

  if(obsZone != nil) 
  {
      [obsZone drop];
      obsZone = nil;
  }

  [super drop];

  fprintf(stdout,"TroutBatchSwarm >>>> drop >>>> BEGIN\n");
  fflush(0);
}

- (id <Swarm>) getModelSwarm 
{
     return troutModelSwarm;
}

@end
