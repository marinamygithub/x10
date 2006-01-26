/*
 * Created on Oct 7, 2004
 */
package polyglot.ext.x10.visit;

import java.io.DataInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;

import org.ovmj.util.Runabout;

import polyglot.ast.Expr;
import polyglot.ast.Formal;
import polyglot.ast.Node;
import polyglot.ast.Receiver;
import polyglot.ast.Special;
import polyglot.ast.TypeNode;
import polyglot.ext.jl.ast.Binary_c;
import polyglot.ext.jl.ast.Call_c;
import polyglot.ext.jl.ast.CanonicalTypeNode_c;
import polyglot.ext.jl.ast.Cast_c;
import polyglot.ext.jl.ast.Field_c;
import polyglot.ext.jl.ast.MethodDecl_c;
import polyglot.ext.x10.Configuration;
import polyglot.ext.x10.ast.ArrayConstructor_c;
import polyglot.ext.x10.ast.Async_c;
import polyglot.ext.x10.ast.AtEach_c;
import polyglot.ext.x10.ast.Atomic_c;
import polyglot.ext.x10.ast.Await_c;
import polyglot.ext.x10.ast.Finish_c;
import polyglot.ext.x10.ast.ForEach_c;
import polyglot.ext.x10.ast.ForLoop_c;
import polyglot.ext.x10.ast.Future_c;
import polyglot.ext.x10.ast.Here_c;
import polyglot.ext.x10.ast.Next_c;
import polyglot.ext.x10.ast.Now_c;
import polyglot.ext.x10.ast.PlaceCast_c;
import polyglot.ext.x10.ast.RemoteCall_c;
import polyglot.ext.x10.ast.When_c;
import polyglot.ext.x10.ast.X10ArrayAccess1Assign_c;
import polyglot.ext.x10.ast.X10ArrayAccess1_c;
import polyglot.ext.x10.ast.X10ArrayAccess_c;
import polyglot.ext.x10.ast.X10ClockedLoop;
import polyglot.ext.x10.ast.X10Loop;
import polyglot.ext.x10.types.NullableType;
import polyglot.ext.x10.types.X10ReferenceType;
import polyglot.ext.x10.types.X10Type;
import polyglot.types.ReferenceType;
import polyglot.types.Type;
import polyglot.util.CodeWriter;
import polyglot.visit.PrettyPrinter;

/**
 * Visitor on the AST nodes that for some X10 nodes triggers the template
 * based dumping mechanism (and for all others just defaults to the normal
 * pretty printing).
 *
 * @author Christian Grothoff
 * @author Igor Peshansky (template classes)
 */
public class X10PrettyPrinterVisitor extends Runabout {

	private final CodeWriter w;
	private final PrettyPrinter pp;

	private static int nextId_;
	/* to provide a unique name for local variabales introduce in the templates */
	private static Integer getUniqueId_() {
		return new Integer(nextId_++);
	}

	public static String getId() {
		return "__var" + getUniqueId_() + "__";
	}

	public X10PrettyPrinterVisitor(CodeWriter w, PrettyPrinter pp) {
		this.w = w;
		this.pp = pp;
	}

	public void visit(Node n) {
		if (n.comment() != null)
			w.write(n.comment());
		n.prettyPrint(w, pp);
	}

	public void visit(Cast_c c) {
		boolean exp_nullab = (c.expr().type() instanceof NullableType);
		boolean casttype_nullab = (c.castType().type() instanceof NullableType);
		if (exp_nullab && !casttype_nullab) {
			dump("cast_nullable", new Node[] {c.castType(), c.expr()});
		} else {
			visit((Node)c);
		}
	}

