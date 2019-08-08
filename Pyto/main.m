//
//  main.m
//  Pyto
//
//  Created by Adrian Labbe on 9/16/18.
//  Modified by goodclass on 2019/4/30.
//
//  Copyright © 2018 Adrian Labbé. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "../Python/Headers/Python.h"
#if MAIN
#import "Pyto-Swift.h"
#elif WIDGET
#import "Pyto_Widget-Swift.h"
#endif
#include <dlfcn.h>

#define load(HANDLE) handle = dlopen(file.path.UTF8String, RTLD_GLOBAL);  HANDLE = handle;

/// Returns the main bundle.
NSBundle* mainBundle() {
    #if MAIN
    return [NSBundle mainBundle];
    #elif WIDGET
    // Taken from https://stackoverflow.com/a/27849695/7515957
    NSBundle *bundle = [NSBundle mainBundle];
    if ([[bundle.bundleURL pathExtension] isEqualToString:@"appex"]) {
        // Peel off two directory levels - MY_APP.app/PlugIns/MY_APP_EXTENSION.appex
        bundle = [NSBundle bundleWithURL:[[bundle.bundleURL URLByDeletingLastPathComponent] URLByDeletingLastPathComponent]];
    }
    return bundle;
    #else
    return [NSBundle mainBundle];
    #endif
}

// MARK: - BandHandle

void BandHandle(NSString *fkTitle, NSArray *nameArray, NSArray *keyArray, bool staticlib) {
    
    if (staticlib) {
        void *handle = dlopen(NULL, RTLD_LAZY);
        for( int i=0; i<nameArray.count; i++){
            NSString *fkey  = [keyArray  objectAtIndex:i];
            void *function = dlsym(handle, [NSString stringWithFormat:@"PyInit_%@",[nameArray objectAtIndex:i]].UTF8String);
            
            if (!handle || !function) {
                fprintf(stderr, "%s\n", dlerror());
            } else {
                PyImport_AppendInittab(fkey.UTF8String, function);
            }
        }
        return;
    }
    
    
    NSError *error;
    for (NSURL *bundle in [NSFileManager.defaultManager contentsOfDirectoryAtURL:mainBundle().privateFrameworksURL includingPropertiesForKeys:NULL options:NSDirectoryEnumerationSkipsHiddenFiles error:&error]) {
        
        NSURL *file = [bundle URLByAppendingPathComponent:[bundle.URLByDeletingPathExtension URLByAppendingPathExtension:@"cpython-37m-darwin.so"].lastPathComponent];
        NSString *name = file.URLByDeletingPathExtension.URLByDeletingPathExtension.lastPathComponent;
        
        void *handle = NULL;
        for( int i=0; i<nameArray.count; i++){
            NSString *fkey  = [keyArray  objectAtIndex:i];
            
            if ([name isEqualToString:[nameArray objectAtIndex:i]]){
                void *dllHandle = NULL; load(dllHandle);
                if (!handle) {
                    fprintf(stderr, "%s\n", dlerror());
                } else {
                    PyImport_AppendInittab(fkey.UTF8String, dlsym(dllHandle, [NSString stringWithFormat:@"PyInit_%@",[nameArray objectAtIndex:i]].UTF8String));
                }
                break;
            }
        }
    }
}

#if MAIN

// MARK: - Numpy

void init_numpy() {
    NSMutableArray *name = [NSMutableArray array]; NSMutableArray *key = [NSMutableArray array];
    [name addObject:@"_multiarray_umath"];  [key addObject:@"__numpy_core__multiarray_umath"];
    [name addObject:@"lapack_lite"];        [key addObject:@"__numpy_linalg_lapack_lite"];
    [name addObject:@"_umath_linalg"];      [key addObject:@"__numpy_linalg__umath_linalg"];
    [name addObject:@"fftpack_lite"];       [key addObject:@"__numpy_fft_fftpack_lite"];
    [name addObject:@"mtrand"];             [key addObject:@"__numpy_random_mtrand"];
    BandHandle(@"numpy", name, key, false);
}

// MARK: - Matplotlib

