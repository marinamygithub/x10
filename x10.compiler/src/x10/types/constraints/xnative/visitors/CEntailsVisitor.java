package x10.types.constraints.xnative.visitors;

import polyglot.types.Type;
import x10.constraint.XFailure;
import x10.constraint.XTerm;
import x10.constraint.XTypeSystem;
import x10.constraint.XVar;
import x10.constraint.xnative.XNativeConstraintSystem;
import x10.constraint.xnative.visitors.XGraphVisitor;
import x10.types.constraints.CConstraint;
import x10.types.constraints.ConstraintMaker;

public class CEntailsVisitor extends XGraphVisitor<Type> {
    CConstraint c1;
    ConstraintMaker c2m;
    XVar<Type> otherSelf;
    boolean result=true;
    public CEntailsVisitor(XNativeConstraintSystem<Type> sys, XTypeSystem<Type> ts, boolean hideEQV, boolean hideFake, CConstraint c1, ConstraintMaker c2m,
    		XVar<Type> otherSelf) {
    	super(sys, ts, hideEQV, hideFake);
        this.c1=c1;
        this.c2m = c2m;
        this.otherSelf=otherSelf;
    }
    public boolean visitAtomicFormula(XTerm<Type> t) {
        try {
            t = t.subst(sys, c1.self(), otherSelf);
            boolean myResult = c1.entails(t);
            if (! myResult && c2m!=null) {
                c1 = c1.copy();
                c1.addIn(c2m.make());
                c2m=null;
                if (! c1.consistent())
                    return false;
                
                myResult = c1.entails(t);
            }
            result &=myResult;   
                
        } catch (XFailure z) {
            return false;
        }
        return result;
    }
    public boolean visitEquals(XTerm<Type> t1, XTerm<Type> t2) {
        t1 = t1.subst(sys, c1.self(), otherSelf);
        t2 = t2.subst(sys, c1.self(), otherSelf);
        boolean myResult = c1.entailsEquality(t1, t2);
        if (! myResult && c2m!=null) {
            try {
                c1 = c1.copy();
                c1.addIn(c2m.make());
                c2m=null;
                if (! c1.consistent())
                    return false;
                myResult = c1.entailsEquality(t1, t2);
            } catch (XFailure z) {
                myResult=false;
            }
        }
        result &=myResult;   
        return result;
    }
    public boolean visitDisEquals(XTerm<Type> t1, XTerm<Type> t2) {
        t1 = t1.subst(sys, c1.self(), otherSelf);
        t2 = t2.subst(sys, c1.self(), otherSelf);
        boolean myResult = c1.entailsDisEquality(t1, t2);
        if (! myResult && c2m!=null) {
            try {
                c1 = c1.copy();
                c1.addIn(c2m.make());
                c2m=null;
                if (! c1.consistent())
                    return false;
                myResult = c1.entailsDisEquality(t1, t2);
            } catch (XFailure z) {
                myResult=false;
            }
        }
        result &=myResult;   
        return result;
    }
    public boolean result() {
        return result;
    }
}