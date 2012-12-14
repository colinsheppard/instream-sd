//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 


#import "SurvMGR.h"



@implementation SurvMGR


+         createBegin: aZone
   withHabitatObject: anObj
{

  SurvMGR* aSurvMgr;
  
  aSurvMgr = [super createBegin: aZone];

  aSurvMgr->mgrZone = [Zone create: aZone];
  aSurvMgr->ANIMAL = [Symbol create: aSurvMgr->mgrZone setName: "ANIMAL"];
  aSurvMgr->HABITAT = [Symbol create: aSurvMgr->mgrZone setName: "HABITAT"];


  aSurvMgr->starvSurvivalProb = nil;
  aSurvMgr->listOfSurvProbs = nil;
  aSurvMgr->listOfKnownNonStarvSurvProbs = nil;
  aSurvMgr->listOfHabitatUpdateFuncs = nil;
  aSurvMgr->listOfAnimalUpdateFuncs = nil;

  aSurvMgr->myCurrentAnimal = nil;
  aSurvMgr->myHabitatObject = anObj;

  aSurvMgr->testOutput = NO;
  aSurvMgr->testOutputFilePtr = NULL;
  aSurvMgr->formatString = NULL;

  aSurvMgr->survProbLstNdx = nil;
  aSurvMgr->knownNonStarvSurvProbLstNdx = nil;

  aSurvMgr->listOfSurvProbs = [List create: aSurvMgr->mgrZone];
  aSurvMgr->listOfKnownNonStarvSurvProbs = [List create: aSurvMgr->mgrZone];
  aSurvMgr->listOfHabitatUpdateFuncs = [List create: aSurvMgr->mgrZone];
  aSurvMgr->listOfAnimalUpdateFuncs = [List create: aSurvMgr->mgrZone];


  return aSurvMgr;

}



- createEnd
{

  id aProb = nil;


  //
  //
  //
  [listOfSurvProbs forEach: M(createEnd)];

  numberOfProbs = [listOfSurvProbs getCount];

  //
  // This index is used throughout the model run DO NOT DROP IT!!!
  //
  if(survProbLstNdx != nil)
  {
     [survProbLstNdx drop]; 
  }

  survProbLstNdx = [listOfSurvProbs listBegin: mgrZone];

  if( [listOfKnownNonStarvSurvProbs getCount] > 0)
  {
      [listOfKnownNonStarvSurvProbs removeAll];
  }
 

  [survProbLstNdx setLoc: Start];

  while (([survProbLstNdx getLoc] != End) && ((aProb = [survProbLstNdx next]) != nil))
  {

     BOOL isStarvSurvProb = [aProb getIsStarvProb];
     BOOL anAgentKnows = [aProb getAnAgentKnows];

     if(!isStarvSurvProb && anAgentKnows)
     {
        [listOfKnownNonStarvSurvProbs addLast: aProb];
     }
       
  }
   
  //
  // This index is used throughout the model run DO NOT DROP IT!!!
  //
  knownNonStarvSurvProbLstNdx  = [listOfKnownNonStarvSurvProbs listBegin: mgrZone];


  return [super createEnd];

}


- setMyHabitatObject: anObj
{

   myHabitatObject = anObj;

   return self;

}



- setTestOutputOnWithFileName: (char *) aFileName;
{

    static FILE* outFilePtr = NULL;

    struct tm *timeStruct;
    time_t aTime;
    char sysDateAndTime[35];

    testOutput = TRUE;

    if(outFilePtr == NULL)
    {
        if((outFilePtr = fopen(aFileName, "w")) == NULL)
        {
           [InternalError raiseEvent: "ERROR: SurvMGR >>>> Cannot open %s for writing\n", aFileName];
        }

        testOutputFilePtr = outFilePtr;

        aTime = time(NULL);
        timeStruct = localtime(&aTime);
        strftime(sysDateAndTime, 35, "%a %d-%b-%Y %H:%M:%S", timeStruct) ;

        fprintf(testOutputFilePtr, "\n");
        fprintf(testOutputFilePtr, "Model Run System Date and Time: %s\n", sysDateAndTime); 
        fprintf(testOutputFilePtr, "\n");
        fflush(0);

    }

    testOutputFilePtr = outFilePtr;

    [self createHeaderAndFormatStrings];

    return self;

}


