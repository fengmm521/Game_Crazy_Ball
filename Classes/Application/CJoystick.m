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
// VIRTUAL JOYSTICK
// 
// --------------------------------------------------------------------------
#import "CJoystick.h"
#import "CRunApp.h"
#import "CRunView.h"
#import "CRenderer.h"
#import "CImage.h"

#import <GameController/GameController.h>

@implementation CJoystick

-(id)initWithApp:(CRunApp*)a
{
	if(self = [super init])
	{
		app=a;

		NSString* path;
		path=[[NSBundle mainBundle] pathForResource: @"joyback" ofType:@"png"];
		joyBack=[[UIImage alloc] initWithContentsOfFile:path];
		path=[[NSBundle mainBundle] pathForResource: @"joyfront" ofType:@"png"];
		joyFront=[[UIImage alloc] initWithContentsOfFile:path];
		path=[[NSBundle mainBundle] pathForResource: @"fire1U" ofType:@"png"];
		fire1U=[[UIImage alloc] initWithContentsOfFile:path];
		path=[[NSBundle mainBundle] pathForResource: @"fire2U" ofType:@"png"];
		fire2U=[[UIImage alloc] initWithContentsOfFile:path];
		path=[[NSBundle mainBundle] pathForResource: @"fire1D" ofType:@"png"];
		fire1D=[[UIImage alloc] initWithContentsOfFile:path];
		path=[[NSBundle mainBundle] pathForResource: @"fire2D" ofType:@"png"];
		fire2D=[[UIImage alloc] initWithContentsOfFile:path];

		joyBackTex = [CImage loadUIImage:joyBack];
		joyFrontTex = [CImage loadUIImage:joyFront];
		fire1UTex = [CImage loadUIImage:fire1U];
		fire2UTex = [CImage loadUIImage:fire2U];
		fire1DTex = [CImage loadUIImage:fire1D];
		fire2DTex = [CImage loadUIImage:fire2D];

		flags=0;

		joystickX=0;
		joystickY=0;
		joystick=0;
		imagesX[KEY_JOYSTICK]=JPOS_NOTDEFINED;
		imagesY[KEY_JOYSTICK]=JPOS_NOTDEFINED;
		imagesX[KEY_FIRE1]=JPOS_NOTDEFINED;
		imagesY[KEY_FIRE1]=JPOS_NOTDEFINED;
		imagesX[KEY_FIRE2]=JPOS_NOTDEFINED;
		imagesY[KEY_FIRE2]=JPOS_NOTDEFINED;

		int sxApp=a->gaCxWin;
		int syApp=a->gaCyWin;
		CGRect screen=[[UIScreen mainScreen] applicationFrame];
		int sxScreen=screen.size.width;
		int syScreen=screen.size.height;
		CGFloat scale=[UIScreen mainScreen].scale;
		sxScreen*=scale;
		syScreen*=scale;
		zoom=1.0;

		float minSizeInCm = 1;
		float desiredScreenSizeInCm = 1;

		if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		{
			minSizeInCm = 14.8;
			desiredScreenSizeInCm = 2.0;
		}
		else
		{
			minSizeInCm = 5.1;
			desiredScreenSizeInCm = 1.5;
		}
		float pixelsPerCm = MIN(sxApp,syApp)/minSizeInCm;
		zoom = (pixelsPerCm * desiredScreenSizeInCm)/80.0;	//80 being the pixel size of the joystick image
	}
	return self;
}
-(void)dealloc
{
	[joyBack release];
	[joyFront release];
	[fire1U release];
	[fire2U release];
	[fire1D release];
	[fire2D release];
	[joyBackTex release];
	[joyFrontTex release];
	[fire1UTex release];
	[fire2UTex release];
	[fire1DTex release];
	[fire2DTex release];
	[super dealloc];
}
-(void)reset:(int)f
{
	[app->runView setMultiTouch:YES];
	flags=f;
	[self setPositions];
}
-(void)setPositions
{	
	int sx, sy;
	sx=app->gaCxWin;
	sy=app->gaCyWin;
	if ((flags&JFLAG_LEFTHANDED)==0)
	{
		if ((flags&JFLAG_JOYSTICK)!=0)
		{
			imagesX[KEY_JOYSTICK]=16+(joyBack.size.width/2)*zoom;
			imagesY[KEY_JOYSTICK]=sy-16-(joyBack.size.height/2)*zoom;
		}
		if ((flags&JFLAG_FIRE1)!=0 && (flags&JFLAG_FIRE2)!=0)
		{
			imagesX[KEY_FIRE1]=sx-(fire1U.size.width/2+32)*zoom;
			imagesY[KEY_FIRE1]=sy-(fire1U.size.height/2+16)*zoom;
			imagesX[KEY_FIRE2]=sx-(fire2U.size.width/2+16)*zoom;
			imagesY[KEY_FIRE2]=sy-(fire2U.size.height/2+fire1U.size.height+24)*zoom;
		}
		else if ((flags&JFLAG_FIRE1)!=0)
		{
			imagesX[KEY_FIRE1]=sx-(fire1U.size.width/2+16)*zoom;
			imagesY[KEY_FIRE1]=sy-(fire1U.size.height/2+16)*zoom;
		}
		else if ((flags&JFLAG_FIRE2)!=0)
		{
			imagesX[KEY_FIRE2]=sx-(fire2U.size.width/2+16)*zoom;
			imagesY[KEY_FIRE2]=sy-(fire2U.size.height/2+16)*zoom;
		}
	}
	else
	{
		if ((flags&JFLAG_JOYSTICK)!=0)
		{
			imagesX[KEY_JOYSTICK]=sx-(16+joyBack.size.width/2)*zoom;
			imagesY[KEY_JOYSTICK]=sy-(16+joyBack.size.height/2)*zoom;
		}
		if ((flags&JFLAG_FIRE1)!=0 && (flags&JFLAG_FIRE2)!=0)
		{
			imagesX[KEY_FIRE1]=(fire1U.size.width/2+16+fire2U.size.width*2/3)*zoom;
			imagesY[KEY_FIRE1]=sy-(fire1U.size.height/2+16)*zoom;
			imagesX[KEY_FIRE2]=(fire2U.size.width/2+16)*zoom;
			imagesY[KEY_FIRE2]=sy-(fire2U.size.height/2+fire1U.size.height+24)*zoom;
		}
		else if ((flags&JFLAG_FIRE1)!=0)
		{
			imagesX[KEY_FIRE1]=(fire1U.size.width/2+16)*zoom;
			imagesY[KEY_FIRE1]=sy-(fire1U.size.height/2+16)*zoom;
		}
		else if ((flags&JFLAG_FIRE2)!=0)
		{
			imagesX[KEY_FIRE2]=(fire2U.size.width/2+16)*zoom;
			imagesY[KEY_FIRE2]=sy-(fire2U.size.height/2+16)*zoom;
		}
	}
}	
-(void)setXPosition:(int)f withPos:(int)p
{
	if ((f&JFLAG_JOYSTICK)!=0)
	{
		imagesX[KEY_JOYSTICK]=p;
	}
	else if ((f&JFLAG_FIRE1)!=0)
	{
		imagesX[KEY_FIRE1]=p;
	}
	else if ((f&JFLAG_FIRE2)!=0)
	{
		imagesX[KEY_FIRE2]=p;
	}
}
-(void)setYPosition:(int)f withPos:(int)p
{
	if ((f&JFLAG_JOYSTICK)!=0)
	{
		imagesY[KEY_JOYSTICK]=p;
	}
	else if ((f&JFLAG_FIRE1)!=0)
	{
		imagesY[KEY_FIRE1]=p;
	}
	else if ((f&JFLAG_FIRE2)!=0)
	{
		imagesY[KEY_FIRE2]=p;
	}
}
-(void)draw
{
	CRenderer* renderer = app->runView->renderer;

	//Hide the on-screen joysticks when an external controller is connected
	if([app->runView hasAnyGameControllerConnected])
		return;
	
	if ((flags&JFLAG_JOYSTICK)!=0)
	{
		renderer->renderImage(joyBackTex,
							  imagesX[KEY_JOYSTICK]-(joyBackTex->width/2)*zoom,
							  imagesY[KEY_JOYSTICK]-(joyBackTex->height/2)*zoom,
							  joyBackTex->width*zoom,
							  joyBackTex->height*zoom, 0, 0);

		renderer->renderImage(joyFrontTex,
							  imagesX[KEY_JOYSTICK]+joystickX-(joyFrontTex->width/2)*zoom,
							  imagesY[KEY_JOYSTICK]+joystickY-(joyFrontTex->height/2)*zoom,
							  joyFrontTex->width*zoom,
							  joyFrontTex->height*zoom, 0, 0);
	}
	if ((flags&JFLAG_FIRE1)!=0)
	{
		CImage* tex = ((joystick&0x10)==0) ? fire1UTex : fire1DTex;
		renderer->renderImage(tex, imagesX[KEY_FIRE1]-(tex->width/2)*zoom,
							  imagesY[KEY_FIRE1]-(tex->height/2)*zoom,
							  tex->width*zoom,
							  tex->height*zoom,
							  0, 0);
	}
	if ((flags&JFLAG_FIRE2)!=0)
	{
		CImage* tex = ((joystick&0x20)==0) ? fire2UTex : fire2DTex;
		renderer->renderImage(tex, imagesX[KEY_FIRE2]-(tex->width/2)*zoom,
							  imagesY[KEY_FIRE2]-(tex->height/2)*zoom,
							  tex->width*zoom,
							  tex->height*zoom,
							  0, 0);
	}
}

