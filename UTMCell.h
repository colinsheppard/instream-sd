//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 



#include <math.h>
#include <stdlib.h>


#import <objectbase/SwarmObject.h>
#import <gui.h>
#import "ZoneAllocMapper.h"
#import "globals.h"
#import "InterpolationTableP.h"
#import "DayPhaseTypes.h"

struct PointStruct {
                          double x;
                          double y;
                        };

typedef struct PointStruct UTMPoint;

struct DisplayCoordStruct {
                          int x;
                          int y;
                        };

typedef struct DisplayCoordStruct DisplayPoint;

struct PixelCoordStruct {
                          unsigned int pixelX;
                          unsigned int pixelY;
                        };

typedef struct PixelCoordStruct PixelCoord;

@interface UTMCell : SwarmObject
{
  id cellZone;
  int utmCellNumber;

  int numberOfNodes;

  double utmCellArea;
  double utmCenterX;
  double utmCenterY;

  int cornerNode1;
  int cornerNode2;
  int cornerNode3;
  int cornerNode4;

  int** cornerNodeArray;

  double corner1UTMEasting;
  double corner1UTMNorthing;
  double corner2UTMEasting;
  double corner2UTMNorthing;
  double corner3UTMEasting;
  double corner3UTMNorthing;
  double corner4UTMEasting;
  double corner4UTMNorthing;

  UTMPoint** utmPointArray; 

  int corner1DisplayX;
  int corner1DisplayY;
  int corner2DisplayX;
  int corner2DisplayY;
  int corner3DisplayX;
  int corner3DisplayY;
  int corner4DisplayX;
  int corner4DisplayY;

  DisplayPoint** displayPointArray; 

  int midPointNode1;
  int midPointNode2;
  int midPointNode3;
  int midPointNode4;

  double midPoint1UTMEasting;
  double midPoint1UTMNorthing;
  double midPoint2UTMEasting;
  double midPoint2UTMNorthing;
  double midPoint3UTMEasting;
  double midPoint3UTMNorthing;
  double midPoint4UTMEasting;
  double midPoint4UTMNorthing;

  double minUTMEasting;
  double maxUTMNorthing;

  double minCellUTMEasting;
  double maxCellUTMEasting;
  double minCellUTMNorthing;
  double maxCellUTMNorthing;

  int minDisplayX;
  int maxDisplayX;
  int minDisplayY;
  int maxDisplayY;
  int displayCenterX;
  int displayCenterY;

  int utmRasterResolution;
  int utmRasterResolutionX;
  int utmRasterResolutionY;
  char* rasterColorVariable;

  int* utmCellPixelsX;
  int pixelArraySizeX;
  int* utmCellPixelsY;
  int pixelArraySizeY;

  PixelCoord** utmCellPixels;
  int pixelCount;

  int cellColor; 
  int boundaryColor; 
  int interiorColor; 
  BOOL tagCell;

  double nwUTMEasting;
  double nwUTMNorthing;
  double swUTMEasting;
  double swUTMNorthing;
  double seUTMEasting;
  double seUTMNorthing;
  double neUTMEasting;
  double neUTMNorthing;

  id <List> listOfAdjacentCells;

  id <InterpolationTable> velocityInterpolator;
  id <InterpolationTable> depthInterpolator;

  double utmCellDepth;
  double utmCellVelocity;
}

+ create: aZone;

- (id <Zone>) getUTMCellZone;

- setUTMCellNumber: (int) aUTMCellNumber;
- (int) getUTMCellNumber;

- setNumberOfNodes: (int) aNumberOfNodes;
- (int) getNumberOfNodes;
- (int **) getCornerNodeArray; 

- setCornerNodesWith: (int) aCornerNode1
         cornerNode2: (int) aCornerNode2
         cornerNode3: (int) aCornerNode3
         cornerNode4: (int) aCornerNode4;

- (int) getCornerNode1;
- (int) getCornerNode2;
- (int) getCornerNode3;
- (int) getCornerNode4;