void init_matplotlib() {
    NSURL *mpl_data = [[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSAllDomainsMask].firstObject URLByAppendingPathComponent:@"mpl-data"];
    
    [NSFileManager.defaultManager removeItemAtPath:mpl_data.path error:NULL];
    
    if (![NSFileManager.defaultManager fileExistsAtPath:mpl_data.path]) {
        [NSFileManager.defaultManager createDirectoryAtPath:mpl_data.path withIntermediateDirectories:NO attributes:NULL error:NULL];
    }
    
    putenv((char *)[[NSString stringWithFormat:@"MATPLOTLIBDATA=%@", mpl_data.path] UTF8String]);
    
    for (NSURL *fileURL in [NSFileManager.defaultManager contentsOfDirectoryAtURL:[mainBundle() URLForResource:@"site-packages/matplotlib/mpl-data" withExtension:NULL] includingPropertiesForKeys:NULL options:NSDirectoryEnumerationSkipsHiddenFiles error:NULL]) {
        NSURL *newURL = [mpl_data URLByAppendingPathComponent:fileURL.lastPathComponent];
        if (![NSFileManager.defaultManager fileExistsAtPath:newURL.path]) {
            [NSFileManager.defaultManager copyItemAtURL:fileURL toURL:newURL error:NULL];
        }
    }
    
    NSMutableArray *name = [NSMutableArray array]; NSMutableArray *key = [NSMutableArray array];
    [name addObject:@"_backend_agg"];       [key addObject:@"__matplotlib_backends__backend_agg"];
    [name addObject:@"ttconv"];             [key addObject:@"__matplotlib_ttconv"];
    [name addObject:@"_tkagg"];             [key addObject:@"__matplotlib_backends__tkagg"];
    [name addObject:@"_png"];               [key addObject:@"__matplotlib__png"];
    [name addObject:@"_image"];             [key addObject:@"__matplotlib__image"];
    [name addObject:@"_contour"];           [key addObject:@"__matplotlib__contour"];
    [name addObject:@"_qhull"];             [key addObject:@"__matplotlib__qhull"];
    [name addObject:@"_tri"];               [key addObject:@"__matplotlib__tri"];
    [name addObject:@"ft2font"];            [key addObject:@"__matplotlib_ft2font"];
    [name addObject:@"_path"];              [key addObject:@"__matplotlib__path"];
    [name addObject:@"kiwisolver"];         [key addObject:@"kiwisolver"];
    BandHandle(@"matplotlib", name, key, false);
}

// MARK: - Pandas

void init_pandas(){
    NSMutableArray *name = [NSMutableArray array]; NSMutableArray *key = [NSMutableArray array];
    [name addObject:@"_move"];              [key addObject:@"__pandas_util__move"];
    [name addObject:@"_packer"];            [key addObject:@"__pandas_io_msgpack__packer"];
    [name addObject:@"_unpacker"];          [key addObject:@"__pandas_io_msgpack__unpacker"];
    [name addObject:@"_sas"];               [key addObject:@"__pandas_io_sas__sas"];
    [name addObject:@"writers"];            [key addObject:@"__pandas__libs_writers"];
    [name addObject:@"properties"];         [key addObject:@"__pandas__libs_properties"];
    [name addObject:@"interval"];           [key addObject:@"__pandas__libs_interval"];
    [name addObject:@"reduction"];          [key addObject:@"__pandas__libs_reduction"];
    [name addObject:@"lib"];                [key addObject:@"__pandas__libs_lib"];
    [name addObject:@"join"];               [key addObject:@"__pandas__libs_join"];
    [name addObject:@"testing"];            [key addObject:@"__pandas__libs_testing"];
    [name addObject:@"reshape"];            [key addObject:@"__pandas__libs_reshape"];
    [name addObject:@"internals"];          [key addObject:@"__pandas__libs_internals"];
    [name addObject:@"hashing"];            [key addObject:@"__pandas__libs_hashing"];
    [name addObject:@"missing"];            [key addObject:@"__pandas__libs_missing"];
    [name addObject:@"groupby"];            [key addObject:@"__pandas__libs_groupby"];
    [name addObject:@"parsers"];            [key addObject:@"__pandas__libs_parsers"];
    [name addObject:@"ops"];                [key addObject:@"__pandas__libs_ops"];
    [name addObject:@"indexing"];           [key addObject:@"__pandas__libs_indexing"];
    [name addObject:@"sparse"];             [key addObject:@"__pandas__libs_sparse"];
    [name addObject:@"window"];             [key addObject:@"__pandas__libs_window"];
    [name addObject:@"ccalendar"];          [key addObject:@"__pandas__libs_tslibs_ccalendar"];
    [name addObject:@"conversion"];         [key addObject:@"__pandas__libs_tslibs_conversion"];
    [name addObject:@"fields"];             [key addObject:@"__pandas__libs_tslibs_fields"];
    [name addObject:@"nattype"];            [key addObject:@"__pandas__libs_tslibs_nattype"];
    [name addObject:@"timedeltas"];         [key addObject:@"__pandas__libs_tslibs_timedeltas"];
    [name addObject:@"frequencies"];        [key addObject:@"__pandas__libs_tslibs_frequencies"];
    [name addObject:@"resolution"];         [key addObject:@"__pandas__libs_tslibs_resolution"];
    [name addObject:@"offsets"];            [key addObject:@"__pandas__libs_tslibs_offsets"];
    [name addObject:@"np_datetime"];        [key addObject:@"__pandas__libs_tslibs_np_datetime"];
    [name addObject:@"period"];             [key addObject:@"__pandas__libs_tslibs_period"];
    [name addObject:@"timezones"];          [key addObject:@"__pandas__libs_tslibs_timezones"];
    [name addObject:@"strptime"];           [key addObject:@"__pandas__libs_tslibs_strptime"];
    [name addObject:@"parsing"];            [key addObject:@"__pandas__libs_tslibs_parsing"];
    [name addObject:@"timestamps"];         [key addObject:@"__pandas__libs_tslibs_timestamps"];
    [name addObject:@"tslib"];              [key addObject:@"__pandas__libs_tslib"];
    [name addObject:@"index"];              [key addObject:@"__pandas__libs_index"];
    [name addObject:@"algos"];              [key addObject:@"__pandas__libs_algos"];
    [name addObject:@"skiplist"];           [key addObject:@"__pandas__libs_skiplist"];
    [name addObject:@"hashtable"];          [key addObject:@"__pandas__libs_hashtable"];
    [name addObject:@"json"];               [key addObject:@"__pandas__libs_json"];
    BandHandle(@"pandas", name, key, false);
}

