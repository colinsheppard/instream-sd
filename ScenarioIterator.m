//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 

#include <stdlib.h>

#import "ScenarioIterator.h"

struct experVar {

         void * experVariableValue;
         int scenarioCount;
         int replicateCount;

}; 


struct updateVar {

           Class updateClass;
           id <VarProbe> varProbe;
};


@implementation ScenarioIterator 

+ createBegin: aZone 
{
  ScenarioIterator * newSelf;
  id <Map> tempMap;
  id <List> tempList;
  char * tempString;


  newSelf = [super createBegin: aZone];

  newSelf->scenarioIterZone = [Zone create: aZone];


  tempMap = [Map create: aZone];
  newSelf->iterMap = tempMap;


  tempList = [List create: aZone];
  newSelf->updateScenarioClassList = tempList;
  
  tempList = [List create: aZone];
  newSelf->updateReplicateClassList = tempList;
  

  tempString = (char *) [aZone alloc: 101*sizeof(char)];
  newSelf->oldParameter = tempString;

  newSelf->scenarioCount = 1;
  newSelf->replicateCount = 1;
  newSelf->classCount = 0;
  newSelf->numScenarios = 1;
  newSelf->numReplicates = 1;

  newSelf->aProbe=nil;

  newSelf->classList = [List create: aZone];
  //newSelf->instanceNameList = [List create: aZone];
  newSelf->paramClassInstanceNameMap = [Map create: aZone];

  return newSelf;

}



//////////////////////////////////////////////
//
// setNumScenarios
//
//////////////////////////////////////////////
- setNumScenarios: (int) aNumScenarios
{
  numScenarios = aNumScenarios;

  return self;

}



/////////////////////////////////////////////
//
// setNumReplicates
//
/////////////////////////////////////////////
- setNumReplicates: (int) aNumReplicates {

  numReplicates = aNumReplicates;

  return self; 
 
}




