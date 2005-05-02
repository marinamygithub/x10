/**
 * Simple array test #3
 */
import x10.lang.*;
public class Array3Boolean {

	public boolean run() {
		
		region e= region.factory.region(1,10); //(low,high)
		region r = region.factory.region(e, e); 
		distribution d=distribution.factory.local(r);
		boolean[.] ia = new boolean[d];
		ia[1,1] = true;
		return (true == ia[1,1]);
	
	}
	
    public static void main(String[] args) {
        final boxedBoolean b=new boxedBoolean();
        try {
                finish b.val=(new Array3Boolean()).run();
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
