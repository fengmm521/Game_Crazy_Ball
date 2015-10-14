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

#import "CRunFlocking.h"
#import "CExtension.h"
#import "CActExtension.h"
#import "CCndExtension.h"
#import "CCreateObjectInfo.h"
#import "CRunApp.h"
#import "CRun.h"
#import "CValue.h"
#import "CArrayList.h"
#import "ObjectSelection.h"
#import "CEventProgram.h"
#import "CServices.h"
#import "CRCom.h"
#import "CObject.h"
#import "CRunFrame.h"
#import "CColMask.h"
#import "CoreMath.h"

@implementation CRunFlocking
	
#define CON_ONLOOPEDBOID						0
#define CON_LAST								1

#define ACT_ADDOBJECTASBOID						0
#define ACT_REMOVEOBJECT						1
#define ACT_SETIDLESPEED						2
#define ACT_SETMINSPEED							3
#define ACT_SETMAXSPEED							4
#define ACT_SETACCELERATION						5
#define ACT_SETDECELERATION						6
#define ACT_SETTURNSPEED						7
#define ACT_SETVIEWRADIUS						8
#define ACT_SETAVOIDANCERADIUS					9
#define ACT_SETMOVEMENTRANDOMIZATION			10
#define ACT_SETSEPARATIONWEIGHT					11
#define ACT_SETALIGNMENTWEIGHT					12
#define ACT_SETCOHESIONWEIGHT					13
#define ACT_SETANGLEDIRSETTING					14
#define ACT_SETSPEEDDEPENDANTTURN				15
#define ACT_SETAVOIDOBSTACLES					16
#define ACT_ALLOFTYPE_ATTRACTTOWARDSPOSITION	17
#define ACT_ALLOFTYPE_CHASEAWAYFROMPOSITION		18
#define ACT_ALLOFTYPE_APPLYFORCE				19
#define ACT_WITHINRADIUS_ATTRACTTOWARDPOSITION	20
#define ACT_WITHINRADIUS_CHASEAWAYFROMPOSITION	21
#define ACT_WITHINRADIUS_APPLYFORCE				22
#define ACT_SINGLEBOID_ATTRACTTOWARDSPOSITION	23
#define ACT_SINGLEBOID_CHASEAWAYFROMPOSITION	24
#define ACT_SINGLEBOID_APPLYFORCE				25
#define ACT_LOOPNEIGHBOURBOIDS					26
#define ACT_LOOPBOIDSINRADIUS					27
#define ACT_LOOPBOIDSINRECTANGLE				28
#define ACT_LOOPALLBOIDS						29
#define ACT_LOOPALLOFTYPE						30

#define EXP_FROMBOIDTYPE_GETIDLESPEED			0
#define EXP_FROMBOIDTYPE_GETMINSPEED			1
#define EXP_FROMBOIDTYPE_GETMAXSPEED			2
#define EXP_FROMBOIDTYPE_GETACCELERATION		3
#define EXP_FROMBOIDTYPE_GETDECELERATION		4
#define EXP_FROMBOIDTYPE_GETTURNSPEED			5
#define EXP_FROMBOIDTYPE_GETBOIDVIEWRADIUS		6
#define EXP_FROMBOIDTYPE_GETAVOIDANCERADIUS		7
#define EXP_FROMBOIDTYPE_GETRANDOMIZATION		8
#define EXP_FROMBOIDTYPE_GETVIEWRADIUS			9
#define EXP_FROMBOIDTYPE_GETSEPARATIONWEIGHT	10
#define EXP_FROMBOIDTYPE_GETALIGNMENTWEIGHT		11
#define EXP_FROMBOIDTYPE_GETCOHESIONWEIGHT		12
#define EXP_FROMOBJECT_GETANGLE					13
#define EXP_FROMOBJECT_GETSPEED					14
#define EXP_FROMOBJECT_GETXSPEED				15
#define EXP_FROMOBJECT_GETYSPEED				16
#define EXP_FROMOBJECT_GETTARGETX				17
#define EXP_FROMOBJECT_GETTARGETY				18
#define EXP_LOOPCURRENT_GETANGLE				19
#define EXP_LOOPCURRENT_GETSPEED				20
#define EXP_LOOPCURRENT_GETXSPEED				21
#define EXP_LOOPCURRENT_GETYSPEED				22
#define EXP_LOOPCURRENT_GETTARGETX				23
#define EXP_LOOPCURRENT_GETTARGETY				24

#define ANGLE_SETTING				0
#define DIR_SETTING					1
#define NODIR_SETTING				2

-(int)getNumberOfConditions
{
	return CON_LAST;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	cellsize = [file readAInt];
	struct BoidType defaultBoidType;
	[file readACharBuffer:(char*)&defaultBoidType withLength:sizeof(struct BoidType) - sizeof(float)*2];
	defaultBoidType.viewRadiusSquared = defaultBoidType.viewRadius*defaultBoidType.viewRadius;
	defaultBoidType.avoidanceRadiusSquared = defaultBoidType.avoidanceRadius*defaultBoidType.avoidanceRadius;
	
	for(int i=0; i<FLOCK_BOIDTYPES; ++i)
		boidtypes[i] = defaultBoidType;
	
	objectSet = [[NSMutableSet alloc] init];
	cells = [[CellMap alloc] initWithCapacity:200 andCellSize:cellsize];
	boidBuffer = [[NSMutableArray alloc] init];
	numLoops = 0;
	memset(&boidLoops, 0, sizeof(NSString*));
	return YES;
}

-(void)destroyRunObject:(BOOL)bFast
{
	[objectSet release];
	[cells release];
	[boidBuffer release];
}

