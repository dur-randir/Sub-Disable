#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "xs/compat.h"

STATIC OP*
disable_function_checker(pTHX_ OP *op, GV *namegv, SV *ckobj) {
    op_free(op);
    return newOP(OP_NULL, 0);
}

STATIC Perl_check_t old_entersub_checker = 0;
STATIC HV* disabled_methods;

STATIC OP*
entersub_checker(pTHX_ OP *o) {
    if (!HvARRAY(disabled_methods)) goto end;

    OP* kid = cUNOPo->op_first;
    if (!kid || kid->op_type != OP_PUSHMARK) goto end;

    kid = OpSIBLING(kid);

    if (!kid || kid->op_type != OP_CONST) goto end;
    SV* package = cSVOPx_sv(kid);

    while (OpSIBLING(kid)) {
        kid = OpSIBLING(kid);
    }

    if (kid->op_type != OP_METHOD_NAMED) goto end;
    SV* method = cMETHOPx_meth(kid);
    if (!SvPOK(method)) goto end;

    HE* hent = hv_fetch_ent(disabled_methods, package, 0, 0);
    if (!hent) goto end;

    AV* needles         = (AV*)HeVAL(hent);
    SV** needle_list    = AvARRAY(needles);
    SSize_t needle_cnt  = AvFILLp(needles);

    while (needle_cnt-- >= 0) {
        SV* needle = *(needle_list++);

        if (SvCUR(needle) != SvCUR(method)) continue;
        if (SvPVX(needle) == SvPVX(method) || memEQ(SvPVX(needle), SvPVX(method), SvCUR(needle))) {
            op_free(o);
            return newOP(OP_NULL, 0);
        }
    }

    end:
    return old_entersub_checker(aTHX_ o);
}

MODULE = Sub::Disable      PACKAGE = Sub::Disable
PROTOTYPES: DISABLE

BOOT:
{
    disabled_methods = newHV();
    wrap_op_checker(OP_ENTERSUB, entersub_checker, &old_entersub_checker);
}

void
disable_cv_call(SV* cv)
PPCODE:
{
    if (SvROK(cv)) cv = SvRV(cv);
    if (SvTYPE(cv) != SVt_PVCV) croak("Not a CODE reference");

    cv_set_call_checker((CV*)cv, disable_function_checker, cv);
    XSRETURN_UNDEF;
}

void
disable_named_call(SV* package, SV* func)
PPCODE:
{
    HV* stash = gv_stashsv(package, GV_ADD);
    HE* hent = hv_fetch_ent(stash, func, 0, 0);
    GV* glob = hent ? (GV*)HeVAL(hent) : NULL;

    if (!glob || !isGV(glob) || SvFAKE(glob)) {
        if (!glob) glob = (GV*)newSV(0);
        gv_init_sv(glob, stash, func, GV_ADDMULTI);

        if (hent) {
            SvREFCNT_inc_NN((SV*)glob);
            SvREFCNT_dec_NN(HeVAL(hent));
            HeVAL(hent) = (SV*)glob;

        } else {
            if (!hv_store_ent(stash, func, (SV*)glob, 0)) {
                SvREFCNT_dec_NN(glob);
                croak("Can't add a glob to package");
            }
        }
    }

    CV* cv = GvCV(glob);
    if (!cv) {
        cv = (CV*)newSV_type(SVt_PVCV);
        GvCV_set(glob, cv);
        CvGV_set(cv, glob);
    }

    cv_set_call_checker(cv, disable_function_checker, (SV*)cv);

    XSRETURN_UNDEF;
}

void
disable_method_call(SV* package, SV* method)
PPCODE:
{
    SV* shared_method_sv;

    if (!SvIsCOW_shared_hash(method)) {
        STRLEN len;
        const char* method_buf = SvPV_const(method, len);
        shared_method_sv = newSVpvn_share(method_buf, SvUTF8(method) ? -(I32)len : (I32)len, 0);
    } else {
        shared_method_sv = method;
        share_hek_hek(SvSHARED_HEK_FROM_PV(SvPVX_const(shared_method_sv)));
    }

    SV** svp = hv_common(disabled_methods, package, NULL, 0, 0, HV_FETCH_LVALUE | HV_FETCH_JUST_SV | HV_FETCH_EMPTY_HE, NULL, 0);
    Perl_av_create_and_push(aTHX_ (AV**)svp, shared_method_sv);

    XSRETURN_UNDEF;
}