// MARK: - Biopython

void init_biopython() {

    NSMutableArray *name = [NSMutableArray array]; NSMutableArray *key = [NSMutableArray array];
    [name addObject:@"_aligners"];              [key addObject:@"__Bio_Align__aligners"];
    [name addObject:@"_CKDTree"];               [key addObject:@"__Bio_KDTree__CKDTree"];
    [name addObject:@"_cluster"];               [key addObject:@"__Bio_Cluster__cluster"];
    [name addObject:@"_pwm"];                   [key addObject:@"__Bio_motifs__pwm"];
    [name addObject:@"cnexus"];                 [key addObject:@"__Bio_Nexus_cnexus"];
    [name addObject:@"cpairwise2"];             [key addObject:@"__Bio_cpairwise2"];
    [name addObject:@"kdtrees"];                [key addObject:@"__Bio_PDB_kdtrees"];
    [name addObject:@"qcprotmodule"];           [key addObject:@"__Bio_PDB_QCPSuperimposer_qcprotmodule"];
    [name addObject:@"trie"];                   [key addObject:@"__Bio_trie"];
    BandHandle(@"Bio", name, key, false);
}

// MARK: - LXML

void init_lxml() {
    
    NSMutableArray *name = [NSMutableArray array]; NSMutableArray *key = [NSMutableArray array];
    [name addObject:@"_elementpath"];              [key addObject:@"__lxml__elementpath"];
    [name addObject:@"builder"];                   [key addObject:@"__lxml_builder"];
    [name addObject:@"etree"];                     [key addObject:@"__lxml_etree"];
    [name addObject:@"clean"];                     [key addObject:@"__lxml_html_clean"];
    [name addObject:@"diff"];                      [key addObject:@"__lxml_html_diff"];
    [name addObject:@"objectify"];                 [key addObject:@"__lxml_objectifiy"];
    BandHandle(@"lxml", name, key, true);
}

// MARK: - SciPy

// Thanks @goodclass !!!!!!

//_lib
extern PyMODINIT_FUNC PyInit__ccallback_c(void);
extern PyMODINIT_FUNC PyInit__fpumode(void);
extern PyMODINIT_FUNC PyInit_messagestream(void);

//cluster
extern PyMODINIT_FUNC PyInit__vq(void);
extern PyMODINIT_FUNC PyInit__hierarchy(void);
extern PyMODINIT_FUNC PyInit__optimal_leaf_ordering(void);

//fftpack
extern PyMODINIT_FUNC PyInit__fftpack(void);
extern PyMODINIT_FUNC PyInit_convolve(void);

//integrate
extern PyMODINIT_FUNC PyInit__dop(void);
extern PyMODINIT_FUNC PyInit__odepack(void);
extern PyMODINIT_FUNC PyInit__quadpack(void);
extern PyMODINIT_FUNC PyInit_lsoda(void);
extern PyMODINIT_FUNC PyInit_vode(void);

//interpolate
extern PyMODINIT_FUNC PyInit__bspl(void);
extern PyMODINIT_FUNC PyInit__fitpack(void);
extern PyMODINIT_FUNC PyInit__interpolate(void);
extern PyMODINIT_FUNC PyInit__ppoly(void);
extern PyMODINIT_FUNC PyInit_dfitpack(void);
extern PyMODINIT_FUNC PyInit_interpnd(void);

//io_matlab
extern PyMODINIT_FUNC PyInit_mio5_utils(void);
extern PyMODINIT_FUNC PyInit_mio_utils(void);
extern PyMODINIT_FUNC PyInit_streams(void);

//linalg
extern PyMODINIT_FUNC PyInit__decomp_update(void);
extern PyMODINIT_FUNC PyInit__fblas(void);
extern PyMODINIT_FUNC PyInit__flapack(void);
extern PyMODINIT_FUNC PyInit__flinalg(void);
extern PyMODINIT_FUNC PyInit__interpolative(void);
extern PyMODINIT_FUNC PyInit__solve_toeplitz(void);
extern PyMODINIT_FUNC PyInit_cython_blas(void);
extern PyMODINIT_FUNC PyInit_cython_lapack(void);

//ndimage
extern PyMODINIT_FUNC PyInit__nd_image(void);
extern PyMODINIT_FUNC PyInit__ni_label(void);
extern PyMODINIT_FUNC PyInit___odrpack(void);

//optimize
extern PyMODINIT_FUNC PyInit__cobyla(void);
extern PyMODINIT_FUNC PyInit__group_columns(void);
extern PyMODINIT_FUNC PyInit__lbfgsb(void);
extern PyMODINIT_FUNC PyInit__minpack(void);
extern PyMODINIT_FUNC PyInit__nnls(void);
extern PyMODINIT_FUNC PyInit__slsqp(void);
extern PyMODINIT_FUNC PyInit__zeros(void);
extern PyMODINIT_FUNC PyInit_minpack2(void);
extern PyMODINIT_FUNC PyInit_moduleTNC(void);

