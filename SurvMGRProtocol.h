//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 

@protocol SurvMGR  <CREATABLE>


// CREATING


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

@protocol SurvProb  <CREATABLE>

- (const char *) getName;
- (id <Symbol>) getProbSymbol;
- (BOOL) getIsStarvProb;
- (BOOL) getAnAgentKnows;
- (double) getSurvivalProb;

@end

@class SurvMGR;
@class SurvProb;
