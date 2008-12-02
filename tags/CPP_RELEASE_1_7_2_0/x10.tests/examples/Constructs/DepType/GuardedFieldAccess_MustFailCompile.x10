/*
 *
 * (C) Copyright IBM Corporation 2006
 *
 *  This file is part of X10 Test.
 *
 */
//LIMITATION:
//The current release does not implement guarded methods or fields.

/**Tests that a field of a class C, guarded with this(:c), is accessed only in objects
 * whose type is a subtype of C(:c).
 *@author pvarma
 *
 */

import harness.x10Test;

public class GuardedFieldAccess_MustFailCompile extends x10Test { 

	class Test(i:int, j:int) {
		public var v{i==j}: int = 5;
		def this(i:int, j:int): Test{self.i==i,self.j==j} = {
			property(i,j);
		}
	}
		
	public def run():boolean= {
		val t = new Test(6, 5);
		t.v = t.v + 1; // Must fail. t needs to be of type Test(:i==j).
	   return true;
	}  
	
    	public static def main(Rail[String]) = {
		new GuardedFieldAccess_MustFailCompile().execute();
	}
   

		
}
