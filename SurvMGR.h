//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 


#import <objectbase/SwarmObject.h>
#import <defobj.h>
#import <string.h>
#import <math.h>
#import <time.h>

#import "ZoneAllocMapper.h"
#import "SingleFuncProb.h"
#import "LimitingFunctionProb.h"
#import "SurvMGRProtocol.h"


#ifndef NO
#define NO 0
#endif

#ifndef YES
#define YES 1
#endif


//
// Each habitat object (world, cell, etc...)
// creates a survival manager instance 
//


@interface SurvMGR : SwarmObject <SurvMGR, CREATABLE>
{

//
// Which of these variables should be private?
//

id <Zone> mgrZone;

id <Symbol> ANIMAL;
id <Symbol> HABITAT;



//
// myCurrentAnimal will change depending
// on which animal requests its probabities
//
id myCurrentAnimal;


//
// myHabitatObject is set during the create
// phase an does not change during the 
// lifetime of the survMGR instance.
//
id myHabitatObject;

id starvSurvivalProb;
id <List> listOfSurvProbs;
id <ListIndex> survProbLstNdx;
int numberOfProbs;

id <List> listOfKnownNonStarvSurvProbs;
id <ListIndex> knownNonStarvSurvProbLstNdx;


//
// These lists contain references to
// the functions owned by the various 
// probability objects. The habitat update
// funcs are updated by the survival manager
// when the habitat object is updated and the 
// animal update funcs are updated when 
// the animal (agent) objects request
// the probabilities from their habitat object
// e.g., the animals world.
//
id <List> listOfHabitatUpdateFuncs;
id <List> listOfAnimalUpdateFuncs;

//
// 
//
BOOL testOutput;
FILE* testOutputFilePtr;
char* outputString;
char** formatString;

}


+         createBegin: aZone
   withHabitatObject: anObj;
    

- createEnd;
- setMyHabitatObject: anObj;

- setTestOutputOnWithFileName: (char *) aFileName;

- (id <Symbol>) getANIMALSYMBOL;
- (id <Symbol>) getHABITATSYMBOL;

- (int) getNumberOfProbs;
- getHabitatObject;
- getCurrentAnimal;

- addPROBWithSymbol: (id <Symbol>) aProbSymbol
          withType: (char *) aProbType
    withAgentKnows: (BOOL) anAgentKnows
   withIsStarvProb: (BOOL) isAStarvProb;

- addBoolSwitchFuncToProbWithSymbol: (id <Symbol>) aProbSymbol
          withInputObjectType: (id <Symbol>) objType
               withInputSelector: (SEL) aSelector
                  withYesValue: (double) aYesValue   //FIX
                   withNoValue: (double) aNoValue;


- addLogisticFuncToProbWithSymbol: (id <Symbol>) aProbSymbol
         withInputObjectType: (id <Symbol>) objType
              withInputSelector: (SEL) aSelector
                  withXValue1: (double) xValue1
                  withYValue1: (double) yValue1
                  withXValue2: (double) xValue2
                  withYValue2: (double) yValue2;

- setLogisticFuncLimiterTo: (double) aLimiter;

- addConstantFuncToProbWithSymbol: (id <Symbol>) aProbSymbol
                   withValue: (double) aValue;


- addCustomFuncToProbWithSymbol: (id <Symbol>) aProbSymbol
                  withClassName: (char *) className
            withInputObjectType: (id <Symbol>) objType
              withInputSelector: (SEL) aObjSelector;

//
// The survival manager knows its habitat object
//
- updateForHabitat;
- updateForAnimal: anAnimal;

- (id <List>) getListOfSurvProbsFor: anAnimal;

- (double) getTotalSurvivalProbFor: anAnimal;
- (double) getTotalKnownNonStarvSurvivalProbFor: anAnimal;

- (double) getStarvSurvivalFor: anAnimal;

- createHeaderAndFormatStrings;

- writeSurvOutputWithAnimal: anAnimal;

- (void) drop;
@end