/////////////////////////////////////////////////
//
// appendToIterSetParam
//
/////////////////////////////////////////////////
-  appendToIterSetParam: (const char *) newParam
          withParamType: (char) aParamType
                ofClass: (Class) paramClass
       withInstanceName: (id <Symbol>) anInstanceName
             paramValue: (void *) paramValue
{

 static int scenarioCounter = 1;
 struct experVar *myVar;
 id <Map> aNewProbeMap = nil;
 id <Map> instanceNameMap = nil;
 const char * needANewParam = "need a new param";
 char probeType;
 BOOL TYPEERROR = YES;

  fprintf(stdout, "ScenarioIterator >>>> appendToIterSetParam >>>> BEGIN\n");
  fflush(0);
 
  myVar = (struct experVar *) [scenarioIterZone  alloc: sizeof(struct experVar)];

  if(![classList contains: paramClass]) 
  {
    instanceNameMap = [Map create: scenarioIterZone];
    aNewProbeMap = [Map create: scenarioIterZone];
    instanceNameList = [List create: scenarioIterZone];

    [instanceNameMap at: anInstanceName insert: aNewProbeMap];
   

    [iterMap at: paramClass insert: instanceNameMap];

    parameterClass = paramClass;

    classCount++;

    strncpy(oldParameter, needANewParam, 1 + strlen(needANewParam));

    [classList addLast: paramClass];
    [instanceNameList addLast: anInstanceName];
    [paramClassInstanceNameMap at: paramClass insert: instanceNameList]; 


  }
  else if([classList contains: paramClass] && ![[paramClassInstanceNameMap at: paramClass] contains: anInstanceName])
  {
     aNewProbeMap = [Map create: scenarioIterZone];
    [[iterMap at: paramClass] at: anInstanceName insert: aNewProbeMap];
    [[paramClassInstanceNameMap at: paramClass] addLast: anInstanceName];
  }

  aProbe = [probeLibrary getProbeForVariable: newParam inClass: paramClass];


  if(aProbe == nil)
  {
       fprintf(stderr, "ERROR: ScenarioIterator >>>> appendToIterSetParam >>>> nil Probe\n");
       fprintf(stderr, "       Check the experiment setup file for parameter: %s\n", newParam);
       fflush(0);
       exit(1);
  }

  if(strcmp(oldParameter, newParam) != 0) 
  {
    id <Array> tempArray;

    tempArray = [Array createBegin: scenarioIterZone];
    [tempArray setDefaultMember: nil];
    [tempArray setCount: 0];
    tempArray = [tempArray createEnd];

    if(anInstanceName == nil)
    {
        fprintf(stderr, "ERROR: ScenarioIterator >>>> appendToIterSetParam >>>> anInstanceName is nil\n");
        fflush(0);
        exit(1);
    }

    [[[iterMap at: paramClass] at: anInstanceName] at: aProbe insert: tempArray];

     strncpy( oldParameter, newParam, 1 + strlen(newParam) );
  }

  if([[[iterMap at: paramClass] at: anInstanceName] at: aProbe] == nil)
  {
    id <Array> tempArray;

    tempArray = [Array createBegin: scenarioIterZone];
    [tempArray setDefaultMember: nil];
    [tempArray setCount: 0];
    tempArray = [tempArray createEnd];

    [[[iterMap at: paramClass] at: anInstanceName] at: aProbe insert: tempArray];
  }

  probeType = [aProbe getProbedType][0];

  if((probeType == _C_CHARPTR) && (aParamType == _C_CHARPTR))
  {
        TYPEERROR = NO;
  } 
  else if((probeType == _C_INT) && (aParamType == _C_INT))
  {
        TYPEERROR = NO;
  } 
  else if((probeType == _C_UCHR) && (aParamType == _C_UCHR))
  {
        TYPEERROR = NO;
  } 
  else if((probeType == _C_FLT) && (aParamType == _C_FLT))
  {
        TYPEERROR = NO;
  } 
  else if((probeType == _C_DBL) && (aParamType == _C_DBL))
  {
        TYPEERROR = NO;
  } 
  
   
  if(TYPEERROR == YES)
  {
     fprintf(stderr, "ERROR: ScenarioIterator >>>> appendToIterSet: >>>> data type mismatch\n");
     fprintf(stderr, "       Check the experiment set up file for parameter: %s\n", newParam);
     fflush(0);
     exit(1);
  }


    switch (([aProbe getProbedType])[0]) {

        case _C_CHARPTR:   {

                 char *aNewString;
                     
                  aNewString = (char *)[[self getZone] alloc: (size_t) 1 + strlen(paramValue)*sizeof(char)];
                  strcpy(aNewString, paramValue);

                  myVar->experVariableValue = (void *) aNewString;


                          }
          break;

         case _C_INT:     {
                 int *aNewInt;
                 aNewInt = (int *) [[self getZone] alloc: sizeof(int)];
                 *aNewInt = *((int *) paramValue);

                 myVar->experVariableValue = (void *) aNewInt;

                         }
          break;

         case _C_UCHR:     {

                 unsigned char *aNewUChar;
                 aNewUChar = (unsigned char *) [[self getZone] alloc: sizeof(unsigned char)];
                 *aNewUChar = *((unsigned char *) paramValue);

                 myVar->experVariableValue = (void *) aNewUChar;

                         }
          break;

         case _C_FLT:    {
                 
                 float *aNewFlt;
                 aNewFlt = (float *) [ZoneAllocMapper allocBlockIn: scenarioIterZone
                                                            ofSize: sizeof(float)];
                 //aNewFlt = (float *) [[self getZone] alloc: sizeof(float)];
                 *aNewFlt = *((float *) paramValue);

                 myVar->experVariableValue = (void *) aNewFlt;

                         }

          break;

         case _C_DBL:   {
                 
                 double *aNewDbl;
                 aNewDbl = (double *) [[self getZone] alloc: sizeof(double)];
                 *aNewDbl = *((double *) paramValue);

                 myVar->experVariableValue = (void *) aNewDbl;

                 }
          break;

         default:
             fprintf(stderr, "ERROR: ScenarioIterator: Didn't recognize probedType\n");
             fflush(0);
             exit(1);
          break;


     } //switch

     myVar->scenarioCount = scenarioCounter;
     myVar->replicateCount = numReplicates; 

     [[[[iterMap at: paramClass] at: anInstanceName] at: aProbe] setCount: scenarioCounter + 1];
     [[[[iterMap at: paramClass] at: anInstanceName] at: aProbe] atOffset: scenarioCounter put: (void *) myVar];

    scenarioCounter++;

  if(scenarioCounter > numScenarios) scenarioCounter = 1;

  //fprintf(stdout, "ScenarioIterator >>>> appendToIterSetParam >>>> Class = %s\n", class_get_class_name(paramClass));
  //fflush(0);
  //xprint([[iterMap at: paramClass] at: anInstanceName]);
  //xprint([[[iterMap at: paramClass] at: anInstanceName] at: aProbe]);

  //fprintf(stdout, "ScenarioIterator >>>> appendToIterSetParam >>>> END\n");
  //fflush(0);

  return self;

}



- checkParameters {

  return self;

}


- createEnd 
{
  [super createEnd];

  if((numScenarios == 0) || (numReplicates == 0)) 
  {  
     fprintf(stderr, "ERROR: numScenarios or numReplicates is 0\n");
     fflush(0);
     exit(1);
  }

  scenarioNdx = [updateScenarioClassList listBegin: scenarioIterZone];
  replicateNdx = [updateReplicateClassList listBegin: scenarioIterZone];

  return self;
}


