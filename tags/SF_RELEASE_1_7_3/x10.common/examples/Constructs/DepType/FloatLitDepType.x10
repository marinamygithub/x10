/*
 *
 * (C) Copyright IBM Corporation 2006
 *
 *  This file is part of X10 Test.
 *
 */
import harness.x10Test;

/**
 * Check that a float literal can be cast to float.
 */
public class FloatLitDepType extends x10Test {
	public boolean run() {
		float(:self==0.001F) f =  0.001F;
		return true;
	}

	public static void main(String[] args) {
		new FloatLitDepType().execute();
	}


}

