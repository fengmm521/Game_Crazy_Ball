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
//----------------------------------------------------------------------------------
//
// CRunAdvPathMov: advanced path movement object
// fin 6th march 09
//
//----------------------------------------------------------------------------------
#import "CRunAdvPathMov.h"
#import "CFile.h"
#import "CObject.h"
#import "CCreateObjectInfo.h"
#import "CBitmap.h"
#import "CActExtension.h"
#import "CCndExtension.h"
#import "CRCom.h"
#import "CArrayList.h"
#import "CExtension.h"
#import "CRun.h"
#import "CValue.h"


// CLASSES SUPPLEMENTAIRES ///////////////////////////////////////////////////////////////////////

@implementation AdvPathMovJourney
-(id)initWithParam:(int)n
{
	Node=n;
	return self;
}
@end

@implementation AdvPathMovConnect    
-(id)initWithParam1:(int)PID andParam2:(float)Dist 
{
	PointID = PID;
	Distance = Dist;
	return self;
}
@end

@implementation AdvPathMovPoints
-(id)initWithParam1:(int)xx andParam2:(int)yy
{
	if(self = [super init])
	{
		X=xx;
		Y=yy;
		Connections=[[CArrayList alloc] init];
	}
	return self;
}
-(void)dealloc
{
	[Connections clearRelease];
	[Connections release];
	[super dealloc];
}
@end

@implementation AdvPathMovmyclass
-(id)init
{
	if(self = [super init])
	{
		myvector=[[CArrayList alloc] init];
		myjourney=[[CArrayList alloc] init];
	}
	return self;
}
-(void)dealloc
{
	[myvector clearRelease];
	[myvector release];
	[myjourney clearRelease];
	[myjourney clearRelease];
	[super dealloc];
}
@end

// MAIN CLASS /////////////////////////////////////////////////////////////////////////////
@implementation CRunAdvPathMov

-(int)getNumberOfConditions
{
	return 5;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	[file setUnicode:NO];
	mypointer = [[AdvPathMovmyclass alloc] init];
	ho->hoX = cob->cobX;
	ho->hoY = cob->cobY;
	[file skipBytes:4];
	ho->hoImgWidth = [file readAShort];
	ho->hoImgHeight = [file readAShort];
	speed = (float)[file readAInt] / 100.0f;
	xoffset = [file readAInt];
	yoffset = [file readAInt];
	ChangeX = [file readAByte] == 1 ? YES : NO;
	ChangeY = [file readAByte] == 1 ? YES : NO;
	ChangeDirection = [file readAByte] == 1 ? YES : NO;
	enableautostep = [file readAByte] == 1 ? YES : NO;
	
	return YES;
}

-(void)destroyRunObject:(BOOL)bFast
{
	[mypointer release];
}

-(int)handleRunObject
{
	if ([mypointer->myjourney size] == 1)
	{
		//	MessageBox(NULL,"Hi",NULL,NULL);
		//This is so the object is at the first point if its not moving->
		mypointer->JourneyIterator = (AdvPathMovJourney*)[mypointer->myjourney get:0];
		mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:mypointer->JourneyIterator->Node];
		x = mypointer->theIterator->X;
		y = mypointer->theIterator->Y;
		if( ChangeX == YES ){ myObject->hoX = x;}
		if( ChangeY == YES ){ myObject->hoY = y;}
		myObject->roc->rcChanged = YES;
	}
	if(ismoving == NO) { return 0; }
	if(enableautostep == NO){return 0;}
	distance += speed;
	
	int FirstNode = 0;
	int NextNode  = 0;
	BOOL connectfound = NO;
	
	while ((ismoving == YES) && (distance >= totaldist))
	{
		
		//Take away the distance travelled so far :)
		[mypointer->myjourney removeIndexRelease:0];
		
		////Calculate position ( for when it touches a new node )
		mypointer->JourneyIterator = (AdvPathMovJourney*)[mypointer->myjourney get:0];
		FirstNode = mypointer->JourneyIterator->Node;
		mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:FirstNode];
		x = mypointer->theIterator->X + xoffset;
		y = mypointer->theIterator->Y + yoffset;
		
		if(ChangeX == YES ){myObject->hoX = x;}
		if(ChangeY == YES ){myObject->hoY = y;}
		
		myObject->roc->rcChanged = YES;
		[ho generateEvent:CID_touchednewnod withParam:[ho getEventParam]];
		//callRunTimeFunction(rdPtr, RFUNCTION_GENERATEEVENT, 4, 0);
		
		if(([mypointer->myjourney size]) <= 1 || (muststop ==YES))
		{
			ismoving = NO;
			distance = 0;
			muststop = NO;
			totaldist = 0;
			[ho generateEvent:CID_Hasreachedend withParam:[ho getEventParam]];
			//callRunTimeFunction(rdPtr, RFUNCTION_GENERATEEVENT, 3, 0);
		}
		
		if(ismoving == YES) 
		{
			distance -= totaldist;
			
			//Set the iterator to the first journey step
			mypointer->JourneyIterator = (AdvPathMovJourney*)[mypointer->myjourney get:0];
			//Now we know what the current point has to be :)
			FirstNode = mypointer->JourneyIterator->Node;
			mypointer->JourneyIterator = (AdvPathMovJourney*)[mypointer->myjourney get:1];
			//Now we what what the next point is going to be :)
			NextNode = mypointer->JourneyIterator->Node;
			
			//now we select the first point
			mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:FirstNode];
			//Great->->->now we need to run through all the connections and find the right one
			for (int i = 0; i < [mypointer->theIterator->Connections size]; i++)
			{
				mypointer->theIterator->ConnectIterator = (AdvPathMovConnect*)[mypointer->theIterator->Connections get:i];
				if( mypointer->theIterator->ConnectIterator->PointID == NextNode)
				{
					totaldist = mypointer->theIterator->ConnectIterator->Distance;
					connectfound = YES;
				}
			}
			if(connectfound == NO )
			{
				ismoving = NO;
				distance = 0;
				muststop = NO;
				totaldist = 0;
			}
		}
	}
	
	if((ismoving == YES) && (distance != 0))
	{
		////Get points
		mypointer->JourneyIterator = (AdvPathMovJourney*)[mypointer->myjourney get:0];
		//Now we know what the current point has to be :)
		FirstNode = mypointer->JourneyIterator->Node;
		mypointer->JourneyIterator = (AdvPathMovJourney*)[mypointer->myjourney get:1];
		//Now we want what the next point is going to be :)
		NextNode = mypointer->JourneyIterator->Node;
		
		mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:FirstNode];
		int x1 = mypointer->theIterator->X;
		int y1 = mypointer->theIterator->Y;
		
		mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:NextNode];
		int x2 = mypointer->theIterator->X;
		int y2 = mypointer->theIterator->Y;
		int deltax= x2 - x1;
		int deltay= y2 - y1;
		
		/////Below need to go in main
		
		if(totaldist!= 0)
		{
			float myval = (float)(atan2((deltax+0.0),(deltay+0.0))/3.1415926535897932384626433832795 * 180.0);
			angle = (int)(180.0-myval);
		}
		
		
		///////////////////////////End
		/////Below need to go in main
		if(totaldist!=0)
		{
			x = (int)(x1 + deltax * (distance / totaldist )+ xoffset);
			y = (int)(y1 + deltay * (distance / totaldist )+ yoffset);
			if(ChangeX == YES ){myObject->hoX = x;}
			if(ChangeY == YES ){myObject->hoY = y;}
			
			if(ChangeDirection == YES )
			{
				int direction = (angle *32+180)/ 360;
				direction = 8-direction;
				if ( direction < 0){direction +=32;}
                //	return direction;
				myObject->roc->rcDir = direction;
			}
			myObject->roc->rcChanged = YES;
		}
	}
	return 0;
}

