/*
** bervaluetmap.i
**
** converts BerValue structs to perl SVs
*/

make_in_OUTPUT(BerValue *);
%typemap(argout) BerValue ** OUTPUTSTR {
    if (argvi >= items) EXTEND(sp, 1);
    if (*($1) && (*($1))->bv_val) {
	$result = sv_2mortal(newSVpvn((*($1))->bv_val, (*($1))->bv_len));
	ber_bvfree(*($1));
    }
    else
	$result = &PL_sv_undef;
    argvi++;
}

%typemap(out) BerValue {
    if (($1).bv_val)
	ST(argvi) = sv_2mortal(newSVpvn(($1).bv_val, ($1).bv_len));
    else
	ST(argvi) = &PL_sv_undef;
    argvi++;
}

%typemap(in, numinputs=0) BerValue ** OUTPUTSTR (BerValue *temp) "temp=0; $1=&temp;";
%typemap(in) BerValue * (BerValue temp) %{
    if (SvROK((SV *)($input))) {
	if (SWIG_ConvertPtr($input, (void **) &$1, $1_descriptor,0) < 0) {
            SWIG_croak("Type error in argument $argnum of $symname. Expected $1_mangle or string");
        }
    }
    else if (SvOK((SV *)($input))) {
	int n;
	$1=&temp;
	temp.bv_val=SvPV((SV *)($input), n);
	temp.bv_len=n;
    }
    else {
	$1=NULL;
    }
%}

%{

static void free_BerValueARRAY(BerValue **array, int copied) {
    if (array) {
	BerValue *bv=*array;
	if (bv) {
	    if (copied) {
		char *v=bv->bv_val;
		if (v) {
		    free(v);
		}
	    }
	    free(bv);
	}
	free(array);
    }
	
}


static BerValue **RV2BerValueARRAY(SV *rv, int copy, char **croak) {
    if (SvOK(rv)) {
	if (SvROK(rv)) {
	    AV *av=(AV *)SvRV(rv);
	    if (SvTYPE(av)==SVt_PVAV) {
		int len=av_len(av)+1;
		BerValue **array=malloc(sizeof(BerValue *)*len+1);
		BerValue *bv=malloc(sizeof(BerValue)*len);
		if (array && bv) {
		    int i;
		    int clen=0;
		    for (i=0; i<len; i++) {
			SV **sv=av_fetch(av, i, 0);
			array[i]=bv+i;
			if (sv) {
			    int l;
			    bv[i].bv_val=SvPV(*sv, l);
			    bv[i].bv_len=l;
			    clen+=l+1;
			}
			else {
			    bv[i].bv_len=0;
			    bv[i].bv_val="";
			}
		    }
		    array[len]=NULL;
		    if (copy) {
			char *v=malloc(clen+1);
			if (v) {
			    for (i=0; i<len; i++) {
				int l=bv[i].bv_len;
				memcpy(v, bv[i].bv_val, l);
				bv[i].bv_val=v;
				v+=l;
				*v='\0';
				v++;
			    }
			}
			else {
			    free_BerValueARRAY(array, 0);
			    *croak="Out of memory";
			    return NULL;
			}
		    }
		    return array;
		}
		*croak="Out of memory";
		return NULL;
	    }
	}
	*croak="Type error array of scalars representing BerValues expected";
    }
    return NULL;
}

static void BerValue2RV(SV *output, void *input,
			swig_type_info *type, int flags) {
    BerValue *bv=(BerValue *)input;
    if (bv) {
	sv_setpvn(output, bv->bv_val, bv->bv_len);
    }
    else {
	sv_setref_pv(output, NULL, NULL);
    }
}

%}
