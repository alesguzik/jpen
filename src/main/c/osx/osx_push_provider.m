/* [{
Copyright 2008 Brien Colwell <xcolwell at users.sourceforge.net>
Copyright 2009 Marcello Bastea-Forte <marcello at cellosoft.com>

This file is part of jpen.

jpen is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.

jpen is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with jpen.  If not, see <http://www.gnu.org/licenses/>.

This file incorporates work covered by the following copyright and  
permission notice:

	Copyright 2006 Jerry Huxtable
	
	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at
	
		 http://www.apache.org/licenses/LICENSE-2.0
	
	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
}] */

/*
Based on code by Jerry Huxtable. See http://www.jhlabs.com/java/tablet/ .
 Also based on code from 
 http://mxr.mozilla.org/mozilla/source/widget/src/cocoa/nsChildView.h
 http://firefox-3.1.sourcearchive.com/lines/3.1~b2plus-pbuild1plus-pnobinonly/nsChildView_8mm-source.html
*/

#import <jni.h>
#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import <objc/runtime.h>
#import "JRSwizzle.h"
#import "../nativeBuild/osx-BuildNumber.h"
#import "WacomAccess.h"
//#include "NSDate_Additions.h"

/* these are not defined in 10.5 */
#if MAC_OS_X_VERSION_MAX_ALLOWED == MAC_OS_X_VERSION_10_5
enum {
    NSEventTypeGesture          = 29,
    NSEventTypeMagnify          = 30,
    NSEventTypeSwipe            = 31,
    NSEventTypeRotate           = 18,
    NSEventTypeBeginGesture     = 19,
    NSEventTypeEndGesture       = 20
};
@interface NSEvent (JPen)
- (CGFloat)magnification;       
- (CGFloat)deviceDeltaX;
- (CGFloat)deviceDeltaY;
- (EventRef)_eventRef;
@end

#endif

/* Our global variables */
static JavaVM *g_jvm;
static jobject g_object;
static jclass g_class;
static jmethodID g_methodID;
static jmethodID g_methodID_prox;
static jmethodID g_methodID_scroll;
static jmethodID g_methodID_swipe;
static jmethodID g_methodID_magnify;
static jmethodID g_methodID_rotate;
static bool enabled = 0;
static jboolean watchTabletEvents = false;
static jboolean watchProximityEvents = true;
static jboolean watchScrollEvents = false;
static jboolean watchGestureEvents = false;
static jboolean watchingEvents = true;
static double systemStartTime = 0;

/*
 ** A subclass of NSApplication which overrides sendEvent and calls back into Java with the event data for mouse events.
 */
@interface NSApplication (JPen)
- (void) JPen_sendEvent:(NSEvent *)event;
@end

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved)
{
	g_jvm = vm;
	
	return JNI_VERSION_1_4;
}

static jint GetJNIEnv(JNIEnv **env, bool *mustDetach)
{
    jint getEnvErr = JNI_OK;
    *mustDetach = false;
    if (g_jvm) {
        getEnvErr = (*g_jvm)->GetEnv(g_jvm, (void **)env, JNI_VERSION_1_4);
        if (getEnvErr == JNI_EDETACHED) {
            getEnvErr = (*g_jvm)->AttachCurrentThread(g_jvm, (void **)env, NULL);
            if (getEnvErr == JNI_OK)
                *mustDetach = true;
        }
    }
    return getEnvErr;
}



bool throwException(JNIEnv *env, const char *message) {
//	env->ExceptionDescribe();
//	env->ExceptionClear();
	
//	jclass newExcCls = env->FindClass("cello/tablet/JTabletException");
//	if (newExcCls == 0) // Unable to find the new exception class, give up.
//		return false;
//	
//	env->ThrowNew(newExcCls, message);
	return true;
}


