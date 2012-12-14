//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 


#import "Func.h"

@implementation Func

+ create: aZone
{
  return [super create: aZone];
}



+ createBegin: aZone
{
   return [super createBegin: aZone];
}

+     createBegin: aZone
   setInputMethod: (SEL) anInputMethod
{

   Func* aFunc = [super createBegin: aZone];

   aFunc->inputMethod = anInputMethod;
   [aFunc createInputMethodMessageProbeFor: aFunc->inputMethod];

   return aFunc;

}

- createEnd
{
   return [super createEnd];
}


- updateWith: anObj 
{
  return ([self subclassResponsibility: M(updateWith:)]);
}



- setInputMethod: (SEL) anInputMethod
{

  inputMethod = anInputMethod;

  return self;

}


- (id <MessageProbe>) createInputMethodMessageProbeFor: (SEL) anInputMethod
{

  if(messageProbe == nil)
  {
      messageProbe = [MessageProbe        create: [self getZone]
                               setProbedSelector: anInputMethod];

  } 

   return messageProbe;

}


- (const char *) getProbedMessage
{

   return [messageProbe getProbedMessage];

}

- (val_t) getProbedMessageValWithAnObj: anObj
{

    return (val_t) [messageProbe dynamicCallOn: anObj];

}


- (BOOL) isResultId
{
   return [messageProbe isResultId];
}


- (double) getProbedMessageRetValWithAnObj: anObj
{

    double retVal = 0.0;

    val_t val = [messageProbe dynamicCallOn: anObj];

    if((val.type == fcall_type_object) || (val.type == fcall_type_selector))
    {
        abort();
    }
    else
    { 
       retVal =  [messageProbe doubleDynamicCallOn: anObj];
    }

    return retVal;

}


- getProbedMessageIDRetValWithAnObj: anObj
{
    id retVal = nil;
    val_t val = [messageProbe dynamicCallOn: anObj];

    if((val.type == fcall_type_object) || (val.type == fcall_type_selector))
    {
       retVal = [messageProbe objectDynamicCallOn: anObj];
    }
    else
    {
       abort();
    }

    return retVal;
}
    

- (double) getFuncValue
{

   //fprintf(stdout, "Func >>>> getFuncValue >>>> funcValue = %f\n", funcValue);
   //fflush(0);

 
   return funcValue;

}


- (void) drop
{

    [super drop];
}

@end

