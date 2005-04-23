/**
 *@ author kemal 4/2005
 *
 * Array operations and points must be type checked.
 *
 * The expected result is that compilation must fail.
 *
 * As of 4/05, this is a limitation of the current release
 *
 */
public class ArrayTypeCheck_MustFailCompile {

	public boolean run() {
		int [.] a1=new int[[0:2,0:3]->here](point p[i]){ return i;};
		System.out.println("1");
		int [.] a2=(int[(-1:-2)->here])a1;
		System.out.println("2");
		int [.] a3=(int[distribution.factory.unique()])a2;
		System.out.println("3");
		int i=1;
		int j=2;
		int k=0;
		point p=[i,j,k];
		point q=[i,j];
		point r=[i];
		if (p==q) return false;
		System.out.println("4");
		if (a1[q]+a3[q]!=2) return false;
		System.out.println("5");
		return a1[i]==a1[i,j,k];
	}
	public static void main(String args[]) {
		boolean b= (new ArrayTypeCheck_MustFailCompile()).run();
		System.out.println("++++++ "+(b?"Test succeeded.":"Test failed."));
		System.exit(b?0:1);
	}
}