static NSPoint getLocation(NSEvent *event) {
	
	NSPoint location = [event locationInWindow];
	
	// Transform to screen coordinates...
	NSWindow *w = [event window];
	if (w != nil) {
		NSRect f = [w frame];
		
		location.x += f.origin.x;
		location.y += f.origin.y;
	}	
	
	
	
	// Flip Y axis 
	
	// At this point the location is relative to the bottom left of the main screen 
	// (the actual bottom left is 0,1, not 0,0, 
	//  so we can flip with screen.height - y and get 0,0 as the top-left corner)
	
		// Note: [NSScreen mainScreen] references the screen that has keyboard focus, 
		//  You need [NSScreen screens][0] for the origin/menubar screen
		// see http://developer.apple.com/mac/library/documentation/Cocoa/Reference/ApplicationKit/Classes/NSScreen_Class/Reference/Reference.html#//apple_ref/doc/uid/20000333-mainScreen
		// and http://developer.apple.com/mac/library/documentation/Cocoa/Reference/ApplicationKit/Classes/NSScreen_Class/Reference/Reference.html#//apple_ref/doc/uid/20000333-screens
		// the documentation recommends against caching this
		NSScreen *originScreen = [[NSScreen screens] objectAtIndex:0];
	
	location.y = [originScreen frame].size.height - location.y;
	
	return location;
}

static void postProximityEvent(JNIEnv *env, NSEvent* event) {
	
	// This location is bogus. It merely represents the last point the cursor was at, 
	// not the new point for the device entering proximity	
	//NSPoint location = getLocation(event);
	(*env)->CallVoidMethod(env, g_object, g_methodID_prox,
						   [event timestamp]+systemStartTime,
						   [event modifierFlags],
						   [event capabilityMask],
						   [event deviceID],
						   [event isEnteringProximity],
						   [event pointingDeviceID],
						   [event pointingDeviceSerialNumber],
						   [event pointingDeviceType],
						   [event systemTabletID],
						   [event tabletID],
						   [event uniqueID],
						   [event vendorID],
						   [event vendorPointingDeviceType]
						   );
	
}