// Conditions
// --------------------------------------------------
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	switch (num)
	{
		case CID_ismoving:
			return ismoving;
		case CID_nodesconnected:
			return [self nodesconnected:[cnd getParamExpression:rh withNum:0] withParam1:[cnd getParamExpression:rh withNum:1]];
		case CID_isstopping:
			return muststop;
		case CID_Hasreachedend:
			return YES;
		case CID_touchednewnod:
			return YES;
	}
	return NO;//won't happen
}

-(BOOL)nodesconnected:(int)param1 withParam1:(int)param2
{
	param1--;
	param2--;
	if(param1 < 0||param2 < 0){return NO;}
	if((param1 >= [mypointer->myvector size]) || (param2 >= [mypointer->myvector size])){return NO;}
	
	//param1 contains the number inputed by the user
	//param2 contains the number inputed by the user
	mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:param1];
	for(int i = 0; i < [mypointer->theIterator->Connections size];	i++)
	{
		mypointer->theIterator->ConnectIterator = (AdvPathMovConnect*)[mypointer->theIterator->Connections get:i];
		if(mypointer->theIterator->ConnectIterator->PointID == param2)
		{
			return YES;
		}
	}
	return NO;
}

		
// Actions
// -------------------------------------------------
-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{
		case AID_creatpathnod:
			[self creatpathnod:[act getParamExpression:rh withNum:0] withParam1:[act getParamExpression:rh withNum:1]];
			break;
		case AID_removepathnod:
			[self removepathnod:[act getParamExpression:rh withNum:0]];
			break;
		case AID_Clearpath:
			[self Clearpath:[act getParamExpression:rh withNum:0]];
			break;
		case AID_Connectnods:
			[self Connectnods:[act getParamExpression:rh withNum:0] withParam1:[act getParamExpression:rh withNum:1] andParam2:[act getParamExpDouble:rh withNum:2]];
			break;
		case AID_Addnodjourney:
			[self Addnodjourney:[act getParamExpression:rh withNum:0]];
			break;
		case AID_Insertnodjourney:
			[self Insertnodjourney:[act getParamExpression:rh withNum:0] withParam1:[act getParamExpression:rh withNum:1]];
			break;
		case AID_Removelastnodjourney:
			[mypointer->myjourney removeIndexRelease:[mypointer->myjourney size] - 1];
			break;
		case AID_Deletenodjourney:
			[self Deletenodjourney:[act getParamExpression:rh withNum:0]];
			break;
		case AID_Findjourney:
			[self Findjourney:[act getParamExpression:rh withNum:0]];
			break;
		case AID_LoadPath:
//			[seld LoadPath:[act getParamExpString:rh withNum:0]];
			break;
		case AID_SavePath:
//			SavePath(act->getParamExpString(rh, 0));
			break;
		case AID_MovementStart:
			[self MovementStart];
			break;
		case AID_MovementStop:
			muststop = YES;
			break;
		case AID_MovementPause:
			ismoving = NO;
			break;
		case AID_Setspeed:
			[self Setspeed:[act getParamExpDouble:rh withNum:0]];
			break;
		case AID_Setobject:
			[self Setobject:[act getParamObject:rh withNum:0]];
			break;
		case AID_setXoffset:
			xoffset = [act getParamExpression:rh withNum:0];
			break;
		case AID_setYoffset:
			yoffset = [act getParamExpression:rh withNum:0];
			break;
		case AID_Enableautostep:
			enableautostep = YES;
			break;
		case AID_Disableautostep:
			enableautostep = YES;
			break;
		case AID_Forcemovexsteps:
			[self Forcemovexsteps:[act getParamExpDouble:rh withNum:0]];
			break;
		case AID_SetNodeX:
			[self SetNodeX:[act getParamExpression:rh withNum:0] withParam1:[act getParamExpression:rh withNum:1]];
			break;
		case AID_SetNodeY:
			[self SetNodeY:[act getParamExpression:rh withNum:0] withParam1:[act getParamExpression:rh withNum:1]];
			break;
		case AID_Disconnectnode:
			[self Disconnectnode:[act getParamExpression:rh withNum:0] withParam1:[act getParamExpression:rh withNum:1]];
			break;
		case AID_ClearJourney:
			[self ClearJourney];
			break;
		case AID_ChangeX:
			[self ChangeX:[act getParamExpression:rh withNum:0]];
			break;
		case AID_ChangeY:
			[self ChangeY:[act getParamExpression:rh withNum:0]];
			break;
		case AID_ChangeDirection:
			[self ChangeDirection:[act getParamExpression:rh withNum:0]];
			break;
	}
}

-(void) creatpathnod:(int)param1 withParam1:(int)param2
{
	[mypointer->myvector add:[[AdvPathMovPoints alloc] initWithParam1:param1 andParam2:param2]];
}