- nextFileSetOnObject: (id) theObject 
{
  return self;
}




//////////////////////////////////////////
//
// getIteration
//
/////////////////////////////////////////
- (int) getIteration 
{
    return scenarioCount;
}




////////////////////////////////////////////////////
//
// canWeGoAgain
//
////////////////////////////////////////////////////
- (BOOL) canWeGoAgain
{
   BOOL canWeGoAgain = YES;

   replicateCount++;

   //fprintf(stdout, "ScenarioIterator >>>> canWeGoAgain >>>> BEGIN\n");
   //fprintf(stdout, "ScenarioIterator >>>> canWeGoAgain >>>> numReplicates = %d\n", numReplicates);
   //fprintf(stdout, "ScenarioIterator >>>> canWeGoAgain >>>> replicateCount = %d\n", replicateCount);
   //fflush(0);
   
   if(numScenarios == 1)
   {
       if(replicateCount > numReplicates)
       {
            canWeGoAgain = NO;
       } 

   }
   else if (numScenarios > 1)
   {
      if(replicateCount > numReplicates) 
      {
         scenarioCount++;
         replicateCount = 1;
      }

      if(scenarioCount > numScenarios)
      {
         fprintf(stdout, "ScenarioIterator >>>> canWeGoAgain >>>> We're done >>>> EXITING\n");
         fflush(0);
 
         canWeGoAgain = NO;
      }
   }
   else
   {
        fprintf(stderr, "ScenarioIterator >>>> canWeGoAgain >>>> scenarioCount <= 0\n");
        fflush(0);
        exit(1);
   }

   //fprintf(stdout, "ScenarioIterator >>>> canWeGoAgain >>>> END\n");
   //fflush(0);

   return canWeGoAgain;
}
 



//////////////////////////////////////////////////////////
//
// nextControlSetOnObject
//
///////////////////////////////////////////////////////////
- nextControlSetOnObject: (id) theObject 
        withInstanceName: (id <Symbol>) anInstanceName
{
   id <VarProbe> ctrlSetProbe=nil;
   id ctrlSetObject;

   id <Map> myProbeMap = nil;

   id <MapIndex> probeMapNdx;

   char * newFile;

   unsigned char newUCharVal;
   int newIntVal;
   float newFloatVal;
   double newDoubleVal;

   struct experVar *myVar;


   fprintf(stdout, "ScenarioIterator >>>> nextControlSetOnObject >>>> BEGIN\n");
   fflush(0);

   [self updateClassScenarioCounts: theObject];
   [self updateClassReplicateCounts: theObject];

   if(strncmp([anInstanceName getName], "NONE", 4) != 0)
   {
       myProbeMap = [[iterMap at: getClass(theObject)] at: anInstanceName];
   }
   if(strncmp([anInstanceName getName], "NONE", 4) == 0)
   {
       if([iterMap at: getClass(theObject)] != nil)
       {
           myProbeMap = [[iterMap at: getClass(theObject)] at: anInstanceName];
       }
   }

   if(myProbeMap != nil) 
   {
       probeMapNdx = [myProbeMap mapBegin: [self getZone]];

        while( ([probeMapNdx getLoc] != End) && ([probeMapNdx next], (ctrlSetProbe = [probeMapNdx getKey]) != nil) )
        {

             myVar = (struct experVar *) [[myProbeMap at: ctrlSetProbe] atOffset: scenarioCount];

        if(scenarioCount != myVar->scenarioCount) continue;

        ctrlSetObject = theObject;

        switch (([ctrlSetProbe getProbedType])[0]) 
        {

            case _C_CHARPTR:

                  newFile = strdup((char *) myVar->experVariableValue);
                  [ctrlSetProbe setData: ctrlSetObject ToString: newFile];

                  break;

             case _C_UCHR:     

                  newUCharVal = *((unsigned char *) myVar->experVariableValue);
                  [ctrlSetProbe setData: ctrlSetObject To: &newUCharVal];

                  break;

             case _C_INT:

              newIntVal = *((int *) myVar->experVariableValue);
              [ctrlSetProbe setData: ctrlSetObject To: &newIntVal];

              break;

            case _C_FLT:
              newFloatVal = *((float *) myVar->experVariableValue);
              [ctrlSetProbe setData: ctrlSetObject To: &newFloatVal];
              break;

            case _C_DBL:
              newDoubleVal = *((double *) myVar->experVariableValue);
              [ctrlSetProbe setData: ctrlSetObject To: &newDoubleVal];

              break;

            default:
              fprintf(stderr, "ERROR: ScenarioIterate: Didn't recognize probedType\n");
              fflush(0);
              exit(1);
              break;
               
         } //switch

      } //while  


       [probeMapNdx drop];


  } //if probeMap 
  else
  {
      char* objectName = (char *) [theObject getName];
      fprintf(stderr, "SCENARIO ITERATOR >>>> nextControlSetOnObject\n"
                      "         theObject = %s does not belong to iterMap\n", [theObject getName]);

      [scratchZone free: objectName];
 
   }

   fprintf(stdout, "ScenarioIterator >>>> nextControlSetOnObject >>>> END\n");
   fflush(0);

   return self;

}

