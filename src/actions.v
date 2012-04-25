Require Import Common. 

Inductive type : Type :=
| Tlift : type0 -> type
| Tsum : list type -> type
| Ttuple : list type -> type. 

Variable state : Type. 
Variable element : state -> Type. 

Notation Int := (Tlift (Tint 16)).
Notation Bool := (Tlift (Tbool)).
Notation Unit := (Tlift (Tunit)). 

Section s. 
  Variable Phi : state.
  Variable primitive : element Phi -> list type -> type -> Type. 

  Section t. 
    
    Variable Var : type -> Type. 
    Inductive expr :  type -> Type :=
    | Evar : forall t (v : Var t), expr t
    | Ebuiltin : forall args res (f : builtin args res), 
                   dlist  expr (List.map Tlift args) -> 
                   expr  (Tlift res)
    | Econstant : forall  (c : constant), expr (Tlift (cst_ty c))
    | Etuple : forall l (exprs : dlist (expr) l), expr (Ttuple l)
    | Econstructor :  forall l t (cn: var l t) (arg : expr t),  expr (Tsum l)
    | Ematch : forall l t'
                 (arg : expr (Tsum l))
                 (cases : dlist (fun t => Var t -> expr t') (l))
                 (default : expr t'),
                 expr t'.
    
    Inductive action : type -> Type :=
    | Return : forall t, expr t -> action t
    | Bind :
      forall t u, 
        action  t -> 
        (Var t -> action u) -> 
        action u
    | When : forall t,  expr Bool -> action t -> action t
    | Primitive : 
      forall A args res (p : primitive A args res), 
        dlist (expr) args -> 
        action res 
    | Case : 
      forall l t t', 
        var l t -> 
        expr (Tsum l) -> 
        (Var t -> action t') -> 
        action t'. 
    
  End t. 
  
  Fixpoint eval_type (t : type) :=
    match t with 
    | Tlift t => eval_type0 t
    | Tsum l =>
        List.fold_right (fun x acc => eval_type x + acc)%type Datatypes.unit l
    | Ttuple l =>
        List.fold_right (fun x acc => eval_type x * acc)%type Datatypes.unit l
    end.    

  Notation eval_type_list := (List.fold_right (fun x acc => eval_type x * acc)%type Datatypes.unit). 
  Arguments dlist_fold' {T P E} _ _ _. 
  
  Definition eval_expr (t : type) (e : expr eval_type t) : eval_type t. 
  refine ( 
      let fix eval_expr t e {struct e}:=
          match e with
            | Evar t v => v
            | Ebuiltin args res f x => 
                let exprs := 
                    _
                in
                builtin_denotation args res f exprs                            
            | Econstant c => cst_val c
            | Etuple l exprs => 
                dlist_fold' eval_expr l exprs 
            | Econstructor l t cn arg => 
                _
            | Ematch l t' arg cases default => 
                _ 
          end 
      in eval_expr t e). 
  unfold eval_type0_list. 
  refine (
      let f := fix fold l : dlist (expr eval_type) (List.map Tlift l) -> eval_env eval_type0 l :=
      match l with 
          | nil => fun _ => tt
          | cons t q => fun args => (eval_expr _ (dlist_hd _ _ _ _ args),fold q (dlist_tl _ _ _ _  args))
      end in f args x). 
  refine (let fix fold l t (v : var l t):  eval_type t -> eval_type (Tsum  l) :=  
              match v in var l t return eval_type t -> eval_type (Tsum l) with 
                | var_0 l b => fun x => inl x
                | var_S l _ _ v'  => fun x => inr (fold _ _ v' x)
              end in fold l t1 cn (eval_expr _ arg)).
  refine (let fix fold l (cases : dlist (fun t => eval_type t -> expr eval_type t') l) :
              eval_type (Tsum l) -> 
              eval_type t' :=
              match cases with 
                | dlist_nil => fun  _ => eval_expr _ default
                | dlist_cons a b t q => fun (arg : eval_type (Tsum (a::b))) => 
                           match arg with 
                               | inl x => eval_expr _ (t x)
                               | inr x =>  fold _ q x
                           end
              end
          in fold l cases (eval_expr _ arg)
         ).

  Defined. 
  Definition Action t := forall Var, action Var t.
  Definition Expr t := forall Var, expr Var t. 
End s. 

(* Definition Const (n : Z) : Expr (Int) := *)
(*   fun _ =>  Econstant _ (Build_constant (Tint 16) (Word.repr 16 n)). *)

(* Definition Plus (E1 E2 : Expr Int) : Expr Int := *)
(*   fun _ => Ebuiltin _ (W 16 :: W 16 :: nil) _  (BI_plus 16) (dlist_cons E1 (dlist_cons E2 dlist_nil)).  *)
(* Definition App dom ran (F : Exp (dom --> ran)) (X : Exp dom) : Exp ran := *)
(*   fun _ => App' (F _) (X _). *)
(* Definition  *)
(* Section st.  *)
(*   Variable A B : Type.  *)
(*   Variable PA : A -> list type -> type -> Type.  *)
(*   Variable PB : B -> list type -> type -> Type.  *)
(*   Definition C := (A * B)%type.  *)

    
(* Arguments Bind {Phi primitive Var t u} _ _.  *)
(* Arguments Primitive {Phi primitive Var} A {args res} p _ .  *)

(* Definition register (ty : type) : effects. Admitted.  *)

(* Inductive register_ops (ty : type) : register ty -> list type -> type -> Type := *)
(*   | Write : forall E, register_ops ty E (cons ty nil) unit *)
(*   | Read  : forall E, register_ops ty E nil ty.  *)

(* Definition Num : type := Tlift (Tint 32).  *)
(* Require Import List.  *)
(* Definition Val : type := Tsum ((Ttuple (Num :: Num :: nil) :: (Ttuple (Num :: nil)) :: nil )).  *)

(* Let R := register Val.  *)
(* Definition iterate : Action R (register_ops Val) unit.  *)
(* intros Var.  *)
(* Notation "'DO' X <- A ; B" := (Bind A (fun X => B)) *)
(*   (at level 200, X ident, A at level 100, B at level 200).  *)

(* Section st.  *)

(* refine (DO X <- _ ; _).  *)
(* eapply Primitive.  *)
(* eapply Read. apply dlist_nil.  *)
(* refine (DO Y <- Case _ _ _ _ _ _ var_0 (Evar _ _  X) _ ; _).  *)

(* Focus 2.  *)


(* 2: refine (Primitive _ (register_ops Val) _ (Read R )).  *)
(* Definition mod_iterate_rule : rule [Treg Val].  *)
(* set (env := [Treg Num; Treg Num]).  *)
(* set (a := var_0 : var env (Treg Num)).  *)
(* set (b := var_S var_0 : var env (Treg Num)).  *)
(* apply (mk_rule' env).  *)

(* Definition pattern2_vector_singleton E t x := *)
(*   pattern2_vector_cons E _ t _ x pattern2_vector_nil.  *)
(* apply (pattern2_vector_singleton env).  *)
(* apply Plift.  *)
(* eapply Punion.  apply  (pattern1_disjunct_hd).  *)
(* apply ([| Pvar1 Num, Pvar1 Num |])%pattern.  *)
    
(* apply (! b <= ! a)%expr.  *)


(* Definition expr2_vector_singleton E t (x : @expr2 E t) : expr2_vector E [t] := *)
(*   dlist_cons x (@dlist_nil type2 (expr2 E)).  *)

(* apply expr2_vector_singleton.  *)
(* eapply Eset. eapply Eunion. eapply expr1_disjunct_hd.  apply ([| !a - !b, !b|])%expr.  *)
(* Defined.  *)

(* Definition mod_done_rule : rule [Treg Val].  *)
(* set (env := [Treg Num; Treg Num]).  *)
(* set (a := var_0 : var env (Treg Num)).  *)
(* set (b := var_S var_0 : var env (Treg Num)).  *)
(* apply (mk_rule' env).  *)
    
(* apply (pattern2_vector_singleton env).  *)
(* apply Plift. eapply Punion. apply pattern1_disjunct_hd.  *)
(* apply ([| Pvar1 Num, Pvar1 Num |])%pattern.  *)

(* apply (!a < !b)%expr.  *)

(* apply expr2_vector_singleton.  *)
(* apply Eset.  *)
(* apply Eunion. apply expr1_disjunct_tl. apply expr1_disjunct_hd. *)
(* apply ([| !a |])%expr.  *)
(* Defined.  *)
    
(* Definition TRS : TRS := *)
(*   {| trs_type := [Treg Val];  *)
(*      trs_rules := [mod_iterate_rule; mod_done_rule ]|}.  *)

(* Definition AA : Word.T 32 := Word.repr 32 31.  *)
(* Definition BB : Word.T 32 := Word.repr 32 3.  *)

(* Definition this_ENV : eval_env eval_type2 [Treg Num; Treg Num] := (AA, (BB, tt)).  *)

(* Eval compute in run_unfair 10 TRS ((inl this_ENV, tt)).  *)
