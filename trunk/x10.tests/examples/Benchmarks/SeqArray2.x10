// (C) Copyright IBM Corporation 2006
// This file is part of X10 Test.

/**
 * Basic array
 *
 * @author bdlucas
 */

public class SeqArray2 extends Benchmark {

    //
    // parameters
    //

    val N = 2000;
    def expected() = 1.0*N*N*(N-1);
    def operations() = 2.0*N*N;

    //
    // the benchmark
    //

    val a = Array.make[double]([0..N-1, 0..N-1]);

    def once() {
        for (var i:int=0; i<N; i++)
            for (var j:int=0; j<N; j++)
                a(i,j) = i+j;
        var sum:double = 0.0;
        for (var i:int=0; i<N; i++)
            for (var j:int=0; j<N; j++)
                sum += a(i,j);
        return sum;
    }

    //
    // boilerplate
    //

    public static def main(Rail[String]) {
        new SeqArray2().execute();
    }
}
