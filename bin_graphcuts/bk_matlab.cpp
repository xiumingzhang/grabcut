#include <mex.h>
#include <stdio.h>
#include <map>
#include <string>
#include "energy.h"
#include "maxflow.cpp"
#include "graph.cpp"

#if !defined(MX_API_VER) || MX_API_VER < 0x07030000
typedef int mwSize;
typedef int mwIndex;
#endif

#if BK_COSTTYPE == 0
typedef double EnergyType;
typedef double EnergyTermType;
mxClassID cEnergyTermClassID = mxDOUBLE_CLASS;
mxClassID cEnergyClassID     = mxDOUBLE_CLASS;
const char* cCostTypeName = "double";
#elif BK_COSTTYPE == 1
typedef int EnergyType;
typedef long long EnergyTermType;
mxClassID cEnergyTermClassID = mxINT32_CLASS;
mxClassID cEnergyClassID     = mxINT64_CLASS;
const char* cCostTypeName = "int32";
#endif

typedef Energy<EnergyTermType,EnergyTermType,EnergyType> BKEnergy;
mxClassID cLabelClassID      = mxUINT8_CLASS;
mxClassID cSiteClassID       = mxINT32_CLASS;
typedef unsigned char LabelID;
typedef int SiteID;

// MATLAB 2014a: mxCreateReference is NO LONGER AVAILABLE :(
//extern "C" mxArray *mxCreateReference(const mxArray*); // undocumented mex function

#define BK_EXPORT(func) \
	extern "C" void func(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]); \
	FuncRegistry::Entry regentry_##func(#func,func); \
	extern "C" void func(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])

