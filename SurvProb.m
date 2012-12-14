//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 



#import "SurvProb.h"

@implementation SurvProb 


+ createBegin: aZone
{

  SurvProb* aProb = [super createBegin: aZone];

  aProb->probZone = [Zone create: aZone];

  aProb->isStarvProb = 3;

  aProb->anAgentKnows = 3;

  aProb->funcList = [List create: aProb->probZone];
  aProb->funcListNdx = nil;


  return aProb;

}


- createEnd
{

   if(isStarvProb == 3)
   {
      [InternalError raiseEvent: "ERROR: SurvProb >>>> isStarvProb has not been set\n"];
   }

   if(anAgentKnows == 3)
   {
      [InternalError raiseEvent: "ERROR: SurvProb >>>> anAgentKnows has not been set\n"];
   }

   if(funcListNdx == nil)
   {
       funcListNdx = [funcList listBegin: [self getZone]];
   }


   return [super createEnd];

}


- setProbSymbol: (id <Symbol>) aNameSymbol
{

  probSymbol = aNameSymbol;

  probName = (char *) [probSymbol getName];

  return self;

}


- setIsStarvProb: (BOOL) aBool
{

  isStarvProb = (unsigned) aBool;

  return self;

}


- setAnAgentKnows: (BOOL) aBool
{

  anAgentKnows = (unsigned) aBool;

 return self;

}



- setSurvMgr: aSurvMgr
{

  survMgr = aSurvMgr;

  return self;

}




- (const char *) getName
{

   //fprintf(stdout, "SurvProb >>>> getName >>>> probName = %s\n", probName);
   //fflush(0);

   return probName;
}



- (id <Symbol>) getProbSymbol
{
  return probSymbol;
}


- (BOOL) getIsStarvProb
{
   return (BOOL) isStarvProb;
}


- (BOOL) getAnAgentKnows
{
   return (BOOL) anAgentKnows;
}

- (id <List>) getFuncList
{
    return funcList;
}


- (double) getSurvivalProb
{

  [self subclassResponsibility: M(getSurvivalProb)];

  return -1.0;

}




- createLogisticFuncWithInputMethod: (SEL) inputMethod
                withInputObjectType: (id <Symbol>) anObjType
                         andXValue1: (double) xValue1
                         andYValue1: (double) yValue1
                         andXValue2: (double) xValue2
                         andYValue2: (double) yValue2
{

      id aFunc;

      if(inputMethod == (SEL) nil)
      {
          [InternalError raiseEvent: "ERROR: SurvProb >>>> createLogisticFuncWithInputMethod inputMethod was not set\n"];
      }


      aFunc =  [LogisticFunc createBegin: probZone 
                         withInputMethod: inputMethod
		              usingIndep: xValue1
		                     dep: yValue1
                                   indep: xValue2
                                     dep: yValue2];

      aFunc = [aFunc createEnd];
      [funcList addLast: aFunc];

      return aFunc;

}



- createConstantFuncWithValue: (double) aValue
{

  id aFunc;

  aFunc = [ConstantFunc create: probZone
                     withValue: aValue];

  [funcList addLast: aFunc];

  return aFunc;

}





- createBoolSwitchFuncWithInputMethod: (SEL) anInputMethod
                         withYesValue: (double) aYesValue
                          withNoValue: (double) aNoValue
{

  id aFunc;

  if(anInputMethod == (SEL) nil)
  {
     [InternalError raiseEvent: "ERROR: SurvProb >>>> createBooleanSwitchFuncWithInputMethod inputMethod was not set\n"];
  }

  aFunc = [BooleanSwitchFunc   create: probZone
                      withInputMethod: anInputMethod 
                         withYesValue: aYesValue
                          withNoValue: aNoValue];


  [funcList addLast: aFunc];

  return aFunc;

}

- createCustomFuncWithClassName: (char *) className
              withInputSelector: (SEL) anInputSelector
            withInputObjectType: (id <Symbol>) objType
{
   //
   // SurvProb knows nothing about the custom function
   // at compile time. This gets resolved at runtime...
   //
   Class CustomFunc = Nil;
   id aFunc = nil;

   CustomFunc = [objc_get_class(className) class];

   //fprintf(stdout, "SurvProb >>>> createCustomFuncWithClassName >>>> className = %s\n", className);
   //fprintf(stdout, "SurvProb >>>> createCustomFuncWithClassName >>>> class = %p\n", CustomFunc);
   //fflush(0);

   
   aFunc = [CustomFunc createBegin: [self getZone]
                    setInputMethod: anInputSelector];


   //fprintf(stdout, "SurvProb >>>> createCustomFuncWithClassName >>>> aFunc = %p\n", aFunc);
   //fflush(0);
  
  [funcList addLast: aFunc];

  return aFunc;

}

- (void) drop
{
    [scratchZone free: probName];
    [funcList deleteAll];
    [super drop];
}


@end