-(int)handleRunObject
{
	//Erases all nonexistant objects
	for(Boid* boid in objectSet)
	{
		CObject* object = [ho getObjectFromFixed:boid->fixedValue];
		boid->bObject = object;
		if(object == nil)
			[boidBuffer addObject:boid];
	}
	for(Boid* boid in boidBuffer)
	{
		[objectSet removeObject:boid];
		[cells removeBoid:boid];
	}
	[boidBuffer removeAllObjects];
		
	//Begin iterate all boids
	for(Boid* boid in objectSet)
	{
		struct BoidType boidtype = boidtypes[boid->boidType];
		CObject* object = boid->bObject;
				
		// Separation: steer to avoid crowding local flockmates
		// Alignment:  steer towards the average heading of local flockmates
		// Cohesion:   steer to move toward the average position of local flockmates
		
		boid->aliCohNeighbourCount = boid->sepNeighbourCount = 0;
		boid->cohX = 0.0f; boid->cohY = 0.0f;
		boid->aliX = 0.0f; boid->aliY = 0.0f;
		boid->sepX = 0.0f; boid->sepY = 0.0f;
		
		//Target position relative to the boid itself (cartesian coordinates)
		boid->targetX = 0.0f;
		boid->targetY = 0.0f;
		
		//Find all cells inside the radius:
		int startCellX = (int)floorf((boid->x - boidtype.viewRadius)/cellsize);
		int endCellX = (int)ceilf((boid->x + boidtype.viewRadius)/cellsize);
		int startCellY = (int)floorf((boid->y - boidtype.viewRadius)/cellsize);
		int endCellY = (int)ceilf((boid->y + boidtype.viewRadius)/cellsize);
		
		for(int y = startCellY; y<endCellY; ++y)
		{
			for(int x=startCellX; x<endCellX; ++x)
			{
				//Iterate through all objects in the cell:
				//=========================================
				CellType* cell = [cells cellForX:x andY:y];
				if(cell == nil)
					continue;
				
				for(Boid* neighbour in cell)
				{
					//avoid the checked boid testing itself
					if(neighbour->fixedValue != boid->fixedValue)
					{
						float dX = neighbour->x - boid->x;
						float dY = neighbour->y - boid->y;
						
						float distanceSquared = dX*dX + dY*dY;
						if(distanceSquared < boidtype.viewRadiusSquared)
						{
							if(neighbour->boidType == boid->boidType)
							{
								++boid->aliCohNeighbourCount;
								float influence = 1.0f - distanceSquared/boidtype.viewRadiusSquared;
								boid->cohX += (neighbour->x - boid->x) * influence;
								boid->cohY += (neighbour->y - boid->y) * influence;
								boid->aliX += neighbour->dirX * influence;
								boid->aliY += neighbour->dirY * influence;
							}
							if(distanceSquared < boidtype.avoidanceRadiusSquared)
							{
								//The closer to the boid, the faster it will escape in the opposite direction.
								++boid->sepNeighbourCount;
								float escapeFactor = 1.0f - distanceSquared/boidtype.avoidanceRadiusSquared;
								boid->sepX += (boid->x - neighbour->x) * escapeFactor;
								boid->sepY += (boid->y - neighbour->y) * escapeFactor;
							}
						}
					}
				}
			}
		}
		
		// Avoid obstacles
		if(boidtype.avoidObstacles)
		{
			float wallX = 0, wallY = 0;
			CPoint startpoint = CPointMake((int)boid->x, (int)boid->y);
			int countWalls = 0;
			
			for(int iangle=-132; iangle<132; iangle+=22)
			{
				float angle = degreesToRadians(boid->dirAngle+iangle);
				CPoint endpoint = CPointMake((int)(boid->x + cosf(angle)*boidtype.avoidanceRadius), (int)(boid->y + sinf(angle)*boidtype.avoidanceRadius));
				CPoint respoint = [self tracePositionAtLayer:object->hoLayer pointA:startpoint pointB:endpoint];
				
				if(respoint.x != endpoint.x || respoint.y != endpoint.y)
				{
					endpoint.x -= startpoint.x;
					endpoint.y -= startpoint.y;
					wallX += endpoint.x;
					wallY += endpoint.y;
					++countWalls;
				}
			}
			if(countWalls>0)
			{
				float distanceSquared = wallX*wallX + wallY*wallY;
				float escapeFactor = 1.0f - distanceSquared/boidtype.avoidanceRadiusSquared;
				
				++boid->sepNeighbourCount;
				boid->sepX += ((startpoint.x+wallX) - boid->x) * escapeFactor;
				boid->sepY += ((startpoint.y+wallY) - boid->y) * escapeFactor;
			}
		}
		
		//Divide all values with the number of neighbours to get the average
		float invNeighAliCoh = (boid->aliCohNeighbourCount > 0) ? 1.0f/boid->aliCohNeighbourCount : 1.0f;
		float invNeighSep = (boid->sepNeighbourCount > 0) ? 1.0f/boid->sepNeighbourCount : 1.0f;
		
		boid->aliX *= invNeighAliCoh; boid->aliY *= invNeighAliCoh;
		boid->cohX *= invNeighAliCoh; boid->cohY *= invNeighAliCoh;
		boid->sepX *= invNeighSep; boid->sepY *= invNeighSep;
		
		boid->targetX += boid->sepX * boidtype.separationWeight + boid->cohX * boidtype.cohesionWeight;
		boid->targetY += boid->sepY * boidtype.separationWeight + boid->cohY * boidtype.cohesionWeight;
		
		//Normalize average angle
		float aliDirLengthSquared = boid->aliX*boid->aliX + boid->aliY*boid->aliY;
		if(aliDirLengthSquared > 0.001f)
		{
			float invAliDirLength = Q_rsqrt(aliDirLengthSquared);
			boid->targetX += boid->aliX * invAliDirLength * boidtype.alignmentWeight;
			boid->targetY += boid->aliY * invAliDirLength * boidtype.alignmentWeight;
		}
	}
	
	//Loop over all boids to update their cell and position them on the screen.
	for(Boid* boid in objectSet)
	{
		struct BoidType boidtype = boidtypes[boid->boidType];
		CObject* object = boid->bObject;
		
		//Apply the external force and reset it
		boid->targetX += boid->forceX;
		boid->targetY += boid->forceY;
		boid->forceX = boid->forceY = 0.0f;
		boid->oldSpeed = boid->speed;
		
		//Apply movement randomization
		if(boidtype.movementRandomization > 0)
		{
			boid->targetX += ((rand()/(float)RAND_MAX)*2.0f-1.0f) *boidtype.movementRandomization;
			boid->targetY += ((rand()/(float)RAND_MAX)*2.0f-1.0f) *boidtype.movementRandomization;
		}
		
		//Calculate the vector length to the target position
		float invTargetDistance = Q_rsqrt(boid->targetX*boid->targetX + boid->targetY*boid->targetY);
		boid->targetDistance = MAX(1.0f/invTargetDistance, 0.00001f);
		
		//Update the direction information for the boid
		float newDirX = boid->targetX * invTargetDistance;
		float newDirY = boid->targetY * invTargetDistance;
		float newDirAngle = boid->dirAngle;
		if((newDirX > 0.0001f || newDirX < -0.0001f) || (newDirY > 0.0001f || newDirY < -0.0001f))
			newDirAngle = radiansToDegrees(atan2f(newDirY, newDirX));
		
		//Calculate dot product between the old direction and the target direction
		float cosO = boid->dirX*newDirX + boid->dirY*newDirY;
		bool targetIsBehind = cosO < 0;
		
		//Adjust speed based on target distance and which direction it is located in.
		if(cosO < -0.01f || cosO > 0.01f)
			boid->speed = boid->targetDistance * cosO;
		else
			boid->speed = boid->targetDistance;
		
		//Nothing to do? Set to idle speed
		bool hasNoTarget = boid->targetDistance < 0.001f;
		//bool targetInFront = boid->targetDistance > 0.001f && !targetIsBehind;
		if( hasNoTarget || (boidtype.idleSpeed > 0 && boid->speed > 0))
			boid->speed = MAX(boidtype.idleSpeed, boid->speed);
		
		//Fix for objects getting stuck if they cannot reverse while their target is behind them
		if(targetIsBehind && boidtype.speedDependantTurn && boidtype.minSpeed >= 0)
			boid->speed = boid->targetDistance;
		
		//Compensate for acceleration and deceleration
		float deltaSpeed = boid->speed - boid->oldSpeed;
		if(deltaSpeed > 0 && deltaSpeed > boidtype.acceleration)
			boid->speed = MIN(boid->speed, boid->oldSpeed+boidtype.acceleration);
		else if(deltaSpeed < 0 && deltaSpeed < -boidtype.deceleration )
			boid->speed = MAX(boid->speed, boid->oldSpeed-boidtype.deceleration);
		
		//Min and Max speed
		boid->speed = (float)clampd(boid->speed, boidtype.minSpeed, boidtype.maxSpeed);
		
		//Turn towards target
		if(boid->targetDistance > 0.001f)
		{
			//Turn speed depends on the haste the boid has
			if(boidtype.speedDependantTurn)
			{
				float speedFactor = ABS((boid->speed+0.01f)/boidtype.maxSpeed);
				boid->dirAngle = [self rotateTowardsFromAngle:boid->dirAngle toAngle:newDirAngle withSpeed:boidtype.turnSpeed*speedFactor];
			}
			else	// Turn speed independant of boid speed
				boid->dirAngle = [self rotateTowardsFromAngle:boid->dirAngle toAngle:newDirAngle withSpeed:boidtype.turnSpeed];
			
			boid->dirX = cosf(degreesToRadians(boid->dirAngle));
			boid->dirY = sinf(degreesToRadians(boid->dirAngle));
		}
		
		//Check if the boid was manually moved since last frame and then update the internal position
		if(object->hoX != (int)boid->x || object->hoY != (int)boid->y)
		{
			boid->x = (float)object->hoX;
			boid->y = (float)object->hoY;
		}
		
		//Update old positions
		boid->oldX = boid->x;
		boid->oldY = boid->y;
		
		//Update positions
		boid->x += boid->dirX * boid->speed;
		boid->y += boid->dirY * boid->speed;
		
		//Push out of obstacle if it ended up inside:
		if(boidtype.avoidObstacles)
		{
			if ([rh->rhFrame bkdLevObjCol_TestPoint:(int)boid->x withY:(int)boid->y andLayer:object->hoLayer andPlane:CM_TEST_OBSTACLE])
			{
				int x = (int)boid->x;
				int y = (int)boid->y;
				int oX = (int)boid->oldX;
				int oY = (int)boid->oldY;
				int dX = x-oX;
				int dY = y-oY;
				//No previous position recorded, cannot reliably push out
				if( !(dX == 0 && dY == 0))
				{
					int distance = (int)ceilf(1.0f/Q_rsqrt((float)(dX*dX+dY*dY)));
					for(int i=0; i<distance; ++i)
					{
						float step = i/(float)distance;
						int testX = (int)(oX+dX*step);
						int testY = (int)(oY+dY*step);
						
						if (![rh->rhFrame bkdLevObjCol_TestPoint:testX withY:testY andLayer:object->hoLayer andPlane:CM_TEST_OBSTACLE])
						{
							boid->x = (float)testX;
							boid->y = (float)testY;
						}
						else
							break;
					}
				}
				
			}
		}
		
		//Count how many boids needs to be moved
		if((int)(boid->x/cellsize) != boid->cellX || (int)(boid->y/cellsize) != boid->cellY )
			[boidBuffer addObject:boid];
		
		//Reposition the object on screen and mark as changed to force a redraw.
		object->roc->rcChanged = YES;
		object->hoX = (int)boid->x;
		object->hoY = (int)boid->y;
		object->roc->rcCheckCollides = 1;
		
		//Store angle value
		switch(boidtype.angleDirSetting)
		{
			case ANGLE_SETTING:
				object->roc->rcAngle = 360.0f-boid->dirAngle;
				break;
			case DIR_SETTING:
				object->roc->rcDir = (int)((360.0f-boid->dirAngle)/11.25f);
				break;
		}
	}

	for(Boid* boid in boidBuffer)
	{
		//Boid moved cell, relocate!
		[cells removeBoid:boid];
		boid->cellX = (int)boid->x/cellsize;
		boid->cellY = (int)boid->y/cellsize;
		[cells putBoid:boid];
	}
	[boidBuffer removeAllObjects];
	return 0;
}