#define MATLAB_ASSERT(expr,msg) if (!(expr)) { throw MatlabError(msg); }
#define MATLAB_ASSERT_ARGCOUNT(nout, nin) \
	MATLAB_ASSERT(nlhs >= nout, "Not enough output arguments, expected " #nout); \
	MATLAB_ASSERT(nlhs <= nout, "Too many output arguments, expected " #nout); \
	MATLAB_ASSERT(nrhs >= nin,  "Not enough input arguments, expected " #nin); \
	MATLAB_ASSERT(nrhs <= nin,  "Too many input arguments, expected " #nin);
#define MATLAB_ASSERT_INTYPE(arg, type) \
	MATLAB_ASSERT(mxGetClassID(prhs[arg]) == type, "Expected " #type " for input argument " #arg);
#define MATLAB_ASSERT_HANDLE(arg) \
	MATLAB_ASSERT(mxGetClassID(prhs[arg]) == mxINT32_CLASS, "Expected valid handle for argument " #arg);

struct MatlabError {
	MatlabError(const char* msg): msg(msg) { }
	const char* msg;
};

struct FuncRegistry {
	typedef void (*Func)(int, mxArray*[], int, const mxArray*[]);
	typedef std::map<std::string,Func> LookupTable;
	static LookupTable sLookup;
	struct Entry {
		Entry(const char* name, Func ptr) { sLookup[name] = ptr; }
	};
};
FuncRegistry::LookupTable FuncRegistry::sLookup;


struct BKInstanceInfo {
	BKInstanceInfo(): bk(0), dc(0), pc(0), nb(0), changed_list(0), was_minimized(false) { }
	~BKInstanceInfo() {
		if (nb) mxDestroyArray(nb);
		if (pc) mxDestroyArray(pc);
		if (dc) mxDestroyArray(dc);
		if (bk) delete bk;
		if (changed_list) delete changed_list;
	}
	BKEnergy* bk;
	mxArray* dc;
	mxArray* pc;
	mxArray* nb;
	Block<BKEnergy::node_id>* changed_list;
	bool was_minimized;
private:
};

typedef std::map<int,BKInstanceInfo> BKInstanceMap;

static int gNextInstanceID = 10001; // some start id for the first GC object
static BKInstanceMap gInstanceMap;

BKInstanceMap::mapped_type& sGetBKInstance(int id) {
	BKInstanceMap::iterator it = gInstanceMap.find(id);
	MATLAB_ASSERT(it != gInstanceMap.end(), "Invalid handle; no such bkptimization object");
	return it->second;
}

struct BKexception {
	BKexception(char* msg): message(msg) { }
	char* message;
};

void handleError(char *message)
{
	throw BKexception(message);
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	if (nrhs == 0 || !mxIsChar(prhs[0]))
		mexErrMsgTxt("Do not use bk_matlab() directly, instead use the bk functions such as BK_Create"); 
	mwSize nameLen = mxGetN(prhs[0])*sizeof(mxChar)+1;
	char funcName[512];
	mxGetString(prhs[0], funcName, nameLen); 
	FuncRegistry::LookupTable::const_iterator it = FuncRegistry::sLookup.find(funcName);
	if (it == FuncRegistry::sLookup.end())
		mexErrMsgTxt("Specified function does not exist within bk_matlab module"); 
	try {
		it->second(nlhs, plhs, nrhs-1, prhs+1);
	} catch (BKexception err) {
		mexErrMsgTxt(err.message);
	} catch (MatlabError err) {
		mexErrMsgTxt(err.msg);
	}
}


BK_EXPORT(bk_create)
{
	int instanceID = 0;
	try {
		MATLAB_ASSERT_ARGCOUNT(1,2);
		MATLAB_ASSERT_INTYPE(0,cSiteClassID);
		MATLAB_ASSERT_INTYPE(1,cSiteClassID);
		SiteID  numSites = *(SiteID*)mxGetData(prhs[0]); MATLAB_ASSERT(numSites >= 0, "Number of variables must be non-negative");
		SiteID  maxEdges = *(SiteID*)mxGetData(prhs[1]); MATLAB_ASSERT(maxEdges >= 0, "Number of edges must be non-negative");
		instanceID = gNextInstanceID++;
		BKInstanceInfo& gcinstance = gInstanceMap[instanceID];
		gcinstance.bk = new BKEnergy(numSites,maxEdges,handleError);
		gcinstance.bk->add_variable(numSites);
		gcinstance.was_minimized = false;
		mwSize outSize = 1;
		plhs[0] = mxCreateNumericArray(1, &outSize, mxINT32_CLASS, mxREAL);
		*(int*)mxGetData(plhs[0]) = instanceID;
	} catch (MatlabError) {
		if (instanceID) 
			gInstanceMap.erase(instanceID);
		throw;
	}
}

BK_EXPORT(bk_delete)
{
	MATLAB_ASSERT_HANDLE(0);
	const int* instanceIDs = (int*)mxGetData(prhs[0]);
	MATLAB_ASSERT(mxGetN(prhs[0]) == 1 || mxGetM(prhs[0]) == 1, "Input must be a scalar or a vector");
	mwIndex count = mxGetNumberOfElements(prhs[0]);
	for (mwIndex i = 0; i < count; ++i) {
		MATLAB_ASSERT(gInstanceMap.find(instanceIDs[i]) != gInstanceMap.end(), "Invalid handle (no such BK object)");
		gInstanceMap.erase(instanceIDs[i]);
	}
}

BK_EXPORT(bk_listhandles)
{
	MATLAB_ASSERT_ARGCOUNT(1,0);
	mwSize outSize = (mwSize)gInstanceMap.size();
	plhs[0] = mxCreateNumericArray(1, &outSize, mxINT32_CLASS, mxREAL);
	int* instanceIDs = (int*)mxGetData(plhs[0]);
	for (BKInstanceMap::const_iterator i = gInstanceMap.begin(); i != gInstanceMap.end(); ++i)
		*(instanceIDs++) = i->first;
}

BK_EXPORT(bk_setunary)
{
	MATLAB_ASSERT_ARGCOUNT(0,2);
	MATLAB_ASSERT_HANDLE(0);
	MATLAB_ASSERT_INTYPE(1,cEnergyTermClassID);
	BKInstanceInfo& gcinstance = sGetBKInstance(*(int*)mxGetData(prhs[0]));
	const mxArray* dc = prhs[1];

	BKEnergy* bk = gcinstance.bk;
	SiteID varcount = bk->var_num();
	// Dense data costs
	MATLAB_ASSERT(mxGetN(dc) == varcount && mxGetM(dc) == 2,
					"Numeric data cost must be 2 x NumSites in size");
	// Increment reference count on this array to avoid copy.
	// This way the BK object refers directly to the Matlab storage.
	// If the user modifies their original variable, Matlab will do a lazy copy
	// before modifying, thus making sure the pointer used here is valid and
	// still points to the original data.
	EnergyTermType* newcosts = (EnergyTermType*)mxGetData(dc);
	if (!gcinstance.was_minimized || !gcinstance.dc) {
		for (SiteID i = 0; i < varcount; ++i)
			bk->add_term1(i,newcosts[2*i],newcosts[2*i+1]);
	} else {
		EnergyTermType* oldcosts = (EnergyTermType*)mxGetData(gcinstance.dc);
		for (SiteID i = 0; i < varcount; ++i) {
			bool mark = bk->add_term1(i,newcosts[2*i]-oldcosts[2*i],newcosts[2*i+1]-oldcosts[2*i+1]);
			if (mark)
				bk->mark_node(i);
		}
	}
	if (gcinstance.dc)
		mxDestroyArray(gcinstance.dc);

    // Make a copy since MATLAB no longer supports incrementing reference 
    // count from mex extensions... I miss you mxCreateReference :(
    mxArray* dc_copy = mxDuplicateArray(dc);
    mexMakeArrayPersistent(dc_copy);
	gcinstance.dc = dc_copy;
}

BK_EXPORT(bk_setneighbors)
{
	MATLAB_ASSERT_ARGCOUNT(0,2);
	MATLAB_ASSERT_HANDLE(0);
	MATLAB_ASSERT_INTYPE(1,mxDOUBLE_CLASS);
	BKInstanceInfo& gcinstance = sGetBKInstance(*(int*)mxGetData(prhs[0]));
	BKEnergy* bk = gcinstance.bk;
	const mxArray* nb = prhs[1];
	MATLAB_ASSERT(mxIsSparse(nb), "SetNeighbors expects a sparse matrix")
	MATLAB_ASSERT(mxGetN(nb) == gcinstance.bk->var_num() && mxGetM(nb) == gcinstance.bk->var_num(),
					"Sparse neighbours array must be NumSites x NumSites in size");
	MATLAB_ASSERT(!gcinstance.was_minimized, "Cannot call SetNeighbors after Minimize");
	MATLAB_ASSERT(!gcinstance.nb, "Cannot call SetNeighbors twice on the same instance");
	MATLAB_ASSERT(!gcinstance.pc, "Cannot call SetNeighbors after SetPairwise");

	mwIndex n = (mwIndex)mxGetN(nb);
	const mwIndex* ir = mxGetIr(nb);
	const mwIndex* jc = mxGetJc(nb);
	double*        pr = mxGetPr(nb);
	mwIndex count = 0;
	bool warned = false;
	for (mwIndex c = 0; c < n; ++c) {
		mwIndex rowStart = jc[c]; 
		mwIndex rowEnd   = jc[c+1]; 
		for (mwIndex ri = rowStart; ri < rowEnd; ++ri)  {
			mwIndex r = ir[ri];
			MATLAB_ASSERT(r != c, "A site cannot neighbor itself; make sure diagonal is all zero");

			double dw = pr[count++];
#if BK_COSTTYPE == 1
			if ((double) ((int)dw) != dw && !warned) {
				mexWarnMsgTxt("Non-integer weight detected; rounding to int32");
				warned = true;
			}
#endif
			if (r < c) {
				bk->add_term2((SiteID)r, (SiteID)c, (EnergyTermType)dw);
			}
		}
	}
	// TODO: support assigning new neighbour weights via dynamic graph cuts
	//gcinstance.nb = mxCreateReference(nb);
}

BK_EXPORT(bk_setpairwise)
{
	MATLAB_ASSERT_ARGCOUNT(0,2);
	MATLAB_ASSERT_HANDLE(0);
	BKInstanceInfo& gcinstance = sGetBKInstance(*(int*)mxGetData(prhs[0]));
	BKEnergy* bk = gcinstance.bk;
	const mxArray* pc = prhs[1];
	MATLAB_ASSERT_INTYPE(1,cEnergyTermClassID);
	MATLAB_ASSERT(!mxIsSparse(pc), "Pairwise cost array must be dense, not sparse")
	MATLAB_ASSERT(mxGetN(pc) == 6, "Pairwise cost array must be NumEdges x 6 in size");
	MATLAB_ASSERT(!gcinstance.was_minimized, "Cannot call SetNeighbors after Minimize");
	MATLAB_ASSERT(!gcinstance.nb, "Cannot call SetPairwise after SetNeighbors");
	MATLAB_ASSERT(!gcinstance.pc, "Cannot call SetPairwise twice on the same instance");

	mwIndex m = (mwIndex)mxGetM(pc);
	EnergyTermType* pcdata = (EnergyTermType*)mxGetData(pc);

#if BK_COSTTYPE == 1
	int numsites = bk->var_num();
	for (mwIndex row = 0; row < m; ++row) {
		EnergyTermType i = pcdata[row+0*m];
		EnergyTermType j = pcdata[row+1*m];
		MATLAB_ASSERT((double)((SiteID)i) == i, "Non-integer SiteID detected");
		MATLAB_ASSERT((double)((SiteID)j) == j, "Non-integer SiteID detected");
		MATLAB_ASSERT((SiteID)i >= 1 && (SiteID)i <= numsites, "SiteID was outside range 1..NumSites");
		MATLAB_ASSERT((SiteID)j >= 1 && (SiteID)j <= numsites, "SiteID was outside range 1..NumSites");
	}
#endif

	for (mwIndex row = 0; row < m; ++row) {
		SiteID i =   (SiteID)pcdata[row+0*m]-1;
		SiteID j =   (SiteID)pcdata[row+1*m]-1;
		EnergyTermType e00 = pcdata[row+2*m];
		EnergyTermType e01 = pcdata[row+3*m];
		EnergyTermType e10 = pcdata[row+4*m];
		EnergyTermType e11 = pcdata[row+5*m];

		bk->add_term2(i, j, e00, e01, e10, e11);
	}
	// TODO: support assigning new pairwise costs via dynamic graph cuts
	//gcinstance.pc = mxCreateReference(pc);
}

BK_EXPORT(bk_minimize)
{
	MATLAB_ASSERT_ARGCOUNT(1,1);
	MATLAB_ASSERT_HANDLE(0);
	BKInstanceInfo& gcinstance = sGetBKInstance(*(int*)mxGetData(prhs[0]));
	EnergyType energy;
	if (!gcinstance.was_minimized) {
		energy = gcinstance.bk->minimize();
		gcinstance.was_minimized = true;
	} else {
		if (!gcinstance.changed_list)
			gcinstance.changed_list = new Block<BKEnergy::node_id>(256);
		energy = gcinstance.bk->minimize(true,gcinstance.changed_list);
	}
	mwSize outdim = 1;
	plhs[0] = mxCreateNumericArray(1, &outdim, cEnergyClassID, mxREAL);
	*(EnergyType*)mxGetData(plhs[0]) = energy;
}

BK_EXPORT(bk_getcosttype)
{
	plhs[0] = mxCreateString(cCostTypeName);
}

BK_EXPORT(bk_addvars)
{
	MATLAB_ASSERT_ARGCOUNT(1,2);
	MATLAB_ASSERT_HANDLE(0);
	MATLAB_ASSERT_INTYPE(1,cSiteClassID);
	BKInstanceInfo& gcinstance = sGetBKInstance(*(int*)mxGetData(prhs[0]));
	SiteID varnum_old = gcinstance.bk->var_num();
	SiteID  count = *(SiteID* )mxGetData(prhs[1]); MATLAB_ASSERT(count >= 1, "Number of new variables must be positive");
	SiteID id = gcinstance.bk->add_variable(count);
	if (gcinstance.dc) {
		// need to extend the old datacost table and fill the new region with zeros
		SiteID varnum_new = gcinstance.bk->var_num();
		mwSize dcdim[2] = {2,varnum_new};
		mxArray* newdch = mxCreateNumericArray(2, dcdim, cEnergyTermClassID, mxREAL);
		EnergyTermType* newdc = (EnergyTermType*)mxGetData(newdch);
		EnergyTermType* olddc = (EnergyTermType*)mxGetData(gcinstance.dc);
		for (SiteID i = 0; i < varnum_old; ++i) {
			newdc[2*i+0] = olddc[2*i+0];
			newdc[2*i+1] = olddc[2*i+1];
		}
		for (SiteID i = varnum_old; i < varnum_new; ++i) {
			newdc[2*i+0] = 0;
			newdc[2*i+1] = 0;
		}
		mxDestroyArray(gcinstance.dc);
		gcinstance.dc = newdch;
	}
	mwSize outdim = 1;
	plhs[0] = mxCreateNumericArray(1, &outdim, cSiteClassID, mxREAL);
	*(SiteID*)mxGetData(plhs[0]) = id+1; // convert C index to Matlab index
}

BK_EXPORT(bk_getlabeling)
{
	MATLAB_ASSERT_ARGCOUNT(1,1);
	MATLAB_ASSERT_HANDLE(0);
	BKInstanceInfo& gcinstance = sGetBKInstance(*(int*)mxGetData(prhs[0]));
	MATLAB_ASSERT(gcinstance.was_minimized,"GetLabeling can only be called after Minimize");
	mwSize mlcount = (mwSize)gcinstance.bk->var_num();
	plhs[0] = mxCreateNumericArray(1, &mlcount, cLabelClassID, mxREAL);
	LabelID* labeling = (LabelID*)mxGetData(plhs[0]);
	// if no changed list, straight-forward update
	if (!gcinstance.changed_list) {
		for ( SiteID i = 0; i < mlcount; ++i )
			labeling[i] = gcinstance.bk->get_var(i)+1; // convert C index to Matlab index
	} else {
		for (BKEnergy::node_id* ptr = gcinstance.changed_list->ScanFirst(); ptr; ptr = gcinstance.changed_list->ScanNext()) {
			BKEnergy::node_id i = *ptr; MATLAB_ASSERT(i>=0 && i<mlcount, "bug!!!");
			gcinstance.bk->remove_from_changed_list(i);
		}
		for ( SiteID i = 0; i < mlcount; ++i )
			labeling[i] = gcinstance.bk->get_var(i)+1; // convert C index to Matlab index
		gcinstance.changed_list->Reset();
	}
}

BK_EXPORT(bk_getnumsites)
{
	MATLAB_ASSERT_ARGCOUNT(1,1);
	MATLAB_ASSERT_HANDLE(0);
	BKInstanceInfo& gcinstance = sGetBKInstance(*(int*)mxGetData(prhs[0]));
	mwSize outdim = 1;
	plhs[0] = mxCreateNumericArray(1, &outdim, cSiteClassID, mxREAL);
	*(SiteID*)mxGetData(plhs[0]) = gcinstance.bk->var_num();
}

