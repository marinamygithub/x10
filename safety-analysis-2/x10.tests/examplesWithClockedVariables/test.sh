example=( AllReduceParallel Pipeline Convolve NQueensPar MontyPiParallel KMeansScalar Histogram MergeSort Stream Prefix UTS IDEA SOR Stencil RandomAccess Series RayTrace LUFact SparseMatMul)
for ((i = 0; i < ${#example[@]}; i++))
do
	
	echo ""
	echo "----${example[$i]}: Clocked Code -----"
	echo ""
	../../../x10.dist/bin/x10c -SAFE_PARALLELIZATION_CHECK=true ../${example[$i]}.x10 > out.txt 
	time ../../../x10.dist/bin/x10  ${example[$i]}.x10 

	echo ""
	echo "----${example[$i]}Orig: Original Code -----"
	echo ""
	../../../x10.dist/bin/x10c  ../${example[$i]}Orig.x10 > out.txt 
	time ../../../x10.dist/bin/x10  ${example[$i]}Orig.x10 
	
	echo ""
	echo "----${example[$i]}Orig: Original Code with safe parallelization check -----"
	echo ""
	../../../x10.dist/bin/x10c  -SAFE_PARALLELIZATION_CHECK=true ../${example[$i]}Orig.x10 > out.txt 
done

rm *.java *.class