extern PyMODINIT_FUNC PyInit_givens_elimination(void);
extern PyMODINIT_FUNC PyInit__trlib(void);

//signal
extern PyMODINIT_FUNC PyInit__max_len_seq_inner(void);
extern PyMODINIT_FUNC PyInit__peak_finding_utils(void);
extern PyMODINIT_FUNC PyInit__spectral(void);
extern PyMODINIT_FUNC PyInit__upfirdn_apply(void);
extern PyMODINIT_FUNC PyInit_sigtools(void);
extern PyMODINIT_FUNC PyInit_spline(void);

//sparse_csgraph
extern PyMODINIT_FUNC PyInit__min_spanning_tree(void);
extern PyMODINIT_FUNC PyInit__reordering(void);
extern PyMODINIT_FUNC PyInit__shortest_path(void);
extern PyMODINIT_FUNC PyInit__tools(void);
extern PyMODINIT_FUNC PyInit__traversal(void);
//sparse_linalg
extern PyMODINIT_FUNC PyInit__superlu(void);
extern PyMODINIT_FUNC PyInit__arpack(void);
extern PyMODINIT_FUNC PyInit__iterative(void);
//sparse
extern PyMODINIT_FUNC PyInit__csparsetools(void);
extern PyMODINIT_FUNC PyInit__sparsetools(void);

//spatial
extern PyMODINIT_FUNC PyInit__distance_wrap(void);
extern PyMODINIT_FUNC PyInit__hausdorff(void);
extern PyMODINIT_FUNC PyInit__voronoi(void);
extern PyMODINIT_FUNC PyInit_ckdtree(void);
extern PyMODINIT_FUNC PyInit_qhull(void);

//special
extern PyMODINIT_FUNC PyInit__comb(void);
extern PyMODINIT_FUNC PyInit__ellip_harm_2(void);
extern PyMODINIT_FUNC PyInit__ufuncs(void);
extern PyMODINIT_FUNC PyInit__ufuncs_cxx(void);
extern PyMODINIT_FUNC PyInit_cython_special(void);
extern PyMODINIT_FUNC PyInit_specfun(void);

//stats
extern PyMODINIT_FUNC PyInit__stats(void);
extern PyMODINIT_FUNC PyInit_mvn(void);
extern PyMODINIT_FUNC PyInit_statlib(void);

