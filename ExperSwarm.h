//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 


#import <objc/objc-api.h>
#import <simtoolsgui/GUISwarm.h>
#import <objectbase/SwarmObject.h>
#import <objectbase.h>
#import <analysis.h>
#import <analysis/EZGraph.h>

#import "UTMTroutObserverSwarm.h"

// First, the interface for the ParameterManager

id <Symbol> NONE;

@interface ParameterManager: SwarmObject {

  id modelIterator;

  id <Zone> parameterZone;
  id <ProbeMap> paramProbeMap;

  id <List> managedClasses;
  id <List> instanceNames;
}

- initializeParameters;
- initializeModelFor: (id ) subSwarm
      andSwarmObject: (id ) aSwarmObject
    withInstanceName: (id <Symbol>) anInstanceName;
- (BOOL) canWeGoAgain;
//- printParameters: anOutFile;
- (id <List>) getManagedClasses;
- (id <List>) getInstanceNames;

@end




@interface ExperSwarm: GUISwarm
{
  int numExperimentsRun;

  id dynRunGroup;
  id testRunGroup;

  id experSchedule;
  id testSchedule;

  UTMTroutObserverSwarm* subSwarm;
  id <ActivityControl> subSwarmControl;

  id * modelSwarm;
  id <List> experClassList;
  id <ListIndex> experClassNdx;

  id <List> experInstanceNames;
  id <ListIndex> experInstanceNameNdx;

  ParameterManager *parameterManager;

  id <Activity> subswarmActivity;

  id <ProbeMap> modelProbeMap;

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
- updateTkEvents;


@end

@interface TestInput : SwarmObject
{
   //no vars

}

+ create: aZone;

- testInputWithDataType: (char *) varType
           andWithValue: (char *) varValue
       andWithParamName: (char *) varName;
        

@end



