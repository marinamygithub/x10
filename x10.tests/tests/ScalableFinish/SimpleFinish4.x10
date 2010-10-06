import x10.compiler.FinishAsync;
import x10.util.Timer;
public class SimpleFinish4 {
    public static def main(args: Array[String](1)) //throws Exception
    {
	    val start = Timer.milliTime();
	    finish{
	    var i:int = 0;
	    for(i=0;i<1000;i++){
		val p1 = Place.place(i % Place.MAX_PLACES);
	    	async at (p1){    
		    @FinishAsync(1,1,false,2)
                    finish {
                        for(var p:int = 0; p<Place.MAX_PLACES; p++){
                            async at (Place.place(p)){
                                for(var pp:int = 0; pp<Place.MAX_PLACES; pp++){
                                     val i = pp;
                                     async{}
                                }
                            }
                         }
                     }
		}
	    }
	    }
	    val end = Timer.milliTime();
	    Console.OUT.println("time = "+(end-start)+" milliseconds");
    }
}