- (id <Symbol>) getANIMALSYMBOL
{

   if(ANIMAL == nil)
   {
      fprintf(stderr,"ERROR: SurvMgr >>>> ANIMAL Symbol is nil\n");
      fflush(0);
      exit(1);
   }

   return ANIMAL;
}

- (id <Symbol>) getHABITATSYMBOL
{

   if(HABITAT == nil)
   {
      fprintf(stderr,"ERROR: SurvMgr >>>> HABITAT Symbol is nil\n");
      fflush(0);
      exit(1);
   }


   return HABITAT;
}


- (int) getNumberOfProbs
{
  return numberOfProbs;
}


- getHabitatObject
{
  return myHabitatObject;
}


- getCurrentAnimal
{
  return myCurrentAnimal;
}




- addPROBWithSymbol: (id <Symbol>) aProbSymbol
          withType: (char *) aProbType
    withAgentKnows: (BOOL) anAgentKnows
   withIsStarvProb: (BOOL) isAStarvProb
{

  id aProb = nil;
  int i;
   
  for(i = 0; i < [listOfSurvProbs getCount]; i++)
  {
      id aProb = [listOfSurvProbs atOffset: i];
    
      if([aProb getProbSymbol] == aProbSymbol)
      {
           fprintf(stderr, "ERROR: addPROBWithSymbol:withType:withAgentKnows:withIsStarvProb >>>> Probability object %s already exists\n", [aProb getName]);
           fflush(0);
           exit(1);
      }
  }



  if(strncmp("SingleFunctionProb", aProbType, strlen("SingleFunctionProb")) == 0)
  {

     aProb = [SingleFuncProb createBegin: mgrZone];

  }
  else if(strncmp("LimitingFunctionProb", aProbType, strlen("LimitingFunctionProb")) == 0)
  {

     aProb = [LimitingFunctionProb createBegin: mgrZone];
  }

  else if(strncmp("CustomProb", aProbType, strlen("CustomProb")) == 0)
  {
     //
     // SurvMGR knows nothing about the custom probablity
     // at compile time. This gets resolved at runtime...
     //
     Class aCustomProbClass;

     aCustomProbClass = [objc_get_class([aProbSymbol getName]) class];
     
     aProb = [aCustomProbClass createBegin: mgrZone];

  }
  else
  {
     [InternalError raiseEvent: "ERROR: SurvMGR >>>> Cannot create Probability type %s \n", aProbType];
  }  


   [aProb setProbSymbol: aProbSymbol];
   [aProb setIsStarvProb: isAStarvProb];
   [aProb setAnAgentKnows: anAgentKnows];
   [aProb setSurvMgr: self];

   [listOfSurvProbs addLast: aProb];


   if(isAStarvProb)
   {
     if(starvSurvivalProb != nil)
     {
         [InternalError raiseEvent: "ERROR: SurvMGR >>>> addPROBWithSymbol:andType:andAgentKnows:andIsStarvProb >>>> attempting to create more than one starvation survival probability function\n"];
     }
     starvSurvivalProb = aProb;
   }

  return self;

}


- addBoolSwitchFuncToProbWithSymbol: (id <Symbol>) aProbSymbol
          withInputObjectType: (id <Symbol>) objType
               withInputSelector: (SEL) aSelector
                  withYesValue: (double) aYesValue
                   withNoValue: (double) aNoValue
{

  id <ListIndex> ndx;
  id aProb = nil;
  id aFunc = nil;

  BOOL ERROR=TRUE;

  ndx = [listOfSurvProbs listBegin: mgrZone];
  while (([ndx getLoc] != End) && ((aProb = [ndx next]) != nil))
  {
     if(aProbSymbol == [aProb getProbSymbol])
     {

          aFunc = [aProb createBoolSwitchFuncWithInputMethod: aSelector
                                        withYesValue: aYesValue
                                         withNoValue: aNoValue];



         if(objType == HABITAT)
         {
             [listOfHabitatUpdateFuncs addLast: aFunc];
         }
         else if(objType == ANIMAL)
         {
             [listOfAnimalUpdateFuncs addLast: aFunc];
         }
         else
         {
            break;  //an error occurred 
         }

         ERROR = FALSE;
         break;
     }

  }


  [ndx drop];

  if(ERROR) 
  {
     [InternalError raiseEvent: "ERROR: SurvMGR >>>> addBoolSwitchFuncToProbWihSymbol >>>> Either aProbSymbol = %s was not found or inputObject is invalid\n", [aProbSymbol getName]];
  }


  return self;

}



