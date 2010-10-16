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

import harness.x10Test;

/**
 * Basic typdefs and type equivalence.
 *
 * Type definitions are applicative, not generative; that is, they define
 * aliases for types and do not introduce new types.
 *
 * @author bdlucas 9/2008
 */

public class TypedefBasic4 extends TypedefTest {

    public def run(): boolean = {
        
        class X(i:int,s:String) {def this(i:int,s:String):X{self.i==i,self.s==s} = property(i,s);}

        type A(i:int,s:String) = X{self.i==i&&self.s==s};
        a:A(1,"1") = new X(1,"1");

        return result;
    }

    public static def main(var args: Array[String](1)): void = {
        new TypedefBasic4().execute();
    }
}