-(BOOL)condition:(int)num withCndExtension:(CCndExtension *)cnd
{
	if(numLoops == 0 || numLoops > 9)
		return NO;
	
	NSString* loopName = [cnd getParamExpString:rh withNum:0];
	short oi = [cnd getParamOi:rh withNum:1];
	
	NSString* currentLoop = boidLoops[numLoops-1];
	if(![loopName isEqualToString:currentLoop])
		return NO;
	
	CObject* object = [ho getObjectFromFixed:loopedBoid->fixedValue];
	if(object != nil && [object isOfType:oi])
	{
		rh->rhEvtProg->rh2ActionOn = YES;
		[rh->objectSelection selectOneObject:object];
		rh->rhEvtProg->rh2ActionOn = NO;
		return YES;
	}
	[rh->objectSelection selectNone:oi];
	return YES;
}

-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{
		case ACT_ADDOBJECTASBOID:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			int boidType = [act getParamExpression:rh withNum:1];
			if(object == nil)
				return;
			
			Boid* b = [[Boid alloc] initWithObject:object asBoidType:boidType andCellSize:cellsize];
			if([objectSet containsObject:b])
			{
				[b release];
				break;
			}
			[objectSet addObject:b];
			[cells putBoid:b];
			break;
		}
		case ACT_REMOVEOBJECT:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			if(object == nil)
				return;
			
			Boid* b = [cells findBoidForObject:object];
			if(b != nil)
			{
				[cells removeBoid:b];
				[objectSet removeObject:b];
				[b release];
			}
			break;
		}
		case ACT_SETIDLESPEED:
		{
			int index = [act getParamExpression:rh withNum:0];
			float value = (float)[act getParamExpDouble:rh withNum:1];
			if(index >= 0 && index < FLOCK_BOIDTYPES)
				boidtypes[index].idleSpeed = value;
			break;
		}
		case ACT_SETMINSPEED:
		{
			int index = [act getParamExpression:rh withNum:0];
			float value = (float)[act getParamExpDouble:rh withNum:1];
			if(index >= 0 && index < FLOCK_BOIDTYPES)
				boidtypes[index].minSpeed = value;
			break;
		}
		case ACT_SETMAXSPEED:
		{
			int index = [act getParamExpression:rh withNum:0];
			float value = (float)[act getParamExpDouble:rh withNum:1];
			if(index >= 0 && index < FLOCK_BOIDTYPES)
				boidtypes[index].maxSpeed = value;
			break;
		}
		case ACT_SETACCELERATION:
		{
			int index = [act getParamExpression:rh withNum:0];
			float value = (float)[act getParamExpDouble:rh withNum:1];
			if(index >= 0 && index < FLOCK_BOIDTYPES)
				boidtypes[index].acceleration = value;
			break;
		}
		case ACT_SETDECELERATION:
		{
			int index = [act getParamExpression:rh withNum:0];
			float value = (float)[act getParamExpDouble:rh withNum:1];
			if(index >= 0 && index < FLOCK_BOIDTYPES)
				boidtypes[index].deceleration = value;
			break;
		}
		case ACT_SETTURNSPEED:
		{
			int index = [act getParamExpression:rh withNum:0];
			float value = (float)[act getParamExpDouble:rh withNum:1];
			if(index >= 0 && index < FLOCK_BOIDTYPES)
				boidtypes[index].turnSpeed = value;
			break;
		}
		case ACT_SETVIEWRADIUS:
		{
			int index = [act getParamExpression:rh withNum:0];
			float value = (float)[act getParamExpDouble:rh withNum:1];
			if(index >= 0 && index < FLOCK_BOIDTYPES)
			{
				boidtypes[index].viewRadius = value;
				boidtypes[index].viewRadiusSquared = value*value;
			}
			break;
		}
		case ACT_SETAVOIDANCERADIUS:
		{
			int index = [act getParamExpression:rh withNum:0];
			float value = (float)[act getParamExpDouble:rh withNum:1];
			if(index >= 0 && index < FLOCK_BOIDTYPES)
			{
				boidtypes[index].avoidanceRadius = value;
				boidtypes[index].avoidanceRadiusSquared = value*value;
			}
			break;
		}
		case ACT_SETMOVEMENTRANDOMIZATION:
		{
			int index = [act getParamExpression:rh withNum:0];
			float value = (float)[act getParamExpDouble:rh withNum:1];
			if(index >= 0 && index < FLOCK_BOIDTYPES)
				boidtypes[index].movementRandomization = value;
			break;
		}
		case ACT_SETSEPARATIONWEIGHT:
		{
			int index = [act getParamExpression:rh withNum:0];
			float value = (float)[act getParamExpDouble:rh withNum:1];
			if(index >= 0 && index < FLOCK_BOIDTYPES)
				boidtypes[index].separationWeight = value;
			break;
		}
		case ACT_SETALIGNMENTWEIGHT:
		{
			int index = [act getParamExpression:rh withNum:0];
			float value = (float)[act getParamExpDouble:rh withNum:1];
			if(index >= 0 && index < FLOCK_BOIDTYPES)
				boidtypes[index].alignmentWeight = value;
			break;
		}
		case ACT_SETCOHESIONWEIGHT:
		{
			int index = [act getParamExpression:rh withNum:0];
			float value = (float)[act getParamExpDouble:rh withNum:1];
			if(index >= 0 && index < FLOCK_BOIDTYPES)
				boidtypes[index].cohesionWeight = value;
			break;
		}
		case ACT_SETANGLEDIRSETTING:
		{
			int index = [act getParamExpression:rh withNum:0];
			char value = (char)[act getParamExpression:rh withNum:1];
			if(index >= 0 && index < FLOCK_BOIDTYPES)
				boidtypes[index].angleDirSetting = value;
			break;
		}
		case ACT_SETSPEEDDEPENDANTTURN:
		{
			int index = [act getParamExpression:rh withNum:0];
			char value = (char)[act getParamExpression:rh withNum:1];
			if(index >= 0 && index < FLOCK_BOIDTYPES)
				boidtypes[index].speedDependantTurn = value;
			break;
		}
		case ACT_SETAVOIDOBSTACLES:
		{
			int index = [act getParamExpression:rh withNum:0];
			char value = (char)[act getParamExpression:rh withNum:1];
			if(index >= 0 && index < FLOCK_BOIDTYPES)
				boidtypes[index].avoidObstacles = (value != 0);
			break;
		}
		case ACT_ALLOFTYPE_ATTRACTTOWARDSPOSITION:
		{
			int type = [act getParamExpression:rh withNum:0];
			int posX = [act getParamExpression:rh withNum:1];
			int posY = [act getParamExpression:rh withNum:2];
			float weight = (float)[act getParamExpDouble:rh withNum:3];
			
			for(Boid* boid in objectSet)
			{
				if(boid->boidType == type)
				{
					float dX = boid->x - posX;
					float dY = boid->y - posY;
					float invDistance = Q_rsqrt(dX*dX+dY*dY);
					boid->forceX += (posX - boid->x) * invDistance * weight;
					boid->forceY += (posY - boid->y) * invDistance * weight;
				}
			}
			break;
		}
		case ACT_ALLOFTYPE_CHASEAWAYFROMPOSITION:
		{
			int type = [act getParamExpression:rh withNum:0];
			int posX = [act getParamExpression:rh withNum:1];
			int posY = [act getParamExpression:rh withNum:2];
			float weight = (float)[act getParamExpDouble:rh withNum:3];
			
			for(Boid* boid in objectSet)
			{
				if(boid->boidType == type)
				{
					float dX = boid->x - posX;
					float dY = boid->y - posY;
					float invDistance = Q_rsqrt(dX*dX+dY*dY);
					boid->forceX += (boid->x - posX) * invDistance * weight;
					boid->forceY += (boid->y - posY) * invDistance * weight;
				}
			}
			break;
		}
		case ACT_ALLOFTYPE_APPLYFORCE:
		{
			int type = [act getParamExpression:rh withNum:0];
			int forceX = [act getParamExpression:rh withNum:1];
			int forceY = [act getParamExpression:rh withNum:2];
			
			for(Boid* boid in objectSet)
			{
				if(boid->boidType == type)
				{
					boid->forceX += forceX;
					boid->forceY += forceY;
				}
			}
			break;
		}
		case ACT_WITHINRADIUS_ATTRACTTOWARDPOSITION:
		{
			int type = [act getParamExpression:rh withNum:0];
			int posX = [act getParamExpression:rh withNum:1];
			int posY = [act getParamExpression:rh withNum:2];
			int radius = [act getParamExpression:rh withNum:3];
			float weight = (float)[act getParamExpDouble:rh withNum:4];
			float radiusSquared = radius*(float)radius;
						
			float fcellsize = (float)cellsize;
			int startCellX = (int)floorf((posX - radius)/fcellsize);
			int endCellX = (int)ceilf((posX + radius)/fcellsize);
			int startCellY = (int)floorf((posY - radius)/fcellsize);
			int endCellY = (int)ceilf((posY + radius)/fcellsize);
			
			for(int y = startCellY; y<endCellY; ++y)
			{
				for(int x=startCellX; x<endCellX; ++x)
				{
					CellType* cell = [cells cellForX:x andY:y];
					for(Boid* boid in cell)
					{
						if(boid->boidType != type)
							continue;
						
						float dX = boid->x - posX;
						float dY = boid->y - posY;
						float distanceSquared = dX*dX+dY*dY;
						if(distanceSquared < radiusSquared)
						{
							float factor = 1.0f - (distanceSquared / radiusSquared);
							boid->forceX += (posX - boid->x) * factor * weight;
							boid->forceY += (posY - boid->y) * factor * weight;
						}
					}
				}
			}
			break;
		}
		case ACT_WITHINRADIUS_CHASEAWAYFROMPOSITION:
		{
			int type = [act getParamExpression:rh withNum:0];
			int posX = [act getParamExpression:rh withNum:1];
			int posY = [act getParamExpression:rh withNum:2];
			int radius = [act getParamExpression:rh withNum:3];
			float weight = (float)[act getParamExpDouble:rh withNum:4];
			
			float fcellsize = (float)cellsize;
			int startCellX = (int)floorf((posX - radius)/fcellsize);
			int endCellX = (int)ceilf((posX + radius)/fcellsize);
			int startCellY = (int)floorf((posY - radius)/fcellsize);
			int endCellY = (int)ceilf((posY + radius)/fcellsize);
			float radiusSquared = radius*(float)radius;
			
			for(int y = startCellY; y<endCellY; ++y)
			{
				for(int x=startCellX; x<endCellX; ++x)
				{
					CellType* cell = [cells cellForX:x andY:y];
					for(Boid* boid in cell)
					{
						if(boid->boidType != type)
							continue;
						
						float dX = boid->x-posX;
						float dY = boid->y-posY;
						float distanceSquared = dX*dX+dY*dY;
						if(distanceSquared < radiusSquared)
						{
							float factor = 1.0f - (distanceSquared / radiusSquared);
							boid->forceX += (boid->x - posX) * factor * weight;
							boid->forceY += (boid->y - posY) * factor * weight;
						}
					}
				}
			}
			break;
		}
		case ACT_WITHINRADIUS_APPLYFORCE:
		{
			int type = [act getParamExpression:rh withNum:0];
			int posX = [act getParamExpression:rh withNum:1];
			int posY = [act getParamExpression:rh withNum:2];
			int radius = [act getParamExpression:rh withNum:3];
			float forceX = (float)[act getParamExpDouble:rh withNum:4];
			float forceY = (float)[act getParamExpDouble:rh withNum:5];
			float radiusSquared = radius*(float)radius;
			
			float fcellsize = (float)cellsize;
			int startCellX = (int)floorf((posX - radius)/fcellsize);
			int endCellX = (int)ceilf((posX + radius)/fcellsize);
			int startCellY = (int)floorf((posY - radius)/fcellsize);
			int endCellY = (int)ceilf((posY + radius)/fcellsize);
			
			for(int y = startCellY; y<endCellY; ++y)
			{
				for(int x=startCellX; x<endCellX; ++x)
				{
					CellType* cell = [cells cellForX:x andY:y];
					for(Boid* boid in cell)
					{
						if(boid->boidType != type)
							continue;
						
						float dX = boid->x-posX;
						float dY = boid->y-posY;
						float distanceSquared = dX*dX+dY*dY;
						if(distanceSquared < radiusSquared)
						{
							float factor = 1.0f - (distanceSquared / radiusSquared);
							boid->forceX += forceX * factor;
							boid->forceY += forceY * factor;
						}
					}
				}
			}
			break;
		}
		case ACT_SINGLEBOID_ATTRACTTOWARDSPOSITION:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			int posX = [act getParamExpression:rh withNum:1];
			int posY = [act getParamExpression:rh withNum:2];
			float weight = [act getParamExpDouble:rh withNum:3];
			if(object == nil)
				break;
			
			Boid* boid = [cells findBoidForObject:object];
			if(boid != nil)
			{
				float dX = boid->x - posX;
				float dY = boid->y - posY;
				float invDistance = Q_rsqrt(dX*dX+dY*dY);
				boid->forceX += (posX - boid->x) * invDistance * weight;
				boid->forceY += (posY - boid->y) * invDistance * weight;
			}
			break;
		}
		case ACT_SINGLEBOID_CHASEAWAYFROMPOSITION:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			int posX = [act getParamExpression:rh withNum:1];
			int posY = [act getParamExpression:rh withNum:2];
			float weight = [act getParamExpDouble:rh withNum:3];
			if(object == nil)
				break;
			
			Boid* boid = [cells findBoidForObject:object];
			if(boid != nil)
			{
				float dX = boid->x - posX;
				float dY = boid->y - posY;
				float invDistance = Q_rsqrt(dX*dX+dY*dY);
				boid->forceX += (boid->x - posX) * invDistance * weight;
				boid->forceY += (boid->y - posY) * invDistance * weight;
			}
			break;
		}
		case ACT_SINGLEBOID_APPLYFORCE:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			float forceX = [act getParamExpDouble:rh withNum:1];
			float forceY = [act getParamExpDouble:rh withNum:2];
			if(object == nil)
				break;
			
			Boid* boid = [cells findBoidForObject:object];
			if(boid != nil)
			{
				boid->forceX += forceX;
				boid->forceY += forceY;
			}
			break;
		}
		case ACT_LOOPNEIGHBOURBOIDS:
		{
			NSString* loopname = [act getParamExpString:rh withNum:0];
			CObject* object = [act getParamObject:rh withNum:1];
			int radius = [act getParamExpression:rh withNum:2];
			if(object == nil)
				break;
			
			Boid* boid = [cells findBoidForObject:object];
			if(boid != nil)
				[self loopNeighbourBoids:loopname withBoid:boid andRadius:radius];
		
			loopedBoid = nil;
			break;
		}
		case ACT_LOOPBOIDSINRADIUS:
		{
			NSString* loopname = [act getParamExpString:rh withNum:0];
			int xPos = [act getParamExpression:rh withNum:1];
			int yPos = [act getParamExpression:rh withNum:2];
			int radius = [act getParamExpression:rh withNum:3];
			float radiusSquared = radius*(float)radius;
			if(numLoops > FLOCK_BOIDLOOPS)
				break;
			
			boidLoops[numLoops++] = [[NSString alloc] initWithString:loopname];
			float fCellsize = (float)cellsize;
			NSMutableArray* foundBoids = [[NSMutableArray alloc] init];
			
			int left = xPos-radius;
			int right = xPos+radius;
			int top = yPos-radius;
			int bottom = yPos+radius;
			
			int startCellX = (int)floorf(left/fCellsize);
			int endCellX = (int)ceilf(right/fCellsize);
			int startCellY = (int)floorf(top/fCellsize);
			int endCellY = (int)ceilf(bottom/fCellsize);
			
			for(int y = startCellY; y<endCellY; ++y)
			{
				for(int x=startCellX; x<endCellX; ++x)
				{
					CellType* cell = [cells cellForX:x andY:y];
					if(cell == nil)
						continue;
					for(Boid* boid in cell)
					{
						float xDist = xPos - boid->x;
						float yDist = yPos - boid->y;
						float distanceSquared = xDist*xDist + yDist*yDist;
						
						if(distanceSquared < radiusSquared)
							[foundBoids addObject:boid];
					}
				}
			}
			
			rh->rhEvtProg->rh2ActionOn = NO;
			for(Boid* lBoid in foundBoids)
			{
				loopedBoid = lBoid;
				[ho generateEvent:CON_ONLOOPEDBOID withParam:0];
			}
			rh->rhEvtProg->rh2ActionOn = YES;
			
			--numLoops;
			[boidLoops[numLoops] release];
			boidLoops[numLoops] = nil;
			[foundBoids release];
			loopedBoid = nil;
			break;
		}
		case ACT_LOOPBOIDSINRECTANGLE:
		{
			NSString* loopname = [act getParamExpString:rh withNum:0];
			int left = [act getParamExpression:rh withNum:1];
			int top = [act getParamExpression:rh withNum:2];
			int width = [act getParamExpression:rh withNum:3];
			int height = [act getParamExpression:rh withNum:4];
			if(numLoops > FLOCK_BOIDLOOPS)
				break;
			
			boidLoops[numLoops++] = [[NSString alloc] initWithString:loopname];
			float fCellsize = (float)cellsize;
			NSMutableArray* foundBoids = [[NSMutableArray alloc] init];
			
			int right = left+width;
			int bottom = top+height;
			
			int startCellX = (int)floorf(left/fCellsize);
			int endCellX = (int)ceilf(right/fCellsize);
			int startCellY = (int)floorf(top/fCellsize);
			int endCellY = (int)ceilf(bottom/fCellsize);
			
			for(int y = startCellY; y<endCellY; ++y)
			{
				for(int x=startCellX; x<endCellX; ++x)
				{
					CellType* cell = [cells cellForX:x andY:y];
					if(cell == nil)
						continue;
					for(Boid* boid in cell)
					{
						if( boid->x < left || boid->y < top || boid->x > right || boid->y > bottom )
							continue;
						[foundBoids addObject:boid];
					}
				}
			}
			
			rh->rhEvtProg->rh2ActionOn = NO;
			for(Boid* lBoid in foundBoids)
			{
				loopedBoid = lBoid;
				[ho generateEvent:CON_ONLOOPEDBOID withParam:0];
			}
			rh->rhEvtProg->rh2ActionOn = YES;
			
			--numLoops;
			[boidLoops[numLoops] release];
			boidLoops[numLoops] = nil;
			[foundBoids release];
			loopedBoid = nil;
			break;
		}
		case ACT_LOOPALLBOIDS:
		{
			NSString* loopname = [act getParamExpString:rh withNum:0];
			if(numLoops > FLOCK_BOIDLOOPS)
				break;
			
			boidLoops[numLoops++] = [[NSString alloc] initWithString:loopname];
			NSMutableArray* foundBoids = [[NSMutableArray alloc] initWithArray:[objectSet allObjects]];

			rh->rhEvtProg->rh2ActionOn = NO;
			for(Boid* lBoid in foundBoids)
			{
				loopedBoid = lBoid;
				[ho generateEvent:CON_ONLOOPEDBOID withParam:0];
			}
			rh->rhEvtProg->rh2ActionOn = YES;
			
			--numLoops;
			[boidLoops[numLoops] release];
			boidLoops[numLoops] = nil;
			[foundBoids release];
			loopedBoid = nil;
			break;
		}	
		case ACT_LOOPALLOFTYPE:
		{
			NSString* loopname = [act getParamExpString:rh withNum:0];
			int boidType = [act getParamExpression:rh withNum:1];
			if(numLoops > FLOCK_BOIDLOOPS)
				break;
			
			boidLoops[numLoops++] = [[NSString alloc] initWithString:loopname];
			NSMutableArray* foundBoids = [[NSMutableArray alloc] initWithArray:[objectSet allObjects]];
			
			rh->rhEvtProg->rh2ActionOn = NO;
			for(Boid* lBoid in foundBoids)
			{
				if(lBoid->boidType == boidType)
				{
					loopedBoid = lBoid;
					[ho generateEvent:CON_ONLOOPEDBOID withParam:0];
				}
			}
			rh->rhEvtProg->rh2ActionOn = YES;
			
			--numLoops;
			[boidLoops[numLoops] release];
			boidLoops[numLoops] = nil;
			[foundBoids release];
			loopedBoid = nil;
			break;
		}
	}
}