-(void) removepathnod:(int)param1
{
	if (distance != 0)
	{
		return;
	}
	if ([mypointer->myjourney size]!= 0)
	{
		return;
	}
	if (param1 < 1)
	{
		return;
	}
	if (param1 > [mypointer->myvector size])
	{
		return;
	}
	[mypointer->myvector removeIndexRelease:param1 - 1];
	int connectionspot;
	///Loop through all the vectors!
	
	for (int i = 0; i < [mypointer->myvector size]; i++)
	{
		mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:i];
		connectionspot = -1;
		for (int j = 0; j < [mypointer->theIterator->Connections size]; j++)
		{
			mypointer->theIterator->ConnectIterator = (AdvPathMovConnect*)[mypointer->theIterator->Connections get:j];
			connectionspot++;
			if (mypointer->theIterator->ConnectIterator->PointID == param1 - 1)
			{
				[mypointer->theIterator->Connections removeIndexRelease:connectionspot];
			}
			if (mypointer->theIterator->ConnectIterator->PointID >= param1 - 1)
			{
				mypointer->theIterator->ConnectIterator->PointID -= 1;
			}
		}
	}
}

-(void) remove:(CArrayList*)array withFrom:(int)from andTo:(int)to
{
	int i = from;
	while (i <= to)
	{
		[array removeIndex:from];
		i++;
	}
}

-(void) removeClear:(CArrayList*)array withFrom:(int)from andTo:(int)to
{
	int i = from;
	while (i <= to)
	{
		[array removeIndexRelease:from];
		i++;
	}
}

-(void) Clearpath:(int)param1
{
	////THIS IS ACTUALLY CLEAR JOURNEY
	if ([mypointer->myjourney size] < 2)
	{
		distance = 0;
		totaldist = 0;
		ismoving = NO;
		return;
	}
	if (param1 == 0)
	{
		[mypointer->myjourney clear];
		distance = 0;
		totaldist = 0;
		ismoving = NO;
		return;
	}
	if ((param1 == 1) && (distance == 0))
	{
		[self removeClear:mypointer->myjourney withFrom:1 andTo:[mypointer->myjourney size]];
		
		distance = 0;
		totaldist = 0;
	}
	
	if ((param1 == 1) && (distance > 0))
	{
		[self removeClear:mypointer->myjourney withFrom:2 andTo:[mypointer->myjourney size]];
	}
}

-(void)Connectnods:(int)p1 withParam1:(int)p2 andParam2:(double)p3
{
	p1--;
	p2--;
	/// Idiot Proof :P
	if (p1 < 0 || p2 < 0 || p1 >= [mypointer->myvector size] || p2 >= [mypointer->myvector size] || p1 == p2)
	{
		return;
	}
	//int myval = 0;
	/////Check for existing connections->
	mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:p1];
	
	for (int i = 0; i < [mypointer->theIterator->Connections size]; i++)
	{
		mypointer->theIterator->ConnectIterator = (AdvPathMovConnect*)[mypointer->theIterator->Connections get:i];
		
		if (mypointer->theIterator->ConnectIterator->PointID == p2)
		{
			[mypointer->theIterator->Connections removeObjectRelease:mypointer->theIterator->ConnectIterator];
		}
        //	myval ++;
	}
	
	/////
	//Get second vector
	mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:p2];
	int v2x = mypointer->theIterator->X;
	int v2y = mypointer->theIterator->Y;
	
	//Get first vector
	mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:p1];
	int v1x = mypointer->theIterator->X;
	int v1y = mypointer->theIterator->Y;
	int deltax = v2x - v1x;
	int deltay = v2y - v1y;
	float dist = (float) sqrt(deltax * deltax + deltay * deltay);
	float vectorentry = (float) (dist / p3);
	// now stick the data into the first vector
	if (p3 == 0)
	{
		p3 = 1;
	}
	[mypointer->theIterator->Connections add:[[AdvPathMovConnect alloc] initWithParam1:p2 andParam2:vectorentry]];
}

-(void) Addnodjourney:(int)param1
{
	if (param1 < 1 || param1 > [mypointer->myvector size])
	{
		return;
	}
	if ([mypointer->myjourney size] > 0)
	{
		mypointer->JourneyIterator = (AdvPathMovJourney*)[mypointer->myjourney get:[mypointer->myjourney size] - 1];
		if (param1 - 1 == mypointer->JourneyIterator->Node)
		{
			return;
		}
	}
	[mypointer->myjourney add:[[AdvPathMovJourney alloc] initWithParam:param1 - 1]];
}

-(void) Insertnodjourney:(int)param1 withParam1:(int)param2
{
	//param1 is the Node
	
	if (param1 < 0)
	{
		param1 = 0;
	}
	param1--;
	
	//param2 is the position ( starting at 0 )
	if (param2 >= [mypointer->myjourney size])
	{
		[mypointer->myjourney add:[[AdvPathMovJourney alloc] initWithParam:param1]];
		return;
	}
	
	if (param2 < 0)
	{
		param2 = 0;
	}
	//param2--;
	//	int temp;
	for (int i = [mypointer->myjourney size] - 1; i >= 0; i--)
	{
		mypointer->JourneyIterator = (AdvPathMovJourney*)[mypointer->myjourney get:i];
		
		if (i == [mypointer->myjourney size] - 1)
		{
			[mypointer->myjourney add:[[AdvPathMovJourney alloc] initWithParam:mypointer->JourneyIterator->Node]];
		}
		else
		{
			int temp = mypointer->JourneyIterator->Node;
			mypointer->JourneyIterator = (AdvPathMovJourney*)[mypointer->myjourney get:i + 1];
			mypointer->JourneyIterator->Node = temp;
		}
		
	}
	
	mypointer->JourneyIterator = (AdvPathMovJourney*)[mypointer->myjourney get:param2];
	mypointer->JourneyIterator->Node = param1;
}

-(void) Deletenodjourney:(int)param1
{
	///FOOL PROOF
	if (param1 < 0 || param1 > [mypointer->myjourney size])
	{
		return;
	}
	///////////
	
	if (distance == 0)
	{
		[mypointer->myjourney removeIndexRelease:param1];
	}
    //param1 contains the number inputed by the user
}

