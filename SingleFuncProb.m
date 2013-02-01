//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 



#import "SingleFuncProb.h"

@implementation SingleFuncProb


+ createBegin: aZone
{

  SingleFuncProb* aProb;

  aProb = [super createBegin: aZone];

  aProb->singleFunc = nil;

  return aProb;

}


- createEnd
{
	//fprintf(stdout, "SingleFuncProb >>>> createEnd >>>> BEGIN, %s \n", [self getName]);
	//fflush(0);

  
  if(singleFunc == nil)
  {
	  //fprintf(stdout, "SingleFuncProb >>>> createEnd >>>> singleFunc == nil \n");
	  //fflush(0);
     if([funcList getCount] > 1)
     {
        [Warning raiseEvent: "WARNING: SingleFuncProb >>>> more than one function on funcList\n"];
     }
  
     //fprintf(stdout, "SingleFuncProb >>>> createEnd >>>> before getFirst \n");
     //fflush(0);
     singleFunc = [funcList getFirst];

  }

  //fprintf(stdout, "SingleFuncProb >>>> createEnd >>>> END\n");
  //fflush(0);
  return [super createEnd];

}



- (double) getSurvivalProb
{

   double survProb=-1.0;

   survProb = [singleFunc getFuncValue];

   //if((survProb < 0.0) || (survProb > 1.0))
   //{
      //[InternalError raiseEvent: "ERROR: SingleFuncProb >>>> probName = %s >>>> survProb is not between zero and one. Value is: %f\n", probName, survProb];
   //}

   return survProb;

}

- (void) drop
{
   [super drop];
}

@end
