//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 


#include <stdlib.h>

#import "FishParams.h"

@implementation FishParams

+  createBegin: aZone
{
  FishParams* fishParams=nil;

  Class superClass;   
  id <ProbeLibrary> superProbeLibrary=nil;  
  id <ProbeMap> superProbeMap=nil;  
  id supMapNdx;
  id <VarProbe> supProbe;
  id mapNdx;
  id aProbe;


  fishParams = [super createBegin: aZone];

  fishParams->fishParamZone = [Zone create: aZone];
  
  fishParams->parameterFileName = (char *) nil;

  fishParams->anInitInt = [fishParams->fishParamZone alloc: sizeof(int)];
  fishParams->anInitFloat = [fishParams->fishParamZone alloc: sizeof(double)];  //Change to double skj 6jun08
  fishParams->anInitDouble = [fishParams->fishParamZone alloc: sizeof(double)];
  fishParams->anInitId = [fishParams->fishParamZone alloc: sizeof(id)];

  fprintf(stdout, "CPMFishParams >>>> createBegin >>>>> fishParams->anInitId = %p\n", fishParams->anInitId);
  fflush(0);

  strncpy(fishParams->anInitString, "nil", 3);
  *(fishParams->anInitInt) = -LARGEINT;
  *(fishParams->anInitFloat) = (double) -LARGEINT;  //Chage to double skj 6jun08
  *(fishParams->anInitDouble) = (double) -LARGEINT;

  superClass = [[fishParams getClass] getSuperclass];

  fishParams->probeMap = [CompleteVarMap createBegin: fishParams->fishParamZone];
  [fishParams->probeMap setProbedClass: [fishParams getClass]];
  fishParams->probeMap = [fishParams->probeMap createEnd];

  fprintf(stdout, "BEFORE ----\n");
  fflush(0);

  //xprint(fishParams->probeMap); //Commented out 6Jun08 SKJ
 
  
  [fishParams->probeMap dropProbeForVariable: "fishParamZone"];
  [fishParams->probeMap dropProbeForVariable: "anInitString"];
  [fishParams->probeMap dropProbeForVariable: "anInitInt"];
  [fishParams->probeMap dropProbeForVariable: "anInitFloat"];
  [fishParams->probeMap dropProbeForVariable: "anInitDouble"];
  [fishParams->probeMap dropProbeForVariable: "anInitId"];
  [fishParams->probeMap dropProbeForVariable: "parameterFileName"];
  [fishParams->probeMap dropProbeForVariable: "instanceName"];

  //[fishParams->probeMap dropProbeForVariable: "probeLibrary"];
  [fishParams->probeMap dropProbeForVariable: "probeMap"];

  
  fprintf(stdout, "AFTER ----\n");
  fflush(0);
 

  superProbeLibrary = [ProbeLibrary createBegin: scratchZone];
  superProbeLibrary = [superProbeLibrary createEnd]; 
  superProbeMap = [superProbeLibrary getCompleteVarMapFor: superClass];

  supMapNdx = [superProbeMap begin: fishParams->fishParamZone];

  while(([supMapNdx getLoc] != End) && ((supProbe = [supMapNdx next]) != nil) )
  {
     if([fishParams->probeMap getProbeForVariable: [supProbe getProbedVariable]] != nil)
     {
         [fishParams->probeMap dropProbeForVariable: [supProbe getProbedVariable]];
         continue;
     }
  }
        
  [supMapNdx drop];

  [superProbeMap drop];  //Added 6Jun08 skj

  mapNdx = [(id <Map>) fishParams->probeMap begin: scratchZone];
  while(([mapNdx getLoc] != End) && ((aProbe = [mapNdx next]) != nil) )
  {


        switch ([aProbe getProbedType][0]) {
         

            case _C_CHARPTR:

                   [aProbe setData: fishParams ToString: (void *) fishParams->anInitString];
                   break;

            case _C_INT:

                  [aProbe setData: fishParams To: (void *) fishParams->anInitInt];
                  break;

            case _C_FLT:
                  [aProbe setData: fishParams To: (void *) fishParams->anInitFloat];
                  break;

            case _C_DBL:
                  [aProbe setData: fishParams To: (void *) fishParams->anInitDouble];
                  break;

            case _C_ID:
                  [aProbe setData: fishParams To: (void *) fishParams->anInitId];
                  break;

            default:
                  fprintf(stdout, "ERROR: FishParams >>>> createBegin >>>> cannot preset variable = %s\n", [aProbe getProbedVariable]);
                  fflush(0);
                  exit(1);
                  break;

            }



  }

 [mapNdx drop];

 
 return fishParams;

}

