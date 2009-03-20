/*
 *
 * (C) Copyright IBM Corporation 2006
 *
 *  This file is part of X10 Test.
 *
 */
import harness.x10Test;

/**
 * Tests assignments to final fields in constructor.
 *
 * @author kemal, 3/2005
 */
public class FinalInitializationTest extends x10Test {

	static class myval {
		val intval: int;
		val cval: complex;
		val refval: foo;
		def this(var intval: int, var cval: complex, var refval: foo): myval = {
			this.intval = intval;
			this.cval = cval;
			this.refval = refval;
		}
		def eq(var other: myval): boolean = {
			return
				this.intval == other.intval &&
				this.cval.eq(other.cval) &&
				this.refval == other.refval;
		}
	}

	static class foo {
		var w: int = 19;
	}

	static class complex {
		val re: int;
		val im: int;
		def this(var re: int, var im: int): complex = {
			this.re = re;
			this.im = im;
		}
		def add(var other: complex) = new complex(this.re+other.re,this.im+other.im);
		def eq(var other: complex) = this.re == other.re && this.im == other.im;
	}

	public def run(): boolean = {
		val f = new foo();
		val x  = new myval(1, new complex(2, 3), f);
		val y  = new myval(1, (new complex(1, 4)).add(new complex(1, -1)), f);
		return (x.eq(y));
	}

	public static def main(var args: Rail[String]): void = {
		new FinalInitializationTest().execute();
	}
}
