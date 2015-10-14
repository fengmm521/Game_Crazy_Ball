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
// CTRANS : interface avec un effet de transition
//
//----------------------------------------------------------------------------------
#import "CTrans.h"
#import "CFile.h"
#import "CBitmap.h"
#import "CTransitionData.h"
#import "CRunApp.h"

#import "CRenderToTexture.h"
#import "CRenderer.h"
#import "CRect.h"

@implementation CTrans

-(void)setApp:(CRunApp*)a
{
	app=a;
}

-(void)start:(CTransitionData*)data withRenderer:(CRenderer*)renderer andStart:(CRenderToTexture*)debut andEnd:(CRenderToTexture*)fin andType:(int)type
{
	//dest = display;
	source1 = debut;
	source2 = fin;
	es2renderer = renderer;
	tType = type;
	
	m_initTime = CFAbsoluteTimeGetCurrent()*1000;
	//m_initTime = 0;
	
	m_duration = data->transDuration;
	if (m_duration == 0)
	{
		m_duration = 1;
	}
	m_currentTime = m_initTime;
	m_endTime = m_initTime + m_duration;
	m_running = YES;
	m_starting = YES;
}
-(void)dealloc
{
	if(tType == 1)
	   [source1 release];	//This is 'oldImage'. Only to be released if it's an object transition

	[source2 release];	//This is 'newImage'
	
	[super dealloc];
}
-(void)finish
{
}

-(BOOL)isCompleted
{
	if (m_running)
	{
		//m_currentTime += 10.0f;
		//return (m_currentTime >= m_endTime);
		return (CFAbsoluteTimeGetCurrent()*1000 >= m_endTime);	// m_currentTime >= m_endTime;
	}
	return YES;
}

-(int)getDeltaTime
{
	//Outcomment for fake timer
	m_currentTime = CFAbsoluteTimeGetCurrent()*1000;
	if (m_currentTime > m_endTime)
	{
		m_currentTime = m_endTime;
	}
	return (int) (m_currentTime - m_initTime);
}

-(int)getTimePos
{
	return (int) (m_currentTime - m_initTime);
}

-(void)setTimePos:(double)msTimePos
{
	m_initTime = (m_currentTime - msTimePos);
	m_endTime = m_initTime + m_duration;
}


-(void)initialize:(CTransitionData*)data withFile:(CFile*)file andRenderer:(CRenderer*)renderer andStart:(CRenderToTexture*)source andEnd:(CRenderToTexture*)dest andType:(int)type
{
}

-(char*)stepDraw:(int)flag
{
	return nil;
}

-(void)end
{
}
-(NSString*)description{return @"Transition";}

@end
