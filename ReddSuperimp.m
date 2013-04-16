//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 


#import "ReddSuperimp.h"


@implementation ReddSuperimp

+ createBegin: aZone
{

  ReddSuperimp* aCustomProb = [super createBegin: aZone];

  aCustomProb->funcList = [List create: aCustomProb->probZone];

  return aCustomProb;

}

- createEnd
{

  return [super createEnd];

}


- createReddSuperimpFuncWithMap: (id <Map>) aMap
                withInputMethod: (SEL) anInputMethod
{

  ReddSuperimpFunc* superimpFunc = [ReddSuperimpFunc createBegin: probZone
                                                   setInputMethod: anInputMethod];


  [funcList addLast: superimpFunc];

  return superimpFunc;

}



- (double) getSurvivalProb
{
    id aFunc=nil;

    aFunc = [funcList getFirst];

    if(aFunc == nil)
    {
       fprintf(stderr, "ERROR: ReddSuperimp >>>> getSurvivalProb >>>> aFunc is nil\n");
       fflush(0);
       exit(1);
    }


    return [aFunc getFuncValue];


    //return 1.0;

}


- (void) drop
{
    //fprintf(stdout, "ReddSuperimp >>>> drop >>>> BEGIN\n");
    //fflush(0);

    [super drop];

    //fprintf(stdout, "ReddSuperimp >>>> drop >>>> END\n");
    //fflush(0);
}


@end



