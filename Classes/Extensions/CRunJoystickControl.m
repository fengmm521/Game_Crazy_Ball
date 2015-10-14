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
// CRUNIPHONEJOYSTICKCONTROL iPhone joysticks
//
//----------------------------------------------------------------------------------
#import "CRunJoystickControl.h"
#import "CFile.h"
#import "CRunApp.h"
#import "CBitmap.h"
#import "CCreateObjectInfo.h"
#import "CValue.h"
#import "CExtension.h"
#import "CRun.h"
#import "CCndExtension.h"
#import "CActExtension.h"
#import "CRunFrame.h"
#import "CJoystick.h"
#import "CServices.h"

@implementation CRunJoystickControl

-(int)getNumberOfConditions
{
	return 0;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	xJoystick=POS_NOTDEFINED;
	yJoystick=POS_NOTDEFINED;
	xFire1=POS_NOTDEFINED;
	yFire1=POS_NOTDEFINED;
	xFire2=POS_NOTDEFINED;
	yFire2=POS_NOTDEFINED;
	bAccelerometer=NO;
	bJoystick=NO;
	
	return YES;
}

-(void)destroyRunObject:(BOOL)bFast
{
	if (bJoystick)
	{
		[ho->hoAdRunHeader->rhApp createJoystick:NO withFlags:0];
	}		
	if (bAccelerometer)
	{
		[ho->hoAdRunHeader->rhApp createJoystickAcc:NO];
	}
}


