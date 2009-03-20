/*
 *
 * (C) Copyright IBM Corporation 2006
 *
 *  This file is part of X10 Language.
 *
 */
package x10.lang;

import x10.array.Operator;

/**
 * The base class for all (value or reference) multidimensional,
 * distributed int arrays in X10.  Is a subclass-only mutable class
 * (has no mutable state, and all methods are value methods).
 * Specialized from array by replacing the type parameter with int.
 *
 * Handtranslated from the X10 code in x10/lang/intArray.x10
 *
 * @author vj 12/24/2004
 */
abstract public class intArray extends x10Array {
	protected intArray(dist D, boolean mutable) {
		super(D, mutable);
	}

	abstract public int[] getBackingArray();
	

	public static final Operator.Binary sub = new Operator.Binary() { public int apply(int r, int s) { return r-s; }};
	public static final Operator.Binary add = new Operator.Binary() { public int apply(int r, int s) { return r+s; }};
	public static final Operator.Binary mul = new Operator.Binary() { public int apply(int r, int s) { return r*s; }};
	public static final Operator.Binary div = new Operator.Binary() { public int apply(int r, int s) { return r/s; }};
	public static final Operator.Binary max = new Operator.Binary() { public int apply(int r, int s) { return Math.max(r,s); }};
	public static final Operator.Unary abs = new Operator.Unary() { public int apply(int r) { return Math.abs(r); }};
	public static interface pointwiseOp/*(region r)*/ {
		int apply(point/*(r)*/ p);
	}

	public static class Constant extends Operator.Pointwise {
		private final int c_;
		public Constant(int c) { c_ = c; }
		public int apply(point p, int i) { return c_; }
	}

	/**
	 * Return the value of the array at the given point in the
	 * region.
	 */
	abstract /*value*/ public int get(point/*(region)*/ p);
	abstract public int getOrdinal(int p);
	//TODO: interim support for multi-index access.
	abstract /*value*/ public int get(int p);
	abstract /*value*/ public int get(int p, int q);
	abstract /*value*/ public int get(int p, int q, int r);
	abstract /*value*/ public int get(int p, int q, int r, int s);
//	abstract public int get(int[] p);

	/**
	 * Convenience method for returning the sum of the array.
	 * @return sum of the array.
	 */
	public int sum() {
		return reduce(add, 0);
	}
	/**
	 * Convenience method for returning the max of the array.
	 * @return
	 */
	public int max() {
		return reduce(max, java.lang.Integer.MIN_VALUE);
	}
	/**
	 * Convenience method for returning the max of the array after applying the given fun.
	 * @param fun
	 * @return
	 */
	public int max(Operator.Unary fun) {
		return lift(fun).reduce(max, java.lang.Integer.MIN_VALUE);
	}
	/**
	 * Convenience method for applying abs to each element in the array.
	 * @return
	 */
	public IntReferenceArray abs() {
		return lift(abs);
	}
	/**
	 * Convenience method for applying max after applying abs.
	 * @return
	 */
	public int maxAbs() {
		return max(abs);
	}

	public IntReferenceArray add(intArray other) {
		return lift(add, other);
	}
	public IntReferenceArray mul( intArray other) {
		return lift(mul, other);
	}
	public IntReferenceArray sub( intArray other) {
		return lift(sub, other);
	}
	public IntReferenceArray div( intArray other) {
		return lift(div, other);
	}
	public IntReferenceArray scale(final int k) {
		return lift( new Operator.Unary() { public int apply(int r) { return r*k; }});
	}
	/**
	 * Return the value obtained by reducing the given array with the
	 * function fun, which is assumed to be associative and
	 * commutative. unit should satisfy fun(unit,x)=x=fun(x,unit).
	 */
	abstract /*value*/ public int reduce(Operator.Binary fun, int unit);
	abstract /*value*/ public int reduce(Operator.Binary fun, region r);

	/**
	 * Return an IntArray with the same distribution as this, by
	 * scanning this with the function fun, and unit unit.
	 */
	abstract /*value*/ public IntReferenceArray/*(distribution)*/ scan(Operator.Binary fun, int unit);

	/**
	 * Return an array of B@P defined on the intersection of the
	 * region underlying the array and the parameter region R.
	 */
	abstract /*value*/ public /*(region(rank) R)*/
	IntReferenceArray/*(distribution.restriction(R)())*/  restriction(region R);

	/**
	 * Return an array of B@P defined on the intersection of
	 * the region underlying this and the parametric distribution.
	 */
	abstract /*value*/ public  /*(distribution(:rank=this.rank) D)*/
	IntReferenceArray/*(distribution.restriction(D.region)())*/ restriction(dist D);

	public IntReferenceArray restriction(place P) {
		return restriction(distribution.restriction(P));
	}

	/**
	 * Take as parameter a distribution D of the same rank as *
	 * this, and defined over a disjoint region. Take as argument an *
	 * array other over D. Return an array whose distribution is the
	 * union of this and D and which takes on the value
	 * this.atValue(p) for p in this.region and other.atValue(p) for p
	 * in other.region.
	 */
	abstract /*value*/ public /*(distribution(:region.disjoint(this.region) &&
	rank=this.rank) D)*/
	IntReferenceArray/*(distribution.union(D))*/ union( intArray/*(D)*/ other);

	/**
	 * Return the array obtained by overlaying this array on top of
	 * other. The method takes as parameter a distribution D over the
	 * same rank. It returns an array over the distribution
	 * dist.asymmetricUnion(D).
	 */
	abstract /*value*/ public /*(distribution(:rank=this.rank) D)*/
	IntReferenceArray/*(distribution.asymmetricUnion(D))*/ overlay( intArray/*(D)*/ other);

	/**
	 * Update this array in place by overlaying the array other on top of
	 * this. The distribution of the input array must be a subdistribution
	 * of D.
	 * TODO: update the description of the parametric type.
	 */
	abstract public void update( intArray/*(D)*/ other);

	/** Assume given an intArray a over the given distribution.
	 * Assume given a function fun: int -> int -> int.
	 * Return an intArray with distribution dist
	 * containing fun(this.atValue(p),a.atValue(p)) for each p in
	 * dist.region.
	 */
	abstract /*value*/ public
	IntReferenceArray/*(distribution)*/ lift(Operator.Binary fun, intArray/*(distribution)*/ a);

	/**
	 * Apply the given fun: int -> int on each element of the array, returning
	 * an array with the same distribution.
	 *
	 * @param fun -- the function to be applied pointwise.
	 * @return the array with fun applied pointwise
	 */
	abstract /*value*/ public
	IntReferenceArray/*(distribution)*/ lift(Operator.Unary fun);

	/**
	 * Return an immutable copy of this array.
	 * Note: The implementation actually returns a copy at the
	 * representation of the X10 type x10.lang.intValueArray,
	 * which is intArray.
	 * @return an immutable version of this array.
	 */
	abstract public intArray toValueArray();

	/**
	 * Return the local chunk of this distributed array.  The result will have a
	 * 1-dimensional 0-based contiguous region.
	 * FIXME: this is just a stub for now.
	 * @return the local chunk of this array.
	 */
	public intArray local() {
		return this;
	}
}