-(void) Findjourney:(int)param1
{
	param1--;
	if (param1 < 0)
	{
		return;
	}
	if (param1 > [mypointer->myvector size])
	{
		return;
	}
	if ([mypointer->myjourney size] == 0)
	{
		return;
	}
	
	/////stuff from the class
	CArrayList* ThePoints = [[CArrayList alloc] init];//holds the point numbers
	CArrayList* Connection = [[CArrayList alloc] init];//holds which connection id it has
	CArrayList* dist = [[CArrayList alloc] init];
	CArrayList* Results = [[CArrayList alloc] init];
	//all ArrayList<Integer>
	int Get;
	
	int Resultdistance = 0;
	BOOL Resultfound = NO;
	int TheDistance = 0;
	//Put the first point into the point array
	mypointer->JourneyIterator = (AdvPathMovJourney*)[mypointer->myjourney get:[mypointer->myjourney size] - 1];
	[ThePoints addInt:mypointer->JourneyIterator->Node];
	[Connection addInt:0];
	[dist add:(void*)0];
	Resultfound = NO;

	BOOL dontstop = YES;
//	debug = -1;
	
	while (dontstop)
	{
		// Get the point we need to check for connections
		Get = [ThePoints getInt:[ThePoints size] - 1];
		mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:Get];
		// Check the point
		//check that there will be another conection spot
		if ([mypointer->theIterator->Connections size] > [Connection getInt:[Connection size] - 1])
		{
			//Select the next connection point
			mypointer->theIterator->ConnectIterator = (AdvPathMovConnect*) [mypointer->theIterator->Connections get:[Connection getInt:[Connection size] - 1]];
			
		
			/// We look through all the points used so far ( this is necassary so not to go over the same point twice)
			BOOL worked = YES;
			for (int Currentpos = 0; Currentpos < [ThePoints size]; Currentpos++)
			{
				Get = [ThePoints getInt:Currentpos];
				
				if (mypointer->theIterator->ConnectIterator->PointID == Get)
				{
					worked = NO;
					
					if ([ThePoints size] == 0)
					{
						dontstop = NO;
					}
					else
					{
						int v = [Connection getInt:[Connection size] - 1];
						[Connection set:[Connection size] - 1 integer:v+1];
					}				
				}					
			}
				
			//// MUST STICK SOMETHING IN HERE FOR ADDING TO THE DISTANCE
			if (worked)
			{
				
				[ThePoints addInt:mypointer->theIterator->ConnectIterator->PointID];
				[dist addInt:(int)mypointer->theIterator->ConnectIterator->Distance];
				TheDistance += mypointer->theIterator->ConnectIterator->Distance;
				
				[Connection addInt:0];
				if (TheDistance > Resultdistance && Resultfound == YES)
				{				
					[Connection removeIndex:[Connection size]- 1];
					TheDistance -= [dist getInt:[dist size] - 1];
					[dist removeIndex:[dist size] - 1];
					[ThePoints removeIndex:[ThePoints size] - 1];
					int v = [Connection getInt:[Connection size] - 1];
					[Connection set:[Connection size]- 1 integer:v+1];
				}
			
				///check if the point we have just added is the one we are after
				Get = [ThePoints getInt:[ThePoints size] - 1];
				if (Get == param1)
				{
					///////////////////////////////////////////////////////////////////////////////
					/////    WOOOHOOOOO PATH HAS BEEN FOUND FRIGGIN AWSOME :D!!!!                //
					///////////////////////////////////////////////////////////////////////////////
					
					////first we calculate the total distance of the journey->->->->i love C++ :)
					//   int totaldis = 0;
					// for(int x = 0;x<distance->size();x++)
					// {
					//	   totaldis += distance->at(x);}
					
					
					///no point doing anything if the route is longer
					
					if (Resultdistance > TheDistance || Resultfound == NO)
					{
						Resultfound = YES;
						Resultdistance = TheDistance;
						[Results clear];
						
						//////Now we must stick the distance in the vector and copy all the points
						for (int yy = 0; yy < [ThePoints size]; yy++)
						{
							Get = [ThePoints getInt:yy];
							[Results addInt:Get];
						}
					}
					[Connection removeIndex:[Connection size] - 1];
					TheDistance -= [dist getInt:[dist size] - 1];
					[dist removeIndex:[dist size] - 1];
					[ThePoints removeIndex:[ThePoints size] - 1];
					int v = [Connection getInt:[Connection size] - 1];
					[Connection set:[Connection size]-1 integer:v+1];
				}
			}
		}
		else
		{
			[ThePoints removeIndex:[ThePoints size] - 1];
			[Connection removeIndex:[Connection size] - 1];
			TheDistance -= [dist getInt:[dist size] - 1];
			[dist removeIndex:[dist size] - 1];
			if ([ThePoints size] == 0)
			{
				dontstop = NO;
			}
			else
			{
				int v = [Connection getInt:[Connection size] - 1];
				[Connection set:[Connection size] - 1 integer:v+1];
			}
		}
	}
 
	///Now we have found all the paths, we must stick them into the journey:)
	
	for (int z = 1; z < [Results size]; z++)
	{
		Get = [Results getInt:z];
		[mypointer->myjourney add:[[AdvPathMovJourney alloc] initWithParam:Get]];
	}

	//param1 contains the number inputed by the user
	[Results release];
	[ThePoints release];
	[Connection release];
	[dist release];
//	debug = [ThePoints size] + [Connection size] + [distance size] + [Results size];
 	
}

