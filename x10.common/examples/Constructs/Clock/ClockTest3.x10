import x10.lang.*;

/**
 * Clock test for  barrier functions
 * @author kemal 3/2005
 */
public class ClockTest3 {

	int val=0;
	static final int N=32;

	public boolean run() {
      		final clock c = clock.factory.clock();
		
		foreach (point [i]: 0:(N-1)) clocked(c) {
			now(c) {async(here) {atomic val++;}}
			next;
			int temp;
			atomic {temp=val;}
			if (temp != N) {
				throw new Error();
			}
			next;
			now(c) {async(here) {atomic val++;}}
			next;
		}
		next; next; next;
		int temp2;
		atomic {temp2=val;}
		if (temp2!=2*N) {
			throw new Error();
		}
		return true;
	}

	public static void main(String args[]) {
		boolean b= (new ClockTest3()).run();
		System.out.println("++++++ "+(b?"Test succeeded.":"Test failed."));
		System.exit(b?0:1);
	}

}
