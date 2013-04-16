//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 


#import "ReddScour.h"


@implementation ReddScour

+ createBegin: aZone
{

  ReddScour* aCustomProb = [super createBegin: aZone];

  aCustomProb->scourFunc = nil;

  return aCustomProb;

}

- createEnd
{
  return [super createEnd];
}


- createReddScourFuncWithMap: (id <Map>) aMap
                withInputMethod: (SEL) anInputMethod
{

  scourFunc = [ReddScourFunc createBegin: probZone
                          setInputMethod: anInputMethod];
  if(scourFunc == nil)
  {
     fprintf(stderr, "ERROR: ReddScour >>>> createReddScourFuncWithMap:withInputMethod: >>>> scourFunc is nil\n");
     fflush(0);
     exit(1);
  }

  return scourFunc;

}



- (double) getSurvivalProb
{

    id aFunc=nil;

    aFunc = [funcList getFirst];

    //fprintf(stdout, "ReddScour >>>> getSurvivalProb >>>> BEGIN\n");
    //fflush(0); 

    if(aFunc == nil)
    {
       fprintf(stderr, "ERROR: ReddScour >>>> getSurvivalProb >>>> aFunc is nil\n");
       fflush(0);
       exit(1);
    }

    //fprintf(stdout, "ReddScour >>>> getSurvivalProb >>>> END\n");
    //fflush(0); 

    //return [scourFunc getFuncValue];
    return [aFunc getFuncValue];
}


- (void) drop
{
    fprintf(stdout, "ReddScour >>>> drop >>>> BEGIN\n");
    fflush(0);

    [super drop];

    fprintf(stdout, "ReddScour >>>> drop >>>> END\n");
    fflush(0);
}


@end