-(void)resetTouches
{
	for (int n=0; n<MAX_TOUCHES; n++)
	{
		touches[n]=nil;
	}
	joystick = joystickX = joystickY = 0;
}

-(BOOL)touchBegan:(UITouch*)touch
{
	//Ignore the on-screen joysticks when an external controller is connected
	if([app->runView hasAnyGameControllerConnected])
		return NO;

	CGPoint position = [touch locationInView:app->runView];
	
	BOOL bFlag=NO;
	int key=[self getKey:position.x withY:position.y];
	if (key!=KEY_NONE)
	{
		touches[key]=touch;
		if (key==KEY_JOYSTICK)
		{
			joystick&=0xF0;
			bFlag=YES;
		}		
		if (key==KEY_FIRE1)
		{
			joystick|=0x10;
			bFlag=YES;
		}
		else if (key==KEY_FIRE2)
		{
			joystick|=0x20;
			bFlag=YES;
		}
	}
	return bFlag;
}
-(void)touchMoved:(UITouch*)touch
{
	//Ignore the on-screen joysticks when an external controller is connected
	if([app->runView hasAnyGameControllerConnected])
		return;

	CGPoint position = [touch locationInView:app->runView];
	
	int key=[self getKey:position.x withY:position.y];
	if (key==KEY_JOYSTICK)
	{
		touches[KEY_JOYSTICK]=touch;
	}
	if (touch==touches[KEY_JOYSTICK])
	{
		joystickX=position.x-imagesX[KEY_JOYSTICK];
		joystickY=position.y-imagesY[KEY_JOYSTICK];
		if (joystickX<-joyBack.size.width/4*zoom)
		{
			joystickX=-joyBack.size.width/4*zoom;
		}
		if (joystickX>joyBack.size.width/4*zoom)
		{
			joystickX=joyBack.size.width/4*zoom;
		}
		if (joystickY<-joyBack.size.height/4*zoom)
		{
			joystickY=-joyBack.size.height/4*zoom;
		}
		if (joystickY>joyBack.size.height/4*zoom)
		{
			joystickY=joyBack.size.height/4*zoom;
		}
		[self setJoystickStateBasedOnXY];
	}
}

