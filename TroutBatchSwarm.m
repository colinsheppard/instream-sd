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

#import <collections.h>
#import <objectbase.h>
#import <gui.h>

#import "TroutBatchSwarm.h"


@implementation TroutBatchSwarm

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
  TroutBatchSwarm* obj;

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
  fprintf(stdout, "TroutBatchSwarm >>>> objectSetup >>>> BEGIN\n");
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

  fprintf(stdout, "TroutBatchSwarm >>>> objectSetup >>>> END\n");
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
