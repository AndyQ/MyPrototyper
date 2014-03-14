#import "UIColor-Expanded.h"

/*
 
 Thanks to Poltras, Millenomi, Eridius, Nownot, WhatAHam, jberry,
 and everyone else who helped out but whose name is inadvertantly omitted
 
*/

/*
 Current outstanding request list:
 
 - PolarBearFarm - color descriptions ([UIColor warmGrayWithHintOfBlueTouchOfRedAndSplashOfYellowColor])
 - Crayola color set
 - Eridius - UIColor needs a method that takes 2 colors and gives a third complementary one
 - Consider UIMutableColor that can be adjusted (brighter, cooler, warmer, thicker-alpha, etc)
 */

/*
 FOR REFERENCE: Color Space Models: enum CGColorSpaceModel {
	kCGColorSpaceModelUnknown = -1,
	kCGColorSpaceModelMonochrome,
	kCGColorSpaceModelRGB,
	kCGColorSpaceModelCMYK,
	kCGColorSpaceModelLab,
	kCGColorSpaceModelDeviceN,
	kCGColorSpaceModelIndexed,
	kCGColorSpaceModelPattern
};
*/

// Static cache of looked up color names. Used with +colorWithName:
static NSMutableDictionary *colorNameCache = nil;

@interface UIColor (UIColor_Expanded_Support)
+ (UIColor *)searchForColorByName:(NSString *)cssColorName;
@end

#pragma mark -

@implementation UIColor (UIColor_Expanded)

- (CGColorSpaceModel)colorSpaceModel {
	return CGColorSpaceGetModel(CGColorGetColorSpace(self.CGColor));
}

- (NSString *)colorSpaceString {
	switch (self.colorSpaceModel) {
		case kCGColorSpaceModelUnknown:
			return @"kCGColorSpaceModelUnknown";
		case kCGColorSpaceModelMonochrome:
			return @"kCGColorSpaceModelMonochrome";
		case kCGColorSpaceModelRGB:
			return @"kCGColorSpaceModelRGB";
		case kCGColorSpaceModelCMYK:
			return @"kCGColorSpaceModelCMYK";
		case kCGColorSpaceModelLab:
			return @"kCGColorSpaceModelLab";
		case kCGColorSpaceModelDeviceN:
			return @"kCGColorSpaceModelDeviceN";
		case kCGColorSpaceModelIndexed:
			return @"kCGColorSpaceModelIndexed";
		case kCGColorSpaceModelPattern:
			return @"kCGColorSpaceModelPattern";
		default:
			return @"Not a valid color space";
	}
}

- (BOOL)canProvideRGBComponents {
	switch (self.colorSpaceModel) {
		case kCGColorSpaceModelRGB:
		case kCGColorSpaceModelMonochrome:
			return YES;
		default:
			return NO;
	}
}

- (NSArray *)arrayFromRGBAComponents {
	NSAssert(self.canProvideRGBComponents, @"Must be an RGB color to use -arrayFromRGBAComponents");

	CGFloat r,g,b,a;
	if (![self red:&r green:&g blue:&b alpha:&a]) return nil;
	
	return [NSArray arrayWithObjects:
			[NSNumber numberWithFloat:r],
			[NSNumber numberWithFloat:g],
			[NSNumber numberWithFloat:b],
			[NSNumber numberWithFloat:a],
			nil];
}

- (BOOL)red:(CGFloat *)red green:(CGFloat *)green blue:(CGFloat *)blue alpha:(CGFloat *)alpha {
	const CGFloat *components = CGColorGetComponents(self.CGColor);
	
	CGFloat r,g,b,a;
	
	switch (self.colorSpaceModel) {
		case kCGColorSpaceModelMonochrome:
			r = g = b = components[0];
			a = components[1];
			break;
		case kCGColorSpaceModelRGB:
			r = components[0];
			g = components[1];
			b = components[2];
			a = components[3];
			break;
		default:	// We don't know how to handle this model
			return NO;
	}
	
	if (red) *red = r;
	if (green) *green = g;
	if (blue) *blue = b;
	if (alpha) *alpha = a;
	
	return YES;
}

