package x10.emitter;

import polyglot.ext.x10.visit.X10PrettyPrinterVisitor;
import polyglot.util.InternalCompilerError;
import polyglot.visit.Translator;

/**
 * An abstract class for sub-template expansion.
 */
public abstract class Expander {
	/**
	 * 
	 */
	public final Emitter er;

	/**
	 * @param prettyPrinterVisitor
	 */
	public Expander(Emitter er) {
		this.er = er;
	}

	public void expand() {
		expand(er.tr);
	}

	public abstract void expand(Translator tr);

}