	public void visit(Call_c c) {
		boolean done = false;
		if (c instanceof RemoteCall_c) {
			// TODO assert false - that is not implemented yet
			throw new RuntimeException("not implemented");
		} else {
			// add a check that verifies if the target of the call is in place 'here'
			Receiver target = c.target();
			Type t = target.type();
			boolean base = false;

			// access to method x10.lang.Object.getLocation should not be checked
			boolean is_location_access;
			String f_name = c.methodInstance().name();
			ReferenceType f_container = c.methodInstance().container();
			is_location_access = f_name != null && "getLocation".equals(f_name) && f_container instanceof X10ReferenceType;

			if (! (target instanceof TypeNode) &&	// don't annotate access to static vars
				! (target instanceof Future_c) &&
				t instanceof X10ReferenceType &&	// don't annotate access to instances of ordinary Java objects.
				! c.isTargetImplicit() &&
				! (target instanceof Special) &&
				! is_location_access)
			{
				// don't annotate calls with implicit target, or this and super
				// the template file only emits the target
				dump("call_local", new Object[] { t.translate(null), target } );
				// then emit '.', name of the method and argument list.
				w.write(c.name() + "(");
				w.begin(0);
				List l = c.arguments();
				for(Iterator i = l.iterator(); i.hasNext();) {
					Expr e = (Expr) i.next();
					c.print(e, w, pp);
					if (i.hasNext()) {
						w.write(",");
						w.allowBreak(0, " ");
					}
				}
				w.end();
				w.write(")");
				done = true;
			}
		}
		if (!done)
			c.prettyPrint(w, pp);
	}

	public void visit(Binary_c binary) {
		if (binary.operator().equals(polyglot.ast.Binary.EQ) &&
			(binary.left().type() instanceof ReferenceType) &&
			(binary.right().type() instanceof ReferenceType)
			/*&&
			(binary.left().type() instanceof ValueType) &&
			(binary.right().type() instanceof ValueType) */)
		{
			dump("equalsequals", new Node[] { binary.left(), binary.right() });
		} else if (binary.operator().equals(polyglot.ast.Binary.NE) &&
				   (binary.left().type() instanceof ReferenceType) &&
				   (binary.right().type() instanceof ReferenceType)
				   /*&&
				   (binary.left().type() instanceof ValueType) &&
				   (binary.right().type() instanceof ValueType) */)
		{
			dump("notequalsequals", new Node[] { binary.left(), binary.right() });
		} else {
			visit((Node)binary);
		}
	}

	public void visit(MethodDecl_c dec) {
		if (dec.comment() != null)
			w.write(dec.comment());
		if (dec.name().equals("main") &&
			dec.flags().isPublic() &&
			dec.flags().isStatic() &&
			dec.returnType().type().isVoid() &&
			(dec.formals().size() == 1) &&
			((Formal)dec.formals().get(0)).type().toString().equals("java.lang.String[]"))
		{
			dump("Main", new Node[] { (Node) dec.formals().get(0), dec.body() });
		} else
			dec.prettyPrint(w, pp);
	}

	public void visit(Async_c a) {
		assert (null != a.clocks());
		dump("Async",
			 new Object[] {
				 a.place(),
				 new Loop("clocked-loop", a.clocks()),
				 a.body()
			 });
	}

	public void visit(Atomic_c a) {
		dump("Atomic", new Object[] { a.body(), getUniqueId_() });
	}

	public void visit(Here_c a) {
		dump("here", new Node[] {});
	}

	public void visit(Await_c c) {
		dump("await", new Node[] { c.expr() });
	}

	public void visit(Next_c d) {
		dump("next", new Object[] { getUniqueId_() });
	}

	public void visit(Future_c f) {
		dump("Future", new Node[] {f.place(), f.body()});
	}

	public void visit(ForLoop_c f) {
		// System.out.println("X10PrettyPrinter.visit(ForLoop c): |" + f.formal().flags().translate() + "|");
		dump("forloop",
			 new Object[] {
				 f.formal().flags().translate(),
				 f.formal().type(),
				 f.formal().name(),
				 f.domain(),
				 f.body()
			 });
	}

	private void processClockedLoop(String template, X10ClockedLoop l) {
		assert (null != l.clocks());
		dump(template,
			 new Object[] {
				 l.formal().flags().translate(),
				 l.formal().type(),
				 l.formal().name(),
				 l.domain(),
				 l.body(),
				 new Join("\n",
					 new Join("\n", l.locals()),
					 new Loop("clocked-loop", l.clocks()))
			 });
	}