void init_scipy() {
    
    PyImport_AppendInittab("__scipy__lib__ccallback_c", &PyInit__ccallback_c);
    PyImport_AppendInittab("__scipy__lib__fpumode", &PyInit__fpumode);
    PyImport_AppendInittab("__scipy__lib_messagestream", &PyInit_messagestream);
    
    PyImport_AppendInittab("__scipy_cluster__vq", &PyInit__vq);
    PyImport_AppendInittab("__scipy_cluster__hierarchy", &PyInit__hierarchy);
    PyImport_AppendInittab("__scipy_cluster__optimal_leaf_ordering", &PyInit__optimal_leaf_ordering);
    
    PyImport_AppendInittab("__scipy_fftpack__fftpack", &PyInit__fftpack);
    PyImport_AppendInittab("__scipy_fftpack_convolve", &PyInit_convolve);
    
    PyImport_AppendInittab("__scipy_integrate__dop", &PyInit__dop);
    PyImport_AppendInittab("__scipy_integrate__odepack", &PyInit__odepack);
    PyImport_AppendInittab("__scipy_integrate__quadpack", &PyInit__quadpack);
    PyImport_AppendInittab("__scipy_integrate_lsoda", &PyInit_lsoda);
    PyImport_AppendInittab("__scipy_integrate_vode", &PyInit_vode);
    
    PyImport_AppendInittab("__scipy_interpolate__bspl", &PyInit__bspl);
    PyImport_AppendInittab("__scipy_interpolate__fitpack", &PyInit__fitpack);
    PyImport_AppendInittab("__scipy_interpolate__interpolate", &PyInit__interpolate);
    PyImport_AppendInittab("__scipy_interpolate__ppoly", &PyInit__ppoly);
    PyImport_AppendInittab("__scipy_interpolate_dfitpack", &PyInit_dfitpack);
    PyImport_AppendInittab("__scipy_interpolate_interpnd", &PyInit_interpnd);
    
    PyImport_AppendInittab("__scipy_io_matlab_mio5_utils", &PyInit_mio5_utils);
    PyImport_AppendInittab("__scipy_io_matlab_mio_utils", &PyInit_mio_utils);
    PyImport_AppendInittab("__scipy_io_matlab_streams", &PyInit_streams);
    
    PyImport_AppendInittab("__scipy_linalg__decomp_update", &PyInit__decomp_update);
    PyImport_AppendInittab("__scipy_linalg__fblas", &PyInit__fblas);
    PyImport_AppendInittab("__scipy_linalg__flapack", &PyInit__flapack);
    PyImport_AppendInittab("__scipy_linalg__flinalg", &PyInit__flinalg);
    PyImport_AppendInittab("__scipy_linalg__interpolative", &PyInit__interpolative);
    PyImport_AppendInittab("__scipy_linalg__solve_toeplitz", &PyInit__solve_toeplitz);
    PyImport_AppendInittab("__scipy_linalg_cython_blas", &PyInit_cython_blas);
    PyImport_AppendInittab("__scipy_linalg_cython_lapack", &PyInit_cython_lapack);
    
    PyImport_AppendInittab("__scipy_ndimage__nd_image", &PyInit__nd_image);
    PyImport_AppendInittab("__scipy_ndimage__ni_label", &PyInit__ni_label);
    PyImport_AppendInittab("__scipy_odr___odrpack", &PyInit___odrpack);
    
    PyImport_AppendInittab("__scipy_optimize__cobyla", &PyInit__cobyla);
    PyImport_AppendInittab("__scipy_optimize__group_columns", &PyInit__group_columns);
    PyImport_AppendInittab("__scipy_optimize__lbfgsb", &PyInit__lbfgsb);
    PyImport_AppendInittab("__scipy_optimize__minpack", &PyInit__minpack);
    PyImport_AppendInittab("__scipy_optimize__nnls", &PyInit__nnls);
    PyImport_AppendInittab("__scipy_optimize__slsqp", &PyInit__slsqp);
    PyImport_AppendInittab("__scipy_optimize__zeros", &PyInit__zeros);
    PyImport_AppendInittab("__scipy_optimize_minpack2", &PyInit_minpack2);
    PyImport_AppendInittab("__scipy_optimize_moduleTNC", &PyInit_moduleTNC);
    PyImport_AppendInittab("__scipy_optimize__lsq_givens_elimination", &PyInit_givens_elimination);
    PyImport_AppendInittab("__scipy_optimize__trlib__trlib", &PyInit__trlib);
    
    PyImport_AppendInittab("__scipy_signal__max_len_seq_inner", &PyInit__max_len_seq_inner);
    PyImport_AppendInittab("__scipy_signal__peak_finding_utils", &PyInit__peak_finding_utils);
    PyImport_AppendInittab("__scipy_signal__spectral", &PyInit__spectral);
    PyImport_AppendInittab("__scipy_signal__upfirdn_apply",  &PyInit__upfirdn_apply);
    PyImport_AppendInittab("__scipy_signal_sigtools", &PyInit_sigtools);
    PyImport_AppendInittab("__scipy_signal_spline", &PyInit_spline);
    
    PyImport_AppendInittab("__scipy_sparse_csgraph__min_spanning_tree", &PyInit__min_spanning_tree);
    PyImport_AppendInittab("__scipy_sparse_csgraph__reordering", &PyInit__reordering);
    PyImport_AppendInittab("__scipy_sparse_csgraph__shortest_path", &PyInit__shortest_path);
    PyImport_AppendInittab("__scipy_sparse_csgraph__tools", &PyInit__tools);
    PyImport_AppendInittab("__scipy_sparse_csgraph__traversal", &PyInit__traversal);
    PyImport_AppendInittab("__scipy_sparse_linalg_dsolve__superlu", &PyInit__superlu);
    PyImport_AppendInittab("__scipy_sparse_linalg_eigen_arpack__arpack", &PyInit__arpack);
    PyImport_AppendInittab("__scipy_sparse_linalg_isolve__iterative", &PyInit__iterative);
    PyImport_AppendInittab("__scipy_sparse__csparsetools", &PyInit__csparsetools);
    PyImport_AppendInittab("__scipy_sparse__sparsetools", &PyInit__sparsetools);
    
    PyImport_AppendInittab("__scipy_spatial__distance_wrap", &PyInit__distance_wrap);
    PyImport_AppendInittab("__scipy_spatial__hausdorff", &PyInit__hausdorff);
    PyImport_AppendInittab("__scipy_spatial__voronoi", &PyInit__voronoi);
    PyImport_AppendInittab("__scipy_spatial_ckdtree", &PyInit_ckdtree);
    PyImport_AppendInittab("__scipy_spatial_qhull", &PyInit_qhull);
    
    PyImport_AppendInittab("__scipy_special__comb", &PyInit__comb);
    PyImport_AppendInittab("__scipy_special__ellip_harm_2", &PyInit__ellip_harm_2);
    PyImport_AppendInittab("__scipy_special__ufuncs_cxx", &PyInit__ufuncs_cxx);
    PyImport_AppendInittab("__scipy_special__ufuncs", &PyInit__ufuncs);
    PyImport_AppendInittab("__scipy_special_cython_special", &PyInit_cython_special);
    PyImport_AppendInittab("__scipy_special_specfun", &PyInit_specfun);
    
    PyImport_AppendInittab("__scipy_stats__stats", &PyInit__stats);
    PyImport_AppendInittab("__scipy_stats_mvn", &PyInit_mvn);
    PyImport_AppendInittab("__scipy_stats_statlib", &PyInit_statlib);
}

// MARK: - SKLearn

