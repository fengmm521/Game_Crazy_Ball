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
// CTransitionCTrans : point d'entree des transitions standart
//
//----------------------------------------------------------------------------------
#import "CTransitionscctrans.h"
#import "CTransitionData.h"
#import "CServices.h"
#import "CFile.h"
#import "CBitmap.h"
#import "CRunApp.h"
#import "CRun.h"
#import "CRenderer.h"
#import "CRenderToTexture.h"

const char* identifiers[]=
{
	"BAND",
	"SE00",
	"SE10",
	"SE12",
	"DOOR",
	"SE03",
	"MOSA",
	"SE05",
	"SE06",
	"SCRL",
	"SE01",
	"SE07",
	"SE09",
	"SE13",	
	"SE08",
	"SE02",
	"ZIGZ",
	"SE04",
	"ZOOM",
	"SE11",
	"FADE",
	nil
};

@implementation CTransitionscctrans

-(CTrans*)getTrans:(CTransitionData*)data
{
	// Extrait l'identifier
	int id=data->transID;
	char idChars[5];
	idChars[0]=(char)(id&0xFF);
	id>>=8;
	idChars[1]=(char)(id&0xFF);
	id>>=8;
	idChars[2]=(char)(id&0xFF);
	id>>=8;
	idChars[3]=(char)(id&0xFF);
	idChars[4]=0;
	
	// Recherche dans la liste
	int n;
	for (n=0; identifiers[n]!=nil; n++)
	{
		if (strcmp(idChars, identifiers[n])==0)
		{
			break;
		}
	}
	
	// Cree la transition
	CTrans* trans=nil;
	switch (n)
	{
		case 0:
			trans=(CTrans*)[[CTransBand alloc] init];
			break;
		case 1:
			trans=(CTrans*)[[CTransAdvancedScrolling alloc] init];
			break;
		case 2:
			trans=(CTrans*)[[CTransBack alloc] init];
			break;
		case 3:
			trans=(CTrans*)[[CTransCell alloc] init];
			break;
		case 4:
			trans=(CTrans*)[[CTransDoor alloc] init];
			break;
		case 5:
			trans=(CTrans*)[[CTransLine alloc] init];
			break;
		case 6:
			trans=(CTrans*)[[CTransMosaic alloc] init];
			break;
		case 7:
			trans=(CTrans*)[[CTransOpen alloc] init];
			break;
		case 8:
			trans=(CTrans*)[[CTransPush alloc] init];
			break;
		case 9:
			trans=(CTrans*)[[CTransScroll alloc] init];
			break;
		case 10:
			trans=(CTrans*)[[CTransSquare alloc] init];
			break;
		case 11:
			trans=(CTrans*)[[CTransStretch alloc] init];
			break;
		case 12:
			trans=(CTrans*)[[CTransStretch2 alloc] init];
			break;
		case 13:
			trans=(CTrans*)[[CTransTrame alloc] init];
			break;
		case 14:
			trans=(CTrans*)[[CTransTurn alloc] init];
			break;
		case 15:
			trans=(CTrans*)[[CTransTurn2 alloc] init];
			break;
		case 16:
			trans=(CTrans*)[[CTransZigZag alloc] init];
			break;
		case 17:
			trans=(CTrans*)[[CTransZigZag2 alloc] init];
			break;
		case 18:
			trans=(CTrans*)[[CTransZoom alloc] init];
			break;
		case 19:
			trans=(CTrans*)[[CTransZoom2 alloc] init];
			break;
		case 20:
			trans=(CTrans*)[[CTransFade alloc] init];
			break;
	}
	return trans;
}
@end


// ADVANCED SCROLLING 
///////////////////////////////////////////////////////////////////////////////////////////

@implementation CTransAdvancedScrolling

-(void)initialize:(CTransitionData*)data withFile:(CFile*)file andRenderer:(CRenderer*)renderer andStart:(CRenderToTexture*)s andEnd:(CRenderToTexture*)d andType:(int)type
{
	dwStyle=[file readAInt];
	[self start:data withRenderer:renderer andStart:s andEnd:d andType:type];
	
	tempBuffer = [[CRenderToTexture alloc] initWithWidth:s->width andHeight:s->height andRunApp:[CRunApp getRunApp]];
	[tempBuffer bindFrameBuffer];
	es2renderer->renderBlitFull(source1);
	[tempBuffer unbindFrameBuffer];
}
-(char*)stepDraw:(int)flag
{
	// 1st time?
	if ( m_starting )
	{
		m_starting = NO;
		m_source2Width = source2->width;
		m_source2Height = source2->height;
		
		if ( dwStyle!=8 )
			m_style = dwStyle;
		else
		{
			m_style=[app->run random:10000];
			m_style=8*m_style/10000;
		}
	}
	
	int elapsedTime = [self getDeltaTime];
	
	if ( ((double)(elapsedTime)/(double)(m_duration))>1.0 )
	{
		es2renderer->renderBlitFull(source2);
	}
	else
	{
		int w, h;
		es2renderer->useBlending(false);
		[tempBuffer bindFrameBuffer];
		
		es2renderer->renderBlitFull(source1);
		
		switch(m_style)
		{
			case 0:
				// Scrolling (To right, to left and to down)
				/////////////////////////////////////////////
				
				w = m_source2Width/3 * elapsedTime / m_duration;
				h = m_source2Height;
				
				es2renderer->renderBlit(source2, 0, 0, m_source2Width/3-w, 0, w, h); // Left Side
				es2renderer->renderBlit(source2, m_source2Width-w, 0, 2*m_source2Width/3, 0, w, h); // Right Side
				w = m_source2Width/3;
				h = m_source2Height * elapsedTime / m_duration;
				es2renderer->renderBlit(source2, w, 0, w, m_source2Height-h, w, h); // Top side
				break;
			case 1:
				// Scrolling (To right, to left and to up)
				/////////////////////////////////////////////
				
				w = m_source2Width/3 * elapsedTime / m_duration;
				h = m_source2Height;
				es2renderer->renderBlit(source2, 0, 0, m_source2Width/3-w, 0, w, h);					// Left Side
				es2renderer->renderBlit(source2, m_source2Width-w, 0, 2*m_source2Width/3, 0, w, h);	// Right Side
				
				w = m_source2Width/3;
				h = m_source2Height * elapsedTime / m_duration;
				es2renderer->renderBlit(source2, w, m_source2Height-h, w, 0, w, h);					// Bottom side
				break;
			case 2:
				// To right, to left and to up
				////////////////////////////////
				
				w = m_source2Width/3 * elapsedTime / m_duration;
				h = m_source2Height;
				es2renderer->renderBlit(source2, 0, 0, m_source2Width/3-w, 0, w, h);					// Left Side
				es2renderer->renderBlit(source2, m_source2Width-w, 0, 2*m_source2Width/3, 0, w, h);	// Right Side
				
				w = m_source2Width/3;
				h = m_source2Height * elapsedTime / m_duration;
				es2renderer->renderBlit(source2, w, 0, w, 0, w, h);									// Top side
				break;
			case 3:
				// To right, to left and to down
				/////////////////////////////////
				
				w = m_source2Width/3 * elapsedTime / m_duration;
				h = m_source2Height;
				es2renderer->renderBlit(source2, 0, 0, m_source2Width/3-w, 0, w, h);					// Left Side
				es2renderer->renderBlit(source2, m_source2Width-w, 0, 2*m_source2Width/3, 0, w, h);	// Right Side
				
				w = m_source2Width/3;
				h = m_source2Height * elapsedTime / m_duration;
				es2renderer->renderBlit(source2, w, m_source2Height-h, w, m_source2Height-h, w, h);	// Bottom side
				break;
			case 4:
				// To right, to left, to down and to up
				////////////////////////////////////////
				
				w = m_source2Width/3 * elapsedTime / m_duration;
				h = m_source2Height;
				es2renderer->renderBlit(source2, 0, 0, m_source2Width/3-w, 0, w, h);					// Left Side
				es2renderer->renderBlit(source2, m_source2Width-w, 0, 2*m_source2Width/3, 0, w, h);	// Right Side
				
				w = m_source2Width/3;
				h = m_source2Height/2 * elapsedTime / m_duration;
				es2renderer->renderBlit(source2, w, 0, w, m_source2Height/2-h, w, h);					// Top side
				es2renderer->renderBlit(source2, w, m_source2Height-h, w, m_source2Height/2, w, h);	// Bottom side
				break;
			case 5:
				// To right, to left, to down and to up
				////////////////////////////////////////
				
				w = m_source2Width/3 * elapsedTime / m_duration;
				h = m_source2Height;
				es2renderer->renderBlit(source2, 0, 0, m_source2Width/3-w, 0, w, h);					// Left Side
				es2renderer->renderBlit(source2, m_source2Width-w, 0, 2*m_source2Width/3, 0, w, h);	// Right Side
				
				w = m_source2Width/3;
				h = m_source2Height/2 * elapsedTime / m_duration;
				es2renderer->renderBlit(source2, w, 0, w, 0, w, h);									// Top side
				es2renderer->renderBlit(source2, w, m_source2Height-h, w, m_source2Height-h, w, h);	// Bottom side
				break;
			case 6:
				// Scrolling (3 bands)
				///////////////////////
				
				w = m_source2Width/3;
				h = m_source2Height * elapsedTime / m_duration;
				
				es2renderer->renderBlit(source2, 0, m_source2Height-h, 0, 0, w, h);					// Band 1
				es2renderer->renderBlit(source2, w, 0, w, m_source2Height-h, w, h);					// Band 2
				es2renderer->renderBlit(source2, w*2, m_source2Height-h, w*2, 0, w, h);				// Band 3
				break;
			case 7:
				// Scrolling (7 bands)
				///////////////////////
				
				w = m_source2Width/7;
				h = m_source2Height * elapsedTime / m_duration;
				
				es2renderer->renderBlit(source2, 0, m_source2Height-h, 0, 0, w, h);					// Band 1
				es2renderer->renderBlit(source2, w, 0, w, m_source2Height-h, w, h);					// Band 2
				es2renderer->renderBlit(source2, w*2, m_source2Height-h, w*2, 0, w, h);				// Band 3
				es2renderer->renderBlit(source2, w*3, 0, w*3, m_source2Height-h, w, h);				// Band 4
				es2renderer->renderBlit(source2, w*4, m_source2Height-h, w*4, 0, w, h);				// Band 5
				es2renderer->renderBlit(source2, w*5, 0, w*5, m_source2Height-h, w, h);				// Band 6
				es2renderer->renderBlit(source2, w*6, m_source2Height-h, w*6, 0, w*2, h);				// Band 7
				break;
			default:
				es2renderer->renderBlitFull(source2);
				break;
		}
		
		[tempBuffer unbindFrameBuffer];
		es2renderer->useBlending(true);
		es2renderer->renderBlitFull(tempBuffer);
	}
	return nil;
}
-(void)end
{
	[tempBuffer release];
	[self finish];
}
-(NSString*)description{return @"AdvancedScrolling";}

