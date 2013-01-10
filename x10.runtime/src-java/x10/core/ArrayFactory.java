/*
 *  This file is part of the X10 project (http://x10-lang.org).
 *
 *  This file is licensed to You under the Eclipse Public License (EPL);
 *  You may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *      http://www.opensource.org/licenses/eclipse-1.0.php
 *
 *  (C) Copyright IBM Corporation 2006-2010.
 */

package x10.core;

import x10.rtt.Type;

public abstract class ArrayFactory {

    public static <T> x10.array.Array<T> makeArrayFromJavaArray(Type type, Object value) {
        int length = type.arrayLength(value);
        // XTENLANG-3063
//        x10.array.Array<T> array = new x10.array.Array<T>((java.lang.System[]) null, type).$init(length);
        x10.array.Array<T> array = new x10.array.Array<T>((java.lang.System[]) null, type).x10$array$Array$$init$S(length);
        System.arraycopy(value, 0, array.raw.value, 0, length);
        return array;
    }
}