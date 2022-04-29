//MOC-ENV MOC_UNLOCK_PRIM=yesplease
import Prim "mo:⛔";

func serUnit() : Blob = to_candid ();
func deserUnit(x : Blob) : ?() = from_candid x;

func serNats(x: Nat, y: Nat, z: Nat) : Blob = to_candid (x,y,z);
func deserNats(x: Blob) : ?(Nat, Nat, Nat) = from_candid x;

func serBool(x: Bool) : Blob = to_candid (x);
func deserBool(x: Blob) : ?(Bool) = from_candid x;

func serText(x: Text) : Blob = to_candid (x);
func deserText(x: Blob) : ?(Text) = from_candid x;

Prim.debugPrint(debug_show (serUnit ()));
Prim.debugPrint(debug_show (serNats (1,2,3)));
Prim.debugPrint(debug_show (serText "Hello World!"));
Prim.debugPrint(debug_show (serBool true));
Prim.debugPrint(debug_show (serBool false));

// unit and triples

assert (?() == deserUnit (serUnit ()));
assert(?(1,2,3) == (deserNats (serNats (1,2,3)) : ?(Nat,Nat,Nat)));
assert(?(1,2,3) == (from_candid (to_candid (1,2,3)) : ?(Nat,Nat,Nat)));

// singletons

assert(?(true) == deserBool (serBool true));
assert(?(false) == deserBool (serBool false));
assert (?("Hello World!") == deserText (serText "Hello World!"));

let arrayNat : [Nat] = [0,1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768,65536,131072,262144,524288,1048576,2097152,4194304,8388608,16777216,33554432,67108864,134217728,268435456,536870912,1073741824,2147483648,4294967296,8589934592,17179869184,34359738368];

let arrayInt : [Int] = [-1,-2,-4,-8,-16,-32,-64,-128,-256,-512,-1024,-2048,-4096,-8192,-16384,-32768,-65536,-131072,-262144,-524288,-1048576,-2097152,-4194304,-8388608,-16777216,-33554432,-67108864,-134217728,-268435456,-536870912,-1073741824,-2147483648,-4294967296,-8589934592,-17179869184,-34359738368,-68719476736];

func serArrayNat(a: [Nat]) : Blob = (prim "serialize" : [Nat] -> Blob) a;
func deserArrayNat(b: Blob) : [Nat] = (prim "deserialize" : Blob -> [Nat]) b;

func serArrayInt(a: [Int]) : Blob = (prim "serialize" : [Int] -> Blob) a;
func deserArrayInt(b: Blob) : [Int] = (prim "deserialize" : Blob -> [Int]) b;

let started_with = Prim.rts_heap_size();
assert(arrayNat == deserArrayNat (serArrayNat arrayNat));
assert(arrayNat == deserArrayInt (serArrayNat arrayNat));
assert(arrayNat == deserArrayInt (serArrayInt arrayNat));
assert(arrayInt == deserArrayInt (serArrayInt arrayInt));
Prim.debugPrint(debug_show (Prim.rts_heap_size() : Int - started_with));

//SKIP run
//SKIP run-ir
//SKIP run-low