- createEnd
{

  id mapNdx;  
  id <VarProbe> aProbe;
  BOOL ERROR = FALSE;
  char buffer[300];

  fprintf(stderr, "FishParams >>>> createEnd >>>> BEGIN\n");
  fflush(0);


  mapNdx = [(id <Map>) probeMap begin: scratchZone];

  [mapNdx setLoc: Start];

  
  while(([mapNdx getLoc] != End) && ((aProbe = [mapNdx next]) != nil) )
  {
        switch ([aProbe getProbedType][0]) {
         

            case _C_CHARPTR:

                       [aProbe probeAsString: self Buffer: buffer];
 
                       if(strncmp(buffer, "nil", 3) == 0)
                       {
                           ERROR = TRUE;
                           fprintf(stderr, "ERROR: >>>> createEnd >>>> %s has not been initialized\n", [aProbe getProbedVariable]);
                           fflush(0);
                       } 
                       break;


             case _C_INT:

                      if([aProbe probeAsInt: self] == *anInitInt)
                      {
                               ERROR = TRUE;
                               fprintf(stderr, "ERROR: >>>> createEnd >>>> %s has not been initialized\n", [aProbe getProbedVariable]);
                               fflush(0);
                      } 
                      break;

            case _C_FLT:
                      if([aProbe probeAsDouble: self] == *anInitFloat)
                      {
                               ERROR = TRUE;
                               fprintf(stderr, "ERROR: >>>> createEnd >>>> %s has not been initialized\n", [aProbe getProbedVariable]);
                               fflush(0);
                      } 
                      break;

            case _C_DBL:
                      if([aProbe probeAsDouble: self] == *anInitDouble)
                      {
                               ERROR = TRUE;
                               fprintf(stderr, "ERROR: >>>> createEnd >>>> %s has not been initialized\n", [aProbe getProbedVariable]);
                               fflush(0);
                      } 
                      break;

            case _C_ID:
                      if([aProbe probeAsPointer: self] == *(id *) anInitId)
                      {
                               ERROR = TRUE;
                               fprintf(stderr, "ERROR: >>>> createEnd >>>> %s has not been initialized\n", [aProbe getProbedVariable]);
                               fprintf(stderr, "ERROR: >>>> createEnd >>>> %s has not been initialized %p\n", [aProbe getProbedVariable], anInitId);
                               fflush(0);
                      } 
                      break;
            default:
                     fprintf(stderr, "FishParams >>>> createEnd >>>> cannot test variable = %s\n", [aProbe getProbedVariable]);
                     fflush(0);
                     exit(1);
                     break;

            }



  }

 [mapNdx drop];


  //
  // Added the following drop 6jun08 skj
  //
  [fishParamZone free: anInitInt];
  [fishParamZone free: anInitFloat];
  [fishParamZone free: anInitDouble];
  [fishParamZone free: anInitId];


  if(ERROR) 
  {
     fprintf(stderr, "ERROR: FishParams >>>> createEnd >>>> Please check Fish Parameter input file\n");
     fflush(0);
     exit(1);
  }

  fprintf(stderr, "FishParams >>>> createEnd >>>> EXIT\n");
  fflush(0);
 
  return [super createEnd];
}