- (CGFloat)red {
	NSAssert(self.canProvideRGBComponents, @"Must be an RGB color to use -red");
	const CGFloat *c = CGColorGetComponents(self.CGColor);
	return c[0];
}

- (CGFloat)green {
	NSAssert(self.canProvideRGBComponents, @"Must be an RGB color to use -green");
	const CGFloat *c = CGColorGetComponents(self.CGColor);
	if (self.colorSpaceModel == kCGColorSpaceModelMonochrome) return c[0];
	return c[1];
}

- (CGFloat)blue {
	NSAssert(self.canProvideRGBComponents, @"Must be an RGB color to use -blue");
	const CGFloat *c = CGColorGetComponents(self.CGColor);
	if (self.colorSpaceModel == kCGColorSpaceModelMonochrome) return c[0];
	return c[2];
}

- (CGFloat)white {
	NSAssert(self.colorSpaceModel == kCGColorSpaceModelMonochrome, @"Must be a Monochrome color to use -white");
	const CGFloat *c = CGColorGetComponents(self.CGColor);
	return c[0];
}

- (CGFloat)alpha {
	return CGColorGetAlpha(self.CGColor);
}

- (unsigned int)rgbaHex {
	NSAssert(self.canProvideRGBComponents, @"Must be a RGB color to use rgbaHex");
	
	CGFloat r,g,b,a;
	if (![self red:&r green:&g blue:&b alpha:&a]) return 0;
	
	r = MIN(MAX(self.red, 0.0f), 1.0f);
	g = MIN(MAX(self.green, 0.0f), 1.0f);
	b = MIN(MAX(self.blue, 0.0f), 1.0f);
	a = MIN(MAX(self.alpha, 0.0f), 1.0f);
	
	return (((int)roundf(r * 255)) << 24)
	     | (((int)roundf(g * 255)) << 16)
         | (((int)roundf(b * 255)) << 8)
         | (((int)roundf(a * 255)));
}

#pragma mark Arithmetic operations

- (UIColor *)colorByLuminanceMapping {
	NSAssert(self.canProvideRGBComponents, @"Must be a RGB color to use arithmatic operations");
	
	CGFloat r,g,b,a;
	if (![self red:&r green:&g blue:&b alpha:&a]) return nil;
	
	// http://en.wikipedia.org/wiki/Luma_(video)
	// Y = 0.2126 R + 0.7152 G + 0.0722 B
	return [UIColor colorWithWhite:r*0.2126f + g*0.7152f + b*0.0722f
							 alpha:a];
	
}

- (UIColor *)colorByMultiplyingByRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha {
	NSAssert(self.canProvideRGBComponents, @"Must be a RGB color to use arithmatic operations");

	CGFloat r,g,b,a;
	if (![self red:&r green:&g blue:&b alpha:&a]) return nil;
		
	return [UIColor colorWithRed:MAX(0.0, MIN(1.0, r * red))
						   green:MAX(0.0, MIN(1.0, g * green)) 
							blue:MAX(0.0, MIN(1.0, b * blue))
						   alpha:MAX(0.0, MIN(1.0, a * alpha))];
}

- (UIColor *)colorByAddingRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha {
	NSAssert(self.canProvideRGBComponents, @"Must be a RGB color to use arithmatic operations");
	
	CGFloat r,g,b,a;
	if (![self red:&r green:&g blue:&b alpha:&a]) return nil;
	
	return [UIColor colorWithRed:MAX(0.0, MIN(1.0, r + red))
						   green:MAX(0.0, MIN(1.0, g + green)) 
							blue:MAX(0.0, MIN(1.0, b + blue))
						   alpha:MAX(0.0, MIN(1.0, a + alpha))];
}

- (UIColor *)colorByLighteningToRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha {
	NSAssert(self.canProvideRGBComponents, @"Must be a RGB color to use arithmatic operations");
	
	CGFloat r,g,b,a;
	if (![self red:&r green:&g blue:&b alpha:&a]) return nil;
		
	return [UIColor colorWithRed:MAX(r, red)
						   green:MAX(g, green)
							blue:MAX(b, blue)
						   alpha:MAX(a, alpha)];
}

