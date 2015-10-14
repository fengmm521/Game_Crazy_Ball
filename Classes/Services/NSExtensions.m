
#import "NSExtensions.h"
#include <zlib.h>
#import <CommonCrypto/CommonDigest.h>

@implementation NSData (NSDataExtension)

- (NSString*)base64encode
{
	NSUInteger length = [self length];
	
	unsigned char in0, in1, in2;
	char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	unsigned char* uData = (unsigned char*)[self bytes];
	
	NSUInteger outLen = (length + 2 - ((length + 2) % 3)) / 3 * 4;
	char* outData = (char*)calloc(outLen+1, sizeof(char));
	
	for(int i=0, w=0; i<length; i += 3, w += 4)
	{
		bool use1 = i+1<length;
		bool use2 = i+2<length;
		in0 = uData[i];
		in1 = use1 ? uData[i+1] : 0;
		in2 = use2 ? uData[i+2] : 0;
		outData[w] = table[in0 >> 2];
		outData[w+1] = table[((in0 & 0x03) << 4) | ((in1 & 0xf0) >> 4)];
		outData[w+2] = use1 ? table[((in1 & 0x0f) << 2) | ((in2 & 0xc0) >> 6)] : '=';
		outData[w+3] = use2 ? table[in2 & 0x3f] : '=';
	}
	
	NSData* mdata = [NSData dataWithBytes:outData length:outLen];
	NSString* outString = [[NSString alloc] initWithData:mdata encoding:NSASCIIStringEncoding];
	free(outData);
	return outString;
}


- (NSData *)zlibInflate
{
	if ([self length] == 0) return self;
	
	NSUInteger full_length = [self length];
	NSUInteger half_length = [self length] / 2;
	
	NSMutableData *decompressed = [NSMutableData dataWithLength:full_length + half_length];
	BOOL done = NO;
	int status;
	
	z_stream strm;
	strm.next_in = (Bytef *)[self bytes];
	strm.avail_in = (uInt)[self length];
	strm.total_out = 0;
	strm.zalloc = Z_NULL;
	strm.zfree = Z_NULL;
	
	if (inflateInit (&strm) != Z_OK) return nil;
	
	while (!done)
	{
		// Make sure we have enough room and reset the lengths.
		if (strm.total_out >= [decompressed length])
			[decompressed increaseLengthBy: half_length];
		strm.next_out = (Bytef*)[decompressed mutableBytes] + strm.total_out;
		strm.avail_out = (uInt)([decompressed length] - strm.total_out);
		
		// Inflate another chunk.
		status = inflate (&strm, Z_SYNC_FLUSH);
		if (status == Z_STREAM_END) done = YES;
		else if (status != Z_OK) break;
	}
	if (inflateEnd (&strm) != Z_OK) return nil;
	
	// Set real length.
	if (done)
	{
		[decompressed setLength: strm.total_out];
		//return [NSData dataWithData: decompressed];
		return [[NSData alloc] initWithData:decompressed];
	}
	else return nil;
}

- (NSData *)zlibDeflate
{
	if ([self length] == 0) return self;
	
	z_stream strm;
	
	strm.zalloc = Z_NULL;
	strm.zfree = Z_NULL;
	strm.opaque = Z_NULL;
	strm.total_out = 0;
	strm.next_in=(Bytef *)[self bytes];
	strm.avail_in = (uInt)[self length];
	
	// Compresssion Levels:
	//   Z_NO_COMPRESSION
	//   Z_BEST_SPEED
	//   Z_BEST_COMPRESSION
	//   Z_DEFAULT_COMPRESSION
	
	if (deflateInit(&strm, Z_DEFAULT_COMPRESSION) != Z_OK) return nil;
	
	NSMutableData *compressed = [NSMutableData dataWithLength:16384];  // 16K chuncks for expansion
	
	do {
		
		if (strm.total_out >= [compressed length])
			[compressed increaseLengthBy: 16384];
		
		strm.next_out = (Bytef*)[compressed mutableBytes] + strm.total_out;
		strm.avail_out = (uInt)([compressed length] - strm.total_out);
		
		deflate(&strm, Z_FINISH);  
		
	} while (strm.avail_out == 0);
	
	deflateEnd(&strm);
	
	[compressed setLength: strm.total_out];
	return [NSData dataWithData: compressed];
}

- (NSData *)gzipInflate
{
	if ([self length] == 0) return self;
	
	NSUInteger full_length = [self length];
	NSUInteger half_length = [self length] / 2;
	
	NSMutableData *decompressed = [NSMutableData dataWithLength: full_length + half_length];
	BOOL done = NO;
	int status;
	
	z_stream strm;
	strm.next_in = (Bytef *)[self bytes];
	strm.avail_in = (uInt)[self length];
	strm.total_out = 0;
	strm.zalloc = Z_NULL;
	strm.zfree = Z_NULL;
	
	if (inflateInit2(&strm, (15+32)) != Z_OK) return nil;
	while (!done)
	{
		// Make sure we have enough room and reset the lengths.
		if (strm.total_out >= [decompressed length])
			[decompressed increaseLengthBy: half_length];
		strm.next_out = (Bytef*)[decompressed mutableBytes] + strm.total_out;
		strm.avail_out = (uInt)([decompressed length] - strm.total_out);
		
		// Inflate another chunk.
		status = inflate (&strm, Z_SYNC_FLUSH);
		if (status == Z_STREAM_END) done = YES;
		else if (status != Z_OK) break;
	}
	if (inflateEnd (&strm) != Z_OK) return nil;
	
	// Set real length.
	if (done)
	{
		[decompressed setLength: strm.total_out];
		return [NSData dataWithData: decompressed];
	}
	else return nil;
}

- (NSData *)gzipDeflate
{
	if ([self length] == 0) return self;
	
	z_stream strm;
	
	strm.zalloc = Z_NULL;
	strm.zfree = Z_NULL;
	strm.opaque = Z_NULL;
	strm.total_out = 0;
	strm.next_in=(Bytef *)[self bytes];
	strm.avail_in = (uInt)[self length];
	
	// Compresssion Levels:
	//   Z_NO_COMPRESSION
	//   Z_BEST_SPEED
	//   Z_BEST_COMPRESSION
	//   Z_DEFAULT_COMPRESSION
	
	if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY) != Z_OK) return nil;
	
	NSMutableData *compressed = [NSMutableData dataWithLength:16384];  // 16K chunks for expansion
	
	do {
		
		if (strm.total_out >= [compressed length])
			[compressed increaseLengthBy: 16384];
		
		strm.next_out = (Bytef*)[compressed mutableBytes] + strm.total_out;
		strm.avail_out = (uInt)([compressed length] - strm.total_out);
		
		deflate(&strm, Z_FINISH);  
		
	} while (strm.avail_out == 0);
	
	deflateEnd(&strm);
	
	[compressed setLength: strm.total_out];
	return [NSData dataWithData:compressed];
}
@end


@implementation NSString (NSStringExtension)

- (NSString *) md5
{
	[self retain];
    const char *cStr = [self UTF8String];
    unsigned char result[16];
	CC_MD5( cStr, (CC_LONG)strlen(cStr), result ); // This is the md5 call
    return [NSString stringWithFormat:
			@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
			result[0], result[1], result[2], result[3], 
			result[4], result[5], result[6], result[7],
			result[8], result[9], result[10], result[11],
			result[12], result[13], result[14], result[15]
			];  
}

- (NSString*)urlEncode
{
	NSString *result = (NSString*)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, NULL, (CFStringRef)@"î:/?#[]@!$&í()*+,;=î", kCFStringEncodingUTF8);
	return [result autorelease];
}

@end