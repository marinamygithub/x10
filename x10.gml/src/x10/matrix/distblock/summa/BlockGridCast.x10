/*
 *  This file is part of the X10 project (http://x10-lang.org).
 *
 *  This file is licensed to You under the Eclipse Public License (EPL);
 *  You may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *      http://www.opensource.org/licenses/eclipse-1.0.php
 *
 *  (C) Copyright IBM Corporation 2006-2012.
 */

package x10.matrix.distblock.summa;

import x10.io.Console;
import x10.util.Timer;
import x10.util.ArrayList;

import x10.compiler.Ifdef;
import x10.compiler.Ifndef;
import x10.compiler.Uninitialized;
import x10.compiler.Inline;

import x10.matrix.Debug;
import x10.matrix.Matrix;
import x10.matrix.DenseMatrix;
import x10.matrix.sparse.SparseCSC;
import x10.matrix.block.MatrixBlock;

import x10.matrix.comm.WrapMPI;

import x10.matrix.distblock.BlockSet;
import x10.matrix.distblock.CastPlaceMap;

/**
 * Ring cast sends data from here to a set of blocks, or partial broadcast
 *.
 */
public class BlockGridCast  {


	//==================================================
	// GridCast: row-wise or column-wise 
	//==================================================
	public static def rowWise(rid:Int, cid:Int):Int = rid;
	public static def colWise(rid:Int, cid:Int):Int = cid;
	
	/**
	 * Sends data of the front block at here that has same row block id as root block to all front blocks 
	 * in other places in the same row 
	 *
	 * @param distBS     distributed block sets in all places
	 * @param rootbid    root block id
	 * @param datCnt     number of data to send out
	 * @param plst       list of places to receive data
	 */
	public static def rowCastToPlaces(distBS:PlaceLocalHandle[BlockSet], rootbid:Int, datCnt:Int, plst:Array[Int](1)) {
		castToPlaces(distBS, rootbid, datCnt, (r:Int,c:Int)=>r, plst);
	}
	
	/**
	 * Sends data of the front block at here that has the same column block id as root block 
	 * to all front blocks in other places the same column
	 * 
	 * @param distBS     distributed block sets in all places
	 * @param rootbid    root block id
	 * @param colCnt     number of data to send out
	 * @param plst       list of places
	 */	
	public static def colCastToPlaces(distBS:PlaceLocalHandle[BlockSet], rootbid:Int, datCnt:Int, plst:Array[Int](1)) {
		castToPlaces(distBS, rootbid, datCnt, (r:Int,c:Int)=>c, plst);
	}
	
	/**
	 * Send data of root block to all front blocks in the specified list of places
	 * row/column-wise. This method reqires to be at the place of root block.
	 * The root place ID is not required to be in the place list. 
	 * 
	 */
	public static def castToPlaces(distBS:PlaceLocalHandle[BlockSet], rootbid:Int, datCnt:Int, 
			select:(Int,Int)=>Int, plst:Array[Int](1)) {
		// Must start at the place of root block
		if (plst.size > 1) {
			val rtblk = distBS().findFrontBlock(rootbid, select);
			if (rtblk.isSparse()) {
				val spa = rtblk.getMatrix() as SparseCSC;
				spa.initRemoteCopyAtSource();
			}
			binaryTreeCastTo(distBS, rootbid, datCnt, select, plst);
			//Local ring cast
			finalizeRingCast(distBS, rootbid, datCnt, select, plst);
		}
	}
	

