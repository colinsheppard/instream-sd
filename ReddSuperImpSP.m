//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 


#import "ReddSuperImpSP.h"


@implementation ReddSuperImpSP

+ createBegin: aZone
{

  ReddSuperImpSP* aCustomProb = [super createBegin: aZone];

  aCustomProb->funcList = [List create: aCustomProb->probZone];

  return aCustomProb;

}

- createEnd
{

  return [super createEnd];

}


- createReddSuperImpFuncWithMap: (id <Map>) aMap
                withInputMethod: (SEL) anInputMethod
{

  ReddSuperImpFunc* superImpFunc = [ReddSuperImpFunc createBegin: probZone
                                                   setInputMethod: anInputMethod];


  [funcList addLast: superImpFunc];

  return superImpFunc;

}



- (double) getSurvivalProb
{
    id aFunc=nil;

    aFunc = [funcList getFirst];

    if(aFunc == nil)
    {
       fprintf(stderr, "ERROR: ReddSuperImpSP >>>> getSurvivalProb >>>> aFunc is nil\n");
       fflush(0);
       exit(1);
    }


    return [aFunc getFuncValue];


    //return 1.0;

}


- (void) drop
{
    //fprintf(stdout, "ReddSuperImp >>>> drop >>>> BEGIN\n");
    //fflush(0);

    [super drop];

    //fprintf(stdout, "ReddSuperImp >>>> drop >>>> END\n");
    //fflush(0);
}


@end



