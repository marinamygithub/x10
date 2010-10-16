/*
 *  This file is part of the X10 project (http://x10-lang.org).
 *
 *  This file is licensed to You under the Eclipse Public License (EPL);
 *  You may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *      http://www.opensource.org/licenses/eclipse-1.0.php
 *
 *  (C) Copyright IBM Corporation 2006-2010.
 */

package x10.types;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import polyglot.util.InternalCompilerError;
import polyglot.util.Position;
import polyglot.util.Transformation;
import polyglot.util.TransformingList;
import polyglot.util.TypedList;
import x10.constraint.XConstraint;
import x10.constraint.XNameWrapper;
import x10.constraint.XTerms;
import x10.constraint.XVar;

public abstract class ParametrizedType_c extends ReferenceType_c implements ParametrizedType {
	private static final long serialVersionUID = 7637749680707950061L;

	StructType container;
	Flags flags;
	Name name;

	public ParametrizedType_c(TypeSystem ts, Position pos) {
		super(ts, pos);
	}
	
	public ParametrizedType container(StructType container) {
		ParametrizedType_c t = (ParametrizedType_c) copy();
		t.container = container;
		return t;
	}

	public StructType container() {
		if (this.container == null) {
			this.container = Types.get(def().container());
		}
		return this.container;
	}
	
	public Flags flags() {
		if (this.flags == null) { 
			this.flags = def().flags();
		}
		return this.flags;
	}

	public ParametrizedType flags(Flags flags) {
		ParametrizedType_c t = (ParametrizedType_c) copy();
		t.flags = flags;
		return t;
	}
	
	public ParametrizedType name(Name name) {
		ParametrizedType_c t = (ParametrizedType_c) copy();
		t.name = name;
		return t;
	}

	public boolean isSafe() {
		return true;
	}

	@Override
	public abstract String translate(Resolver c);

	public abstract MemberDef def();
	
	public QName fullName() {
		if (container() instanceof Named) {
			return QName.make(((Named) container()).fullName(), name());
		}
		return QName.make(null, name());
	}
	
	@Override
	public boolean equalsImpl(TypeObject t) {
		if (t instanceof ParametrizedType) {
			ParametrizedType pt = (ParametrizedType) t;
			if (pt.def() != def()) return false;
			if (! pt.typeParameters().equals(typeParameters())) return false;
			if (! pt.formals().equals(formals())) return false;
			if (! pt.formalTypes().equals(formalTypes())) return false;
			return true;
		}
		return false;
	}

}