/////////////////////////////////////////////
//
// setInstanceName
//
////////////////////////////////////////////
- setInstanceName: (char *) anInstanceName
{
    strncpy(instanceName, anInstanceName, 50);
    return self;
}

- (char *) getInstanceName
{
    return instanceName;
}


- setFishSpeciesIndex: (int) aSpeciesIndex
{
   speciesIndex = aSpeciesIndex;
   return self;

}

- (int) getFishSpeciesIndex
{
   return speciesIndex;
}


- setFishSpecies: (id <Symbol>) aFishSpecies
{
    fishSpecies = aFishSpecies;
    return self;
}


- (id <Symbol>) getFishSpecies
{
    return fishSpecies;
}


- (void) printSelf 
{

  id mapNdx;  
  id <VarProbe> aProbe;
  char buffer[300];
  char outputFileName[25];

  FILE* filePtr = NULL;


  fprintf(stderr, "FishParams >>>> printSelf >>>> BEGIN\n");
  fflush(0);
 
  //sprintf(outputFileName, "Species%sParamCheck.out", [fishSpecies getName]);
  sprintf(outputFileName, "Species%dParamCheck.out", speciesIndex);

  if((filePtr = fopen(outputFileName, "w")) == NULL)
  {
     [InternalError raiseEvent: "ERROR: FishParams >>>> printSelf >>>> Cannot open outputFileName for writing\n", outputFileName];
  }



  mapNdx = [(id <Map>) probeMap begin: scratchZone];

  [mapNdx setLoc: Start];

  
  while(([mapNdx getLoc] != End) && ((aProbe = [mapNdx next]) != nil) )
  {

        switch ([aProbe getProbedType][0])
        {
         
            case _C_CHARPTR:
 
                       fprintf(filePtr, "FishParams >>>> %s = %s \n",
                                              [aProbe getProbedVariable],
                                              [aProbe probeAsString: self Buffer: buffer]);
                       fflush(0);
                       break;


             case _C_INT:

                       fprintf(filePtr, "FishParams >>>> %s = %d \n",
                                              [aProbe getProbedVariable],
                                              [aProbe probeAsInt: self]);
                       fflush(0);
                      
                      break;

            case _C_FLT:
                      fprintf(filePtr, "FishParams >>>> %s = %f \n",
                                                 [aProbe getProbedVariable],
                                                 [aProbe probeAsDouble: self]);
                      fflush(0);
                      break;

            case _C_DBL:
                           fprintf(filePtr, "FishParams >>>> %s = %f \n", [aProbe getProbedVariable],
                                                                             [aProbe probeAsDouble: self]);
                           fflush(0);
                           break;
            case _C_ID:
                           {
                               id obj = [aProbe probeObject: self];
                               if([obj respondsTo: @selector(getName)])
                               {
                                  fprintf(filePtr, "FishParams >>>> %s = %s \n", [aProbe getProbedVariable],
                                                                                    [[aProbe probeObject: self] getName]);
                                  fflush(0);
                                  break;
                               }
                               else
                               {
                                  fprintf(filePtr, "FishParams >>>> %s = %p \n", [aProbe getProbedVariable],
                                                                                    [[aProbe probeObject: self] getName]);
                                  fflush(0);
                                  break;
                               }
                            }

            default:
                     [InternalError raiseEvent: "FishParams >>>> printSelf >>>> cannot test variable = %s\n", [aProbe getProbedVariable]];
                     break;

        }

  }

  [mapNdx drop];


  fprintf(stderr, "FishParams >>>> printSelf >>>> EXIT\n");
  fflush(0);


}


- (void) drop
{
   fprintf(stdout, "FishParams >>>> drop >>>> BEGIN\n");
   fflush(0);

   [fishParamZone drop];
   [super drop];

   fprintf(stdout, "FishParams >>>> drop >>>> END\n");
   fflush(0);
}   



@end