void init_sklearn() {
    
    NSMutableArray *name = [NSMutableArray array]; NSMutableArray *key = [NSMutableArray array];
    
    [name addObject:@"_tree"];                     [key addObject:@"__sklearn_tree__tree"];
    [name addObject:@"_criterion"];                [key addObject:@"__sklearn_tree__criterion"];
    [name addObject:@"_splitter"];                 [key addObject:@"__sklearn_tree__splitter"];
    [name addObject:@"_tree_utils"];               [key addObject:@"__sklearn_tree__utils"];
    [name addObject:@"expected_mutual_info_fast"]; [key addObject:@"__sklearn_metrics_cluster_expected_mutual_info_fast"];
    [name addObject:@"pairwise_fast"];             [key addObject:@"__sklearn_metrics_pairwise_fast"];
    [name addObject:@"_gradient_boosting"];        [key addObject:@"__sklearn_ensemble__gradient_boosting"];
    [name addObject:@"_k_means"];                  [key addObject:@"__sklearn_cluster__k_means"];
    [name addObject:@"_hierarchical"];             [key addObject:@"__sklearn_cluster__hierarchical"];
    [name addObject:@"_dbscan_inner"];             [key addObject:@"__sklearn_cluster__dbscan_inner"];
    [name addObject:@"_k_means_elkan"];            [key addObject:@"__sklearn_cluster__k_means_elkan"];
    [name addObject:@"_hashing"];                  [key addObject:@"__sklearn_feature_extraction__hashing"];
    [name addObject:@"_check_build"];              [key addObject:@"__sklearn___check_build__check_build"];
    [name addObject:@"_svmlight_format"];          [key addObject:@"__sklearn_datasets__svmlight_format"];
    [name addObject:@"sgd_fast"];                  [key addObject:@"__sklearn_linear_model_sgd_fast"];
    [name addObject:@"sag_fast"];                  [key addObject:@"__sklearn_linear_model_sag_fast"];
    [name addObject:@"cd_fast"];                   [key addObject:@"__sklearn_linear_model_cd_fast"];
    [name addObject:@"arrayfuncs"];                [key addObject:@"__sklearn_utils_arrayfuncs"];
    [name addObject:@"graph_shortest_path"];       [key addObject:@"__sklearn_utils_graph_shortest_path"];
    [name addObject:@"murmurhash"];                [key addObject:@"__sklearn_utils_murmurhash"];
    [name addObject:@"sparsefuncs_fast"];          [key addObject:@"__sklearn_utils_sparsefuncs_fast"];
    [name addObject:@"fast_dict"];                 [key addObject:@"__sklearn_utils_fast_dict"];
    [name addObject:@"weight_vector"];             [key addObject:@"__sklearn_utils_weight_vector"];
    [name addObject:@"_logistic_sigmoid"];         [key addObject:@"__sklearn_utils__logistic_sigmoid"];
    [name addObject:@"seq_dataset"];               [key addObject:@"__sklearn_utils_seq_dataset"];
    [name addObject:@"lgamma"];                    [key addObject:@"__sklearn_utils_lgamma"];
    [name addObject:@"_random"];                   [key addObject:@"__sklearn_utils__random"];
    [name addObject:@"_isotonic"];                 [key addObject:@"__sklearn__isotonic"];
    [name addObject:@"libsvm"];                    [key addObject:@"__sklearn_svm_libsvm"];
    [name addObject:@"liblinear"];                 [key addObject:@"__sklearn_svm_liblinear"];
    [name addObject:@"libsvm_sparse"];             [key addObject:@"__sklearn_svm_libsvm_sparse"];
    [name addObject:@"_barnes_hut_tsne"];          [key addObject:@"__sklearn_manifold__barnes_hut_tsne"];
    [name addObject:@"_manifold_utils"];           [key addObject:@"__sklearn_manifold__utils"];
    [name addObject:@"cdnmf_fast"];                [key addObject:@"__sklearn_decomposition_cdnmf_fast"];
    [name addObject:@"_online_lda"];               [key addObject:@"__sklearn_decomposition__online_lda"];
    [name addObject:@"quad_tree"];                 [key addObject:@"__sklearn_neighbors_quad_tree"];
    [name addObject:@"typedefs"];                  [key addObject:@"__sklearn_neighbors_typedefs"];
    [name addObject:@"ball_tree"];                 [key addObject:@"__sklearn_neighbors_ball_tree"];
    [name addObject:@"dist_metrics"];              [key addObject:@"__sklearn_neighbors_dist_metrics"];
    [name addObject:@"kd_tree"];                   [key addObject:@"__sklearn_neighbors_kd_tree"];
    
    BandHandle(@"sklearn", name, key, false);
}

// MARK: - SKImage

