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
// CRECT : classe rectangle similaire a celle de windows
//
//----------------------------------------------------------------------------------
#include "CRect.h"


int CRect::width() const
{
	return right-left;
}

int CRect::height() const
{
	return bottom-top;
}

BOOL CRect::isNil() const
{
	return (left | right | top | bottom) == 0;
}

BOOL CRect::containsPoint(int x, int y) const
{
	return (x>=left && x<right && y>=top && y<bottom);
}

CRect CRectLoad(CFile* file)
{
	CRect rc;
	rc.left = [file readAInt];
	rc.top = [file readAInt];
	rc.right = [file readAInt];
	rc.bottom = [file readAInt];
	return rc;
}

CRect CRectInflate(CRect rc, int dx, int dy)
{
	rc.left-=dx;
	rc.top-=dy;
	rc.right+=dx;
	rc.top+=dy;
	return rc;
}

BOOL CRectAreEqual(CRect a, CRect b)
{
	return a.left == b.left && a.top == b.top && a.left == b.left && a.bottom == b.bottom;
}

BOOL CRectIntersects(CRect a, CRect b)
{
	return a.left <= b.right && a.right >= b.left && a.top <= b.bottom && a.bottom >= b.top;
}

CRect CRectCreateAtPosition(int x, int y, int w, int h)
{
	CRect rc;
	rc.left = x;
	rc.top = y;
	rc.right = x+w;
	rc.bottom = y+h;
	return rc;
}

CRect CRectCreate(int left, int top, int right, int bottom)
{
	CRect rc;
	rc.left = left;
	rc.top = top;
	rc.right = right;
	rc.bottom = bottom;
	return rc;
}