//OPTIONS: -STATIC_CHECKS=false -CONSTRAINT_INFERENCE=false -VERBOSE_INFERENCE=true



import harness.x10Test;

public class Test069_DynChecks_MustFailRun extends x10Test {

    public def run(): boolean {
	val b = new B(0);
	val a = new A(new B(0));
	Test069_DynChecks.f(a, b);
        return true;
    }

    public static def main(Rail[String]) {
    	new Test069_DynChecks_MustFailRun().execute();
    }

}