@implementation NSApplication (JPen)
- (void) JPen_sendEvent:(NSEvent *)event
{			
	if (watchingEvents) {
		JNIEnv *env;
		bool shouldDetach = false;
		
		if (GetJNIEnv(&env, &shouldDetach) == JNI_OK) {			
			switch ( [event type] ) {
				case NSTabletProximity:
					if (watchProximityEvents) {
						postProximityEvent(env, event);
					}
					break;
				case NSScrollWheel:
					if (watchScrollEvents) {
						float dx = 0, dy = 0;
						bool useDeviceDelta = false;
						
						// Turns out that deviceDeltaX/Y trigger an assertion if you try to access them on a scroll 
						// event that doesn't actually have them (e.g. from an actual scroll mouse, not multi-touch)
						// Unfortunately, [event respondsToSelector:@selector(deviceDeltaX)] always returns true, 
						// even when it ends up throwing an assertion.
						
						// Using code found at http://firefox-3.1.sourcearchive.com/lines/3.1~b2plus-pbuild1plus-pnobinonly/nsChildView_8mm-source.html
						// I discovered that you can get the underlying Carbon event that the Cocoa event maps to,
						// and it can be checked for being of type "kEventMouseScroll" to determine whether deviceDeltaX
						// is actually available.
						if ([event respondsToSelector:@selector(_eventRef)] && 
							[event respondsToSelector:@selector(deviceDeltaX)]) {
							EventRef theCarbonEvent = [event _eventRef];
							useDeviceDelta = theCarbonEvent && GetEventKind(theCarbonEvent) == kEventMouseScroll;
						}
						if (useDeviceDelta) {
							dx = [event deviceDeltaX];
							dy = [event deviceDeltaY];
						} else {
							dx = [event deltaX];
							dy = [event deltaY];
						}
						if (dx != 0 || dy != 0) {
							NSPoint location = getLocation(event);
							(*env)->CallVoidMethod(env, g_object, g_methodID_scroll,
												[event timestamp]+systemStartTime,
												[event modifierFlags],
												location.x,
												location.y,
												useDeviceDelta,
												dx,
												dy
												   );
						}
						
					}
					break;
				case NSEventTypeMagnify:
					if (watchGestureEvents) {
						float magnification =  [event magnification];
						if (magnification != 0) {
							NSPoint location = getLocation(event);
							(*env)->CallVoidMethod(env, g_object, g_methodID_magnify,
												   [event timestamp]+systemStartTime,
												   [event modifierFlags],
												   location.x,
												   location.y,
												   magnification
												   );
						}
						
					}
					break;
				case NSEventTypeSwipe:
					if (watchGestureEvents) {
						float dx = [event deltaX];
						float dy = [event deltaY];
						if (dx != 0 || dy != 0) {
							NSPoint location = getLocation(event);		
							(*env)->CallVoidMethod(env, g_object, g_methodID_swipe,
												   [event timestamp]+systemStartTime,
												   [event modifierFlags],
												   location.x,
												   location.y,
												   dx,
												   dy
												   );
						}
						
					}
					break;
				case NSEventTypeRotate:
					if (watchGestureEvents) {
						float rotation = [event rotation];
						if (rotation != 0) {
							NSPoint location = getLocation(event);		
							(*env)->CallVoidMethod(env, g_object, g_methodID_rotate,
												   [event timestamp]+systemStartTime,
												   [event modifierFlags],
												   location.x,
												   location.y,
												   rotation
												   );
						}
						
					}
					break;
				case NSEventTypeGesture:
				case NSEventTypeBeginGesture:
				case NSEventTypeEndGesture:
					break;
					
				case NSMouseMoved:
				case NSLeftMouseDown:
				case NSLeftMouseUp:
				case NSLeftMouseDragged:
				case NSRightMouseDown:
				case NSRightMouseUp:
				case NSRightMouseDragged:
				case NSOtherMouseDown:
				case NSOtherMouseUp:
				case NSOtherMouseDragged:
				case NSTabletPoint:
				{
					if (watchTabletEvents) {
						bool tablet = NSTabletPoint == [event type] || NSTabletPointEventSubtype == [event subtype];
						
						// Apparently this is a duplicate of the proximity event, so we don't want to do anything with it...
						if (NSTabletPoint != [event type] && [event subtype] == NSTabletProximityEventSubtype) {
							break;
							//postProximityEvent(env, event);
						}
						
						NSPoint location = getLocation(event);				
						NSPoint tilt;
						if (tablet) {
							tilt = [event tilt];
						}
						
						(*env)->CallVoidMethod( env, g_object, g_methodID,
											   [event type],
											   [event timestamp]+systemStartTime,
											   [event modifierFlags],
											   location.x,
											   location.y,
											   tablet,
											   tablet ? [event absoluteX] : 0 ,
											   tablet ? [event absoluteY] : 0 ,
											   tablet ? [event absoluteZ] : 0 ,
											   tablet ? [event buttonMask] : 0,
											   tablet ? [event pressure] : 0,
											   tablet ? [event rotation] : 0,
											   tablet ? tilt.x : 0,
											   tablet ? tilt.y : 0,
											   tablet ? [event tangentialPressure] : 0
											   );
					}
					break;
				}
			}
			
			if (shouldDetach) {
				(*g_jvm)->DetachCurrentThread(g_jvm);
			}
		} else {
			NSLog(@"Couldn't attach to JVM");
		}
	}
    
	// believe it or not, this is not recursive... when we swap NSApplication's sendEvent method with this one, 
	// JPen_sendEvent points to the original NSApplication sendEvent
    [self JPen_sendEvent:event];
}
@end

static void updateWatchingEvents() {
	// Proximity events aren't coalesced
	BOOL trackMovement = watchTabletEvents || watchScrollEvents || watchGestureEvents;
	[NSEvent setMouseCoalescingEnabled: trackMovement];
	
	watchingEvents = watchProximityEvents || trackMovement;
}


JNIEXPORT jint JNICALL Java_jpen_provider_osx_CocoaAccess_getNativeBuild(JNIEnv *env, jobject this) {
	return BUILD_NUMBER;
}


JNIEXPORT void JNICALL Java_jpen_provider_osx_CocoaAccess_setTabletEventsEnabled(JNIEnv *env, jobject this, jboolean enabled) {
    watchTabletEvents = enabled;
	updateWatchingEvents();
}
JNIEXPORT void JNICALL Java_jpen_provider_osx_CocoaAccess_setProximityEventsEnabled(JNIEnv *env, jobject this, jboolean enabled) {
	watchProximityEvents = enabled;
	updateWatchingEvents();
}
JNIEXPORT void JNICALL Java_jpen_provider_osx_CocoaAccess_setScrollEventsEnabled(JNIEnv *env, jobject this, jboolean enabled) {
	watchScrollEvents = enabled;
	updateWatchingEvents();
}
JNIEXPORT void JNICALL Java_jpen_provider_osx_CocoaAccess_setGestureEventsEnabled(JNIEnv *env, jobject this, jboolean enabled) {
	watchGestureEvents = enabled;
	updateWatchingEvents();
}