	//----------------------------------------------------------------
	/**
	 * Broadcast data from local root block at here to a list of places. 
	 */
	private static def binaryTreeCastTo(
			distBS:PlaceLocalHandle[BlockSet], rootbid:Int, datCnt:Int, 
			select:(Int,Int)=>Int, 
			plist:Array[Int](1)){

		val pcnt   = plist.size;
		val rtcnt:Int = (pcnt+1) / 2; 
		val lfcnt  = pcnt - rtcnt;
		val rtroot = plist(lfcnt);

		val lfplist = new Array[Int](lfcnt, (i:Int)=>plist(i));
		val rtplist = new Array[Int](rtcnt, (i:Int)=>plist(lfcnt+i));

		//Debug.flushln("left branch list:"+lfplist.toString());
		//Debug.flushln("Right branch root:"+rtroot+" list:"+rtplist.toString());		
		finish {
			if (rtcnt > 0) async {
				copyBlockToRightBranch(distBS, rootbid, rtroot, datCnt, select, rtplist);
			}
			// Perform binary bcast on the left branch
			if (lfcnt > 0) async {
				binaryTreeCastTo(distBS, rootbid, datCnt, select, lfplist); 
			}
		}
	}
	//--------------------------------------------------------------
	
	private static def copyBlockToRightBranch(
			distBS:PlaceLocalHandle[BlockSet], rootbid:Int, remotepid:Int, datCnt:Int,
			select:(Int,Int)=>Int, plist:Array[Int](1)) {

		val rootpid = distBS().findPlace(rootbid);
		if (remotepid == here.id() || remotepid==rootpid ) {
			if (plist.size > 1 ) {
				binaryTreeCastTo(distBS, rootbid, datCnt, select, plist);
			}
			return;
		}
		
		val srcblk = distBS().findFrontBlock(rootbid, select);
		if (srcblk.isDense()) {
			@Ifdef("MPI_COMMU") {
				mpiCopyDenseBlock(distBS, rootbid, srcblk, remotepid, datCnt, select, plist);
			}
			@Ifndef("MPI_COMMU") {
				x10CopyDenseBlock(distBS, rootbid, srcblk, remotepid, datCnt, select, plist);
			}
		} else if (srcblk.isSparse()) {
			@Ifdef("MPI_COMMU") {
				mpiCopySparseBlock(distBS, rootbid, srcblk, remotepid, datCnt, select, plist);
			}
			@Ifndef("MPI_COMMU") {
				x10CopySparseBlock(distBS, rootbid, srcblk, remotepid, datCnt, select, plist);
			}			
		} else {
			Debug.exit("Error in block type");
		}
	}

	//--------------------------------------------------------------
	//--------------------------------------------------------------
	private static def x10CopyDenseBlock(distBS:PlaceLocalHandle[BlockSet], rootbid:Int, 
			srcblk:MatrixBlock, rmtpid:Int, datCnt:Int,	select:(Int,Int)=>Int, plist:Array[Int](1)):void {
		
		val srcden = srcblk.getMatrix() as DenseMatrix;
		val srcbuf = new RemoteArray[Double](srcden.d as Array[Double](1){self!=null});
		at (Dist.makeUnique()(rmtpid)) {
			//Remote capture:distBS, rootbid, datCnt, rtplist
			val blk  = distBS().findFrontBlock(rootbid, select);
			val dstden = blk.getMatrix() as DenseMatrix;
			// Using copyFrom style
			finish Array.asyncCopy[Double](srcbuf, 0, dstden.d, 0, datCnt);
			// Perform binary bcast on the right branch
			if (plist.size > 1 ) {
				binaryTreeCastTo(distBS, rootbid, datCnt, select, plist);
			}
		}
		
	}
	
