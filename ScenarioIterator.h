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
#import <string.h>
#import <stdlib.h>
#import "ZoneAllocMapper.h"

#import "SearchElement.h"

@interface ScenarioIterator : SearchElement 
{

  id <Zone> scenarioIterZone;

  char *oldParameter;
  Class parameterClass;

  id <Index> experParamNdx;

  int numScenarios;
  int numReplicates;

  int scenarioCount;
  int replicateCount;

  int classCount;

  int numProbes;

  id <Map> iterMap;

  id <List> updateScenarioClassList;
  id <ListIndex> scenarioNdx;
  id <List> updateReplicateClassList;
  id <ListIndex> replicateNdx;

  id <VarProbe> aProbe;

  id <List> classList;
  id <List> instanceNameList;
  id <Map> paramClassInstanceNameMap;

}

+ createBegin: aZone;

- createEnd;

- nextFileSetOnObject: (id) theObject;

- (BOOL) canWeGoAgain;
 
- nextControlSetOnObject: (id) theObject
        withInstanceName: (id <Symbol>) anInstanceName;

-  appendToIterSetParam: (const char *) newParam
          withParamType: (char) aParamType 
                ofClass: (Class) paramClass
       withInstanceName: (id <Symbol>) anInstanceName
             paramValue: (void *) paramValue;



- setNumScenarios: (int) aNumScenarios;
- setNumReplicates: (int) aNumReplicates;

- checkParameters;
- (int) getIteration;


- sendScenarioCountToParam: (const char *) newParam
                   inClass: (Class) paramClass;

- sendReplicateCountToParam: (const char *) newParam
                    inClass: (Class) paramClass;

- updateClassScenarioCounts: (id) inObject;
- updateClassReplicateCounts: (id) inObject;

- calcStep;
@end
