//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 




#import <collections.h>
#import <objectbase/SwarmObject.h>

@interface SearchElement : SwarmObject {

  id <Array> controlSet;  // array of probes
  id <Array> controlSetObjects; // array of things to probe
  id <Array> measureSet;  // array of probes

}


         //////////////
         // METHODS  //
         //////////////

- nextControlSetOnObject: (id) theObject;
- measureSystemInObject: (id) theObject;
- calcStep;
@end
