/-
Copyright (c) 2024 Andrew Yang. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Andrew Yang
-/
import Mathlib.RingTheory.Noetherian
import Mathlib.Algebra.Module.LocalizedModule
import Mathlib.LinearAlgebra.Isomorphisms
import Mathlib.LinearAlgebra.FreeModule.Finite.Basic
/-!

# Finitely Presented Modules

## Main definition

- `Module.FinitePresentation`: A module is finitely presented if it is generated by some
  finite set `s` and the kernel of the presentation `Rˢ → M` is also finitely generated.

## Main results

- `Module.finitePresentation_iff_finite`: If `R` is noetherian, then f.p. iff f.g. on `R`-modules.

Suppose `0 → K → M → N → 0` is an exact sequence of `R`-modules.

- `Module.finitePresentation_of_surjective`: If `M` is f.p., `K` is f.g., then `N` is f.p.

- `Module.FinitePresentation.fg_ker`: If `M` is f.g., `N` is f.p., then `K` is f.g.

- `Module.finitePresentation_of_ker`: If `N` and `K` is f.p., then `M` is also f.p.

- `Module.FinitePresentation.isLocalizedModule_map`: If `M` and `N` are `R`-modules and `M` is f.p.,
  and `S` is a submonoid of `R`, then `Hom(Mₛ, Nₛ)` is the localization of `Hom(M, N)`.


Also the instances finite + free => f.p. => finite are also provided

## TODO
Suppose `S` is an `R`-algebra, `M` is an `S`-module. Then
1. If `S` is f.p., then `M` is `R`-f.p. implies `M` is `S`-f.p.
2. If `S` is both f.p. (as an algebra) and finite (as a module),
  then `M` is `S`-fp implies that `M` is `R`-f.p.
3. If `S` is f.p. as a module, then `S` is f.p. as an algebra.
In particular,
4. `S` is f.p. as an `R`-module iff it is f.p. as an algebra and is finite as a module.


For finitely presented algebras, see `Algebra.FinitePresentation`
in file `Mathlib.RingTheory.FinitePresentation`.
-/

section Semiring
variable (R M) [Semiring R] [AddCommMonoid M] [Module R M]

/--
A module is finitely presented if it is finitely generated by some set `s`
and the kernel of the presentation `Rˢ → M` is also finitely generated.
-/
class Module.FinitePresentation : Prop where
  out : ∃ (s : Finset M), Submodule.span R (s : Set M) = ⊤ ∧
    (LinearMap.ker (Finsupp.total s M R Subtype.val)).FG

instance (priority := 100) [h : Module.FinitePresentation R M] : Module.Finite R M := by
  obtain ⟨s, hs₁, _⟩ := h
  exact ⟨s, hs₁⟩

end Semiring

section Ring

variable (R M N) [Ring R] [AddCommGroup M] [Module R M] [AddCommGroup N] [Module R N]

-- Ideally this should be an instance but it makes mathlib much slower.
lemma Module.finitePresentation_of_finite [IsNoetherianRing R] [h : Module.Finite R M] :
    Module.FinitePresentation R M := by
  obtain ⟨s, hs⟩ := h
  exact ⟨s, hs, IsNoetherian.noetherian _⟩

lemma Module.finitePresentation_iff_finite [IsNoetherianRing R] :
    Module.FinitePresentation R M ↔ Module.Finite R M :=
  ⟨fun _ ↦ inferInstance, fun _ ↦ finitePresentation_of_finite R M⟩

variable {R M N}