void init_skimage() {
    
    NSMutableArray *name = [NSMutableArray array]; NSMutableArray *key = [NSMutableArray array];
    
    [name addObject:@"_ctmf"];                      [key addObject:@"__skimage_filters__ctmf"];
    [name addObject:@"bilateral_cy"];               [key addObject:@"__skimage_filters_rank_bilateral_cy"];
    [name addObject:@"generic_cy"];                 [key addObject:@"__skimage_filters_rank_generic_cy"];
    [name addObject:@"percentile_cy"];              [key addObject:@"__skimage_filters_rank_percentile_cy"];
    [name addObject:@"core_cy"];                    [key addObject:@"__skimage_filters_rank_core_cy"];
    [name addObject:@"_denoise_cy"];                [key addObject:@"__skimage_restoration__denoise_cy"];
    [name addObject:@"_unwrap_1d"];                 [key addObject:@"__skimage_restoration__unwrap_1d"];
    [name addObject:@"_unwrap_2d"];                 [key addObject:@"__skimage_restoration__unwrap_2d"];
    [name addObject:@"_nl_means_denoising"];        [key addObject:@"__skimage_restoration__nl_means_denoising"];
    [name addObject:@"_unwrap_3d"];                 [key addObject:@"__skimage_restoration__unwrap_3d"];
    [name addObject:@"_felzenszwalb_cy"];           [key addObject:@"__skimage_segmentation__felzenszwalb_cy"];
    [name addObject:@"_slic"];                      [key addObject:@"__skimage_segmentation__slic"];
    [name addObject:@"_quickshift_cy"];             [key addObject:@"__skimage_segmentation__quickshift_cy"];
    [name addObject:@"_colormixer"];                [key addObject:@"__skimage_io__plugins__colormixer"];
    [name addObject:@"_histograms"];                [key addObject:@"__skimage_io__plugins__histograms"];
    [name addObject:@"_mcp"];                       [key addObject:@"__skimage_graph__mcp"];
    [name addObject:@"_spath"];                     [key addObject:@"__skimage_graph__spath"];
    [name addObject:@"heap"];                       [key addObject:@"__skimage_graph_heap"];
    [name addObject:@"_ccomp"];                     [key addObject:@"__skimage_measure__ccomp"];
    [name addObject:@"_pnpoly"];                    [key addObject:@"__skimage_measure__pnpoly"];
    [name addObject:@"_marching_cubes_classic_cy"]; [key addObject:@"__skimage_measure__marching_cubes_classic_cy"];
    [name addObject:@"_marching_cubes_lewiner_cy"]; [key addObject:@"__skimage_measure__marching_cubes_lewiner_cy"];
    [name addObject:@"_find_contours_cy"];          [key addObject:@"__skimage_measure__find_contours_cy"];
    [name addObject:@"_moments_cy"];                [key addObject:@"__skimage_measure__moments_cy"];
    [name addObject:@"transform"];                  [key addObject:@"__skimage__shared_transform"];
    [name addObject:@"interpolation"];              [key addObject:@"__skimage__shared_interpolation"];
    [name addObject:@"geometry"];                   [key addObject:@"__skimage__shared_geometry"];
    [name addObject:@"_extrema_cy"];                [key addObject:@"__skimage_morphology__extrema_cy"];
    [name addObject:@"_skeletonize_3d_cy"];         [key addObject:@"__skimage_morphology__skeletonize_3d_cy"];
    [name addObject:@"_convex_hull"];               [key addObject:@"__skimage_morphology__convex_hull"];
    [name addObject:@"_greyreconstruct"];           [key addObject:@"__skimage_morphology__greyreconstruct"];
    [name addObject:@"_skeletonize_cy"];            [key addObject:@"__skimage_morphology__skeletonize_cy"];
    [name addObject:@"_watershed"];                 [key addObject:@"__skimage_morphology__watershed"];
    [name addObject:@"_texture"];                   [key addObject:@"__skimage_feature__texture"];
    [name addObject:@"orb_cy"];                     [key addObject:@"__skimage_feature_orb_cy"];
    [name addObject:@"_hoghistogram"];              [key addObject:@"__skimage_feature__hoghistogram"];
    [name addObject:@"brief_cy"];                   [key addObject:@"__skimage_feature_brief_cy"];
    [name addObject:@"censure_cy"];                 [key addObject:@"__skimage_feature_censure_cy"];
    [name addObject:@"_haar"];                      [key addObject:@"__skimage_feature__haar"];
    [name addObject:@"_hessian_det_appx"];          [key addObject:@"__skimage_feature__hessian_det_appx"];
    [name addObject:@"corner_cy"];                  [key addObject:@"__skimage_feature_corner_cy"];
    [name addObject:@"tifffile._tifffile"];         [key addObject:@"__skimage_external_tifffile__tifffile"];
    [name addObject:@"_warps_cy"];                  [key addObject:@"__skimage_transform__warps_cy"];
    [name addObject:@"_hough_transform"];           [key addObject:@"__skimage_transform__hough_transform"];
    [name addObject:@"_radon_transform"];           [key addObject:@"__skimage_transform__radon_transform"];
    [name addObject:@"_seam_carving"];              [key addObject:@"__skimage_transform__seam_carving"];
    [name addObject:@"_draw"];                      [key addObject:@"__skimage_draw__draw"];
    [name addObject:@"_ncut_cy"];                   [key addObject:@"__skimage_future_graph__ncut_cy"];
    
    BandHandle(@"skimage", name, key, false);
}

// MARK: - Pywt

