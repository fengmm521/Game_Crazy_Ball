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
// CRUNMVTSINWAVE
//
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import "CRunMvtExtension.h"

#define MFLAGSIN_MOVEATSTART 1
#define ONEND_STOP 0
#define ONEND_RESET 1
#define ONEND_BOUNCE 2
#define ONEND_REVERSE 3

@interface CRunMvtclickteam_sinewave : CRunMvtExtension
{
    int m_dwFlags;
    int m_dwSpeed;
    int m_dwFinalX;
    int m_dwFinalY;
    int m_dwAmp;
    int m_dwAngVel;
    int m_dwStartAngle;
    int m_dwOnEnd;
    //*** General variables
    double r_CurrentX;
    double r_CurrentY;
    BOOL r_Stopped;
    int r_OnEnd;
	
    //*** Line motion variables
    int r_Speed;
    int r_StartX;
    int r_StartY;
    int r_FinalX;
    int r_FinalY;
    double r_Dx;
    double r_Dy;
    double r_Steps;
    double r_Angle;
	
    //*** Sine motion variables
    double r_Amp;
    double r_AngVel;
    double r_CurrentAngle;
    double r_Cx;
    double r_Cy;
	
}
-(void)initialize:(CFile*)file;
-(BOOL)move;
-(void)reset;
-(void)setPosition:(int)x withY:(int)y;
-(void)setXPosition:(int)x;
-(void)setYPosition:(int)y;
-(void)stop:(BOOL)bCurrent;
-(void)bounce:(BOOL)bCurrent;
-(void)reverse;
-(void)start;
-(void)setSpeed:(int)speed;
-(double)actionEntry:(int)action;

@end