@end

//
//////////////////////////////////////////////////////////////////////////////////////////
@implementation CTransBack

-(void)initialize:(CTransitionData*)data withFile:(CFile*)file andRenderer:(CRenderer*)renderer andStart:(CRenderToTexture*)s andEnd:(CRenderToTexture*)d andType:(int)type
{
	dwStyle=[file readAInt];
	[self start:data withRenderer:renderer andStart:s andEnd:d andType:type];        
}
-(char*)stepDraw:(int)flag
{
	
	// 1st time?
	if ( m_starting )
	{
		m_starting = NO;
		m_source2Width = source2->width;
		m_source2Height = source2->height;
	}
	
	int halfWidth = m_source2Width/2;
	int halfHeight = m_source2Height/2;
	
	int elapsedTime = [self getDeltaTime];
	float progress = elapsedTime / (float)m_duration;
	float nProgress = 1.0f - progress;
	
	if ( ((double)(elapsedTime)/(double)(m_duration))>1.0 )
	{
		es2renderer->renderBlitFull(source2);
	}
	else
	{
		int w, h;
		es2renderer->renderBlitFull(source2);
		switch(dwStyle)
		{
			case 0:// OPEN
				w = halfWidth * nProgress;
				h = halfHeight * nProgress;
				es2renderer->renderStretch(source1, 0, 0, w, h, 0, 0, halfWidth, halfHeight);
				w = halfWidth * progress;
				h = halfHeight * nProgress;
				es2renderer->renderStretch(source1, halfWidth+w, 0, halfWidth-w, h, halfWidth, 0, halfWidth, halfHeight);
				w = halfWidth * nProgress;
				h = halfHeight * progress;
				es2renderer->renderStretch(source1, 0, halfHeight+h, w, halfHeight-h, 0, halfHeight, halfWidth, halfHeight);
				w = halfWidth * progress;
				h = halfHeight * progress;
				es2renderer->renderStretch(source1, halfWidth+w, halfHeight+h, halfWidth-w, halfHeight-h, halfWidth, halfHeight, halfWidth, halfHeight);
				break;
			case 1:// SLIDE
				w = m_source2Width * nProgress;
				h = m_source2Height * nProgress;
				es2renderer->renderBlit(source1, 0, 0, m_source2Width-w, m_source2Height-h, w, h);
				break;
			case 2:// SLIDE
				w = m_source2Width * progress;
				h = m_source2Height * nProgress;
				es2renderer->renderBlit(source1, w, 0, 0, m_source2Height-h, m_source2Width-w, h);
				break;
			case 3:// SLIDE
				w = m_source2Width * nProgress;
				h = m_source2Height * progress;
				es2renderer->renderBlit(source1, 0, h, m_source2Width-w, 0, w, m_source2Height-h);
				break;
			case 4:// SLIDE
				w = m_source2Width * progress;
				h = m_source2Height * progress;
				es2renderer->renderBlit(source1, w, h, 0, 0, m_source2Width-w, m_source2Height-h);
				break;
			case 5:// OPEN (SCROLLING)
				w = halfWidth * nProgress;
				h = halfHeight * nProgress;
				es2renderer->renderBlit(source1, w-halfWidth, h-halfHeight, 0, 0, halfWidth, halfHeight);				
				w = halfWidth * progress;
				h = halfHeight * nProgress;
				es2renderer->renderBlit(source1, halfWidth+w, h-halfHeight, halfWidth, 0, halfWidth, halfHeight);
				w = halfWidth * nProgress;
				h = halfHeight * progress;
				es2renderer->renderBlit(source1, w-halfWidth, halfHeight+h, 0, halfHeight, halfWidth, halfHeight);
				w = halfWidth * progress;
				h = halfHeight * progress;
				es2renderer->renderBlit(source1, halfWidth+w, halfHeight+h, halfWidth, halfHeight, halfWidth, halfHeight);
				break;
			case 6: // SLIDE
				h = halfWidth * nProgress;
				es2renderer->renderBlit(source1, 0, h-halfHeight, 0, 0, m_source2Width, halfHeight);
				es2renderer->renderBlit(source1, 0, m_source2Height-h, 0, halfHeight, m_source2Width, halfHeight);
				break;
			case 7: // SLIDE
				w = halfWidth * nProgress;
				es2renderer->renderBlit(source1, w-halfWidth, 0, 0, 0, halfWidth, m_source2Height);
				es2renderer->renderBlit(source1, m_source2Width-w, 0, halfWidth, 0, halfWidth, m_source2Height);
				break;
		}
	}
	return nil;
}
-(void)end
{
	[self finish];
}
-(NSString*)description{return @"Back";}

@end

// TRANSBAND
//////////////////////////////////////////////////////////////////////////////////////////
@implementation CTransBand

-(void)initialize:(CTransitionData*)data withFile:(CFile*)file andRenderer:(CRenderer*)renderer andStart:(CRenderToTexture*)s andEnd:(CRenderToTexture*)d andType:(int)type
{
	bpNbBands=[file readAShort];
	bpDirection=[file readAShort];
	[self start:data withRenderer:renderer andStart:s andEnd:d andType:type];
	
	tempBuffer = [[CRenderToTexture alloc] initWithWidth:s->width andHeight:s->height andRunApp:[CRunApp getRunApp]];
	[tempBuffer bindFrameBuffer];
	es2renderer->renderBlitFull(source1);
	[tempBuffer unbindFrameBuffer];
	
}
-(char*)stepDraw:(int)flag
{
	int sw = source1->width;
	int sh = source1->height;
	int n;
			
	// 1st time? create surface
	if ( m_starting )
	{
		// Security...
		if ( bpNbBands == 0 )
			bpNbBands = 1;
		
		switch (bpDirection) 
		{
			case LEFT_RIGHT:
			case RIGHT_LEFT:
				m_wbande = (sw + bpNbBands - 1)/ bpNbBands;
				if ( m_wbande == 0 )
				{
					m_wbande = 1;
					bpNbBands = (short)sw;
				}
				break;
			default:
				m_wbande = (sh + bpNbBands - 1) / bpNbBands;
				if ( m_wbande == 0 )
				{
					m_wbande = 1;
					bpNbBands = (short)sh;
				}
				break;
		}
		m_rw = 0;
		m_starting = NO;
	}

	es2renderer->useBlending(false);
	[tempBuffer bindFrameBuffer];
	
	// Attention, passer la transparence en parametre...
	if ( bpNbBands <= 0 || m_wbande <= 0 || m_duration == 0 )
		es2renderer->renderBlitFull(source1);	// termine
	else
	{
		int rw = m_wbande * [self getDeltaTime] / m_duration;
		if ( rw > m_rw )
		{
			int x=0, y=0, w=0, h=0;
			for (n=0; n<(int)bpNbBands; n++)
			{
				switch (bpDirection) 
				{
					case LEFT_RIGHT:
						x = (int)m_rw + n * (int)m_wbande;
						y = 0;
						w = (int)rw - (int)m_rw;
						h = (int)sh;
						break;
					case RIGHT_LEFT:
						x = (int)sw - ((int)m_rw + n * (int)m_wbande) - ((int)rw-(int)m_rw);
						y = 0;
						w = (int)rw - (int)m_rw;
						h = (int)sh;
						break;
					case TOP_BOTTOM:
						x = 0;
						y = (int)m_rw + n * (int)m_wbande;
						w = (int)sw;
						h = (int)rw - (int)m_rw;
						break;
					case BOTTOM_TOP:
						x = 0;
						y = (int)sh - ((int)m_rw + n * (int)m_wbande) - ((int)rw-(int)m_rw);
						w = (int)sw;
						h = (int)rw - (int)m_rw;
						break;
				}
				es2renderer->renderBlit(source2, x, y, x, y, w,  h);
			}
		}
		m_rw = rw;
	}
	[tempBuffer unbindFrameBuffer];
	es2renderer->useBlending(true);
	es2renderer->renderBlitFull(tempBuffer);

	return nil;
}
-(void)end
{
	[tempBuffer release];
	[self finish];
}
-(NSString*)description{return @"Band";}

@end

// TRANSCELL
//////////////////////////////////////////////////////////////////////////////////////////
@implementation CTransCell

-(void)initialize:(CTransitionData*)data withFile:(CFile*)file andRenderer:(CRenderer*)renderer andStart:(CRenderToTexture*)s andEnd:(CRenderToTexture*)d andType:(int)type
{
	dwPos=[file readAInt];
	dwPos2=[file readAInt];
	[self start:data withRenderer:renderer andStart:s andEnd:d andType:type];        
}
-(char*)stepDraw:(int)flag
{
	// 1st time?
	if ( m_starting )
	{
		m_starting = NO;
		m_source2Width = source2->width;
		m_source2Height = source2->height;
	}
	
	int elapsedTime = [self getDeltaTime];
	
	if ( ((double)(elapsedTime)/(double)(m_duration))>1.0 )
	{
		es2renderer->renderBlitFull(source2);					// completed
	}
	else
	{
		es2renderer->renderBlitFull(source1);
		int x, y, w, h, i, j, w2, h2;
		double width, height;
		
		width = (double)m_source2Width / (double)dwPos;
		height = (double)m_source2Height / (double)dwPos2;
		w = m_source2Width / dwPos;
		h = m_source2Height / dwPos2;
		
		for ( i=0 ; i<dwPos ; i++ )
		{
			for ( j=0 ; j<dwPos2 ; j++ )
			{
				x = (int)( (double)i * width );
				y = (int)( (double)j * height );
				
				w2 = w * elapsedTime / m_duration;
				h2 = h * elapsedTime / m_duration;
				es2renderer->renderStretch(source2, x+(w-w2)/2, y+(h-h2)/2, w2, h2, x+(w-w2)/2, y+(h-h2)/2, w2, h2);
			}
		}
	}
	return nil;
}
-(void)end
{
	[self finish];
}
-(NSString*)description{return @"Cell";}

@end

// TRANSDOOR
//////////////////////////////////////////////////////////////////////////////////////////
@implementation CTransDoor