/*
-(void) LoadPath(String fileName)
{
	CFile file = null;
	try
	{
		file = ho->openHFile(fileName);
		mypointer->myvector->clear();
		
		BOOL finishedloading = NO;
		//int finish = _lseek( pathfile,0, SEEK_END);
		//_lseek( pathfile, 0, SEEK_SET);
		int special = 0;
		int Loadnumber = 0;
		int Currentpos = 0;
		int vectorpos = -1;
		float Loadfloat = 0->0f;
		while (!finishedloading)
		{
			try
			{
				byte b = file->readAByte();
				file->skipBack(1);
			}
			catch (Exception ex)
			{
				finishedloading = YES;
			}
			if ((!finishedloading) && !((Currentpos > 1) && ((Currentpos % 2) == 1)))
			{
				Loadnumber = file->readAInt();
			}
			
			if ((!finishedloading) && ((Currentpos > 1) && ((Currentpos % 2) == 1)))
			{
				int readf = file->readAInt();
				Loadfloat = Float->intBitsToFloat(readf);
			}
			if ((special > 0) && (!finishedloading))
			{
				if (Currentpos == 0)
				{
					mypointer->myvector->add(new AdvPathMovPoints(Loadnumber, 0));
				}
				if (Currentpos == 1)
				{
					mypointer->theIterator = (AdvPathMovPoints) mypointer->myvector->get(vectorpos);
					mypointer->theIterator->Y = Loadnumber;
				}
				if (Currentpos > 1 && (Currentpos % 2) == 0)
				{//MessageBox(NULL, "Loading Point ID", NULL,MB_OK );
					mypointer->theIterator = (AdvPathMovPoints) mypointer->myvector->get(vectorpos);
					mypointer->theIterator->Connections->add(new AdvPathMovConnect(Loadnumber, 5));
				}
				if (Currentpos > 1 && (Currentpos % 2) == 1)
				{//MessageBox(NULL, "Loading float", NULL,MB_OK );
					mypointer->theIterator = (AdvPathMovPoints) mypointer->myvector->get(vectorpos);
					mypointer->theIterator->ConnectIterator = (AdvPathMovConnect) mypointer->theIterator->Connections->get((int) ((Currentpos - 3) / 2));
					mypointer->theIterator->ConnectIterator->Distance = Loadfloat + 20->0f;
				}
				Currentpos++;
			}
			if ((special == 0) && (!finishedloading))
			{
				//	MessageBox(NULL, "New Vector", NULL,MB_OK );
				special = Loadnumber + 1;
				vectorpos++;
				Currentpos = 0;
			}
			special -= 1;
		}
	}
	catch (Exception e)
	{
	}
	try
	{
		if (file != null)
		{
			ho->closeHFile(file);
		}
	}
	catch (Exception e)
	{
	}
	
}

private static void writeAnInt(DataOutputStream dis, int v) throws IOException
{
	dis->writeInt(Integer->reverseBytes(v));
}

private static void writeAFloat(DataOutputStream dis, float v) throws IOException
{
	dis->writeInt(Integer->reverseBytes(Float->floatToIntBits(v)));
}

-(void) SavePath(String fileName)
{
	File file = null;
	FileOutputStream fos = null;
	BufferedOutputStream bos = null;
	DataOutputStream dos = null;
	try
	{
		file = new File(fileName);
		fos = new FileOutputStream(file);
		bos = new BufferedOutputStream(fos);
		dos = new DataOutputStream(bos);
		for (int i = 0;
			 i < [mypointer->myvector size];
			 i++)
		{
			mypointer->theIterator = (AdvPathMovPoints) mypointer->myvector->get(i);
			writeAnInt(dos, [mypointer->theIterator->Connections size] * 2 + 2);
			writeAnInt(dos, mypointer->theIterator->X);
			writeAnInt(dos, mypointer->theIterator->Y);
			
			for (int j = 0;
				 j < [mypointer->theIterator->Connections size];
				 j++)
			{
				mypointer->theIterator->ConnectIterator = (AdvPathMovConnect) mypointer->theIterator->Connections->get(j);
				writeAnInt(dos, mypointer->theIterator->ConnectIterator->PointID);
				writeAFloat(dos, mypointer->theIterator->ConnectIterator->Distance);
			}
		}
		dos->flush();
	}
	catch (Exception e)
	{
	}
	try
	{
		if (fos != null)
		{
			fos->close();
		}
		if (bos != null)
		{
			bos->close();
		}
		if (dos != null)
		{
			dos->close();
		}
	}
	catch (Exception e)
	{
	}
}
*/
 
-(void) MovementStart
{
	if ([mypointer->myjourney size] < 1)
	{
		return;
	}
	ismoving = YES;
	muststop = NO;
	
	//Set the iterator to the first journey step
	mypointer->JourneyIterator = (AdvPathMovJourney*)[mypointer->myjourney get:0];
	//Now we know what the current point has to be :)
	int FirstNode = mypointer->JourneyIterator->Node;
	int NextNode = 0;
	if ([mypointer->myjourney size] > 1)
	{
		mypointer->JourneyIterator = (AdvPathMovJourney*)[mypointer->myjourney get:1];
		//Now we what what the next point is going to be :)
		NextNode = mypointer->JourneyIterator->Node;
	}
	
	BOOL connectfound = NO;
	
	//now we select the first point
	mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:FirstNode];
	//Great->->->now we need to run through all the connections and find the right one
	for (int i = 0; i < [mypointer->theIterator->Connections size]; i++)
	{
		mypointer->theIterator->ConnectIterator = (AdvPathMovConnect*)[mypointer->theIterator->Connections get:i];
		if (mypointer->theIterator->ConnectIterator->PointID == NextNode)
		{
			totaldist = mypointer->theIterator->ConnectIterator->Distance;
			connectfound = YES;
		}
	}
	if (connectfound == NO)
	{
		ismoving = NO;
		distance = 0;
		muststop = NO;
		totaldist = 0;
	}
}
 
-(void) Setspeed:(double)spd
{
	if (spd <= 0)
	{
		return;
	}
	speed = (float) spd;
}

