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
// CRUNMVTINANDOUT : Movement inandout!
//
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import "CRunMvtExtension.h"

#define MOVESTATUS_PREPAREOUT 0
#define MOVESTATUS_MOVEOUT 1
#define MOVESTATUS_WAITOUT 2
#define MOVESTATUS_PREPAREIN 3
#define MOVESTATUS_MOVEIN 4
#define MOVESTATUS_WAITIN 5
#define MOVESTATUS_POSITIONIN 6
#define MOVESTATUS_POSITIONOUT 7
#define ACTION_POSITIONIN 0
#define ACTION_POSITIONOUT 1
#define ACTION_MOVEIN 2
#define ACTION_MOVEOUT 3
#define MFLAG_OUTATSTART 0x00000001
#define MFLAG_MOVEATSTART 0x00000002
#define MFLAG_STOPPED 0x00000004
#define MOVETYPE_LINEAR 0
#define MOVETYPE_SMOOTH 1

@interface CRunMvtinandout : CRunMvtExtension
{
	int m_direction;
	int m_speed;
	int m_flags;
	int	m_moveStatus;
	double	m_angle;
	double	m_maxPente;
	int m_moveTimerStart;
	int m_stopTimer;
	int	m_type;
	int	m_startX;
	int	m_startY;
	int	m_destX;
	int	m_destY;	
}
-(void)initialize:(CFile*)file;
-(BOOL)move;
-(void)stop:(BOOL)bCurrent;
-(void)start;
-(double)actionEntry:(int)action;
-(int)getSpeed;

@end
