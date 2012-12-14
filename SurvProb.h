//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 


#import <objectbase/SwarmObject.h>

#import "SurvMGRProtocol.h"

#import "BooleanSwitchFunc.h"
#import "LogisticFunc.h"
#import "ConstantFunc.h"


@interface SurvProb : SwarmObject <SurvProb, CREATABLE>
{


@protected

id <Zone> probZone;

id survMgr;


char *probName;
id <Symbol> probSymbol;

unsigned isStarvProb;
unsigned anAgentKnows;

id <List> funcList;
id <ListIndex> funcListNdx;

}

+ createBegin: aZone;
- createEnd;

- setSurvMgr: aSurvMgr;



- setProbSymbol: (id <Symbol>) aNameSymbol;
- setIsStarvProb: (BOOL) aBool;
- setAnAgentKnows: (BOOL) aBool;

- (const char *) getName;
- (id <Symbol>) getProbSymbol;

- (BOOL) getIsStarvProb;
- (BOOL) getAnAgentKnows;

- (id <List>) getFuncList;

- (double) getSurvivalProb;

- createLogisticFuncWithInputMethod: (SEL) inputMethod
                withInputObjectType: (id <Symbol>) anObjType
                         andXValue1: (double) xValue1
                         andYValue1: (double) yValue1
                         andXValue2: (double) xValue2
                         andYValue2: (double) yValue2;



- createConstantFuncWithValue: (double) aValue;

- createBoolSwitchFuncWithInputMethod: (SEL) anInputMethod
                         withYesValue: (double) aYesValue
                         withNoValue: (double) aNoValue;



- createCustomFuncWithClassName: (char *) className
              withInputSelector: (SEL) anInputSelector
            withInputObjectType: (id <Symbol>) objType;



- (void) drop;
@end