-(void)initialize:(CTransitionData*)data withFile:(CFile*)file andRenderer:(CRenderer*)renderer andStart:(CRenderToTexture*)s andEnd:(CRenderToTexture*)d andType:(int)type
{
	m_direction=[file readAShort];
	[self start:data withRenderer:renderer andStart:s andEnd:d andType:type];        
}
-(char*)stepDraw:(int)flag
{
	// 1st time? create surface
	if ( m_starting )
	{
		switch (m_direction) 
		{
			case CENTER_LEFTRIGHT:
			case LEFTRIGHT_CENTER:
				m_wbande = source1->width / 2;
				break;
			default:
				m_wbande = source1->height / 2;
				break;
		}
		m_rw = 0;
		m_starting = NO;
	}
	
	// Attention, passer la transparence en parametre...
	if ( m_wbande == 0 )
		es2renderer->renderBlitFull(source2);	// termine
	else
	{
		es2renderer->renderBlitFull(source1);
		int	x=0, y=0, w=0, h=0;
		int rw = m_wbande * [self getDeltaTime] / m_duration;
		if ( rw > m_rw )
		{
			// 1st band
			switch(m_direction) 
			{
				case CENTER_LEFTRIGHT:
					x = source1->width / 2 - (int)rw;
					y = 0;
					w = (int)rw - (int)m_rw;
					h = source2->height;
					break;
				case LEFTRIGHT_CENTER:
					x = (int)m_rw;
					y = 0;
					w = (int)rw - (int)m_rw;
					h = source2->height;
					break;
				case CENTER_TOPBOTTOM:
					x = 0;
					y = source1->height / 2 - (int)rw;
					w = source2->width;
					h = (int)rw - (int)m_rw;
					break;
				case TOPBOTTOM_CENTER:
					x = 0;
					y = (int)m_rw;
					w = source2->width;
					h = (int)rw - (int)m_rw;
					break;
			}
			es2renderer->renderBlit(source2,  x,  y,  x,  y,  w,  h);
			
			// 2nd band
			switch(m_direction) 
			{
				case CENTER_LEFTRIGHT:
					x = source1->width / 2 + (int)m_rw;
					break;
				case LEFTRIGHT_CENTER:
					x = source1->width - (int)rw;
					break;
				case CENTER_TOPBOTTOM:
					y = source1->height / 2 + (int)m_rw;
					break;
				case TOPBOTTOM_CENTER:
					y = source1->height - (int)rw;
					break;
			}
			es2renderer->renderBlit(source2,  x,  y,  x,  y,  w,  h);
		}
	}
	return nil;
}
-(void)end
{
	[self finish];
}
-(NSString*)description{return @"Door";}

@end

// TRANSFADE
//////////////////////////////////////////////////////////////////////////////////////////
@implementation CTransFade

-(void)initialize:(CTransitionData*)data withFile:(CFile*)file andRenderer:(CRenderer*)renderer andStart:(CRenderToTexture*)s andEnd:(CRenderToTexture*)d andType:(int)type
{
	[self start:data withRenderer:renderer andStart:s andEnd:d andType:type];        
}
-(char*)stepDraw:(int)flag
{
	// 1st time? create surface
	if ( m_starting )
	{
		m_starting = NO;
	}
	
	int fadeCoef;
	
	// Fade in
	if ( (flag & TRFLAG_FADEIN)!=0 )
	{
		fadeCoef = 255 - 255 * [self getDeltaTime] / m_duration;
		es2renderer->renderBlitFull(source1);
		es2renderer->renderFade(source2, fadeCoef);
	}
	// Fade out
	else
	{
		fadeCoef = (255 * [self getDeltaTime] / m_duration);
		es2renderer->renderBlitFull(source2);
		es2renderer->renderFade(source1, fadeCoef);
	}
	return nil;
}
-(void)end
{
	[self finish];
}
-(NSString*)description{return @"Fade";}

@end

// TRANSLINE
//////////////////////////////////////////////////////////////////////////////////////////
@implementation CTransLine

-(void)initialize:(CTransitionData*)data withFile:(CFile*)file andRenderer:(CRenderer*)renderer andStart:(CRenderToTexture*)s andEnd:(CRenderToTexture*)d andType:(int)type
{
	dwPos=[file readAInt];
	dwStyle=[file readAInt];
	dwScrolling=[file readAInt];
	[self start:data withRenderer:renderer andStart:s andEnd:d andType:type];        
}
-(char*)stepDraw:(int)flag
{
	// 1st time?
	if ( m_starting )
	{
		m_starting = NO;
		m_source2Width = source2->width;
		m_source2Height = source2->height;
	}
	
	int elapsedTime = [self getDeltaTime];
	
	if ( ((double)(elapsedTime)/(double)(m_duration))>1.0 )
	{
		es2renderer->renderBlitFull(source2);      // completed
	}
	else
	{
		es2renderer->renderBlitFull(source1);
		int x, y, w, h;
		int i = 0;		// Loop
		int j = 0;		// Loop
		double linesize = 0;
		
		// Horizontal
		if ( dwStyle==0 )
		{
			linesize = (double)m_source2Height / (double)dwPos;
			for ( i=0 ; i<dwPos ; i++ )
			{
				if ( j==0 )
				{
					x = 0;
					y = (int)((double)i * linesize);
					w = m_source2Width * elapsedTime / m_duration;
					
					// Last
					if ( i==dwPos-1 )
						h = m_source2Height;
					else
						h = (int)(linesize+1.0);
					
					// Without scrolling or with scrolling
					if ( dwScrolling==0 )
						es2renderer->renderBlit(source2, x, y, x, y, w, h);
					else
						es2renderer->renderBlit(source2, x, y, m_source2Width-w, y, w, h);
					
					j = 1;
				}
				else
				{
					y = (int)((double)i * linesize);//h;
					w = m_source2Width * elapsedTime / m_duration;
					x = m_source2Width - w;
					
					// Last
					if ( i==dwPos-1 )
						h = m_source2Height;
					else
						h = (int)(linesize+1.0);
					
					// Without scrolling or with scrolling
					if ( dwScrolling==0 )
						es2renderer->renderBlit(source2, x, y, x, y, w, h);
					else
						es2renderer->renderBlit(source2, x, y, 0, y, w, h);
					
					j = 0;
				}
			}
		}
		// Vertical
		else
		{
			linesize = (double)m_source2Width / (double)dwPos;
			for ( i=0 ; i<dwPos ; i++ )
			{
				if ( j==0 )
				{
					x = (int)((double)i * linesize);
					y = 0;
					h = m_source2Height * elapsedTime / m_duration;
					
					// Last
					if ( i==dwPos-1 )
						w = m_source2Width;
					else
						w = (int)(linesize+1);
					
					// Without scrolling or with scrolling
					if ( dwScrolling==0 )
						es2renderer->renderBlit(source2, x, y, x, y, w, h);
					else
						es2renderer->renderBlit(source2, x, y, x, m_source2Height-h, w, h);
					
					j = 1;
				}
				else
				{
					x = (int)((double)i * linesize);
					h = m_source2Height * elapsedTime / m_duration;
					y = m_source2Height - h;
					
					// Last
					if ( i==dwPos-1 )
						w = m_source2Width;
					else
						w = (int)(linesize+1);
					
					// Without scrolling or with scrolling
					if ( dwScrolling==0 )
						es2renderer->renderBlit(source2, x, y, x, y, w, h);
					else
						es2renderer->renderBlit(source2, x, y, x, 0, w, h);
					j = 0;
				}
			}
		}
	}
	return nil;
}
-(void)end
{
	[self finish];
}
-(NSString*)description{return @"Line";}

@end

// TRANSMOSAIC
//////////////////////////////////////////////////////////////////////////////////////////
@implementation CTransMosaic

-(void)initialize:(CTransitionData*)data withFile:(CFile*)file andRenderer:(CRenderer*)renderer andStart:(CRenderToTexture*)s andEnd:(CRenderToTexture*)d andType:(int)type
{
	m_spotPercent=[file readAInt];
	[self start:data withRenderer:renderer andStart:s andEnd:d andType:type];        
}
-(char*)stepDraw:(int)flag
{
	// 1st time? create surface
	if ( m_starting )
	{
		int sw = source1->width;
		int sh = source1->height;
		
		// Spot size: voir si ca rend bien
		m_spotSize = (int)((((int)sw * m_spotPercent / 100) + ((int)sh * m_spotPercent / 100)) / 2);
		if ( m_spotSize == 0 )
			m_spotSize = 1;
		
		// Calcul buffer bits
		int bufSize;
		m_nbBlockPerLine = ((sw + m_spotSize - 1) / m_spotSize);
		m_nbBlockPerCol = ((sh + m_spotSize - 1) / m_spotSize);
		m_nbBlocks = (int)m_nbBlockPerLine * (int)m_nbBlockPerCol;
		bufSize = (m_nbBlocks + 7) / 8 + 2;	// 2 = security
		m_lastNbBlocks = 0;
		m_bitbuf = (unsigned char*)calloc(bufSize, 1);
		m_starting = NO;
	}
	
	if ( m_bitbuf == nil || m_nbBlockPerLine < 2 || m_nbBlockPerCol < 2 || m_duration == 0 )
		es2renderer->renderBlitFull(source2);	// termine
	else
	{
		int NB_TRIES=1;
		int i;
		int l, xb=0, yb=0;
		int nbBlocks = (int)((double)m_nbBlocks * (double)[self getDeltaTime] / (double)m_duration);
		int nbCurrentBlocks = nbBlocks - m_lastNbBlocks;
		if ( nbCurrentBlocks != 0 )
		{
			es2renderer->useBlending(false);
			m_lastNbBlocks = nbBlocks;
			for (l=0; l<nbCurrentBlocks; l++)
			{
				// Get random block coordinates
				for (i=0; i<NB_TRIES; i++)
				{
					xb = [app->run random:m_nbBlockPerLine];
					yb = [app->run random:m_nbBlockPerCol];
					
					int	nb, off;
					unsigned char mask;
					
					nb = yb * m_nbBlockPerLine + xb;
					off = nb/8;
					mask = (unsigned char)(1 << (nb&7));
					if ( (m_bitbuf[off] & mask) == 0 )
					{
						m_bitbuf[off] |= mask;
						break;
					}
					
					int pBuf=off; 
					int	nbb = (m_nbBlocks+7)/8;
					int	b;
					BOOL	r = NO;
					for (b=off; b<nbb; b++, pBuf++)
					{
						if ( m_bitbuf[pBuf] != 0xFF )
						{
							yb = (b*8) / m_nbBlockPerLine;
							xb = (b*8) % m_nbBlockPerLine;
							for (mask=1; mask!=0; mask<<=1)
							{
								if ( (m_bitbuf[pBuf] & mask) == 0 )
								{
									m_bitbuf[pBuf] |= mask;
									r = YES;
									break;
								}
								if ( ++xb >= m_nbBlockPerLine )
								{
									xb = 0;
									if ( ++yb >= m_nbBlockPerCol )
										break;
								}
							}
							if ( r )
								break;								
						}
					}
					if ( r )
						break;
					
					pBuf = 0;
					for (b=0; b<off; b++, pBuf++)
					{
						if ( m_bitbuf[pBuf] != 255 )
						{
							yb = (b*8) / m_nbBlockPerLine;
							xb = (b*8) % m_nbBlockPerLine;
							for (mask=1; mask!=0; mask<<=1)
							{
								if ( (m_bitbuf[pBuf] & mask) == 0 )
								{
									m_bitbuf[pBuf] |= mask;
									r = YES;
									break;
								}
								if ( ++xb >= m_nbBlockPerLine )
								{
									xb = 0;
									if ( ++yb >= m_nbBlockPerCol )
										break;
								}
							}
							if ( r )
								break;
						}
						if ( r )
							break;
						
						r = NO;
					}
				}
				if ( i < NB_TRIES )
				{
					[source1 bindFrameBuffer];
					es2renderer->renderBlit(source2, (int)xb*(int)m_spotSize,  (int)yb*(int)m_spotSize, (int)xb*(int)m_spotSize,  (int)yb*(int)m_spotSize,  (int)m_spotSize,  (int)m_spotSize);
					[source1 unbindFrameBuffer];
				}
			}
		}
		es2renderer->useBlending(true);
		es2renderer->renderBlitFull(source1);
	}
	return nil;
}
-(void)end
{
	free(m_bitbuf);
	[self finish];
}
-(NSString*)description{return @"Mosaic";}