- addLogisticFuncToProbWithSymbol: (id <Symbol>) aProbSymbol
         withInputObjectType: (id <Symbol>) objType
              withInputSelector: (SEL) aSelector
                  withXValue1: (double) xValue1
                  withYValue1: (double) yValue1
                  withXValue2: (double) xValue2
                  withYValue2: (double) yValue2
{

  id <ListIndex> ndx;
  id aProb = nil;
  id aFunc = nil;

  BOOL ERROR=TRUE;


  ndx = [listOfSurvProbs listBegin: mgrZone];
  while (([ndx getLoc] != End) && ((aProb = [ndx next]) != nil))
  {
     if(aProbSymbol == [aProb getProbSymbol])
     {

        aFunc = [aProb createLogisticFuncWithInputMethod: aSelector
                              withInputObjectType: objType
                                       andXValue1: xValue1
                                       andYValue1: yValue1
                                       andXValue2: xValue2
                                       andYValue2: yValue2];


         if(objType == HABITAT)
         {
             [listOfHabitatUpdateFuncs addLast:  aFunc];
         }
         else if(objType == ANIMAL)
         {
             [listOfAnimalUpdateFuncs addLast: aFunc];
         }
         else
         {
            break;  //an error occurred 
         }

         ERROR = FALSE;
         break;
     }

  }


  [ndx drop];

  if(ERROR) 
  {
     [InternalError raiseEvent: "ERROR: SurvMGR >>>> addLogisticFuncToProbWithSymbol >>>> Either aProbSymbol = %s was not found or inputObjectType is invalid\n", [aProbSymbol getName]];
  }


  return self;

}


- setLogisticFuncLimiterTo: (double) aLimiter
{

   id aFunc = nil;

   id <ListIndex> habitatUpdateFuncsNdx = [listOfHabitatUpdateFuncs listBegin: mgrZone];
   id <ListIndex> animalUpdateFuncsNdx = [listOfAnimalUpdateFuncs listBegin: mgrZone];

   [habitatUpdateFuncsNdx setLoc: Start];
   
   while(([habitatUpdateFuncsNdx getLoc] != End) && ((aFunc = [habitatUpdateFuncsNdx next]) != nil))
   {
        if([aFunc respondsTo: @selector(setLogisticFuncLimiterTo:)])
        {
            [aFunc setLogisticFuncLimiterTo: aLimiter];
        }
   }

   [habitatUpdateFuncsNdx drop];
  
   [animalUpdateFuncsNdx setLoc: Start];
  
   while(([animalUpdateFuncsNdx getLoc] != End) && ((aFunc = [animalUpdateFuncsNdx next]) != nil))
   {
        if([aFunc respondsTo: @selector(setLogisticFuncLimiterTo:)])
        {
            [aFunc setLogisticFuncLimiterTo: aLimiter];
        }
   }
 
   [animalUpdateFuncsNdx drop];



   return self;
}


- addConstantFuncToProbWithSymbol: (id <Symbol>) aProbSymbol
                   withValue: (double) aValue
{


  id <ListIndex> ndx;
  id aProb;

  BOOL ERROR=TRUE;


  ndx = [listOfSurvProbs listBegin: mgrZone];
  while (([ndx getLoc] != End) && ((aProb = [ndx next]) != nil))
  {
     if(aProbSymbol == [aProb getProbSymbol])
     {
           [aProb createConstantFuncWithValue: aValue];

           ERROR = FALSE;
           break;
     }

   }

  if(ERROR) 
  {
     [InternalError raiseEvent: "ERROR: SurvMGR >>>> addConstantFuncToProbWithSymbol >>>> Either aProbSymbol = %s was not found or inputObjectType is invalid\n", [aProbSymbol getName]];
  }

  return self;
}


