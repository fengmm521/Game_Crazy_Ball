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
// CRUNMVTSIMPLEELLIPSE
//
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import "CRunMvtExtension.h"

#define MFLAGEL_MOVEATSTART 1

@interface CRunMvtclickteam_simple_ellipse : CRunMvtExtension
{
	int m_dwCX;
    int m_dwCY;
    int m_dwRadiusX;
    int m_dwRadiusY;
    int m_dwStartAngle;
    int m_dwFlags;
    int m_dwAngVel;
    int m_dwOffset;
    BOOL r_Stopped;
    int r_CX;
    int r_CY;
    int r_radiusX;
    int r_radiusY;
    double r_AngVel;
    double r_Offset;
    double r_CurrentAngle;
	
}
-(void)initialize:(CFile*)file;
-(BOOL)move;
-(void)reset;
-(void)setPosition:(int)x withY:(int)y;
-(void)setXPosition:(int)x;
-(void)setYPosition:(int)y;
-(void)stop:(BOOL)bCurrent;
-(void)reverse;
-(void)start;
-(void)setSpeed:(int)speed;
-(double)actionEntry:(int)action;
-(int)getSpeed;

@end
