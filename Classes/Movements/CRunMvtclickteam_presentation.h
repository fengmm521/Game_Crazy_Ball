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
// CRUNMVTPRESENTAION
//
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import "CRunMvtExtension.h"
#import "CExtStorage.h"

#define PRESIDENTIFIER 3
//*** Fly In/Out effects
#define FLYEFFECT_NONE 0
#define FLYEFFECT_APPEAR 1
#define FLYEFFECT_BOTTOM 2
#define FLYEFFECT_LEFT 3
#define FLYEFFECT_RIGHT 4
#define FLYEFFECT_TOP 5

//*** Movement status
#define STOPPED 0
#define ENTRANCE 1
#define EXIT 2

//*** Speed
#define SPEED_VERYSLOW 0
#define SPEED_SLOW 1
#define SPEED_MEDIUM 2
#define SPEED_FAST 3
#define SPEED_VERYFAST 4

//*** Global settings
#define GLOBAL_AUTOCONTROL 1
#define GLOBAL_AUTOFRAMEJUMP 2
#define GLOBAL_AUTOCOMPLETE 4

@class CGlobalPres;
@class CArrayList;

@interface CRunMvtclickteam_presentation : CRunMvtExtension
{
    int m_dwEntranceType;
    int m_dwEntranceSpeed;
    int m_dwEntranceOrder;
    int m_dwExitType;
    int m_dwExitSpeed;
    int m_dwExitOrder;
    int m_dwFlagsGlobalSettings;
    CObject* pLPHO;
    int initialX;
    int initialY;
    int startEntranceX;
    int startEntranceY;
    int entranceEffect;
    int entranceOrder;
    int entranceSpeed;
    double entranceSpeedX;
    double entranceSpeedY;
    int finalExitX;
    int finalExitY;
    int exitEffect;
    int exitOrder;
    int exitSpeed;
    double exitSpeedX;
    double exitSpeedY;
    int isMoving;
	
}
-(int)getSpeed;
-(double)actionEntry:(int)action;
-(void)setYPosition:(int)y;
-(void)setXPosition:(int)x;
-(void)setPosition:(int)x withY:(int)y;
-(void)moveBack;
-(void)moveForward;
-(BOOL)move;
-(void)kill;
-(void)checkKeyPresses:(CGlobalPres*)data;
-(void)moveToEnd;
-(void)reset:(CGlobalPres*)data;
-(void)initialize:(CFile*)file;

@end

@interface CGlobalPres : CExtStorage
{
@public
    int orderPosition;
    int finalOrder;
    int keyNext;
    int keyPrev;
    BOOL reset;
    BOOL resetToEnd;
    BOOL autoControl;
    BOOL autoFrameJump;
    BOOL autoComplete;
    CArrayList* myList;	
}
-(id)init;
-(void)dealloc;
@end
