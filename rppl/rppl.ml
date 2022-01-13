open Byoppl

type 'a distribution = 'a Distribution.t

let gaussian mu sigma = Distribution.gaussian ~mu ~sigma
let bernoulli p = Distribution.bernoulli ~p
let uniform a b = Distribution.uniform ~a ~b
let draw = Distribution.draw
let mean = Distribution.mean

open Ztypes

type prob = None (* TODO *)

let sample (_prob, d) = assert false (* TODO *)

let factor (prob, s) = assert false (* TODO *)

let observe (prob, d, x) = assert false (* TODO *)

type 'a infer_state = { mutable particles : 'a array; scores : float array }

let infer_importance n (Cnode { alloc; reset; step; copy }) =
  let infer_alloc () = assert false (* TODO *) in
  let infer_reset state = assert false (* TODO *) in
  let infer_step state data = assert false (* TODO *) in
  let infer_copy _ _ = () in
  Cnode
    {
      alloc = infer_alloc;
      reset = infer_reset;
      step = infer_step;
      copy = infer_copy;
    }

let resample alloc copy n state = assert false (* TODO *)

let infer_pf n (Cnode { alloc; reset; step; copy }) =
  let infer_alloc () = assert false (* TODO *) in
  let infer_reset state = assert false (* TODO *) in
  let infer_step state data = assert false (* TODO *) in
  let infer_copy _ _ = () in
  Cnode
    {
      alloc = infer_alloc;
      reset = infer_reset;
      step = infer_step;
      copy = infer_copy;
    }
