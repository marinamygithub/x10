// (C) Copyright IBM Corporation 2008
// This file is part of X10 Test. *

import harness.x10Test;


/**
 * Basic typdefs and type equivalence.
 *
 * Type definitions are applicative, not generative; that is, they define
 * aliases for types and do not introduce new types.
 *
 * @author bdlucas 9/2008
 */

public class TypedefIterated05_MustFailCompile extends TypedefTest {

    public def run(): boolean = {
        
        type A = B;
        type B = A;

        return result;
    }

    public static def main(var args: Rail[String]): void = {
        new TypedefIterated05_MustFailCompile().execute();
    }
}