@end

// TRANSOPEN
//////////////////////////////////////////////////////////////////////////////////////////
@implementation CTransOpen

-(void)initialize:(CTransitionData*)data withFile:(CFile*)file andRenderer:(CRenderer*)renderer andStart:(CRenderToTexture*)s andEnd:(CRenderToTexture*)d andType:(int)type
{
	dwStyle=[file readAInt];
	[self start:data withRenderer:renderer andStart:s andEnd:d andType:type];
	
	tempBuffer = [[CRenderToTexture alloc] initWithWidth:s->width andHeight:s->height andRunApp:[CRunApp getRunApp]];
	[tempBuffer bindFrameBuffer];
	es2renderer->renderBlitFull(source1);
	[tempBuffer unbindFrameBuffer];
}
-(char*)stepDraw:(int)flag
{
	// 1st time?
	if ( m_starting )
	{
		m_starting = NO;
		m_source2Width = source2->width;
		m_source2Height = source2->height;
	}
	
	int elapsedTime = [self getDeltaTime];
	double pourcentage = (double)(elapsedTime)/(double)(m_duration);
	
	es2renderer->useBlending(false);
	[tempBuffer bindFrameBuffer];
	
	
	if ( pourcentage>1.0 )
	{
		es2renderer->renderBlitFull(source2);					// completed
	}
	else
	{
		int x, y, w, h;
		
		[source1 bindFrameBuffer];
		if ( pourcentage<0.3 )
		{
			w = m_source2Width*2 * elapsedTime / m_duration;
			w *= 2;
			h = m_source2Height / 7;
			x = m_source2Width/2 - w/2;
			y = m_source2Height/2 - h/2;
			es2renderer->renderBlit(source2, x, y, x, y, w, h);
			
			w = m_source2Width / 7;
			h = m_source2Height*2 * elapsedTime / m_duration;
			h *= 2;
			x = m_source2Width/2 - w/2;
			y = m_source2Height/2 - h/2;
			es2renderer->renderBlit(source2, x, y, x, y, w, h);
		}
		else
		{
			x = m_source2Width/2;
			w = m_source2Width * elapsedTime / m_duration - x;
			h = m_source2Height/2;
			y = 0;
			es2renderer->renderBlit(source2, x, y, x, y, w, h);
			
			y = m_source2Height/2;
			h = m_source2Height * elapsedTime / m_duration - y;
			w = m_source2Width/2;
			x = w;
			es2renderer->renderBlit(source2, x, y, x, y, w, h);
			
			w = m_source2Width * elapsedTime / m_duration - m_source2Width/2;
			x = m_source2Width/2 - w;
			h = m_source2Height/2;
			y = h;
			es2renderer->renderBlit(source2, x, y, x, y, w, h);
			
			h = m_source2Height * elapsedTime / m_duration - m_source2Height/2;
			y = m_source2Height/2 - h;
			w = m_source2Width/2;
			x = 0;
			es2renderer->renderBlit(source2, x, y, x, y, w, h);
		}
		[source1 unbindFrameBuffer];
		es2renderer->renderBlitFull(source1);
	}
	
	[tempBuffer unbindFrameBuffer];
	es2renderer->useBlending(true);
	es2renderer->renderBlitFull(tempBuffer);
	return nil;
}
-(void)end
{
	[tempBuffer release];
	[self finish];
}
-(NSString*)description{return @"Open";}

@end

// TRANSPUSH
//////////////////////////////////////////////////////////////////////////////////////////
@implementation CTransPush

-(void)initialize:(CTransitionData*)data withFile:(CFile*)file andRenderer:(CRenderer*)renderer andStart:(CRenderToTexture*)s andEnd:(CRenderToTexture*)d andType:(int)type
{
	dwStyle=[file readAInt];
	[self start:data withRenderer:renderer andStart:s andEnd:d andType:type];        
}
-(char*)stepDraw:(int)flag
{
	// 1st time?
	if ( m_starting )
	{
		m_starting = NO;
		m_source2Width = source2->width;
		m_source2Height = source2->height;
		m_refresh = NO;
	}
	
	int elapsedTime = [self getDeltaTime];
	
	double pourcentage = (double)(elapsedTime)/(double)(m_duration);
	if ( pourcentage>1.0 )
	{
		es2renderer->renderBlitFull(source2);
	}
	else
	{
		es2renderer->renderBlitFull(source1);
		int x, y, w, h;
		
		// First Scrolling
		if ( pourcentage<=0.5 )
		{
			switch(dwStyle)
			{
				case 0:
					w = m_source2Width * elapsedTime / m_duration * 2;
					h = m_source2Height/2;
					x = m_source2Width - w;
					y = m_source2Height/2;
					es2renderer->renderBlit(source2, 0, 0, x, y, w, h);
					break;
				case 1:
					w = m_source2Width * elapsedTime / m_duration * 2;
					h = m_source2Height/2;
					x = m_source2Width - w;
					y = m_source2Height/2;
					es2renderer->renderBlit(source2, x, 0, 0, y, w, h);
					break;
				case 2:
					w = m_source2Width * elapsedTime / m_duration * 2;
					h = m_source2Height/2;
					x = m_source2Width - w;
					y = m_source2Height/2;
					es2renderer->renderBlit(source2, 0, y, x, 0, w, h);
					break;
				case 3:
					w = m_source2Width * elapsedTime / m_duration * 2;
					h = m_source2Height/2;
					x = m_source2Width - w;
					y = m_source2Height/2;
					es2renderer->renderBlit(source2, x, y, 0, 0, w, h);
					break;
			}
		}
		
		// Second Scrolling
		if ( pourcentage>0.5 )
		{
			if ( m_refresh==NO )
			{
				if ( dwStyle<=1 )
					es2renderer->renderBlit(source2, 0, 0, 0, m_source2Height/2, m_source2Width, m_source2Height/2);
				else
					es2renderer->renderBlit(source2, 0, m_source2Height/2, 0, 0, m_source2Width, m_source2Height/2);
				m_refresh = YES;
			}
			
			pourcentage = (double)elapsedTime - (double)m_duration/2.0;
			pourcentage /= (double)m_duration / 2.0;
			pourcentage *= 1000;
			h = m_source2Height/2 * (int)pourcentage / 1000;
			
			switch(dwStyle)
			{
				case 0:
				case 1:
					es2renderer->renderStretch(source2,  0,  h, m_source2Width,  m_source2Height/2, 0,  m_source2Height/2,  m_source2Width,  m_source2Height/2);
					es2renderer->renderStretch(source2,  0,  0,  m_source2Width,  h, 0,  m_source2Height/2-h,  m_source2Width,  h);
					break;
				case 2:
				case 3:
					es2renderer->renderStretch(source2,  0,  m_source2Height/2-h, m_source2Width,  m_source2Height/2, 0,  0,  m_source2Width,  m_source2Height/2);
					es2renderer->renderStretch(source2,  0,  m_source2Height-h,  m_source2Width,  h,  0,  m_source2Height/2,  m_source2Width,  h);
					break;
			}
		}
	}
	return nil;
}
-(void)end
{
	[self finish];
}
-(NSString*)description{return @"Push";}

@end

// TRANSSCROLL
//////////////////////////////////////////////////////////////////////////////////////////
@implementation CTransScroll

-(void)initialize:(CTransitionData*)data withFile:(CFile*)file andRenderer:(CRenderer*)renderer andStart:(CRenderToTexture*)s andEnd:(CRenderToTexture*)d andType:(int)type
{
	m_direction=[file readAInt];
	[self start:data withRenderer:renderer andStart:s andEnd:d andType:type];        
}
-(char*)stepDraw:(int)flag
{
	int sw = source1->width;
	int sh = source1->height;
	
	// 1st time? create surface
	if ( m_starting )
	{
		switch (m_direction) 
		{
			case LEFT_RIGHT:
			case RIGHT_LEFT:
				m_wbande = sw;
				break;
			default:
				m_wbande = sh;
				break;
		}
		m_rw = 0;
		m_starting = NO;
	}
	
	if ( m_duration == 0 )
		es2renderer->renderBlitFull(source2);  // termine
	else
	{
		es2renderer->renderBlitFull(source1);
		int rw = m_wbande * [self getDeltaTime] / m_duration;
		if ( rw > m_rw )
		{
			int x=0, y=0;
			
			switch (m_direction) 
			{
				case LEFT_RIGHT:
					x = (int)rw - sw;
					y = 0;
					break;
				case RIGHT_LEFT:
					x = sw - (int)rw;
					y = 0;
					break;
				case TOP_BOTTOM:
					x = 0;
					y = (int)rw - sh;
					break;
				case BOTTOM_TOP:
					x = 0;
					y = sh - (int)rw;
					break;
			}
			es2renderer->renderBlit(source2,  x,  y,  0,  0,  sw,  sh);
			m_rw = rw;
		}
	}
	return nil;
}
-(void)end
{
	[self finish];
}
-(NSString*)description{return @"Scroll";}

@end

// TRANSSQUARE
//////////////////////////////////////////////////////////////////////////////////////////
@implementation CTransSquare

