type 'a support = {
  values : 'a array;
  logits : float array;
  probs : float array;
}

type 'a t = {
  sample : unit -> 'a;
  logpdf : 'a -> float;
  mean : (unit -> float) option;
  var : (unit -> float) option;
  samples : 'a array Lazy.t;
  support : 'a support option;
}

let make ?(n = 10000) ~sample ~logpdf ?mean ?var ?support () =
  let samples = lazy (Array.init n (fun _ -> sample ())) in
  { sample; logpdf; mean; var; samples; support }

let draw dist = dist.sample ()
let get_samples dist = Lazy.force dist.samples

let get_support ?(shrink = false) dist =
  match shrink with
  | false -> Option.get dist.support
  | true ->
      let { values; probs; _ } = Option.get dist.support in
      let values, probs = Utils.shrink ~values ~probs in
      { values; logits = Array.map log probs; probs }

let logpdf dist x = dist.logpdf x

let mean_generic ~transform dist : float =
  match (dist.mean, dist.support) with
  | Some mean, _ -> mean ()
  | _, Some { values; logits; _ } ->
      let values = values |> Array.map transform |> Utils.to_owl_arr in
      let logits = Utils.to_owl_arr logits in
      Utils.average ~values ~logits
  | _ -> Owl_stats.mean (dist |> get_samples |> Array.map transform)

let var_generic ~transform dist =
  match (dist.var, dist.support) with
  | Some var, _ -> var ()
  | _, Some { values; logits; _ } ->
      let m = mean_generic ~transform dist in
      let values =
        values |> Array.map transform |> Utils.to_owl_arr
        |> Owl.Arr.(fun a -> (a -$ m) **$ 2.)
      in
      let logits = Utils.to_owl_arr logits in
      Utils.average ~values ~logits
  | _ -> Owl_stats.var (dist |> get_samples |> Array.map transform)

let mean = mean_generic ~transform:Fun.id
let mean_int = mean_generic ~transform:Float.of_int
let var = var_generic ~transform:Fun.id
let var_int = var_generic ~transform:Float.of_int
let std dist = sqrt (var dist)
let std_int dist = sqrt (var_int dist)
let stats dist = (mean dist, std dist)
let stats_int dist = (mean_int dist, std_int dist)

let bernoulli ~p =
  assert (0. <= p && p <= 1.);
  let sample () = Owl_stats.binomial_rvs ~p ~n:1 in
  let logpdf x = Owl_stats.binomial_logpdf x ~p ~n:1 in
  let mean () = p in
  let var () = p *. (1. -. p) in
  let support =
    {
      values = [| 0; 1 |];
      logits = [| log (1. -. p); log p |];
      probs = [| 1. -. p; p |];
    }
  in
  make ~sample ~logpdf ~support ~mean ~var ()

let binomial ~p ~n =
  assert (n >= 0 && 0. <= p && p <= 1.);
  let sample () = Owl_stats.binomial_rvs ~p ~n in
  let logpdf x = Owl_stats.binomial_logpdf x ~p ~n in
  let mean () = Float.of_int n *. p in
  let var () = Float.of_int n *. p *. (1. -. p) in
  make ~sample ~logpdf ~mean ~var ()

let dirac ~v =
  let sample () : 'a = v in
  let logpdf x = if x = v then 0. else -.infinity in
  make ~sample ~logpdf ()

let support ~values ~logits =
  assert (Array.length values = Array.length logits);
  let probs = Utils.normalize logits in
  let support = { values; logits; probs } in
  let sample () =
    let i = Owl_stats.categorical_rvs probs in
    values.(i)
  in
  let logpdf x =
    let idx = Option.get (Utils.findi values x) in
    logits.(idx)
  in
  make ~sample ~logpdf ~support ()

let uniform_support ~values =
  support ~values ~logits:(Array.make (Array.length values) 0.)

let split dist =
  let { values; logits; _ } = get_support dist in
  let v1, v2 = values |> Array.to_list |> List.split in
  (* let v1, v2 = Array.split values in *)
  ( support ~values:(Array.of_list v1) ~logits,
    support ~values:(Array.of_list v2) ~logits )

let split_list dist =
  let { values; logits; _ } = get_support dist in
  assert (Array.length values > 0);
  assert (Array.for_all (fun v -> List.length v = List.length values.(0)) values);
  let rec split res sup =
    if Array.for_all (( = ) []) sup then res
    else
      let res = split res (Array.map (fun x -> List.tl x) sup) in
      let values = Array.map (fun x -> List.hd x) sup in
      support ~values ~logits :: res
  in
  split [] values

let split_array dist =
  let { values; logits; _ } = get_support dist in
  let values = Array.map Array.to_list values in
  let d = split_list (support ~values ~logits) in
  Array.of_list d

let beta ~a ~b =
  assert (a > 0. && b > 0.);
  let sample () = Owl_stats.beta_rvs ~a ~b in
  let logpdf x = Owl_stats.beta_logpdf x ~a ~b in
  let mean () = a /. (a +. b) in
  let var () = a *. b /. (((a +. b) ** 2.) *. (a +. b +. 1.)) in
  make ~sample ~logpdf ~mean ~var ()

let gaussian ~mu ~sigma =
  assert (sigma > 0.);
  let sample () = Owl_stats.gaussian_rvs ~mu ~sigma in
  let logpdf x = Owl_stats.gaussian_logpdf x ~mu ~sigma in
  let mean () = mu in
  let var () = sigma ** 2. in
  make ~sample ~logpdf ~mean ~var ()

let uniform ~a ~b =
  let sample () = Owl_stats.uniform_rvs ~a ~b in
  let logpdf x = Owl_stats.uniform_logpdf x ~a ~b in
  let mean () = a +. (b /. 2.) in
  let var () = 1. /. 12. *. ((b -. a) ** 2.) in
  make ~sample ~logpdf ~mean ~var ()
