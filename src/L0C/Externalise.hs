-- | Convert an L0 program in internal representation to a
-- corresponding program in external representation.  No effort is
-- made to make the external program look pretty, but correctness and
-- performance should be preserved.
--
-- Single-element tuples are converted to their element type, not a
-- tuple.
--
-- SOACs are currently converted to the tupleless SOACs of the
-- external language, although this should probably be changed.
module L0C.Externalise
  ( externaliseProg
  )
  where

import Control.Applicative
import qualified Data.Array as A
import Data.Loc

import L0C.ExternalRep as E
import L0C.InternalRep as I

-- | Convert a program in internal representation to the corresponding
-- program in the external representation.  The number and names of
-- functions is preserved.
externaliseProg :: I.Prog -> E.Prog
externaliseProg (I.Prog funs) =
  E.Prog $ map externaliseFunction funs

externaliseFunction :: I.FunDec -> E.FunDec
externaliseFunction (fname, ret, params, body, loc) =
  (fname,
   externaliseDeclTypes ret,
   map externaliseParam params,
   externaliseBody body,
   loc)

externaliseBody :: I.Body -> E.Exp
externaliseBody (I.LetPat pat e body loc) =
  E.LetPat (externalisePat pat loc) (externaliseExp e) (externaliseBody body) loc
externaliseBody (I.LetWith cs dest src idxcs idxs ve body loc) =
  E.LetWith (externaliseCerts cs) (externaliseIdent dest) (externaliseIdent src)
            (externaliseCerts <$> idxcs) (map externaliseSubExp idxs)
            (externaliseSubExp ve) (externaliseBody body) loc
externaliseBody (I.DoLoop merge i bound loopbody letbody loc) =
  E.DoLoop (externalisePat mergepat loc) (externaliseSubExps mergeexp loc)
           (externaliseIdent i) (externaliseSubExp bound)
           (externaliseBody loopbody) (externaliseBody letbody) loc
  where (mergepat, mergeexp) = unzip merge
externaliseBody (I.Result es loc) =
  externaliseSubExps es loc

externaliseExp :: I.Exp -> E.Exp
externaliseExp (SubExp e)        = externaliseSubExp e
externaliseExp (I.TupLit es loc) = externaliseSubExps es loc
externaliseExp (I.ArrayLit es et loc) =
  E.ArrayLit (map externaliseSubExp es) (externaliseType et) loc
externaliseExp (I.Apply fname args ts loc) =
  E.Apply fname (map externaliseArg args) (externaliseTypes ts) loc
    where externaliseArg (e,d) =
            (externaliseSubExp e,
             externaliseDiet d)
externaliseExp (I.If ce tb fb t loc) =
  E.If (externaliseSubExp ce)
       (externaliseBody tb)
       (externaliseBody fb)
       (externaliseTypes t)
       loc
externaliseExp (I.BinOp bop x y t loc) =
  E.BinOp bop (externaliseSubExp x) (externaliseSubExp y)
              (externaliseType t) loc
externaliseExp (I.Not x loc) =
  E.Not (externaliseSubExp x) loc
externaliseExp (I.Negate x loc) =
  E.Negate (externaliseSubExp x) loc
externaliseExp (I.Assert x loc) =
  E.Assert (externaliseSubExp x) loc
externaliseExp (I.Conjoin es loc) =
  E.Conjoin (map externaliseSubExp es) loc
externaliseExp (I.Index cs src idxcs idxs loc) =
  E.Index (externaliseCerts cs)
          (externaliseIdent src)
          (externaliseCerts <$> idxcs)
          (map externaliseSubExp idxs)
          loc
externaliseExp (I.Size cs i e loc) =
  E.Size (externaliseCerts cs)
         i
         (externaliseSubExp e)
         loc
externaliseExp (I.Split cs ne ae loc) =
  E.Split (externaliseCerts cs)
          (externaliseSubExp ne)
          (externaliseSubExp ae)
          loc
externaliseExp (I.Concat cs x y loc) =
  E.Concat (externaliseCerts cs)
           (externaliseSubExp x)
           (externaliseSubExp y)
           loc
externaliseExp (I.Copy e loc) =
  E.Copy (externaliseSubExp e) loc
externaliseExp (I.Iota ne loc) =
  E.Iota (externaliseSubExp ne) loc
