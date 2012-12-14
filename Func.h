//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 



#import <objectbase/SwarmObject.h>
#import <defobj.h>
#import "globals.h"

@interface Func : SwarmObject
{

@protected

   double funcValue;

   SEL inputMethod;
   id <MessageProbe> messageProbe;

}

+ create: aZone;
+ createBegin: aZone;
+      createBegin: aZone
    setInputMethod: (SEL) anInputMethod;
- createEnd;

- setInputMethod: (SEL) anInputMethod;
- (id <MessageProbe>) createInputMethodMessageProbeFor: (SEL) anInputMethod;


- (const char *) getProbedMessage;
- (BOOL) isResultId;
- (val_t) getProbedMessageValWithAnObj: anObj;
- (double) getProbedMessageRetValWithAnObj: anObj;
- getProbedMessageIDRetValWithAnObj: anObj;

- updateWith: anObj;

- (double) getFuncValue;

- (void) drop;

@end