// Actions
// -------------------------------------------------
-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{
		case ACT_STARTACCELEROMETER:
			[self startAccelerometer:act];
			break;
		case ACT_STOPACCELEROMETER:
			[self stopAccelerometer:act];
			break;
		case ACT_STARTSTOPTOUCH:
			[self startStopTouch:act];
			break;
		case ACT_SETJOYPOSITION:
			[self setJoyPosition:act];
			break;
		case ACT_SETFIRE1POSITION:
			[self setFire1Position:act];
			break;
		case ACT_SETFIRE2POSITION:
			[self setFire2Position:act];
			break;
		case ACT_SETXJOYSTICK:
			[self setXJoystick:act];
			break;
		case ACT_SETYJOYSTICK:
			[self setYJoystick:act];
			break;
		case ACT_SETXFIRE1:
			[self setXFire1:act];
			break;
		case ACT_SETYFIRE1:
			[self setYFire1:act];
			break;
		case ACT_SETXFIRE2:
			[self setXFire2:act];
			break;
		case ACT_SETYFIRE2:
			[self setYFire2:act];
			break;
		case ACT_SETJOYMASK:
			[self setJoyMask:act];
			break;
	}
}
-(void)startAccelerometer:(CActExtension*)act
{
	CRunApp* rhApp=ho->hoAdRunHeader->rhApp;
	if (rhApp->parentApp!=nil)
	{
		return;
	}
	if (rhApp->frame->joystick!=JOYSTICK_EXT)
	{
		return;
	}

	if (bAccelerometer==NO)
	{
		[ho->hoAdRunHeader->rhApp createJoystickAcc:YES];
		bAccelerometer=YES;
	}
}
-(void)stopAccelerometer:(CActExtension*)act
{
	if (bAccelerometer==YES)
	{
		[ho->hoAdRunHeader->rhApp createJoystickAcc:NO];
		bAccelerometer=NO;
	}
}
-(void)startStopTouch:(CActExtension*)act
{
	CRunApp* rhApp=ho->hoAdRunHeader->rhApp;
	if (rhApp->parentApp!=nil)
	{
		return;
	}
	if (rhApp->frame->joystick!=JOYSTICK_EXT)
	{
		return;
	}
	
	int joy=[act getParamExpression:rh withNum:0];
	int fire1=[act getParamExpression:rh withNum:1];
	int fire2=[act getParamExpression:rh withNum:2];
	int leftHanded=[act getParamExpression:rh withNum:3];
	
	int flags=0;
	if (fire1!=0)
	{
		flags=JFLAG_FIRE1;
	}
	if (fire2!=0)
	{
		flags|=JFLAG_FIRE2;
	}
	if (joy!=0)
	{
		flags|=JFLAG_JOYSTICK;
	}
	if (leftHanded!=0)
	{
		flags|=JFLAG_LEFTHANDED;
	}
	if ((flags&(JFLAG_FIRE1|JFLAG_FIRE2|JFLAG_JOYSTICK))!=0)
	{
		[rhApp createJoystick:YES withFlags:flags];
		[rhApp->joystick reset:flags];
		if (xJoystick!=POS_NOTDEFINED)
		{
			[rhApp->joystick setXPosition:JFLAG_JOYSTICK withPos:xJoystick];
		}
		else 
		{
			xJoystick=rhApp->joystick->imagesX[KEY_JOYSTICK];
		}

		if (yJoystick!=POS_NOTDEFINED)
		{
			[rhApp->joystick setYPosition:JFLAG_JOYSTICK withPos:yJoystick];
		}
		else 
		{
			yJoystick=rhApp->joystick->imagesY[KEY_JOYSTICK];
		}

		if (xFire1!=POS_NOTDEFINED)
		{
			[rhApp->joystick setXPosition:JFLAG_FIRE1 withPos:xFire1];
		}
		else 
		{
			xFire1=rhApp->joystick->imagesX[KEY_FIRE1];
		}
		
		if (yFire1!=POS_NOTDEFINED)
		{
			[rhApp->joystick setYPosition:JFLAG_FIRE1 withPos:yFire1];
		}
		else 
		{
			yFire1=rhApp->joystick->imagesY[KEY_FIRE1];
		}

		if (xFire2!=POS_NOTDEFINED)
		{
			[rhApp->joystick setXPosition:JFLAG_FIRE2 withPos:xFire2];
		}
		else 
		{
			xFire2=rhApp->joystick->imagesX[KEY_FIRE2];
		}
		
		if (yFire2!=POS_NOTDEFINED)
		{
			[rhApp->joystick setXPosition:JFLAG_FIRE2 withPos:yFire2];
		}
		else 
		{
			yFire2=rhApp->joystick->imagesY[KEY_FIRE2];
		}
		
		bJoystick=YES;
	}
	else
	{
		[rhApp createJoystick:NO withFlags:0];
		bJoystick=NO;
	}
}
-(void)setJoyPosition:(CActExtension*)act
{
	int pos=[act getParamPosition:rh withNum:0];
	xJoystick=POSX(pos);
	yJoystick=POSY(pos);
	if (bJoystick)
	{
		[ho->hoAdRunHeader->rhApp->joystick setXPosition:JFLAG_JOYSTICK withPos:xJoystick];
		[ho->hoAdRunHeader->rhApp->joystick setYPosition:JFLAG_JOYSTICK withPos:yJoystick];
	}
}
-(void)setFire1Position:(CActExtension*)act
{
	int pos=[act getParamPosition:rh withNum:0];
	xFire1=POSX(pos);
	yFire1=POSY(pos);
	if (bJoystick)
	{
		[ho->hoAdRunHeader->rhApp->joystick setXPosition:JFLAG_FIRE1 withPos:xFire1];
		[ho->hoAdRunHeader->rhApp->joystick setYPosition:JFLAG_FIRE1 withPos:yFire1];
	}
}
-(void)setFire2Position:(CActExtension*)act
{
	int pos=[act getParamPosition:rh withNum:0];
	xFire2=POSX(pos);
	yFire2=POSY(pos);
	if (bJoystick)
	{
		[ho->hoAdRunHeader->rhApp->joystick setXPosition:JFLAG_FIRE2 withPos:xFire2];
		[ho->hoAdRunHeader->rhApp->joystick setYPosition:JFLAG_FIRE2 withPos:yFire2];
	}
}
-(void)setXJoystick:(CActExtension*)act
{
	xJoystick=[act getParamExpression:rh withNum:0];
	if (bJoystick)
	{
		[ho->hoAdRunHeader->rhApp->joystick setXPosition:JFLAG_JOYSTICK withPos:xJoystick];
	}
}
-(void)setYJoystick:(CActExtension*)act
{
	yJoystick=[act getParamExpression:rh withNum:0];
	if (bJoystick)
	{
		[ho->hoAdRunHeader->rhApp->joystick setYPosition:JFLAG_JOYSTICK withPos:yJoystick];
	}
}
-(void)setXFire1:(CActExtension*)act
{
	xFire1=[act getParamExpression:rh withNum:0];
	if (bJoystick)
	{
		[ho->hoAdRunHeader->rhApp->joystick setXPosition:JFLAG_FIRE1 withPos:xFire1];
	}
}
-(void)setYFire1:(CActExtension*)act
{
	yFire1=[act getParamExpression:rh withNum:0];
	if (bJoystick)
	{
		[ho->hoAdRunHeader->rhApp->joystick setYPosition:JFLAG_FIRE1 withPos:yFire1];
	}
}
-(void)setXFire2:(CActExtension*)act
{
	xFire2=[act getParamExpression:rh withNum:0];
	if (bJoystick)
	{
		[ho->hoAdRunHeader->rhApp->joystick setXPosition:JFLAG_FIRE2 withPos:xFire2];
	}
}
-(void)setYFire2:(CActExtension*)act
{
	yFire2=[act getParamExpression:rh withNum:0];
	if (bJoystick)
	{
		[ho->hoAdRunHeader->rhApp->joystick setYPosition:JFLAG_FIRE2 withPos:yFire2];
	}
}
-(void)setJoyMask:(CActExtension*)act
{
	int mask=[act getParamExpression:rh withNum:0];
	ho->hoAdRunHeader->rhJoystickMask=mask;
}


// Expressions
// --------------------------------------------
-(CValue*)expression:(int)num
{
	int ret=0;
	
	switch (num)
	{
		case EXP_XJOYSTICK:
			ret=xJoystick;
			break;
		case EXP_YJOYSTICK:
			ret=yJoystick;
			break;
		case EXP_XFIRE1:
			ret=xFire1;
			break;
		case EXP_YFIRE1:
			ret=yFire1;
			break;
		case EXP_XFIRE2:
			ret=xFire2;
			break;
		case EXP_YFIRE2:
			ret=yFire2;
			break;
	}
	CValue* v=[rh getTempValue:ret];
	return v;
}

@end
