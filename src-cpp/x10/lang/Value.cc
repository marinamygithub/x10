#include <sstream>

#include <x10aux/ref.h>
#include <x10aux/alloc.h>

#include <x10/lang/Value.h>
#include <x10/lang/String.h>

x10_int x10::lang::Value::hashCode() {
    //FIXME: no idea what to do here
    return 0;
}

x10aux::ref<x10::lang::String> x10::lang::Value::toString() {
    //FIXME: no idea what to do here
    return new (x10aux::alloc<x10::lang::String>()) x10::lang::String("Vacant");
}

const x10::lang::Value::RTT * const x10::lang::Value::RTT::it =
    new Value::RTT();