-(CValue*)expression:(int)num
{
	switch(num)
	{
		case EXP_FROMBOIDTYPE_GETIDLESPEED:
		{
			int boidType = [[ho getExpParam] getInt];
			if(boidType >= 0 && boidType < FLOCK_BOIDTYPES)
				return [rh getTempDouble:boidtypes[boidType].idleSpeed];
			break;
		}
		case EXP_FROMBOIDTYPE_GETMINSPEED:
		{
			int boidType = [[ho getExpParam] getInt];
			if(boidType >= 0 && boidType < FLOCK_BOIDTYPES)
				return [rh getTempDouble:boidtypes[boidType].minSpeed];
			break;
		}
		case EXP_FROMBOIDTYPE_GETMAXSPEED:
		{
			int boidType = [[ho getExpParam] getInt];
			if(boidType >= 0 && boidType < FLOCK_BOIDTYPES)
				return [rh getTempDouble:boidtypes[boidType].maxSpeed];
			break;
		}
		case EXP_FROMBOIDTYPE_GETACCELERATION:
		{
			int boidType = [[ho getExpParam] getInt];
			if(boidType >= 0 && boidType < FLOCK_BOIDTYPES)
				return [rh getTempDouble:boidtypes[boidType].acceleration];
			break;
		}
		case EXP_FROMBOIDTYPE_GETDECELERATION:
		{
			int boidType = [[ho getExpParam] getInt];
			if(boidType >= 0 && boidType < FLOCK_BOIDTYPES)
				return [rh getTempDouble:boidtypes[boidType].deceleration];
			break;
		}
		case EXP_FROMBOIDTYPE_GETTURNSPEED:
		{
			int boidType = [[ho getExpParam] getInt];
			if(boidType >= 0 && boidType < FLOCK_BOIDTYPES)
				return [rh getTempDouble:boidtypes[boidType].turnSpeed];
			break;
		}
		case EXP_FROMBOIDTYPE_GETBOIDVIEWRADIUS:
		{
			int boidType = [[ho getExpParam] getInt];
			if(boidType >= 0 && boidType < FLOCK_BOIDTYPES)
				return [rh getTempDouble:boidtypes[boidType].viewRadius];	//Why is this here twice?
			break;
		}
		case EXP_FROMBOIDTYPE_GETAVOIDANCERADIUS:
		{
			int boidType = [[ho getExpParam] getInt];
			if(boidType >= 0 && boidType < FLOCK_BOIDTYPES)
				return [rh getTempDouble:boidtypes[boidType].avoidanceRadius];
			break;
		}
		case EXP_FROMBOIDTYPE_GETRANDOMIZATION:
		{
			int boidType = [[ho getExpParam] getInt];
			if(boidType >= 0 && boidType < FLOCK_BOIDTYPES)
				return [rh getTempDouble:boidtypes[boidType].movementRandomization];
			break;
		}
		case EXP_FROMBOIDTYPE_GETVIEWRADIUS:
		{
			int boidType = [[ho getExpParam] getInt];
			if(boidType >= 0 && boidType < FLOCK_BOIDTYPES)
				return [rh getTempDouble:boidtypes[boidType].viewRadius];	//Why is this here twice?
			break;
		}
		case EXP_FROMBOIDTYPE_GETSEPARATIONWEIGHT:
		{
			int boidType = [[ho getExpParam] getInt];
			if(boidType >= 0 && boidType < FLOCK_BOIDTYPES)
				return [rh getTempDouble:boidtypes[boidType].separationWeight];
			break;
		}
		case EXP_FROMBOIDTYPE_GETALIGNMENTWEIGHT:
		{
			int boidType = [[ho getExpParam] getInt];
			if(boidType >= 0 && boidType < FLOCK_BOIDTYPES)
				return [rh getTempDouble:boidtypes[boidType].alignmentWeight];
			break;
		}
		case EXP_FROMBOIDTYPE_GETCOHESIONWEIGHT:
		{
			int boidType = [[ho getExpParam] getInt];
			if(boidType >= 0 && boidType < FLOCK_BOIDTYPES)
				return [rh getTempDouble:boidtypes[boidType].cohesionWeight];
			break;
		}
		case EXP_FROMOBJECT_GETANGLE:
		{
			int fixed = [[ho getExpParam] getInt];
			CObject* object = [ho getObjectFromFixed:fixed];
			if(object != nil)
			{
				Boid* b = [cells findBoidForObject:object];
				if(b != nil)
					return [rh getTempDouble:b->dirAngle];
			}
			break;
		}
		case EXP_FROMOBJECT_GETSPEED:
		{
			int fixed = [[ho getExpParam] getInt];
			CObject* object = [ho getObjectFromFixed:fixed];
			if(object != nil)
			{
				Boid* b = [cells findBoidForObject:object];
				if(b != nil)
					return [rh getTempDouble:b->speed];
			}
			break;
		}
		case EXP_FROMOBJECT_GETXSPEED:
		{
			int fixed = [[ho getExpParam] getInt];
			CObject* object = [ho getObjectFromFixed:fixed];
			if(object != nil)
			{
				Boid* b = [cells findBoidForObject:object];
				if(b != nil)
					return [rh getTempDouble:b->forceX];
			}
			break;
		}
		case EXP_FROMOBJECT_GETYSPEED:
		{
			int fixed = [[ho getExpParam] getInt];
			CObject* object = [ho getObjectFromFixed:fixed];
			if(object != nil)
			{
				Boid* b = [cells findBoidForObject:object];
				if(b != nil)
					return [rh getTempDouble:b->forceY];
			}
			break;
		}
		case EXP_FROMOBJECT_GETTARGETX:
		{
			int fixed = [[ho getExpParam] getInt];
			CObject* object = [ho getObjectFromFixed:fixed];
			if(object != nil)
			{
				Boid* b = [cells findBoidForObject:object];
				if(b != nil)
					return [rh getTempDouble:b->targetX];
			}
			break;
		}
		case EXP_FROMOBJECT_GETTARGETY:
		{
			int fixed = [[ho getExpParam] getInt];
			CObject* object = [ho getObjectFromFixed:fixed];
			if(object != nil)
			{
				Boid* b = [cells findBoidForObject:object];
				if(b != nil)
					return [rh getTempDouble:b->targetY];
			}
			break;
		}
		case EXP_LOOPCURRENT_GETANGLE:
		{
			if(loopedBoid != nil)
				return [rh getTempDouble:loopedBoid->dirAngle];
			break;
		}
		case EXP_LOOPCURRENT_GETSPEED:
		{
			if(loopedBoid != nil)
				return [rh getTempDouble:loopedBoid->speed];
			break;
		}
		case EXP_LOOPCURRENT_GETXSPEED:
		{
			if(loopedBoid != nil)
				return [rh getTempDouble:loopedBoid->forceX];
			break;
		}
		case EXP_LOOPCURRENT_GETYSPEED:
		{
			if(loopedBoid != nil)
				return [rh getTempDouble:loopedBoid->forceY];
			break;
		}
		case EXP_LOOPCURRENT_GETTARGETX:
		{
			if(loopedBoid != nil)
				return [rh getTempDouble:loopedBoid->targetX];
			break;
		}
		case EXP_LOOPCURRENT_GETTARGETY:
		{
			if(loopedBoid != nil)
				return [rh getTempDouble:loopedBoid->targetY];
			break;
		}
	}
	return [rh getTempDouble:0];
}