lemma Module.finitePresentation_of_free_of_surjective [Module.Free R M] [Module.Finite R M]
    (l : M →ₗ[R] N)
    (hl : Function.Surjective l) (hl' : (LinearMap.ker l).FG) :
    Module.FinitePresentation R N := by
  classical
  let b := Module.Free.chooseBasis R M
  let π : Free.ChooseBasisIndex R M → (Set.finite_range (l ∘ b)).toFinset :=
    fun i ↦ ⟨l (b i), by simp⟩
  have : π.Surjective := fun ⟨x, hx⟩ ↦ by
    obtain ⟨y, rfl⟩ : ∃ a, l (b a) = x := by simpa using hx
    exact ⟨y, rfl⟩
  choose σ hσ using this
  have hπ : Subtype.val ∘ π = l ∘ b := rfl
  have hσ₁ : π ∘ σ = id := by ext i; exact congr_arg Subtype.val (hσ i)
  have hσ₂ : l ∘ b ∘ σ = Subtype.val := by ext i; exact congr_arg Subtype.val (hσ i)
  refine ⟨(Set.finite_range (l ∘ b)).toFinset,
    by simpa [Set.range_comp, LinearMap.range_eq_top], ?_⟩
  let f : M →ₗ[R] (Set.finite_range (l ∘ b)).toFinset →₀ R :=
    Finsupp.lmapDomain _ _ π ∘ₗ b.repr.toLinearMap
  convert hl'.map f
  ext x; simp only [LinearMap.mem_ker, Submodule.mem_map]
  constructor
  · intro hx
    refine ⟨b.repr.symm (x.mapDomain σ), ?_, ?_⟩
    · simp [Finsupp.apply_total, hσ₂, hx]
    · simp only [f, LinearMap.comp_apply, b.repr.apply_symm_apply,
        LinearEquiv.coe_toLinearMap, Finsupp.lmapDomain_apply]
      rw [← Finsupp.mapDomain_comp, hσ₁, Finsupp.mapDomain_id]
  · rintro ⟨y, hy, rfl⟩
    simp [f, hπ, ← Finsupp.apply_total, hy]

-- Ideally this should be an instance but it makes mathlib much slower.
variable (R M) in
lemma Module.finitePresentation_of_free [Module.Free R M] [Module.Finite R M] :
    Module.FinitePresentation R M :=
  Module.finitePresentation_of_free_of_surjective LinearMap.id (⟨·, rfl⟩)
    (by simpa using Submodule.fg_bot)

variable {ι} [_root_.Finite ι]

instance : Module.FinitePresentation R R := Module.finitePresentation_of_free _ _
instance : Module.FinitePresentation R (ι →₀ R) := Module.finitePresentation_of_free _ _
instance : Module.FinitePresentation R (ι → R) := Module.finitePresentation_of_free _ _

lemma Module.finitePresentation_of_surjective [h : Module.FinitePresentation R M] (l : M →ₗ[R] N)
    (hl : Function.Surjective l) (hl' : (LinearMap.ker l).FG) :
    Module.FinitePresentation R N := by
  classical
  obtain ⟨s, hs, hs'⟩ := h
  obtain ⟨t, ht⟩ := hl'
  have H : Function.Surjective (Finsupp.total s M R Subtype.val) :=
    LinearMap.range_eq_top.mp (by rw [Finsupp.range_total, Subtype.range_val, ← hs]; rfl)
  apply Module.finitePresentation_of_free_of_surjective (l ∘ₗ Finsupp.total s M R Subtype.val)
    (hl.comp H)
  choose σ hσ using (show _ from H)
  have : Finsupp.total s M R Subtype.val '' (σ '' t) = t := by
    simp only [Set.image_image, hσ, Set.image_id']
  rw [LinearMap.ker_comp, ← ht, ← this, ← Submodule.map_span, Submodule.comap_map_eq,
    ← Finset.coe_image]
  exact Submodule.FG.sup ⟨_, rfl⟩ hs'

lemma Module.FinitePresentation.fg_ker [Module.Finite R M]
    [h : Module.FinitePresentation R N] (l : M →ₗ[R] N) (hl : Function.Surjective l) :
    (LinearMap.ker l).FG := by
  classical
  obtain ⟨s, hs, hs'⟩ := h
  have H : Function.Surjective (Finsupp.total s N R Subtype.val) :=
    LinearMap.range_eq_top.mp (by rw [Finsupp.range_total, Subtype.range_val, ← hs]; rfl)
  obtain ⟨f, hf⟩ : ∃ f : (s →₀ R) →ₗ[R] M, l ∘ₗ f = (Finsupp.total s N R Subtype.val) := by
    choose f hf using show _ from hl
    exact ⟨Finsupp.total s M R (fun i ↦ f i), by ext; simp [hf]⟩
  have : (LinearMap.ker l).map (LinearMap.range f).mkQ = ⊤ := by
    rw [← top_le_iff]
    rintro x -
    obtain ⟨x, rfl⟩ := Submodule.mkQ_surjective _ x
    obtain ⟨y, hy⟩ := H (l x)
    rw [← hf, LinearMap.comp_apply, eq_comm, ← sub_eq_zero, ← map_sub] at hy
    exact ⟨_, hy, by simp⟩
  apply Submodule.fg_of_fg_map_of_fg_inf_ker f.range.mkQ
  · rw [this]
    exact Module.Finite.out
  · rw [Submodule.ker_mkQ, inf_comm, ← Submodule.map_comap_eq, ← LinearMap.ker_comp, hf]
    exact hs'.map f

lemma Module.FinitePresentation.fg_ker_iff [Module.FinitePresentation R M]
    (l : M →ₗ[R] N) (hl : Function.Surjective l) :
    Submodule.FG (LinearMap.ker l) ↔ Module.FinitePresentation R N :=
  ⟨finitePresentation_of_surjective l hl, fun _ ↦ fg_ker l hl⟩

lemma Module.finitePresentation_of_ker [Module.FinitePresentation R N]
    (l : M →ₗ[R] N) (hl : Function.Surjective l) [Module.FinitePresentation R (LinearMap.ker l)] :
    Module.FinitePresentation R M := by
  obtain ⟨s, hs⟩ : (⊤ : Submodule R M).FG := by
    apply Submodule.fg_of_fg_map_of_fg_inf_ker l
    · rw [Submodule.map_top, LinearMap.range_eq_top.mpr hl]; exact Module.Finite.out
    · rw [top_inf_eq, ← Submodule.fg_top]; exact Module.Finite.out
  refine ⟨s, hs, ?_⟩
  let π := Finsupp.total s M R Subtype.val
  have H : Function.Surjective π :=
    LinearMap.range_eq_top.mp (by rw [Finsupp.range_total, Subtype.range_val, ← hs]; rfl)
  have inst : Module.Finite R (LinearMap.ker (l ∘ₗ π)) := by
    constructor
    rw [Submodule.fg_top]; exact Module.FinitePresentation.fg_ker _ (hl.comp H)
  letI : AddCommGroup (LinearMap.ker (l ∘ₗ π)) := inferInstance
  let f : LinearMap.ker (l ∘ₗ π) →ₗ[R] LinearMap.ker l := LinearMap.restrict π (fun x ↦ id)
  have e : π ∘ₗ Submodule.subtype _ = Submodule.subtype _ ∘ₗ f := by ext; rfl
  have hf : Function.Surjective f := by
    rw [← LinearMap.range_eq_top]
    apply Submodule.map_injective_of_injective (Submodule.injective_subtype _)
    rw [Submodule.map_top, Submodule.range_subtype, ← LinearMap.range_comp, ← e,
      LinearMap.range_comp, Submodule.range_subtype, LinearMap.ker_comp,
      Submodule.map_comap_eq_of_surjective H]
  show (LinearMap.ker π).FG
  have : LinearMap.ker π ≤ LinearMap.ker (l ∘ₗ π) :=
    Submodule.comap_mono (f := π) (bot_le (a := LinearMap.ker l))
  rw [← inf_eq_right.mpr this, ← Submodule.range_subtype (LinearMap.ker _),
    ← Submodule.map_comap_eq, ← LinearMap.ker_comp, e, LinearMap.ker_comp f,
    LinearMap.ker_eq_bot.mpr (Submodule.injective_subtype _), Submodule.comap_bot]
  exact (Module.FinitePresentation.fg_ker f hf).map (Submodule.subtype _)

end Ring

section CommRing
open BigOperators
variable {R M N N'} [CommRing R] [AddCommGroup M] [Module R M] [AddCommGroup N] [Module R N]
variable [AddCommGroup N'] [Module R N'] (S : Submonoid R) (f : N →ₗ[R] N') [IsLocalizedModule S f]


lemma Module.FinitePresentation.exists_lift_of_isLocalizedModule
    [h : Module.FinitePresentation R M] (g : M →ₗ[R] N') :
    ∃ (h : M →ₗ[R] N) (s : S), f ∘ₗ h = s • g := by
  obtain ⟨σ, hσ, τ, hτ⟩ := h
  let π := Finsupp.total σ M R Subtype.val
  have hπ : Function.Surjective π :=
    LinearMap.range_eq_top.mp (by rw [Finsupp.range_total, Subtype.range_val, ← hσ]; rfl)
  classical
  choose s hs using IsLocalizedModule.surj S f
  let i : σ → N :=
    fun x ↦ (∏ j in σ.erase x.1, (s (g j)).2) • (s (g x)).1
  let s₀ := ∏ j in σ, (s (g j)).2
  have hi : f ∘ₗ Finsupp.total σ N R i = (s₀ • g) ∘ₗ π := by
    ext j
    simp only [LinearMap.coe_comp, Function.comp_apply, Finsupp.lsingle_apply, Finsupp.total_single,
      one_smul, LinearMap.map_smul_of_tower, ← hs, LinearMap.smul_apply, i, s₀, π]
    rw [← mul_smul, Finset.prod_erase_mul]
    exact j.prop
  have : ∀ x : τ, ∃ s : S, s • (Finsupp.total σ N R i x) = 0 := by
    intros x
    convert_to ∃ s : S, s • (Finsupp.total σ N R i x) = s • 0
    · simp only [smul_zero]
    apply IsLocalizedModule.exists_of_eq (S := S) (f := f)
    rw [← LinearMap.comp_apply, map_zero, hi, LinearMap.comp_apply]
    convert map_zero (s₀ • g)
    rw [← LinearMap.mem_ker, ← hτ]
    exact Submodule.subset_span x.prop
  choose s' hs' using this
  let s₁ := ∏ i : τ, s' i
  have : LinearMap.ker π ≤ LinearMap.ker (s₁ • Finsupp.total σ N R i) := by
    rw [← hτ, Submodule.span_le]
    intro x hxσ
    simp only [s₁]
    rw [SetLike.mem_coe, LinearMap.mem_ker, LinearMap.smul_apply,
      ← Finset.prod_erase_mul _ _ (Finset.mem_univ ⟨x, hxσ⟩), mul_smul]
    convert smul_zero _
    exact hs' ⟨x, hxσ⟩
  refine ⟨Submodule.liftQ _ _ this ∘ₗ
    (LinearMap.quotKerEquivOfSurjective _ hπ).symm.toLinearMap, s₁ * s₀, ?_⟩
  ext x
  obtain ⟨x, rfl⟩ := hπ x
  rw [← LinearMap.comp_apply, ← LinearMap.comp_apply, mul_smul, LinearMap.smul_comp, ← hi,
    ← LinearMap.comp_smul, LinearMap.comp_assoc, LinearMap.comp_assoc]
  congr 2
  convert Submodule.liftQ_mkQ _ _ this using 2
  ext x
  apply (LinearMap.quotKerEquivOfSurjective _ hπ).injective
  simp [LinearMap.quotKerEquivOfSurjective]

lemma Module.Finite.exists_smul_of_comp_eq_of_isLocalizedModule
    [hM : Module.Finite R M] (g₁ g₂ : M →ₗ[R] N) (h : f.comp g₁ = f.comp g₂) :
    ∃ (s : S), s • g₁ = s • g₂ := by
  classical
  have : ∀ x, ∃ s : S, s • g₁ x = s • g₂ x := fun x ↦
    IsLocalizedModule.exists_of_eq (S := S) (f := f) (LinearMap.congr_fun h x)
  choose s hs using this
  obtain ⟨σ, hσ⟩ := hM
  use σ.prod s
  rw [← sub_eq_zero, ← LinearMap.ker_eq_top, ← top_le_iff, ← hσ, Submodule.span_le]
  intro x hx
  simp only [SetLike.mem_coe, LinearMap.mem_ker, LinearMap.sub_apply, LinearMap.smul_apply,
    sub_eq_zero, ← Finset.prod_erase_mul σ s hx, mul_smul, hs]

lemma Module.FinitePresentation.isLocalizedModule_map
    {M' : Type*} [AddCommGroup M'] [Module R M'] (f : M →ₗ[R] M') [IsLocalizedModule S f]
    {N' : Type*} [AddCommGroup N'] [Module R N'] (g : N →ₗ[R] N') [IsLocalizedModule S g]
    [Module.FinitePresentation R M] :
      IsLocalizedModule S (IsLocalizedModule.map S f g) := by
  constructor
  · intro s
    rw [Module.End_isUnit_iff]
    have := (Module.End_isUnit_iff _).mp (IsLocalizedModule.map_units (S := S) (f := g) s)
    constructor
    · exact fun _ _ e ↦ LinearMap.ext fun m ↦ this.left (LinearMap.congr_fun e m)
    · intro h;
      use ((IsLocalizedModule.map_units (S := S) (f := g) s).unit⁻¹).1 ∘ₗ h
      ext x
      exact Module.End_isUnit_apply_inv_apply_of_isUnit
        (IsLocalizedModule.map_units (S := S) (f := g) s) (h x)
  · intro h
    obtain ⟨h', s, e⟩ := Module.FinitePresentation.exists_lift_of_isLocalizedModule S g (h ∘ₗ f)
    refine ⟨⟨h', s⟩, ?_⟩
    apply IsLocalizedModule.ringHom_ext S f (IsLocalizedModule.map_units g)
    refine e.symm.trans (by ext; simp)
  · intro h₁ h₂ e
    apply Module.Finite.exists_smul_of_comp_eq_of_isLocalizedModule S g
    ext x
    simpa using LinearMap.congr_fun e (f x)

end CommRing