-(void) Setobject:(CObject*)object
{
	myObject = object;
}
 
 -(void) Forcemovexsteps:(double)p1
{
	if (p1 <= 0)
	{
		return;
	}
	float oldspeed = speed;
	speed = (float) p1;
	
	///////////////////////////////////////////////////
	//////////////////////////////////////////////////
	/////////////////////////////////////////////////
	////////////////////////////////////////////////
	///////////////////////////////////////////////
	//////////////////////////////////////////////
	if ([mypointer->myjourney size] == 1)
	{
		//	MessageBox(NULL,"Hi",NULL,NULL);
		//This is so the object is at the first point if its not moving->
		mypointer->JourneyIterator = (AdvPathMovJourney*)[mypointer->myjourney get:0];
		mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:mypointer->JourneyIterator->Node];
		x = mypointer->theIterator->X;
		y = mypointer->theIterator->Y;
		if (ChangeX == YES)
		{
			myObject->hoX = x;
		}
		if (ChangeY == YES)
		{
			myObject->hoY = y;
		}
		myObject->roc->rcChanged = YES;
	}
	
	if (ismoving == NO)
	{
		return;
	}
	
	distance += speed;
	
	int FirstNode = 0;
	int NextNode = 0;
	BOOL connectfound = NO;
	while ((ismoving == YES) && (distance >= totaldist))
	{
		//Take away the distance travelled so far :)
		[mypointer->myjourney removeIndexRelease:0];
		
		////Calculate position ( for when it touches a new node )
		mypointer->JourneyIterator = (AdvPathMovJourney*)[mypointer->myjourney get:0];
		FirstNode = mypointer->JourneyIterator->Node;
		mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:FirstNode];
		x = mypointer->theIterator->X + xoffset;
		y = mypointer->theIterator->Y + yoffset;
		
		if (ChangeX == YES)
		{
			myObject->hoX = x;
		}
		if (ChangeY == YES)
		{
			myObject->hoY = y;
		}
		
		myObject->roc->rcChanged = YES;
		[ho generateEvent:CID_touchednewnod withParam:[ho getEventParam]];
		//callRunTimeFunction(rdPtr, RFUNCTION_GENERATEEVENT, 4, 0);
		
		if ([mypointer->myjourney size] <= 1 || muststop == YES)
		{
			ismoving = NO;
			distance = 0;
			muststop = NO;
			totaldist = 0;
			[ho generateEvent:CID_Hasreachedend withParam:[ho getEventParam]];
            //callRunTimeFunction(rdPtr, RFUNCTION_GENERATEEVENT, 3, 0);
		}
		if (ismoving == YES)
		{
			distance -= totaldist;
			
			//Set the iterator to the first journey step
			mypointer->JourneyIterator = (AdvPathMovJourney*)[mypointer->myjourney get:0];
			//Now we know what the current point has to be :)
			FirstNode = mypointer->JourneyIterator->Node;
			mypointer->JourneyIterator = (AdvPathMovJourney*)[mypointer->myjourney get:1];
			//Now we what what the next point is going to be :)
			NextNode = mypointer->JourneyIterator->Node;
			
			//now we select the first point
			mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:FirstNode];
			//Great->->->now we need to run through all the connections and find the right one
			for (int i = 0; i < [mypointer->theIterator->Connections size]; i++)
			{
				mypointer->theIterator->ConnectIterator = (AdvPathMovConnect*)[mypointer->theIterator->Connections get:i];
				if (mypointer->theIterator->ConnectIterator->PointID == NextNode)
				{
					totaldist = mypointer->theIterator->ConnectIterator->Distance;
					connectfound = YES;
				}
			}
			if (connectfound == NO)
			{
				ismoving = NO;
				distance = 0;
				muststop = NO;
				totaldist = 0;
			}
		}
	}
	if ((ismoving == YES) && (distance != 0))
	{
		////Get points
		mypointer->JourneyIterator = (AdvPathMovJourney*)[mypointer->myjourney get:0];
		//Now we know what the current point has to be :)
		FirstNode = mypointer->JourneyIterator->Node;
		mypointer->JourneyIterator = (AdvPathMovJourney*)[mypointer->myjourney get:1];
		//Now we want what the next point is going to be :)
		NextNode = mypointer->JourneyIterator->Node;
		
		
		mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:FirstNode];
		int x1 = mypointer->theIterator->X;
		int y1 = mypointer->theIterator->Y;
		
		mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:NextNode];
		int x2 = mypointer->theIterator->X;
		int y2 = mypointer->theIterator->Y;
		int deltax = x2 - x1;
		int deltay = y2 - y1;
		
		/////Below need to go in main
		
		if (totaldist != 0)
		{
			float myval = (float) (atan2((deltax + 0.0), (deltay + 0.0)) / 3.1415926535897932384626433832795 * 180);
			angle = (int) (180 - myval);
		}
		
		
		///////////////////////////End
		
		
		/////Below need to go in main
		if (totaldist != 0)
		{
			x = (int) (x1 + deltax * (distance / totaldist) + xoffset);
			y = (int) (y1 + deltay * (distance / totaldist) + yoffset);
			if (ChangeX == YES)
			{
				myObject->hoX = x;
			}
			if (ChangeY == YES)
			{
				myObject->hoY = y;
			}
			
			if (ChangeDirection == YES)
			{
				int direction = (angle * 32 + 180) / 360;
				direction = 8 - direction;
				if (direction < 0)
				{
					direction += 32;
				}
				//	return direction;
				myObject->roc->rcDir = direction;
			}
			myObject->roc->rcChanged = YES;
		}
	}
	/////////////////////////////////////
	/////////////////
	////////////////
	///////////////
	speed = oldspeed;
}
 
