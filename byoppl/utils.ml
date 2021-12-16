(** Missing utilies functions. *)

(** {1 Numerical functions} *)

(** [approx expected x] returns true if [x] is within [[expected +/- eps]]. The optional argument [eps] controls the tolerance. *)
let approx ?(eps = 0.1) expected x =
  expected -. eps <= x && x <= expected +. eps

(** {1 List functions} *)

(** Remove all elements of [l] after position [idx] (excluded). *)
let rec slice l idx =
  match (l, idx) with [], _ -> [] | l, 0 -> l | _ :: t, n -> slice t (n - 1)

(** {1 Array functions} *)

(** [findi a x] returns the first index [i] of an array [a] such that [a.(i) = x]. *)
let findi a x =
  let rec traversal i =
    if i >= Array.length a then None
    else if a.(i) = x then Some i
    else traversal (i + 1)
  in
  traversal 0

(** Same as [Array.fold_left] but the function is applied to the index of the element as first argument. *)
let foldi f a ~init =
  let acc = ref init in
  Array.iteri (fun i x -> acc := f i !acc x) a;
  !acc

(** Turn an OCaml Array to an Owl 1D Array. *)
let to_owl_arr a = Owl.Arr.of_array a [| Array.length a |]

(** Turn an array of score (in log scale) into an array of probabilities. *)
let normalize scores =
  scores |> to_owl_arr
  |> (fun s -> Owl.Arr.(exp (s -$ log_sum_exp' s)))
  |> Owl.Arr.to_array

(** [average ~values ~weights] computes the weighted average of the values where each [values.(i)] is associated to the unnormalized log-probability [weights.(i)]. *)
let average ~values ~logits =
  let weights = Owl.Arr.(exp (logits -$ log_sum_exp' logits)) in
  let weighted_sum = Owl.Arr.(sum' (values * weights)) in
  weighted_sum /. Owl.Arr.sum' weights

(** [shrink ~values ~probs] gathers similar values to shrink a support. *)
let shrink ~values ~probs =
  let tbl = Hashtbl.create (Array.length values) in
  Array.iter2
    (fun x w ->
      match Hashtbl.find_opt tbl x with
      | None -> Hashtbl.add tbl x w
      | Some p -> Hashtbl.replace tbl x (p +. w))
    values probs;
  let values = tbl |> Hashtbl.to_seq_keys |> Array.of_seq in
  let probs = tbl |> Hashtbl.to_seq_values |> Array.of_seq in
  (values, probs)

(** {1 Hashtbl functions } *)

(** Add missing Hashtbl functions. *)
module Hashtbl = struct
  include Hashtbl

  type ('a, 'b) t = ('a, 'b) Hashtbl.t

  (** Add key [k] with value [v] in the table. 
  If [k] is already bound to [w] repalce the values with [gather w v]*)
  let add hist gather k v =
    match Hashtbl.find_opt hist k with
    | None -> Hashtbl.add hist k v
    | Some w -> Hashtbl.replace hist k (gather w v)

  (** Returns an array containing the keys. *)
  let to_array_keys hist = hist |> Hashtbl.to_seq_keys |> Array.of_seq

  (** Returns an array containing the values. *)
  let to_array_values hist = hist |> Hashtbl.to_seq_values |> Array.of_seq
end
