//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 


#import <objc/objc-api.h>
#import <objectbase.h>
#import <simtools.h>
#import <analysis.h>
#import <activity.h>
#import <collections.h>
#import "UTMTroutBatchSwarm.h"

// First, the interface for the ParameterManager

id <Symbol> NONE;

@interface ParameterBatchManager: Swarm 
{

  id modelIterator;
  id <Zone> parameterZone;
  id <List> managedClasses;
  id <List> instanceNames;
}

- initializeParameters;
- initializeModelFor: (id ) subSwarm
      andSwarmObject: (id ) aSwarmObject
    withInstanceName: (id <Symbol>) anInstanceName;
- (BOOL) canWeGoAgain;
- (id <List>) getManagedClasses;
- (id <List>) getInstanceNames;


@end


@interface ExperBatchSwarm: Swarm
{
  int numExperimentsRun;

  id experSchedule;
  id testSchedule;

  UTMTroutBatchSwarm* subSwarm;

  id * modelSwarm;
  id <List> experClassList;
  id <ListIndex> experClassNdx;

  id <List> experInstanceNames;
  id <ListIndex> experInstanceNameNdx;

  ParameterBatchManager *parameterManager;

  id <Activity> subswarmActivity;

  id <Zone> experZone;

}

+ createBegin: aZone;
- createEnd;
- setupModel;
- buildModel;
- runModel;
- dropModel;
- checkToStop;

- buildObjects;
- buildActions;
- activateIn: swarmContext;

- go;


@end



@interface BatchTestInput : SwarmObject
{
   //no vars
}

+ create: aZone;

- testInputWithDataType: (char *) varType
           andWithValue: (char *) varValue
       andWithParamName: (char *) varName;
        

- (void) drop;

@end



