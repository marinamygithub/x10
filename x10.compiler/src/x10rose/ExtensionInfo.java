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

package x10rose;


import java.io.File;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;

import polyglot.ast.ClassMember;
import polyglot.ast.Node;
import polyglot.ast.NodeFactory;
import polyglot.ast.SourceFile;
import polyglot.ast.TopLevelDecl;
import polyglot.ast.TypeNode;
import polyglot.frontend.AllBarrierGoal;
import polyglot.frontend.Compiler;
import polyglot.frontend.CyclicDependencyException;
import polyglot.frontend.ForgivingVisitorGoal;
import polyglot.frontend.Goal;
import polyglot.frontend.JLScheduler;
import polyglot.frontend.Job;
import polyglot.frontend.JobExt;
import polyglot.frontend.OutputGoal;
import polyglot.frontend.ParserGoal;
import polyglot.frontend.Scheduler;
import polyglot.frontend.Source;
import polyglot.frontend.SourceGoal;
import polyglot.frontend.SourceGoal_c;
import polyglot.frontend.TargetFactory;
import polyglot.frontend.VisitorGoal;
import polyglot.main.Options;
import polyglot.types.Flags;
import polyglot.types.SemanticException;
import polyglot.types.TypeSystem;
import polyglot.util.ErrorInfo;
import polyglot.util.ErrorQueue;
import polyglot.util.Position;
import polyglot.visit.ConformanceChecker;
import polyglot.visit.ConstructorCallChecker;
import polyglot.visit.ExceptionChecker;
import polyglot.visit.ExitChecker;
import polyglot.visit.FwdReferenceChecker;
import polyglot.visit.InitChecker;
import polyglot.visit.PostCompiled;
import polyglot.visit.PruningVisitor;
import polyglot.visit.ReachChecker;
import polyglot.visit.Translator;
import x10.Version;
import x10.X10CompilerOptions;
import x10.ast.X10ClassDecl;
import x10.extension.X10Ext;
import x10.visit.AnnotationChecker;
import x10.visit.CheckEscapingThis;
import x10.visit.ErrChecker;
import x10.visit.IfdefVisitor;
import x10.visit.X10MLVerifier;
import x10.visit.X10TypeBuilder;
import x10.visit.X10TypeChecker;
import x10cpp.X10CPPCompilerOptions;
import x10cpp.visit.X10CPPTranslator;
import x10rose.visit.DotTranslator;

/**
 * Extension information for x10 extension.
 */
public class ExtensionInfo extends x10.ExtensionInfo {

	/*** Construct an ExtensionInfo */

	public polyglot.main.Version version() {
		return new Version() {
			public String name() { return "x10rose"; }
		};
	}
	public String[] fileExtensions() {
		return new String[] { "x10" };
	}

	public String compilerName() {
		return "x10rose";
	}


	// ==================================================
	// Scheduling of compiler passes for the Rose backend
	// ==================================================
	protected Scheduler createScheduler() {
		return new X10Scheduler(this);
	}

	public static class X10Scheduler extends JLScheduler {

		public X10Scheduler(ExtensionInfo extInfo) {
			super(extInfo);
		}

		public ExtensionInfo extensionInfo() {
			return (ExtensionInfo) this.extInfo;
		}

		public List<Goal> goals(Job job) {
			List<Goal> goals = new ArrayList<Goal>();

			// PARSE
			goals.add(Parsed(job));

			// TYPE CHECK
			X10CompilerOptions opts = extensionInfo().getOptions();
			if (opts.x10_config.CHECK_ERR_MARKERS) goals.add(ErrChecker(job)); // must be the first phase after parsing because later phases might fail and stop type checking (it shouldn't happen, but it does)
			goals.add(ImportTableInitialized(job));
			goals.add(TypesInitialized(job));

			goals.add(PropagateAnnotations(job));

			goals.add(PreTypeCheck(job));
			goals.add(Ifdef(job));
			goals.add(TypesInitializedForCommandLineBarrier());

			goals.add(TypeChecked(job));
			goals.add(ReassembleAST(job));


			// 'SEMANTIC' CHECKS
			// check that types are consistent (e.g. constraints are not inconsistent)
			goals.add(ConformanceChecked(job));

			// Data-flow analyses
			goals.add(ReachabilityChecked(job)); // This must be the first dataflow analysis (see DataFlow.reportCFG_Errors)
			goals.add(ExceptionsChecked(job));
			goals.add(ExitPathsChecked(job));
			goals.add(InitializationsChecked(job));
			goals.add(ConstructorCallsChecked(job));
			goals.add(CheckEscapingThis(job));
			goals.add(AnnotationChecker(job));
			goals.add(CheckASTForErrors(job));


			goals.add(CodeGenerated(job));

			goals.add(End(job));

			return goals;
		}