-(float)rotateTowardsFromAngle:(float)angle toAngle:(float)targetAngle withSpeed:(float)speed
{
	float diff = targetAngle - angle;
	float dist = ABS(diff);
	float direction = (diff > 0) ? 1.0f : -1.0f;
	if(dist > 180.0f)
		direction *= -1.0f;
	
	float ret = angle + direction*MIN(speed, dist);
	if(ret >= 360.0f)
		return ret-360.0f;
	else if(ret < 0.0f)
		return ret+360.0f;
	else
		return ret;
}

-(void)loopNeighbourBoids:(NSString*)loopname withBoid:(Boid*)boid andRadius:(int)radius
{
	if(numLoops >= FLOCK_BOIDLOOPS)
		return;
	
	boidLoops[numLoops++] = [[NSString alloc] initWithString:loopname];
	centerBoid = boid;
	
	int startCellX = (int)floorf((boid->x - radius)/cellsize);
	int endCellX = (int)ceilf((boid->x + radius)/cellsize);
	int startCellY = (int)floorf((boid->y - radius)/cellsize);
	int endCellY = (int)ceilf((boid->y + radius)/cellsize);
	float radiusSquared = radius*(float)radius;
	
	NSMutableArray* foundBoids = [[NSMutableArray alloc] init];
	
	for(int y = startCellY; y<endCellY; ++y)
	{
		for(int x=startCellX; x<endCellX; ++x)
		{
			CellType* cell = [cells cellForX:x andY:y];
			if(cell == nil)
				continue;
			
			for(Boid* neighbour in cell)
			{
				if(neighbour->fixedValue == boid->fixedValue)
					continue;
				
				float xDist = neighbour->x - boid->x;
				float yDist = neighbour->y - boid->y;
				float distanceSquared = xDist*xDist + yDist*yDist;
				
				if(distanceSquared >= radiusSquared)
					continue;
				
				[foundBoids addObject:neighbour];
			}
		}
	}
	
	rh->rhEvtProg->rh2ActionOn = NO;
	for(Boid* boid in foundBoids)
	{
		loopedBoid = boid;
		[ho generateEvent:CON_ONLOOPEDBOID withParam:0];
	}
	rh->rhEvtProg->rh2ActionOn = YES;
	
	//Free loop name again
	--numLoops;
	[boidLoops[numLoops] release];
	boidLoops[numLoops] = nil;
	[foundBoids release];
}