	private static def x10CopySparseBlock(
			distBS:PlaceLocalHandle[BlockSet], 
			rootbid:Int, srcblk:MatrixBlock, rmtpid:Int, datCnt:Int,
			select:(Int,Int)=>Int, plist:Array[Int](1)) {
		
		val srcspa = srcblk.getMatrix() as SparseCSC;
		val srcidx = new RemoteArray[Int   ](srcspa.getIndex() as Array[Int   ]{self!=null});
		val srcval = new RemoteArray[Double](srcspa.getValue() as Array[Double]{self!=null});
		
		at (Dist.makeUnique()(rmtpid)) {
			//Remote capture:distBS, rootbid, datCnt, rtplist
			val blk    = distBS().findFrontBlock(rootbid, select);
			val dstspa = blk.getMatrix() as SparseCSC;
			// Using copyFrom style
			dstspa.initRemoteCopyAtDest(datCnt);
			finish Array.asyncCopy[Int   ](srcidx, 0, dstspa.getIndex(), 0, datCnt);
			finish Array.asyncCopy[Double](srcval, 0, dstspa.getValue(), 0, datCnt);
			// Perform binary bcast on the right branch
			if (plist.size > 1 ) {
				binaryTreeCastTo(distBS, rootbid, datCnt, select, plist);
			}
		}	
	}	
	//=======================================================================
	private static def mpiCopyDenseBlock(
			distBS:PlaceLocalHandle[BlockSet], 
			rootbid:Int, srcblk:MatrixBlock, rmtpid:Int, datCnt:Int,
			select:(Int,Int)=>Int, 
			plist:Array[Int](1)) {

		val srcpid = here.id();
		val srcden = srcblk.getMatrix() as DenseMatrix;
		val tag    = rootbid;//RandTool.nextInt(Int.MAX_VALUE);
		//Tag is used to differ different ring cast.
		//Row and column-wise ringcast must NOT be carried out at the same
		//time. This tag only allows ringcast be differed by root block id.
				
		async {
			WrapMPI.world.send(srcden.d, 0, datCnt, rmtpid, tag);
		}
		at (Dist.makeUnique()(rmtpid)) {
			//Remote capture:distBS, rootbid, datCnt, rtplist, tag
			val blk    = distBS().findFrontBlock(rootbid, select);
			val dstden = blk.getMatrix() as DenseMatrix;
			// Using copyFrom style
			WrapMPI.world.recv(dstden.d, 0, datCnt, srcpid, tag);
			
			// Perform binary bcast on the right branch
			if (plist.size > 1 ) {
				binaryTreeCastTo(distBS, rootbid, datCnt, select, plist);
			}
		}
	}
	
	private static def mpiCopySparseBlock(
			distBS:PlaceLocalHandle[BlockSet], 
			rootbid:Int, srcblk:MatrixBlock, rmtpid:Int, datCnt:Int,
			select:(Int,Int)=>Int, 
			plist:Array[Int](1)) {

		val srcpid = here.id();
		val srcspa = srcblk.getMatrix() as SparseCSC;
		val tag = rootbid;//RandTool.nextInt(Int.MAX_VALUE);
		//Tag must allow to differ multiply ringcast.
		async {
			WrapMPI.world.send(srcspa.getIndex(), 0, datCnt, rmtpid, tag);
			WrapMPI.world.send(srcspa.getValue(), 0, datCnt, rmtpid, tag+1000000);
		}
		
		at (Dist.makeUnique()(rmtpid)) {
			//Remote capture:distBS, rootbid, datCnt, rtplist, tag
			val blk    = distBS().findFrontBlock(rootbid, select);
			val dstspa = blk.getMatrix() as SparseCSC;
			dstspa.initRemoteCopyAtDest(datCnt);
			// Using copyFrom style
			WrapMPI.world.recv(dstspa.getIndex(), 0, datCnt, srcpid, tag);
			WrapMPI.world.recv(dstspa.getValue(), 0, datCnt, srcpid, tag+1000000);
			// Perform binary bcast on the right branch
			//Debug.flushln("Recv "+here.id()+" get from "+srcpid);
			if (plist.size > 1 ) {
				binaryTreeCastTo(distBS, rootbid, datCnt, select, plist);
			}
		}
	}	
	
	//=======================================================================
	private static def finalizeRingCastRowwise(distBS:PlaceLocalHandle[BlockSet], rootbid:Int, datCnt:Int, plist:Array[Int](1)){
		finalizeRingCast(distBS, rootbid, datCnt, (rid:Int,cid:Int)=>rid, plist);
	}