		protected Goal PostCompiled() {
			return new PostCompiled(extInfo) {
				private static final long serialVersionUID = 1834245937046911633L;

				protected boolean invokePostCompiler(Options options, Compiler compiler, ErrorQueue eq) {
					if (System.getProperty("x10.postcompile", "TRUE").equals("FALSE"))
						return true;
					for (String key : compiler.outputFiles().keySet()) {
						for (String outfile : compiler.outputFiles().get(key)) {
							String[] cmdline = {"dot", "-Tpng", "-O", outfile};
					        try {
					            Runtime runtime = Runtime.getRuntime();
					        	Process proc = runtime.exec(cmdline, null, options.output_directory);

					        	InputStreamReader err = new InputStreamReader(proc.getErrorStream());

					        	String output = null;
					        	try {
					        		char[] c = new char[72];
					        		int len;
					        		StringBuffer sb = new StringBuffer();
					        		while((len = err.read(c)) > 0) {
					        			sb.append(String.valueOf(c, 0, len));
					        		}

					        		if (sb.length() != 0) {
					        			output = sb.toString();
					        		}
					        	}
					        	finally {
					        		err.close();
					        	}

					        	proc.waitFor();

					        	if (!options.keep_output_files) {
					        		String[] rmCmd = new String[] {"rm", outfile};
					        		runtime.exec(rmCmd, null, options.output_directory);
					        	}

					        	if (output != null)
					        		eq.enqueue(proc.exitValue()>0 ? ErrorInfo.POST_COMPILER_ERROR : ErrorInfo.WARNING, output);
					        	if (proc.exitValue() > 0) {
					        		eq.enqueue(ErrorInfo.POST_COMPILER_ERROR, "Non-zero return code: " + proc.exitValue());
					        		return false;
					        	}
					        } catch(Exception e) {
					        	eq.enqueue(ErrorInfo.POST_COMPILER_ERROR, e.getMessage() != null ? e.getMessage() : e.toString());
					        	return false;
					        }						
						}
					}
					return true;
				}
			}.intern(this);
		}		

		protected Goal EndAll() {
			return PostCompiled();
		}

		public Goal CheckASTForErrors(Job job) {
			return new SourceGoal_c("CheckASTForErrors", job) {
				private static final long serialVersionUID = 565345690079406384L;
				public boolean runTask() {
					if (job.reportedErrors()) {
						Node ast = job.ast();
						job.ast(((X10Ext)ast.ext()).setSubtreeValid(false));
					}
					return true;
				}
			}.intern(this);
		}

		public Goal PropagateAnnotations(Job job) {
			// ###
			return new VisitorGoal("PropagateAnnotations", job, new PruningVisitor()).intern(this);
		}

		@Override
		public Goal InitializationsChecked(Job job) {
			TypeSystem ts = job.extensionInfo().typeSystem();
			NodeFactory nf = job.extensionInfo().nodeFactory();
			return new ForgivingVisitorGoal("InitializationsChecked", job, new InitChecker(job, ts, nf)).intern(this);
		}

		public static class ValidatingOutputGoal extends OutputGoal {
			private static final long serialVersionUID = -7021152686342225925L;
			public ValidatingOutputGoal(Job job, Translator translator) {
				super(job, translator);
			}
			public boolean runTask() {
				Node ast = job().ast();
				if (ast != null && !((X10Ext)ast.ext()).subtreeValid()) {
					return false;
				}
				return super.runTask();
			}
		}

		@Override
		public Goal CodeGenerated(Job job) {
			TypeSystem ts = extInfo.typeSystem();
			NodeFactory nf = extInfo.nodeFactory();
			Goal cg = new ValidatingOutputGoal(job, new DotTranslator(job, ts, nf, extInfo.targetFactory()));
			return cg.intern(this);
		}

		static class X10ParserGoal extends ParserGoal {
			private static final long serialVersionUID = 6811976416160592748L;
			public X10ParserGoal(Compiler compiler, Job job) {
				super(compiler, job);
			}

			@Override
			protected SourceFile createDummyAST() {
				NodeFactory nf = job().extensionInfo().nodeFactory();
				String fName = job.source().name();
				Position pos = new Position("", job.source().path(), 1, 1).markCompilerGenerated();
				String name = fName.substring(fName.lastIndexOf(File.separatorChar)+1, fName.lastIndexOf('.'));
				X10ClassDecl decl = (X10ClassDecl) nf.ClassDecl(pos, nf.FlagsNode(pos, Flags.PUBLIC),
						nf.Id(pos, name), null, Collections.<TypeNode>emptyList(),
						nf.ClassBody(pos, Collections.<ClassMember>emptyList()));
				decl = decl.errorInAST(new SemanticException("", pos));
				SourceFile ast = nf.SourceFile(pos, Collections.<TopLevelDecl>singletonList(decl)).source(job.source());
				ast = (SourceFile) ((X10Ext)ast.ext()).setSubtreeValid(false);
				return ast;
			}
		}