-(CPoint)tracePositionAtLayer:(int)layer pointA:(CPoint)a pointB:(CPoint)b
{
	//Optimization: Return if the endpoint isn't obstacle
	if (![rh->rhFrame bkdLevObjCol_TestPoint:b.x	withY:b.y andLayer:layer andPlane:CM_TEST_OBSTACLE])
		return b;
	
	int oX = a.x;
	int oY = a.y;
	int dX = b.x-oX;
	int dY = b.y-oY;
	int onX = a.x, onY = a.y;
	
	int distance = (int)ceilf(sqrtf(dX*dX+dY*dY));
	int lowerbound = 0;
	int upperbound = distance;
	int current = distance/2;
	float progress = 0.5f;
	
	//Push out, maximum 10 iterations
	for(int i=0; i<10; ++i)
	{
		int nX = (int)(oX+dX*progress);
		int nY = (int)(oY+dY*progress);
		
		//If it's done pusing out
		if(onX == nX && onY == nY)
			break;
		
		onX = nX;
		onY = nY;
	
		if (![rh->rhFrame bkdLevObjCol_TestPoint:nX withY:nY andLayer:layer andPlane:CM_TEST_OBSTACLE])
			lowerbound = current;
		else
			upperbound = current;
		
		current = (upperbound+lowerbound)/2;
		progress = current/(float)distance;
	}
	return CPointMake(onX, onY);
}