- addCustomFuncToProbWithSymbol: (id <Symbol>) aProbSymbol
                  withClassName: (char *) className
            withInputObjectType: (id <Symbol>) objType
              withInputSelector: (SEL) anInputSelector
{

  id <ListIndex> ndx;
  id aProb;

  BOOL ERROR=TRUE;

  ndx = [listOfSurvProbs listBegin: mgrZone];
  while (([ndx getLoc] != End) && ((aProb = [ndx next]) != nil))
  {
     if(aProbSymbol == [aProb getProbSymbol])
     {
         id aFunc = nil;

         aFunc = [aProb createCustomFuncWithClassName: className
                                       withInputSelector: anInputSelector
                                     withInputObjectType: objType];

         if(objType == HABITAT)
         {
             [listOfHabitatUpdateFuncs addLast: aFunc];
         }
         else if(objType == ANIMAL)
         {
             [listOfAnimalUpdateFuncs addLast: aFunc];
         }
         else
         {
            break;  //an error occurred 
         }

         ERROR = FALSE;
         break;
     }

   }

  [ndx drop];

  if(ERROR) 
  {
     [InternalError raiseEvent: "ERROR: SurvMGR >>>> addCustomFuncToProbWithSymbol >>>> aProbSymbol = %s was not found or inputObjectType was not found\n", [aProbSymbol getName]];

  }


  return self;


}



//
// USING
//


///////////////////////////////////
//
// updateForHabitat
//
///////////////////////////////////
- updateForHabitat
{
   //fprintf(stdout, "SURVMGR >>>> updateForHabitat BEGIN\n");
   //fflush(0);
   
   if(myHabitatObject == nil)
   {
      [InternalError raiseEvent: "ERROR: SurvMGR >>>> myHabitatObject is nil\n"];
   }


   [listOfHabitatUpdateFuncs forEach: M(updateWith:) :myHabitatObject];

   //fprintf(stdout, "SURVMGR >>>> updateForHabitat EXIT\n");
   //fflush(0);

   return self;

}


///////////////////////////////////
//
// updateForAnimal
//
///////////////////////////////////
- updateForAnimal: anAnimal
{

   //
   // set the SurvMGR's instance var. myCurrentAnimal
   // will change from agent to agent.
   //
   myCurrentAnimal = anAnimal;

   [listOfAnimalUpdateFuncs forEach: M(updateWith:) :myCurrentAnimal];

   if(testOutput == YES)
   {
      [self writeSurvOutputWithAnimal: anAnimal];
   }

   return self;

}


//////////////////////////////////////////////////
//
// getListOfSurvProbsFor
//
//////////////////////////////////////////////////
- (id <List>) getListOfSurvProbsFor: anAnimal
{

  if(myCurrentAnimal != anAnimal)
  {
     [InternalError raiseEvent: "ERROR: SurvMGR >>>> Attempt to use getListOfSurvProbStructsFor for an animal the survival manager has not been updated for\n"];
  }

  return listOfSurvProbs;

}



///////////////////////////////////////////////
//
// getTotalSurvivalProbFor
//
///////////////////////////////////////////////
- (double) getTotalSurvivalProbFor: anAnimal
{

  id aProb = nil;

  double totalSurvivalProb=1.0;


  if(myCurrentAnimal != anAnimal)
  {
     [InternalError raiseEvent: "ERROR: SurvMGR >>>> Attempt to use  getTotalSurvivalProbFor for an animal the survival manager has not been updated for\n"];
  }

  if(survProbLstNdx == nil)
  {
     [InternalError raiseEvent: "ERROR: >>>> getTotalSurvivalProbFor >>>> survProbLstNdx is nil >>>> ensure createEnd was invoked\n"];
  }

  [survProbLstNdx setLoc: Start];

  while (([survProbLstNdx getLoc] != End) && ((aProb = [survProbLstNdx next]) != nil))
  {
      totalSurvivalProb *= [aProb getSurvivalProb];
  } 


  return totalSurvivalProb;

}