externaliseExp (I.Replicate ne ve loc) =
  E.Replicate (externaliseSubExp ne)
              (externaliseSubExp ve)
              loc
externaliseExp (I.Reshape cs shape e loc) =
  E.Reshape (externaliseCerts cs)
            (map externaliseSubExp shape)
            (externaliseSubExp e)
            loc
externaliseExp (I.Transpose cs k n e loc) =
  E.Transpose (externaliseCerts cs)
              k n
              (externaliseSubExp e)
              loc
externaliseExp (I.Map cs fun es loc) =
  E.MapT (externaliseCerts cs)
         (externaliseLambda fun)
         (map externaliseSubExp es)
         loc
externaliseExp (I.Reduce cs fun inputs loc) =
  E.ReduceT (externaliseCerts cs)
           (externaliseLambda fun)
           [ (externaliseSubExp ve, externaliseSubExp ae)
             | (ve, ae) <- inputs ]
           loc
externaliseExp (I.Scan cs fun inputs loc) =
  E.ScanT (externaliseCerts cs)
          (externaliseLambda fun)
          [ (externaliseSubExp ve, externaliseSubExp ae)
            | (ve, ae) <- inputs ]
          loc
externaliseExp (I.Filter cs fun es loc) =
  E.FilterT (externaliseCerts cs)
            (externaliseLambda fun)
            (map externaliseSubExp es)
            loc
externaliseExp (I.Redomap cs outerfun innerfun vs as loc) =
  E.RedomapT (externaliseCerts cs)
             (externaliseLambda outerfun)
             (externaliseLambda innerfun)
             (map externaliseSubExp vs)
             (map externaliseSubExp as)
             loc

externaliseLambda :: I.Lambda -> E.TupleLambda
externaliseLambda (Lambda params body ret loc) =
  E.TupleLambda (map externaliseParam params) (externaliseBody body)
                (map externaliseDeclType ret) loc

externaliseDiet :: I.Diet -> E.Diet
externaliseDiet I.Consume = E.Consume
externaliseDiet I.Observe = E.Observe

externaliseCerts :: I.Certificates -> E.Certificates
externaliseCerts = map externaliseIdent

externalisePat :: [I.Ident] -> SrcLoc -> E.TupIdent
externalisePat [v] _  = Id $ externaliseIdent v
externalisePat vs loc = TupId (map (Id . externaliseIdent) vs) loc

externaliseDeclTypes :: [I.DeclType] -> E.DeclType
externaliseDeclTypes ts =
  case map externaliseDeclType ts of
    [t]  -> t
    ts'  -> E.Elem $ E.Tuple ts'

externaliseTypes :: [I.Type] -> E.Type
externaliseTypes ts =
  case map externaliseType ts of
    [t]  -> t
    ts'  -> E.Elem $ E.Tuple ts'

externaliseDeclType :: I.DeclType -> E.DeclType
externaliseDeclType (I.Basic t) = E.Elem $ E.Basic t
externaliseDeclType (I.Array et size u ()) =
  E.Array (E.Basic et) (replicate (length size) Nothing) u NoInfo

externaliseType :: I.Type -> E.Type
externaliseType (I.Basic t) = E.Elem $ E.Basic t
externaliseType (I.Array et size u als) =
  E.Array (E.Basic et) (replicate (length size) Nothing)
          u als

externaliseSubExps :: [I.SubExp] -> SrcLoc -> E.Exp
externaliseSubExps [e] _  = externaliseSubExp e
externaliseSubExps es loc = E.TupLit (map externaliseSubExp es) loc

externaliseSubExp :: I.SubExp -> E.Exp
externaliseSubExp (I.Var v) =
  E.Var $ externaliseIdent v
externaliseSubExp (I.Constant v loc) =
  E.Literal (externaliseValue v) loc

externaliseParam :: I.Param -> E.Parameter
externaliseParam (I.Ident name t loc) =
  E.Ident name (externaliseDeclType t) loc

externaliseIdent :: I.Ident -> E.Ident
externaliseIdent (I.Ident name t loc) =
  E.Ident name (externaliseType t) loc

externaliseValue :: I.Value -> E.Value
externaliseValue (I.BasicVal bv) = E.BasicVal bv
externaliseValue (I.ArrayVal a dt) =
  E.arrayVal (map externaliseValue $ A.elems a) $
  externaliseDeclType dt