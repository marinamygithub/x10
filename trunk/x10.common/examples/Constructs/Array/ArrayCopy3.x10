/**
 * Test for arrays, regions and distributions.
 * Based on original arraycopy3 by vj.
 *
 * @author kemal 1/2005
 */

public class ArrayCopy3 {
	
        /**
         * Throws an error iff b is false.
         */
	static void chk(boolean b) {
		if(!b) throw new Error();
	}
	
	/**
	 * Returns true iff point x is not in the domain of
	 * distribution D
	 */
	static boolean outOfRange(final distribution D, final point x) {
		boolean gotException=false;
		try{
			async(D[x]){}; // dummy op just to use D[x]
		} catch (Throwable e) {
			gotException=true;
		}
		return gotException;
	}
	
	/**
	 * Returns true iff A[i]==B[i] for all points i 
	 */
	
	public void arrayEqual(final int[.] A, final int[.] B) {
		final distribution D=A.distribution;
		final distribution E=B.distribution;
		// Spawn an activity for each index to 
		// fetch the B[i] value 
		// Then compare it to the A[i] value
		finish
		ateach(point i:D) chk(A[i]==future(E[i]){B[i]}.force());
	}
	
	/**
	 * Set A[i]=B[i] for all points i.
	 * Return false iff some assertion failed.
	 */
	
	public void arrayCopy(final int[.] A, final int[.] B) {
		final distribution D=A.distribution;
		final distribution E=B.distribution;
		// Allows message aggregation
		

		final distribution D_1=distribution.factory.unique(D.places()); 
		// number of times elems of a are accessed
		final int[.] accessed_a = new int[D];
		// number of times elems of b are accessed
		final int[.] accessed_b = new int[E];
		
		finish
		ateach (point x:D_1) {
			final place px=D_1[x];
			
			chk(here==px);
			final region LocalD = (D|px).region;

			for ( place py : (E|LocalD).places() ) {
				final region RemoteE = (E|py).region;
				final region Common = LocalD&&RemoteE;
				final distribution D_common= D|Common;
				// the future's can be aggregated
				for(point i:D_common) {
					async(py) atomic accessed_b[i]+=1;
					final int temp=
						future(py){B[i]}.force();
					// the following may need to be bracketed in
					// atomic, unless the disambiguator
					// knows about distributions
					A[i]=temp;
					atomic accessed_a[i]+=1;
				}
				// check if distribution ops are working
				final distribution D_notCommon= D-D_common;
				chk((D_common||D_notCommon).equals(D));
				final distribution E_common= E|Common;
				final distribution E_notCommon= E-E_common;
					
				chk((E_common||E_notCommon).equals(E));
				for(point k:D_common) {
					chk(D_common[k]==px);
					chk(outOfRange(D_notCommon,k));
					chk(E_common[k]==py);
					chk(outOfRange(E_notCommon,k));
					chk(D[k]==px && E[k]==py);
				}

				for (point k: D_notCommon) { 
					chk(outOfRange(D_common,k));
					chk(!outOfRange(D_notCommon,k));
					chk(outOfRange(E_common,k));
					chk(!outOfRange(E_notCommon,k));
					chk(!(D[k]==px && E[k]==py));
				}
				
			}
		}
		// ensure each A[i] was accessed exactly once
		finish ateach(point i:D) chk(accessed_a[i]==1);
		// ensure each B[i] was accessed exactly once
		finish ateach(point i:E) chk(accessed_b[i]==1);
	}

    const int N=3;

    /**
     * For all combinations of distributions of arrays B and A,
     * do an array copy from B to A, and verify.
     */
    public boolean run() {
         final region R= [0:N-1,0:N-1,0:N-1,0:N-1];
         final region TestDists= [0:dist.N_DIST_TYPES-1,0:dist.N_DIST_TYPES-1];
         for(point distP[dX,dY]: TestDists) {
		
             final distribution D=dist.getDist(dX,R);
             final distribution E=dist.getDist(dY,R);
             chk(D.region.equals(E.region)&&D.region.equals(R)); 
             final int[.] A= new int[D];
             final int[.] B= new int[E]
	      (point p[i,j,k,l]){int x=((i*N+j)*N+k)*N+l; return x*x+1;};
             arrayCopy(A,B);
             arrayEqual(A,B);
         }
         return true;
    }

	/**
	 * main method
	 */
	public static void main(String args[]) {
		boolean b=false;
		try {
			b= (new ArrayCopy3()).run();
		} catch(Throwable e) {
			e.printStackTrace();
			b=false;
		}
		System.out.println("++++++ "+(b?"Test succeeded.":"Test failed."));
		System.exit(b?0:1);
	}
}

/**
 * utility for creating a distribution from a
 * a distribution type int value and a region
 */
class dist {
   const int BLOCK=0;
   const int CYCLIC=1;
   const int BLOCKCYCLIC=2;
   const int CONSTANT=3;
   const int RANDOM=4;
   const int ARBITRARY=5;
   public const int N_DIST_TYPES=6;

   /**
    * Return a distribution with region r, of type disttype
    *
    */

   public static distribution getDist(int distType, region r) {
      switch(distType) {
         case BLOCK: return distribution.factory.block(r);
         case CYCLIC: return distribution.factory.cyclic(r);
         case BLOCKCYCLIC: return distribution.factory.blockCyclic(r,3);
         case CONSTANT: return distribution.factory.constant(r, here);
         case RANDOM: return distribution.factory.random(r);
         case ARBITRARY: return distribution.factory.arbitrary(r);
         default: throw new Error();
      }
     
   } 
}
