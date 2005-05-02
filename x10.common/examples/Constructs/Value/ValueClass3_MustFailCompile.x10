/**
 * Value class test:
 *
 * Testing that an assignment to a value array element
 * causes a compiler error
 *
 * @author kemal 4/2005
 *
 */
final value  class myval {
    int intval;
    complex cval;
    foo refval;
    int value[.] arrayval;
    myval(int intval,complex cval,foo refval, int value[.] arrayval) {
        this.intval=intval;
        this.cval=cval;
        this.refval=refval;
        this.arrayval= arrayval;
    }
}

class foo {
    int w=19;
}

final value  complex extends x10.lang.Object {
    int re;
    int im;
    complex(int re, int im) {
        this.re=re;
        this.im=im;
    }
    complex add (complex other) {
        return new complex(this.re+other.re,this.im+other.im);
    }
}

public class ValueClass3_MustFailCompile  {


        public boolean run() {

        distribution d=[0:9]->here;
        final foo f= new foo();
        myval x= new myval(1,new complex(2,3),f, new int value[d]);
        myval y= new myval(1,new complex(2,3),f, new int value[d]);
//====> compiler error should occur here
        x.arrayval[0]=1; // java will not object
                         // x10 compiler should flag this
	
        if (x.arrayval[0]!=y.arrayval[0]+1) return false;
	int value[d] z= new int value[d];
//====> compiler error should occur here
	z[0] = x.arrayval[0];
	return (z[0]==1);

        }

	
    public static void main(String[] args) {
        final boxedBoolean b=new boxedBoolean();
        try {
                finish b.val=(new ValueClass3_MustFailCompile()).run();
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