-(void) SetNodeX:(int)param1 withParam1:(int)param2
{
	param1--; // 1 based index convert to 0 based
	//use param1
	// and 2
	if ((param1 >= 0) && (param1 < [mypointer->myvector size]))
	{
		mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:param1];
		int OldX = mypointer->theIterator->X;
		int OldY = mypointer->theIterator->Y;
		mypointer->theIterator->X = param2;
		int NewX = mypointer->theIterator->X;
		int NewY = mypointer->theIterator->Y;
		
		for (int i = 0; i < [mypointer->myvector size]; i++)
		{
			mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:i];
			if (mypointer->theIterator != (AdvPathMovPoints*)[mypointer->myvector get:param1])
			{
				for (int j = 0; j < [mypointer->theIterator->Connections size]; j++)
				{
					mypointer->theIterator->ConnectIterator = (AdvPathMovConnect*)[mypointer->theIterator->Connections get:j];
					if (mypointer->theIterator->ConnectIterator->PointID == param1)
					{
						//we need to figure the speed
						int X1 = mypointer->theIterator->X;
						int Y1 = mypointer->theIterator->Y;
						float Olddist = (float) (sqrt((X1 - OldX) * (X1 - OldX) + (Y1 - OldY) * (Y1 - OldY)));
						float vecspeed = mypointer->theIterator->ConnectIterator->Distance / Olddist;
						float Newdist = (float) (sqrt((X1 - NewX) * (X1 - NewX) + (Y1 - NewY) * (Y1 - NewY)));
						mypointer->theIterator->ConnectIterator->Distance = vecspeed * Newdist;
					}
				}
			}
		}
		mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:param1];
			
		
		for (int i = 0; i < [mypointer->theIterator->Connections size]; i++)
		{
			mypointer->theIterator->ConnectIterator = (AdvPathMovConnect*)[mypointer->theIterator->Connections get:i];
			//rdPtr->mypointer->theIterator->ConnectIterator = rdPtr->mypointer->theIterator->Connections->begin() + temp;
			
			float Distancexspeed = mypointer->theIterator->ConnectIterator->Distance;
				
			mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:mypointer->theIterator->ConnectIterator->PointID];
			int X1 = mypointer->theIterator->X;
			int Y1 = mypointer->theIterator->Y;
			float Olddist = (float) (sqrt((X1 - OldX) * (X1 - OldX) + (Y1 - OldY) * (Y1 - OldY)));
			float vecspeed = Distancexspeed / Olddist;
			float Newdist = (float) (sqrt((X1 - NewX) * (X1 - NewX) + (Y1 - NewY) * (Y1 - NewY)));
			mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:param1];
			mypointer->theIterator->ConnectIterator->Distance = vecspeed * Newdist;			
		}
	}
}

 
-(void) SetNodeY:(int)param1 withParam1:(int)param2
{
	param1--; // 1 based index convert to 0 based
	//use param1
	// and 2
	if ((param1 >= 0) && (param1 < [mypointer->myvector size]))
	{
		mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:param1];
		int OldX = mypointer->theIterator->X;
		int OldY = mypointer->theIterator->Y;
		mypointer->theIterator->Y = param2;
		int NewX = mypointer->theIterator->X;
		int NewY = mypointer->theIterator->Y;
	
		for (int i = 0; i < [mypointer->myvector size]; i++)
		{
			mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:i];
			// For points that are connected to the just moved one we need to update
			if (mypointer->theIterator != (AdvPathMovPoints*)[mypointer->myvector get:param1])
			{
				
				for (int j = 0; j < [mypointer->theIterator->Connections size]; j++)
				{
					mypointer->theIterator->ConnectIterator = (AdvPathMovConnect*)[mypointer->theIterator->Connections get:j];
					if (mypointer->theIterator->ConnectIterator->PointID == param1)
					{
						//we need to figure the speed
						int X1 = mypointer->theIterator->X;
						int Y1 = mypointer->theIterator->Y;
						float Olddist = (float) (sqrt((X1 - OldX) * (X1 - OldX) + (Y1 - OldY) * (Y1 - OldY)));
						float vecspeed = mypointer->theIterator->ConnectIterator->Distance / Olddist;
						float Newdist = (float) (sqrt((X1 - NewX) * (X1 - NewX) + (Y1 - NewY) * (Y1 - NewY)));
						mypointer->theIterator->ConnectIterator->Distance = vecspeed * Newdist;
					}
				}
			}
		}
		///Ok now we must update the point so all the things its connected to will change
		
		mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:param1];
		
		for (int i = 0; i < [mypointer->theIterator->Connections size]; i++)
		{
			mypointer->theIterator->ConnectIterator = (AdvPathMovConnect*)[mypointer->theIterator->Connections get:i];
			//rdPtr->mypointer->theIterator->ConnectIterator = rdPtr->mypointer->theIterator->Connections->begin() + temp;
			
			float Distancexspeed = mypointer->theIterator->ConnectIterator->Distance;
			
			mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:mypointer->theIterator->ConnectIterator->PointID];
			int X1 = mypointer->theIterator->X;
			int Y1 = mypointer->theIterator->Y;
			float Olddist = (float) (sqrt((X1 - OldX) * (X1 - OldX) + (Y1 - OldY) * (Y1 - OldY)));
			float vecspeed = Distancexspeed / Olddist;
			float Newdist = (float) (sqrt((X1 - NewX) * (X1 - NewX) + (Y1 - NewY) * (Y1 - NewY)));
			mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:param1];
			mypointer->theIterator->ConnectIterator->Distance = vecspeed * Newdist;				
		}
	
	}
}
	
		
-(void) Disconnectnode:(int)param1 withParam1:(int)param2
{
	param1--;
	param2--;
	//param 1 and param 2
	if ((param1 >= 0) && (param1 < [mypointer->myvector size]))
	{
		mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:param1];
		
		for (int i = 0; i < [mypointer->theIterator->Connections size]; i++)
		{
			mypointer->theIterator->ConnectIterator = (AdvPathMovConnect*)[mypointer->theIterator->Connections get:i];
			if (mypointer->theIterator->ConnectIterator->PointID == param2)
			{
				[mypointer->theIterator->Connections removeObjectRelease:(mypointer->theIterator->ConnectIterator)];
                //         rdPtr->mypointer->theIterator->ConnectIterator--;
			}
		}
	}
}

-(void) ClearJourney
{
	////THIS IS ACTUALLY CLEAR PATH!!!!!!
	[mypointer->myvector clearRelease];
	[mypointer->myjourney clearRelease];
	ismoving = NO;
}
	
-(void) ChangeX:(int)param1
{
	if (param1 == 1)
	{
		ChangeX = YES;
	}
	if (param1 == 0)
	{
		ChangeX = NO;
	}
}

-(void) ChangeY:(int)param1
{
	if (param1 == 1)
	{
		ChangeY = YES;
	}
	if (param1 == 0)
	{
		ChangeY = NO;
	}
}

-(void) ChangeDirection:(int)param1
{
	if (param1 == 1)
	{
		ChangeDirection = YES;
	}
	if (param1 == 0)
	{
		ChangeDirection = NO;
	}
}
	
// Expressions
// --------------------------------------------
-(CValue*)expression:(int)num
{
	switch (num){
		case EID_Findnode:
			return [self Findnode];
		case EID_Numberofnods:
			return [rh getTempValue:[mypointer->myvector size]];
		case EID_GetJourneynode:
			return [self GetJourneynode:[[ho getExpParam] getInt]];
		case EID_Countjourneynode:
			return [rh getTempValue:[mypointer->myjourney size]];
		case EID_ObjectGetX:
			return [rh getTempValue:x];
		case EID_ObjectGetY:
			return [rh getTempValue:y];
		case EID_ObjectGetSpeed:
			return [rh getTempValue:speed];
		case EID_NodeDistance:
			return [self NodeDistance];
		case EID_NodeX:
			return [self NodeX:[[ho getExpParam] getInt]];
		case EID_NodeY:
			return [self NodeY:[[ho getExpParam] getInt]];
		case EID_GetCurrentSpeed:
			return [rh getTempValue:0];
		case EID_GetXoffset:
			return [rh getTempValue:xoffset];
		case EID_GetYoffset:
			return [rh getTempValue:yoffset];
		case EID_GetAngle:
			return [rh getTempValue:angle];
		case EID_GetDirection:
			return [self GetDirection];
		case EID_Getconnection:
			return [self Getconnection];
		case EID_GetNumberconnections:
			return [self GetNumberconnections:[[ho getExpParam] getInt]];
		case EID_GetNodesSpeed:
			return [self GetNodesSpeed];
		case EID_AutochangeX:
			return [rh getTempValue:(ChangeX ? 1 : 0)];
		case EID_AutochangeY:
			return [rh getTempValue:(ChangeY ? 1 : 0)];
		case EID_AutochangeDirection:
			return [rh getTempValue:(ChangeDirection ? 1 : 0)];
	}
	return [rh getTempValue:0];//won't be 
}

