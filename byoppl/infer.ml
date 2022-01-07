module Gen = struct
  type 'a prob = 'a option
  and 'a next = 'a prob -> 'a prob
  and ('a, 'b) model = 'a -> ('b -> 'b next) -> 'b next

  let sample d k prob =
    let v = Distribution.draw d in
    k v prob

  let factor _s k prob = k () prob
  let observe d x = factor (Distribution.logpdf d x)
  let assume p = factor (if p then 0. else -.infinity)
  let exit v _prob = Some v

  let draw model data =
    let v = (model data) exit None in
    Option.get v
end

module Importance_sampling = struct
  type 'a prob = { id : int; particles : 'a particle array }
  and 'a particle = { value : 'a option; score : float; k : 'a next }
  and 'a next = 'a prob -> 'a prob
  and ('a, 'b) model = 'a -> ('b -> 'b next) -> 'b next

  let sample d k prob =
    let v = Distribution.draw d in
    k v prob

  let factor s k prob =
    let particle = prob.particles.(prob.id) in
    prob.particles.(prob.id) <- { particle with score = s +. particle.score };
    k () prob

  let assume p = factor (if p then 0. else -.infinity)
  let observe d x = factor (Distribution.logpdf d x)

  let run_next prob =
    if prob.id < Array.length prob.particles - 1 then
      let k = prob.particles.(prob.id + 1).k in
      k { prob with id = prob.id + 1 }
    else prob

  let exit v prob =
    let particle = prob.particles.(prob.id) in
    prob.particles.(prob.id) <- { particle with value = Some v };
    run_next prob

  let infer ?(n = 1000) model data =
    let init_particle = { value = None; score = 0.; k = (model data) exit } in
    let prob = { id = -1; particles = Array.make n init_particle } in
    let prob = run_next prob in
    let values = Array.map (fun p -> Option.get p.value) prob.particles in
    let logits = Array.map (fun p -> p.score) prob.particles in
    Distribution.support ~values ~logits
end

module Particle_filter = struct
  include Importance_sampling

  let resample particles =
    let logits = Array.map (fun x -> x.score) particles in
    let values = Array.map (fun x -> { x with score = 0. }) particles in
    let dist = Distribution.support ~values ~logits in
    Array.init (Array.length particles) (fun _ -> Distribution.draw dist)

  let factor s k prob =
    let particle = prob.particles.(prob.id) in
    prob.particles.(prob.id) <-
      { particle with k = k (); score = s +. particle.score };
    let prob =
      if prob.id < Array.length prob.particles - 1 then prob
      else { id = -1; particles = resample prob.particles }
    in
    run_next prob

  let assume p = factor (if p then 0. else -.infinity)
  let observe d x = factor (Distribution.logpdf d x)
end