/////////////////////////////////////////////////////////////////////
//
// sendScenarioCountToParam
//
/////////////////////////////////////////////////////////////////////
- sendScenarioCountToParam: (const char *) newParam
                   inClass: (Class) paramClass {
   struct updateVar *aScenarioCounter;

   //fprintf(stdout, "ScenarioIterator >>>> sendScenarioCountToParam >>>> BEGIN\n");
   //fflush(0);

   aScenarioCounter = (struct updateVar *) [scenarioIterZone alloc: sizeof(struct updateVar)];

   aScenarioCounter->updateClass = paramClass;
   aScenarioCounter->varProbe = [probeLibrary getProbeForVariable: newParam inClass: paramClass];
 

   [updateScenarioClassList addLast: (void *) aScenarioCounter];

   //xprint(aScenarioCounter->varProbe); 
   
   //fprintf(stdout, "ScenarioIterator >>>> sendScenarioCountToParam >>>> END\n");
   //fflush(0);

   return self;
}

/////////////////////////////////////////////////////////////////////
//
// sendReplicateCountToParam
//
/////////////////////////////////////////////////////////////////////
- sendReplicateCountToParam: (const char *) newParam
                    inClass: (Class) paramClass {
 
   struct updateVar *aReplicateCounter;

   //fprintf(stdout, "ScenarioIterator >>>> sendReplicateCountToParam >>>> BEGIN\n");
   //fflush(0);

   aReplicateCounter = (struct updateVar *) [scenarioIterZone alloc: sizeof(struct updateVar)];

   aReplicateCounter->updateClass = paramClass;
   aReplicateCounter->varProbe = [probeLibrary getProbeForVariable: newParam inClass: paramClass];

   [updateReplicateClassList addLast: (void *) aReplicateCounter];

   //xprint(aReplicateCounter->varProbe);

   //fprintf(stdout, "ScenarioIterator >>>> sendReplicateCountToParam >>>> END\n");
   //fflush(0);

   return self;
}

////////////////////////////////////////////
//
// updateClassScenarioCounts
// 
////////////////////////////////////////////
- updateClassScenarioCounts: (id) inObject 
{
  struct updateVar *anSCounter;

  //fprintf(stdout, "ScenarioIterator >>>> updateClassScenarioCounts >>>> BEGIN\n");
  //fflush(0);

  //xprint(updateScenarioClassList);
  //xprint(scenarioNdx);

  [scenarioNdx setLoc: Start];

  while(([scenarioNdx getLoc] != End) && ((anSCounter = (struct updateVar *) [scenarioNdx next]) != (struct updateVar *) nil))
  {
	  //fprintf(stdout, "ScenarioIterator >>>> updateClassScenarioCounts >>>> while >>>> varProbe = %p\n", anSCounter->varProbe);
	  //fflush(0);
	  //fprintf(stdout, "ScenarioIterator >>>> updateClassScenarioCounts >>>> while >>>> varProbe getProbedVar = %s\n", [anSCounter->varProbe getProbedVariable]);
	  //fflush(0);
	  //xprint(anSCounter->varProbe);

          if(getClass(inObject) != anSCounter->updateClass) 
          {
             continue;            
          }


          [anSCounter->varProbe setData: inObject To: &scenarioCount];
  }

  fprintf(stdout, "ScenarioIterator >>>> updateClassScenarioCounts >>>> END\n");
  fflush(0);

  return self;
}


///////////////////////////////////////////////
//
// updateClassreplicateCounts
//
///////////////////////////////////////////////
- updateClassReplicateCounts: (id) inObject 
{
  struct updateVar *anRCounter;

  fprintf(stdout, "ScenarioIterator >>>> updateClassReplicateCounts >>>> BEGIN\n");
  fflush(0);


  [replicateNdx setLoc: Start];

  while(([replicateNdx getLoc] != End) && ( (anRCounter = (struct updateVar *) [replicateNdx next]) != (struct updateVar *) nil))
  {
          if(getClass(inObject) != anRCounter->updateClass) continue;            

          [anRCounter->varProbe setData: inObject To: &replicateCount];
  }

  fprintf(stdout, "ScenarioIterator >>>> updateClassReplicateCounts >>>> END\n");
  fflush(0);

  return self;
}

- calcStep {

    return self;

}

@end

