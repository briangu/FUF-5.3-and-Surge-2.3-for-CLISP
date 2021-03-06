;;; -*- Mode:Lisp; Syntax:Common-Lisp; Package: -*-
;;; -----------------------------------------------------------------------
;;; File:         complex.l
;;; Description:  Grammatical systems for complex constituents
;;; Author:       Michael Elhadad & Jacques Robin
;;; Created:      19 Dec 1991
;;; Modified:     19 Aug 1992: plural for conjunctions of > 2 elements.
;;;               ?? Feb 1993: JR added adverbials attached to clause complex
;;;                5 Jul 1995: SURGE 2.2 VERSION
;;;                            - Added generic-mood constraint on clause
;;;                              conjunction.
;;;                            - Added alt complex-populate-common
;;;                              and complex of ordinal and cardinal
;;;                              explanations on how to add conjoinable cats.
;;;                            - Added punctuation choice of others than comma
;;;               12 Oct 1997: - Added alt mood in complex clause.
;;;               27 Aug 1998: - Added alt relaters in complex clasue (YD)
;;;               25 May 2005: SURGE 2.3 VERSION
;;;                            - Added more punctuation and conjunction defaults
;;;                            - Added more possible syntactic categories for conjunction
;;;                            - Set default ellipsis in conjunction to no
;;; -----------------------------------------------------------------------

;(in-package :FUG5)

;; Complex constituents are syntactic complexes - either conjunction or
;; apposition. The type is specified as (complex T).
;; All conjuncts in a complex must be of the same cat.
;; All existing cats can be part of a complex (cf Winograd AppB).
;; The length of a complex in not limited by syntax (but obviously it
;; is by psychological factors).
;; The main features in a complex are:
;; common: all the features that MUST be common to all conjuncts.
;; distinct: the list of constituents in car/cdr form (~ macro is useful).
;; For appositions: restrictive yes/no
;; For conjunctions: conjunction (a conj).
;; NOTE: this is the generic handler for complex constructs, when no
;; more than just checking that common is indeed common and putting
;; commas and conjunctions is involved.
;; For handling cat specific phenomena (in particular ellipsis), a
;; special branch must be added for complex-clause etc...

;; Enforce a common cat for all elements of the list
;; Do NOT DO  (common ((cat {^ ^ cat}))) alone.
;; because this will fail on a conj proper + common
;; To avoid that: first thought of some hack...
;; Solution would involve defining a configuration like:
;; Instead, map from top-level cat to lowest level category for each top
;; which is a specialization of all.
;; Example:    NP
;;            /  \
;;        common proper
;;           \    /
;;          BOTTOM-NP
;; But then, you loose the information specific to each constituent
;; (common becomes bottom-np) and when you recurse on it, it will
;; do the wrong thing (lost info. that was common).  To avoid that
;; you would need to manually copy existing cats of constituents to
;; another feature (NOT through conflation)
;; something like (alt (((cat common) (np-type common)) ...))
;; and then do (cat {^ ^ common cat}) in the constituent.
;; This is really ugly... and really destroys the consistency of
;; the typing scheme (that is, you can loose information through
;; unification instead of always gaining some).
;; Instead, here is what I do here:
;; If a cat is given in a constituent, use it.
;; otherwise inherit it from common.
;; NOTE: this does not enforce the constraint of common cat for all
;; conjoints as the hack would do.
;; SO: how do you enforce the constraint?
;; SOLUTION (credit to Frank Smadja): you must realize that the
;; categories NP, AP, PP, CLAUSE have something special - they are
;; the real generic grammatical categories.  All specializations
;; are just defined for implementation reasons.  The constraint on
;; conjunction is that the generic cats are the same - not the
;; specializations.  So let's define a new feature called
;; generic-cat which will be added by each branch of the grammar.
;; And each time, we match the generic cats of all conjoints together.

;; 21 Dec 93: Same solution for the issue of mood in conjoined clauses.
;; The mood system has evolved so that "mood" now means much more than just
;; declarative or interrogative (with subtypes such as possessive-relative
;; etc).  So use a feature generic-mood to keep only the specific info
;; affecting constraints on conjunction.  [Far from trivial to determine
;; the legal combinations of moods in conjunctions.]

;; NOTE: If you want to allow for conjunctions of a new cat xx, you need to:
;; 1/ Add xx under complex in types.l
;;    (define-feature-type complex (clause verb-group np ap pp np-head adj...))
;; 2/ Add a declaration in types.l
;;    (define-feature-type xx (simple-xx complex-xx))
;; 3/ In gr-modular.l in the alt for all cats, do:
;;    ((cat simple-xx)
;;     (complex none) ...)
;; 4/ Add xx under alt complex-populate-common
;; 5/ Add xx under alt constituent-cat

