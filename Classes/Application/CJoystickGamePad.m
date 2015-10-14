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
//
//  CGamePad.m
//  RuntimeIPhone
//
//  Created by Anders Riggelsen on 26/04/14.
//  Copyright (c) 2014 Clickteam. All rights reserved.
//

#import "CJoystickGamepad.h"
#import "CRunView.h"
#import "CRunApp.h"

@implementation CJoystickGamepad

-(id)initWithApp:(CRunApp*)_app
{
	if(self = [super init])
	{
		app = _app;
		if(SYSTEM_VERSION_LESS_THAN(@"7.0"))
			return nil;
	}
	return self;
}

-(unsigned char)getJoystick
{
	int joystick = 0;
#ifdef __IPHONE_7_0
	for(GCController* controller in [GCController controllers])
	{
		GCExtendedGamepad* extGamepad = controller.extendedGamepad;
		if(extGamepad == nil)
		{
			GCGamepad* gamepad = controller.gamepad;
			if(gamepad == nil)
				continue;

			if(gamepad.dpad.up.isPressed)
				joystick |=	0x01;
			if(gamepad.dpad.down.isPressed)
				joystick |=	0x02;
			if(gamepad.dpad.left.isPressed)
				joystick |=	0x04;
			if(gamepad.dpad.right.isPressed)
				joystick |=	0x08;
			if(gamepad.buttonA.isPressed)
				joystick |= 0x10;
			if(gamepad.buttonB.isPressed)
				joystick |= 0x20;
			if(gamepad.rightShoulder.isPressed)
				joystick |= 0x10;
			if(gamepad.leftShoulder.isPressed)
				joystick |= 0x20;
		}
		else
		{
			if(extGamepad.dpad.up.isPressed || extGamepad.leftThumbstick.up.isPressed || extGamepad.rightThumbstick.up.isPressed)
				joystick |=	0x01;
			if(extGamepad.dpad.down.isPressed || extGamepad.leftThumbstick.down.isPressed || extGamepad.rightThumbstick.down.isPressed)
				joystick |=	0x02;
			if(extGamepad.dpad.left.isPressed || extGamepad.leftThumbstick.left.isPressed || extGamepad.rightThumbstick.left.isPressed)
				joystick |=	0x04;
			if(extGamepad.dpad.right.isPressed || extGamepad.leftThumbstick.right.isPressed || extGamepad.rightThumbstick.right.isPressed)
				joystick |=	0x08;
			if(extGamepad.buttonA.isPressed)
				joystick |= 0x10;
			if(extGamepad.buttonB.isPressed)
				joystick |= 0x20;
			if(extGamepad.rightShoulder.isPressed)
				joystick |= 0x10;
			if(extGamepad.leftShoulder.isPressed)
				joystick |= 0x20;
		}
	}
#endif
	return joystick;
}

@end