-(void)initialize:(CTransitionData*)data withFile:(CFile*)file andRenderer:(CRenderer*)renderer andStart:(CRenderToTexture*)s andEnd:(CRenderToTexture*)d andType:(int)type
{
	dwStyle=[file readAInt];
	dwPos=[file readAInt];
	dwStretch=[file readAInt];
	[self start:data withRenderer:renderer andStart:s andEnd:d andType:type];        
}
-(char*)stepDraw:(int)flag
{
	// 1st time?
	if ( m_starting )
	{
		m_starting = NO;
		m_source2Width = source2->width;
		m_source2Height = source2->height;
	}
	
	int elapsedTime = [self getDeltaTime];
	
	if ( ((double)(elapsedTime)/(double)(m_duration))>1.0 )
	{
		es2renderer->renderBlitFull(source2);													// completed
	}
	else
	{
		es2renderer->renderBlitFull(source1);
		int x, y, w, h;
		int width, height;
		
		// Inside Square
		/////////////////
		
		width = m_source2Width * dwPos / 100;
		height = m_source2Height * dwPos / 100;
		
		w = width * elapsedTime / m_duration;
		h = height * elapsedTime / m_duration;
		x = m_source2Width/2 - w/2;
		y = m_source2Height/2 - h/2;
		
		// No Stretch
		if ( dwStretch==0 )
			es2renderer->renderBlit(source2, x, y, x, y, w, h);
		else
			es2renderer->renderStretch(source2,  x,  y,  w,  h,  m_source2Width/2-width/2,  m_source2Height/2-height/2,  width,  height);
		
		// Outside Square
		//////////////////
		
		int pos = 100 - dwPos;
		width = m_source2Width * pos / 100;
		height = m_source2Height * pos / 100;
		
		w = width/2 * elapsedTime / m_duration;
		h = height/2 * elapsedTime / m_duration;
		es2renderer->renderBlit(source2, 0, 0, 0, 0, m_source2Width, h);									// Up To Down
		es2renderer->renderBlit(source2, 0, 0, 0, 0, w, m_source2Height);									// Left to Right
		es2renderer->renderBlit(source2, 0, m_source2Height-h, 0, m_source2Height-h, m_source2Width, h);	// Down To Up
		es2renderer->renderBlit(source2, m_source2Width-w, 0, m_source2Width-w, 0, w, m_source2Height);	// Right To Left
	}
	return nil;
}
-(void)end
{
	[self finish];
}
-(NSString*)description{return @"Square";}

@end

// TRANSSTRETCH
//////////////////////////////////////////////////////////////////////////////////////////
@implementation CTransStretch

-(void)initialize:(CTransitionData*)data withFile:(CFile*)file andRenderer:(CRenderer*)renderer andStart:(CRenderToTexture*)s andEnd:(CRenderToTexture*)d andType:(int)type
{
	dwStyle=[file readAInt];
	[self start:data withRenderer:renderer andStart:s andEnd:d andType:type];        
}
-(char*)stepDraw:(int)flag
{
	// 1st time?
	if ( m_starting )
	{
		m_starting = NO;
		m_source2Width = source2->width;
		m_source2Height = source2->height;
	}
	
	int elapsedTime = [self getDeltaTime];
	
	if ( ((double)(elapsedTime)/(double)(m_duration))>1.0 )
	{
		es2renderer->renderBlitFull(source2);					// completed
	}
	else
	{
		es2renderer->renderBlitFull(source1);
		int w, h;
		
		switch(dwStyle)
		{
                // Top Left
			case 0:
				w = m_source2Width * elapsedTime / m_duration;
				h = m_source2Height * elapsedTime / m_duration;
				es2renderer->renderStretch(source2,  0, 0, w, h,  0, 0, m_source2Width,  m_source2Height);
				break;
                // Top Right
			case 1:
				w = m_source2Width * elapsedTime / m_duration;
				h = m_source2Height * elapsedTime / m_duration;
				es2renderer->renderStretch(source2, m_source2Width-w, 0, w, h,  0, 0, m_source2Width,  m_source2Height);
				break;
                // Bottom Left
			case 2:
				w = m_source2Width * elapsedTime / m_duration;
				h = m_source2Height * elapsedTime / m_duration;
				es2renderer->renderStretch(source2, 0, m_source2Height-h, w, h,  0, 0, m_source2Width,  m_source2Height);
				break;
                // Bottom Right
			case 3:
				w = m_source2Width * elapsedTime / m_duration;
				h = m_source2Height * elapsedTime / m_duration;
				es2renderer->renderStretch(source2, m_source2Width-w, m_source2Height-h, w, h,  0, 0, m_source2Width,  m_source2Height);
				break;
                // 4 corners
			case 4:
				// Top Left
				w = m_source2Width/2 * elapsedTime / m_duration;
				h = m_source2Height/2 * elapsedTime / m_duration;
				if ( h<5 )
                    h = 5;
				es2renderer->renderStretch(source2, 0, 0, w, h, 0, 0, source1->width/2, source1->height/2);
				// Top Right
				w = m_source2Width/2 * elapsedTime / m_duration;
				h = m_source2Height/2 * elapsedTime / m_duration;
				if ( h<5 )
					h = 5;
				es2renderer->renderStretch(source2, m_source2Width-w, 0, w, h, m_source2Width/2, 0, m_source2Width/2, m_source2Height/2);
				// Bottom Left
				w = m_source2Width/2 * elapsedTime / m_duration;
				h = m_source2Height/2 * elapsedTime / m_duration;
				es2renderer->renderStretch(source2, 0, m_source2Height-h, w, h, 0, m_source2Height/2, m_source2Width/2, m_source2Height/2);
				// Bottom Right
				w = m_source2Width/2 * elapsedTime / m_duration;
				h = m_source2Height/2 * elapsedTime / m_duration;
				es2renderer->renderStretch(source2, m_source2Width-w, m_source2Height-h, w, h, m_source2Width/2, m_source2Height/2, m_source2Width/2, m_source2Height/2);
				break;
                // Center
			case 5:
				// Top Left
				w = m_source2Width/2 * elapsedTime / m_duration;
				h = m_source2Height/2 * elapsedTime / m_duration;
				if ( h<5 )
					h = 5;
				es2renderer->renderStretch(source2, m_source2Width/2-w, m_source2Height/2-h, w, h, 0, 0, source1->width/2, source1->height/2);
				// Top Right
				w = m_source2Width/2 * elapsedTime / m_duration;
				h = m_source2Height/2 * elapsedTime / m_duration;
				if ( h<5 )
					h = 5;
				es2renderer->renderStretch(source2, m_source2Width/2, m_source2Height/2-h, w, h, m_source2Width/2, 0, m_source2Width/2, m_source2Height/2);
				// Bottom Left
				w = m_source2Width/2 * elapsedTime / m_duration;
				h = m_source2Height/2 * elapsedTime / m_duration;
				es2renderer->renderStretch(source2, m_source2Width/2-w, m_source2Height/2, w, h, 0, m_source2Height/2, m_source2Width/2, m_source2Height/2);
				// Bottom Right
				w = m_source2Width/2 * elapsedTime / m_duration;
				h = m_source2Height/2 * elapsedTime / m_duration;
				es2renderer->renderStretch(source2, m_source2Width/2, m_source2Height/2, w, h, m_source2Width/2, m_source2Height/2, m_source2Width/2, m_source2Height/2);
				break;
                // Top Middle
			case 6:
				w = m_source2Width;
				h = m_source2Height * elapsedTime / m_duration;
				es2renderer->renderStretch(source2, 0, 0, w, h,  0, 0, m_source2Width,  m_source2Height);
				break;
                // Middle Left
			case 7:
				w = m_source2Width * elapsedTime / m_duration;
				h = m_source2Height;
				es2renderer->renderStretch(source2, 0, 0, w, h,  0, 0, m_source2Width,  m_source2Height);
				break;
                // Middle Right
			case 8:
				w = m_source2Width * elapsedTime / m_duration;
				h = m_source2Height;
				es2renderer->renderStretch(source2, m_source2Width-w, 0, w, h,  0, 0, m_source2Width,  m_source2Height);
				break;
                // Bottom Middle
			case 9:
				w = m_source2Width;
				h = m_source2Height * elapsedTime / m_duration;
				es2renderer->renderStretch(source2, 0, m_source2Height-h, w, h,  0, 0, m_source2Width,  m_source2Height);
				break;
		}
	}
	return nil;
}
-(void)end
{
	[self finish];
}
-(NSString*)description{return @"Stretch";}

@end

// TRANSSTRECH2
//////////////////////////////////////////////////////////////////////////////////////////
@implementation CTransStretch2

