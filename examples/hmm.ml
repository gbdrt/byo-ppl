open Byoppl
open Distribution
open Basic.Importance_sampling

let hmm prob data =
  let rec gen states data =
    match (states, data) with
    | [], y :: data -> gen [ y ] data
    | states, [] -> states
    | pre_x :: _, y :: data ->
        let x = sample prob (gaussian ~mu:pre_x ~sigma:1.0) in
        let () = observe prob (gaussian ~mu:x ~sigma:1.0) y in
        gen (x :: states) data
  in
  gen [] data

let _ =
  Format.printf "@.-- HMM, Basic Importance Sampling --@.";
  let data = Owl.Arr.linspace 0. 20. 20 |> Owl.Arr.to_array |> Array.to_list in
  let dist = Distribution.split_list (infer hmm data) in
  let m_x = List.map Distribution.mean (List.rev dist) in
  List.iter2 (Format.printf "%f >> %f@.") data m_x

open Cps_operators
open Infer.Importance_sampling

let hmm data =
  let rec gen states data =
    match (states, data) with
    | [], y :: data -> gen [ y ] data
    | states, [] -> return states
    | pre_x :: _, y :: data ->
        let* x = sample (gaussian ~mu:pre_x ~sigma:1.0) in
        let* () = observe (gaussian ~mu:x ~sigma:1.0) y in
        gen (x :: states) data
  in
  gen [] data

let _ =
  Format.printf "@.-- HMM, CPS Importance Sampling --@.";
  let data =
    Owl.Arr.(linspace 0. 20. 20 + gaussian [| 20 |])
    |> Owl.Arr.to_array |> Array.to_list
  in
  let dist = Distribution.split_list (infer hmm data) in
  let m_x = List.map Distribution.mean (List.rev dist) in
  List.iter2 (Format.printf "%f %f@.") data m_x

open Cps_operators
open Infer.Particle_filter

let hmm data =
  let rec gen states data =
    match (states, data) with
    | [], y :: data -> gen [ y ] data
    | states, [] -> return states
    | pre_x :: _, y :: data ->
        let* x = sample (gaussian ~mu:pre_x ~sigma:1.0) in
        let* () = observe (gaussian ~mu:x ~sigma:1.0) y in
        gen (x :: states) data
  in
  gen [] data

let _ =
  Format.printf "@.-- HMM, CPS Particle Filter --@.";
  let data =
    Owl.Arr.(linspace 0. 20. 20 + gaussian [| 20 |])
    |> Owl.Arr.to_array |> Array.to_list
  in
  let dist = Distribution.split_list (infer hmm data) in
  let m_x = List.map Distribution.mean (List.rev dist) in
  List.iter2 (Format.printf "%f %f@.") data m_x