-(CValue*) Findnode
{
	int p1=[[ho getExpParam] getInt];
	int p2=[[ho getExpParam] getInt];
	int p3=[[ho getExpParam] getInt];

	int Answer = p3*p3;
	int result = 0;
	int deltaX = 0;
	int deltaY = 0;
	int loopcount =0;
	
	for(int i = 0; i < [mypointer->myvector size];i++)
	{
		mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:i];
		loopcount ++;
		deltaX = abs(mypointer->theIterator->X - p1);
		deltaY = abs(mypointer->theIterator->Y - p2);
		
		if(Answer > (deltaX * deltaX + deltaY * deltaY ))
		{
			Answer = (deltaX * deltaX + deltaY * deltaY );
			result = loopcount;
		}
	}
	return [rh getTempValue:result];
}

-(CValue*) GetJourneynode:(int)p1
{
	if(p1 < 0){return [rh getTempValue:0];}
	if([mypointer->myjourney size] == 0){return [rh getTempValue:0];}
	if(p1 >= [mypointer->myjourney size] ){return [rh getTempValue:0];}
	mypointer->JourneyIterator = (AdvPathMovJourney*)[mypointer->myjourney get:p1];
	return [rh getTempValue:mypointer->JourneyIterator->Node + 1];
}
-(CValue*) NodeDistance
{
	int p1=[[ho getExpParam] getInt];
	int p2=[[ho getExpParam] getInt];
	p1 --;
	p2 --;
	if ((p1 >= 0) && (p1 < [mypointer->myvector size]) && (p2 >= 0) && (p2 < [mypointer->myvector size]))
	{
		//Get second vector
		mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:p2];
		int v2x = mypointer->theIterator->X;
		int v2y = mypointer->theIterator->Y;
		
		//Get first vector
		mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:p1];
		int v1x = mypointer->theIterator->X;
		int v1y = mypointer->theIterator->Y;
		int deltax = v2x - v1x;
		int deltay = v2y - v1y;
		float dist = (float)sqrt(deltax * deltax + deltay * deltay );
		return [rh getTempValue:dist];
	}
	return [rh getTempValue:0];
}

-(CValue*)NodeX:(int)p1
{
	if(p1 < 1){return [rh getTempValue:0];}
	if([mypointer->myvector size] == 0){return [rh getTempValue:0];}
	if(p1 > [mypointer->myvector size] ){return [rh getTempValue:0];}
	mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:(p1 - 1)];
	return [rh getTempValue:mypointer->theIterator->X];
}
-(CValue*) NodeY:(int)p1
{
	if(p1 < 1){return [rh getTempValue:0];}
	if([mypointer->myvector size] == 0){return [rh getTempValue:0];}
	if(p1 > [mypointer->myvector size] ){return [rh getTempValue:0];}
	mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:(p1 - 1)];
	return [rh getTempValue:mypointer->theIterator->Y];
}
-(CValue*) GetDirection
{
	int direction = (angle *32+180)/ 360;
	direction = 8-direction;
	if ( direction < 0){direction +=32;}
	return [rh getTempValue:direction];
}
-(CValue*)Getconnection
{
	int p1=[[ho getExpParam] getInt];
	int p2=[[ho getExpParam] getInt];
	p1--;
	if(p1 < 0){return [rh getTempValue:0];}
	if(p1 >= [mypointer->myvector size]){return [rh getTempValue:0];}
	
	mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:p1];
	if(p2 < 0){return [rh getTempValue:0];}
	if([mypointer->theIterator->Connections size] <= p2){return [rh getTempValue:0];}
	mypointer->theIterator->ConnectIterator = (AdvPathMovConnect*)[mypointer->theIterator->Connections get:p2];
	return [rh getTempValue:mypointer->theIterator->ConnectIterator->PointID + 1];
}
-(CValue*)GetNumberconnections:(int)p1
{
	p1--;
	if(p1 < 0){return [rh getTempValue:0];}
	if(p1 >= [mypointer->myvector size]){return [rh getTempValue:0];}
	mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:p1];
	return [rh getTempValue:[mypointer->theIterator->Connections size]];
}
-(CValue*)GetNodesSpeed
{
	int p1=[[ho getExpParam] getInt];
	int p2=[[ho getExpParam] getInt];
	p1--;
	p2--;
	float sp = 0;
	BOOL cont = YES;
	//param1 contains the number inputed by the user
	//param2 contains the number inputed by the user
	if ((p1 >= 0) && (p1 < [mypointer->myvector size]) && (p2 >= 0) && (p2 < [mypointer->myvector size]))
	{
		mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:p1];
		for(int i = 0; i < [mypointer->theIterator->Connections size]; i++)
		{
			mypointer->theIterator->ConnectIterator = (AdvPathMovConnect*)[mypointer->theIterator->Connections get:i];
			if(mypointer->theIterator->ConnectIterator->PointID == p2)
			{
				sp = mypointer->theIterator->ConnectIterator->Distance;
				cont = NO;
			}
		}
		
		if (cont){return [rh getTempValue:0.0f];}
		//Get second vector
		mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:p2];
		int v2x = mypointer->theIterator->X;
		int v2y = mypointer->theIterator->Y;
		
		//Get first vector
		mypointer->theIterator = (AdvPathMovPoints*)[mypointer->myvector get:p1];
		int v1x = mypointer->theIterator->X;
		int v1y = mypointer->theIterator->Y;
		int deltax = v2x - v1x;
		int deltay = v2y - v1y;
		float dist = (float)sqrt(deltax * deltax + deltay * deltay );
		if(dist == 0)
		{
			return [rh getTempValue:1.0f];
		}
		return [rh getTempValue:dist/sp];
	}
	return [rh getTempValue:0.0f];
}


@end