		@Override
		public Goal Parsed(Job job) {
			return new X10ParserGoal(extInfo.compiler(), job).intern(this);
		}

		@Override
		public Goal constructTypesInitialized(Job job) {
			TypeSystem ts = job.extensionInfo().typeSystem();
			NodeFactory nf = job.extensionInfo().nodeFactory();
			return new ForgivingVisitorGoal("TypesInitialized", job, new X10TypeBuilder(job, ts, nf)).intern(this);
		}

		@Override
		public Goal TypeChecked(Job job) {
			TypeSystem ts = job.extensionInfo().typeSystem();
			NodeFactory nf = job.extensionInfo().nodeFactory();
			return new ForgivingVisitorGoal("TypeChecked", job, new X10TypeChecker(job, ts, nf, job.nodeMemo())).intern(this);
		}

		public Goal ConformanceChecked(Job job) {
			TypeSystem ts = job.extensionInfo().typeSystem();
			NodeFactory nf = job.extensionInfo().nodeFactory();
			return new ForgivingVisitorGoal("ConformanceChecked", job, new ConformanceChecker(job, ts, nf)).intern(this);
		}

		public Goal ReachabilityChecked(Job job) {
			TypeSystem ts = job.extensionInfo().typeSystem();
			NodeFactory nf = job.extensionInfo().nodeFactory();
			return new ForgivingVisitorGoal("ReachChecked", job, new ReachChecker(job, ts, nf)).intern(this);
		}

		public Goal ExceptionsChecked(Job job) {
			TypeSystem ts = job.extensionInfo().typeSystem();
			NodeFactory nf = job.extensionInfo().nodeFactory();
			return new ForgivingVisitorGoal("ExceptionsChecked", job, new ExceptionChecker(job, ts, nf)).intern(this);
		}

		public Goal ExitPathsChecked(Job job) {
			TypeSystem ts = job.extensionInfo().typeSystem();
			NodeFactory nf = job.extensionInfo().nodeFactory();
			return new ForgivingVisitorGoal("ExitChecked", job, new ExitChecker(job, ts, nf)).intern(this);
		}

		public Goal ConstructorCallsChecked(Job job) {
			TypeSystem ts = job.extensionInfo().typeSystem();
			NodeFactory nf = job.extensionInfo().nodeFactory();
			return new ForgivingVisitorGoal("ContructorCallsChecked", job, new ConstructorCallChecker(job, ts, nf)).intern(this);
		}

		public Goal ForwardReferencesChecked(Job job) {
			TypeSystem ts = job.extensionInfo().typeSystem();
			NodeFactory nf = job.extensionInfo().nodeFactory();
			return new ForgivingVisitorGoal("ForwardRefsChecked", job, new FwdReferenceChecker(job, ts, nf)).intern(this);
		}

		public Goal CheckEscapingThis(Job job) {
			return new ForgivingVisitorGoal("CheckEscapingThis", job, new CheckEscapingThis.Main(job)).intern(this);
		}
		private Goal AnnotationChecker(Job job) {
			return new ForgivingVisitorGoal("AnnotationChecker", job, new AnnotationChecker(job,job.extensionInfo().typeSystem(),job.extensionInfo().nodeFactory())).intern(this);
		}
		private Goal Ifdef(Job job) {
			return new ForgivingVisitorGoal("IfdefVisitor", job, new IfdefVisitor(job,job.extensionInfo().typeSystem(),job.extensionInfo().nodeFactory())).intern(this);
		}
		private Goal ErrChecker(Job job) {
			return new ForgivingVisitorGoal("ErrChecker", job, new ErrChecker(job)).intern(this);
		}

		@Override
		protected Job createSourceJob(Source source, Node ast) {
			return new x10.ExtensionInfo.X10Scheduler.X10Job(extInfo, extInfo.jobExt(), source, ast);
		}

		@Override
		protected boolean runPass(Goal goal) throws CyclicDependencyException {
			Job job = goal instanceof SourceGoal ? ((SourceGoal) goal).job() : null;
			int savedInitialErrorCount = -1;
			if (job != null)
				savedInitialErrorCount = ((x10.ExtensionInfo.X10Scheduler.X10Job) job).initialErrorCount();
			boolean result = super.runPass(goal);
			if (job != null)
				((x10.ExtensionInfo.X10Scheduler.X10Job) job).initialErrorCount(savedInitialErrorCount);
			return result;
		}
	}

}
