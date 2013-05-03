/*
EcoSwarm library for individual-based modeling, last revised February 2012.
Developed and maintained by Steve Railsback, Lang, Railsback & Associates, 
Steve@LangRailsback.com; Colin Sheppard, critter@stanfordalumni.org; and
Steve Jackson, Jackson Scientific Computing, McKinleyville, California.
Development sponsored by US Bureau of Reclamation under the 
Central Valley Project Improvement Act, EPRI, USEPA, USFWS,
USDA Forest Service, and others.
Copyright (C) 2004-2012 Lang, Railsback & Associates.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program (see file LICENSE); if not, write to the
Free Software Foundation, Inc., 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.
*/


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