(def-conj complex
  (cat #(under complex))
  (distinct given)    ;; fail if nothing specified
  (alt conj-type (:index complex)
      (((complex conjunction)
        ;; CBC - Version 2.3: Ensure the default conjunction is "and"
        (alt (((conjunction given)
               (conjunction ((cat conj))))
              ((conjunction ((cat conj) (lex "and")))))))
       ((complex apposition)
        ;; CBC - Version 2.3: Ensure the default apposition has no separator
        (alt (((conjunction given))
              ((conjunction ((cat conj) (lex ""))))))
        (restrictive ((alt (no yes)))))))

  ;; Note: we assume this cat is instantiated (use #(under complex)).
  (common ((cat {^ ^ cat})))

  ;; Pass required features into common for specific cats
  ;; Check this alt together with constituent-cat below
  (alt complex-populate-common (:index cat)
    (((cat clause)
      (common ((generic-mood {^2 generic-mood})
           ;; ME Added 17 Jul 95
           (mood {^ generic-mood})
           (scope {^2 scope})
           (restrictive {^2 restrictive}))))
     ((cat np)
      (common ((syntax ((case {^3 syntax case}))))))
     ((cat verb-group))
     ((cat ap))
     ((cat ordinal))
     ((cat cardinal))
     ((cat pp))
     ((cat np-head))
     ((cat partitive))
     ;; CBC - Version 2.3: Let date and adv categories also be involved in coordination
     ((cat date))
     ((cat adv))
     ((cat adj))))

  ;; Recurse through elements of list
  (:! list)

  ;; For complex clauses, handle global adverbials
  (opt complex-clause-adverbial
    ((cat #(under clause))
     (:! predicate-modifiers)
     (:! circumstantials)
     ;;yd change 27/8/98
     (:& relaters)
     ;; CBC - Version 2.3: Let circumstantials and predicate modifiers
     ;;                    be included when verb clauses are coordinated
     (pattern (dots stop-header dots
          front-adverbial-1 front-adverbial-2 front-adverbial-5 dots start dots stop-kernel
          end-adverbial-1 end-adverbial-2 end-adverbial-3 end-adverbial-4
          end-adverbial-5))

     ;; 12 Oct 97: ME & YD Removed old alt on mood -- put full mood here.
     ;; This fixes the bug:
     ;; "Near is the hour [when] bears bite people and dogs bite cats."
     ;; "when" did not appear because the mood of bound was never traversed.
     (:! mood)
     (cset ((- stop-header start stop-kernel)))
     (pattern (dots (* final-adverbial))))))
;;     (cset ((- final-adverbial)))
;;     (pattern (dots (* last-header) stop-header dots))
;;     (cset ((- last-header)))
;;     (pattern (dots stop-header (* next-to-header) dots)))))
;;     (cset ((- next-to-header))))))


