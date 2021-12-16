module Gen = struct
  type 'a prob = TODO
  and 'a next = 'a prob -> 'a prob
  and ('a, 'b) model = 'a -> ('b -> 'b next) -> 'b next

  let sample _ = assert false
  let factor _ = assert false
  let assume _ = assert false
  let observe _ _ = assert false
  let draw _ _ = assert false
end

module Importance_sampling = struct
  type 'a prob = TODO
  and 'a next = 'a prob -> 'a prob
  and ('a, 'b) model = 'a -> ('b -> 'b next) -> 'b next

  let sample _ = assert false
  let factor _ = assert false
  let assume _ = assert false
  let observe _ _ = assert false
  let infer ?n:_n _ _ = assert false
end

module Particle_filter = struct end
