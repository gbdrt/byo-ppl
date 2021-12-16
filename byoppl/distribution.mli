(** Distributions and basic statistical functions. Whenever possible samplers and log-density functions use the {{: https://ocaml.xyz/owl/owl/Owl_stats/index.html}Owl_stats} implementation. *)

type 'a t
(** Distribution type. *)

type 'a support = {
  values : 'a array;
  logits : float array;
  probs : float array;
}
(** Weighted support for discrete distributions (probabilities are stored in log scale for numerical stability). *)

val draw : 'a t -> 'a
(** Draw a sample from the distribution. *)

val logpdf : 'a t -> 'a -> float
(** [logpdf dist x] returns the value of the log-density of [dist] on [x]. *)

val get_samples : 'a t -> 'a array
(** Draw 10 000 samples from the distribution. Every call to [get_samples] returns the same array. *)

val get_support : ?shrink:bool -> 'a t -> 'a support
(** Returns the support of a discrete distribution. Raise [Invalid_argument] if support is not defined. If [shrink] is true we gather similar values to shrink the support. *)

(** {1 Basic statistical functions} *)

val mean : float t -> float
(** [mean dist] returns the mean of [dist]. *)

val mean_int : int t -> float
(** Same as [mean] for distributions over integers. *)

val var : float t -> float
(** [var dist] returns the variance of [dist]. *)

val var_int : int t -> float
(** Same as [var] for distributions over integers. *)

val std : float t -> float
(** [std dist] returns the standard deviation of [dist]. *)

val std_int : int t -> float
(** Same as [std] for distributions over integers. *)

val stats : float t -> float * float
(** [stats dist] returns the mean and standard deviation of [dist]. *)

val stats_int : int t -> float * float
(** Same as [stats] for distributions over integers. *)

val split : ('a * 'b) t -> 'a t * 'b t
(** [split dist] turns a distribution over pairs into a pair of distributions. *)

val split_list : 'a list t -> 'a t list
(** [split_list dist] turns a distribution over lists into a list of distributions. *)

val split_array : 'a array t -> 'a t array
(** [split_array dist] turns a distribution over arrays into an array of distributions. *)

(** {1 Discrete distributions} *)

val bernoulli : p:float -> int t
(** {{: https://en.wikipedia.org/wiki/Bernoulli_distribution}Bernoulli distribution} of parameter [p]. *)

val binomial : p:float -> n:int -> int t
(** {{: https://en.wikipedia.org/wiki/Binomial_distribution}Binomial distribution} of parameter [p] and [n]. *)

val dirac : v:'a -> 'a t
(** {{: https://en.wikipedia.org/wiki/Dirac_distribution}Dirac distribution} on the value [v]. *)

val support : values:'a array -> logits:float array -> 'a t
(** Distribution of a random variable which can take any value [values.(i)] with probability [exp logits.(i)] (probabilities are stored in log scale for numerical stability). *)

val uniform_support : values:'a array -> 'a t
(** Support distribution where all values are equiprobable. *)

(** {1 Continuous distributions} *)

val beta : a:float -> b:float -> float t
(** {{: https://en.wikipedia.org/wiki/Beta_distribution}Beta distribution} with parameters [a] and [b]. *)

val gaussian : mu:float -> sigma:float -> float t
(** {{: https://en.wikipedia.org/wiki/Normal_distribution}Gaussian distribution} with mean [mu] and standard deviation [sigma]. *)

val uniform : a:float -> b:float -> float t
(** {{: https://en.wikipedia.org/wiki/Continuous_uniform_distribution}Uniform distribution} on the segment [[a, b]]. *)
