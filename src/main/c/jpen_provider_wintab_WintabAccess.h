/* [{
Copyright 2007, 2008 Nicolas Carranza <nicarran at gmail.com>

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
}] */
/* DO NOT EDIT THIS FILE - it is machine generated */
#include <jni.h>
/* Header for class jpen_provider_wintab_WintabAccess */

#ifndef _Included_jpen_provider_wintab_WintabAccess
#define _Included_jpen_provider_wintab_WintabAccess
#ifdef __cplusplus
extern "C" {
#endif
/* Inaccessible static: bootTimeUtc */
/*
 * Class:     jpen_provider_wintab_WintabAccess
 * Method:    create
 * Signature: ()I
 */
JNIEXPORT jint JNICALL Java_jpen_provider_wintab_WintabAccess_create
  (JNIEnv *, jclass);

/*
 * Class:     jpen_provider_wintab_WintabAccess
 * Method:    getError
 * Signature: ()Ljava/lang/String;
 */
JNIEXPORT jstring JNICALL Java_jpen_provider_wintab_WintabAccess_getError
  (JNIEnv *, jclass);

/*
 * Class:     jpen_provider_wintab_WintabAccess
 * Method:    getValue
 * Signature: (II)I
 */
JNIEXPORT jint JNICALL Java_jpen_provider_wintab_WintabAccess_getValue
  (JNIEnv *, jclass, jint, jint);

/*
 * Class:     jpen_provider_wintab_WintabAccess
 * Method:    nextPacket
 * Signature: (I)Z
 */
JNIEXPORT jboolean JNICALL Java_jpen_provider_wintab_WintabAccess_nextPacket
  (JNIEnv *, jclass, jint);

/*
 * Class:     jpen_provider_wintab_WintabAccess
 * Method:    getEnabled
 * Signature: (I)Z
 */
JNIEXPORT jboolean JNICALL Java_jpen_provider_wintab_WintabAccess_getEnabled
  (JNIEnv *, jclass, jint);

/*
 * Class:     jpen_provider_wintab_WintabAccess
 * Method:    setEnabled
 * Signature: (IZ)V
 */
JNIEXPORT void JNICALL Java_jpen_provider_wintab_WintabAccess_setEnabled
  (JNIEnv *, jclass, jint, jboolean);

/*
 * Class:     jpen_provider_wintab_WintabAccess
 * Method:    getLevelRange
 * Signature: (II)[I
 */
JNIEXPORT jintArray JNICALL Java_jpen_provider_wintab_WintabAccess_getLevelRange
  (JNIEnv *, jclass, jint, jint);

/*
 * Class:     jpen_provider_wintab_WintabAccess
 * Method:    getCursor
 * Signature: (I)I
 */
JNIEXPORT jint JNICALL Java_jpen_provider_wintab_WintabAccess_getCursor
  (JNIEnv *, jclass, jint);

/*
 * Class:     jpen_provider_wintab_WintabAccess
 * Method:    getTime
 * Signature: (I)J
 */
JNIEXPORT jlong JNICALL Java_jpen_provider_wintab_WintabAccess_getTime
  (JNIEnv *, jclass, jint);

/*
 * Class:     jpen_provider_wintab_WintabAccess
 * Method:    getButtons
 * Signature: (I)I
 */
JNIEXPORT jint JNICALL Java_jpen_provider_wintab_WintabAccess_getButtons
  (JNIEnv *, jclass, jint);

/*
 * Class:     jpen_provider_wintab_WintabAccess
 * Method:    getCursorTypeOrdinal
 * Signature: (I)I
 */
JNIEXPORT jint JNICALL Java_jpen_provider_wintab_WintabAccess_getCursorTypeOrdinal
  (JNIEnv *, jclass, jint);

/*
 * Class:     jpen_provider_wintab_WintabAccess
 * Method:    getFirstCursor
 * Signature: (I)I
 */
JNIEXPORT jint JNICALL Java_jpen_provider_wintab_WintabAccess_getFirstCursor
  (JNIEnv *, jclass, jint);

/*
 * Class:     jpen_provider_wintab_WintabAccess
 * Method:    getCursorsCount
 * Signature: (I)I
 */
JNIEXPORT jint JNICALL Java_jpen_provider_wintab_WintabAccess_getCursorsCount
  (JNIEnv *, jclass, jint);

/*
 * Class:     jpen_provider_wintab_WintabAccess
 * Method:    getCursorActive
 * Signature: (I)Z
 */
JNIEXPORT jboolean JNICALL Java_jpen_provider_wintab_WintabAccess_getCursorActive
  (JNIEnv *, jclass, jint);

/*
 * Class:     jpen_provider_wintab_WintabAccess
 * Method:    getCursorName
 * Signature: (I)Ljava/lang/String;
 */
JNIEXPORT jstring JNICALL Java_jpen_provider_wintab_WintabAccess_getCursorName
  (JNIEnv *, jclass, jint);

/*
 * Class:     jpen_provider_wintab_WintabAccess
 * Method:    getPhysicalId
 * Signature: (I)J
 */
JNIEXPORT jlong JNICALL Java_jpen_provider_wintab_WintabAccess_getPhysicalId
  (JNIEnv *, jclass, jint);

/*
 * Class:     jpen_provider_wintab_WintabAccess
 * Method:    getCursorMode
 * Signature: (I)I
 */
JNIEXPORT jint JNICALL Java_jpen_provider_wintab_WintabAccess_getCursorMode
  (JNIEnv *, jclass, jint);

/*
 * Class:     jpen_provider_wintab_WintabAccess
 * Method:    getDeviceName
 * Signature: (I)Ljava/lang/String;
 */
JNIEXPORT jstring JNICALL Java_jpen_provider_wintab_WintabAccess_getDeviceName
  (JNIEnv *, jclass, jint);

/*
 * Class:     jpen_provider_wintab_WintabAccess
 * Method:    getDefCtxSysMode
 * Signature: ()Z
 */
JNIEXPORT jboolean JNICALL Java_jpen_provider_wintab_WintabAccess_getDefCtxSysMode
  (JNIEnv *, jclass);

/*
 * Class:     jpen_provider_wintab_WintabAccess
 * Method:    getDDCtxSysMode
 * Signature: (I)Z
 */
JNIEXPORT jboolean JNICALL Java_jpen_provider_wintab_WintabAccess_getDDCtxSysMode
  (JNIEnv *, jclass, jint);

/*
 * Class:     jpen_provider_wintab_WintabAccess
 * Method:    destroy
 * Signature: (I)I
 */
JNIEXPORT jint JNICALL Java_jpen_provider_wintab_WintabAccess_destroy
  (JNIEnv *, jclass, jint);

/*
 * Class:     jpen_provider_wintab_WintabAccess
 * Method:    getButtonMap
 * Signature: (I)[I
 */
JNIEXPORT jintArray JNICALL Java_jpen_provider_wintab_WintabAccess_getButtonMap
  (JNIEnv *, jclass, jint);

/*
 * Class:     jpen_provider_wintab_WintabAccess
 * Method:    getStatus
 * Signature: (I)I
 */
JNIEXPORT jint JNICALL Java_jpen_provider_wintab_WintabAccess_getStatus
  (JNIEnv *, jclass, jint);

/*
 * Class:     jpen_provider_wintab_WintabAccess
 * Method:    getTiltExtSupported
 * Signature: (I)Z
 */
JNIEXPORT jboolean JNICALL Java_jpen_provider_wintab_WintabAccess_getTiltExtSupported
  (JNIEnv *, jclass, jint);

/*
 * Class:     jpen_provider_wintab_WintabAccess
 * Method:    getLcSysMode
 * Signature: (I)Z
 */
JNIEXPORT jboolean JNICALL Java_jpen_provider_wintab_WintabAccess_getLcSysMode
  (JNIEnv *, jclass, jint);

/*
 * Class:     jpen_provider_wintab_WintabAccess
 * Method:    getBootTimeUtc
 * Signature: (I)J
 */
JNIEXPORT jlong JNICALL Java_jpen_provider_wintab_WintabAccess_getBootTimeUtc
  (JNIEnv *, jclass, jint);

#ifdef __cplusplus
}
#endif
#endif