	public void visit(ForEach_c f) {
		// System.out.println("X10PrettyPrinter.visit(ForEach c): |" + f.formal().flags().translate() + "|");
		processClockedLoop("foreach", f);
	}

	public void visit(AtEach_c f) {
		processClockedLoop("ateach", f);
	}

	public void visit(Now_c n) {
		dump("Now", new Node[] { n.clock(), n.body()});
	}

	/*
	 * Field access -- this includes FieldAssign (because the left node of
	 * FieldAssign is a Field node!
	 */
	public void visit(Field_c n) {
		boolean done = false;
		Receiver target = n.target();
		Type t = target.type();

		// access to field x10.lang.Object.location should not be checked
		boolean is_location_access;
		String f_name = n.fieldInstance().name();
		ReferenceType f_container = n.fieldInstance().container();
		is_location_access = f_name != null && "location".equals(f_name) && f_container instanceof X10ReferenceType;

		if (! (target instanceof TypeNode) &&	// don't annotate access to static vars
			t instanceof X10ReferenceType &&	// don't annotate access to instances of ordinary Java objects.
			! n.isTargetImplicit() &&
			! (target instanceof Special) &&
			! is_location_access)
		{
			// no check required for implicit targets, this and super
			dump("field", new Object[] { t.translate(null), target, n.name() } );
			done = true;
		}
		if (!done)
			n.prettyPrint(w, pp);
	}

	public void visit(When_c w) {
		dump("when",
			 new Object[] { w.expr(),
				 w.stmt(),
				 new Loop("when-loop", w.branches()),
				 getUniqueId_()
			 });
	}

	public void visit(When_c.Branch_c b) {
		dump("when-branch", new Node[] { b.expr(), b.stmt() });
	}

	public void visit(Finish_c a) {
		dump("finish", new Object[] { a.body(), getUniqueId_() });
	}

	private void processArrayConstructor(String template, ArrayConstructor_c a) {
		if (a.hasLocal1DimDistribution()) {
			if (a.hasInitializer()) {
				dump(template+"_array_initializer",
					 new Object[] {
						 a.initializer(),
						 new Boolean(a.isSafe()),
						 new Boolean(a.isValue())
					 });
				return;
			}
			dump(template+"_array_local",
				 new Object[] {
					 a.distribution(),
					 new Boolean(a.isSafe()),
					 new Boolean(a.isValue())
				 });
			return;
		}
		Object init = a.initializer();
		dump(template+"_array_dist_op",
			 new Object[] {
				 a.distribution(),
				 init != null ? init : "null",
				 new Boolean(a.isSafe()),
				 new Boolean(a.isValue())
			 });
		return;
	}

	public void visit(ArrayConstructor_c a) {
		Type base_type = a.arrayBaseType().type();

		if (base_type.isBoolean()) { // this is a boolean[?] ? array
			processArrayConstructor("boolean", a);
			return;
		}
		if (base_type.isChar()) { // this is a char[?] ? array
			processArrayConstructor("char", a);
			return;
		}
		if (base_type.isByte()) { // this is a byte[?] ? array
			processArrayConstructor("byte", a);
			return;
		}
		if (base_type.isShort()) { // this is a short[?] ? array
			processArrayConstructor("short", a);
			return;
		}
		if (base_type.isInt()) { // this is an int[?] ? array
			processArrayConstructor("int", a);
			return;
		}
		if (base_type.isFloat()) { // this is a float[?] ? array
			processArrayConstructor("float", a);
			return;
		}
		if (base_type.isDouble()) { // this is a double[?] ? array
			processArrayConstructor("double", a);
			return;
		}
		if (base_type.isLong()) { // this is a long[?] ? array
			processArrayConstructor("long", a);
			return;
		}
		if (! base_type.isPrimitive()) { // this is a User-defined[?] ? array
			boolean refs_to_values = (base_type instanceof X10Type && ((X10Type) base_type).isValueType());
			if (a.hasLocal1DimDistribution()) {
				if (a.hasInitializer()) {
					dump("generic_array_initializer",
						 new Object[] {
							 a.initializer(),
							 new Boolean(a.isSafe()),
							 new Boolean(a.isValue()),
							 new Boolean(refs_to_values)
						 });
					return;
				}
				dump("generic_array_local",
					 new Object[] {
						 a.distribution(),
						 new Boolean(a.isSafe()),
						 new Boolean(a.isValue()),
						 new Boolean(refs_to_values)
					 });
				return;
			}
			Object init = a.initializer();
			dump("generic_array_dist_op",
				 new Object[] {
					 a.distribution(),
					 init != null ? init : "(x10.compilergenerated.Parameter1)null",
					 new Boolean(a.isSafe()),
					 new Boolean(a.isValue()),
					 new Boolean(refs_to_values)
				 });
			return;
		}

		throw new Error("Unknown array type.");
	}