	private static def finalRingCastColwise(distBS:PlaceLocalHandle[BlockSet], rootbid:Int, datCnt:Int, plist:Array[Int](1)){
		finalizeRingCast(distBS, rootbid, datCnt, (rid:Int,cid:Int)=>cid, plist);
	}

	private static def finalizeRingCast(distBS:PlaceLocalHandle[BlockSet], 
			rootbid:Int, datCnt:Int, 
			select:(Int,Int)=>Int, plist:Array[Int](1)){
		
		val rootpid = here.id();
		finish {
			//Remote block set update
			for (val [p]:Point in plist) {
				val pid = plist(p);
				async at (Dist.makeUnique()(pid)) {
					val bset = distBS();
					val blk  = bset.findFrontBlock(rootbid, select); 
					if (blk.isSparse() && plist.size > 1) { 
						//If plist has only rootpid, sparse is not initialized for copy
						val spa = blk.getMatrix() as SparseCSC;
						if (here.id() != rootpid)
							spa.finalizeRemoteCopyAtDest();
						else
							spa.finalizeRemoteCopyAtSource();
					}
					//bset.selectCast(blk, colCnt, select);
				}
			}
		}
	}
	
	//===================================================================
	
	public static def verifyCast(chkBS:PlaceLocalHandle[BlockSet],
			srcblk:MatrixBlock, 
			var nxtrid:Int, var nxtcid:Int,
			select:(Int,Int)=>Int, dir:(Int,Int)=>Int):Boolean {
		var retval:Boolean = true;
		
		val grid = chkBS().getGrid();
		val dmap = chkBS().getDistMap();
		while (retval) {
			//My neighoring block's place
			nxtrid = select(nxtrid, dir(nxtrid-1, nxtrid+1));
			nxtcid = select(dir(nxtcid-1, nxtcid+1), nxtcid);

			if (nxtrid < 0 || nxtrid >= grid.numRowBlocks) break;
			if (nxtcid < 0 || nxtcid >= grid.numColBlocks) break;
			val nxtbid = grid.getBlockId(nxtrid, nxtcid);
			val nxtplc = dmap.findPlace(nxtbid);
			if (nxtplc == here.id()) continue;
			
			val nxtRowId = nxtrid;
			val nxtColId = nxtcid;
			retval &= at (Dist.makeUnique()(nxtplc)) {
				val objblk = chkBS().findFrontBlock(nxtRowId, nxtColId, select);
				var ret:Boolean=srcblk.equals(objblk);
				if (!ret) {
					Debug.flushln("Check equal failed");
					srcblk.getMatrix().printMatrix("Remote source block:");
					objblk.getMatrix().printMatrix("check front block:"+nxtRowId+","+nxtColId+" at "+here.id());

				} else
					ret = verifyCast(chkBS, objblk, nxtRowId, nxtColId, select, dir);
				ret
			};
		}
		return retval;
	}
	
	public static def verifyRowCastEast(chkBS:PlaceLocalHandle[BlockSet], rootblk:MatrixBlock) =
		verifyCast(chkBS, rootblk, rootblk.myRowId, rootblk.myColId, (r:Int,c:Int)=>r, (w:Int,e:Int)=>e);

	public static def verifyRowCastWest(chkBS:PlaceLocalHandle[BlockSet], rootblk:MatrixBlock) =
		verifyCast(chkBS, rootblk, rootblk.myRowId, rootblk.myColId, (r:Int,c:Int)=>r, (w:Int,e:Int)=>w);
			
	public static def verifyColCastNorth(chkBS:PlaceLocalHandle[BlockSet], rootblk:MatrixBlock) =
		verifyCast(chkBS, rootblk,  rootblk.myRowId, rootblk.myColId, (r:Int,c:Int)=>c, (n:Int,s:Int)=>n);

	public static def verifyColCastSouth(chkBS:PlaceLocalHandle[BlockSet], rootblk:MatrixBlock) =
		verifyCast(chkBS, rootblk,  rootblk.myRowId, rootblk.myColId, (r:Int,c:Int)=>c, (n:Int,s:Int)=>s);
	
}