/*
 ** Start up: use jrswizzle to subclass the NSApplication object on the fly.
 */
JNIEXPORT void JNICALL Java_jpen_provider_osx_CocoaAccess_startup(JNIEnv *env, jobject this) {
	// Don't startup multiple times
	if (g_object) {
		return;
	}
	
	// Swap the original sendEvent method with our custom one so we can monitor events
	NSError *error = nil;
	[NSApplication jr_swizzleMethod:@selector(sendEvent:)
						 withMethod:@selector(JPen_sendEvent:)
							  error:&error];
	if (error != nil) {
		NSLog(@"error overriding [NSApplication sendEvent]: %@", [error description]);
		throwException(env,"Error initializing event monitor");
	} else {
//		NSDate *startDate = [[NSDate alloc] initWithDateOfSystemStartup];
//		systemStartTime = [startDate timeIntervalSince1970];
//		[startDate release];
		
		g_object = (*env)->NewGlobalRef( env, this );
		g_class = (*env)->GetObjectClass( env, this );
		g_class = (*env)->NewGlobalRef( env, g_class );
		if ( g_class != (jclass)0 ) {
			g_methodID =	     (*env)->GetMethodID( env, g_class, "postEvent",		  "(IDIFFZIIIIFFFFF)V" );
			g_methodID_prox =    (*env)->GetMethodID( env, g_class, "postProximityEvent", "(DIIIZIIIIIJII)V" );
			g_methodID_scroll =  (*env)->GetMethodID( env, g_class, "postScrollEvent",    "(DIFFZFF)V" );
			g_methodID_magnify = (*env)->GetMethodID( env, g_class, "postMagnifyEvent",   "(DIFFF)V" );
			g_methodID_swipe =   (*env)->GetMethodID( env, g_class, "postSwipeEvent",     "(DIFFFF)V" );
			g_methodID_rotate =  (*env)->GetMethodID( env, g_class, "postRotateEvent",    "(DIFFF)V" );
		}
		ResendLastTabletEventofType(eEventProximity);
	}
}

/*
 ** Shut down: release our data.
 */
JNIEXPORT void JNICALL Java_jpen_provider_osx_CocoaAccess_shutdown(JNIEnv *env, jobject this) {
    if ( g_object )
        (*env)->DeleteGlobalRef( env, g_object );
    if ( g_class )
        (*env)->DeleteGlobalRef( env, g_class );
    g_object = NULL;
    g_class = NULL;
}


// CONSTANTS

//JNIEXPORT jintArray Java_jpen_provider_osx_CocoaAccess_getPointingDeviceTypes(JNIEnv *env, jobject this) {
//	jint a[4];
//	a[0] = NSUnknownPointingDevice;
//	a[1] = NSPenPointingDevice;
//	a[2] = NSCursorPointingDevice;
//	a[3] = NSEraserPointingDevice;
//	
//	jintArray types = (*env)->NewIntArray(env, 4);
//	(*env)->SetIntArrayRegion(env, types, 0, 4, (jint*) a);
//	
//	return types;
//	
//	//NSUnknownPointingDevice = NX_TABLET_POINTER_UNKNOWN,
//	//NSPenPointingDevice     = NX_TABLET_POINTER_PEN,
//	//NSCursorPointingDevice  = NX_TABLET_POINTER_CURSOR,
//	//NSEraserPointingDevice  = NX_TABLET_POINTER_ERASER
//}
//
//// NOTE: also want this for button masks
//
//JNIEXPORT jintArray Java_jpen_provider_osx_CocoaAccess_getButtonMasks(JNIEnv *env, jobject this) {
//	jint a[3];
//	a[0] = NSPenTipMask;
//	a[1] = NSPenLowerSideMask;
//	a[2] = NSPenUpperSideMask;
//	
//	jintArray types = (*env)->NewIntArray(env, 3);
//	(*env)->SetIntArrayRegion(env, types, 0, 3, (jint*) a);
//	
//	return types;
//	
//	//NSPenTipMask =       NX_TABLET_BUTTON_PENTIPMASK,
//	//NSPenLowerSideMask = NX_TABLET_BUTTON_PENLOWERSIDEMASK,
//	//NSPenUpperSideMask = NX_TABLET_BUTTON_PENUPPERSIDEMASK
//}
//




