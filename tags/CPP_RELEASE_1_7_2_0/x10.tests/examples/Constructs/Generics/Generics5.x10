/*
 *
 * (C) Copyright IBM Corporation 2008
 *
 *  This file is part of X10 Test.
 *
 */
import harness.x10Test;

/**
 * Test a generics class with an invariant parameter.
 *
 * @author nystrom 8/2008
 */
public class Generics5 extends x10Test {
        public def run(): boolean = {
                var result: boolean = true;

                val v = Rail.makeVar[int](3, (i:int) => 2*i);
                for (var i: int = 0; i < v.length; i++)
                        result &= v(i) == (i*2);

                return result;
        }

	public static def main(var args: Rail[String]): void = {
		new Generics5().execute();
	}
}

