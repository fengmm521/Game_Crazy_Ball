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
// --------------------------------------------------------------------------
// 
// ACCELERATOR JOYSTICK
// 
// --------------------------------------------------------------------------
#import "CJoystickAcc.h"
#import "CRunApp.h"

@implementation CJoystickAcc

-(id)initWithApp:(CRunApp*)a
{
	if(self = [super init])
	{
		app=a;
		motionManager = [[CMMotionManager alloc] init];
		if(motionManager.accelerometerAvailable)
			[motionManager startAccelerometerUpdates];
	}
	return self;
}
-(void)dealloc
{
	[motionManager stopAccelerometerUpdates];
	[motionManager release];
	[super dealloc];
}

#define MAX_POSITIONX 3
#define MAX_POSITIONY 3
#define CENTER_POSITIONX 2
#define CENTER_POSITIONY 2

-(int)getJoystick
{
	acceleration = motionManager.accelerometerData.acceleration;
	joystick=0;
	if (acceleration.x < -0.1)
		joystick|=0x04;
	if (acceleration.x > 0.1)
		joystick|=0x08;
	if (acceleration.y < -0.1)
		joystick|=0x02;
	if (acceleration.y > 0.1)
		joystick|=0x01;

	return joystick;
}

@end