;; DERIVE THE FEATURES OF COMPLEX CONSTITUENT FROM CONJUNCTS *****
;; Here only done for number.
(def-alt list
  (:demo "How many conjuncts are there: 0, 1, 2, or more?")
  (((distinct ((car none)))                 ;; the list is empty
    (cset ()))                              ;; do not recurse on anything
   ((distinct ((cdr ((car none)))))         ;; the list has only 1 elt
    (number {constituent number})
    (constituent ((cat ((alt (given {^ ^ common cat}))))))
    (constituent ((generic-cat {^ ^ common cat})))
    (constituent ((:! constituent-cat)))
    (constituent {^ distinct car})
    (pattern (constituent))
    (cset ((= constituent) (- common))))

   ((distinct ((cdr ((cdr ((car none))))))) ;; list has only 2 elts
    ;; Too complicated to determine when conjunction is plural
    ;; John and Mary are here.
    ;; (number plural)
    ;; CBC - Version 2.3: Repeat default coordinators
    (alt (((conjunction given))
          ((conjunction ((cat conj) (lex "and"))))))
    (alt (((pre-conj given)
           (pre-conj ((cat conj))))
          ((pre-conj ((cat conj) (lex ""))))))
    (constituent1 {^ distinct car})
    (constituent2 {^ distinct cdr car})
    (constituent1 ((:! constituent-cat)))
    (constituent2 ((:! constituent-cat)))
    (alt complex-type (:index complex)
      (((complex conjunction)
        (constituent1 ((punctuation ((after ((alt (given none))))))))
        ;; CBC - Version 2.3: Ensure joint possessors are distributed
        ;;                    across both NPs.  If it's not a pair of
        ;;                    NPs, ensure other constituents are added
        (alt (((cat common)
               (alt (((qualifier none))
                     ((qualifier given))))
               (alt (((possessor none))
                     ((possessor ((case possessive))))))
               (pattern (dots start pre-conj determiner dots possessor dots constituent1
                         conjunction constituent2 stop-kernel qualifier dots)))
              ((:! predicate-modifiers)
               (:! circumstantials)
               (pattern (dots binder dots front-adverbial-1 dots front-adverbial-2 dots
                         front-adverbial-5 dots start pre-conj determiner dots describer
                         dots constituent1 conjunction constituent2 stop-kernel qualifier
                         dots end-adverbial-1 dots end-adverbial-5 dots))))))
       ((complex apposition)
        (alt apposition-restrictive
           (((restrictive no)
             (constituent1 ((punctuation ((after ","))))))
            ((restrictive yes)
             (constituent1 ((punctuation ((after none))))))
            ((constituent1 ((punctuation ((after given))))))))
        ;; CBC - Version 2.3: Put an optional conjunction within the apposition, in
        ;;                    case odd punctuation is needed
        (pattern (dots start constituent1 conjunction constituent2 stop-kernel dots)))))
    (cset ((+ constituent1 constituent2) (- common start stop-kernel)))

    ;; Add a special treatment for clauses
    ;; Would do similar for other cases of ellipsis *****
    ;; Ellipsis for more than 2 conjuncts looks hard to do *****
        (opt ((:& ellipsis)))
   )

   ((distinct ((cdr ((cdr ((car given))))))) ;; list w/more than 3 elts
    (number plural)
    (constituent {^ distinct car})
    (constituent ((cat ((alt (given {^ ^ common cat}))))))
    (alt mult-apposition-restrictive
       ;; CBC - Version 2.3: Reinforce default punctutation
       (((restrictive no) (constituent ((:! constituent-cat)
                                        (punctuation ((after ((alt (given ",")))))))))
        ((restrictive yes) (constituent ((:! constituent-cat)
                                         (punctuation ((after ((alt (given none)))))))))))
    (rest ((cat {^ ^ cat})
           (complex {^ ^ complex})
           (common {^ ^ common})
           (restrictive {^ ^ restrictive})
           (conjunction {^ ^ conjunction})
           (distinct {^ ^ distinct cdr})))
    (pattern (dots start constituent rest stop-kernel dots))
    (cset ((+ constituent rest) (- common start stop-kernel))))))


(def-conj ellipsis
  (cat #(under clause))
  (alt verb-ellipsis (:wait process)
    (:ignore-when (;; JR-1/18/93 (cat verbal-clause)
             ({^ constituent1 complex} given)    ;; JR-10/9/92
             ({^ constituent2 complex} given)))  ;; JR-10/9/92
    ;; CBC - Version 2.3: Make default no verbal ellipsis
    (((verbal-ellipsis no))
     (({^ constituent1 process lex} given)  ;; JR-10/9/92
      ({^ constituent2 process lex} given)  ;; JR-10/9/92
      ({^ constituent1 process lex} {^4 constituent2 process lex})
      ({^ constituent2 process gap} yes)
      (verbal-ellipsis yes))))


  ;; Add ellipsis of subject
  (alt subject-ellipsis (:wait (({^ constituent1 synt-roles subject semantics} given)
                ({^ constituent2 synt-roles subject semantics} given)))
    (:ignore-when (;; JR-2/11/93 (cat verbal-clause)
             ({^ constituent1 complex} given)   ;; JR-10/9/92
             ({^ constituent2 complex} given))) ;; JR-10/9/92
    ;; CBC - Version 2.3: Make default no subject ellipsis
    (((subject-ellipsis no))
     (({^ constituent1 synt-roles subject semantics}
           {^5 constituent2 synt-roles subject semantics})
      ({^ constituent2 synt-roles subject gap} no)
      (subject-ellipsis yes)))))


;; Check this alt together with populate-common above
(def-alt constituent-cat (:index cat)
  ;; Possible cats of a constituent in a list/complex
  ;; And what features must be in common for each.
  (((cat clause)
    (generic-mood {^2 common generic-mood}) ;; all conjuncts have same mood.
    (restrictive {^2 common restrictive}))
   ((cat np)
    (syntax ((case {^3 common syntax case}))))
   ;; CANNOT HAVE JUST ((cat complex)) to catch all other cats, because
   ;; this would also work for clause and nps and remove the constraint...
   ;; CBC - Version 2.3: Added utterance, date, list and adv
   ((cat verb-group))
   ((cat utterance))
   ((cat ap))
   ((cat pp))
   ((cat np-head))
   ((cat partitive))
   ((cat date))
   ((cat cardinal))
   ((cat ordinal))
   ((cat list))
   ((cat adv))
   ((cat adj))))


;; ============================================================
(provide "complex")
;; ============================================================