void init_pywt() {
    
    NSMutableArray *name = [NSMutableArray array]; NSMutableArray *key = [NSMutableArray array];
    
    [name addObject:@"_cwt"];  [key addObject:@"__pywt__extensions__cwt"];
    [name addObject:@"_pywt"]; [key addObject:@"__pywt__extensions__pywt"];
    [name addObject:@"_swt"];  [key addObject:@"__pywt__extensions__swt"];
    [name addObject:@"_dwt"];  [key addObject:@"__pyimportwt__extensions__dwt"];
    
    BandHandle(@"pywt", name, key, false);
}

#endif

// MARK: - PIL

void init_pil() {
    
    NSMutableArray *name = [NSMutableArray array]; NSMutableArray *key = [NSMutableArray array];
    [name addObject:@"_imaging"];           [key addObject:@"__PIL__imaging"];
    #if !WIDGET
    [name addObject:@"_imagingft"];         [key addObject:@"__PIL__imagingft"];
    [name addObject:@"_imagingmath"];       [key addObject:@"__PIL__imagingmath"];
    [name addObject:@"_imagingmorph"];      [key addObject:@"__PIL__imagingmorph"];
    #endif
    BandHandle(@"PIL", name, key, false);
}

// MARK: - Main

#if MAIN || WIDGET
int initialize_python(int argc, char *argv[]) {
    NSBundle *macPythonBundle = [NSBundle bundleWithPath:[NSBundle.mainBundle pathForResource:@"Python3" ofType:@"framework"]];
    NSBundle *_scproxy_bundle = [NSBundle bundleWithPath:[NSBundle.mainBundle pathForResource:@"_scproxy" ofType:@"framework"]];
    if (macPythonBundle) {
        void *handle = dlopen([macPythonBundle pathForResource:@"Versions/A/Python3_Mac" ofType:NULL].UTF8String, RTLD_GLOBAL);
        if (!handle) {
            fprintf(stderr, "%s\n", dlerror());
        }
    }
    if (_scproxy_bundle) {
        void *handle = dlopen([_scproxy_bundle pathForResource:@"Versions/A/_scproxy.cpython-37m-darwin.so" ofType:NULL].UTF8String, RTLD_GLOBAL);
        
        if (!handle) {
            fprintf(stderr, "%s\n", dlerror());
        }
        
        PyImport_AppendInittab("_scproxy", dlsym(handle, "PyInit__scproxy"));
    }
    
    // MARK: - Init builtins
    #if MAIN
    init_numpy();
    init_matplotlib();
    init_pandas();
    init_biopython();
    init_lxml();
    init_scipy();
    init_sklearn();
    init_skimage();
    init_pywt();
    #endif
    init_pil();
    
    NSBundle *pythonBundle = Python.shared.bundle;
    // MARK: - Python env variables
    #if WIDGET
    putenv("PYTHONOPTIMIZE=1");
    #else
    putenv("PYTHONOPTIMIZE=");
    #endif
    putenv("PYTHONDONTWRITEBYTECODE=1");
    putenv((char *)[[NSString stringWithFormat:@"TMP=%@", NSTemporaryDirectory()] UTF8String]);
    putenv((char *)[[NSString stringWithFormat:@"PYTHONHOME=%@", pythonBundle.bundlePath] UTF8String]);
    NSString* path = [NSString stringWithFormat:@"PYTHONPATH=%@:%@:%@:%@", [mainBundle() pathForResource: @"Lib" ofType:NULL], [mainBundle() pathForResource:@"site-packages" ofType:NULL], [pythonBundle pathForResource:@"python37" ofType:NULL], [pythonBundle pathForResource:@"python37.zip" ofType:NULL]];
    #if WIDGET
    path = [path stringByAppendingString: [NSString stringWithFormat:@":%@:%@", [NSFileManager.defaultManager sharedDirectory], [NSFileManager.defaultManager.sharedDirectory URLByAppendingPathComponent:@"modules"]]];
    #endif
    putenv((char *)path.UTF8String);
    
    #if WIDGET
    NSString *certPath = [mainBundle() pathForResource:@"cacert.pem" ofType:NULL];
    putenv((char *)[[NSString stringWithFormat:@"SSL_CERT_FILE=%@", certPath] UTF8String]);
    #endif
    
    // MARK: - Init Python
    Py_SetPythonHome(Py_DecodeLocale([pythonBundle.bundlePath UTF8String], NULL));
    Py_Initialize();
    PyEval_InitThreads();
    
    wchar_t** python_argv = PyMem_RawMalloc(sizeof(wchar_t*) * argc);
    int i;
    for (i = 0; i < argc; i++) {
        python_argv[i] = Py_DecodeLocale(argv[i], NULL);
    }
    PySys_SetArgv(argc, python_argv);
    
    #if MAIN
    [Python.shared importPytoLib];
    
    // MARK: - Start the REPL that will contain all child modules
    [Python.shared runScriptAt:[[NSBundle mainBundle] URLForResource:@"scripts_runner" withExtension:@"py"]];
    
    @autoreleasepool {
        return UIApplicationMain(argc, argv, NULL, NSStringFromClass(AppDelegate.class));
    }
    #endif
    
    return 0;
}

#if MAIN
int main(int argc, char *argv[]) {
#elif WIDGET
int init_python() {
#endif
    
    #if !MAIN
    int argc = 0;
    char *argv[] = {};
    #endif
    
    return initialize_python(argc, argv);
    
}
#endif