@end





@implementation Boid

-(id)initWithObject:(CObject*)object asBoidType:(int)type andCellSize:(int)cellSize
{
	if(self=[super init])
	{
		bObject = object;
		fixedValue = [object fixedValue];
		dirAngle = 360.0f - (float)object->roc->rcAngle;
		dirX	= cosf(degreesToRadians(dirAngle));
		dirY	= sinf(degreesToRadians(dirAngle));
		x		= (float)object->hoX;
		y		= (float)object->hoY;
		boidType= type;
		cellX	= object->hoX / cellSize;
		cellY	= object->hoY / cellSize;
		targetX = targetY = targetDistance = forceX = forceY = 0.0f;
	}
	return self;
}

-(NSUInteger)hash
{
	return fixedValue;
}

-(BOOL)isEqual:(id)object
{
	Boid* other = (Boid*)object;
	if(other->bObject != nil && bObject != nil && other->bObject == bObject)
		return YES;
	
	if(other->fixedValue == fixedValue)
		return YES;
	
	return NO;
}

-(NSString*)description
{
	return [NSString stringWithFormat:@"%@ [x,y]:[%f,%f] sep:[%f,%f] tar:[%f,%f] dir:[%f,%f] speed:%f", bObject,x,y,sepX,sepY,targetX,targetY,dirX,dirY,speed];
}

