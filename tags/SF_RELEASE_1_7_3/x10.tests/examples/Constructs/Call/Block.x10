/*
 *
 * (C) Copyright IBM Corporation 2006
 *
 *  This file is part of X10 Test.
 *
 */
import harness.x10Test;

/**
 * Check that the dist.block method propagates region properties from arg to result
 */
public class Block extends x10Test {
	public def run(): boolean = {
		var r: Region{rect&&zeroBased&&rank==1} = [0..9];
		var d: Dist{rect&&zeroBased&&rank==1} = Dist.makeBlock(r, 0);
		return true;
	}

	public static def main(var args: Rail[String]): void = {
		new Block().execute();
	}


}
