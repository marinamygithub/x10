/**
 *  RandomAccess benchmark
 *
 *  Based on HPCC 0.5beta 
 *
 *  @author kemal, vj approx 7/2004
 *  New version, 11/2004
 */
class C {

// self contained constants suitable for C routines

    private static final long POLY = 0x0000000000000007L;
    private static final long PERIOD= 1317624576693539401L;

private static long nextRandom(long temp) {
    return (temp << 1) ^ (temp < 0 ? POLY : 0);
}

private static boolean getBit(long n, int i) {
  return  ((n>>>i)&1)!=0;
}

/**
 * Utility routine to start random number generator at Nth step
 * (original "starts" routine from RandomAccess)
 * <code>
  Functional synopsis:
  long starts(long n) :=
  long n1=for(long t=n; t<0 return t; next t=t+PERIOD){} ;
  long n2=for(long t=n1; t>PERIOD return t; next t=t-PERIOD){};
  if (n2==0) return 0x1;
  long m2[]= new long[0..63](i) {i==0?1:(nextRandom**2)(m2[i-1]);}
  int lastSetBit= findFirstSatisfying(int j:62..0)(getBit(n2,j));
  mutable long ran=2;
  for(int i=lastSetBit..1) {
         long ranXor= Xor(int j:0..63 where getBit(ran,j))(m2[j]);
         ran= getBit(n2,i-1)?nextRandom(ranXor):ranXor;}
  return ran;
 * </code>
 */

public static long starts(long n) {
  int i, j;
  long[] m2= new long[64];
  long temp, ran;

  while (n < 0) n += PERIOD;
  while (n > PERIOD) n -= PERIOD;
  if (n == 0) return 1;

  temp = 1;
  for (i=0; i<64; i++) {
    m2[i] = temp;
    temp = nextRandom(temp);
    temp = nextRandom(temp);
  }

  for (i=62; i>=0; i--)
    if (getBit(n,i))
      break;

  ran = 2;
  while (i > 0) {
    temp = 0;
    for (j=0; j<64; j++)
      if (getBit(ran,j))
	temp ^= m2[j];
    ran = temp;
    i -= 1;
    if (getBit(n,i))
      ran = nextRandom(ran);
  }

  return ran;
 }
}
public class RandomAccess {
  // Set places.MAX_PLACES to 128 to match original
  // Set LOG2_TABLE_SIZE to 25 to match original

  const int  MAX_PLACES= place.MAX_PLACES;
  const int  LOG2_TABLE_SIZE=5;
  const int  LOG2_S_TABLE_SIZE=4;
  const int  TABLE_SIZE=(1<<LOG2_TABLE_SIZE);
  const int  S_TABLE_SIZE=(1<<LOG2_S_TABLE_SIZE);
  const int  N_UPDATES=(4*TABLE_SIZE);
  const int  N_UPDATES_PER_PLACE=(N_UPDATES/MAX_PLACES);
  const int  WORD_SIZE=64;
  const long POLY=7;
  const long S_TABLE_INIT=0x0123456789abcdefL;
  // expected result with LOG2_S_TABLE_SIZE=5,
  // LOG2_S_TABLE_SIZE = 4
  // MAX_PLACES=4
  const long EXPECTED_RESULT= 1973902911463121104L;

static value class ranNum extends x10.lang.Object {
   long val;
   /**
    * Constructor
    */
   public ranNum(long x) {val=x;}
   /** Get the value as a Table index.
    */
   int f() {return (int) (this.val & (TABLE_SIZE-1));} 
   /** Get the value as an index into the small Table.
    */
   int g() {return (int)(this.val>>>(WORD_SIZE-LOG2_S_TABLE_SIZE));}
   /*
    * return the value exclusive or'ed with k 
    */
   ranNum update(ranNum k) {
	return new ranNum(this.val^k.val);
	}

   /** Return the next number following this one.
    * Actually the next item in the sequence generated
    * by a primitive polynomial over GF(2).)
    */
   ranNum nextRandom() {return new ranNum((val<<1)^(val<0?POLY:0));}

}
   /**
    * find the sum of a ranNum array
    */
   long ranNumSum(final ranNum[.] A) {
	final int[.] P=new int[unique()];
        final long[.] S= new long[unique()];
	finish ateach(point [i]: P) {
	  long sum=0L;
	  for(point [j]: (A.distribution|(P.distribution[i]))) {
		sum+= A[j].val;
          }
	  S[i]=sum;
        }
        return S.sum();
   }
        


   /*
    * Utility routines to create simple common distributions
    */
   /**
    * create a simple 1D blocked distribution
    */
   distribution block (int arraySize) {
      return distribution.factory.block(0:(arraySize-1));
   }
    
   /**
    * create a unique distribution (mapping each i to place i)
    */
   distribution unique () {
       return distribution.factory.unique(place.places);
   }
  
   /**
    * main RandomAccess routine
    */
   public boolean run() {  	
    // A small value Table that will be copied to all processors
    final ranNum value[.] SmallTable = 
        new ranNum value[(0:S_TABLE_SIZE-1)->here]
          (point [i]) {return new ranNum(i*S_TABLE_INIT);};        
    // distributed histogram Table
    final ranNum[.] Table = new ranNum[block(TABLE_SIZE)]
         (point [i]){return new ranNum(i);};
    // random number starting seeds for each place (calls C code)
    final ranNum[.] RanStarts = new ranNum[unique()]
      (point [i]) {return new ranNum(C.starts(N_UPDATES_PER_PLACE*i));};
    // In all places in parallel,repeatedly generate random indices
    // and do remote atomic updates on corresponding Table elements
    finish ateach (point [i]: RanStarts) {
        ranNum ran = RanStarts[i].nextRandom();
        for(point [count]: 1:N_UPDATES_PER_PLACE) {
            System.out.println("Place "+i+" iteration "+count);
            final int  J = ran.f();
            final ranNum K = SmallTable[ran.g()]; 
            async(Table.distribution[J]) atomic Table[J]=Table[J].update(K);
            ran = ran.nextRandom();
        }
    }
    return ranNumSum(Table)==EXPECTED_RESULT;
    
  }

  
    public static void main(String[] args) {
        final boxedBoolean b=new boxedBoolean();
        try {
                finish b.val=(new RandomAccess()).run();
        } catch (Throwable e) {
                e.printStackTrace();
                b.val=false;
        }
        System.out.println("++++++ "+(b.val?"Test succeeded.":"Test failed."));
        x10.lang.Runtime.setExitCode(b.val?0:1);
    }
    static class boxedBoolean {
        boolean val=false;
    }

 }


