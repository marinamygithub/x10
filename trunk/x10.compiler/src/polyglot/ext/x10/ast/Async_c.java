/*
 * Created on Oct 5, 2004
 */
package polyglot.ext.x10.ast;

import java.util.List;

import polyglot.ast.Block;
import polyglot.ast.Expr;
import polyglot.ast.Node;
import polyglot.ast.Term;
import polyglot.ext.jl.ast.Stmt_c;
import polyglot.util.CodeWriter;
import polyglot.util.Position;
import polyglot.visit.CFGBuilder;

/**
 * @author Christian Grothoff
 */
public class Async_c extends Stmt_c 
    implements Async, NodeDumperHelper.Dumpable {

    public Block body;
    
    public Expr place; 
    
    public Async_c(Position p) {
        super(p);
    }
    
    /**
     * Return the first (sub)term performed when evaluating this
     * term.
     */
    public Term entry() {
        return place;
    }

    /**
     * Visit this term in evaluation order.
     */
    public List acceptCFG(CFGBuilder v, List succs) {
        v.visitCFG(place, body());
        v.visitCFG(body(), this);
        return succs;
    }
    
    /* (non-Javadoc)
     * @see polyglot.ext.x10.ast.TranslateWhenDumpedNode#getArgument(int)
     */
    public Node getArgument(int id) {
        if (id == 0)
            return place;
        if (id == 1)
            return body;
        assert (false);
        return null;
    }
    

    /* (non-Javadoc)
     * @see polyglot.ext.x10.ast.Future#body(polyglot.ast.Expr)
     */
    public RemoteActivityInvocation body(Block body) {
        this.body = body;
        return this;
    }

    /* (non-Javadoc)
     * @see polyglot.ext.x10.ast.Future#body()
     */
    public Block body() {
        return body;
    }

    /** Get the RemoteActivity's place. */
    public Expr place() {
        return place;
    }
    
    /** Set the RemoteActivity's place. */
    public RemoteActivityInvocation place(Expr place) {
        this.place = place;
        return this;
    }
    
    public void dump(CodeWriter w) {
        NodeDumperHelper.dump(this, w);
    }
        
}
