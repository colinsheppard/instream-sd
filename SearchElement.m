//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 





#import "SearchElement.h"

@implementation SearchElement

- nextControlSetOnObject: (id) theObject {
  return ([self subclassResponsibility: M(nextControlSetOnObject:)]);
}



- measureSystemInObject: (id) theObject {
  return ([self subclassResponsibility: M(measureSystemInObject:)]);
}


- calcStep {
  return ([self subclassResponsibility: M(calcStep)]);
}

@end
