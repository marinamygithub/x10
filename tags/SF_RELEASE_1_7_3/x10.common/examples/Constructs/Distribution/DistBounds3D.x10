/*
 *
 * (C) Copyright IBM Corporation 2006
 *
 *  This file is part of X10 Test.
 *
 */
import harness.x10Test;

/**
 * Array bounds test - 3D.
 *
 * randomly generate 3D arrays and indices,
 *
 * see if the array index out of bounds exception occurs
 * in the right  conditions
 */
public class DistBounds3D extends x10Test {

	public boolean run() {
		final int COUNT = 200;
		final int L = 3;
		final int K = 1;
		for (int n = 0; n < COUNT; n++) {
			int i = ranInt(-L-K, L+K);
			int j = ranInt(-L-K, L+K);
			int k = ranInt(-L-K, L+K);
			int lb1 = ranInt(-L, L);
			int lb2 = ranInt(-L, L);
			int lb3 = ranInt(-L, L);
			int ub1 = ranInt(lb1, L);
			int ub2 = ranInt(lb2, L);
			int ub3 = ranInt(lb3, L);
			int d = ranInt(0, dist2.N_DIST_TYPES-1);
			boolean withinBounds = arrayAccess(lb1, ub1, lb2, ub2, lb3, ub3, i, j, k, d);
			chk(iff(withinBounds,
						i >= lb1 && i <= ub1 &&
						j >= lb2 && j <= ub2 &&
						k >= lb3 && k <= ub3));
		}
		return true;
	}

	/**
	 * create a[lb1..ub1,lb2..ub2,lb3..ub3] then access a[i,j,k],
	 * return true iff
	 * no array bounds exception occurred
	 */
	private static boolean arrayAccess(int lb1, int ub1,
			int lb2, int ub2, int lb3, int ub3, final int i, final int j, final int k,
			int distType) {

		//pr(lb1+" "+ub1+" "+lb2+" "+ub2+" "+lb3+" "+ub3+" "+i+" "+j+" "+k+" "+ distType);

		final int[.] a = new int[dist2.getDist(distType, [lb1:ub1,lb2:ub2,lb3:ub3])];

		boolean withinBounds = true;
		try {
			chk(a.distribution[i,j,k].id<x10.lang.place.MAX_PLACES &&
					a.distribution[i,j,k].id >= 0);
			finish async(a.distribution[i,j,k]) {
				a[i,j,k] = (int) 0xabcdef07L;
				chk(a[i,j,k] == (int) 0xabcdef07L);
			}
		} catch (ArrayIndexOutOfBoundsException e) {
			withinBounds = false;
		}

		//pr(lb1+" "+ub1+" "+lb2+" "+ub2+" "+lb3+" "+ub3+" "+i+" "+j+" "+k+" "+distType+" "+ withinBounds);

		return withinBounds;
	}

	// utility methods after this point

	/**
	 * print a string
	 */
	private static void pr(String s) {
		System.out.println(s);
	}

	/**
	 * true iff (x if and only if y)
	 */
	private static boolean iff(boolean x, boolean y) {
		return x == y;
	}

	public static void main(String[] args) {
		new DistBounds3D().execute();
	}

	/**
	 * utility for creating a dist from a
	 * a dist type int value
	 */
	static class dist2 {
		// Java has poor support for enum
		public final static int BLOCK = 0;
		public final static int CYCLIC = 1;
		public final static int CONSTANT = 2;
		public final static int RANDOM = 3;
		public final static int ARBITRARY = 4;
		public final static int N_DIST_TYPES = 5;

		/**
		 * Return a dist with region r, of type disttype
		 */
		public static dist getDist(int distType, region r) {
			switch(distType) {
				case BLOCK: return dist.factory.block(r);
				case CYCLIC: return dist.factory.cyclic(r);
				case CONSTANT: return dist.factory.constant(r, here);
				case RANDOM: return dist.factory.random(r);
				case ARBITRARY: return dist.factory.arbitrary(r);
				default: throw new Error("TODO");
			}
		}
	}
}