///////////////////////////////////////////////
//
// getTotalKnownNonStarvSurvivalProb
//
//////////////////////////////////////////////
- (double) getTotalKnownNonStarvSurvivalProbFor: anAnimal
{
  id aProb=nil;

  double totalKnownNonStarvSurvivalProb = 1.0;

  if(myCurrentAnimal != anAnimal)
  {
      [InternalError raiseEvent: "ERROR: SurvMGR >>>> Attempt to use getTotalKnownNonStarvSurvivalProbFor for an animal the survival manager has not been updated for\n"];
  }

  [knownNonStarvSurvProbLstNdx setLoc: Start];

  while (([knownNonStarvSurvProbLstNdx getLoc] != End) && ((aProb = [knownNonStarvSurvProbLstNdx next]) != nil))
  {
         totalKnownNonStarvSurvivalProb *=  [aProb getSurvivalProb];
  }


  return totalKnownNonStarvSurvivalProb; 

}


- (double) getStarvSurvivalFor: anAnimal
{

   if(myCurrentAnimal != anAnimal)
   {
      [InternalError raiseEvent: "ERROR: SurvMGR >>>> Attempt to use getStarvSurvivalFor for an animal the survival manager has not been updated for\n"];
   }

   return [starvSurvivalProb getSurvivalProb];

}







///////////////////////////////////////////////
//
// createHeaderAndFormatStrings
//
///////////////////////////////////////////////
- createHeaderAndFormatStrings
{
    if(!testOutput) 
    {
       return self;
    }
    else 
    {
         static BOOL firstTime = YES;
     
         id <ListIndex> probLstNdx;
         id aProb = nil;

         size_t strLen = 0;
         int numProbs = 0;
         int numFuncs = 0;
         int numMethods = 0;

         int numOutputStrings;
         int j = 0;
   

         if(firstTime == NO) 
         {
            return self;
         }

         probLstNdx = [listOfSurvProbs listBegin: scratchZone];

         fprintf(stdout, "SurvMGR >>>> createHeaderAndFormatStrings >>>> BEGIN\n");
         fflush(0);

         while(([probLstNdx getLoc] != End) && ((aProb = [probLstNdx next]) != nil))
         {
             id <List> funcList = [aProb getFuncList];
             id <ListIndex> funcLstNdx = [funcList listBegin: scratchZone];
             id func = nil;               

             //fprintf(stdout, "SurvMGR >>>> createHeaderAndFormatStrings >>>> aProb = %s\n", [aProb getName]);
             //fflush(0);

             while(([funcLstNdx getLoc] != End) && ((func = [funcLstNdx next]) != nil))
             {
                strLen += strlen([func getName]);
                strLen += strlen([func getProbedMessage]);

                numFuncs++;
                numMethods++;
             }

             strLen += strlen([aProb getName]);
             numProbs++;

             [funcLstNdx drop];
         }

         //
         // create the header string
         //
         {
             int i = -1;
             char header[numProbs + numFuncs + numMethods][36];

         [probLstNdx setLoc: Start];
         while(([probLstNdx getLoc] != End) && ((aProb = [probLstNdx next]) != nil))
         {
             id <List> funcList = [aProb getFuncList];
             id <ListIndex> funcLstNdx = [funcList listBegin: scratchZone];
             id func = nil;               


             char* probStr = (char *) [ZoneAllocMapper allocBlockIn: mgrZone
                                                          ofSize: 36*sizeof(char)];

             sprintf(probStr, "%-35s", [aProb getName]);

             i++;
             while(([funcLstNdx getLoc] != End) && ((func = [funcLstNdx next]) != nil))
             {
                
                char* messageStr = (char *) [ZoneAllocMapper allocBlockIn: mgrZone
                                                                   ofSize: 36*sizeof(char)];                

                char* funcStr = (char *) [ZoneAllocMapper allocBlockIn: mgrZone
                                                                ofSize: 36*sizeof(char)];                

                sprintf(messageStr, "%-35s", [func getProbedMessage]);
                sprintf(funcStr, "%-35s", [func getName]);

                strncpy(header[i], messageStr, 36);
                i++;
                strncpy(header[i], funcStr, 36);
             }

             i++;
             strncpy(header[i], probStr, 36);
 
             [funcLstNdx drop];
         }

         numOutputStrings = ++i;
         for(j = 0; j < numOutputStrings; j++)
         { 
            fprintf(testOutputFilePtr, "%s", header[j]);
            fflush(testOutputFilePtr);
         }

         } // Create the header string

        
         fprintf(testOutputFilePtr, "%c", '\n');
         fflush(testOutputFilePtr);
   
         firstTime = NO;
         [probLstNdx drop];

         //fprintf(stdout, "SurvMGR >>>> createHeaderAndFormatStrings >>>> END\n");
         //fflush(0);
    }

    return self;
}