	public void visit(X10ArrayAccess1_c a) {
		dump("array_get1", new Node[] { a.array(), a.index() });
	}

	public void visit(PlaceCast_c a) {
		System.out.println("Visit:" + a + "," + a.expr() + "," + a.placeCastType() );
		dump("cast_place",
			 new Node[] {
				 a.expr(),
				 a.placeCastType(),
				 new CanonicalTypeNode_c(a.position(), a.expr().type())
			 });
	}

	// [IP] TODO: rewrite using a loop
	public void visit(X10ArrayAccess_c a) {
		List index = a.index();
		int size = index.size();
		assert size > 1;
		if (size == 2)
			dump("array_get2",
				 new Node[] {
					 a.array(),
					 (Node) index.get(0),
					 (Node) index.get(1)
				 });
		else if (size == 3)
			dump("array_get3",
				 new Node[] {
					 a.array(),
					 (Node) index.get(0),
					 (Node) index.get(1),
					 (Node) index.get(2)
				 });
		else if (size == 4)
			dump("array_get4",
				 new Node[] {
					 a.array(),
					 (Node) index.get(0),
					 (Node) index.get(1),
					 (Node) index.get(2),
					 (Node) index.get(3)
				 });
		else
			throw new Error("TODO: vj->cvp/cg ... Please implement general case.");
	}

	public void visit(X10ArrayAccess1Assign_c a) {
		// Remember the index is a point or an int.
		X10ArrayAccess1_c left = (X10ArrayAccess1_c) a.left();
		dump("array_set1",
			 new Node[] {
				 left.array(),
				 a.right(),
				 left.index()
			 });
	}

	/*
	public void visit(X10ArrayAccessAssign_c a) {
		X10ArrayAccess_c left = (X10ArrayAccess_c) a.left();
		List index = left.index();
		int size = index.size();
		assert size > 1;
		if (size == 2)
			dump("array_set2",
				 new Node[] {
					 left.array(), a.right(),
					 (Node) index.get(0),
					 (Node) index.get(1)
				 });
		else if (size == 3)
			dump("array_set3",
				 new Node[] {
					 left.array(),
					 a.right(),
					 (Node) index.get(0),
					 (Node) index.get(1),
					 (Node) index.get(2)
				 });
		else if (size == 4)
			dump("array_set4",
				 new Node[] {
					 left.array(),
					 a.right(),
					 (Node) index.get(0),
					 (Node) index.get(1),
					 (Node) index.get(2),
					 (Node) index.get(3)
				 });
		else
			throw new Error("TODO: vj->cvp/cg ... Please implement general case.");
	}
	*/

	/**
	 * Pretty-print a given object.
	 *
	 * @param o object to print
	 */
	private void prettyPrint(Object o) {
		if (o instanceof Expander) {
			((Expander) o).expand();
		} else if (o instanceof Node) {
			((Node) o).del().prettyPrint(w, pp);
		} else {
			w.write(o.toString());
		}
	}