- (UIColor *)colorByDarkeningToRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha {
	NSAssert(self.canProvideRGBComponents, @"Must be a RGB color to use arithmatic operations");
	
	CGFloat r,g,b,a;
	if (![self red:&r green:&g blue:&b alpha:&a]) return nil;
	
	return [UIColor colorWithRed:MIN(r, red)
						   green:MIN(g, green)
							blue:MIN(b, blue)
						   alpha:MIN(a, alpha)];
}

- (UIColor *)colorByMultiplyingBy:(CGFloat)f {
	return [self colorByMultiplyingByRed:f green:f blue:f alpha:1.0f];
}

- (UIColor *)colorByAdding:(CGFloat)f {
	return [self colorByMultiplyingByRed:f green:f blue:f alpha:0.0f];
}

- (UIColor *)colorByLighteningTo:(CGFloat)f {
	return [self colorByLighteningToRed:f green:f blue:f alpha:0.0f];
}

- (UIColor *)colorByDarkeningTo:(CGFloat)f {
	return [self colorByDarkeningToRed:f green:f blue:f alpha:1.0f];
}

- (UIColor *)colorByMultiplyingByColor:(UIColor *)color {
	NSAssert(self.canProvideRGBComponents, @"Must be a RGB color to use arithmatic operations");
	
	CGFloat r,g,b,a;
	if (![self red:&r green:&g blue:&b alpha:&a]) return nil;
	
	return [self colorByMultiplyingByRed:r green:g blue:b alpha:1.0f];
}

- (UIColor *)colorByAddingColor:(UIColor *)color {
	NSAssert(self.canProvideRGBComponents, @"Must be a RGB color to use arithmatic operations");
	
	CGFloat r,g,b,a;
	if (![self red:&r green:&g blue:&b alpha:&a]) return nil;
	
	return [self colorByAddingRed:r green:g blue:b alpha:0.0f];
}

- (UIColor *)colorByLighteningToColor:(UIColor *)color {
	NSAssert(self.canProvideRGBComponents, @"Must be a RGB color to use arithmatic operations");
	
	CGFloat r,g,b,a;
	if (![self red:&r green:&g blue:&b alpha:&a]) return nil;
		
	return [self colorByLighteningToRed:r green:g blue:b alpha:0.0f];
}

- (UIColor *)colorByDarkeningToColor:(UIColor *)color {
	NSAssert(self.canProvideRGBComponents, @"Must be a RGB color to use arithmatic operations");
	
	CGFloat r,g,b,a;
	if (![self red:&r green:&g blue:&b alpha:&a]) return nil;
	
	return [self colorByDarkeningToRed:r green:g blue:b alpha:1.0f];
}

#pragma mark String utilities

- (NSString *)stringFromColor {
	NSAssert(self.canProvideRGBComponents, @"Must be an RGB color to use -stringFromColor");
	NSString *result;
	switch (self.colorSpaceModel) {
		case kCGColorSpaceModelRGB:
			result = [NSString stringWithFormat:@"{%0.3f, %0.3f, %0.3f, %0.3f}", self.red, self.green, self.blue, self.alpha];
			break;
		case kCGColorSpaceModelMonochrome:
			result = [NSString stringWithFormat:@"{%0.3f, %0.3f}", self.white, self.alpha];
			break;
		default:
			result = nil;
	}
	return result;
}

- (NSString *)hexStringFromColor {
	return [NSString stringWithFormat:@"%0.8X", self.rgbaHex];
}

+ (UIColor *)colorWithString:(NSString *)stringToConvert {
	NSScanner *scanner = [NSScanner scannerWithString:stringToConvert];
	if (![scanner scanString:@"{" intoString:NULL]) return nil;
	const NSUInteger kMaxComponents = 4;
	CGFloat c[kMaxComponents];
	NSUInteger i = 0;
	if (![scanner scanFloat:&c[i++]]) return nil;
	while (1) {
		if ([scanner scanString:@"}" intoString:NULL]) break;
		if (i >= kMaxComponents) return nil;
		if ([scanner scanString:@"," intoString:NULL]) {
			if (![scanner scanFloat:&c[i++]]) return nil;
		} else {
			// either we're at the end of there's an unexpected character here
			// both cases are error conditions
			return nil;
		}
	}
	if (![scanner isAtEnd]) return nil;
	UIColor *color;
	switch (i) {
		case 2: // monochrome
			color = [UIColor colorWithWhite:c[0] alpha:c[1]];
			break;
		case 4: // RGB
			color = [UIColor colorWithRed:c[0] green:c[1] blue:c[2] alpha:c[3]];
			break;
		default:
			color = nil;
	}
	return color;
}