-(void)initialize:(CTransitionData*)data withFile:(CFile*)file andRenderer:(CRenderer*)renderer andStart:(CRenderToTexture*)s andEnd:(CRenderToTexture*)d andType:(int)type
{
	dwStyle=[file readAInt];
	[self start:data withRenderer:renderer andStart:s andEnd:d andType:type];        
}
-(char*)stepDraw:(int)flag
{
	// 1st time?
	if ( m_starting )
	{
		m_starting = NO;
		m_source2Width = source2->width;
		m_source2Height = source2->height;
		m_phase = 0;
	}
	
	int elapsedTime = [self getDeltaTime];
	
	if(tType == 0)
		es2renderer->clear();	//Clear the background if frame transition

	if ( ((double)(elapsedTime)/(double)(m_duration))>1.0 )
	{
		es2renderer->renderBlitFull(source2);					// completed
	}
	else
	{
		int w, h;
		
		switch(dwStyle)
		{
                // Top Left
			case 0:
				if ( m_phase==0 )
				{
					w = 2 * m_source2Width * elapsedTime / m_duration;
					w = m_source2Width - w;
					h = 2 * m_source2Height * elapsedTime / m_duration;
					h = m_source2Height - h;
					
					es2renderer->renderStretch(source1,  0, 0, w, h,  0, 0, m_source2Width,  m_source2Height);
					
					if ( elapsedTime>=m_duration/2 )
						m_phase = 1;
				}
				else
				{
					w = 2 * m_source2Width * elapsedTime / m_duration;
					w -= m_source2Width;
					h = 2 * m_source2Height * elapsedTime / m_duration;
					h -= m_source2Height;
					es2renderer->renderStretch(source2, 0, 0, w, h,  0, 0, m_source2Width,  m_source2Height);
				}
				break;
                // Top Middle
			case 1:
				if ( m_phase==0 )
				{
					w = m_source2Width;
					h = 2 * m_source2Height * elapsedTime / m_duration;
					h = m_source2Height - h;
					
					es2renderer->renderStretch(source1, 0, 0, w, h,  0, 0, m_source2Width,  m_source2Height);
					
					if ( elapsedTime>=m_duration/2 )
						m_phase = 1;
				}
				else
				{
					w = m_source2Width;
					h = 2 * m_source2Height * elapsedTime / m_duration;
					h -= m_source2Height;
					es2renderer->renderStretch(source2, 0, 0, w, h,  0, 0, m_source2Width,  m_source2Height);
				}
				break;
                // Top Right
			case 2:
				if ( m_phase==0 )
				{
					w = 2 * m_source2Width * elapsedTime / m_duration;
					w = m_source2Width - w;
					h = 2 * m_source2Height * elapsedTime / m_duration;
					h = m_source2Height - h;
					
					es2renderer->renderStretch(source1, m_source2Width-w, 0, w, h,  0, 0, m_source2Width,  m_source2Height);
					
					if ( elapsedTime>=m_duration/2 )
						m_phase = 1;
				}
				else
				{
					w = 2 * m_source2Width * elapsedTime / m_duration;
					w -= m_source2Width;
					h = 2 * m_source2Height * elapsedTime / m_duration;
					h -= m_source2Height;
					es2renderer->renderStretch(source2, m_source2Width-w, 0, w, h,  0, 0, m_source2Width,  m_source2Height);
				}
				break;
                // Middle Left
			case 3:
				if ( m_phase==0 )
				{
					w = 2 * m_source2Width * elapsedTime / m_duration;
					w = m_source2Width - w;
					h = m_source2Height;
					
					es2renderer->renderStretch(source1, 0, 0, w, h,  0, 0, m_source2Width,  m_source2Height);
					
					if ( elapsedTime>=m_duration/2 )
						m_phase = 1;
				}
				else
				{
					w = 2 * m_source2Width * elapsedTime / m_duration;
					w -= m_source2Width;
					h = m_source2Height;
					es2renderer->renderStretch(source2, 0, 0, w, h,  0, 0, m_source2Width,  m_source2Height);
				}
				break;
                // Center H
			case 4:
				if ( m_phase==0 )
				{
					w = 2 * m_source2Width * elapsedTime / m_duration;
					w = m_source2Width - w;
					h = m_source2Height;
					
					es2renderer->renderStretch(source1, m_source2Width/2-w/2, 0, w, h,  0, 0, m_source2Width,  m_source2Height);
					
					if ( elapsedTime>=m_duration/2 )
						m_phase = 1;
				}
				else
				{
					w = 2 * m_source2Width * elapsedTime / m_duration;
					w -= m_source2Width;
					h = m_source2Height;
					es2renderer->renderStretch(source2, m_source2Width/2-w/2, 0, w, h,  0, 0, m_source2Width,  m_source2Height);
				}
				break;
                // Center V
			case 5:
				if ( m_phase==0 )
				{
					h = 2 * m_source2Height * elapsedTime / m_duration;
					h = m_source2Height - h;
					w = m_source2Width;
					
					es2renderer->renderStretch(source1, 0, m_source2Height/2-h/2, w, h,  0, 0, m_source2Width,  m_source2Height);
					
					if ( elapsedTime>=m_duration/2 )
						m_phase = 1;
				}
				else
				{
					h = 2 * m_source2Height * elapsedTime / m_duration;
					h -= m_source2Height;
					w = m_source2Width;
					es2renderer->renderStretch(source2, 0, m_source2Height/2-h/2, w, h,  0, 0, m_source2Width,  m_source2Height);
				}
				break;
                // Center H+V
			case 6:
				if ( m_phase==0 )
				{
					w = 2 * m_source2Width * elapsedTime / m_duration;
					w = m_source2Width - w;
					h = 2 * m_source2Height * elapsedTime / m_duration;
					h = m_source2Height - h;
					
					es2renderer->renderStretch(source1, m_source2Width/2-w/2, m_source2Height/2-h/2, w, h,  0, 0, m_source2Width,  m_source2Height);
					
					if ( elapsedTime>=m_duration/2 )
						m_phase = 1;
				}
				else
				{
					w = 2 * m_source2Width * elapsedTime / m_duration;
					w -= m_source2Width;
					h = 2 * m_source2Height * elapsedTime / m_duration;
					h -= m_source2Height;
					es2renderer->renderStretch(source2, m_source2Width/2-w/2, m_source2Height/2-h/2, w, h,  0, 0, m_source2Width,  m_source2Height);
				}
				break;
                // Middle Right
			case 7:
				if ( m_phase==0 )
				{
					w = 2 * m_source2Width * elapsedTime / m_duration;
					w = m_source2Width - w;
					h = m_source2Height;
					
					es2renderer->renderStretch(source1, m_source2Width-w, 0, w, h,  0, 0, m_source2Width,  m_source2Height);
					
					if ( elapsedTime>=m_duration/2 )
						m_phase = 1;
				}
				else
				{
					w = 2 * m_source2Width * elapsedTime / m_duration;
					w -= m_source2Width;
					h = m_source2Height;
					es2renderer->renderStretch(source2, m_source2Height-w, 0, w, h,  0, 0, m_source2Width,  m_source2Height);
				}
				break;
                // Bottom Left
			case 8:
				if ( m_phase==0 )
				{
					w = 2 * m_source2Width * elapsedTime / m_duration;
					w = m_source2Width - w;
					h = 2 * m_source2Height * elapsedTime / m_duration;
					h = m_source2Height - h;
					
					es2renderer->renderStretch(source1, 0, m_source2Height-h, w, h,  0, 0, m_source2Width,  m_source2Height);
					
					if ( elapsedTime>=m_duration/2 )
						m_phase = 1;
				}
				else
				{
					w = 2 * m_source2Width * elapsedTime / m_duration;
					w -= m_source2Width;
					h = 2 * m_source2Height * elapsedTime / m_duration;
					h -= m_source2Height;
					es2renderer->renderStretch(source2, 0, m_source2Height-h, w, h,  0, 0, m_source2Width,  m_source2Height);
				}
				break;
                // Bottom Middle
			case 9:
				if ( m_phase==0 )
				{
					w = m_source2Width;
					h = 2 * m_source2Height * elapsedTime / m_duration;
					h = m_source2Height - h;
					
					es2renderer->renderStretch(source1, 0, m_source2Height-h, w, h,  0, 0, m_source2Width,  m_source2Height);
					
					if ( elapsedTime>=m_duration/2 )
						m_phase = 1;
				}
				else
				{
					w = m_source2Width;
					h = 2 * m_source2Height * elapsedTime / m_duration;
					h -= m_source2Height;
					es2renderer->renderStretch(source2, 0, m_source2Height-h, w, h,  0, 0, m_source2Width,  m_source2Height);
				}
				break;
                // Bottom Right
			case 10:
				if ( m_phase==0 )
				{
					w = 2 * m_source2Width * elapsedTime / m_duration;
					w = m_source2Width - w;
					h = 2 * m_source2Height * elapsedTime / m_duration;
					h = m_source2Height - h;
					
					es2renderer->renderStretch(source1, m_source2Width-w, m_source2Height-h, w, h,  0, 0, m_source2Width,  m_source2Height);
					
					if ( elapsedTime>=m_duration/2 )
						m_phase = 1;
				}
				else
				{
					w = 2 * m_source2Width * elapsedTime / m_duration;
					w -= m_source2Width;
					h = 2 * m_source2Height * elapsedTime / m_duration;
					h -= m_source2Height;
					es2renderer->renderStretch(source2, m_source2Width-w, m_source2Height-h, w, h,  0, 0, m_source2Width,  m_source2Height);
				}
				break;
		}
	}
	return nil;
}
-(void)end
{
	[self finish];
}
-(NSString*)description{return @"Stretch2";}

@end

// TRANSTRAME
//////////////////////////////////////////////////////////////////////////////////////////
@implementation CTransTrame

-(void)initialize:(CTransitionData*)data withFile:(CFile*)file andRenderer:(CRenderer*)renderer andStart:(CRenderToTexture*)s andEnd:(CRenderToTexture*)d andType:(int)type
{
	dwStyle=[file readAInt];
	[self start:data withRenderer:renderer andStart:s andEnd:d andType:type];    
    
	tempBuffer = [[CRenderToTexture alloc] initWithWidth:s->width andHeight:s->height andRunApp:[CRunApp getRunApp]];
	[tempBuffer bindFrameBuffer];
	es2renderer->renderBlitFull(source1);
	[tempBuffer unbindFrameBuffer];
}
-(char*)stepDraw:(int)flag
{
	// 1st time?
	if ( m_starting )
	{
		m_starting = NO;
		m_source2Width = source2->width;
		m_source2Height = source2->height;
		m_index = 0;
		m_index2 = 0;
	}
	
	int elapsedTime = [self getDeltaTime];
	
	es2renderer->useBlending(false);
	[tempBuffer bindFrameBuffer];
	
	if ( ((double)(elapsedTime)/(double)(m_duration))>1.0 )
	{
		es2renderer->renderBlitFull(source2);					// completed
	}
	else
	{
		[source1 bindFrameBuffer];
		int w, h, i, j, k;
		
		h = m_source2Height * elapsedTime / m_duration;
		w = m_source2Width * elapsedTime / m_duration;
		
		if ( dwStyle==0 )
		{
			k = h % 2;
			for ( i=0 ; i<m_source2Width ; i+=2 )
			{
				for ( j=m_index ; j<h ; j++ )
				{
					es2renderer->renderBlit(source2, i, j, i, j, 1, 1);
				}
				for ( j=m_source2Height-h-k ; j<m_source2Height-m_index ; j++ )
				{
					es2renderer->renderBlit(source2, i+1, j+1, i+1, j+1, 1, 1);
				}
			}
			if (h%2==0)
				m_index=h;
			else
				m_index=h-1;
		}
		
		if ( dwStyle==1 )
		{
			k = w % 2;
			for ( j=0 ; j<m_source2Height ; j++ )
			{
				for ( i=m_index2 ; i<w ; i+=2 )
				{
					es2renderer->renderBlit(source2, i+1, j, i+1, j, 1, 1);
				}
				for ( i=m_source2Width-w-k ; i<m_source2Width-m_index2 ; i+=2 )
				{
					es2renderer->renderBlit(source2, i, j+1, i, j+1, 1, 1);
				}
			}
			if (w%2==0)
				m_index2=w;
			else
				m_index2=w-1;
		}
		
		if ( dwStyle==2 )
		{
			k = h % 2;
			for ( i=0 ; i<m_source2Width ; i+=2 )
			{
				for ( j=m_index ; j<h ; j+=2 )
				{
					es2renderer->renderBlit(source2, i, j, i, j, 1, 1);
				}
				for ( j=m_source2Height-h-k ; j<m_source2Height-m_index ; j+=2 )
				{
					es2renderer->renderBlit(source2, i+1, j+1, i+1, j+1, 1, 1);
				}
			}
			
			k = w % 2;
			for ( j=0 ; j<m_source2Height ; j+=2 )
			{
				for ( i=m_index2 ; i<w ; i+=2 )
				{
					es2renderer->renderBlit(source2, i+1, j, i+1, j, 1, 1);
				}
				for ( i=m_source2Width-w-k ; i<m_source2Width-m_index2 ; i+=2 )
				{
					es2renderer->renderBlit(source2, i, j+1, i, j+1, 1, 1);
				}
			}
			if (h%2==0)
				m_index=h;
			else
				m_index=h-1;
			if (w%2==0)
				m_index2=w;
			else
				m_index2=w-1;
		}
		[source1 unbindFrameBuffer];
	}
	es2renderer->renderBlitFull(source1);
	[tempBuffer unbindFrameBuffer];
	es2renderer->useBlending(true);
	es2renderer->renderBlitFull(tempBuffer);
	return nil;
}
-(void)end
{
	[tempBuffer release];
	[self finish];
}
-(NSString*)description{return @"Trame";}