@end






@implementation CellMap

-(id)initWithCapacity:(int)capacity andCellSize:(int)cellSize
{
	self = [super init];
	if(self)
	{
		table = (CellType**)calloc(capacity, sizeof(CellType*));
		tCapacity = capacity;
		tCellSize = cellSize;
		primeA = 104537;
		primeB = 93103;
	}
	return self;
}

-(void)dealloc
{
	for(int i=0; i<tCapacity; ++i)
	{
		CellType* cell = table[i];
		if(cell != nil)
			[cell release];
	}
	free(table);
	[super dealloc];
}

-(CellType*)cellForX:(int)x andY:(int)y
{
	return table[[self indexForX:x andY:y]];
}

-(int)indexForX:(int)x andY:(int)y
{
	return abs((x*primeA + y*primeB) % tCapacity);
}

-(CellType*)putBoid:(Boid*)boid
{
	int index =[self indexForX:boid->cellX andY:boid->cellY];
	CellType* cell = table[index];
	if(cell == nil)
	{
		cell = [[CellType alloc] init];
		table[index] = cell;
	}
	[cell addObject:boid];
	return cell;
}

-(void)removeBoid:(Boid*)boid
{
	int index =[self indexForX:boid->cellX andY:boid->cellY];
	CellType* cell = table[index];
	if(cell != nil)
	{
		[cell removeObject:boid];
		if([cell count] == 0)
		{
			table[index] = nil;
			[cell release];
		}
	}
}

-(Boid*)findBoidForObject:(CObject*)object
{
	int cellX = object->hoX/tCellSize;
	int cellY = object->hoY/tCellSize;
	int index =[self indexForX:cellX andY:cellY];
	CellType* cell = table[index];
	int fixed = [object fixedValue];
	for(Boid* b in cell)
	{
		if(b->fixedValue == fixed)
			return b;
	}
	return nil;
}

@end