#pragma mark Class methods

+ (UIColor *)randomColor {
	return [UIColor colorWithRed:(CGFloat)RAND_MAX / random()
						   green:(CGFloat)RAND_MAX / random()
							blue:(CGFloat)RAND_MAX / random()
						   alpha:1.0f];
}

+ (UIColor *)colorWithRGBHex:(UInt32)hex {
	int r = (hex >> 24) & 0xFF;
	int g = (hex >> 16) & 0xFF;
	int b = (hex >> 8) & 0xFF;
	int a = (hex) & 0xFF;
	
	return [UIColor colorWithRed:r / 255.0f
						   green:g / 255.0f
							blue:b / 255.0f
						   alpha:a / 255.0f];
}

// Returns a UIColor by scanning the string for a hex number and passing that to +[UIColor colorWithRGBHex:]
// Skips any leading whitespace and ignores any trailing characters
+ (UIColor *)colorWithHexString:(NSString *)stringToConvert {
	NSScanner *scanner = [NSScanner scannerWithString:stringToConvert];
	unsigned hexNum;
	if (![scanner scanHexInt:&hexNum]) return nil;
	return [UIColor colorWithRGBHex:hexNum];
}

// Lookup a color using css 3/svg color name
+ (UIColor *)colorWithName:(NSString *)cssColorName {
	UIColor *color;
	@synchronized(colorNameCache) {
		// Look for the color in the cache
		color = [colorNameCache objectForKey:cssColorName];
		
		if ((id)color == [NSNull null]) {
			// If it wasn't there previously, it's still not there now
			color = nil;
		} else if (!color) {
			// Color not in cache, so search for it now
			color = [self searchForColorByName:cssColorName];
			
			// Set the value in cache, storing NSNull on failure
			[colorNameCache setObject:(color ?: (id)[NSNull null])
							   forKey:cssColorName];
		}
	}
	
	return color;
}

#pragma mark UIColor_Expanded initialization

+ (void)load {
	colorNameCache = [[NSMutableDictionary alloc] init];
}

@end

#pragma mark -

@implementation UIColor (UIColor_Expanded_Support)
/*
 * Database of color names and hex rgb values, derived
 * from the css 3 color spec:
 *	http://www.w3.org/TR/css3-color/
 *
 * We think this is a very compact way of storing
 * this information, and relatively cheap to lookup.
 *
 * Note that we search for color names starting with ','
 * and terminated by '#', so that we don't get false matches.
 * For this reason, the database begins with ','.
 */
