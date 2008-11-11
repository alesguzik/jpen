/* [{
Copyright 2008 Brien Colwell

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
*/

#include <jni.h>
#include <Cocoa/Cocoa.h>

/* Our global variables */
static JavaVM *g_jvm;
static jobject g_object;
static jclass g_class;
static jmethodID g_methodID;
static jmethodID g_methodID_prox;
static bool enabled = 0;

/*
** A subclass of NSApplication which overrides sendEvent and calls back into Java with the event data for mouse events.
** We don't handle tablet proximity events yet.
*/
@interface CustomApplication : NSApplication 
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

@implementation CustomApplication
- (void) sendEvent:(NSEvent *)event
{
	if (! enabled) {
		[super sendEvent: event];
		return;
	}
	
    JNIEnv *env;
    bool shouldDetach = false;

    if (GetJNIEnv(&env, &shouldDetach) != JNI_OK) {
        NSLog(@"Couldn't attach to JVM");
        return;
    }
    
    switch ( [event type] ) {
    case NSTabletProximity:
	    {
	    	(*env)->CallVoidMethod(env, g_object, g_methodID_prox,
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
//    case NSTabletPoint:
        {
        	bool tablet = NSTabletPointEventSubtype == [event subtype];
            NSPoint tilt = [event tilt];
            NSPoint location = [event locationInWindow];
            (*env)->CallVoidMethod( env, g_object, g_methodID,
                    [event type],
					//[event pointingDeviceType],
                    tablet ? 1 : NSMouseMoved == [event type] ? 2 : 0,
                    location.x,
                    location.y,
                    [event absoluteX],
                    [event absoluteY],
                    [event absoluteZ],
                    tablet ? [event buttonMask] : [event buttonNumber],
                    [event pressure],
                    [event rotation],
                    tilt.x,
                    tilt.y,
                    [event tangentialPressure],
                    0.0f, 0.0f, 0.0f
                );
        }
        break;
    default:
        break;
    }
    
    if (shouldDetach)
        (*g_jvm)->DetachCurrentThread(g_jvm);
    
    [super sendEvent: event];
}
@end



JNIEXPORT void JNICALL Java_jpen_provider_osx_CocoaAccess_enable(JNIEnv *env, jobject this) {
    enabled = 1;
}

JNIEXPORT void JNICALL Java_jpen_provider_osx_CocoaAccess_disable(JNIEnv *env, jobject this) {
	enabled = 0;
}



/*
** Start up: use poseAsClass to subclass the NSApplication object on the fly.
*/
JNIEXPORT void JNICALL Java_jpen_provider_osx_CocoaAccess_startup(JNIEnv *env, jobject this) {
    [CustomApplication poseAsClass: [NSApplication class]];
    g_object = (*env)->NewGlobalRef( env, this );
    g_class = (*env)->GetObjectClass( env, this );
    g_class = (*env)->NewGlobalRef( env, g_class );
    if ( g_class != (jclass)0 ) {
        g_methodID = (*env)->GetMethodID( env, g_class, "postEvent", "(IIFFIIIIFFFFFFFF)V" );
        g_methodID_prox = (*env)->GetMethodID( env, g_class, "postProximityEvent", "(IIZIIIIIIII)V" );
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

JNIEXPORT jintArray Java_jpen_provider_osx_CocoaAccess_getPointingDeviceTypes(JNIEnv *env, jobject this) {
	jint a[4];
	a[0] = NSUnknownPointingDevice;
	a[1] = NSPenPointingDevice;
	a[2] = NSCursorPointingDevice;
	a[3] = NSEraserPointingDevice;
	
	jintArray types = (*env)->NewIntArray(env, 4);
	(*env)->SetIntArrayRegion(env, types, 0, 4, (jint*) a);
	
	return types;
	
//NSUnknownPointingDevice = NX_TABLET_POINTER_UNKNOWN,
//NSPenPointingDevice     = NX_TABLET_POINTER_PEN,
//NSCursorPointingDevice  = NX_TABLET_POINTER_CURSOR,
//NSEraserPointingDevice  = NX_TABLET_POINTER_ERASER
}

// NOTE: also want this for button masks

JNIEXPORT jintArray Java_jpen_provider_osx_CocoaAccess_getButtonMasks(JNIEnv *env, jobject this) {
	jint a[3];
	a[0] = NSPenTipMask;
	a[1] = NSPenLowerSideMask;
	a[2] = NSPenUpperSideMask;
		
	jintArray types = (*env)->NewIntArray(env, 3);
	(*env)->SetIntArrayRegion(env, types, 0, 3, (jint*) a);
		
	return types;
	
//NSPenTipMask =       NX_TABLET_BUTTON_PENTIPMASK,
//NSPenLowerSideMask = NX_TABLET_BUTTON_PENLOWERSIDEMASK,
//NSPenUpperSideMask = NX_TABLET_BUTTON_PENUPPERSIDEMASK
}





