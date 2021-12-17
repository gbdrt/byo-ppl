module Rejection_sampling = struct
  type prob = Prob

  let sample _prob d = Distribution.draw d

  exception Reject

  let assume _prob p = if not p then raise Reject

  let observe prob d x =
    let y = Distribution.draw d in
    assume prob (x = y)

  let infer ?(n = 1000) model data =
    let rec exec i = try model Prob data with Reject -> exec i in
    let values = Array.init n exec in
    Distribution.uniform_support ~values
end

module Importance_sampling = struct
  type prob = { id : int; scores : float array }

  let sample _prob d = Distribution.draw d
  let factor prob s = prob.scores.(prob.id) <- prob.scores.(prob.id) +. s
  let observe prob d x = factor prob (Distribution.logpdf d x)
  let assume prob p = factor prob (if p then 0. else -.infinity)

  let infer ?(n = 1000) model data =
    let scores = Array.make n 0. in
    let values = Array.mapi (fun i _ -> model { id = i; scores } data) scores in
    Distribution.support ~values ~logits:scores
end