//////////////////////////////////////////////
//
// writeSurvivalOutputWithAnimal
//
/////////////////////////////////////////////
- writeSurvOutputWithAnimal: anAnimal
{
   if(testOutput == YES)
   {

       //fprintf(stdout, "SurvMGR >>>> writeSurvOutputWithAnimal >>>> BEGIN\n");
       //fflush(0);

       if(myCurrentAnimal != anAnimal)
       {
          fprintf(stderr, "ERROR: SurvMGR >>>> Attempt to use writeSurvOutputWithAnimal for an animal the survival manager has not been updated for\n");
          fflush(0);
          exit(1);
       }

       if(myHabitatObject != nil)
       {
          id <ListIndex> lstNdx;
          id survProb = nil;
          val_t val;

          lstNdx = [listOfSurvProbs listBegin: scratchZone];

          [lstNdx setLoc: Start];

           while(([lstNdx getLoc] != End) && ((survProb = [lstNdx next]) != nil)) 
           {
                id func = nil;
                id funcNdx = [[survProb getFuncList] listBegin: scratchZone];

                while(([funcNdx getLoc] != End) && ((func = [funcNdx next]) != nil)) 
                {
                    id myObject = nil;

                    if([listOfHabitatUpdateFuncs contains: func])
                    {
                         myObject = myHabitatObject;
                    }
                    else if([listOfAnimalUpdateFuncs contains: func])
                    {
                         myObject = anAnimal;
                    }
                    else
                    {
                         fprintf(stderr, "ERROR: SurvMGR >>>> writeSurvOutputWithAnimal >>>> no update objects\n");
                         fflush(0);
                         exit(1);
                    }

                    val = [func getProbedMessageValWithAnObj: myObject];
    
                    //fprintf(stderr, "SURVMGR TYPE %d\n", (int) val.type);
                    //fflush(0);

                    if((val.type == fcall_type_object) || (val.type == fcall_type_selector))
                    {
                       //fprintf(stdout, "SURVMGR TYPE POINTER %p\n", [func getProbedMessageIDRetValWithAnObj: myObject]);
                       //fflush(0);
                       fprintf(testOutputFilePtr, "%-35p", [func getProbedMessageIDRetValWithAnObj: myObject]);
                       fflush(testOutputFilePtr);
                    }
                    else
                    {   
                       //fprintf(stdout, "SURVMGR TYPE FLOAT %f\n", [func getProbedMessageRetValWithAnObj: myObject]);
                       //fflush(0);
                       fprintf(testOutputFilePtr, "%-35E", [func getProbedMessageRetValWithAnObj: myObject]);
                       fflush(testOutputFilePtr);
                    }
    

                    fprintf(testOutputFilePtr, "%-35E", [func getFuncValue]);
                    fflush(testOutputFilePtr);
               }

               [funcNdx drop];

               fprintf(testOutputFilePtr, "%-35E", [survProb getSurvivalProb]);
               fflush(testOutputFilePtr);
           }

           fprintf(testOutputFilePtr, "%c", '\n');
           fflush(testOutputFilePtr);

           [lstNdx drop];

           //fprintf(stdout, "SurvMGR >>>> writeSurvOutputWithAnimal >>>> END\n");
           //fflush(0);
       }
   }

   return self;
}


/////////////////////////////////////
//
// drop
//
/////////////////////////////////////
- (void) drop
{
    //fprintf(stdout, "SurvMGR >>>> drop >>>> BEGIN\n");
    //fflush(0);
     //[listOfAnimalUpdateFuncs deleteAll];
     //[listOfAnimalUpdateFuncs deleteAll];
     [listOfSurvProbs deleteAll];
     [mgrZone drop];
    //fprintf(stdout, "SurvMGR >>>> drop >>>> END\n");
    //fflush(0);
}



@end


