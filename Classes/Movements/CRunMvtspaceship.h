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
// CRUNMVTSPACESHIP : Movement spaceship!
//
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import "CRunMvtExtension.h"

@interface CRunMvtspaceship : CRunMvtExtension
{
    int m_dwPower;
    int m_dwRotationSpeed;
    int m_dwInitialSpeed;
    int m_dwInitialDir;
    int m_dwDeceleration;
    int m_dwGravity;
    int m_dwGravityDir;
    int m_dwPlayer;
    int m_dwButton;
    int m_dwFlags;
    double m_X;
    double m_Y;
    double m_xVector;
    double m_yVector;
    double m_xGravity;
    double m_yGravity;
    double m_deceleration;
    double m_power;
    int m_button;
    int m_rotationSpeed;
    int m_rotCounter;
    int m_gravity;
    int m_gravityAngle;
    BOOL m_bStop;
    BOOL m_autoReactor;
    BOOL m_autoRotateRight;
    BOOL m_autoRotateLeft;
    int m_initialSpeed;
	
}
-(void)initialize:(CFile*)file;
-(double)getAngle:(double)vX withVY:(double)vY;
-(double)getVector:(double)vX withVY:(double)vY;
-(BOOL)move;
-(void)setPosition:(int)x withY:(int)y;
-(void)setXPosition:(int)x;
-(void)setYPosition:(int)y;
-(void)stop:(BOOL)bCurrent;
-(void)bounce:(BOOL)bCurrent;
-(void)reverse;
-(void)start;
-(void)setSpeed:(int)speed;
-(void)setDir:(int)dir;
-(void)setDec:(int)dec;
-(void)setRotSpeed:(int)speed;
-(void)setGravity:(int)gravity;
-(double)actionEntry:(int)action;
-(int)getSpeed;
-(int)getAcceleration;
-(int)getDeceleration;
-(int)getGravity;
-(double)fmodf:(double)value;

@end
