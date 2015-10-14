/* Copyright (c) 1996-2014 Clickteam
*
* This source code is part of the iOS exporter for Clickteam Multimedia Fusion 2
* and Clickteam Fusion 2.5.
* 
* Permission is hereby granted to any person obtaining a legal copy 
* of Clickteam Multimedia Fusion 2 or Clickteam Fusion 2.5 to use or modify this source 
* code for debugging, optimizing, or customizing applications created with 
* Clickteam Multimedia Fusion 2 and/or Clickteam Fusion 2.5. 
* Any other use of this source code is prohibited.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
* IN THE SOFTWARE.
*/

#import <Foundation/Foundation.h>
#import "CRunExtension.h"
#import "CPoint.h"

@class CFile;
@class CCreateObjectInfo;
@class CValue;
@class CCndExtension;
@class CArrayList;
@class CObject;
@class ObjectSelection;

@class CellMap;
@class Boid;

typedef NSMutableArray CellType;

#define FLOCK_BOIDTYPES 100
#define FLOCK_BOIDLOOPS 10

struct BoidType
{
	float idleSpeed, minSpeed, maxSpeed, acceleration, deceleration, turnSpeed;
	float viewRadius, avoidanceRadius;
	float movementRandomization;
	float separationWeight, alignmentWeight, cohesionWeight;
	char angleDirSetting;
	BOOL avoidObstacles;
	BOOL speedDependantTurn;
	float viewRadiusSquared, avoidanceRadiusSquared;
};

@interface CRunFlocking : CRunExtension
{
@public
	//Mapping from a cell into a number of Boids in that cell.
	CellMap* cells;
	int	cellsize;
	int numLoops;
	struct BoidType boidtypes[FLOCK_BOIDTYPES];
	NSString* boidLoops[FLOCK_BOIDLOOPS];
	Boid* loopedBoid;
	Boid* centerBoid;
	NSMutableSet* objectSet;
	NSMutableArray* boidBuffer;
}
-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(void)destroyRunObject:(BOOL)bFast;
-(BOOL)condition:(int)num withCndExtension:(CCndExtension *)cnd;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(CValue*)expression:(int)num;

-(float)rotateTowardsFromAngle:(float)angle toAngle:(float)targetAngle withSpeed:(float)speed;
-(void)loopNeighbourBoids:(NSString*)loopname withBoid:(Boid*)boid andRadius:(int)radius;
-(CPoint)tracePositionAtLayer:(int)layer pointA:(CPoint)a pointB:(CPoint)b;

@end

@interface Boid : NSObject
{
@public
	CObject* bObject;
	int fixedValue;
	int boidType;
	int cellX, cellY;
	float x, y;
	float oldX, oldY;
	float speed, oldSpeed;
	float dirAngle, dirX, dirY;
	float sepX, sepY, cohX, cohY, aliX, aliY;
	float forceX, forceY;
	float targetX, targetY, targetDistance;
	int sepNeighbourCount;
	int aliCohNeighbourCount;
}
-(id)initWithObject:(CObject*)object asBoidType:(int)type andCellSize:(int)cellSize;
@end

@interface CellMap : NSObject
{
@public
	CellType** table;
	int tCapacity;
	int tCellSize;
	int primeA;
	int primeB;
}
-(id)initWithCapacity:(int)capacity andCellSize:(int)cellSize;
-(void)dealloc;
-(int)indexForX:(int)x andY:(int)y;
-(CellType*)cellForX:(int)x andY:(int)y;
-(CellType*)putBoid:(Boid*)boid;
-(void)removeBoid:(Boid*)boid;
-(Boid*)findBoidForObject:(CObject*)object;

@end