@end

// TRANSTURN
//////////////////////////////////////////////////////////////////////////////////////////
@implementation CTransTurn

-(void)initialize:(CTransitionData*)data withFile:(CFile*)file andRenderer:(CRenderer*)renderer andStart:(CRenderToTexture*)s andEnd:(CRenderToTexture*)d andType:(int)type
{
	dwPos=[file readAInt];
	dwCheck1=[file readAInt];
	dwCheck2=[file readAInt];
	[self start:data withRenderer:renderer andStart:s andEnd:d andType:type];
	
	tempBuffer = [[CRenderToTexture alloc] initWithWidth:s->width andHeight:s->height andRunApp:[CRunApp getRunApp]];
	[tempBuffer bindFrameBuffer];
	es2renderer->renderBlitFull(source1);
	[tempBuffer unbindFrameBuffer];
}
-(char*)stepDraw:(int)flag
{
	// 1st time?
	if ( m_starting )
	{
		m_starting = NO;
		m_source2Width = source2->width;
		m_source2Height = source2->height;
		m_angle = 0.0;
	}
	
	int elapsedTime = [self getDeltaTime];
	
	es2renderer->useBlending(false);
	[tempBuffer bindFrameBuffer];
	
	if ( ((double)(elapsedTime)/(double)(m_duration))>1.0 )
	{
		es2renderer->renderBlitFull(source2);			// completed
	}
	else
	{
		int x, y, w, h;
		int dist, xcenter, ycenter;
		
		xcenter = m_source2Width/2;
		ycenter = m_source2Height/2;
		
		m_angle = dwPos * 6.28318 * (double)elapsedTime / ((double)m_duration);
		
		// Inverse ?
		if ( dwCheck2==1 )
		{
			m_angle = 6.28318 - m_angle;
		}
		
		dist = m_source2Width/2 - m_source2Width/2 * elapsedTime / m_duration;
		x = (int)(xcenter + cosf(m_angle) * (float)dist);
		y = (int)(ycenter + sinf(m_angle) * (float)dist);
		
		w = m_source2Width * elapsedTime / m_duration;
		h = m_source2Height * elapsedTime / m_duration;
		
		es2renderer->renderStretch(source1,  0,  0,  m_source2Width,  m_source2Height,  0,  0,  source1->width,  source1->height);
		
		// Full Image ?
		if ( dwCheck1==1 )
			es2renderer->renderStretch(source2,  x-w/2,  y-h/2,  w,  h,  0,  0,  m_source2Width,  m_source2Height);
		else
			es2renderer->renderStretch(source2,  x-w/2,  y-h/2,  w,  h,  m_source2Width-w,  m_source2Height-h,  w,  h);
	}
	
	[tempBuffer unbindFrameBuffer];
	es2renderer->useBlending(true);
	es2renderer->renderBlitFull(tempBuffer);
	return nil;
}
-(void)end
{
	[tempBuffer release];
	[self finish];
}
-(NSString*)description{return @"Turn";}

@end

// TRANSTURN2
//////////////////////////////////////////////////////////////////////////////////////////
@implementation CTransTurn2

-(void)initialize:(CTransitionData*)data withFile:(CFile*)file andRenderer:(CRenderer*)renderer andStart:(CRenderToTexture*)s andEnd:(CRenderToTexture*)d andType:(int)type
{
	dwPos=[file readAInt];
	dwCheck1=[file readAInt];
	[self start:data withRenderer:renderer andStart:s andEnd:d andType:type];
	
	tempBuffer = [[CRenderToTexture alloc] initWithWidth:s->width andHeight:s->height andRunApp:[CRunApp getRunApp]];
	[tempBuffer bindFrameBuffer];
	es2renderer->renderBlitFull(source1);
	[tempBuffer unbindFrameBuffer];
}
-(char*)stepDraw:(int)flag
{
	// 1st time?
	if ( m_starting )
	{
		m_starting = NO;
		m_source2Width = source2->width;
		m_source2Height = source2->height;
		m_curcircle = 0;
	}
	
	int elapsedTime = [self getDeltaTime];
	
	es2renderer->useBlending(false);
	[tempBuffer bindFrameBuffer];
	
	if ( ((double)(elapsedTime)/(double)(m_duration))>1.0 )
	{
		es2renderer->renderBlitFull(source2);				// completed
	}
	else
	{
		int x, y, xcenter, ycenter, dist;
		double angle = 0.0;
		
		xcenter = m_source2Width/2;
		ycenter = m_source2Height/2;
		
		angle = dwPos * 6.28318 * (double)elapsedTime / (double)m_duration;
		angle -= m_curcircle * 6.28318;
		if ( dwCheck1==1 )
			angle = 6.28318 - angle;
		
		dist = m_source2Width * elapsedTime / m_duration;
		x = (int)( (double)xcenter + cos(angle) * (double)dist );
		y = (int)( (double)ycenter + sin(angle) * (double)dist );
		
		es2renderer->renderBlitFull(source2);
		es2renderer->renderBlit(source1, x-m_source2Width/2, y-m_source2Height/2, 0, 0, m_source2Width, m_source2Height);
		
		if ( dwCheck1==0 )
		{
			if ( angle>=6.28318 )
				m_curcircle++;
		}
		else
		{
			if ( angle<=0 )
				m_curcircle++;
		}
	}
	
	[tempBuffer unbindFrameBuffer];
	es2renderer->useBlending(true);
	es2renderer->renderBlitFull(tempBuffer);
	
	return nil;
}
-(void)end
{
	[tempBuffer release];
	[self finish];
}
-(NSString*)description{return @"Turn2";}

@end

// TRANSZIGZAG
//////////////////////////////////////////////////////////////////////////////////////////
@implementation CTransZigZag

-(void)initialize:(CTransitionData*)data withFile:(CFile*)file andRenderer:(CRenderer*)renderer andStart:(CRenderToTexture*)s andEnd:(CRenderToTexture*)d andType:(int)type
{
	zpSpotPercent=[file readAInt];
	zpStartPoint=[file readAShort];
	zpDirection=[file readAShort];
	[self start:data withRenderer:renderer andStart:s andEnd:d andType:type];
	
	tempBuffer = [[CRenderToTexture alloc] initWithWidth:s->width andHeight:s->height andRunApp:[CRunApp getRunApp]];
	[tempBuffer bindFrameBuffer];
	es2renderer->renderBlitFull(source1);
	[tempBuffer unbindFrameBuffer];
}
-(char*)stepDraw:(int)flag
{
	int sw = source1->width;
	int sh = source1->height;
	
	es2renderer->useBlending(false);
	[tempBuffer bindFrameBuffer];
	
	// 1st time? create surface
	if ( m_starting )
	{
		// Spot size: voir si ca rend bien
		m_spotSize = (int)((((int)sw * zpSpotPercent / 100) + ((int)sh * zpSpotPercent / 100)) / 2);
		if ( m_spotSize == 0 )
			m_spotSize = 1;
		
		m_nbBlockPerLine = ((sw + m_spotSize - 1) / m_spotSize);
		m_nbBlockPerCol = ((sh + m_spotSize - 1) / m_spotSize);
		
		// Start point
		m_currentDirection = zpDirection;
		m_currentStartPoint = zpStartPoint;
		
		switch(zpStartPoint) 
		{
			case TOP_LEFT:
				m_curx = m_cury = 0;
				break;
			case TOP_RIGHT:
				m_curx = sw - m_spotSize;
				m_cury = 0;
				break;
			case BOTTOM_LEFT:
				m_curx = 0;
				m_cury = sh - m_spotSize;
				break;
			case BOTTOM_RIGHT:
				m_curx = sw - m_spotSize;
				m_cury = sh - m_spotSize;
				break;
			case CENTER:
				m_curx = sw/2 - m_spotSize;
				m_cury = sh/2 - m_spotSize;
				if ( m_currentDirection == DIR_HORZ )
					m_currentStartPoint = TOP_LEFT;
				else
					m_currentStartPoint = TOP_RIGHT;
				m_left = m_curx - m_spotSize;
				m_top = m_cury - m_spotSize;
				m_bottom = m_cury + m_spotSize*2;
				m_right = m_curx + m_spotSize*2;
				
				m_nbBlockPerLine = 2 + 2 * (m_curx + m_spotSize - 1)/m_spotSize;
				m_nbBlockPerCol = 2 + 2 * (m_cury + m_spotSize - 1)/m_spotSize;
				break;
		}
		m_nbBlocks = (int)m_nbBlockPerLine * (int)m_nbBlockPerCol;
		m_lastNbBlocks = 0;
		m_starting = NO;
	}
	
	if ( m_spotSize >= (int)sw || m_spotSize >= (int)sh )
		es2renderer->renderBlitFull(source2);	// termine
	else
	{
		// Compute number of spots to display in 1 step
		int l;
		int nbBlocks = (int)((double)m_nbBlocks * (double)[self getDeltaTime] / (double)m_duration);
		int nbCurrentBlocks = nbBlocks - m_lastNbBlocks;
		if ( nbCurrentBlocks != 0 )
		{
			m_lastNbBlocks = nbBlocks;
			for (l=0; l<nbCurrentBlocks; l++)
			{
				// Blit current spot
				[source1 bindFrameBuffer];
				es2renderer->renderBlit(source2,  m_curx,  m_cury,  m_curx,  m_cury,  m_spotSize,  m_spotSize);
				[source1 unbindFrameBuffer];
				
				// Increment spot coordinates
				if ( zpStartPoint == CENTER )
				{
					switch(m_currentStartPoint) 
					{
						case TOP_LEFT:
							m_curx += m_spotSize;
							if ( m_curx >= (int)m_right )
							{
								m_curx -= m_spotSize;
								m_cury += m_spotSize;
								m_currentStartPoint = TOP_RIGHT;
								m_right += m_spotSize;
							}
							break;
						case TOP_RIGHT:
							m_cury += m_spotSize;
							if ( m_cury >= (int)m_bottom )
							{
								m_cury -= m_spotSize;
								m_curx -= m_spotSize;
								m_currentStartPoint = BOTTOM_RIGHT;
								m_bottom += m_spotSize;
							}
							break;
						case BOTTOM_RIGHT:
							m_curx -= m_spotSize;
							if ( (int)(m_curx+m_spotSize) <= m_left )
							{
								m_curx += m_spotSize;
								m_cury -= m_spotSize;
								m_currentStartPoint = BOTTOM_LEFT;
								m_left -= m_spotSize;
							}
							break;
						case BOTTOM_LEFT:
							m_cury -= m_spotSize;
							if ( (int)(m_cury + m_spotSize) <= m_top )
							{
								m_cury += m_spotSize;
								m_curx += m_spotSize;
								m_currentStartPoint = TOP_LEFT;
								m_top -= m_spotSize;
							}
							break;
					}
				}
				else 
				{
					switch (m_currentDirection) 
					{
                            // Horizontal
						case DIR_HORZ:
							switch(m_currentStartPoint) 
						{
							case TOP_LEFT:
								m_curx += m_spotSize;
								if ( m_curx >= (int)sw )
								{
									m_curx -= m_spotSize;
									m_cury += m_spotSize;
									m_currentStartPoint = TOP_RIGHT;
								}
								break;
							case TOP_RIGHT:
								m_curx -= m_spotSize;
								if ( (int)(m_curx+m_spotSize) <= 0 )
								{
									m_curx += m_spotSize;
									m_cury += m_spotSize;
									m_currentStartPoint = TOP_LEFT;
								}
								break;
							case BOTTOM_LEFT:
								m_curx += m_spotSize;
								if ( m_curx >= (int)sw )
								{
									m_curx -= m_spotSize;
									m_cury -= m_spotSize;
									m_currentStartPoint = BOTTOM_RIGHT;
								}
								break;
							case BOTTOM_RIGHT:
								m_curx -= m_spotSize;
								if ( (int)(m_curx+m_spotSize) <= 0 )
								{
									m_curx += m_spotSize;
									m_cury -= m_spotSize;
									m_currentStartPoint = BOTTOM_LEFT;
								}
								break;
						}
							break;
							
                            // Vertical
						case DIR_VERT:
							switch(m_currentStartPoint) 
						{
							case TOP_LEFT:
								m_cury += m_spotSize;
								if ( m_cury >= (int)sh )
								{
									m_cury -= m_spotSize;
									m_curx += m_spotSize;
									m_currentStartPoint = BOTTOM_LEFT;
								}
								break;
							case TOP_RIGHT:
								m_cury += m_spotSize;
								if ( m_cury >= (int)sh )
								{
									m_cury -= m_spotSize;
									m_curx -= m_spotSize;
									m_currentStartPoint = BOTTOM_RIGHT;
								}
								break;
							case BOTTOM_LEFT:
								m_cury -= m_spotSize;
								if ( (int)(m_cury + m_spotSize) <= 0 )
								{
									m_cury += m_spotSize;
									m_curx += m_spotSize;
									m_currentStartPoint = TOP_LEFT;
								}
								break;
							case BOTTOM_RIGHT:
								m_cury -= m_spotSize;
								if ( (int)(m_cury + m_spotSize) <= 0 )
								{
									m_cury += m_spotSize;
									m_curx -= m_spotSize;
									m_currentStartPoint = TOP_RIGHT;
								}
								break;
						}
							break;
					}
				}
			}
		}
		es2renderer->renderBlitFull(source1);
	}
	
	[tempBuffer unbindFrameBuffer];
	es2renderer->useBlending(true);
	es2renderer->renderBlitFull(tempBuffer);
	
	return nil;
}
-(void)end
{
	[tempBuffer release];
	[self finish];
}
-(NSString*)description{return @"ZigZag";}