	/**
	 * Expand a given template with given parameters.
	 *
	 * @param id xcd filename for the template
	 * @param components arguments to the template.
	 */
	private void dump(String id, Object[] components) {
		String regex = translate(id);
		int len = regex.length();
		int pos = 0;
		int start = 0;
		while (pos < len) {
			if (regex.charAt(pos) == '#') {
				w.write(regex.substring(start, pos));
				Integer idx = new Integer(regex.substring(pos+1,pos+2));
				pos++;
				start = pos+1;
				prettyPrint(components[idx.intValue()]);
			}
			pos++;
		}
		w.write(regex.substring(start));
	}

	/**
	 * An abstract class for sub-template expansion.
	 */
	public abstract class Expander { public abstract void expand(); }

	/**
	 * Expand a given template in a loop with the given set of arguments.
	 * For the loop body, pass in an array of Lists of identical length
	 * (each list representing all instances of a given argument),
	 * which will be translated into array-length repetitions of the
	 * loop body template.
	 * If the template has only one argument, a single list can be used.
	 */
	public class Loop extends Expander {
		private final String id;
		//private final String template;
		private final List[] lists;
		private final int N;
		public Loop(String id, List components) {
			this(id, new List[] { components });
		}
		public Loop(String id, List[] components) {
			this.id = id;
			//this.template = translate(id);
			this.lists = components;
			// Make sure we have the parameters
			assert(lists.length > 0);
			this.N = lists[0].size();
			// Make sure the lists are all of the same size
			for (int i = 1; i < lists.length; i++)
				assert(lists[i].size() == N);
		}
		public void expand() {
			Object[] args = new Object[lists.length];
			Iterator[] iters = new Iterator[lists.length];
			// Parallel iterators over all argument lists
			for (int j = 0; j < lists.length; j++)
				iters[j] = lists[j].iterator();
			for (int i = 0; i < N; i++) {
				for (int j = 0; j < args.length; j++)
					args[j] = iters[j].next();
				dump(id, args);
			}
		}
	}

	private static List asList(Object a, Object b) {
		List l = new ArrayList(2); l.add(a); l.add(b); return l;
	}
	private static List asList(Object a, Object b, Object c) {
		List l = new ArrayList(3); l.add(a); l.add(b); l.add(c); return l;
	}

	/**
	 * Join a given list of arguments with a given delimiter.
	 * Two or three arguments can also be specified separately.
	 */
	public class Join extends Expander {
		private final String delimiter;
		private final List args;
		public Join(String delimiter, Object a, Object b) {
			this(delimiter, asList(a, b));
		}
		public Join(String delimiter, Object a, Object b, Object c) {
			this(delimiter, asList(a, b, c));
		}
		public Join(String delimiter, List args) {
			this.delimiter = delimiter;
			this.args = args;
		}
		public void expand() {
			int N = args.size();
			for (Iterator i = args.iterator(); i.hasNext(); ) {
				prettyPrint(i.next());
				if (i.hasNext())
					prettyPrint(delimiter);
			}
		}
	}

	static HashMap translationCache_ = new HashMap();

	static String translate(String id) {
		String cached = (String) translationCache_.get(id);
		if (cached != null)
			return cached;
		try {
			String fname = Configuration.COMPILER_FRAGMENT_DATA_DIRECTORY + id + ".xcd"; // xcd = x10 compiler data/definition
			fname = fname.replace('\\','/'); // win32 hack
			// Override definition with any identically named file in DATA_EXT dir
			if (null != Configuration.COMPILER_FRAGMENT_DATA_EXT_DIRECTORY) {
				String extfname = Configuration.COMPILER_FRAGMENT_DATA_EXT_DIRECTORY + id + ".xcd";
				extfname = extfname.replace('\\','/'); // win32 hack
				File testFile = new File(extfname);
				if (testFile.exists() && testFile.canRead()) {
					fname = extfname;
				}
			}

			FileInputStream fis = new FileInputStream(fname);
			DataInputStream dis = new DataInputStream(fis);
			byte[] b = new byte[dis.available()];
			dis.read(b);
			String trans = new String(b, "UTF-8");
			trans = "/* template:"+id+" { */ " + trans + " /* } */";
			translationCache_.put(id, trans);
			return trans;
		} catch (IOException io) {
			throw new Error("No translation for " + id + " found!");
		}
	}
} // end of X10PrettyPrinterVisitor

