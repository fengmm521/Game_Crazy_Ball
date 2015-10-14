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
// CRUNMVTCIRCULAR : Movement circular!
//
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import "CRunMvtExtension.h"

#define MFLAG1_MOVEATSTART 1
#define ONEND_STOP 0
#define ONEND_RESET 1
#define ONEND_REVERSE_VEL 2
#define ONEND_REVERSE_DIR 3

@interface CRunMvtclickteam_circular : CRunMvtExtension 
{
    int m_dwCX;
    int m_dwCY;
    int m_dwStartAngle;
    int m_dwRadius;
    int m_dwRmin;
    int m_dwRmax;
    int m_dwFlags;
    int m_dwOnEnd;
    int m_dwSpiVel;
    int m_dwAngVel;
    BOOL r_Stopped;
    int r_OnEnd;
    int r_CX;
    int r_CY;
    int r_Rmin;
    int r_Rmax;
    double r_AngVel;
    double r_SpiVel;
    double r_CurrentRadius;
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