-(void)setJoystickStateBasedOnXY
{
	joystick&=0xF0;
	double h=sqrt(joystickX*joystickX+joystickY*joystickY);
	if (h>=joyBack.size.width/6*zoom)
	{
		double angle=atan2(-joystickY, joystickX);
		int j=0;
		if (angle>=0.0)
		{
			if (angle<M_PI/8)
				j=8;
			else if (angle<(M_PI/8)*3)
				j=9;
			else if (angle<(M_PI/8)*5)
				j=1;
			else if (angle<(M_PI/8)*7)
				j=5;
			else
				j=4;
		}
		else
		{
			if (angle>-M_PI/8)
				j=8;
			else if (angle>-(M_PI/8)*3)
				j=0xA;
			else if (angle>-(M_PI/8)*5)
				j=2;
			else if (angle>-(M_PI/8)*7)
				j=6;
			else
				j=4;
		}
		joystick|=j;
	}
}

-(void)touchEnded:(UITouch*)touch
{
	//Ignore the on-screen joysticks when an external controller is connected
	if([app->runView hasAnyGameControllerConnected])
		return;

	int n;
	for (n=0; n<MAX_TOUCHES; n++)
	{
		if (touches[n]==touch)
		{
			touches[n]=nil;
			switch (n)
			{
				case KEY_JOYSTICK:
					joystickX=0;
					joystickY=0;
					joystick&=0xF0;
					break;
				case KEY_FIRE1:
					joystick&=~0x10;
					break;
				case KEY_FIRE2:
					joystick&=~0x20;
					break;
			}
			break;
		}
	}	
}
-(void)touchCancelled:(UITouch*)touch
{
	[self touchEnded:touch];
}

-(int)getKey:(int)x withY:(int)y
{
	if (flags&JFLAG_JOYSTICK)
	{
		if (x>=imagesX[KEY_JOYSTICK]-(joyBack.size.width/2)*zoom && x<imagesX[KEY_JOYSTICK]+(joyBack.size.width/2)*zoom)
		{
			if (y>imagesY[KEY_JOYSTICK]-(joyBack.size.height/2)*zoom && y<imagesY[KEY_JOYSTICK]+(joyBack.size.height/2)*zoom)
			{
				return KEY_JOYSTICK;
			}
		}
	}
	if (flags&JFLAG_FIRE1)
	{
		if (x>=imagesX[KEY_FIRE1]-(fire1U.size.width/2)*zoom && x<imagesX[KEY_FIRE1]+(fire1U.size.width/2)*zoom)
		{
			if (y>imagesY[KEY_FIRE1]-(fire1U.size.height/2)*zoom && y<imagesY[KEY_FIRE1]+(fire1U.size.height/2)*zoom)
			{
				return KEY_FIRE1;
			}
		}
	}
	if (flags&JFLAG_FIRE2)
	{
		if (x>=imagesX[KEY_FIRE2]-(fire2U.size.width/2)*zoom && x<imagesX[KEY_FIRE2]+(fire2U.size.width/2)*zoom)
		{
			if (y>imagesY[KEY_FIRE2]-(fire2U.size.height/2)*zoom && y<imagesY[KEY_FIRE2]+(fire2U.size.height/2)*zoom)
			{
				return KEY_FIRE2;
			}
		}
	}
	return KEY_NONE;
}
-(unsigned char)getJoystick
{
	return joystick;
}
@end
