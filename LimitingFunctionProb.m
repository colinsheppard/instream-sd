//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 



#import "LimitingFunctionProb.h"

@implementation LimitingFunctionProb 


+ createBegin: aZone
{

  LimitingFunctionProb* aProb;

  aProb = [super createBegin: aZone];

  return aProb;

}


- createEnd
{
   if([funcList getCount] < 2)
   {
      [InternalError raiseEvent: "ERROR: LimitingFunctionProb >>>> probName = %s getSurvivalProb funcList has less than 2 members\n", probName];
   }

   minProbFunc = [funcList getFirst];

   return [super createEnd];
}


- setMinSurvProb: (double) aMinSurvProb
{

    minSurvProb = aMinSurvProb;
 
    return self;

}



- (id <List>) getMultiFunctionList
{
   return funcList;
}



- (double) getSurvivalProb
{

   double survProb=1.0;
   double survIncreaseFactor=-LARGEINT;
   double maxP = -LARGEINT;

   id probFunc = nil;

   //xprint(minProbFunc);

   minSurvProb = [minProbFunc getFuncValue];

   if((minSurvProb < 0.0) || (minSurvProb > 1.0))
   {
       [InternalError raiseEvent: "ERROR: LimitingFunctionProb >>>> minSurvProb in %s is not between zero and one. Value is: %f\n", probName, minSurvProb];
   }

   //xprint(funcListNdx);

   if(funcListNdx == nil)
   {
       [InternalError raiseEvent: "ERROR: LimitingFunctionProb >>>> funcListNdx is nil\n"];
   }
      
   [funcListNdx setLoc: Start];

   while(([funcListNdx getLoc] != End) && ((probFunc = [funcListNdx next]) != nil))
   {

     if(minProbFunc == probFunc) continue;

     survIncreaseFactor = [probFunc getFuncValue];
 
     if((survIncreaseFactor < 0.0) || (survIncreaseFactor > 1.0))
     {
         [InternalError raiseEvent: "ERROR: LimitingFunctionProb >>>> survIncreaseFactor is not between zero and one. Value is: %f\n", survIncreaseFactor];
     }
   
     if(survIncreaseFactor > maxP)
     {
          maxP = survIncreaseFactor;
     }

   }

   survProb = minSurvProb +
              ((1.0 - minSurvProb) * maxP);

   //if((survProb < 0.0) || (survProb > 1.0))
   //{
      //[InternalError raiseEvent: "ERROR: LimitingFunctionProb >>>> probName = %s >>>> survProb = %f\n", probName, survProb];
   //}

   return survProb;

}

- (void) drop
{
    [super drop];
}

@end
