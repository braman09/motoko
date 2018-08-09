(* Representation *)

type con = Con.t
type mut = ConstMut | VarMut
type actor = Object | Actor

type width =
  | Width8
  | Width16
  | Width32
  | Width64

type prim =
  | NullT
  | BoolT
  | NatT
  | IntT
  | WordT of width
  | FloatT
  | CharT
  | TextT

type typ =
  | VarT of con * typ list                     (* constructor *)
  | PrimT of prim                              (* primitive *)
  | ObjT of actor * typ_field list             (* object *)
  | ArrayT of mut * typ                        (* array *)
  | OptT of typ                                (* option *)
  | TupT of typ list                           (* tuple *)
  | FuncT of typ_bind list * typ * typ         (* function *)
  | AsyncT of typ                              (* future *)
  | LikeT of typ                               (* expansion *)
  | AnyT                                       (* top *)
(*
  | UnionT of type * typ                       (* union *)
  | AtomT of string                            (* atom *)
*)

and typ_bind = {var : con; bound : typ}
and typ_field = {var : string; typ : typ; mut : mut}

type kind =
  | DefK of typ_bind list * typ
  | AbsK of typ_bind list * typ


(* Short-hands *)

val unitT : typ
val boolT : typ
val intT : typ


(* Normalization *)

val normalize : kind Con.Env.t -> typ -> typ


(* First-order substitution *)

type subst = typ Con.Env.t

val subst : subst -> typ -> typ
val make_subst : typ list -> typ_bind list -> subst


(* Environments *)

module Env : Map.S with type key = string

val union : 'a Env.t -> 'a Env.t -> 'a Env.t


(* Pretty printing *)

val string_of_mut : mut -> string
val string_of_width : width -> string
val string_of_prim : prim -> string
val string_of_typ : typ -> string
val string_of_kind : kind -> string
