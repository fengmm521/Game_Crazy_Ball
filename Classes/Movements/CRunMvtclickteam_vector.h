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
// CRUNMVTVECTOR
//
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import "CRunMvtExtension.h"

#define MOVEATSTARTVECT 1
#define HANDLE_DIRECTION 2
#define ToDegrees 57.295779513082320876798154814105
#define ToRadians 0.017453292519943295769236907684886

@interface CRunMvtclickteam_vector : CRunMvtExtension
{
    int m_dwFlags;
    int m_dwVel;
    int m_dwVelAngle;
    int m_dwAcc;
    int m_dwAccAngle;
    BOOL r_Stopped;
    BOOL handleDirection;
    double posX;
    double posY;
    double velX;
    double velY;
    double accX;
    double accY;
    double angle;
    double minSpeed;
    double maxSpeed;
	
}
-(void)initialize:(CFile*)file;
-(BOOL)move;
-(void)reset;
-(BOOL)checkSpeed;
-(void)recalculateAngle;
-(void)setPosition:(int)x withY:(int)y;
-(void)setXPosition:(int)x;
-(void)setYPosition:(int)y;
-(void)stop:(BOOL)bCurrent;
-(void)reverse;
-(void)start;
-(void)setSpeed:(int)speed;
-(void)setMaxSpeed:(int)speed;
-(void)setGravity:(int)gravity;
-(double)actionEntry:(int)action;
-(int)getSpeed;
-(int)getGravity;

@end
