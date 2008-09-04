/*
 *
 * (C) Copyright IBM Corporation 2006
 *
 *  This file is part of X10 Test.
 *
 */
import harness.x10Test;;

/**
 * The test checks that property syntax is accepted.
 *
 * @author pvarma
 */
public class RailTest extends x10Test {

	public def this(): RailTest = {
	  
	}
	public def run(): boolean = {
		val r:region{rail} = 0..10;
		var d: dist{rail} = Dist.makeBlock(r);
		var a: Array[double]{rail} = Array.make[double](d, (x:Point)=>0.0);
	    return true;
	}
	public static def main(var args: Rail[String]): void = {
		new RailTest().execute();
	}
}
