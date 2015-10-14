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
// CRUNMVTPINBALL : movement pinball
//
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import "CRunMvtExtension.h"

#define EFLAG_MOVEATSTART 1
#define MPINFLAG_STOPPED 1

@interface CRunMvtpinball : CRunMvtExtension
{
    int m_dwInitialSpeed;
    int m_dwDeceleration;
    int m_dwGravity;
    int m_dwInitialDir;
    int m_dwFlags;
    double m_gravity;
    double m_xVector;
    double m_yVector;
    double m_angle;
    double m_X;
    double m_Y;
    double m_deceleration;
    int m_flags;	
}
-(int)getGravity;
-(int)getDeceleration;
-(int)getSpeed;
-(double)actionEntry:(int)action;
-(void)setGravity:(int)gravity;
-(void)setDir:(int)dir;
-(void)setSpeed:(int)speed;
-(void)start;
-(void)reverse;
-(void)bounce:(BOOL)bCurrent;
-(void)stop:(BOOL)bCurrent;
-(void)setYPosition:(int)y;
-(void)setXPosition:(int)x;
-(void)setPosition:(int)x withY:(int)y;
-(BOOL)move;
-(double)getVector:(double)vX withVY:(double)vY;
-(double)getAngle:(double)vX withVY:(double)vY;
-(void)initialize:(CFile*)file;

@end
