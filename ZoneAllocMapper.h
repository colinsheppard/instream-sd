//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 


#import <simtools.h>
#import <defobj.h>
#import <defobj/Create.h>
#import <defobj/defalloc.h> // mapAlloc


@interface ZoneAllocMapper: CreateDrop
{
  size_t size;
  void *block;
}

+ (void *) allocBlockIn: aZone             //return block that was created
                  ofSize: (size_t) aSize;
- (void)mapAllocations: (mapalloc_t)mapalloc;

- (void) drop;
@end

