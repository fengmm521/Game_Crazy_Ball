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
// CRUNJOYSTICKCONTROL iPhone joysticks
//
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import "CRunExtension.h"

#define ACT_STARTACCELEROMETER	0
#define ACT_STOPACCELEROMETER	1
#define ACT_STARTSTOPTOUCH		2
#define ACT_SETJOYPOSITION		3
#define ACT_SETFIRE1POSITION	4
#define ACT_SETFIRE2POSITION	5
#define ACT_SETXJOYSTICK		6
#define ACT_SETYJOYSTICK		7
#define ACT_SETXFIRE1			8
#define ACT_SETYFIRE1			9
#define	ACT_SETXFIRE2			10
#define ACT_SETYFIRE2			11
#define ACT_SETJOYMASK			12
#define EXP_XJOYSTICK			0
#define EXP_YJOYSTICK			1
#define EXP_XFIRE1				2
#define EXP_YFIRE1				3
#define EXP_XFIRE2				4
#define EXP_YFIRE2				5

#define POS_NOTDEFINED			0x80000000

@interface CRunJoystickControl : CRunExtension 
{
	BOOL bAccelerometer;
	BOOL bJoystick;
	int xJoystick;
	int yJoystick;
	int xFire1;
	int yFire1;
	int xFire2;
	int yFire2;
}
-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(void)destroyRunObject:(BOOL)bFast;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(void)startAccelerometer:(CActExtension*)act;
-(void)stopAccelerometer:(CActExtension*)act;
-(void)startStopTouch:(CActExtension*)act;
-(void)setJoyPosition:(CActExtension*)act;
-(void)setFire1Position:(CActExtension*)act;
-(void)setFire2Position:(CActExtension*)act;
-(void)setXJoystick:(CActExtension*)act;
-(void)setYJoystick:(CActExtension*)act;
-(void)setXFire1:(CActExtension*)act;
-(void)setYFire1:(CActExtension*)act;
-(void)setXFire2:(CActExtension*)act;
-(void)setYFire2:(CActExtension*)act;
-(void)setJoyMask:(CActExtension*)act;
-(CValue*)expression:(int)num;

@end
