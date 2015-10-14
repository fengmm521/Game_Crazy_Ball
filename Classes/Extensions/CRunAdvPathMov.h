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
#import <Foundation/Foundation.h>
#import "CRunExtension.h"

@class CObject;
@class CBitmap;
@class CCreateObjectInfo;
@class CBitmap;
@class AdvPathMovmyclass;
@class CValue;
@class CCndExtension;
@class CActExtension;
@class CArrayList;

#define CID_ismoving 0
#define CID_nodesconnected 1
#define CID_isstopping 2
#define CID_Hasreachedend 3
#define CID_touchednewnod 4
#define AID_creatpathnod 0
#define AID_removepathnod 1
#define AID_Clearpath 2
#define AID_Connectnods 3
#define AID_Addnodjourney 4
#define AID_Insertnodjourney 5
#define AID_Removelastnodjourney 6
#define AID_Deletenodjourney 7
#define AID_Findjourney 8
#define AID_LoadPath 9
#define AID_SavePath 10
#define AID_MovementStart 11
#define AID_MovementStop 12
#define AID_MovementPause 13
#define AID_Setspeed 14
#define AID_Setobject 15
#define AID_setXoffset 16
#define AID_setYoffset 17
#define AID_Enableautostep 18
#define AID_Disableautostep 19
#define AID_Forcemovexsteps 20
#define AID_SetNodeX 21
#define AID_SetNodeY 22
#define AID_Disconnectnode 23
#define AID_ClearJourney 24
#define AID_ChangeX 25
#define AID_ChangeY 26
#define AID_ChangeDirection 27
#define EID_Findnode  0
#define EID_Numberofnods 1
#define EID_GetJourneynode              2
#define EID_Countjourneynode            3
#define EID_ObjectGetX                  4
#define EID_ObjectGetY                  5
#define EID_ObjectGetSpeed              6
#define EID_NodeDistance                7
#define EID_NodeX                       8
#define EID_NodeY                       9
#define EID_GetCurrentSpeed             10
#define EID_GetXoffset                  11
#define EID_GetYoffset                  12
#define EID_GetAngle                    13
#define EID_GetDirection                14
#define EID_Getconnection               15
#define EID_GetNumberconnections        16
#define EID_GetNodesSpeed               17
#define EID_AutochangeX                 18
#define EID_AutochangeY                 19
#define EID_AutochangeDirection         20

@interface CRunAdvPathMov : CRunExtension
{
    AdvPathMovmyclass* mypointer;
    float distance, speed, totaldist;
    BOOL ismoving, muststop, enableautostep, ChangeX, ChangeY, ChangeDirection;
    int debug, x, y, xoffset, yoffset, angle;
    CObject* myObject;	
}
-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(void)destroyRunObject:(BOOL)bFast;
-(int)handleRunObject;
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd;
-(BOOL)nodesconnected:(int)param1 withParam1:(int)param2;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(void) creatpathnod:(int)param1 withParam1:(int)param2;
-(void) removepathnod:(int)param1;
-(void) remove:(CArrayList*)array withFrom:(int)from andTo:(int)to;
-(void) removeClear:(CArrayList*)array withFrom:(int)from andTo:(int)to;
-(void) Clearpath:(int)param1;
-(void)Connectnods:(int)p1 withParam1:(int)p2 andParam2:(double)p3;
-(void) Addnodjourney:(int)param1;
-(void) Insertnodjourney:(int)param1 withParam1:(int)param2;
-(void) Deletenodjourney:(int)param1;
-(void) Findjourney:(int)param1;
-(void) MovementStart;
-(void) Setspeed:(double)speed;
-(void) Setobject:(CObject*)object;
-(void) Forcemovexsteps:(double)p1;
-(void) SetNodeX:(int)param1 withParam1:(int)param2;
-(void) SetNodeY:(int)param1 withParam1:(int)param2;
-(void) Disconnectnode:(int)param1 withParam1:(int)param2;
-(void) ClearJourney;
-(void) ChangeX:(int)param1;
-(void) ChangeY:(int)param1;
-(void) ChangeDirection:(int)param1;
-(CValue*)expression:(int)num;
-(CValue*) Findnode;
-(CValue*) GetJourneynode:(int)p1;
-(CValue*) NodeDistance;
-(CValue*)NodeX:(int)p1;
-(CValue*) NodeY:(int)p1;
-(CValue*) GetDirection;
-(CValue*)Getconnection;
-(CValue*)GetNumberconnections:(int)p1;
-(CValue*)GetNodesSpeed;


@end





@interface AdvPathMovJourney : NSObject
{
@public
	int Node;
}
-(id)initWithParam:(int)n;
@end

@interface AdvPathMovConnect : NSObject
{
@public 
    int PointID;
	float Distance;	
}
@end

@interface AdvPathMovPoints : NSObject
{
@public
    int X, Y;
    CArrayList* Connections; //ArrayList<AdvPathMovConnect>
    AdvPathMovConnect* ConnectIterator;
}
-(id)initWithParam1:(int)xx andParam2:(int)yy;
-(void)dealloc;
@end

@interface AdvPathMovmyclass : NSObject
{
@public 	
    CArrayList* myvector; //ArrayList<AdvPathMovPoints>
	AdvPathMovPoints* theIterator;
	
	CArrayList* myjourney; //ArrayList<AdvPathMovJourney>
	AdvPathMovJourney* JourneyIterator;
}
-(id)init;
-(void)dealloc;
@end