- setCorner1UTMEasting: (double) aCoordinate;
- (double) getCorner1UTMEasting;
- setCorner1UTMNorthing: (double) aCoordinate;
- (double) getCorner1UTMNorthing;
- setCorner2UTMEasting: (double) aCoordinate;
- (double) getCorner2UTMEasting;
- setCorner2UTMNorthing: (double) aCoordinate;
- (double) getCorner2UTMNorthing;
- setCorner3UTMEasting: (double) aCoordinate;
- (double) getCorner3UTMEasting;
- setCorner3UTMNorthing: (double) aCoordinate;
- (double) getCorner3UTMNorthing;
- setCorner4UTMEasting: (double) aCoordinate;
- (double) getCorner4UTMEasting;
- setCorner4UTMNorthing: (double) aCoordinate;
- (double) getCorner4UTMNorthing;

- setCorner1DisplayX: (unsigned int) aDisplayX;
- setCorner1DisplayY: (unsigned int) aDisplayY;
- setCorner2DisplayX: (unsigned int) aDisplayX;
- setCorner2DisplayY: (unsigned int) aDisplayY;
- setCorner3DisplayX: (unsigned int) aDisplayX;
- setCorner3DisplayY: (unsigned int) aDisplayY;
- setCorner4DisplayX: (unsigned int) aDisplayX;
- setCorner4DisplayY: (unsigned int) aDisplayY;

- setMinDisplayX: (int) aMinDisplayX;
- setMaxDisplayX: (int) aMaxDisplayX;
- setMinDisplayY: (int) aMinDisplayY;
- setMaxDisplayY: (int) aMaxDisplayY;

- setMidPointNodesWith: (int) aMidPointNode1
         midPointNode2: (int) aMidPointNode2
         midPointNode3: (int) aMidPointNode3
         midPointNode4: (int) aMidPointNode4;

- (int) getMidPointNode1;
- (int) getMidPointNode2;
- (int) getMidPointNode3;
- (int) getMidPointNode4;

- setMidPoint1UTMEasting: (double) aCoordinate;
- (double) getMidPoint1UTMEasting;
- setMidPoint1UTMNorthing: (double) aCoordinate;
- (double) getMidPoint1UTMNorthing;
- setMidPoint2UTMEasting: (double) aCoordinate;
- (double) getMidPoint2UTMEasting;
- setMidPoint2UTMNorthing: (double) aCoordinate;
- (double) getMidPoint2UTMNorthing;
- setMidPoint3UTMEasting: (double) aCoordinate;
- (double) getMidPoint3UTMEasting;
- setMidPoint3UTMNorthing: (double) aCoordinate;
- (double) getMidPoint3UTMNorthing;
- setMidPoint4UTMEasting: (double) aCoordinate;
- (double) getMidPoint4UTMEasting;
- setMidPoint4UTMNorthing: (double) aCoordinate;
- (double) getMidPoint4UTMNorthing;

- setMinUTMEasting: (double) aCoordinate;
- setMaxUTMNorthing: (double) aCoordinate;

- setUTMRasterResolution: (int) aResolution;
- setUTMRasterResolutionX: (int) aResolutionX;
- setUTMRasterResolutionY: (int) aResolutionY;
- (int) getUTMRasterResolutionX;
- (int) getUTMRasterResolutionY;
- (int) getUTMRasterResolution;

-  setVelocityInterpolator: (id <InterpolationTable>) aVelocityInterpolator;
-  (id <InterpolationTable>) getVelocityInterpolator;
-  setDepthInterpolator: (id <InterpolationTable>) aDepthInterpolator;
-  (id <InterpolationTable>) getDepthInterpolator;

- createUTMCellCoordStructures;
- (UTMPoint **) getUTMPointArray; 
- createUTMCellPixels;
- (double) getUTMCellArea;
- (double) getUTMCenterX;
- (double) getUTMCenterY;

- calcUTMCellCentroid;

- createUTMAdjacentCellsFrom: (id <ListIndex>) habSpaceUTMCellListNdx;
- (id <List>) getListOfAdjacentCells;

- updateUTMCellDepthWith: (double) aFlow;
- (double) getUTMCellDepth;
- updateUTMCellVelocityWith: (double) aFlow;
- (double) getUTMCellVelocity;


- (BOOL) containsRasterX: (int) aRasterX andRasterY: (int) aRasterY;
- setUTMRasterColorVariable: (char *) aColorVariable;
//- drawSelfOn: (id <Raster>) aRaster;
- drawSelfOn: (id <Raster>) aRaster
   withPhase: (int) aPhase;


- tagUTMCell;
- unTagUTMCell;
- tagAdjacentCells;

- (void) drop;
@end




