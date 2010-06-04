package x10.util;

/**
 * @author Dave Cunningham
*/
// This class exists as a work-around for XTENLANG-624
public struct Option {
    short_:String; // underscore is workaround for XTENLANG-623
    long_:String;
    description:String;
    public def this(s:String, l:String, d:String) {
        short_ = "-"+s; long_="--"+l; description=d;
    }
    public global safe def toString() = description;
}
