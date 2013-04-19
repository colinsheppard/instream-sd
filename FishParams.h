//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 


#import <defobj.h>

#import <objectbase/SwarmObject.h>
#import <objectbase.h>
#import <string.h>
#import "ZoneAllocMapper.h"



#undef LARGEINT
#define LARGEINT 2147483647

#ifndef TRUE
#define TRUE 1
#endif
#ifndef FALSE
#define FALSE 0
#endif



@interface FishParams: SwarmObject
{

@private
id <Zone> fishParamZone;
char anInitString[3];
int* anInitInt;
double* anInitFloat;
double* anInitDouble;
id anInitId;

id <CompleteVarMap> probeMap;

char* parameterFileName;

char instanceName[50];

int speciesIndex;
id <Symbol> fishSpecies;

@public

// THE FOLLOWING VARIABLES ARE INITIALIZED BY THE
// FISH .Params FILE.
// ADD NEW CONSTANTS HERE.
// 
// CAUTION: If this file is modified in any way the user
//          MUST "make clean" and then remake the executable 
//
//
// Added these 11/27/98 sj
// And I replaced them 6/3/1999 SFR


double fishMoveDistParamA;
double fishMoveDistParamB;

double fishCmaxParamA;
double fishCmaxParamB;
double fishCmaxTempF1;
double fishCmaxTempF2;
double fishCmaxTempF3;
double fishCmaxTempF4;
double fishCmaxTempF5;
double fishCmaxTempF6;
double fishCmaxTempF7;
double fishCmaxTempT1;
double fishCmaxTempT2;
double fishCmaxTempT3;
double fishCmaxTempT4;
double fishCmaxTempT5;
double fishCmaxTempT6;
double fishCmaxTempT7;
double fishEnergyDensity;
double fishFecundParamA;
double fishFecundParamB;
double fishFitnessHorizon;

double fishReactParamA;
double fishReactParamB;
double fishReactParamC;
double fishReactParamD;
double fishRespParamA;
double fishRespParamB;
double fishRespParamC;
double fishRespParamD;
double fishShelterSpeedFrac;
double fishSearchArea;
int   fishSpawnMinAge;
double fishSpawnDSuitD1;
double fishSpawnDSuitD2;
double fishSpawnDSuitD3;
double fishSpawnDSuitD4;
double fishSpawnDSuitD5;
double fishSpawnDSuitS1;
double fishSpawnDSuitS2;
double fishSpawnDSuitS3;
double fishSpawnDSuitS4;
double fishSpawnDSuitS5;
double fishSpawnEggViability;
char * fishSpawnEndDate;
double fishSpawnMaxFlowChange;
double fishSpawnMaxTemp;
double fishSpawnMinCond;
double fishSpawnMinLength;
double fishSpawnMinTemp;
double fishSpawnProb;
char * fishSpawnStartDate;
double fishSpawnVSuitS1;
double fishSpawnVSuitS2;
double fishSpawnVSuitS3;
double fishSpawnVSuitS4;
double fishSpawnVSuitS5;
double fishSpawnVSuitS6;
double fishSpawnVSuitV1;
double fishSpawnVSuitV2;
double fishSpawnVSuitV3;
double fishSpawnVSuitV4;
double fishSpawnVSuitV5;
double fishSpawnVSuitV6;
double fishSpawnWtLossFraction;
double fishSwimParamA;
double fishSwimParamB;
double fishWeightParamA;
double fishWeightParamB;


double fishTurbidMin;
double fishTurbidParamA;
double fishTurbidParamB;


double mortFishAqPredDayMin;
double mortFishAqPredNightMin;
double mortFishAqPredD1;
double mortFishAqPredD9;
double mortFishAqPredL1;
double mortFishAqPredL9;
double mortFishAqPredP9;
double mortFishAqPredP1;
double mortFishAqPredT1;
double mortFishAqPredT9;
double mortFishAqPredU1;
double mortFishAqPredU9;
double mortFishAqPredCoverFactor;

double mortFishHiTT1;
double mortFishHiTT9;
/* Not used in instream-SD: */
/*double mortFishTerrPredF1;*/
/*double mortFishTerrPredF9;*/
/*double mortFishAqPredMin;*/
/*double mortFishAqPredF1;*/
/*double mortFishAqPredF9;*/


double mortFishConditionK1;
double mortFishConditionK9;
double mortFishSpawn;
double mortFishStrandD1;
double mortFishStrandD9;

double mortFishTerrPredT1;
double mortFishTerrPredT9;
double mortFishTerrPredD1;
double mortFishTerrPredD9;
//double mortFishTerrPredF1;
//double mortFishTerrPredF9;
double mortFishTerrPredL1;
double mortFishTerrPredL9;
double mortFishTerrPredDayMin;
double mortFishTerrPredNightMin;
double mortFishTerrPredV1;
double mortFishTerrPredV9;
double mortFishVelocityV1;
double mortFishVelocityV9;
double mortFishVelocityCoverFactor;
double mortFishTerrPredH1;
double mortFishTerrPredH9;
double mortFishTerrPredCoverFactor;

double mortReddDewaterSurv;
double mortReddHiTT1;
double mortReddHiTT9;
double mortReddLoTT1;
double mortReddLoTT9;


double mortReddShearParamA;
double mortReddShearParamB;
double mortReddScourDepth;


double reddDevelParamA;
double reddDevelParamB;
double reddDevelParamC;
double reddNewLengthMean;
double reddNewLengthStdDev;
double reddSize;

//
// Angling and hooking mortality
//
double mortFishAngleSuccess;
//double mortFishAngleFishCoef;
double mortFishAngleL1;
double mortFishAngleL9;
double mortFishAngleSlotLower;
double mortFishAngleSlotUpper;
double mortFishAngleFracKeptLegal;
double mortFishAngleFracKeptIllegal;
double mortFishAngleHookSurvRate;

double fishPiscivoryLength;

double fishReactDistNightFactor;
double fishSearchNightFactor;

double fishMovePenaltyTime;

//END CONSTANTS INITIALIZED BY THE FISH .Params FILE

}


+ createBegin: aZone;
- createEnd;
- setInstanceName: (char *) anInstanceName;
- (char *) getInstanceName;

- setFishSpeciesIndex: (int) aSpeciesIndex;
- (int) getFishSpeciesIndex;
- setFishSpecies: (id <Symbol>) aFishSpecies;
- (id <Symbol>) getFishSpecies;

- (void) printSelf;

- (void) drop;
@end



