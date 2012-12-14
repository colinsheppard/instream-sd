//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 



#import "globals.h"
#import "ReddSurvivalFunc.h"

@protocol Model
- (int) getNumberOfSpecies;
@end



@implementation SurvivalFunc
- setCell: aCell {
  myCell = aCell;
  return self;
}

- createEnd {
  [super createEnd];
  if (myCell == nil)
    [InternalError raiseEvent: "Cannot finish creating %s because "
		   //"myCell is not set.", [self getInstanceName]];
		   "myCell is not set.", [self getName]];
  numSpecies = [self getNumberOfSpecies];
  return self;
}


////////////////////////////////////////////////////////////
//
// update  added 3/8/2000 for cutthroat model
//
///////////////////////////////////////////////////////////
- update {

   return self;

}


- (float) getSFFor: aRedd {
  printf("\nFrom getSFFor in Redd Survival\n");
  [self subclassResponsibility: M(getSFFor:)];
  return -1.0;
}


- (int) getNumberOfSpecies {

  return [(id <Model>) [[myCell getSpace] getModel] getNumberOfSpecies];
}

- (void) drop
{
    [super drop];
}

@end