@end

// TRANSZIGZAG2
//////////////////////////////////////////////////////////////////////////////////////////
@implementation CTransZigZag2

-(void)initialize:(CTransitionData*)data withFile:(CFile*)file andRenderer:(CRenderer*)renderer andStart:(CRenderToTexture*)s andEnd:(CRenderToTexture*)d andType:(int)type
{
	dwStyle=[file readAInt];
	dwPos=[file readAInt];
	[self start:data withRenderer:renderer andStart:s andEnd:d andType:type];
	
	tempBuffer = [[CRenderToTexture alloc] initWithWidth:s->width andHeight:s->height andRunApp:[CRunApp getRunApp]];
	[tempBuffer bindFrameBuffer];
	es2renderer->renderBlitFull(source1);
	[tempBuffer unbindFrameBuffer];
}
-(char*)stepDraw:(int)flag
{
	// 1st time?
	if ( m_starting )
	{
		m_starting = NO;
		m_source2Width = source2->width;
		m_source2Height = source2->height;
		m_linepos = 0;
		m_dir = 0;
	}
	
	int elapsedTime = [self getDeltaTime];
	
	es2renderer->useBlending(false);
	[tempBuffer bindFrameBuffer];
	
	if ( ((double)(elapsedTime)/(double)(m_duration))>1.0 )
	{
		es2renderer->renderBlitFull(source2);					// completed
	}
	else
	{
		int x, y, w, h;
		double nb = 0.0;
		
		[source1 bindFrameBuffer];
		if ( dwStyle==0 )
		{
			nb = (double)m_source2Height / (double)dwPos;
			
			// TOP
			h = (int)( (double)m_linepos * nb) + (int)nb;
			y = 0;
			w = m_source2Width * elapsedTime / m_duration;
			w = w * dwPos / 2;
			w -= m_source2Width * m_linepos;
			if ( m_dir==0 )
				x = 0;
			else
				x = m_source2Width - w;
			es2renderer->renderBlit(source2, x, y, x, y, w, h);
			
			// BOTTOM
			y = m_source2Height - h;
			if ( m_dir==1 )
				x = 0;
			else
				x = m_source2Width - w;
			es2renderer->renderBlit(source2, x, y, x, y, w, h);
			
			// End of line
			if ( w>=m_source2Width )
			{
				m_linepos++;
				m_dir++;
				if ( m_dir==2 )
					m_dir = 0;
			}
		}
		else
		{
			nb = (double)m_source2Width / (double)dwPos;
			
			// LEFT
			w = (int)( (double)m_linepos * nb) + (int)nb;
			x = 0;
			h = m_source2Height * elapsedTime / m_duration;
			h = h * dwPos / 2;
			h -= m_source2Height * m_linepos;
			if ( m_dir==0 )
				y = 0;
			else
				y = m_source2Height - h;
			es2renderer->renderBlit(source2, x, y, x, y, w, h);
			
			// RIGHT
			x = m_source2Width - w;
			if ( m_dir==1 )
				y = 0;
			else
				y = m_source2Height - h;
			es2renderer->renderBlit(source2, x, y, x, y, w, h);
			
			// End of line
			if ( h>=m_source2Height )
			{
				m_linepos++;
				m_dir++;
				if ( m_dir==2 )
					m_dir = 0;
			}
		}
		[source1 unbindFrameBuffer];
		es2renderer->renderBlitFull(source1);
	}
	
	[tempBuffer unbindFrameBuffer];
	es2renderer->useBlending(true);
	es2renderer->renderBlitFull(tempBuffer);
	
	return nil;
}
-(void)end
{
	[tempBuffer release];
	[self finish];
}
-(NSString*)description{return @"ZigZag2";}

@end

// TRANSZOOM
//////////////////////////////////////////////////////////////////////////////////////////
@implementation CTransZoom

-(void)initialize:(CTransitionData*)data withFile:(CFile*)file andRenderer:(CRenderer*)renderer andStart:(CRenderToTexture*)s andEnd:(CRenderToTexture*)d andType:(int)type
{
	[self start:data withRenderer:renderer andStart:s andEnd:d andType:type];        
}
-(char*)stepDraw:(int)flag
{
	int sw = source1->width;
	int sh = source1->height;
	
	// 1st time? 
	if ( m_starting )
	{
		// Reset m_starting
		m_starting = NO;
	}
	
	// Securites
	if ( m_duration == 0 )	// || etc... )
		es2renderer->renderBlitFull(source2);
	else
	{
		int	nw, nh;
		int deltaTime = [self getDeltaTime];
		
		// Fade out
		if ( (flag & TRFLAG_FADEOUT)!=0 )
		{
			nw = (int)(sw - sw * deltaTime / m_duration);
			nh = (int)(sh - sh * deltaTime / m_duration);
			
			// Fill background
			es2renderer->renderBlitFull(source2);
			
			// Stretch new image
			es2renderer->renderStretch(source1,  (sw-nw)/2,  (sh-nh)/2,  nw,  nh,  0,  0,  sw,  sh);
		}
		
		// Fade in
		else
		{
			nw = (int)(sw * deltaTime / m_duration);
			nh = (int)(sh * deltaTime / m_duration);
			
			// Fill background
			es2renderer->renderBlitFull(source1);
			
			// Stretch new image
			es2renderer->renderStretch(source2,  (sw-nw)/2,  (sh-nh)/2,  nw,  nh, 0,  0,  sw,  sh);
		}
	}
	return nil;
}
-(void)end
{
	[self finish];
}
-(NSString*)description{return @"Zoom";}

@end

// TRANSZOOM2
//////////////////////////////////////////////////////////////////////////////////////////
@implementation CTransZoom2

-(void)initialize:(CTransitionData*)data withFile:(CFile*)file andRenderer:(CRenderer*)renderer andStart:(CRenderToTexture*)s andEnd:(CRenderToTexture*)d andType:(int)type
{
	dwPos=[file readAInt];
	[self start:data withRenderer:renderer andStart:s andEnd:d andType:type];
}
-(char*)stepDraw:(int)flag
{
	// 1st time?
	if ( m_starting )
	{
		m_starting = NO;
		m_source2Width = source2->width;
		m_source2Height = source2->height;
	}
	
	int elapsedTime = [self getDeltaTime];
	
	if ( ((double)(elapsedTime)/(double)(m_duration))>1.0 )
	{
		es2renderer->renderBlitFull(source2);		// completed
	}
	else
	{
		int x, y, w, h;
		
		if ( dwPos==0 )
		{
			w = m_source2Width * elapsedTime / m_duration;
			h = m_source2Height * elapsedTime / m_duration;
			x = m_source2Width/2 - w/2;
			y = m_source2Height/2 - h/2;
			
			es2renderer->renderStretch(source2, 0, 0, m_source2Width, m_source2Height, x, y, w, h);
		}
		else
		{
			w = m_source2Width * elapsedTime / m_duration;
			w = m_source2Width - w;
			h = m_source2Height * elapsedTime / m_duration;
			h = m_source2Height - h;
			x = m_source2Width/2 - w/2;
			y = m_source2Height/2 - h/2;
			
			es2renderer->renderStretch(source1, 0, 0, m_source2Width, m_source2Height, x, y, w, h);
		}
	}
	return nil;
}
-(void)end
{
	[self finish];
}
-(NSString*)description{return @"Zoom2";}

@end