static const char *colorNameDB = ","
	"aliceblue#f0f8ffff,antiquewhite#faebd7ff,aqua#00ffffff,aquamarine#7fffd4ff,azure#f0ffffff,"
	"beige#f5f5dcff,bisque#ffe4c4ff,black#000000ff,blanchedalmond#ffebcdff,blue#0000ffff,"
	"blueviolet#8a2be2ff,brown#a52a2aff,burlywood#deb887ff,cadetblue#5f9ea0ff,chartreuse#7fff00ff,"
	"chocolate#d2691eff,coral#ff7f50ff,cornflowerblue#6495edff,cornsilk#fff8dcff,crimson#dc143cff,"
	"cyan#00ffffff,darkblue#00008bff,darkcyan#008b8bff,darkgoldenrod#b8860bff,darkgray#a9a9a9ff,"
	"darkgreen#006400ff,darkgrey#a9a9a9ff,darkkhaki#bdb76bff,darkmagenta#8b008bff,"
	"darkolivegreen#556b2fff,darkorange#ff8c00ff,darkorchid#9932ccff,darkred#8b0000ff,"
	"darksalmon#e9967aff,darkseagreen#8fbc8fff,darkslateblue#483d8bff,darkslategray#2f4f4fff,"
	"darkslategrey#2f4f4fff,darkturquoise#00ced1ff,darkviolet#9400d3ff,deeppink#ff1493ff,"
	"deepskyblue#00bfffff,dimgray#696969ff,dimgrey#696969ff,dodgerblue#1e90ffff,"
	"firebrick#b22222ff,floralwhite#fffaf0ff,forestgreen#228b22ff,fuchsia#ff00ffff,"
	"gainsboro#dcdcdcff,ghostwhite#f8f8ffff,gold#ffd700ff,goldenrod#daa520ff,gray#808080ff,"
	"green#008000ff,greenyellow#adff2fff,grey#808080ff,honeydew#f0fff0ff,hotpink#ff69b4ff,"
	"indianred#cd5c5cff,indigo#4b0082ff,ivory#fffff0ff,khaki#f0e68cff,lavender#e6e6faff,"
	"lavenderblush#fff0f5ff,lawngreen#7cfc00ff,lemonchiffon#fffacdff,lightblue#add8e6ff,"
	"lightcoral#f08080ff,lightcyan#e0ffffff,lightgoldenrodyellow#fafad2ff,lightgray#d3d3d3ff,"
	"lightgreen#90ee90ff,lightgrey#d3d3d3ff,lightpink#ffb6c1ff,lightsalmon#ffa07aff,"
	"lightseagreen#20b2aaff,lightskyblue#87cefaff,lightslategray#778899ff,"
	"lightslategrey#778899ff,lightsteelblue#b0c4deff,lightyellow#ffffe0ff,lime#00ff00ff,"
	"limegreen#32cd32ff,linen#faf0e6ff,magenta#ff00ffff,maroon#800000ff,mediumaquamarine#66cdaaff,"
	"mediumblue#0000cdff,mediumorchid#ba55d3ff,mediumpurple#9370dbff,mediumseagreen#3cb371ff,"
	"mediumslateblue#7b68eeff,mediumspringgreen#00fa9aff,mediumturquoise#48d1ccff,"
	"mediumvioletred#c71585ff,midnightblue#191970ff,mintcream#f5fffaff,mistyrose#ffe4e1ff,"
	"moccasin#ffe4b5ff,navajowhite#ffdeadff,navy#000080ff,oldlace#fdf5e6ff,olive#808000ff,"
	"olivedrab#6b8e23ff,orange#ffa500ff,orangered#ff4500ff,orchid#da70d6ff,palegoldenrod#eee8aaff,"
	"palegreen#98fb98ff,paleturquoise#afeeeeff,palevioletred#db7093ff,papayawhip#ffefd5ff,"
	"peachpuff#ffdab9ff,peru#cd853fff,pink#ffc0cbff,plum#dda0ddff,powderblue#b0e0e6ff,"
	"purple#800080ff,red#ff0000ff,rosybrown#bc8f8fff,royalblue#4169e1ff,saddlebrown#8b4513ff,"
	"salmon#fa8072ff,sandybrown#f4a460ff,seagreen#2e8b57ff,seashell#fff5eeff,sienna#a0522dff,"
	"silver#c0c0c0ff,skyblue#87ceebff,slateblue#6a5acdff,slategray#708090ff,slategrey#708090ff,"
	"snow#fffafaff,springgreen#00ff7fff,steelblue#4682b4ff,tan#d2b48cff,teal#008080ff,"
	"thistle#d8bfd8ff,tomato#ff6347ff,turquoise#40e0d0ff,violet#ee82eeff,wheat#f5deb3ff,"
	"white#ffffffff,whitesmoke#f5f5f5ff,yellow#ffff00ff,yellowgreen#9acd32";

+ (UIColor *)searchForColorByName:(NSString *)cssColorName {
	UIColor *result = nil;
	
	// Compile the string we'll use to search against the database
	// We search for ",<colorname>#" to avoid false matches
	const char *searchString = [[NSString stringWithFormat:@",%@#", cssColorName] UTF8String];
	
	// Search for the color name
	const char *found = strstr(colorNameDB, searchString);
	
	// If found, step past the search string and grab the hex representation
	if (found) {
		const char *after = found + strlen(searchString);
		int hex;
		if (sscanf(after, "%x", &hex) == 1) {
			result = [self colorWithRGBHex:hex];
		}
	}
	
	return result;
}
@end
