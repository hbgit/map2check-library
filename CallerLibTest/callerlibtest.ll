; ModuleID = 'callerlibtest.cpp'
source_filename = "callerlibtest.cpp"
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%"class.std::ios_base::Init" = type { i8 }
%class.Container = type { %"class.std::__cxx11::list" }
%"class.std::__cxx11::list" = type { %"class.std::__cxx11::_List_base" }
%"class.std::__cxx11::_List_base" = type { %"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl" }
%"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl" = type { %"struct.std::__detail::_List_node_header" }
%"struct.std::__detail::_List_node_header" = type { %"struct.std::__detail::_List_node_base", i64 }
%"struct.std::__detail::_List_node_base" = type { %"struct.std::__detail::_List_node_base"*, %"struct.std::__detail::_List_node_base"* }
%"class.std::basic_ostream" = type { i32 (...)**, %"class.std::basic_ios" }
%"class.std::basic_ios" = type { %"class.std::ios_base", %"class.std::basic_ostream"*, i8, i8, %"class.std::basic_streambuf"*, %"class.std::ctype"*, %"class.std::num_put"*, %"class.std::num_get"* }
%"class.std::ios_base" = type { i32 (...)**, i64, i64, i32, i32, i32, %"struct.std::ios_base::_Callback_list"*, %"struct.std::ios_base::_Words", [8 x %"struct.std::ios_base::_Words"], i32, %"struct.std::ios_base::_Words"*, %"class.std::locale" }
%"struct.std::ios_base::_Callback_list" = type { %"struct.std::ios_base::_Callback_list"*, void (i32, %"class.std::ios_base"*, i32)*, i32, i32 }
%"struct.std::ios_base::_Words" = type { i8*, i64 }
%"class.std::locale" = type { %"class.std::locale::_Impl"* }
%"class.std::locale::_Impl" = type { i32, %"class.std::locale::facet"**, i64, %"class.std::locale::facet"**, i8** }
%"class.std::locale::facet" = type <{ i32 (...)**, i32, [4 x i8] }>
%"class.std::basic_streambuf" = type { i32 (...)**, i8*, i8*, i8*, i8*, i8*, i8*, %"class.std::locale" }
%"class.std::ctype" = type <{ %"class.std::locale::facet.base", [4 x i8], %struct.__locale_struct*, i8, [7 x i8], i32*, i32*, i16*, i8, [256 x i8], [256 x i8], i8, [6 x i8] }>
%"class.std::locale::facet.base" = type <{ i32 (...)**, i32 }>
%struct.__locale_struct = type { [13 x %struct.__locale_data*], i16*, i32*, i32*, [13 x i8*] }
%struct.__locale_data = type opaque
%"class.std::num_put" = type { %"class.std::locale::facet.base", [4 x i8] }
%"class.std::num_get" = type { %"class.std::locale::facet.base", [4 x i8] }
%class.NonDetLog = type { i32, i32, %"class.boost::variant", %"class.std::__cxx11::basic_string" }
%"class.boost::variant" = type { i32, [4 x i8], %"class.boost::aligned_storage" }
%"class.boost::aligned_storage" = type { %"struct.boost::detail::aligned_storage::aligned_storage_imp" }
%"struct.boost::detail::aligned_storage::aligned_storage_imp" = type { %"union.boost::detail::aligned_storage::aligned_storage_imp<8, 8>::data_t" }
%"union.boost::detail::aligned_storage::aligned_storage_imp<8, 8>::data_t" = type { [8 x i8] }
%"class.std::__cxx11::basic_string" = type { %"struct.std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::_Alloc_hider", i64, %union.anon }
%"struct.std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::_Alloc_hider" = type { i8* }
%union.anon = type { i64, [8 x i8] }
%"struct.std::_List_iterator" = type { %"struct.std::__detail::_List_node_base"* }
%"class.std::map" = type { %"class.std::_Rb_tree" }
%"class.std::_Rb_tree" = type { %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl" }
%"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl" = type { %"struct.std::_Rb_tree_key_compare", %"struct.std::_Rb_tree_header" }
%"struct.std::_Rb_tree_key_compare" = type { %"struct.std::less" }
%"struct.std::less" = type { i8 }
%"struct.std::_Rb_tree_header" = type { %"struct.std::_Rb_tree_node_base", i64 }
%"struct.std::_Rb_tree_node_base" = type { i32, %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"* }
%"struct.std::_Rb_tree_iterator" = type { %"struct.std::_Rb_tree_node_base"* }
%"struct.std::pair" = type { i32, %class.NonDetLog }
%"class.std::allocator" = type { i8 }
%"struct.std::_List_node" = type { %"struct.std::__detail::_List_node_base", %"struct.__gnu_cxx::__aligned_membuf" }
%"struct.__gnu_cxx::__aligned_membuf" = type { [48 x i8] }
%"class.std::allocator.0" = type { i8 }
%"class.__gnu_cxx::new_allocator.1" = type { i8 }
%"struct.std::_Rb_tree_node" = type { %"struct.std::_Rb_tree_node_base", %"struct.__gnu_cxx::__aligned_membuf.6" }
%"struct.__gnu_cxx::__aligned_membuf.6" = type { [64 x i8] }
%"class.std::allocator.3" = type { i8 }
%"class.__gnu_cxx::new_allocator.4" = type { i8 }
%"struct.boost::detail::variant::destroyer" = type { i8 }
%"struct.mpl_::int_" = type { i8 }
%"struct.boost::detail::variant::visitation_impl_step" = type { i8 }
%"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_" = type { i8 }
%"struct.mpl_::bool_.7" = type { i8 }
%"struct.boost::integral_constant" = type { i8 }
%"struct.mpl_::bool_" = type { i8 }
%"struct.boost::detail::variant::apply_visitor_unrolled" = type { i8 }
%"struct.mpl_::int_.8" = type opaque
%"struct.boost::detail::variant::visitation_impl_step.9" = type { i8 }
%"class.std::__pair_base" = type { i8 }
%"class.boost::detail::variant::printer" = type { %"class.std::basic_ostream"* }
%"class.std::type_info" = type { i32 (...)**, i8* }
%"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node" = type { %"class.std::_Rb_tree"* }
%"class.boost::static_visitor" = type { i8 }
%"class.boost::detail::variant::invoke_visitor" = type { %"class.boost::detail::variant::printer"* }
%"class.boost::detail::variant::reflect" = type { i8 }
%"class.boost::detail::variant::invoke_visitor.11" = type { %"class.boost::detail::variant::reflect"* }
%"class.boost::typeindex::stl_type_index" = type { %"class.std::type_info"* }
%"class.boost::typeindex::type_index_facade" = type { i8 }
%"class.boost::detail::variant::copy_into" = type { i8* }
%"struct.std::pair.17" = type { i32, %class.NonDetLog }
%"struct.std::pair.14" = type <{ %"struct.std::_Rb_tree_iterator", i8, [7 x i8] }>
%"class.boost::detail::variant::direct_assigner" = type { i32* }
%"class.boost::static_visitor.12" = type { i8 }
%"class.boost::detail::variant::invoke_visitor.13" = type { %"class.boost::detail::variant::direct_assigner"* }
%"class.boost::variant<int, unsigned int, char, double, float>::move_assigner" = type { %"class.boost::variant<int, unsigned int, char, double, float>::assigner.base", [4 x i8] }
%"class.boost::variant<int, unsigned int, char, double, float>::assigner.base" = type <{ %"class.boost::variant"*, i32 }>
%"struct.boost::detail::variant::move_storage" = type { i8* }
%"class.boost::variant<int, unsigned int, char, double, float>::assigner" = type <{ %"class.boost::variant"*, i32, [4 x i8] }>
%"class.std::__pair_base.18" = type { i8 }
%"struct.std::pair.20" = type { %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"* }
%"struct.std::_Select1st" = type { i8 }
%"class.std::__pair_base.15" = type { i8 }
%"class.boost::detail::variant::move_into" = type { i8* }
%"class.std::__pair_base.21" = type { i8 }
%"struct.std::__allocated_ptr" = type { %"class.std::allocator.0"*, %"struct.std::_List_node"* }

$_ZN5boost7variantIiJjcdfEEC2Ev = comdat any

$_ZN9ContainerI9NonDetLogEC2Ev = comdat any

$_ZN9ContainerI9NonDetLogED2Ev = comdat any

$_ZN9ContainerI9NonDetLogE26showItemsFromContNonDetLogEv = comdat any

$_Z29add_item_map2check_nondet_logIiEvjjT_PKc = comdat any

$_ZNSt7__cxx114listISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EED2Ev = comdat any

$_ZNSt7__cxx1110_List_baseISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EED2Ev = comdat any

$_ZNSt7__cxx1110_List_baseISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE8_M_clearEv = comdat any

$_ZNSt7__cxx1110_List_baseISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE10_List_implD2Ev = comdat any

$_ZNSt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEE9_M_valptrEv = comdat any

$__clang_call_terminate = comdat any

$_ZNSt16allocator_traitsISaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEEEE7destroyIS9_EEvRSB_PT_ = comdat any

$_ZNSt7__cxx1110_List_baseISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE21_M_get_Node_allocatorEv = comdat any

$_ZNSt7__cxx1110_List_baseISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE11_M_put_nodeEPSt10_List_nodeIS9_E = comdat any

$_ZN9__gnu_cxx16__aligned_membufISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEE6_M_ptrEv = comdat any

$_ZN9__gnu_cxx16__aligned_membufISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEE7_M_addrEv = comdat any

$_ZN9__gnu_cxx13new_allocatorISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS3_EEEEE7destroyISA_EEvPT_ = comdat any

$_ZNSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS0_EEED2Ev = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EED2Ev = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE8_M_eraseEPSt13_Rb_tree_nodeIS3_E = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE8_M_beginEv = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE13_Rb_tree_implIS7_Lb1EED2Ev = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE8_S_rightEPSt18_Rb_tree_node_base = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE7_S_leftEPSt18_Rb_tree_node_base = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE12_M_drop_nodeEPSt13_Rb_tree_nodeIS3_E = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE15_M_destroy_nodeEPSt13_Rb_tree_nodeIS3_E = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE11_M_put_nodeEPSt13_Rb_tree_nodeIS3_E = comdat any

$_ZNSt16allocator_traitsISaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEE7destroyIS4_EEvRS6_PT_ = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE21_M_get_Node_allocatorEv = comdat any

$_ZNSt13_Rb_tree_nodeISt4pairIKi9NonDetLogEE9_M_valptrEv = comdat any

$_ZN9__gnu_cxx13new_allocatorISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEE7destroyIS5_EEvPT_ = comdat any

$_ZNSt4pairIKi9NonDetLogED2Ev = comdat any

$_ZN9NonDetLogD2Ev = comdat any

$_ZN5boost7variantIiJjcdfEED2Ev = comdat any

$_ZN5boost7variantIiJjcdfEE15destroy_contentEv = comdat any

$_ZN5boost15aligned_storageILm8ELm8EED2Ev = comdat any

$_ZNK5boost7variantIiJjcdfEE5whichEv = comdat any

$_ZN5boost15aligned_storageILm8ELm8EE7addressEv = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPviNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPvjNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPvcNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPvdNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPvfNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l = comdat any

$_ZN5boost6detail7variant15visitation_implIN4mpl_4int_ILi20EEENS1_20visitation_impl_stepINS_3mpl6l_iterINS7_5l_endEEESA_EENS1_9destroyerEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT1_11result_typeEiiRSH_T2_NS3_5bool_ILb1EEET3_PT_PT0_ = comdat any

$_ZNK5boost17integral_constantIbLb1EEcvRKN4mpl_5bool_ILb1EEEEv = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9destroyerEPviEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZNK5boost6detail7variant9destroyer14internal_visitIiEEvRT_i = comdat any

$_ZN5boost6detail7variant12cast_storageIiEERT_Pv = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9destroyerEPvjEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZNK5boost6detail7variant9destroyer14internal_visitIjEEvRT_i = comdat any

$_ZN5boost6detail7variant12cast_storageIjEERT_Pv = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9destroyerEPvcEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZNK5boost6detail7variant9destroyer14internal_visitIcEEvRT_i = comdat any

$_ZN5boost6detail7variant12cast_storageIcEERT_Pv = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9destroyerEPvdEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZNK5boost6detail7variant9destroyer14internal_visitIdEEvRT_i = comdat any

$_ZN5boost6detail7variant12cast_storageIdEERT_Pv = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9destroyerEPvfEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZNK5boost6detail7variant9destroyer14internal_visitIfEEvRT_i = comdat any

$_ZN5boost6detail7variant12cast_storageIfEERT_Pv = comdat any

$_ZN5boost6detail7variant13forced_returnIvEET_v = comdat any

$_ZNK5boost7variantIiJjcdfEE12using_backupEv = comdat any

$_ZNK5boost6detail15aligned_storage19aligned_storage_impILm8ELm8EE7addressEv = comdat any

$_ZN9__gnu_cxx16__aligned_membufISt4pairIKi9NonDetLogEE6_M_ptrEv = comdat any

$_ZN9__gnu_cxx16__aligned_membufISt4pairIKi9NonDetLogEE7_M_addrEv = comdat any

$_ZNSt16allocator_traitsISaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEE10deallocateERS6_PS5_m = comdat any

$_ZN9__gnu_cxx13new_allocatorISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEE10deallocateEPS6_m = comdat any

$_ZN9__gnu_cxx13new_allocatorISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEED2Ev = comdat any

$_ZNSt16allocator_traitsISaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEEEE10deallocateERSB_PSA_m = comdat any

$_ZN9__gnu_cxx13new_allocatorISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS3_EEEEE10deallocateEPSB_m = comdat any

$_ZNSaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEEED2Ev = comdat any

$_ZN9__gnu_cxx13new_allocatorISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS3_EEEEED2Ev = comdat any

$_ZN5boost15aligned_storageILm8ELm8EEC2Ev = comdat any

$_ZN5boost7variantIiJjcdfEE14indicate_whichEi = comdat any

$_ZNSt7__cxx114listISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EEC2Ev = comdat any

$_ZNSt7__cxx1110_List_baseISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EEC2Ev = comdat any

$_ZNSt7__cxx1110_List_baseISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE10_List_implC2Ev = comdat any

$_ZNSaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEEEC2Ev = comdat any

$_ZNSt8__detail17_List_node_headerC2Ev = comdat any

$_ZN9__gnu_cxx13new_allocatorISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS3_EEEEEC2Ev = comdat any

$_ZNSt8__detail17_List_node_header7_M_initEv = comdat any

$_ZNSt7__cxx114listISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE4backEv = comdat any

$_ZNKSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS0_EEE4sizeEv = comdat any

$_ZNSt7__cxx114listISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE5beginEv = comdat any

$_ZNSt7__cxx114listISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE3endEv = comdat any

$_ZStneRKSt14_List_iteratorISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEESB_ = comdat any

$_ZNKSt14_List_iteratorISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEEdeEv = comdat any

$_ZNSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS0_EEEC2ERKS7_ = comdat any

$_ZNSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS0_EEE5beginEv = comdat any

$_ZNSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS0_EEE3endEv = comdat any

$_ZStneRKSt17_Rb_tree_iteratorISt4pairIKi9NonDetLogEES6_ = comdat any

$_ZNKSt17_Rb_tree_iteratorISt4pairIKi9NonDetLogEEdeEv = comdat any

$_ZNSt4pairIKi9NonDetLogEC2ERKS2_ = comdat any

$_ZN5boostlsIcSt11char_traitsIcEiJjcdfEEERSt13basic_ostreamIT_T0_ES7_RKNS_7variantIT1_JDpT2_EEE = comdat any

$_ZN9ContainerI9NonDetLogE22getNonDetLogTypeValue_B5cxx11ES0_ = comdat any

$_ZN9NonDetLogC2ERKS_ = comdat any

$_ZNSt17_Rb_tree_iteratorISt4pairIKi9NonDetLogEEppEv = comdat any

$_ZNSt14_List_iteratorISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEEppEv = comdat any

$_ZNSt14_List_iteratorISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEEmmEv = comdat any

$_ZNKSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE4sizeEv = comdat any

$_ZNSt14_List_iteratorISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEEC2EPNSt8__detail15_List_node_baseE = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EEC2ERKS9_ = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE13_Rb_tree_implIS7_Lb1EEC2ERKSB_ = comdat any

$_ZNKSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE7_M_rootEv = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE7_M_copyERKS9_ = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE7_M_rootEv = comdat any

$_ZN9__gnu_cxx14__alloc_traitsISaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEES6_E17_S_select_on_copyERKS7_ = comdat any

$_ZNSaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEED2Ev = comdat any

$_ZNSt20_Rb_tree_key_compareISt4lessIiEEC2ERKS1_ = comdat any

$_ZNSt15_Rb_tree_headerC2Ev = comdat any

$_ZNSt16allocator_traitsISaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEE37select_on_container_copy_constructionERKS6_ = comdat any

$_ZNSaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEC2ERKS5_ = comdat any

$_ZN9__gnu_cxx13new_allocatorISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEC2ERKS7_ = comdat any

$_ZNSt15_Rb_tree_header8_M_resetEv = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE11_Alloc_nodeC2ERS9_ = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE7_M_copyINS9_11_Alloc_nodeEEEPSt13_Rb_tree_nodeIS3_ERKS9_RT_ = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE7_M_copyINS9_11_Alloc_nodeEEEPSt13_Rb_tree_nodeIS3_EPKSD_PSt18_Rb_tree_node_baseRT_ = comdat any

$_ZNKSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE8_M_beginEv = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE6_M_endEv = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE10_S_minimumEPSt18_Rb_tree_node_base = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE11_M_leftmostEv = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE10_S_maximumEPSt18_Rb_tree_node_base = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE12_M_rightmostEv = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE13_M_clone_nodeINS9_11_Alloc_nodeEEEPSt13_Rb_tree_nodeIS3_EPKSD_RT_ = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE8_S_rightEPKSt18_Rb_tree_node_base = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE7_S_leftEPKSt18_Rb_tree_node_base = comdat any

$_ZNKSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE11_Alloc_nodeclIRKS3_EEPSt13_Rb_tree_nodeIS3_EOT_ = comdat any

$_ZNKSt13_Rb_tree_nodeISt4pairIKi9NonDetLogEE9_M_valptrEv = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE14_M_create_nodeIJRKS3_EEEPSt13_Rb_tree_nodeIS3_EDpOT_ = comdat any

$_ZSt7forwardIRKSt4pairIKi9NonDetLogEEOT_RNSt16remove_referenceIS6_E4typeE = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE11_M_get_nodeEv = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE17_M_construct_nodeIJRKS3_EEEvPSt13_Rb_tree_nodeIS3_EDpOT_ = comdat any

$_ZNSt16allocator_traitsISaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEE8allocateERS6_m = comdat any

$_ZN9__gnu_cxx13new_allocatorISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEE8allocateEmPKv = comdat any

$_ZNK9__gnu_cxx13new_allocatorISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEE8max_sizeEv = comdat any

$_ZNSt16allocator_traitsISaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEE9constructIS4_JRKS4_EEEvRS6_PT_DpOT0_ = comdat any

$_ZN9__gnu_cxx13new_allocatorISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEE9constructIS5_JRKS5_EEEvPT_DpOT0_ = comdat any

$_ZNK9__gnu_cxx16__aligned_membufISt4pairIKi9NonDetLogEE6_M_ptrEv = comdat any

$_ZNK9__gnu_cxx16__aligned_membufISt4pairIKi9NonDetLogEE7_M_addrEv = comdat any

$_ZNSt18_Rb_tree_node_base10_S_minimumEPS_ = comdat any

$_ZNSt18_Rb_tree_node_base10_S_maximumEPS_ = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE5beginEv = comdat any

$_ZNSt17_Rb_tree_iteratorISt4pairIKi9NonDetLogEEC2EPSt18_Rb_tree_node_base = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE3endEv = comdat any

$_ZN5boost6detail7variant7printerISoEC2ERSo = comdat any

$_ZNKR5boost7variantIiJjcdfEE13apply_visitorINS_6detail7variant7printerISoEEEENT_11result_typeERS7_ = comdat any

$_ZN5boost6detail7variant14invoke_visitorINS1_7printerISoEELb0EEC2ERS4_ = comdat any

$_ZNK5boost15aligned_storageILm8ELm8EE7addressEv = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKviNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvjNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvcNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvdNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvfNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PNS1_22apply_visitor_unrolledET1_l = comdat any

$_ZN5boost6detail7variant15visitation_implIN4mpl_4int_ILi20EEENS1_20visitation_impl_stepINS_3mpl6l_iterINS7_5l_endEEESA_EENS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT1_11result_typeEiiRSL_T2_NS3_5bool_ILb1EEET3_PT_PT0_ = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKviEENT_11result_typeEiRS9_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZN5boost6detail7variant14invoke_visitorINS1_7printerISoEELb0EE14internal_visitIRKiEENS_12disable_if_cIXaaLb0Esr7is_sameIT_SA_EE5valueEvE4typeEOSA_i = comdat any

$_ZN5boost6detail7variant12cast_storageIiEERKT_PKv = comdat any

$_ZNK5boost6detail7variant7printerISoEclIiEEvRKT_ = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvjEENT_11result_typeEiRS9_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZN5boost6detail7variant14invoke_visitorINS1_7printerISoEELb0EE14internal_visitIRKjEENS_12disable_if_cIXaaLb0Esr7is_sameIT_SA_EE5valueEvE4typeEOSA_i = comdat any

$_ZN5boost6detail7variant12cast_storageIjEERKT_PKv = comdat any

$_ZNK5boost6detail7variant7printerISoEclIjEEvRKT_ = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvcEENT_11result_typeEiRS9_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZN5boost6detail7variant14invoke_visitorINS1_7printerISoEELb0EE14internal_visitIRKcEENS_12disable_if_cIXaaLb0Esr7is_sameIT_SA_EE5valueEvE4typeEOSA_i = comdat any

$_ZN5boost6detail7variant12cast_storageIcEERKT_PKv = comdat any

$_ZNK5boost6detail7variant7printerISoEclIcEEvRKT_ = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvdEENT_11result_typeEiRS9_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZN5boost6detail7variant14invoke_visitorINS1_7printerISoEELb0EE14internal_visitIRKdEENS_12disable_if_cIXaaLb0Esr7is_sameIT_SA_EE5valueEvE4typeEOSA_i = comdat any

$_ZN5boost6detail7variant12cast_storageIdEERKT_PKv = comdat any

$_ZNK5boost6detail7variant7printerISoEclIdEEvRKT_ = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvfEENT_11result_typeEiRS9_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZN5boost6detail7variant14invoke_visitorINS1_7printerISoEELb0EE14internal_visitIRKfEENS_12disable_if_cIXaaLb0Esr7is_sameIT_SA_EE5valueEvE4typeEOSA_i = comdat any

$_ZN5boost6detail7variant12cast_storageIfEERKT_PKv = comdat any

$_ZNK5boost6detail7variant7printerISoEclIfEEvRKT_ = comdat any

$_ZNK5boost7variantIiJjcdfEE4typeEv = comdat any

$_ZNKSt9type_infoeqERKS_ = comdat any

$_ZNKR5boost7variantIiJjcdfEE13apply_visitorINS_6detail7variant7reflectEEENT_11result_typeERS6_ = comdat any

$_ZN5boost6detail7variant14invoke_visitorINS1_7reflectELb0EEC2ERS3_ = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKviNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKvjNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKvcNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKvdNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKvfNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l = comdat any

$_ZN5boost6detail7variant15visitation_implIN4mpl_4int_ILi20EEENS1_20visitation_impl_stepINS_3mpl6l_iterINS7_5l_endEEESA_EENS1_14invoke_visitorINS1_7reflectELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT1_11result_typeEiiRSK_T2_NS3_5bool_ILb1EEET3_PT_PT0_ = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_7reflectELb0EEEPKviEENT_11result_typeEiRS8_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZN5boost6detail7variant14invoke_visitorINS1_7reflectELb0EE14internal_visitIRKiEENS_12disable_if_cIXaaLb0Esr7is_sameIT_S9_EE5valueERKSt9type_infoE4typeEOS9_i = comdat any

$_ZNK5boost6detail7variant7reflectclIiEERKSt9type_infoRKT_ = comdat any

$_ZN5boost9typeindex7type_idIiEENS0_14stl_type_indexEv = comdat any

$_ZNK5boost9typeindex14stl_type_index9type_infoEv = comdat any

$_ZN5boost9typeindex14stl_type_index7type_idIiEES1_v = comdat any

$_ZN5boost9typeindex14stl_type_indexC2ERKSt9type_info = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_7reflectELb0EEEPKvjEENT_11result_typeEiRS8_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZN5boost6detail7variant14invoke_visitorINS1_7reflectELb0EE14internal_visitIRKjEENS_12disable_if_cIXaaLb0Esr7is_sameIT_S9_EE5valueERKSt9type_infoE4typeEOS9_i = comdat any

$_ZNK5boost6detail7variant7reflectclIjEERKSt9type_infoRKT_ = comdat any

$_ZN5boost9typeindex7type_idIjEENS0_14stl_type_indexEv = comdat any

$_ZN5boost9typeindex14stl_type_index7type_idIjEES1_v = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_7reflectELb0EEEPKvcEENT_11result_typeEiRS8_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZN5boost6detail7variant14invoke_visitorINS1_7reflectELb0EE14internal_visitIRKcEENS_12disable_if_cIXaaLb0Esr7is_sameIT_S9_EE5valueERKSt9type_infoE4typeEOS9_i = comdat any

$_ZNK5boost6detail7variant7reflectclIcEERKSt9type_infoRKT_ = comdat any

$_ZN5boost9typeindex7type_idIcEENS0_14stl_type_indexEv = comdat any

$_ZN5boost9typeindex14stl_type_index7type_idIcEES1_v = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_7reflectELb0EEEPKvdEENT_11result_typeEiRS8_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZN5boost6detail7variant14invoke_visitorINS1_7reflectELb0EE14internal_visitIRKdEENS_12disable_if_cIXaaLb0Esr7is_sameIT_S9_EE5valueERKSt9type_infoE4typeEOS9_i = comdat any

$_ZNK5boost6detail7variant7reflectclIdEERKSt9type_infoRKT_ = comdat any

$_ZN5boost9typeindex7type_idIdEENS0_14stl_type_indexEv = comdat any

$_ZN5boost9typeindex14stl_type_index7type_idIdEES1_v = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_7reflectELb0EEEPKvfEENT_11result_typeEiRS8_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZN5boost6detail7variant14invoke_visitorINS1_7reflectELb0EE14internal_visitIRKfEENS_12disable_if_cIXaaLb0Esr7is_sameIT_S9_EE5valueERKSt9type_infoE4typeEOS9_i = comdat any

$_ZNK5boost6detail7variant7reflectclIfEERKSt9type_infoRKT_ = comdat any

$_ZN5boost9typeindex7type_idIfEENS0_14stl_type_indexEv = comdat any

$_ZN5boost9typeindex14stl_type_index7type_idIfEES1_v = comdat any

$_ZN5boost6detail7variant13forced_returnIRKSt9type_infoEET_v = comdat any

$_ZN5boost7variantIiJjcdfEEC2ERKS1_ = comdat any

$_ZN5boost6detail7variant9copy_intoC2EPv = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKviNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKvjNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKvcNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKvdNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKvfNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PNS1_22apply_visitor_unrolledET1_l = comdat any

$_ZN5boost6detail7variant15visitation_implIN4mpl_4int_ILi20EEENS1_20visitation_impl_stepINS_3mpl6l_iterINS7_5l_endEEESA_EENS1_9copy_intoEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT1_11result_typeEiiRSI_T2_NS3_5bool_ILb1EEET3_PT_PT0_ = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9copy_intoEPKviEENT_11result_typeEiRS6_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZNK5boost6detail7variant9copy_into14internal_visitIiEEvRKT_i = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9copy_intoEPKvjEENT_11result_typeEiRS6_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZNK5boost6detail7variant9copy_into14internal_visitIjEEvRKT_i = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9copy_intoEPKvcEENT_11result_typeEiRS6_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZNK5boost6detail7variant9copy_into14internal_visitIcEEvRKT_i = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9copy_intoEPKvdEENT_11result_typeEiRS6_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZNK5boost6detail7variant9copy_into14internal_visitIdEEvRKT_i = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9copy_intoEPKvfEENT_11result_typeEiRS6_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZNK5boost6detail7variant9copy_into14internal_visitIfEEvRKT_i = comdat any

$_ZN5boost7variantIiJjcdfEEaSIiEENS_9enable_ifINS_3mpl3or_INS_7is_sameIT_S1_EENS_6detail7variant29is_variant_constructible_fromIRKS7_NS4_6l_itemIN4mpl_5long_ILl5EEEiNSE_INSG_ILl4EEEjNSE_INSG_ILl3EEEcNSE_INSG_ILl2EEEdNSE_INSG_ILl1EEEfNS4_5l_endEEEEEEEEEEEEENSF_5bool_ILb0EEESU_SU_EERS1_E4typeESD_ = comdat any

$_ZN9ContainerI9NonDetLogE24appendContainerNondetLogEiS0_ = comdat any

$_ZN5boost7variantIiJjcdfEE6assignIiEEvRKT_ = comdat any

$_ZN5boost6detail7variant15direct_assignerIiEC2ERKi = comdat any

$_ZNR5boost7variantIiJjcdfEE13apply_visitorINS_6detail7variant15direct_assignerIiEEEENT_11result_typeERS7_ = comdat any

$_ZN5boost7variantIiJjcdfEEC2IiEERKT_PNS_9enable_ifINS_3mpl3or_INS7_4and_INS7_4not_INS_7is_sameIS3_S1_EEEENS_6detail7variant29is_variant_constructible_fromIS5_NS7_6l_itemIN4mpl_5long_ILl5EEEiNSH_INSJ_ILl4EEEjNSH_INSJ_ILl3EEEcNSH_INSJ_ILl2EEEdNSH_INSJ_ILl1EEEfNS7_5l_endEEEEEEEEEEEEENSI_5bool_ILb1EEESX_SX_EENSB_IS3_NS_18recursive_variant_EEENSW_ILb0EEES11_S11_EEvE4typeE = comdat any

$_ZN5boost7variantIiJjcdfEE14variant_assignEOS1_ = comdat any

$_ZN5boost4moveIRNS_7variantIiJjcdfEEEEEONS_11move_detail16remove_referenceIT_E4typeEOS6_ = comdat any

$_ZN5boost6detail7variant14invoke_visitorINS1_15direct_assignerIiEELb0EEC2ERS4_ = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPviNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvjNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvcNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvdNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvfNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l = comdat any

$_ZN5boost6detail7variant15visitation_implIN4mpl_4int_ILi20EEENS1_20visitation_impl_stepINS_3mpl6l_iterINS7_5l_endEEESA_EENS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT1_11result_typeEiiRSK_T2_NS3_5bool_ILb1EEET3_PT_PT0_ = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPviEENT_11result_typeEiRS8_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZN5boost6detail7variant14invoke_visitorINS1_15direct_assignerIiEELb0EE14internal_visitIRiEENS_12disable_if_cIXaaLb0Esr7is_sameIT_S9_EE5valueEbE4typeEOS9_i = comdat any

$_ZN5boost6detail7variant15direct_assignerIiEclERi = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvjEENT_11result_typeEiRS8_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZN5boost6detail7variant14invoke_visitorINS1_15direct_assignerIiEELb0EE14internal_visitIRjEENS_12disable_if_cIXaaLb0Esr7is_sameIT_S9_EE5valueEbE4typeEOS9_i = comdat any

$_ZN5boost6detail7variant15direct_assignerIiEclIjEEbRT_ = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvcEENT_11result_typeEiRS8_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZN5boost6detail7variant14invoke_visitorINS1_15direct_assignerIiEELb0EE14internal_visitIRcEENS_12disable_if_cIXaaLb0Esr7is_sameIT_S9_EE5valueEbE4typeEOS9_i = comdat any

$_ZN5boost6detail7variant15direct_assignerIiEclIcEEbRT_ = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvdEENT_11result_typeEiRS8_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZN5boost6detail7variant14invoke_visitorINS1_15direct_assignerIiEELb0EE14internal_visitIRdEENS_12disable_if_cIXaaLb0Esr7is_sameIT_S9_EE5valueEbE4typeEOS9_i = comdat any

$_ZN5boost6detail7variant15direct_assignerIiEclIdEEbRT_ = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvfEENT_11result_typeEiRS8_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZN5boost6detail7variant14invoke_visitorINS1_15direct_assignerIiEELb0EE14internal_visitIRfEENS_12disable_if_cIXaaLb0Esr7is_sameIT_S9_EE5valueEbE4typeEOS9_i = comdat any

$_ZN5boost6detail7variant15direct_assignerIiEclIfEEbRT_ = comdat any

$_ZN5boost6detail7variant13forced_returnIbEET_v = comdat any

$_ZN5boost7variantIiJjcdfEE17convert_constructIKiEEvRT_iN4mpl_5bool_ILb0EEE = comdat any

$_ZN5boost6detail7variant21make_initializer_node5applyINS_3mpl4pairINS1_16initializer_rootEN4mpl_4int_ILi0EEEEENS4_6l_iterINS4_5list5IijcdfEEEEE16initializer_node10initializeEPvRKi = comdat any

$_ZN5boost6detail7variant12move_storageC2EPv = comdat any

$_ZN5boost7variantIiJjcdfEE13move_assignerC2ERS1_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPviNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPvjNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPvcNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPvdNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPvfNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l = comdat any

$_ZN5boost6detail7variant15visitation_implIN4mpl_4int_ILi20EEENS1_20visitation_impl_stepINS_3mpl6l_iterINS7_5l_endEEESA_EENS1_12move_storageEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT1_11result_typeEiiRSH_T2_NS3_5bool_ILb1EEET3_PT_PT0_ = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_12move_storageEPviEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZNK5boost6detail7variant12move_storage14internal_visitIiEEvRT_i = comdat any

$_ZN5boost4moveIRiEEONS_11move_detail16remove_referenceIT_E4typeEOS4_ = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_12move_storageEPvjEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZNK5boost6detail7variant12move_storage14internal_visitIjEEvRT_i = comdat any

$_ZN5boost4moveIRjEEONS_11move_detail16remove_referenceIT_E4typeEOS4_ = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_12move_storageEPvcEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZNK5boost6detail7variant12move_storage14internal_visitIcEEvRT_i = comdat any

$_ZN5boost4moveIRcEEONS_11move_detail16remove_referenceIT_E4typeEOS4_ = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_12move_storageEPvdEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZNK5boost6detail7variant12move_storage14internal_visitIdEEvRT_i = comdat any

$_ZN5boost4moveIRdEEONS_11move_detail16remove_referenceIT_E4typeEOS4_ = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_12move_storageEPvfEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZNK5boost6detail7variant12move_storage14internal_visitIfEEvRT_i = comdat any

$_ZN5boost4moveIRfEEONS_11move_detail16remove_referenceIT_E4typeEOS4_ = comdat any

$_ZN5boost7variantIiJjcdfEE8assignerC2ERS1_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPviNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPvjNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPvcNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPvdNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPvfNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPvNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l = comdat any

$_ZN5boost6detail7variant15visitation_implIN4mpl_4int_ILi20EEENS1_20visitation_impl_stepINS_3mpl6l_iterINS7_5l_endEEESA_EENS_7variantIiJjcdfEE13move_assignerEPvNSD_18has_fallback_type_EEENT1_11result_typeEiiRSH_T2_NS3_5bool_ILb1EEET3_PT_PT0_ = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS_7variantIiJjcdfEE13move_assignerEPviEENT_11result_typeEiRS7_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZNK5boost7variantIiJjcdfEE13move_assigner14internal_visitIiEEvRT_i = comdat any

$_ZNK5boost7variantIiJjcdfEE13move_assigner11assign_implIiN4mpl_5bool_ILb1EEENS1_18has_fallback_type_EEEvRT_T0_S6_T1_ = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS_7variantIiJjcdfEE13move_assignerEPvjEENT_11result_typeEiRS7_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZNK5boost7variantIiJjcdfEE13move_assigner14internal_visitIjEEvRT_i = comdat any

$_ZNK5boost7variantIiJjcdfEE13move_assigner11assign_implIjN4mpl_5bool_ILb1EEENS1_18has_fallback_type_EEEvRT_T0_S6_T1_ = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS_7variantIiJjcdfEE13move_assignerEPvcEENT_11result_typeEiRS7_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZNK5boost7variantIiJjcdfEE13move_assigner14internal_visitIcEEvRT_i = comdat any

$_ZNK5boost7variantIiJjcdfEE13move_assigner11assign_implIcN4mpl_5bool_ILb1EEENS1_18has_fallback_type_EEEvRT_T0_S6_T1_ = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS_7variantIiJjcdfEE13move_assignerEPvdEENT_11result_typeEiRS7_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZNK5boost7variantIiJjcdfEE13move_assigner14internal_visitIdEEvRT_i = comdat any

$_ZNK5boost7variantIiJjcdfEE13move_assigner11assign_implIdN4mpl_5bool_ILb1EEENS1_18has_fallback_type_EEEvRT_T0_S6_T1_ = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS_7variantIiJjcdfEE13move_assignerEPvfEENT_11result_typeEiRS7_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZNK5boost7variantIiJjcdfEE13move_assigner14internal_visitIfEEvRT_i = comdat any

$_ZNK5boost7variantIiJjcdfEE13move_assigner11assign_implIfN4mpl_5bool_ILb1EEENS1_18has_fallback_type_EEEvRT_T0_S6_T1_ = comdat any

$_ZNSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS0_EEEC2Ev = comdat any

$_ZNSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS0_EEE6insertIS3_IiS0_EEENSt9enable_ifIXsr16is_constructibleIS5_T_EE5valueES3_ISt17_Rb_tree_iteratorIS5_EbEE4typeEOSB_ = comdat any

$_ZNSt4pairIi9NonDetLogEC2IRiRS0_Lb1EEEOT_OT0_ = comdat any

$_ZNSt4pairIi9NonDetLogED2Ev = comdat any

$_ZNSt7__cxx114listISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE9push_backERKS9_ = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EEC2Ev = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE13_Rb_tree_implIS7_Lb1EEC2Ev = comdat any

$_ZNSaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEC2Ev = comdat any

$_ZNSt20_Rb_tree_key_compareISt4lessIiEEC2Ev = comdat any

$_ZN9__gnu_cxx13new_allocatorISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEC2Ev = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE17_M_emplace_uniqueIJS0_IiS2_EEEES0_ISt17_Rb_tree_iteratorIS3_EbEDpOT_ = comdat any

$_ZSt7forwardISt4pairIi9NonDetLogEEOT_RNSt16remove_referenceIS3_E4typeE = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE14_M_create_nodeIJS0_IiS2_EEEEPSt13_Rb_tree_nodeIS3_EDpOT_ = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE24_M_get_insert_unique_posERS1_ = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE6_S_keyEPKSt13_Rb_tree_nodeIS3_E = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE14_M_insert_nodeEPSt18_Rb_tree_node_baseSB_PSt13_Rb_tree_nodeIS3_E = comdat any

$_ZNSt4pairISt17_Rb_tree_iteratorIS_IKi9NonDetLogEEbEC2IS4_bLb1EEEOT_OT0_ = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE17_M_construct_nodeIJS0_IiS2_EEEEvPSt13_Rb_tree_nodeIS3_EDpOT_ = comdat any

$_ZNSt16allocator_traitsISaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEE9constructIS4_JS1_IiS3_EEEEvRS6_PT_DpOT0_ = comdat any

$_ZN9__gnu_cxx13new_allocatorISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEE9constructIS5_JS2_IiS4_EEEEvPT_DpOT0_ = comdat any

$_ZNSt4pairIKi9NonDetLogEC2IiS1_Lb1EEEOS_IT_T0_E = comdat any

$_ZSt7forwardIiEOT_RNSt16remove_referenceIS0_E4typeE = comdat any

$_ZSt7forwardI9NonDetLogEOT_RNSt16remove_referenceIS1_E4typeE = comdat any

$_ZN9NonDetLogC2EOS_ = comdat any

$_ZN5boost7variantIiJjcdfEEC2EOS1_ = comdat any

$_ZN5boost6detail7variant9move_intoC2EPv = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPviNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPvjNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPvcNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPvdNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPvfNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i = comdat any

$_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l = comdat any

$_ZN5boost6detail7variant15visitation_implIN4mpl_4int_ILi20EEENS1_20visitation_impl_stepINS_3mpl6l_iterINS7_5l_endEEESA_EENS1_9move_intoEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT1_11result_typeEiiRSH_T2_NS3_5bool_ILb1EEET3_PT_PT0_ = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9move_intoEPviEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZNK5boost6detail7variant9move_into14internal_visitIiEEvRT_i = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9move_intoEPvjEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZNK5boost6detail7variant9move_into14internal_visitIjEEvRT_i = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9move_intoEPvcEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZNK5boost6detail7variant9move_into14internal_visitIcEEvRT_i = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9move_intoEPvdEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZNK5boost6detail7variant9move_into14internal_visitIdEEvRT_i = comdat any

$_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9move_intoEPvfEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE = comdat any

$_ZNK5boost6detail7variant9move_into14internal_visitIfEEvRT_i = comdat any

$_ZNKSt4lessIiEclERKiS2_ = comdat any

$_ZSteqRKSt17_Rb_tree_iteratorISt4pairIKi9NonDetLogEES6_ = comdat any

$_ZNSt4pairIPSt18_Rb_tree_node_baseS1_EC2IRPSt13_Rb_tree_nodeIS_IKi9NonDetLogEERS1_Lb1EEEOT_OT0_ = comdat any

$_ZNSt17_Rb_tree_iteratorISt4pairIKi9NonDetLogEEmmEv = comdat any

$_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE6_S_keyEPKSt18_Rb_tree_node_base = comdat any

$_ZNSt4pairIPSt18_Rb_tree_node_baseS1_EC2IRS1_Lb1EEEOT_RKS1_ = comdat any

$_ZSt7forwardIRPSt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEOT_RNSt16remove_referenceIS8_E4typeE = comdat any

$_ZSt7forwardIRPSt18_Rb_tree_node_baseEOT_RNSt16remove_referenceIS3_E4typeE = comdat any

$_ZNKSt10_Select1stISt4pairIKi9NonDetLogEEclERKS3_ = comdat any

$_ZSt7forwardISt17_Rb_tree_iteratorISt4pairIKi9NonDetLogEEEOT_RNSt16remove_referenceIS6_E4typeE = comdat any

$_ZSt7forwardIbEOT_RNSt16remove_referenceIS0_E4typeE = comdat any

$_ZSt7forwardIRiEOT_RNSt16remove_referenceIS1_E4typeE = comdat any

$_ZSt7forwardIR9NonDetLogEOT_RNSt16remove_referenceIS2_E4typeE = comdat any

$_ZNSt7__cxx114listISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE9_M_insertIJRKS9_EEEvSt14_List_iteratorIS9_EDpOT_ = comdat any

$_ZNSt7__cxx114listISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE14_M_create_nodeIJRKS9_EEEPSt10_List_nodeIS9_EDpOT_ = comdat any

$_ZSt7forwardIRKSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEEOT_RNSt16remove_referenceISB_E4typeE = comdat any

$_ZNSt7__cxx1110_List_baseISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE11_M_inc_sizeEm = comdat any

$_ZNSt7__cxx1110_List_baseISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE11_M_get_nodeEv = comdat any

$_ZNSt15__allocated_ptrISaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEEEEC2ERSB_PSA_ = comdat any

$_ZNSt16allocator_traitsISaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEEEE9constructIS9_JRKS9_EEEvRSB_PT_DpOT0_ = comdat any

$_ZNSt15__allocated_ptrISaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEEEEaSEDn = comdat any

$_ZNSt15__allocated_ptrISaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEEEED2Ev = comdat any

$_ZNSt16allocator_traitsISaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEEEE8allocateERSB_m = comdat any

$_ZN9__gnu_cxx13new_allocatorISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS3_EEEEE8allocateEmPKv = comdat any

$_ZNK9__gnu_cxx13new_allocatorISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS3_EEEEE8max_sizeEv = comdat any

$_ZSt11__addressofISaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEEEEPT_RSC_ = comdat any

$_ZN9__gnu_cxx13new_allocatorISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS3_EEEEE9constructISA_JRKSA_EEEvPT_DpOT0_ = comdat any

$_ZZNK5boost17integral_constantIbLb1EEcvRKN4mpl_5bool_ILb1EEEEvE4data = comdat any

$_ZZNK5boost17integral_constantIbLb1EEcvRKN4mpl_5bool_ILb1EEEEvE5pdata = comdat any

@_ZStL8__ioinit = internal global %"class.std::ios_base::Init" zeroinitializer, align 1
@__dso_handle = external hidden global i8
@execution_step = dso_local global i32 1, align 4
@container_nondetlog = dso_local global %class.Container zeroinitializer, align 8
@.str = private unnamed_addr constant [6 x i8] c"hello\00", align 1
@.str.2 = private unnamed_addr constant [6 x i8] c"false\00", align 1
@.str.3 = private unnamed_addr constant [52 x i8] c"/usr/include/boost/variant/detail/forced_return.hpp\00", align 1
@__PRETTY_FUNCTION__._ZN5boost6detail7variant13forced_returnIvEET_v = private unnamed_addr constant [53 x i8] c"T boost::detail::variant::forced_return() [T = void]\00", align 1
@_ZZNK5boost17integral_constantIbLb1EEcvRKN4mpl_5bool_ILb1EEEEvE4data = linkonce_odr dso_local constant [8 x i8] zeroinitializer, comdat, align 1
@_ZZNK5boost17integral_constantIbLb1EEcvRKN4mpl_5bool_ILb1EEEEvE5pdata = linkonce_odr dso_local global i8* getelementptr inbounds ([8 x i8], [8 x i8]* @_ZZNK5boost17integral_constantIbLb1EEcvRKN4mpl_5bool_ILb1EEEEvE4data, i32 0, i32 0), comdat, align 8
@_ZSt4cout = external dso_local global %"class.std::basic_ostream", align 8
@.str.4 = private unnamed_addr constant [41 x i8] c"Step;\09Line;\09Scope;\09Value;\09Type;\09Function\00", align 1
@.str.5 = private unnamed_addr constant [2 x i8] c"\09\00", align 1
@_ZTIi = external dso_local constant i8*
@.str.6 = private unnamed_addr constant [4 x i8] c"int\00", align 1
@_ZTIj = external dso_local constant i8*
@.str.7 = private unnamed_addr constant [9 x i8] c"unsigned\00", align 1
@_ZTIc = external dso_local constant i8*
@.str.8 = private unnamed_addr constant [5 x i8] c"char\00", align 1
@_ZTId = external dso_local constant i8*
@.str.9 = private unnamed_addr constant [7 x i8] c"double\00", align 1
@_ZTIf = external dso_local constant i8*
@.str.10 = private unnamed_addr constant [6 x i8] c"float\00", align 1
@__PRETTY_FUNCTION__._ZN5boost6detail7variant13forced_returnIRKSt9type_infoEET_v = private unnamed_addr constant [71 x i8] c"T boost::detail::variant::forced_return() [T = const std::type_info &]\00", align 1
@__PRETTY_FUNCTION__._ZN5boost6detail7variant13forced_returnIbEET_v = private unnamed_addr constant [53 x i8] c"T boost::detail::variant::forced_return() [T = bool]\00", align 1
@llvm.global_ctors = appending global [1 x { i32, void ()*, i8* }] [{ i32, void ()*, i8* } { i32 65535, void ()* @_GLOBAL__sub_I_callerlibtest.cpp, i8* null }]

@_ZN9NonDetLogC1Ev = dso_local unnamed_addr alias void (%class.NonDetLog*), void (%class.NonDetLog*)* @_ZN9NonDetLogC2Ev

; Function Attrs: noinline uwtable
define internal void @__cxx_global_var_init() #0 section ".text.startup" {
  call void @_ZNSt8ios_base4InitC1Ev(%"class.std::ios_base::Init"* @_ZStL8__ioinit)
  %1 = call i32 @__cxa_atexit(void (i8*)* bitcast (void (%"class.std::ios_base::Init"*)* @_ZNSt8ios_base4InitD1Ev to void (i8*)*), i8* getelementptr inbounds (%"class.std::ios_base::Init", %"class.std::ios_base::Init"* @_ZStL8__ioinit, i32 0, i32 0), i8* @__dso_handle) #3
  ret void
}

declare dso_local void @_ZNSt8ios_base4InitC1Ev(%"class.std::ios_base::Init"*) unnamed_addr #1

; Function Attrs: nounwind
declare dso_local void @_ZNSt8ios_base4InitD1Ev(%"class.std::ios_base::Init"*) unnamed_addr #2

; Function Attrs: nounwind
declare dso_local i32 @__cxa_atexit(void (i8*)*, i8*, i8*) #3

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @_ZN9NonDetLogC2Ev(%class.NonDetLog*) unnamed_addr #4 align 2 {
  %2 = alloca %class.NonDetLog*, align 8
  store %class.NonDetLog* %0, %class.NonDetLog** %2, align 8
  %3 = load %class.NonDetLog*, %class.NonDetLog** %2, align 8
  %4 = getelementptr inbounds %class.NonDetLog, %class.NonDetLog* %3, i32 0, i32 2
  call void @_ZN5boost7variantIiJjcdfEEC2Ev(%"class.boost::variant"* %4) #3
  %5 = getelementptr inbounds %class.NonDetLog, %class.NonDetLog* %3, i32 0, i32 3
  call void @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1Ev(%"class.std::__cxx11::basic_string"* %5) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost7variantIiJjcdfEEC2Ev(%"class.boost::variant"*) unnamed_addr #4 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %2 = alloca %"class.boost::variant"*, align 8
  %3 = alloca i8*
  %4 = alloca i32
  store %"class.boost::variant"* %0, %"class.boost::variant"** %2, align 8
  %5 = load %"class.boost::variant"*, %"class.boost::variant"** %2, align 8
  %6 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %5, i32 0, i32 2
  invoke void @_ZN5boost15aligned_storageILm8ELm8EEC2Ev(%"class.boost::aligned_storage"* %6)
          to label %7 unwind label %16

; <label>:7:                                      ; preds = %1
  %8 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %5, i32 0, i32 2
  %9 = invoke i8* @_ZN5boost15aligned_storageILm8ELm8EE7addressEv(%"class.boost::aligned_storage"* %8)
          to label %10 unwind label %12

; <label>:10:                                     ; preds = %7
  %11 = bitcast i8* %9 to i32*
  store i32 0, i32* %11, align 4
  call void @_ZN5boost7variantIiJjcdfEE14indicate_whichEi(%"class.boost::variant"* %5, i32 0) #3
  ret void

; <label>:12:                                     ; preds = %7
  %13 = landingpad { i8*, i32 }
          catch i8* null
  %14 = extractvalue { i8*, i32 } %13, 0
  store i8* %14, i8** %3, align 8
  %15 = extractvalue { i8*, i32 } %13, 1
  store i32 %15, i32* %4, align 4
  call void @_ZN5boost15aligned_storageILm8ELm8EED2Ev(%"class.boost::aligned_storage"* %6) #3
  br label %19

; <label>:16:                                     ; preds = %1
  %17 = landingpad { i8*, i32 }
          catch i8* null
  %18 = extractvalue { i8*, i32 } %17, 0
  call void @__clang_call_terminate(i8* %18) #16
  unreachable

; <label>:19:                                     ; preds = %12
  %20 = load i8*, i8** %3, align 8
  call void @__clang_call_terminate(i8* %20) #16
  unreachable
}

; Function Attrs: nounwind
declare dso_local void @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1Ev(%"class.std::__cxx11::basic_string"*) unnamed_addr #2

; Function Attrs: noinline uwtable
define internal void @__cxx_global_var_init.1() #0 section ".text.startup" {
  call void @_ZN9ContainerI9NonDetLogEC2Ev(%class.Container* @container_nondetlog)
  %1 = call i32 @__cxa_atexit(void (i8*)* bitcast (void (%class.Container*)* @_ZN9ContainerI9NonDetLogED2Ev to void (i8*)*), i8* bitcast (%class.Container* @container_nondetlog to i8*), i8* @__dso_handle) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN9ContainerI9NonDetLogEC2Ev(%class.Container*) unnamed_addr #4 comdat align 2 {
  %2 = alloca %class.Container*, align 8
  store %class.Container* %0, %class.Container** %2, align 8
  %3 = load %class.Container*, %class.Container** %2, align 8
  %4 = getelementptr inbounds %class.Container, %class.Container* %3, i32 0, i32 0
  call void @_ZNSt7__cxx114listISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EEC2Ev(%"class.std::__cxx11::list"* %4) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN9ContainerI9NonDetLogED2Ev(%class.Container*) unnamed_addr #4 comdat align 2 {
  %2 = alloca %class.Container*, align 8
  store %class.Container* %0, %class.Container** %2, align 8
  %3 = load %class.Container*, %class.Container** %2, align 8
  %4 = getelementptr inbounds %class.Container, %class.Container* %3, i32 0, i32 0
  call void @_ZNSt7__cxx114listISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EED2Ev(%"class.std::__cxx11::list"* %4) #3
  ret void
}

; Function Attrs: noinline optnone uwtable
define dso_local void @_Z26showItemsFromContNonDetLogv() #5 {
  call void @_ZN9ContainerI9NonDetLogE26showItemsFromContNonDetLogEv(%class.Container* @container_nondetlog)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN9ContainerI9NonDetLogE26showItemsFromContNonDetLogEv(%class.Container*) #5 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %2 = alloca %class.Container*, align 8
  %3 = alloca %"class.std::__cxx11::list"*, align 8
  %4 = alloca %"struct.std::_List_iterator", align 8
  %5 = alloca %"struct.std::_List_iterator", align 8
  %6 = alloca %"class.std::map", align 8
  %7 = alloca %"class.std::map"*, align 8
  %8 = alloca %"struct.std::_Rb_tree_iterator", align 8
  %9 = alloca %"struct.std::_Rb_tree_iterator", align 8
  %10 = alloca %"struct.std::pair", align 8
  %11 = alloca i8*
  %12 = alloca i32
  %13 = alloca %"class.std::__cxx11::basic_string", align 8
  %14 = alloca %class.NonDetLog, align 8
  store %class.Container* %0, %class.Container** %2, align 8
  %15 = load %class.Container*, %class.Container** %2, align 8
  %16 = getelementptr inbounds %class.Container, %class.Container* %15, i32 0, i32 0
  %17 = call dereferenceable(48) %"class.std::map"* @_ZNSt7__cxx114listISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE4backEv(%"class.std::__cxx11::list"* %16) #3
  %18 = call i64 @_ZNKSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS0_EEE4sizeEv(%"class.std::map"* %17) #3
  %19 = call dereferenceable(272) %"class.std::basic_ostream"* @_ZNSolsEm(%"class.std::basic_ostream"* @_ZSt4cout, i64 %18)
  %20 = call dereferenceable(272) %"class.std::basic_ostream"* @_ZNSolsEPFRSoS_E(%"class.std::basic_ostream"* %19, %"class.std::basic_ostream"* (%"class.std::basic_ostream"*)* @_ZSt4endlIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_)
  %21 = call dereferenceable(272) %"class.std::basic_ostream"* @_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc(%"class.std::basic_ostream"* dereferenceable(272) @_ZSt4cout, i8* getelementptr inbounds ([41 x i8], [41 x i8]* @.str.4, i32 0, i32 0))
  %22 = call dereferenceable(272) %"class.std::basic_ostream"* @_ZNSolsEPFRSoS_E(%"class.std::basic_ostream"* %21, %"class.std::basic_ostream"* (%"class.std::basic_ostream"*)* @_ZSt4endlIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_)
  %23 = getelementptr inbounds %class.Container, %class.Container* %15, i32 0, i32 0
  store %"class.std::__cxx11::list"* %23, %"class.std::__cxx11::list"** %3, align 8
  %24 = load %"class.std::__cxx11::list"*, %"class.std::__cxx11::list"** %3, align 8
  %25 = call %"struct.std::__detail::_List_node_base"* @_ZNSt7__cxx114listISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE5beginEv(%"class.std::__cxx11::list"* %24) #3
  %26 = getelementptr inbounds %"struct.std::_List_iterator", %"struct.std::_List_iterator"* %4, i32 0, i32 0
  store %"struct.std::__detail::_List_node_base"* %25, %"struct.std::__detail::_List_node_base"** %26, align 8
  %27 = load %"class.std::__cxx11::list"*, %"class.std::__cxx11::list"** %3, align 8
  %28 = call %"struct.std::__detail::_List_node_base"* @_ZNSt7__cxx114listISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE3endEv(%"class.std::__cxx11::list"* %27) #3
  %29 = getelementptr inbounds %"struct.std::_List_iterator", %"struct.std::_List_iterator"* %5, i32 0, i32 0
  store %"struct.std::__detail::_List_node_base"* %28, %"struct.std::__detail::_List_node_base"** %29, align 8
  br label %30

; <label>:30:                                     ; preds = %107, %1
  %31 = call zeroext i1 @_ZStneRKSt14_List_iteratorISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEESB_(%"struct.std::_List_iterator"* dereferenceable(8) %4, %"struct.std::_List_iterator"* dereferenceable(8) %5) #3
  br i1 %31, label %32, label %110

; <label>:32:                                     ; preds = %30
  %33 = call dereferenceable(48) %"class.std::map"* @_ZNKSt14_List_iteratorISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEEdeEv(%"struct.std::_List_iterator"* %4) #3
  call void @_ZNSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS0_EEEC2ERKS7_(%"class.std::map"* %6, %"class.std::map"* dereferenceable(48) %33)
  store %"class.std::map"* %6, %"class.std::map"** %7, align 8
  %34 = load %"class.std::map"*, %"class.std::map"** %7, align 8
  %35 = call %"struct.std::_Rb_tree_node_base"* @_ZNSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS0_EEE5beginEv(%"class.std::map"* %34) #3
  %36 = getelementptr inbounds %"struct.std::_Rb_tree_iterator", %"struct.std::_Rb_tree_iterator"* %8, i32 0, i32 0
  store %"struct.std::_Rb_tree_node_base"* %35, %"struct.std::_Rb_tree_node_base"** %36, align 8
  %37 = load %"class.std::map"*, %"class.std::map"** %7, align 8
  %38 = call %"struct.std::_Rb_tree_node_base"* @_ZNSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS0_EEE3endEv(%"class.std::map"* %37) #3
  %39 = getelementptr inbounds %"struct.std::_Rb_tree_iterator", %"struct.std::_Rb_tree_iterator"* %9, i32 0, i32 0
  store %"struct.std::_Rb_tree_node_base"* %38, %"struct.std::_Rb_tree_node_base"** %39, align 8
  br label %40

; <label>:40:                                     ; preds = %86, %32
  %41 = call zeroext i1 @_ZStneRKSt17_Rb_tree_iteratorISt4pairIKi9NonDetLogEES6_(%"struct.std::_Rb_tree_iterator"* dereferenceable(8) %8, %"struct.std::_Rb_tree_iterator"* dereferenceable(8) %9) #3
  br i1 %41, label %42, label %106

; <label>:42:                                     ; preds = %40
  %43 = call dereferenceable(64) %"struct.std::pair"* @_ZNKSt17_Rb_tree_iteratorISt4pairIKi9NonDetLogEEdeEv(%"struct.std::_Rb_tree_iterator"* %8) #3
  invoke void @_ZNSt4pairIKi9NonDetLogEC2ERKS2_(%"struct.std::pair"* %10, %"struct.std::pair"* dereferenceable(64) %43)
          to label %44 unwind label %88

; <label>:44:                                     ; preds = %42
  %45 = getelementptr inbounds %"struct.std::pair", %"struct.std::pair"* %10, i32 0, i32 0
  %46 = load i32, i32* %45, align 8
  %47 = invoke dereferenceable(272) %"class.std::basic_ostream"* @_ZNSolsEi(%"class.std::basic_ostream"* @_ZSt4cout, i32 %46)
          to label %48 unwind label %92

; <label>:48:                                     ; preds = %44
  %49 = invoke dereferenceable(272) %"class.std::basic_ostream"* @_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc(%"class.std::basic_ostream"* dereferenceable(272) %47, i8* getelementptr inbounds ([2 x i8], [2 x i8]* @.str.5, i32 0, i32 0))
          to label %50 unwind label %92

; <label>:50:                                     ; preds = %48
  %51 = getelementptr inbounds %"struct.std::pair", %"struct.std::pair"* %10, i32 0, i32 1
  %52 = getelementptr inbounds %class.NonDetLog, %class.NonDetLog* %51, i32 0, i32 0
  %53 = load i32, i32* %52, align 8
  %54 = invoke dereferenceable(272) %"class.std::basic_ostream"* @_ZNSolsEj(%"class.std::basic_ostream"* @_ZSt4cout, i32 %53)
          to label %55 unwind label %92

; <label>:55:                                     ; preds = %50
  %56 = invoke dereferenceable(272) %"class.std::basic_ostream"* @_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc(%"class.std::basic_ostream"* dereferenceable(272) %54, i8* getelementptr inbounds ([2 x i8], [2 x i8]* @.str.5, i32 0, i32 0))
          to label %57 unwind label %92

; <label>:57:                                     ; preds = %55
  %58 = getelementptr inbounds %"struct.std::pair", %"struct.std::pair"* %10, i32 0, i32 1
  %59 = getelementptr inbounds %class.NonDetLog, %class.NonDetLog* %58, i32 0, i32 1
  %60 = load i32, i32* %59, align 4
  %61 = invoke dereferenceable(272) %"class.std::basic_ostream"* @_ZNSolsEj(%"class.std::basic_ostream"* @_ZSt4cout, i32 %60)
          to label %62 unwind label %92

; <label>:62:                                     ; preds = %57
  %63 = invoke dereferenceable(272) %"class.std::basic_ostream"* @_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc(%"class.std::basic_ostream"* dereferenceable(272) %61, i8* getelementptr inbounds ([2 x i8], [2 x i8]* @.str.5, i32 0, i32 0))
          to label %64 unwind label %92

; <label>:64:                                     ; preds = %62
  %65 = getelementptr inbounds %"struct.std::pair", %"struct.std::pair"* %10, i32 0, i32 1
  %66 = getelementptr inbounds %class.NonDetLog, %class.NonDetLog* %65, i32 0, i32 2
  %67 = invoke dereferenceable(272) %"class.std::basic_ostream"* @_ZN5boostlsIcSt11char_traitsIcEiJjcdfEEERSt13basic_ostreamIT_T0_ES7_RKNS_7variantIT1_JDpT2_EEE(%"class.std::basic_ostream"* dereferenceable(272) @_ZSt4cout, %"class.boost::variant"* dereferenceable(16) %66)
          to label %68 unwind label %92

; <label>:68:                                     ; preds = %64
  %69 = invoke dereferenceable(272) %"class.std::basic_ostream"* @_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc(%"class.std::basic_ostream"* dereferenceable(272) %67, i8* getelementptr inbounds ([2 x i8], [2 x i8]* @.str.5, i32 0, i32 0))
          to label %70 unwind label %92

; <label>:70:                                     ; preds = %68
  %71 = getelementptr inbounds %"struct.std::pair", %"struct.std::pair"* %10, i32 0, i32 1
  invoke void @_ZN9NonDetLogC2ERKS_(%class.NonDetLog* %14, %class.NonDetLog* dereferenceable(56) %71)
          to label %72 unwind label %92

; <label>:72:                                     ; preds = %70
  invoke void @_ZN9ContainerI9NonDetLogE22getNonDetLogTypeValue_B5cxx11ES0_(%"class.std::__cxx11::basic_string"* sret %13, %class.Container* %15, %class.NonDetLog* %14)
          to label %73 unwind label %96

; <label>:73:                                     ; preds = %72
  %74 = invoke dereferenceable(272) %"class.std::basic_ostream"* @_ZStlsIcSt11char_traitsIcESaIcEERSt13basic_ostreamIT_T0_ES7_RKNSt7__cxx1112basic_stringIS4_S5_T1_EE(%"class.std::basic_ostream"* dereferenceable(272) @_ZSt4cout, %"class.std::__cxx11::basic_string"* dereferenceable(32) %13)
          to label %75 unwind label %100

; <label>:75:                                     ; preds = %73
  %76 = invoke dereferenceable(272) %"class.std::basic_ostream"* @_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc(%"class.std::basic_ostream"* dereferenceable(272) %74, i8* getelementptr inbounds ([2 x i8], [2 x i8]* @.str.5, i32 0, i32 0))
          to label %77 unwind label %100

; <label>:77:                                     ; preds = %75
  call void @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEED1Ev(%"class.std::__cxx11::basic_string"* %13) #3
  call void @_ZN9NonDetLogD2Ev(%class.NonDetLog* %14) #3
  %78 = getelementptr inbounds %"struct.std::pair", %"struct.std::pair"* %10, i32 0, i32 1
  %79 = getelementptr inbounds %class.NonDetLog, %class.NonDetLog* %78, i32 0, i32 3
  %80 = invoke dereferenceable(272) %"class.std::basic_ostream"* @_ZStlsIcSt11char_traitsIcESaIcEERSt13basic_ostreamIT_T0_ES7_RKNSt7__cxx1112basic_stringIS4_S5_T1_EE(%"class.std::basic_ostream"* dereferenceable(272) @_ZSt4cout, %"class.std::__cxx11::basic_string"* dereferenceable(32) %79)
          to label %81 unwind label %92

; <label>:81:                                     ; preds = %77
  %82 = invoke dereferenceable(272) %"class.std::basic_ostream"* @_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc(%"class.std::basic_ostream"* dereferenceable(272) %80, i8* getelementptr inbounds ([2 x i8], [2 x i8]* @.str.5, i32 0, i32 0))
          to label %83 unwind label %92

; <label>:83:                                     ; preds = %81
  %84 = invoke dereferenceable(272) %"class.std::basic_ostream"* @_ZNSolsEPFRSoS_E(%"class.std::basic_ostream"* %82, %"class.std::basic_ostream"* (%"class.std::basic_ostream"*)* @_ZSt4endlIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_)
          to label %85 unwind label %92

; <label>:85:                                     ; preds = %83
  call void @_ZNSt4pairIKi9NonDetLogED2Ev(%"struct.std::pair"* %10) #3
  br label %86

; <label>:86:                                     ; preds = %85
  %87 = call dereferenceable(8) %"struct.std::_Rb_tree_iterator"* @_ZNSt17_Rb_tree_iteratorISt4pairIKi9NonDetLogEEppEv(%"struct.std::_Rb_tree_iterator"* %8) #3
  br label %40

; <label>:88:                                     ; preds = %42
  %89 = landingpad { i8*, i32 }
          cleanup
  %90 = extractvalue { i8*, i32 } %89, 0
  store i8* %90, i8** %11, align 8
  %91 = extractvalue { i8*, i32 } %89, 1
  store i32 %91, i32* %12, align 4
  br label %109

; <label>:92:                                     ; preds = %83, %81, %77, %70, %68, %64, %62, %57, %55, %50, %48, %44
  %93 = landingpad { i8*, i32 }
          cleanup
  %94 = extractvalue { i8*, i32 } %93, 0
  store i8* %94, i8** %11, align 8
  %95 = extractvalue { i8*, i32 } %93, 1
  store i32 %95, i32* %12, align 4
  br label %105

; <label>:96:                                     ; preds = %72
  %97 = landingpad { i8*, i32 }
          cleanup
  %98 = extractvalue { i8*, i32 } %97, 0
  store i8* %98, i8** %11, align 8
  %99 = extractvalue { i8*, i32 } %97, 1
  store i32 %99, i32* %12, align 4
  br label %104

; <label>:100:                                    ; preds = %75, %73
  %101 = landingpad { i8*, i32 }
          cleanup
  %102 = extractvalue { i8*, i32 } %101, 0
  store i8* %102, i8** %11, align 8
  %103 = extractvalue { i8*, i32 } %101, 1
  store i32 %103, i32* %12, align 4
  call void @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEED1Ev(%"class.std::__cxx11::basic_string"* %13) #3
  br label %104

; <label>:104:                                    ; preds = %100, %96
  call void @_ZN9NonDetLogD2Ev(%class.NonDetLog* %14) #3
  br label %105

; <label>:105:                                    ; preds = %104, %92
  call void @_ZNSt4pairIKi9NonDetLogED2Ev(%"struct.std::pair"* %10) #3
  br label %109

; <label>:106:                                    ; preds = %40
  call void @_ZNSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS0_EEED2Ev(%"class.std::map"* %6) #3
  br label %107

; <label>:107:                                    ; preds = %106
  %108 = call dereferenceable(8) %"struct.std::_List_iterator"* @_ZNSt14_List_iteratorISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEEppEv(%"struct.std::_List_iterator"* %4) #3
  br label %30

; <label>:109:                                    ; preds = %105, %88
  call void @_ZNSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS0_EEED2Ev(%"class.std::map"* %6) #3
  br label %111

; <label>:110:                                    ; preds = %30
  ret void

; <label>:111:                                    ; preds = %109
  %112 = load i8*, i8** %11, align 8
  %113 = load i32, i32* %12, align 4
  %114 = insertvalue { i8*, i32 } undef, i8* %112, 0
  %115 = insertvalue { i8*, i32 } %114, i32 %113, 1
  resume { i8*, i32 } %115
}

; Function Attrs: noinline norecurse optnone uwtable
define dso_local i32 @main() #6 {
  call void @_Z29add_item_map2check_nondet_logIiEvjjT_PKc(i32 12, i32 0, i32 7, i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.str, i32 0, i32 0))
  call void @_Z26showItemsFromContNonDetLogv()
  ret i32 0
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_Z29add_item_map2check_nondet_logIiEvjjT_PKc(i32, i32, i32, i8*) #5 comdat personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i8*, align 8
  %9 = alloca %class.NonDetLog, align 8
  %10 = alloca %"class.std::__cxx11::basic_string", align 8
  %11 = alloca %"class.std::allocator", align 1
  %12 = alloca i8*
  %13 = alloca i32
  %14 = alloca %class.NonDetLog, align 8
  store i32 %0, i32* %5, align 4
  store i32 %1, i32* %6, align 4
  store i32 %2, i32* %7, align 4
  store i8* %3, i8** %8, align 8
  call void @_ZN9NonDetLogC1Ev(%class.NonDetLog* %9)
  %15 = load i8*, i8** %8, align 8
  call void @_ZNSaIcEC1Ev(%"class.std::allocator"* %11) #3
  invoke void @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1EPKcRKS3_(%"class.std::__cxx11::basic_string"* %10, i8* %15, %"class.std::allocator"* dereferenceable(1) %11)
          to label %16 unwind label %32

; <label>:16:                                     ; preds = %4
  call void @_ZNSaIcED1Ev(%"class.std::allocator"* %11) #3
  %17 = getelementptr inbounds %class.NonDetLog, %class.NonDetLog* %9, i32 0, i32 3
  %18 = invoke dereferenceable(32) %"class.std::__cxx11::basic_string"* @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSERKS4_(%"class.std::__cxx11::basic_string"* %17, %"class.std::__cxx11::basic_string"* dereferenceable(32) %10)
          to label %19 unwind label %36

; <label>:19:                                     ; preds = %16
  %20 = load i32, i32* %5, align 4
  %21 = getelementptr inbounds %class.NonDetLog, %class.NonDetLog* %9, i32 0, i32 0
  store i32 %20, i32* %21, align 8
  %22 = load i32, i32* %6, align 4
  %23 = getelementptr inbounds %class.NonDetLog, %class.NonDetLog* %9, i32 0, i32 1
  store i32 %22, i32* %23, align 4
  %24 = getelementptr inbounds %class.NonDetLog, %class.NonDetLog* %9, i32 0, i32 2
  %25 = invoke dereferenceable(16) %"class.boost::variant"* @_ZN5boost7variantIiJjcdfEEaSIiEENS_9enable_ifINS_3mpl3or_INS_7is_sameIT_S1_EENS_6detail7variant29is_variant_constructible_fromIRKS7_NS4_6l_itemIN4mpl_5long_ILl5EEEiNSE_INSG_ILl4EEEjNSE_INSG_ILl3EEEcNSE_INSG_ILl2EEEdNSE_INSG_ILl1EEEfNS4_5l_endEEEEEEEEEEEEENSF_5bool_ILb0EEESU_SU_EERS1_E4typeESD_(%"class.boost::variant"* %24, i32* dereferenceable(4) %7)
          to label %26 unwind label %36

; <label>:26:                                     ; preds = %19
  %27 = load i32, i32* @execution_step, align 4
  invoke void @_ZN9NonDetLogC2ERKS_(%class.NonDetLog* %14, %class.NonDetLog* dereferenceable(56) %9)
          to label %28 unwind label %36

; <label>:28:                                     ; preds = %26
  invoke void @_ZN9ContainerI9NonDetLogE24appendContainerNondetLogEiS0_(%class.Container* @container_nondetlog, i32 %27, %class.NonDetLog* %14)
          to label %29 unwind label %40

; <label>:29:                                     ; preds = %28
  call void @_ZN9NonDetLogD2Ev(%class.NonDetLog* %14) #3
  %30 = load i32, i32* @execution_step, align 4
  %31 = add nsw i32 %30, 1
  store i32 %31, i32* @execution_step, align 4
  call void @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEED1Ev(%"class.std::__cxx11::basic_string"* %10) #3
  call void @_ZN9NonDetLogD2Ev(%class.NonDetLog* %9) #3
  ret void

; <label>:32:                                     ; preds = %4
  %33 = landingpad { i8*, i32 }
          cleanup
  %34 = extractvalue { i8*, i32 } %33, 0
  store i8* %34, i8** %12, align 8
  %35 = extractvalue { i8*, i32 } %33, 1
  store i32 %35, i32* %13, align 4
  call void @_ZNSaIcED1Ev(%"class.std::allocator"* %11) #3
  br label %45

; <label>:36:                                     ; preds = %26, %19, %16
  %37 = landingpad { i8*, i32 }
          cleanup
  %38 = extractvalue { i8*, i32 } %37, 0
  store i8* %38, i8** %12, align 8
  %39 = extractvalue { i8*, i32 } %37, 1
  store i32 %39, i32* %13, align 4
  br label %44

; <label>:40:                                     ; preds = %28
  %41 = landingpad { i8*, i32 }
          cleanup
  %42 = extractvalue { i8*, i32 } %41, 0
  store i8* %42, i8** %12, align 8
  %43 = extractvalue { i8*, i32 } %41, 1
  store i32 %43, i32* %13, align 4
  call void @_ZN9NonDetLogD2Ev(%class.NonDetLog* %14) #3
  br label %44

; <label>:44:                                     ; preds = %40, %36
  call void @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEED1Ev(%"class.std::__cxx11::basic_string"* %10) #3
  br label %45

; <label>:45:                                     ; preds = %44, %32
  call void @_ZN9NonDetLogD2Ev(%class.NonDetLog* %9) #3
  br label %46

; <label>:46:                                     ; preds = %45
  %47 = load i8*, i8** %12, align 8
  %48 = load i32, i32* %13, align 4
  %49 = insertvalue { i8*, i32 } undef, i8* %47, 0
  %50 = insertvalue { i8*, i32 } %49, i32 %48, 1
  resume { i8*, i32 } %50
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt7__cxx114listISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EED2Ev(%"class.std::__cxx11::list"*) unnamed_addr #4 comdat align 2 {
  %2 = alloca %"class.std::__cxx11::list"*, align 8
  store %"class.std::__cxx11::list"* %0, %"class.std::__cxx11::list"** %2, align 8
  %3 = load %"class.std::__cxx11::list"*, %"class.std::__cxx11::list"** %2, align 8
  %4 = bitcast %"class.std::__cxx11::list"* %3 to %"class.std::__cxx11::_List_base"*
  call void @_ZNSt7__cxx1110_List_baseISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EED2Ev(%"class.std::__cxx11::_List_base"* %4) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt7__cxx1110_List_baseISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EED2Ev(%"class.std::__cxx11::_List_base"*) unnamed_addr #4 comdat align 2 {
  %2 = alloca %"class.std::__cxx11::_List_base"*, align 8
  store %"class.std::__cxx11::_List_base"* %0, %"class.std::__cxx11::_List_base"** %2, align 8
  %3 = load %"class.std::__cxx11::_List_base"*, %"class.std::__cxx11::_List_base"** %2, align 8
  call void @_ZNSt7__cxx1110_List_baseISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE8_M_clearEv(%"class.std::__cxx11::_List_base"* %3) #3
  %4 = getelementptr inbounds %"class.std::__cxx11::_List_base", %"class.std::__cxx11::_List_base"* %3, i32 0, i32 0
  call void @_ZNSt7__cxx1110_List_baseISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE10_List_implD2Ev(%"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl"* %4) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt7__cxx1110_List_baseISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE8_M_clearEv(%"class.std::__cxx11::_List_base"*) #4 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %2 = alloca %"class.std::__cxx11::_List_base"*, align 8
  %3 = alloca %"struct.std::__detail::_List_node_base"*, align 8
  %4 = alloca %"struct.std::_List_node"*, align 8
  %5 = alloca %"class.std::map"*, align 8
  store %"class.std::__cxx11::_List_base"* %0, %"class.std::__cxx11::_List_base"** %2, align 8
  %6 = load %"class.std::__cxx11::_List_base"*, %"class.std::__cxx11::_List_base"** %2, align 8
  %7 = getelementptr inbounds %"class.std::__cxx11::_List_base", %"class.std::__cxx11::_List_base"* %6, i32 0, i32 0
  %8 = getelementptr inbounds %"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl", %"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl"* %7, i32 0, i32 0
  %9 = bitcast %"struct.std::__detail::_List_node_header"* %8 to %"struct.std::__detail::_List_node_base"*
  %10 = getelementptr inbounds %"struct.std::__detail::_List_node_base", %"struct.std::__detail::_List_node_base"* %9, i32 0, i32 0
  %11 = load %"struct.std::__detail::_List_node_base"*, %"struct.std::__detail::_List_node_base"** %10, align 8
  store %"struct.std::__detail::_List_node_base"* %11, %"struct.std::__detail::_List_node_base"** %3, align 8
  br label %12

; <label>:12:                                     ; preds = %27, %1
  %13 = load %"struct.std::__detail::_List_node_base"*, %"struct.std::__detail::_List_node_base"** %3, align 8
  %14 = getelementptr inbounds %"class.std::__cxx11::_List_base", %"class.std::__cxx11::_List_base"* %6, i32 0, i32 0
  %15 = getelementptr inbounds %"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl", %"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl"* %14, i32 0, i32 0
  %16 = bitcast %"struct.std::__detail::_List_node_header"* %15 to %"struct.std::__detail::_List_node_base"*
  %17 = icmp ne %"struct.std::__detail::_List_node_base"* %13, %16
  br i1 %17, label %18, label %31

; <label>:18:                                     ; preds = %12
  %19 = load %"struct.std::__detail::_List_node_base"*, %"struct.std::__detail::_List_node_base"** %3, align 8
  %20 = bitcast %"struct.std::__detail::_List_node_base"* %19 to %"struct.std::_List_node"*
  store %"struct.std::_List_node"* %20, %"struct.std::_List_node"** %4, align 8
  %21 = load %"struct.std::_List_node"*, %"struct.std::_List_node"** %4, align 8
  %22 = bitcast %"struct.std::_List_node"* %21 to %"struct.std::__detail::_List_node_base"*
  %23 = getelementptr inbounds %"struct.std::__detail::_List_node_base", %"struct.std::__detail::_List_node_base"* %22, i32 0, i32 0
  %24 = load %"struct.std::__detail::_List_node_base"*, %"struct.std::__detail::_List_node_base"** %23, align 8
  store %"struct.std::__detail::_List_node_base"* %24, %"struct.std::__detail::_List_node_base"** %3, align 8
  %25 = load %"struct.std::_List_node"*, %"struct.std::_List_node"** %4, align 8
  %26 = invoke %"class.std::map"* @_ZNSt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEE9_M_valptrEv(%"struct.std::_List_node"* %25)
          to label %27 unwind label %32

; <label>:27:                                     ; preds = %18
  store %"class.std::map"* %26, %"class.std::map"** %5, align 8
  %28 = call dereferenceable(1) %"class.std::allocator.0"* @_ZNSt7__cxx1110_List_baseISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE21_M_get_Node_allocatorEv(%"class.std::__cxx11::_List_base"* %6) #3
  %29 = load %"class.std::map"*, %"class.std::map"** %5, align 8
  call void @_ZNSt16allocator_traitsISaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEEEE7destroyIS9_EEvRSB_PT_(%"class.std::allocator.0"* dereferenceable(1) %28, %"class.std::map"* %29) #3
  %30 = load %"struct.std::_List_node"*, %"struct.std::_List_node"** %4, align 8
  call void @_ZNSt7__cxx1110_List_baseISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE11_M_put_nodeEPSt10_List_nodeIS9_E(%"class.std::__cxx11::_List_base"* %6, %"struct.std::_List_node"* %30) #3
  br label %12

; <label>:31:                                     ; preds = %12
  ret void

; <label>:32:                                     ; preds = %18
  %33 = landingpad { i8*, i32 }
          catch i8* null
  %34 = extractvalue { i8*, i32 } %33, 0
  call void @__clang_call_terminate(i8* %34) #16
  unreachable
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt7__cxx1110_List_baseISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE10_List_implD2Ev(%"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl"*) unnamed_addr #4 comdat align 2 {
  %2 = alloca %"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl"*, align 8
  store %"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl"* %0, %"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl"** %2, align 8
  %3 = load %"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl"*, %"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl"** %2, align 8
  %4 = bitcast %"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl"* %3 to %"class.std::allocator.0"*
  call void @_ZNSaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEEED2Ev(%"class.std::allocator.0"* %4) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"class.std::map"* @_ZNSt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEE9_M_valptrEv(%"struct.std::_List_node"*) #4 comdat align 2 {
  %2 = alloca %"struct.std::_List_node"*, align 8
  store %"struct.std::_List_node"* %0, %"struct.std::_List_node"** %2, align 8
  %3 = load %"struct.std::_List_node"*, %"struct.std::_List_node"** %2, align 8
  %4 = getelementptr inbounds %"struct.std::_List_node", %"struct.std::_List_node"* %3, i32 0, i32 1
  %5 = call %"class.std::map"* @_ZN9__gnu_cxx16__aligned_membufISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEE6_M_ptrEv(%"struct.__gnu_cxx::__aligned_membuf"* %4) #3
  ret %"class.std::map"* %5
}

declare dso_local i32 @__gxx_personality_v0(...)

; Function Attrs: noinline noreturn nounwind
define linkonce_odr hidden void @__clang_call_terminate(i8*) #7 comdat {
  %2 = call i8* @__cxa_begin_catch(i8* %0) #3
  call void @_ZSt9terminatev() #16
  unreachable
}

declare dso_local i8* @__cxa_begin_catch(i8*)

declare dso_local void @_ZSt9terminatev()

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt16allocator_traitsISaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEEEE7destroyIS9_EEvRSB_PT_(%"class.std::allocator.0"* dereferenceable(1), %"class.std::map"*) #4 comdat align 2 {
  %3 = alloca %"class.std::allocator.0"*, align 8
  %4 = alloca %"class.std::map"*, align 8
  store %"class.std::allocator.0"* %0, %"class.std::allocator.0"** %3, align 8
  store %"class.std::map"* %1, %"class.std::map"** %4, align 8
  %5 = load %"class.std::allocator.0"*, %"class.std::allocator.0"** %3, align 8
  %6 = bitcast %"class.std::allocator.0"* %5 to %"class.__gnu_cxx::new_allocator.1"*
  %7 = load %"class.std::map"*, %"class.std::map"** %4, align 8
  call void @_ZN9__gnu_cxx13new_allocatorISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS3_EEEEE7destroyISA_EEvPT_(%"class.__gnu_cxx::new_allocator.1"* %6, %"class.std::map"* %7) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(1) %"class.std::allocator.0"* @_ZNSt7__cxx1110_List_baseISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE21_M_get_Node_allocatorEv(%"class.std::__cxx11::_List_base"*) #4 comdat align 2 {
  %2 = alloca %"class.std::__cxx11::_List_base"*, align 8
  store %"class.std::__cxx11::_List_base"* %0, %"class.std::__cxx11::_List_base"** %2, align 8
  %3 = load %"class.std::__cxx11::_List_base"*, %"class.std::__cxx11::_List_base"** %2, align 8
  %4 = getelementptr inbounds %"class.std::__cxx11::_List_base", %"class.std::__cxx11::_List_base"* %3, i32 0, i32 0
  %5 = bitcast %"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl"* %4 to %"class.std::allocator.0"*
  ret %"class.std::allocator.0"* %5
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt7__cxx1110_List_baseISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE11_M_put_nodeEPSt10_List_nodeIS9_E(%"class.std::__cxx11::_List_base"*, %"struct.std::_List_node"*) #4 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %3 = alloca %"class.std::__cxx11::_List_base"*, align 8
  %4 = alloca %"struct.std::_List_node"*, align 8
  store %"class.std::__cxx11::_List_base"* %0, %"class.std::__cxx11::_List_base"** %3, align 8
  store %"struct.std::_List_node"* %1, %"struct.std::_List_node"** %4, align 8
  %5 = load %"class.std::__cxx11::_List_base"*, %"class.std::__cxx11::_List_base"** %3, align 8
  %6 = getelementptr inbounds %"class.std::__cxx11::_List_base", %"class.std::__cxx11::_List_base"* %5, i32 0, i32 0
  %7 = bitcast %"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl"* %6 to %"class.std::allocator.0"*
  %8 = load %"struct.std::_List_node"*, %"struct.std::_List_node"** %4, align 8
  invoke void @_ZNSt16allocator_traitsISaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEEEE10deallocateERSB_PSA_m(%"class.std::allocator.0"* dereferenceable(1) %7, %"struct.std::_List_node"* %8, i64 1)
          to label %9 unwind label %10

; <label>:9:                                      ; preds = %2
  ret void

; <label>:10:                                     ; preds = %2
  %11 = landingpad { i8*, i32 }
          catch i8* null
  %12 = extractvalue { i8*, i32 } %11, 0
  call void @__clang_call_terminate(i8* %12) #16
  unreachable
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"class.std::map"* @_ZN9__gnu_cxx16__aligned_membufISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEE6_M_ptrEv(%"struct.__gnu_cxx::__aligned_membuf"*) #4 comdat align 2 {
  %2 = alloca %"struct.__gnu_cxx::__aligned_membuf"*, align 8
  store %"struct.__gnu_cxx::__aligned_membuf"* %0, %"struct.__gnu_cxx::__aligned_membuf"** %2, align 8
  %3 = load %"struct.__gnu_cxx::__aligned_membuf"*, %"struct.__gnu_cxx::__aligned_membuf"** %2, align 8
  %4 = call i8* @_ZN9__gnu_cxx16__aligned_membufISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEE7_M_addrEv(%"struct.__gnu_cxx::__aligned_membuf"* %3) #3
  %5 = bitcast i8* %4 to %"class.std::map"*
  ret %"class.std::map"* %5
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local i8* @_ZN9__gnu_cxx16__aligned_membufISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEE7_M_addrEv(%"struct.__gnu_cxx::__aligned_membuf"*) #4 comdat align 2 {
  %2 = alloca %"struct.__gnu_cxx::__aligned_membuf"*, align 8
  store %"struct.__gnu_cxx::__aligned_membuf"* %0, %"struct.__gnu_cxx::__aligned_membuf"** %2, align 8
  %3 = load %"struct.__gnu_cxx::__aligned_membuf"*, %"struct.__gnu_cxx::__aligned_membuf"** %2, align 8
  %4 = getelementptr inbounds %"struct.__gnu_cxx::__aligned_membuf", %"struct.__gnu_cxx::__aligned_membuf"* %3, i32 0, i32 0
  %5 = bitcast [48 x i8]* %4 to i8*
  ret i8* %5
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN9__gnu_cxx13new_allocatorISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS3_EEEEE7destroyISA_EEvPT_(%"class.__gnu_cxx::new_allocator.1"*, %"class.std::map"*) #4 comdat align 2 {
  %3 = alloca %"class.__gnu_cxx::new_allocator.1"*, align 8
  %4 = alloca %"class.std::map"*, align 8
  store %"class.__gnu_cxx::new_allocator.1"* %0, %"class.__gnu_cxx::new_allocator.1"** %3, align 8
  store %"class.std::map"* %1, %"class.std::map"** %4, align 8
  %5 = load %"class.__gnu_cxx::new_allocator.1"*, %"class.__gnu_cxx::new_allocator.1"** %3, align 8
  %6 = load %"class.std::map"*, %"class.std::map"** %4, align 8
  call void @_ZNSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS0_EEED2Ev(%"class.std::map"* %6) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS0_EEED2Ev(%"class.std::map"*) unnamed_addr #4 comdat align 2 {
  %2 = alloca %"class.std::map"*, align 8
  store %"class.std::map"* %0, %"class.std::map"** %2, align 8
  %3 = load %"class.std::map"*, %"class.std::map"** %2, align 8
  %4 = getelementptr inbounds %"class.std::map", %"class.std::map"* %3, i32 0, i32 0
  call void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EED2Ev(%"class.std::_Rb_tree"* %4) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EED2Ev(%"class.std::_Rb_tree"*) unnamed_addr #4 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %2 = alloca %"class.std::_Rb_tree"*, align 8
  %3 = alloca i8*
  %4 = alloca i32
  store %"class.std::_Rb_tree"* %0, %"class.std::_Rb_tree"** %2, align 8
  %5 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %2, align 8
  %6 = call %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE8_M_beginEv(%"class.std::_Rb_tree"* %5) #3
  invoke void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE8_M_eraseEPSt13_Rb_tree_nodeIS3_E(%"class.std::_Rb_tree"* %5, %"struct.std::_Rb_tree_node"* %6)
          to label %7 unwind label %9

; <label>:7:                                      ; preds = %1
  %8 = getelementptr inbounds %"class.std::_Rb_tree", %"class.std::_Rb_tree"* %5, i32 0, i32 0
  call void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE13_Rb_tree_implIS7_Lb1EED2Ev(%"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %8) #3
  ret void

; <label>:9:                                      ; preds = %1
  %10 = landingpad { i8*, i32 }
          catch i8* null
  %11 = extractvalue { i8*, i32 } %10, 0
  store i8* %11, i8** %3, align 8
  %12 = extractvalue { i8*, i32 } %10, 1
  store i32 %12, i32* %4, align 4
  %13 = getelementptr inbounds %"class.std::_Rb_tree", %"class.std::_Rb_tree"* %5, i32 0, i32 0
  call void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE13_Rb_tree_implIS7_Lb1EED2Ev(%"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %13) #3
  br label %14

; <label>:14:                                     ; preds = %9
  %15 = load i8*, i8** %3, align 8
  call void @__clang_call_terminate(i8* %15) #16
  unreachable
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE8_M_eraseEPSt13_Rb_tree_nodeIS3_E(%"class.std::_Rb_tree"*, %"struct.std::_Rb_tree_node"*) #5 comdat align 2 {
  %3 = alloca %"class.std::_Rb_tree"*, align 8
  %4 = alloca %"struct.std::_Rb_tree_node"*, align 8
  %5 = alloca %"struct.std::_Rb_tree_node"*, align 8
  store %"class.std::_Rb_tree"* %0, %"class.std::_Rb_tree"** %3, align 8
  store %"struct.std::_Rb_tree_node"* %1, %"struct.std::_Rb_tree_node"** %4, align 8
  %6 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %3, align 8
  br label %7

; <label>:7:                                      ; preds = %10, %2
  %8 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %4, align 8
  %9 = icmp ne %"struct.std::_Rb_tree_node"* %8, null
  br i1 %9, label %10, label %19

; <label>:10:                                     ; preds = %7
  %11 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %4, align 8
  %12 = bitcast %"struct.std::_Rb_tree_node"* %11 to %"struct.std::_Rb_tree_node_base"*
  %13 = call %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE8_S_rightEPSt18_Rb_tree_node_base(%"struct.std::_Rb_tree_node_base"* %12) #3
  call void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE8_M_eraseEPSt13_Rb_tree_nodeIS3_E(%"class.std::_Rb_tree"* %6, %"struct.std::_Rb_tree_node"* %13)
  %14 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %4, align 8
  %15 = bitcast %"struct.std::_Rb_tree_node"* %14 to %"struct.std::_Rb_tree_node_base"*
  %16 = call %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE7_S_leftEPSt18_Rb_tree_node_base(%"struct.std::_Rb_tree_node_base"* %15) #3
  store %"struct.std::_Rb_tree_node"* %16, %"struct.std::_Rb_tree_node"** %5, align 8
  %17 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %4, align 8
  call void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE12_M_drop_nodeEPSt13_Rb_tree_nodeIS3_E(%"class.std::_Rb_tree"* %6, %"struct.std::_Rb_tree_node"* %17) #3
  %18 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %5, align 8
  store %"struct.std::_Rb_tree_node"* %18, %"struct.std::_Rb_tree_node"** %4, align 8
  br label %7

; <label>:19:                                     ; preds = %7
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE8_M_beginEv(%"class.std::_Rb_tree"*) #4 comdat align 2 {
  %2 = alloca %"class.std::_Rb_tree"*, align 8
  store %"class.std::_Rb_tree"* %0, %"class.std::_Rb_tree"** %2, align 8
  %3 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %2, align 8
  %4 = getelementptr inbounds %"class.std::_Rb_tree", %"class.std::_Rb_tree"* %3, i32 0, i32 0
  %5 = bitcast %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %4 to i8*
  %6 = getelementptr inbounds i8, i8* %5, i64 8
  %7 = bitcast i8* %6 to %"struct.std::_Rb_tree_header"*
  %8 = getelementptr inbounds %"struct.std::_Rb_tree_header", %"struct.std::_Rb_tree_header"* %7, i32 0, i32 0
  %9 = getelementptr inbounds %"struct.std::_Rb_tree_node_base", %"struct.std::_Rb_tree_node_base"* %8, i32 0, i32 1
  %10 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %9, align 8
  %11 = bitcast %"struct.std::_Rb_tree_node_base"* %10 to %"struct.std::_Rb_tree_node"*
  ret %"struct.std::_Rb_tree_node"* %11
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE13_Rb_tree_implIS7_Lb1EED2Ev(%"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"*) unnamed_addr #4 comdat align 2 {
  %2 = alloca %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"*, align 8
  store %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %0, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"** %2, align 8
  %3 = load %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"*, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"** %2, align 8
  %4 = bitcast %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %3 to %"class.std::allocator.3"*
  call void @_ZNSaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEED2Ev(%"class.std::allocator.3"* %4) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE8_S_rightEPSt18_Rb_tree_node_base(%"struct.std::_Rb_tree_node_base"*) #4 comdat align 2 {
  %2 = alloca %"struct.std::_Rb_tree_node_base"*, align 8
  store %"struct.std::_Rb_tree_node_base"* %0, %"struct.std::_Rb_tree_node_base"** %2, align 8
  %3 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %2, align 8
  %4 = getelementptr inbounds %"struct.std::_Rb_tree_node_base", %"struct.std::_Rb_tree_node_base"* %3, i32 0, i32 3
  %5 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %4, align 8
  %6 = bitcast %"struct.std::_Rb_tree_node_base"* %5 to %"struct.std::_Rb_tree_node"*
  ret %"struct.std::_Rb_tree_node"* %6
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE7_S_leftEPSt18_Rb_tree_node_base(%"struct.std::_Rb_tree_node_base"*) #4 comdat align 2 {
  %2 = alloca %"struct.std::_Rb_tree_node_base"*, align 8
  store %"struct.std::_Rb_tree_node_base"* %0, %"struct.std::_Rb_tree_node_base"** %2, align 8
  %3 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %2, align 8
  %4 = getelementptr inbounds %"struct.std::_Rb_tree_node_base", %"struct.std::_Rb_tree_node_base"* %3, i32 0, i32 2
  %5 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %4, align 8
  %6 = bitcast %"struct.std::_Rb_tree_node_base"* %5 to %"struct.std::_Rb_tree_node"*
  ret %"struct.std::_Rb_tree_node"* %6
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE12_M_drop_nodeEPSt13_Rb_tree_nodeIS3_E(%"class.std::_Rb_tree"*, %"struct.std::_Rb_tree_node"*) #4 comdat align 2 {
  %3 = alloca %"class.std::_Rb_tree"*, align 8
  %4 = alloca %"struct.std::_Rb_tree_node"*, align 8
  store %"class.std::_Rb_tree"* %0, %"class.std::_Rb_tree"** %3, align 8
  store %"struct.std::_Rb_tree_node"* %1, %"struct.std::_Rb_tree_node"** %4, align 8
  %5 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %3, align 8
  %6 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %4, align 8
  call void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE15_M_destroy_nodeEPSt13_Rb_tree_nodeIS3_E(%"class.std::_Rb_tree"* %5, %"struct.std::_Rb_tree_node"* %6) #3
  %7 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %4, align 8
  call void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE11_M_put_nodeEPSt13_Rb_tree_nodeIS3_E(%"class.std::_Rb_tree"* %5, %"struct.std::_Rb_tree_node"* %7) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE15_M_destroy_nodeEPSt13_Rb_tree_nodeIS3_E(%"class.std::_Rb_tree"*, %"struct.std::_Rb_tree_node"*) #4 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %3 = alloca %"class.std::_Rb_tree"*, align 8
  %4 = alloca %"struct.std::_Rb_tree_node"*, align 8
  store %"class.std::_Rb_tree"* %0, %"class.std::_Rb_tree"** %3, align 8
  store %"struct.std::_Rb_tree_node"* %1, %"struct.std::_Rb_tree_node"** %4, align 8
  %5 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %3, align 8
  %6 = call dereferenceable(1) %"class.std::allocator.3"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE21_M_get_Node_allocatorEv(%"class.std::_Rb_tree"* %5) #3
  %7 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %4, align 8
  %8 = invoke %"struct.std::pair"* @_ZNSt13_Rb_tree_nodeISt4pairIKi9NonDetLogEE9_M_valptrEv(%"struct.std::_Rb_tree_node"* %7)
          to label %9 unwind label %11

; <label>:9:                                      ; preds = %2
  call void @_ZNSt16allocator_traitsISaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEE7destroyIS4_EEvRS6_PT_(%"class.std::allocator.3"* dereferenceable(1) %6, %"struct.std::pair"* %8) #3
  %10 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %4, align 8
  ret void

; <label>:11:                                     ; preds = %2
  %12 = landingpad { i8*, i32 }
          catch i8* null
  %13 = extractvalue { i8*, i32 } %12, 0
  call void @__clang_call_terminate(i8* %13) #16
  unreachable
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE11_M_put_nodeEPSt13_Rb_tree_nodeIS3_E(%"class.std::_Rb_tree"*, %"struct.std::_Rb_tree_node"*) #4 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %3 = alloca %"class.std::_Rb_tree"*, align 8
  %4 = alloca %"struct.std::_Rb_tree_node"*, align 8
  store %"class.std::_Rb_tree"* %0, %"class.std::_Rb_tree"** %3, align 8
  store %"struct.std::_Rb_tree_node"* %1, %"struct.std::_Rb_tree_node"** %4, align 8
  %5 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %3, align 8
  %6 = call dereferenceable(1) %"class.std::allocator.3"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE21_M_get_Node_allocatorEv(%"class.std::_Rb_tree"* %5) #3
  %7 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %4, align 8
  invoke void @_ZNSt16allocator_traitsISaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEE10deallocateERS6_PS5_m(%"class.std::allocator.3"* dereferenceable(1) %6, %"struct.std::_Rb_tree_node"* %7, i64 1)
          to label %8 unwind label %9

; <label>:8:                                      ; preds = %2
  ret void

; <label>:9:                                      ; preds = %2
  %10 = landingpad { i8*, i32 }
          catch i8* null
  %11 = extractvalue { i8*, i32 } %10, 0
  call void @__clang_call_terminate(i8* %11) #16
  unreachable
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt16allocator_traitsISaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEE7destroyIS4_EEvRS6_PT_(%"class.std::allocator.3"* dereferenceable(1), %"struct.std::pair"*) #4 comdat align 2 {
  %3 = alloca %"class.std::allocator.3"*, align 8
  %4 = alloca %"struct.std::pair"*, align 8
  store %"class.std::allocator.3"* %0, %"class.std::allocator.3"** %3, align 8
  store %"struct.std::pair"* %1, %"struct.std::pair"** %4, align 8
  %5 = load %"class.std::allocator.3"*, %"class.std::allocator.3"** %3, align 8
  %6 = bitcast %"class.std::allocator.3"* %5 to %"class.__gnu_cxx::new_allocator.4"*
  %7 = load %"struct.std::pair"*, %"struct.std::pair"** %4, align 8
  call void @_ZN9__gnu_cxx13new_allocatorISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEE7destroyIS5_EEvPT_(%"class.__gnu_cxx::new_allocator.4"* %6, %"struct.std::pair"* %7) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(1) %"class.std::allocator.3"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE21_M_get_Node_allocatorEv(%"class.std::_Rb_tree"*) #4 comdat align 2 {
  %2 = alloca %"class.std::_Rb_tree"*, align 8
  store %"class.std::_Rb_tree"* %0, %"class.std::_Rb_tree"** %2, align 8
  %3 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %2, align 8
  %4 = getelementptr inbounds %"class.std::_Rb_tree", %"class.std::_Rb_tree"* %3, i32 0, i32 0
  %5 = bitcast %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %4 to %"class.std::allocator.3"*
  ret %"class.std::allocator.3"* %5
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"struct.std::pair"* @_ZNSt13_Rb_tree_nodeISt4pairIKi9NonDetLogEE9_M_valptrEv(%"struct.std::_Rb_tree_node"*) #4 comdat align 2 {
  %2 = alloca %"struct.std::_Rb_tree_node"*, align 8
  store %"struct.std::_Rb_tree_node"* %0, %"struct.std::_Rb_tree_node"** %2, align 8
  %3 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %2, align 8
  %4 = getelementptr inbounds %"struct.std::_Rb_tree_node", %"struct.std::_Rb_tree_node"* %3, i32 0, i32 1
  %5 = call %"struct.std::pair"* @_ZN9__gnu_cxx16__aligned_membufISt4pairIKi9NonDetLogEE6_M_ptrEv(%"struct.__gnu_cxx::__aligned_membuf.6"* %4) #3
  ret %"struct.std::pair"* %5
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN9__gnu_cxx13new_allocatorISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEE7destroyIS5_EEvPT_(%"class.__gnu_cxx::new_allocator.4"*, %"struct.std::pair"*) #4 comdat align 2 {
  %3 = alloca %"class.__gnu_cxx::new_allocator.4"*, align 8
  %4 = alloca %"struct.std::pair"*, align 8
  store %"class.__gnu_cxx::new_allocator.4"* %0, %"class.__gnu_cxx::new_allocator.4"** %3, align 8
  store %"struct.std::pair"* %1, %"struct.std::pair"** %4, align 8
  %5 = load %"class.__gnu_cxx::new_allocator.4"*, %"class.__gnu_cxx::new_allocator.4"** %3, align 8
  %6 = load %"struct.std::pair"*, %"struct.std::pair"** %4, align 8
  call void @_ZNSt4pairIKi9NonDetLogED2Ev(%"struct.std::pair"* %6) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt4pairIKi9NonDetLogED2Ev(%"struct.std::pair"*) unnamed_addr #4 comdat align 2 {
  %2 = alloca %"struct.std::pair"*, align 8
  store %"struct.std::pair"* %0, %"struct.std::pair"** %2, align 8
  %3 = load %"struct.std::pair"*, %"struct.std::pair"** %2, align 8
  %4 = getelementptr inbounds %"struct.std::pair", %"struct.std::pair"* %3, i32 0, i32 1
  call void @_ZN9NonDetLogD2Ev(%class.NonDetLog* %4) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN9NonDetLogD2Ev(%class.NonDetLog*) unnamed_addr #4 comdat align 2 {
  %2 = alloca %class.NonDetLog*, align 8
  store %class.NonDetLog* %0, %class.NonDetLog** %2, align 8
  %3 = load %class.NonDetLog*, %class.NonDetLog** %2, align 8
  %4 = getelementptr inbounds %class.NonDetLog, %class.NonDetLog* %3, i32 0, i32 3
  call void @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEED1Ev(%"class.std::__cxx11::basic_string"* %4) #3
  %5 = getelementptr inbounds %class.NonDetLog, %class.NonDetLog* %3, i32 0, i32 2
  call void @_ZN5boost7variantIiJjcdfEED2Ev(%"class.boost::variant"* %5) #3
  ret void
}

; Function Attrs: nounwind
declare dso_local void @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEED1Ev(%"class.std::__cxx11::basic_string"*) unnamed_addr #2

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost7variantIiJjcdfEED2Ev(%"class.boost::variant"*) unnamed_addr #4 comdat align 2 {
  %2 = alloca %"class.boost::variant"*, align 8
  store %"class.boost::variant"* %0, %"class.boost::variant"** %2, align 8
  %3 = load %"class.boost::variant"*, %"class.boost::variant"** %2, align 8
  call void @_ZN5boost7variantIiJjcdfEE15destroy_contentEv(%"class.boost::variant"* %3) #3
  %4 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %3, i32 0, i32 2
  call void @_ZN5boost15aligned_storageILm8ELm8EED2Ev(%"class.boost::aligned_storage"* %4) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost7variantIiJjcdfEE15destroy_contentEv(%"class.boost::variant"*) #4 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca %"struct.boost::detail::variant::destroyer"*, align 8
  %5 = alloca i8*, align 8
  %6 = alloca %"struct.mpl_::int_"*, align 8
  %7 = alloca %"struct.boost::detail::variant::visitation_impl_step"*, align 8
  %8 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %9 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %10 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %11 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %12 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %13 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %14 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %15 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %16 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %17 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %18 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %19 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %20 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %21 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %22 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %23 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %24 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %25 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %26 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %27 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %28 = alloca %"struct.mpl_::bool_.7", align 1
  %29 = alloca %"struct.boost::integral_constant", align 1
  %30 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %31 = alloca i32, align 4
  %32 = alloca i32, align 4
  %33 = alloca %"struct.boost::detail::variant::destroyer"*, align 8
  %34 = alloca i8*, align 8
  %35 = alloca %"struct.mpl_::bool_", align 1
  %36 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %37 = alloca %"class.boost::variant"*, align 8
  %38 = alloca %"struct.boost::detail::variant::destroyer"*, align 8
  %39 = alloca %"class.boost::variant"*, align 8
  %40 = alloca %"struct.boost::detail::variant::destroyer", align 1
  store %"class.boost::variant"* %0, %"class.boost::variant"** %39, align 8
  %41 = load %"class.boost::variant"*, %"class.boost::variant"** %39, align 8
  store %"class.boost::variant"* %41, %"class.boost::variant"** %37, align 8
  store %"struct.boost::detail::variant::destroyer"* %40, %"struct.boost::detail::variant::destroyer"** %38, align 8
  %42 = load %"class.boost::variant"*, %"class.boost::variant"** %37, align 8
  %43 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %42, i32 0, i32 0
  %44 = load i32, i32* %43, align 8
  %45 = call i32 @_ZNK5boost7variantIiJjcdfEE5whichEv(%"class.boost::variant"* %42) #3
  %46 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %38, align 8
  %47 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %42, i32 0, i32 2
  %48 = invoke i8* @_ZN5boost15aligned_storageILm8ELm8EE7addressEv(%"class.boost::aligned_storage"* %47)
          to label %49 unwind label %163

; <label>:49:                                     ; preds = %1
  store i32 %44, i32* %31, align 4
  store i32 %45, i32* %32, align 4
  store %"struct.boost::detail::variant::destroyer"* %46, %"struct.boost::detail::variant::destroyer"** %33, align 8
  store i8* %48, i8** %34, align 8
  %50 = load i32, i32* %31, align 4
  %51 = load i32, i32* %32, align 4
  %52 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %33, align 8
  %53 = load i8*, i8** %34, align 8
  store i32 %50, i32* %2, align 4
  store i32 %51, i32* %3, align 4
  store %"struct.boost::detail::variant::destroyer"* %52, %"struct.boost::detail::variant::destroyer"** %4, align 8
  store i8* %53, i8** %5, align 8
  store %"struct.mpl_::int_"* null, %"struct.mpl_::int_"** %6, align 8
  store %"struct.boost::detail::variant::visitation_impl_step"* null, %"struct.boost::detail::variant::visitation_impl_step"** %7, align 8
  %54 = load i32, i32* %3, align 4
  switch i32 %54, label %155 [
    i32 0, label %55
    i32 1, label %60
    i32 2, label %65
    i32 3, label %70
    i32 4, label %75
    i32 5, label %80
    i32 6, label %85
    i32 7, label %90
    i32 8, label %95
    i32 9, label %100
    i32 10, label %105
    i32 11, label %110
    i32 12, label %115
    i32 13, label %120
    i32 14, label %125
    i32 15, label %130
    i32 16, label %135
    i32 17, label %140
    i32 18, label %145
    i32 19, label %150
  ]

; <label>:55:                                     ; preds = %49
  %56 = load i32, i32* %2, align 4
  %57 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %4, align 8
  %58 = load i8*, i8** %5, align 8
  invoke void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPviNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32 %56, %"struct.boost::detail::variant::destroyer"* dereferenceable(1) %57, i8* %58, i32* null, i32 1)
          to label %59 unwind label %163

; <label>:59:                                     ; preds = %55
  br label %161

; <label>:60:                                     ; preds = %49
  %61 = load i32, i32* %2, align 4
  %62 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %4, align 8
  %63 = load i8*, i8** %5, align 8
  invoke void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPvjNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32 %61, %"struct.boost::detail::variant::destroyer"* dereferenceable(1) %62, i8* %63, i32* null, i32 1)
          to label %64 unwind label %163

; <label>:64:                                     ; preds = %60
  br label %161

; <label>:65:                                     ; preds = %49
  %66 = load i32, i32* %2, align 4
  %67 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %4, align 8
  %68 = load i8*, i8** %5, align 8
  invoke void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPvcNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32 %66, %"struct.boost::detail::variant::destroyer"* dereferenceable(1) %67, i8* %68, i8* null, i32 1)
          to label %69 unwind label %163

; <label>:69:                                     ; preds = %65
  br label %161

; <label>:70:                                     ; preds = %49
  %71 = load i32, i32* %2, align 4
  %72 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %4, align 8
  %73 = load i8*, i8** %5, align 8
  invoke void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPvdNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32 %71, %"struct.boost::detail::variant::destroyer"* dereferenceable(1) %72, i8* %73, double* null, i32 1)
          to label %74 unwind label %163

; <label>:74:                                     ; preds = %70
  br label %161

; <label>:75:                                     ; preds = %49
  %76 = load i32, i32* %2, align 4
  %77 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %4, align 8
  %78 = load i8*, i8** %5, align 8
  invoke void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPvfNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32 %76, %"struct.boost::detail::variant::destroyer"* dereferenceable(1) %77, i8* %78, float* null, i32 1)
          to label %79 unwind label %163

; <label>:79:                                     ; preds = %75
  br label %161

; <label>:80:                                     ; preds = %49
  %81 = load i32, i32* %2, align 4
  %82 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %4, align 8
  %83 = load i8*, i8** %5, align 8
  invoke void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %81, %"struct.boost::detail::variant::destroyer"* dereferenceable(1) %82, i8* %83, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
          to label %84 unwind label %163

; <label>:84:                                     ; preds = %80
  br label %161

; <label>:85:                                     ; preds = %49
  %86 = load i32, i32* %2, align 4
  %87 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %4, align 8
  %88 = load i8*, i8** %5, align 8
  invoke void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %86, %"struct.boost::detail::variant::destroyer"* dereferenceable(1) %87, i8* %88, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
          to label %89 unwind label %163

; <label>:89:                                     ; preds = %85
  br label %161

; <label>:90:                                     ; preds = %49
  %91 = load i32, i32* %2, align 4
  %92 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %4, align 8
  %93 = load i8*, i8** %5, align 8
  invoke void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %91, %"struct.boost::detail::variant::destroyer"* dereferenceable(1) %92, i8* %93, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
          to label %94 unwind label %163

; <label>:94:                                     ; preds = %90
  br label %161

; <label>:95:                                     ; preds = %49
  %96 = load i32, i32* %2, align 4
  %97 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %4, align 8
  %98 = load i8*, i8** %5, align 8
  invoke void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %96, %"struct.boost::detail::variant::destroyer"* dereferenceable(1) %97, i8* %98, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
          to label %99 unwind label %163

; <label>:99:                                     ; preds = %95
  br label %161

; <label>:100:                                    ; preds = %49
  %101 = load i32, i32* %2, align 4
  %102 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %4, align 8
  %103 = load i8*, i8** %5, align 8
  invoke void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %101, %"struct.boost::detail::variant::destroyer"* dereferenceable(1) %102, i8* %103, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
          to label %104 unwind label %163

; <label>:104:                                    ; preds = %100
  br label %161

; <label>:105:                                    ; preds = %49
  %106 = load i32, i32* %2, align 4
  %107 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %4, align 8
  %108 = load i8*, i8** %5, align 8
  invoke void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %106, %"struct.boost::detail::variant::destroyer"* dereferenceable(1) %107, i8* %108, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
          to label %109 unwind label %163

; <label>:109:                                    ; preds = %105
  br label %161

; <label>:110:                                    ; preds = %49
  %111 = load i32, i32* %2, align 4
  %112 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %4, align 8
  %113 = load i8*, i8** %5, align 8
  invoke void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %111, %"struct.boost::detail::variant::destroyer"* dereferenceable(1) %112, i8* %113, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
          to label %114 unwind label %163

; <label>:114:                                    ; preds = %110
  br label %161

; <label>:115:                                    ; preds = %49
  %116 = load i32, i32* %2, align 4
  %117 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %4, align 8
  %118 = load i8*, i8** %5, align 8
  invoke void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %116, %"struct.boost::detail::variant::destroyer"* dereferenceable(1) %117, i8* %118, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
          to label %119 unwind label %163

; <label>:119:                                    ; preds = %115
  br label %161

; <label>:120:                                    ; preds = %49
  %121 = load i32, i32* %2, align 4
  %122 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %4, align 8
  %123 = load i8*, i8** %5, align 8
  invoke void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %121, %"struct.boost::detail::variant::destroyer"* dereferenceable(1) %122, i8* %123, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
          to label %124 unwind label %163

; <label>:124:                                    ; preds = %120
  br label %161

; <label>:125:                                    ; preds = %49
  %126 = load i32, i32* %2, align 4
  %127 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %4, align 8
  %128 = load i8*, i8** %5, align 8
  invoke void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %126, %"struct.boost::detail::variant::destroyer"* dereferenceable(1) %127, i8* %128, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
          to label %129 unwind label %163

; <label>:129:                                    ; preds = %125
  br label %161

; <label>:130:                                    ; preds = %49
  %131 = load i32, i32* %2, align 4
  %132 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %4, align 8
  %133 = load i8*, i8** %5, align 8
  invoke void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %131, %"struct.boost::detail::variant::destroyer"* dereferenceable(1) %132, i8* %133, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
          to label %134 unwind label %163

; <label>:134:                                    ; preds = %130
  br label %161

; <label>:135:                                    ; preds = %49
  %136 = load i32, i32* %2, align 4
  %137 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %4, align 8
  %138 = load i8*, i8** %5, align 8
  invoke void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %136, %"struct.boost::detail::variant::destroyer"* dereferenceable(1) %137, i8* %138, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
          to label %139 unwind label %163

; <label>:139:                                    ; preds = %135
  br label %161

; <label>:140:                                    ; preds = %49
  %141 = load i32, i32* %2, align 4
  %142 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %4, align 8
  %143 = load i8*, i8** %5, align 8
  invoke void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %141, %"struct.boost::detail::variant::destroyer"* dereferenceable(1) %142, i8* %143, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
          to label %144 unwind label %163

; <label>:144:                                    ; preds = %140
  br label %161

; <label>:145:                                    ; preds = %49
  %146 = load i32, i32* %2, align 4
  %147 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %4, align 8
  %148 = load i8*, i8** %5, align 8
  invoke void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %146, %"struct.boost::detail::variant::destroyer"* dereferenceable(1) %147, i8* %148, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
          to label %149 unwind label %163

; <label>:149:                                    ; preds = %145
  br label %161

; <label>:150:                                    ; preds = %49
  %151 = load i32, i32* %2, align 4
  %152 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %4, align 8
  %153 = load i8*, i8** %5, align 8
  invoke void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %151, %"struct.boost::detail::variant::destroyer"* dereferenceable(1) %152, i8* %153, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
          to label %154 unwind label %163

; <label>:154:                                    ; preds = %150
  br label %161

; <label>:155:                                    ; preds = %49
  %156 = load i32, i32* %2, align 4
  %157 = load i32, i32* %3, align 4
  %158 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %4, align 8
  %159 = load i8*, i8** %5, align 8
  %160 = call dereferenceable(1) %"struct.mpl_::bool_.7"* @_ZNK5boost17integral_constantIbLb1EEcvRKN4mpl_5bool_ILb1EEEEv(%"struct.boost::integral_constant"* %29)
  call void @_ZN5boost6detail7variant15visitation_implIN4mpl_4int_ILi20EEENS1_20visitation_impl_stepINS_3mpl6l_iterINS7_5l_endEEESA_EENS1_9destroyerEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT1_11result_typeEiiRSH_T2_NS3_5bool_ILb1EEET3_PT_PT0_(i32 %156, i32 %157, %"struct.boost::detail::variant::destroyer"* dereferenceable(1) %158, i8* %159, %"struct.mpl_::int_.8"* null, %"struct.boost::detail::variant::visitation_impl_step.9"* null)
  br label %161

; <label>:161:                                    ; preds = %59, %64, %69, %74, %79, %84, %89, %94, %99, %104, %109, %114, %119, %124, %129, %134, %139, %144, %149, %154, %155
  br label %162

; <label>:162:                                    ; preds = %161
  ret void

; <label>:163:                                    ; preds = %150, %145, %140, %135, %130, %125, %120, %115, %110, %105, %100, %95, %90, %85, %80, %75, %70, %65, %60, %55, %1
  %164 = landingpad { i8*, i32 }
          catch i8* null
  %165 = extractvalue { i8*, i32 } %164, 0
  call void @__clang_call_terminate(i8* %165) #16
  unreachable
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost15aligned_storageILm8ELm8EED2Ev(%"class.boost::aligned_storage"*) unnamed_addr #4 comdat align 2 {
  %2 = alloca %"class.boost::aligned_storage"*, align 8
  store %"class.boost::aligned_storage"* %0, %"class.boost::aligned_storage"** %2, align 8
  %3 = load %"class.boost::aligned_storage"*, %"class.boost::aligned_storage"** %2, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local i32 @_ZNK5boost7variantIiJjcdfEE5whichEv(%"class.boost::variant"*) #4 comdat align 2 {
  %2 = alloca i32, align 4
  %3 = alloca %"class.boost::variant"*, align 8
  store %"class.boost::variant"* %0, %"class.boost::variant"** %3, align 8
  %4 = load %"class.boost::variant"*, %"class.boost::variant"** %3, align 8
  %5 = call zeroext i1 @_ZNK5boost7variantIiJjcdfEE12using_backupEv(%"class.boost::variant"* %4) #3
  br i1 %5, label %6, label %11

; <label>:6:                                      ; preds = %1
  %7 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %4, i32 0, i32 0
  %8 = load i32, i32* %7, align 8
  %9 = add nsw i32 %8, 1
  %10 = sub nsw i32 0, %9
  store i32 %10, i32* %2, align 4
  br label %14

; <label>:11:                                     ; preds = %1
  %12 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %4, i32 0, i32 0
  %13 = load i32, i32* %12, align 8
  store i32 %13, i32* %2, align 4
  br label %14

; <label>:14:                                     ; preds = %11, %6
  %15 = load i32, i32* %2, align 4
  ret i32 %15
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local i8* @_ZN5boost15aligned_storageILm8ELm8EE7addressEv(%"class.boost::aligned_storage"*) #5 comdat align 2 {
  %2 = alloca %"class.boost::aligned_storage"*, align 8
  store %"class.boost::aligned_storage"* %0, %"class.boost::aligned_storage"** %2, align 8
  %3 = load %"class.boost::aligned_storage"*, %"class.boost::aligned_storage"** %2, align 8
  %4 = bitcast %"class.boost::aligned_storage"* %3 to %"struct.boost::detail::aligned_storage::aligned_storage_imp"*
  %5 = call i8* @_ZNK5boost6detail15aligned_storage19aligned_storage_impILm8ELm8EE7addressEv(%"struct.boost::detail::aligned_storage::aligned_storage_imp"* %4)
  ret i8* %5
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPviNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32, %"struct.boost::detail::variant::destroyer"* dereferenceable(1), i8*, i32*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"struct.boost::detail::variant::destroyer"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca i32*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"struct.boost::detail::variant::destroyer"* %1, %"struct.boost::detail::variant::destroyer"** %8, align 8
  store i8* %2, i8** %9, align 8
  store i32* %3, i32** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load i32*, i32** %10, align 8
  call void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9destroyerEPviEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"struct.boost::detail::variant::destroyer"* dereferenceable(1) %14, i8* %15, i32* %16)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPvjNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32, %"struct.boost::detail::variant::destroyer"* dereferenceable(1), i8*, i32*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"struct.boost::detail::variant::destroyer"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca i32*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"struct.boost::detail::variant::destroyer"* %1, %"struct.boost::detail::variant::destroyer"** %8, align 8
  store i8* %2, i8** %9, align 8
  store i32* %3, i32** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load i32*, i32** %10, align 8
  call void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9destroyerEPvjEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"struct.boost::detail::variant::destroyer"* dereferenceable(1) %14, i8* %15, i32* %16)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPvcNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32, %"struct.boost::detail::variant::destroyer"* dereferenceable(1), i8*, i8*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"struct.boost::detail::variant::destroyer"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca i8*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"struct.boost::detail::variant::destroyer"* %1, %"struct.boost::detail::variant::destroyer"** %8, align 8
  store i8* %2, i8** %9, align 8
  store i8* %3, i8** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load i8*, i8** %10, align 8
  call void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9destroyerEPvcEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"struct.boost::detail::variant::destroyer"* dereferenceable(1) %14, i8* %15, i8* %16)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPvdNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32, %"struct.boost::detail::variant::destroyer"* dereferenceable(1), i8*, double*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"struct.boost::detail::variant::destroyer"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca double*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"struct.boost::detail::variant::destroyer"* %1, %"struct.boost::detail::variant::destroyer"** %8, align 8
  store i8* %2, i8** %9, align 8
  store double* %3, double** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load double*, double** %10, align 8
  call void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9destroyerEPvdEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"struct.boost::detail::variant::destroyer"* dereferenceable(1) %14, i8* %15, double* %16)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPvfNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32, %"struct.boost::detail::variant::destroyer"* dereferenceable(1), i8*, float*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"struct.boost::detail::variant::destroyer"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca float*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"struct.boost::detail::variant::destroyer"* %1, %"struct.boost::detail::variant::destroyer"** %8, align 8
  store i8* %2, i8** %9, align 8
  store float* %3, float** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load float*, float** %10, align 8
  call void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9destroyerEPvfEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"struct.boost::detail::variant::destroyer"* dereferenceable(1) %14, i8* %15, float* %16)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9destroyerEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32, %"struct.boost::detail::variant::destroyer"* dereferenceable(1), i8*, %"struct.boost::detail::variant::apply_visitor_unrolled"*, i64) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"struct.boost::detail::variant::destroyer"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca %"struct.boost::detail::variant::apply_visitor_unrolled"*, align 8
  %11 = alloca i64, align 8
  store i32 %0, i32* %7, align 4
  store %"struct.boost::detail::variant::destroyer"* %1, %"struct.boost::detail::variant::destroyer"** %8, align 8
  store i8* %2, i8** %9, align 8
  store %"struct.boost::detail::variant::apply_visitor_unrolled"* %3, %"struct.boost::detail::variant::apply_visitor_unrolled"** %10, align 8
  store i64 %4, i64* %11, align 8
  call void @_ZN5boost6detail7variant13forced_returnIvEET_v() #17
  unreachable
                                                  ; No predecessors!
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant15visitation_implIN4mpl_4int_ILi20EEENS1_20visitation_impl_stepINS_3mpl6l_iterINS7_5l_endEEESA_EENS1_9destroyerEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT1_11result_typeEiiRSH_T2_NS3_5bool_ILb1EEET3_PT_PT0_(i32, i32, %"struct.boost::detail::variant::destroyer"* dereferenceable(1), i8*, %"struct.mpl_::int_.8"*, %"struct.boost::detail::variant::visitation_impl_step.9"*) #4 comdat {
  %7 = alloca %"struct.mpl_::bool_.7", align 1
  %8 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca %"struct.boost::detail::variant::destroyer"*, align 8
  %12 = alloca i8*, align 8
  %13 = alloca %"struct.mpl_::int_.8"*, align 8
  %14 = alloca %"struct.boost::detail::variant::visitation_impl_step.9"*, align 8
  store i32 %0, i32* %9, align 4
  store i32 %1, i32* %10, align 4
  store %"struct.boost::detail::variant::destroyer"* %2, %"struct.boost::detail::variant::destroyer"** %11, align 8
  store i8* %3, i8** %12, align 8
  store %"struct.mpl_::int_.8"* %4, %"struct.mpl_::int_.8"** %13, align 8
  store %"struct.boost::detail::variant::visitation_impl_step.9"* %5, %"struct.boost::detail::variant::visitation_impl_step.9"** %14, align 8
  call void @_ZN5boost6detail7variant13forced_returnIvEET_v() #17
  unreachable
                                                  ; No predecessors!
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(1) %"struct.mpl_::bool_.7"* @_ZNK5boost17integral_constantIbLb1EEcvRKN4mpl_5bool_ILb1EEEEv(%"struct.boost::integral_constant"*) #4 comdat align 2 {
  %2 = alloca %"struct.boost::integral_constant"*, align 8
  store %"struct.boost::integral_constant"* %0, %"struct.boost::integral_constant"** %2, align 8
  %3 = load %"struct.boost::integral_constant"*, %"struct.boost::integral_constant"** %2, align 8
  %4 = load i8*, i8** @_ZZNK5boost17integral_constantIbLb1EEcvRKN4mpl_5bool_ILb1EEEEvE5pdata, align 8
  %5 = bitcast i8* %4 to %"struct.mpl_::bool_.7"*
  ret %"struct.mpl_::bool_.7"* %5
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9destroyerEPviEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"struct.boost::detail::variant::destroyer"* dereferenceable(1), i8*, i32*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"struct.boost::detail::variant::destroyer"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca i32*, align 8
  store i32 %0, i32* %6, align 4
  store %"struct.boost::detail::variant::destroyer"* %1, %"struct.boost::detail::variant::destroyer"** %7, align 8
  store i8* %2, i8** %8, align 8
  store i32* %3, i32** %9, align 8
  %10 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(4) i32* @_ZN5boost6detail7variant12cast_storageIiEERT_Pv(i8* %11)
  call void @_ZNK5boost6detail7variant9destroyer14internal_visitIiEEvRT_i(%"struct.boost::detail::variant::destroyer"* %10, i32* dereferenceable(4) %12, i32 1) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost6detail7variant9destroyer14internal_visitIiEEvRT_i(%"struct.boost::detail::variant::destroyer"*, i32* dereferenceable(4), i32) #4 comdat align 2 {
  %4 = alloca %"struct.boost::detail::variant::destroyer"*, align 8
  %5 = alloca i32*, align 8
  %6 = alloca i32, align 4
  store %"struct.boost::detail::variant::destroyer"* %0, %"struct.boost::detail::variant::destroyer"** %4, align 8
  store i32* %1, i32** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %4, align 8
  %8 = load i32*, i32** %5, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(4) i32* @_ZN5boost6detail7variant12cast_storageIiEERT_Pv(i8*) #4 comdat {
  %2 = alloca i8*, align 8
  store i8* %0, i8** %2, align 8
  %3 = load i8*, i8** %2, align 8
  %4 = bitcast i8* %3 to i32*
  ret i32* %4
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9destroyerEPvjEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"struct.boost::detail::variant::destroyer"* dereferenceable(1), i8*, i32*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"struct.boost::detail::variant::destroyer"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca i32*, align 8
  store i32 %0, i32* %6, align 4
  store %"struct.boost::detail::variant::destroyer"* %1, %"struct.boost::detail::variant::destroyer"** %7, align 8
  store i8* %2, i8** %8, align 8
  store i32* %3, i32** %9, align 8
  %10 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(4) i32* @_ZN5boost6detail7variant12cast_storageIjEERT_Pv(i8* %11)
  call void @_ZNK5boost6detail7variant9destroyer14internal_visitIjEEvRT_i(%"struct.boost::detail::variant::destroyer"* %10, i32* dereferenceable(4) %12, i32 1) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost6detail7variant9destroyer14internal_visitIjEEvRT_i(%"struct.boost::detail::variant::destroyer"*, i32* dereferenceable(4), i32) #4 comdat align 2 {
  %4 = alloca %"struct.boost::detail::variant::destroyer"*, align 8
  %5 = alloca i32*, align 8
  %6 = alloca i32, align 4
  store %"struct.boost::detail::variant::destroyer"* %0, %"struct.boost::detail::variant::destroyer"** %4, align 8
  store i32* %1, i32** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %4, align 8
  %8 = load i32*, i32** %5, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(4) i32* @_ZN5boost6detail7variant12cast_storageIjEERT_Pv(i8*) #4 comdat {
  %2 = alloca i8*, align 8
  store i8* %0, i8** %2, align 8
  %3 = load i8*, i8** %2, align 8
  %4 = bitcast i8* %3 to i32*
  ret i32* %4
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9destroyerEPvcEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"struct.boost::detail::variant::destroyer"* dereferenceable(1), i8*, i8*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"struct.boost::detail::variant::destroyer"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca i8*, align 8
  store i32 %0, i32* %6, align 4
  store %"struct.boost::detail::variant::destroyer"* %1, %"struct.boost::detail::variant::destroyer"** %7, align 8
  store i8* %2, i8** %8, align 8
  store i8* %3, i8** %9, align 8
  %10 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(1) i8* @_ZN5boost6detail7variant12cast_storageIcEERT_Pv(i8* %11)
  call void @_ZNK5boost6detail7variant9destroyer14internal_visitIcEEvRT_i(%"struct.boost::detail::variant::destroyer"* %10, i8* dereferenceable(1) %12, i32 1) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost6detail7variant9destroyer14internal_visitIcEEvRT_i(%"struct.boost::detail::variant::destroyer"*, i8* dereferenceable(1), i32) #4 comdat align 2 {
  %4 = alloca %"struct.boost::detail::variant::destroyer"*, align 8
  %5 = alloca i8*, align 8
  %6 = alloca i32, align 4
  store %"struct.boost::detail::variant::destroyer"* %0, %"struct.boost::detail::variant::destroyer"** %4, align 8
  store i8* %1, i8** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %4, align 8
  %8 = load i8*, i8** %5, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(1) i8* @_ZN5boost6detail7variant12cast_storageIcEERT_Pv(i8*) #4 comdat {
  %2 = alloca i8*, align 8
  store i8* %0, i8** %2, align 8
  %3 = load i8*, i8** %2, align 8
  ret i8* %3
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9destroyerEPvdEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"struct.boost::detail::variant::destroyer"* dereferenceable(1), i8*, double*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"struct.boost::detail::variant::destroyer"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca double*, align 8
  store i32 %0, i32* %6, align 4
  store %"struct.boost::detail::variant::destroyer"* %1, %"struct.boost::detail::variant::destroyer"** %7, align 8
  store i8* %2, i8** %8, align 8
  store double* %3, double** %9, align 8
  %10 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(8) double* @_ZN5boost6detail7variant12cast_storageIdEERT_Pv(i8* %11)
  call void @_ZNK5boost6detail7variant9destroyer14internal_visitIdEEvRT_i(%"struct.boost::detail::variant::destroyer"* %10, double* dereferenceable(8) %12, i32 1) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost6detail7variant9destroyer14internal_visitIdEEvRT_i(%"struct.boost::detail::variant::destroyer"*, double* dereferenceable(8), i32) #4 comdat align 2 {
  %4 = alloca %"struct.boost::detail::variant::destroyer"*, align 8
  %5 = alloca double*, align 8
  %6 = alloca i32, align 4
  store %"struct.boost::detail::variant::destroyer"* %0, %"struct.boost::detail::variant::destroyer"** %4, align 8
  store double* %1, double** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %4, align 8
  %8 = load double*, double** %5, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(8) double* @_ZN5boost6detail7variant12cast_storageIdEERT_Pv(i8*) #4 comdat {
  %2 = alloca i8*, align 8
  store i8* %0, i8** %2, align 8
  %3 = load i8*, i8** %2, align 8
  %4 = bitcast i8* %3 to double*
  ret double* %4
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9destroyerEPvfEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"struct.boost::detail::variant::destroyer"* dereferenceable(1), i8*, float*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"struct.boost::detail::variant::destroyer"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca float*, align 8
  store i32 %0, i32* %6, align 4
  store %"struct.boost::detail::variant::destroyer"* %1, %"struct.boost::detail::variant::destroyer"** %7, align 8
  store i8* %2, i8** %8, align 8
  store float* %3, float** %9, align 8
  %10 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(4) float* @_ZN5boost6detail7variant12cast_storageIfEERT_Pv(i8* %11)
  call void @_ZNK5boost6detail7variant9destroyer14internal_visitIfEEvRT_i(%"struct.boost::detail::variant::destroyer"* %10, float* dereferenceable(4) %12, i32 1) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost6detail7variant9destroyer14internal_visitIfEEvRT_i(%"struct.boost::detail::variant::destroyer"*, float* dereferenceable(4), i32) #4 comdat align 2 {
  %4 = alloca %"struct.boost::detail::variant::destroyer"*, align 8
  %5 = alloca float*, align 8
  %6 = alloca i32, align 4
  store %"struct.boost::detail::variant::destroyer"* %0, %"struct.boost::detail::variant::destroyer"** %4, align 8
  store float* %1, float** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"struct.boost::detail::variant::destroyer"*, %"struct.boost::detail::variant::destroyer"** %4, align 8
  %8 = load float*, float** %5, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(4) float* @_ZN5boost6detail7variant12cast_storageIfEERT_Pv(i8*) #4 comdat {
  %2 = alloca i8*, align 8
  store i8* %0, i8** %2, align 8
  %3 = load i8*, i8** %2, align 8
  %4 = bitcast i8* %3 to float*
  ret float* %4
}

; Function Attrs: noinline noreturn nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant13forced_returnIvEET_v() #8 comdat {
  %1 = alloca void ()*, align 8
  call void @__assert_fail(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.str.2, i32 0, i32 0), i8* getelementptr inbounds ([52 x i8], [52 x i8]* @.str.3, i32 0, i32 0), i32 38, i8* getelementptr inbounds ([53 x i8], [53 x i8]* @__PRETTY_FUNCTION__._ZN5boost6detail7variant13forced_returnIvEET_v, i32 0, i32 0)) #16
  unreachable
                                                  ; No predecessors!
  unreachable
}

; Function Attrs: noreturn nounwind
declare dso_local void @__assert_fail(i8*, i8*, i32, i8*) #9

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local zeroext i1 @_ZNK5boost7variantIiJjcdfEE12using_backupEv(%"class.boost::variant"*) #4 comdat align 2 {
  %2 = alloca %"class.boost::variant"*, align 8
  store %"class.boost::variant"* %0, %"class.boost::variant"** %2, align 8
  %3 = load %"class.boost::variant"*, %"class.boost::variant"** %2, align 8
  %4 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %3, i32 0, i32 0
  %5 = load i32, i32* %4, align 8
  %6 = icmp slt i32 %5, 0
  ret i1 %6
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local i8* @_ZNK5boost6detail15aligned_storage19aligned_storage_impILm8ELm8EE7addressEv(%"struct.boost::detail::aligned_storage::aligned_storage_imp"*) #4 comdat align 2 {
  %2 = alloca %"struct.boost::detail::aligned_storage::aligned_storage_imp"*, align 8
  store %"struct.boost::detail::aligned_storage::aligned_storage_imp"* %0, %"struct.boost::detail::aligned_storage::aligned_storage_imp"** %2, align 8
  %3 = load %"struct.boost::detail::aligned_storage::aligned_storage_imp"*, %"struct.boost::detail::aligned_storage::aligned_storage_imp"** %2, align 8
  %4 = bitcast %"struct.boost::detail::aligned_storage::aligned_storage_imp"* %3 to i8*
  ret i8* %4
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"struct.std::pair"* @_ZN9__gnu_cxx16__aligned_membufISt4pairIKi9NonDetLogEE6_M_ptrEv(%"struct.__gnu_cxx::__aligned_membuf.6"*) #4 comdat align 2 {
  %2 = alloca %"struct.__gnu_cxx::__aligned_membuf.6"*, align 8
  store %"struct.__gnu_cxx::__aligned_membuf.6"* %0, %"struct.__gnu_cxx::__aligned_membuf.6"** %2, align 8
  %3 = load %"struct.__gnu_cxx::__aligned_membuf.6"*, %"struct.__gnu_cxx::__aligned_membuf.6"** %2, align 8
  %4 = call i8* @_ZN9__gnu_cxx16__aligned_membufISt4pairIKi9NonDetLogEE7_M_addrEv(%"struct.__gnu_cxx::__aligned_membuf.6"* %3) #3
  %5 = bitcast i8* %4 to %"struct.std::pair"*
  ret %"struct.std::pair"* %5
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local i8* @_ZN9__gnu_cxx16__aligned_membufISt4pairIKi9NonDetLogEE7_M_addrEv(%"struct.__gnu_cxx::__aligned_membuf.6"*) #4 comdat align 2 {
  %2 = alloca %"struct.__gnu_cxx::__aligned_membuf.6"*, align 8
  store %"struct.__gnu_cxx::__aligned_membuf.6"* %0, %"struct.__gnu_cxx::__aligned_membuf.6"** %2, align 8
  %3 = load %"struct.__gnu_cxx::__aligned_membuf.6"*, %"struct.__gnu_cxx::__aligned_membuf.6"** %2, align 8
  %4 = getelementptr inbounds %"struct.__gnu_cxx::__aligned_membuf.6", %"struct.__gnu_cxx::__aligned_membuf.6"* %3, i32 0, i32 0
  %5 = bitcast [64 x i8]* %4 to i8*
  ret i8* %5
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZNSt16allocator_traitsISaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEE10deallocateERS6_PS5_m(%"class.std::allocator.3"* dereferenceable(1), %"struct.std::_Rb_tree_node"*, i64) #5 comdat align 2 {
  %4 = alloca %"class.std::allocator.3"*, align 8
  %5 = alloca %"struct.std::_Rb_tree_node"*, align 8
  %6 = alloca i64, align 8
  store %"class.std::allocator.3"* %0, %"class.std::allocator.3"** %4, align 8
  store %"struct.std::_Rb_tree_node"* %1, %"struct.std::_Rb_tree_node"** %5, align 8
  store i64 %2, i64* %6, align 8
  %7 = load %"class.std::allocator.3"*, %"class.std::allocator.3"** %4, align 8
  %8 = bitcast %"class.std::allocator.3"* %7 to %"class.__gnu_cxx::new_allocator.4"*
  %9 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %5, align 8
  %10 = load i64, i64* %6, align 8
  call void @_ZN9__gnu_cxx13new_allocatorISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEE10deallocateEPS6_m(%"class.__gnu_cxx::new_allocator.4"* %8, %"struct.std::_Rb_tree_node"* %9, i64 %10)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN9__gnu_cxx13new_allocatorISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEE10deallocateEPS6_m(%"class.__gnu_cxx::new_allocator.4"*, %"struct.std::_Rb_tree_node"*, i64) #4 comdat align 2 {
  %4 = alloca %"class.__gnu_cxx::new_allocator.4"*, align 8
  %5 = alloca %"struct.std::_Rb_tree_node"*, align 8
  %6 = alloca i64, align 8
  store %"class.__gnu_cxx::new_allocator.4"* %0, %"class.__gnu_cxx::new_allocator.4"** %4, align 8
  store %"struct.std::_Rb_tree_node"* %1, %"struct.std::_Rb_tree_node"** %5, align 8
  store i64 %2, i64* %6, align 8
  %7 = load %"class.__gnu_cxx::new_allocator.4"*, %"class.__gnu_cxx::new_allocator.4"** %4, align 8
  %8 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %5, align 8
  %9 = bitcast %"struct.std::_Rb_tree_node"* %8 to i8*
  call void @_ZdlPv(i8* %9) #3
  ret void
}

; Function Attrs: nobuiltin nounwind
declare dso_local void @_ZdlPv(i8*) #10

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN9__gnu_cxx13new_allocatorISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEED2Ev(%"class.__gnu_cxx::new_allocator.4"*) unnamed_addr #4 comdat align 2 {
  %2 = alloca %"class.__gnu_cxx::new_allocator.4"*, align 8
  store %"class.__gnu_cxx::new_allocator.4"* %0, %"class.__gnu_cxx::new_allocator.4"** %2, align 8
  %3 = load %"class.__gnu_cxx::new_allocator.4"*, %"class.__gnu_cxx::new_allocator.4"** %2, align 8
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZNSt16allocator_traitsISaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEEEE10deallocateERSB_PSA_m(%"class.std::allocator.0"* dereferenceable(1), %"struct.std::_List_node"*, i64) #5 comdat align 2 {
  %4 = alloca %"class.std::allocator.0"*, align 8
  %5 = alloca %"struct.std::_List_node"*, align 8
  %6 = alloca i64, align 8
  store %"class.std::allocator.0"* %0, %"class.std::allocator.0"** %4, align 8
  store %"struct.std::_List_node"* %1, %"struct.std::_List_node"** %5, align 8
  store i64 %2, i64* %6, align 8
  %7 = load %"class.std::allocator.0"*, %"class.std::allocator.0"** %4, align 8
  %8 = bitcast %"class.std::allocator.0"* %7 to %"class.__gnu_cxx::new_allocator.1"*
  %9 = load %"struct.std::_List_node"*, %"struct.std::_List_node"** %5, align 8
  %10 = load i64, i64* %6, align 8
  call void @_ZN9__gnu_cxx13new_allocatorISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS3_EEEEE10deallocateEPSB_m(%"class.__gnu_cxx::new_allocator.1"* %8, %"struct.std::_List_node"* %9, i64 %10)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN9__gnu_cxx13new_allocatorISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS3_EEEEE10deallocateEPSB_m(%"class.__gnu_cxx::new_allocator.1"*, %"struct.std::_List_node"*, i64) #4 comdat align 2 {
  %4 = alloca %"class.__gnu_cxx::new_allocator.1"*, align 8
  %5 = alloca %"struct.std::_List_node"*, align 8
  %6 = alloca i64, align 8
  store %"class.__gnu_cxx::new_allocator.1"* %0, %"class.__gnu_cxx::new_allocator.1"** %4, align 8
  store %"struct.std::_List_node"* %1, %"struct.std::_List_node"** %5, align 8
  store i64 %2, i64* %6, align 8
  %7 = load %"class.__gnu_cxx::new_allocator.1"*, %"class.__gnu_cxx::new_allocator.1"** %4, align 8
  %8 = load %"struct.std::_List_node"*, %"struct.std::_List_node"** %5, align 8
  %9 = bitcast %"struct.std::_List_node"* %8 to i8*
  call void @_ZdlPv(i8* %9) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEEED2Ev(%"class.std::allocator.0"*) unnamed_addr #4 comdat align 2 {
  %2 = alloca %"class.std::allocator.0"*, align 8
  store %"class.std::allocator.0"* %0, %"class.std::allocator.0"** %2, align 8
  %3 = load %"class.std::allocator.0"*, %"class.std::allocator.0"** %2, align 8
  %4 = bitcast %"class.std::allocator.0"* %3 to %"class.__gnu_cxx::new_allocator.1"*
  call void @_ZN9__gnu_cxx13new_allocatorISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS3_EEEEED2Ev(%"class.__gnu_cxx::new_allocator.1"* %4) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN9__gnu_cxx13new_allocatorISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS3_EEEEED2Ev(%"class.__gnu_cxx::new_allocator.1"*) unnamed_addr #4 comdat align 2 {
  %2 = alloca %"class.__gnu_cxx::new_allocator.1"*, align 8
  store %"class.__gnu_cxx::new_allocator.1"* %0, %"class.__gnu_cxx::new_allocator.1"** %2, align 8
  %3 = load %"class.__gnu_cxx::new_allocator.1"*, %"class.__gnu_cxx::new_allocator.1"** %2, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost15aligned_storageILm8ELm8EEC2Ev(%"class.boost::aligned_storage"*) unnamed_addr #4 comdat align 2 {
  %2 = alloca %"class.boost::aligned_storage"*, align 8
  store %"class.boost::aligned_storage"* %0, %"class.boost::aligned_storage"** %2, align 8
  %3 = load %"class.boost::aligned_storage"*, %"class.boost::aligned_storage"** %2, align 8
  %4 = bitcast %"class.boost::aligned_storage"* %3 to %"struct.boost::detail::aligned_storage::aligned_storage_imp"*
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost7variantIiJjcdfEE14indicate_whichEi(%"class.boost::variant"*, i32) #4 comdat align 2 {
  %3 = alloca %"class.boost::variant"*, align 8
  %4 = alloca i32, align 4
  store %"class.boost::variant"* %0, %"class.boost::variant"** %3, align 8
  store i32 %1, i32* %4, align 4
  %5 = load %"class.boost::variant"*, %"class.boost::variant"** %3, align 8
  %6 = load i32, i32* %4, align 4
  %7 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %5, i32 0, i32 0
  store i32 %6, i32* %7, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt7__cxx114listISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EEC2Ev(%"class.std::__cxx11::list"*) unnamed_addr #4 comdat align 2 {
  %2 = alloca %"class.std::__cxx11::list"*, align 8
  store %"class.std::__cxx11::list"* %0, %"class.std::__cxx11::list"** %2, align 8
  %3 = load %"class.std::__cxx11::list"*, %"class.std::__cxx11::list"** %2, align 8
  %4 = bitcast %"class.std::__cxx11::list"* %3 to %"class.std::__cxx11::_List_base"*
  call void @_ZNSt7__cxx1110_List_baseISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EEC2Ev(%"class.std::__cxx11::_List_base"* %4) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt7__cxx1110_List_baseISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EEC2Ev(%"class.std::__cxx11::_List_base"*) unnamed_addr #4 comdat align 2 {
  %2 = alloca %"class.std::__cxx11::_List_base"*, align 8
  store %"class.std::__cxx11::_List_base"* %0, %"class.std::__cxx11::_List_base"** %2, align 8
  %3 = load %"class.std::__cxx11::_List_base"*, %"class.std::__cxx11::_List_base"** %2, align 8
  %4 = getelementptr inbounds %"class.std::__cxx11::_List_base", %"class.std::__cxx11::_List_base"* %3, i32 0, i32 0
  call void @_ZNSt7__cxx1110_List_baseISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE10_List_implC2Ev(%"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl"* %4) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt7__cxx1110_List_baseISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE10_List_implC2Ev(%"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl"*) unnamed_addr #4 comdat align 2 {
  %2 = alloca %"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl"*, align 8
  store %"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl"* %0, %"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl"** %2, align 8
  %3 = load %"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl"*, %"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl"** %2, align 8
  %4 = bitcast %"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl"* %3 to %"class.std::allocator.0"*
  call void @_ZNSaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEEEC2Ev(%"class.std::allocator.0"* %4) #3
  %5 = getelementptr inbounds %"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl", %"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl"* %3, i32 0, i32 0
  call void @_ZNSt8__detail17_List_node_headerC2Ev(%"struct.std::__detail::_List_node_header"* %5) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEEEC2Ev(%"class.std::allocator.0"*) unnamed_addr #4 comdat align 2 {
  %2 = alloca %"class.std::allocator.0"*, align 8
  store %"class.std::allocator.0"* %0, %"class.std::allocator.0"** %2, align 8
  %3 = load %"class.std::allocator.0"*, %"class.std::allocator.0"** %2, align 8
  %4 = bitcast %"class.std::allocator.0"* %3 to %"class.__gnu_cxx::new_allocator.1"*
  call void @_ZN9__gnu_cxx13new_allocatorISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS3_EEEEEC2Ev(%"class.__gnu_cxx::new_allocator.1"* %4) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt8__detail17_List_node_headerC2Ev(%"struct.std::__detail::_List_node_header"*) unnamed_addr #4 comdat align 2 {
  %2 = alloca %"struct.std::__detail::_List_node_header"*, align 8
  store %"struct.std::__detail::_List_node_header"* %0, %"struct.std::__detail::_List_node_header"** %2, align 8
  %3 = load %"struct.std::__detail::_List_node_header"*, %"struct.std::__detail::_List_node_header"** %2, align 8
  %4 = bitcast %"struct.std::__detail::_List_node_header"* %3 to %"struct.std::__detail::_List_node_base"*
  call void @_ZNSt8__detail17_List_node_header7_M_initEv(%"struct.std::__detail::_List_node_header"* %3) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN9__gnu_cxx13new_allocatorISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS3_EEEEEC2Ev(%"class.__gnu_cxx::new_allocator.1"*) unnamed_addr #4 comdat align 2 {
  %2 = alloca %"class.__gnu_cxx::new_allocator.1"*, align 8
  store %"class.__gnu_cxx::new_allocator.1"* %0, %"class.__gnu_cxx::new_allocator.1"** %2, align 8
  %3 = load %"class.__gnu_cxx::new_allocator.1"*, %"class.__gnu_cxx::new_allocator.1"** %2, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt8__detail17_List_node_header7_M_initEv(%"struct.std::__detail::_List_node_header"*) #4 comdat align 2 {
  %2 = alloca %"struct.std::__detail::_List_node_header"*, align 8
  store %"struct.std::__detail::_List_node_header"* %0, %"struct.std::__detail::_List_node_header"** %2, align 8
  %3 = load %"struct.std::__detail::_List_node_header"*, %"struct.std::__detail::_List_node_header"** %2, align 8
  %4 = bitcast %"struct.std::__detail::_List_node_header"* %3 to %"struct.std::__detail::_List_node_base"*
  %5 = bitcast %"struct.std::__detail::_List_node_header"* %3 to %"struct.std::__detail::_List_node_base"*
  %6 = getelementptr inbounds %"struct.std::__detail::_List_node_base", %"struct.std::__detail::_List_node_base"* %5, i32 0, i32 1
  store %"struct.std::__detail::_List_node_base"* %4, %"struct.std::__detail::_List_node_base"** %6, align 8
  %7 = bitcast %"struct.std::__detail::_List_node_header"* %3 to %"struct.std::__detail::_List_node_base"*
  %8 = getelementptr inbounds %"struct.std::__detail::_List_node_base", %"struct.std::__detail::_List_node_base"* %7, i32 0, i32 0
  store %"struct.std::__detail::_List_node_base"* %4, %"struct.std::__detail::_List_node_base"** %8, align 8
  %9 = getelementptr inbounds %"struct.std::__detail::_List_node_header", %"struct.std::__detail::_List_node_header"* %3, i32 0, i32 1
  store i64 0, i64* %9, align 8
  ret void
}

declare dso_local dereferenceable(272) %"class.std::basic_ostream"* @_ZNSolsEm(%"class.std::basic_ostream"*, i64) #1

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(48) %"class.std::map"* @_ZNSt7__cxx114listISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE4backEv(%"class.std::__cxx11::list"*) #4 comdat align 2 {
  %2 = alloca %"class.std::__cxx11::list"*, align 8
  %3 = alloca %"struct.std::_List_iterator", align 8
  store %"class.std::__cxx11::list"* %0, %"class.std::__cxx11::list"** %2, align 8
  %4 = load %"class.std::__cxx11::list"*, %"class.std::__cxx11::list"** %2, align 8
  %5 = call %"struct.std::__detail::_List_node_base"* @_ZNSt7__cxx114listISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE3endEv(%"class.std::__cxx11::list"* %4) #3
  %6 = getelementptr inbounds %"struct.std::_List_iterator", %"struct.std::_List_iterator"* %3, i32 0, i32 0
  store %"struct.std::__detail::_List_node_base"* %5, %"struct.std::__detail::_List_node_base"** %6, align 8
  %7 = call dereferenceable(8) %"struct.std::_List_iterator"* @_ZNSt14_List_iteratorISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEEmmEv(%"struct.std::_List_iterator"* %3) #3
  %8 = call dereferenceable(48) %"class.std::map"* @_ZNKSt14_List_iteratorISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEEdeEv(%"struct.std::_List_iterator"* %3) #3
  ret %"class.std::map"* %8
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local i64 @_ZNKSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS0_EEE4sizeEv(%"class.std::map"*) #4 comdat align 2 {
  %2 = alloca %"class.std::map"*, align 8
  store %"class.std::map"* %0, %"class.std::map"** %2, align 8
  %3 = load %"class.std::map"*, %"class.std::map"** %2, align 8
  %4 = getelementptr inbounds %"class.std::map", %"class.std::map"* %3, i32 0, i32 0
  %5 = call i64 @_ZNKSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE4sizeEv(%"class.std::_Rb_tree"* %4) #3
  ret i64 %5
}

declare dso_local dereferenceable(272) %"class.std::basic_ostream"* @_ZNSolsEPFRSoS_E(%"class.std::basic_ostream"*, %"class.std::basic_ostream"* (%"class.std::basic_ostream"*)*) #1

declare dso_local dereferenceable(272) %"class.std::basic_ostream"* @_ZSt4endlIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_(%"class.std::basic_ostream"* dereferenceable(272)) #1

declare dso_local dereferenceable(272) %"class.std::basic_ostream"* @_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc(%"class.std::basic_ostream"* dereferenceable(272), i8*) #1

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"struct.std::__detail::_List_node_base"* @_ZNSt7__cxx114listISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE5beginEv(%"class.std::__cxx11::list"*) #4 comdat align 2 {
  %2 = alloca %"struct.std::_List_iterator", align 8
  %3 = alloca %"class.std::__cxx11::list"*, align 8
  store %"class.std::__cxx11::list"* %0, %"class.std::__cxx11::list"** %3, align 8
  %4 = load %"class.std::__cxx11::list"*, %"class.std::__cxx11::list"** %3, align 8
  %5 = bitcast %"class.std::__cxx11::list"* %4 to %"class.std::__cxx11::_List_base"*
  %6 = getelementptr inbounds %"class.std::__cxx11::_List_base", %"class.std::__cxx11::_List_base"* %5, i32 0, i32 0
  %7 = getelementptr inbounds %"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl", %"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl"* %6, i32 0, i32 0
  %8 = bitcast %"struct.std::__detail::_List_node_header"* %7 to %"struct.std::__detail::_List_node_base"*
  %9 = getelementptr inbounds %"struct.std::__detail::_List_node_base", %"struct.std::__detail::_List_node_base"* %8, i32 0, i32 0
  %10 = load %"struct.std::__detail::_List_node_base"*, %"struct.std::__detail::_List_node_base"** %9, align 8
  call void @_ZNSt14_List_iteratorISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEEC2EPNSt8__detail15_List_node_baseE(%"struct.std::_List_iterator"* %2, %"struct.std::__detail::_List_node_base"* %10) #3
  %11 = getelementptr inbounds %"struct.std::_List_iterator", %"struct.std::_List_iterator"* %2, i32 0, i32 0
  %12 = load %"struct.std::__detail::_List_node_base"*, %"struct.std::__detail::_List_node_base"** %11, align 8
  ret %"struct.std::__detail::_List_node_base"* %12
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"struct.std::__detail::_List_node_base"* @_ZNSt7__cxx114listISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE3endEv(%"class.std::__cxx11::list"*) #4 comdat align 2 {
  %2 = alloca %"struct.std::_List_iterator", align 8
  %3 = alloca %"class.std::__cxx11::list"*, align 8
  store %"class.std::__cxx11::list"* %0, %"class.std::__cxx11::list"** %3, align 8
  %4 = load %"class.std::__cxx11::list"*, %"class.std::__cxx11::list"** %3, align 8
  %5 = bitcast %"class.std::__cxx11::list"* %4 to %"class.std::__cxx11::_List_base"*
  %6 = getelementptr inbounds %"class.std::__cxx11::_List_base", %"class.std::__cxx11::_List_base"* %5, i32 0, i32 0
  %7 = getelementptr inbounds %"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl", %"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl"* %6, i32 0, i32 0
  %8 = bitcast %"struct.std::__detail::_List_node_header"* %7 to %"struct.std::__detail::_List_node_base"*
  call void @_ZNSt14_List_iteratorISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEEC2EPNSt8__detail15_List_node_baseE(%"struct.std::_List_iterator"* %2, %"struct.std::__detail::_List_node_base"* %8) #3
  %9 = getelementptr inbounds %"struct.std::_List_iterator", %"struct.std::_List_iterator"* %2, i32 0, i32 0
  %10 = load %"struct.std::__detail::_List_node_base"*, %"struct.std::__detail::_List_node_base"** %9, align 8
  ret %"struct.std::__detail::_List_node_base"* %10
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local zeroext i1 @_ZStneRKSt14_List_iteratorISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEESB_(%"struct.std::_List_iterator"* dereferenceable(8), %"struct.std::_List_iterator"* dereferenceable(8)) #4 comdat {
  %3 = alloca %"struct.std::_List_iterator"*, align 8
  %4 = alloca %"struct.std::_List_iterator"*, align 8
  store %"struct.std::_List_iterator"* %0, %"struct.std::_List_iterator"** %3, align 8
  store %"struct.std::_List_iterator"* %1, %"struct.std::_List_iterator"** %4, align 8
  %5 = load %"struct.std::_List_iterator"*, %"struct.std::_List_iterator"** %3, align 8
  %6 = getelementptr inbounds %"struct.std::_List_iterator", %"struct.std::_List_iterator"* %5, i32 0, i32 0
  %7 = load %"struct.std::__detail::_List_node_base"*, %"struct.std::__detail::_List_node_base"** %6, align 8
  %8 = load %"struct.std::_List_iterator"*, %"struct.std::_List_iterator"** %4, align 8
  %9 = getelementptr inbounds %"struct.std::_List_iterator", %"struct.std::_List_iterator"* %8, i32 0, i32 0
  %10 = load %"struct.std::__detail::_List_node_base"*, %"struct.std::__detail::_List_node_base"** %9, align 8
  %11 = icmp ne %"struct.std::__detail::_List_node_base"* %7, %10
  ret i1 %11
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(48) %"class.std::map"* @_ZNKSt14_List_iteratorISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEEdeEv(%"struct.std::_List_iterator"*) #4 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %2 = alloca %"struct.std::_List_iterator"*, align 8
  store %"struct.std::_List_iterator"* %0, %"struct.std::_List_iterator"** %2, align 8
  %3 = load %"struct.std::_List_iterator"*, %"struct.std::_List_iterator"** %2, align 8
  %4 = getelementptr inbounds %"struct.std::_List_iterator", %"struct.std::_List_iterator"* %3, i32 0, i32 0
  %5 = load %"struct.std::__detail::_List_node_base"*, %"struct.std::__detail::_List_node_base"** %4, align 8
  %6 = bitcast %"struct.std::__detail::_List_node_base"* %5 to %"struct.std::_List_node"*
  %7 = invoke %"class.std::map"* @_ZNSt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEE9_M_valptrEv(%"struct.std::_List_node"* %6)
          to label %8 unwind label %9

; <label>:8:                                      ; preds = %1
  ret %"class.std::map"* %7

; <label>:9:                                      ; preds = %1
  %10 = landingpad { i8*, i32 }
          catch i8* null
  %11 = extractvalue { i8*, i32 } %10, 0
  call void @__clang_call_terminate(i8* %11) #16
  unreachable
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZNSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS0_EEEC2ERKS7_(%"class.std::map"*, %"class.std::map"* dereferenceable(48)) unnamed_addr #5 comdat align 2 {
  %3 = alloca %"class.std::map"*, align 8
  %4 = alloca %"class.std::map"*, align 8
  store %"class.std::map"* %0, %"class.std::map"** %3, align 8
  store %"class.std::map"* %1, %"class.std::map"** %4, align 8
  %5 = load %"class.std::map"*, %"class.std::map"** %3, align 8
  %6 = getelementptr inbounds %"class.std::map", %"class.std::map"* %5, i32 0, i32 0
  %7 = load %"class.std::map"*, %"class.std::map"** %4, align 8
  %8 = getelementptr inbounds %"class.std::map", %"class.std::map"* %7, i32 0, i32 0
  call void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EEC2ERKS9_(%"class.std::_Rb_tree"* %6, %"class.std::_Rb_tree"* dereferenceable(48) %8)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"struct.std::_Rb_tree_node_base"* @_ZNSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS0_EEE5beginEv(%"class.std::map"*) #4 comdat align 2 {
  %2 = alloca %"struct.std::_Rb_tree_iterator", align 8
  %3 = alloca %"class.std::map"*, align 8
  store %"class.std::map"* %0, %"class.std::map"** %3, align 8
  %4 = load %"class.std::map"*, %"class.std::map"** %3, align 8
  %5 = getelementptr inbounds %"class.std::map", %"class.std::map"* %4, i32 0, i32 0
  %6 = call %"struct.std::_Rb_tree_node_base"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE5beginEv(%"class.std::_Rb_tree"* %5) #3
  %7 = getelementptr inbounds %"struct.std::_Rb_tree_iterator", %"struct.std::_Rb_tree_iterator"* %2, i32 0, i32 0
  store %"struct.std::_Rb_tree_node_base"* %6, %"struct.std::_Rb_tree_node_base"** %7, align 8
  %8 = getelementptr inbounds %"struct.std::_Rb_tree_iterator", %"struct.std::_Rb_tree_iterator"* %2, i32 0, i32 0
  %9 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %8, align 8
  ret %"struct.std::_Rb_tree_node_base"* %9
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"struct.std::_Rb_tree_node_base"* @_ZNSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS0_EEE3endEv(%"class.std::map"*) #4 comdat align 2 {
  %2 = alloca %"struct.std::_Rb_tree_iterator", align 8
  %3 = alloca %"class.std::map"*, align 8
  store %"class.std::map"* %0, %"class.std::map"** %3, align 8
  %4 = load %"class.std::map"*, %"class.std::map"** %3, align 8
  %5 = getelementptr inbounds %"class.std::map", %"class.std::map"* %4, i32 0, i32 0
  %6 = call %"struct.std::_Rb_tree_node_base"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE3endEv(%"class.std::_Rb_tree"* %5) #3
  %7 = getelementptr inbounds %"struct.std::_Rb_tree_iterator", %"struct.std::_Rb_tree_iterator"* %2, i32 0, i32 0
  store %"struct.std::_Rb_tree_node_base"* %6, %"struct.std::_Rb_tree_node_base"** %7, align 8
  %8 = getelementptr inbounds %"struct.std::_Rb_tree_iterator", %"struct.std::_Rb_tree_iterator"* %2, i32 0, i32 0
  %9 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %8, align 8
  ret %"struct.std::_Rb_tree_node_base"* %9
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local zeroext i1 @_ZStneRKSt17_Rb_tree_iteratorISt4pairIKi9NonDetLogEES6_(%"struct.std::_Rb_tree_iterator"* dereferenceable(8), %"struct.std::_Rb_tree_iterator"* dereferenceable(8)) #4 comdat {
  %3 = alloca %"struct.std::_Rb_tree_iterator"*, align 8
  %4 = alloca %"struct.std::_Rb_tree_iterator"*, align 8
  store %"struct.std::_Rb_tree_iterator"* %0, %"struct.std::_Rb_tree_iterator"** %3, align 8
  store %"struct.std::_Rb_tree_iterator"* %1, %"struct.std::_Rb_tree_iterator"** %4, align 8
  %5 = load %"struct.std::_Rb_tree_iterator"*, %"struct.std::_Rb_tree_iterator"** %3, align 8
  %6 = getelementptr inbounds %"struct.std::_Rb_tree_iterator", %"struct.std::_Rb_tree_iterator"* %5, i32 0, i32 0
  %7 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %6, align 8
  %8 = load %"struct.std::_Rb_tree_iterator"*, %"struct.std::_Rb_tree_iterator"** %4, align 8
  %9 = getelementptr inbounds %"struct.std::_Rb_tree_iterator", %"struct.std::_Rb_tree_iterator"* %8, i32 0, i32 0
  %10 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %9, align 8
  %11 = icmp ne %"struct.std::_Rb_tree_node_base"* %7, %10
  ret i1 %11
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(64) %"struct.std::pair"* @_ZNKSt17_Rb_tree_iteratorISt4pairIKi9NonDetLogEEdeEv(%"struct.std::_Rb_tree_iterator"*) #4 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %2 = alloca %"struct.std::_Rb_tree_iterator"*, align 8
  store %"struct.std::_Rb_tree_iterator"* %0, %"struct.std::_Rb_tree_iterator"** %2, align 8
  %3 = load %"struct.std::_Rb_tree_iterator"*, %"struct.std::_Rb_tree_iterator"** %2, align 8
  %4 = getelementptr inbounds %"struct.std::_Rb_tree_iterator", %"struct.std::_Rb_tree_iterator"* %3, i32 0, i32 0
  %5 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %4, align 8
  %6 = bitcast %"struct.std::_Rb_tree_node_base"* %5 to %"struct.std::_Rb_tree_node"*
  %7 = invoke %"struct.std::pair"* @_ZNSt13_Rb_tree_nodeISt4pairIKi9NonDetLogEE9_M_valptrEv(%"struct.std::_Rb_tree_node"* %6)
          to label %8 unwind label %9

; <label>:8:                                      ; preds = %1
  ret %"struct.std::pair"* %7

; <label>:9:                                      ; preds = %1
  %10 = landingpad { i8*, i32 }
          catch i8* null
  %11 = extractvalue { i8*, i32 } %10, 0
  call void @__clang_call_terminate(i8* %11) #16
  unreachable
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZNSt4pairIKi9NonDetLogEC2ERKS2_(%"struct.std::pair"*, %"struct.std::pair"* dereferenceable(64)) unnamed_addr #5 comdat align 2 {
  %3 = alloca %"struct.std::pair"*, align 8
  %4 = alloca %"struct.std::pair"*, align 8
  store %"struct.std::pair"* %0, %"struct.std::pair"** %3, align 8
  store %"struct.std::pair"* %1, %"struct.std::pair"** %4, align 8
  %5 = load %"struct.std::pair"*, %"struct.std::pair"** %3, align 8
  %6 = bitcast %"struct.std::pair"* %5 to %"class.std::__pair_base"*
  %7 = load %"struct.std::pair"*, %"struct.std::pair"** %4, align 8
  %8 = bitcast %"struct.std::pair"* %7 to %"class.std::__pair_base"*
  %9 = getelementptr inbounds %"struct.std::pair", %"struct.std::pair"* %5, i32 0, i32 0
  %10 = load %"struct.std::pair"*, %"struct.std::pair"** %4, align 8
  %11 = getelementptr inbounds %"struct.std::pair", %"struct.std::pair"* %10, i32 0, i32 0
  %12 = load i32, i32* %11, align 8
  store i32 %12, i32* %9, align 8
  %13 = getelementptr inbounds %"struct.std::pair", %"struct.std::pair"* %5, i32 0, i32 1
  %14 = load %"struct.std::pair"*, %"struct.std::pair"** %4, align 8
  %15 = getelementptr inbounds %"struct.std::pair", %"struct.std::pair"* %14, i32 0, i32 1
  call void @_ZN9NonDetLogC2ERKS_(%class.NonDetLog* %13, %class.NonDetLog* dereferenceable(56) %15)
  ret void
}

declare dso_local dereferenceable(272) %"class.std::basic_ostream"* @_ZNSolsEi(%"class.std::basic_ostream"*, i32) #1

declare dso_local dereferenceable(272) %"class.std::basic_ostream"* @_ZNSolsEj(%"class.std::basic_ostream"*, i32) #1

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local dereferenceable(272) %"class.std::basic_ostream"* @_ZN5boostlsIcSt11char_traitsIcEiJjcdfEEERSt13basic_ostreamIT_T0_ES7_RKNS_7variantIT1_JDpT2_EEE(%"class.std::basic_ostream"* dereferenceable(272), %"class.boost::variant"* dereferenceable(16)) #5 comdat {
  %3 = alloca %"class.std::basic_ostream"*, align 8
  %4 = alloca %"class.boost::variant"*, align 8
  %5 = alloca %"class.boost::detail::variant::printer", align 8
  store %"class.std::basic_ostream"* %0, %"class.std::basic_ostream"** %3, align 8
  store %"class.boost::variant"* %1, %"class.boost::variant"** %4, align 8
  %6 = load %"class.std::basic_ostream"*, %"class.std::basic_ostream"** %3, align 8
  call void @_ZN5boost6detail7variant7printerISoEC2ERSo(%"class.boost::detail::variant::printer"* %5, %"class.std::basic_ostream"* dereferenceable(272) %6)
  %7 = load %"class.boost::variant"*, %"class.boost::variant"** %4, align 8
  call void @_ZNKR5boost7variantIiJjcdfEE13apply_visitorINS_6detail7variant7printerISoEEEENT_11result_typeERS7_(%"class.boost::variant"* %7, %"class.boost::detail::variant::printer"* dereferenceable(8) %5)
  %8 = load %"class.std::basic_ostream"*, %"class.std::basic_ostream"** %3, align 8
  ret %"class.std::basic_ostream"* %8
}

declare dso_local dereferenceable(272) %"class.std::basic_ostream"* @_ZStlsIcSt11char_traitsIcESaIcEERSt13basic_ostreamIT_T0_ES7_RKNSt7__cxx1112basic_stringIS4_S5_T1_EE(%"class.std::basic_ostream"* dereferenceable(272), %"class.std::__cxx11::basic_string"* dereferenceable(32)) #1

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN9ContainerI9NonDetLogE22getNonDetLogTypeValue_B5cxx11ES0_(%"class.std::__cxx11::basic_string"* noalias sret, %class.Container*, %class.NonDetLog*) #5 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %4 = alloca %class.Container*, align 8
  %5 = alloca i1, align 1
  %6 = alloca i8*
  %7 = alloca i32
  store %class.Container* %1, %class.Container** %4, align 8
  %8 = load %class.Container*, %class.Container** %4, align 8
  store i1 false, i1* %5, align 1
  call void @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1Ev(%"class.std::__cxx11::basic_string"* %0) #3
  %9 = getelementptr inbounds %class.NonDetLog, %class.NonDetLog* %2, i32 0, i32 2
  %10 = invoke dereferenceable(16) %"class.std::type_info"* @_ZNK5boost7variantIiJjcdfEE4typeEv(%"class.boost::variant"* %9)
          to label %11 unwind label %16

; <label>:11:                                     ; preds = %3
  %12 = call zeroext i1 @_ZNKSt9type_infoeqERKS_(%"class.std::type_info"* %10, %"class.std::type_info"* dereferenceable(16) bitcast (i8** @_ZTIi to %"class.std::type_info"*)) #3
  br i1 %12, label %13, label %20

; <label>:13:                                     ; preds = %11
  %14 = invoke dereferenceable(32) %"class.std::__cxx11::basic_string"* @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSEPKc(%"class.std::__cxx11::basic_string"* %0, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str.6, i32 0, i32 0))
          to label %15 unwind label %16

; <label>:15:                                     ; preds = %13
  br label %20

; <label>:16:                                     ; preds = %49, %44, %41, %36, %33, %28, %25, %20, %13, %3
  %17 = landingpad { i8*, i32 }
          cleanup
  %18 = extractvalue { i8*, i32 } %17, 0
  store i8* %18, i8** %6, align 8
  %19 = extractvalue { i8*, i32 } %17, 1
  store i32 %19, i32* %7, align 4
  call void @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEED1Ev(%"class.std::__cxx11::basic_string"* %0) #3
  br label %56

; <label>:20:                                     ; preds = %15, %11
  %21 = getelementptr inbounds %class.NonDetLog, %class.NonDetLog* %2, i32 0, i32 2
  %22 = invoke dereferenceable(16) %"class.std::type_info"* @_ZNK5boost7variantIiJjcdfEE4typeEv(%"class.boost::variant"* %21)
          to label %23 unwind label %16

; <label>:23:                                     ; preds = %20
  %24 = call zeroext i1 @_ZNKSt9type_infoeqERKS_(%"class.std::type_info"* %22, %"class.std::type_info"* dereferenceable(16) bitcast (i8** @_ZTIj to %"class.std::type_info"*)) #3
  br i1 %24, label %25, label %28

; <label>:25:                                     ; preds = %23
  %26 = invoke dereferenceable(32) %"class.std::__cxx11::basic_string"* @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSEPKc(%"class.std::__cxx11::basic_string"* %0, i8* getelementptr inbounds ([9 x i8], [9 x i8]* @.str.7, i32 0, i32 0))
          to label %27 unwind label %16

; <label>:27:                                     ; preds = %25
  br label %28

; <label>:28:                                     ; preds = %27, %23
  %29 = getelementptr inbounds %class.NonDetLog, %class.NonDetLog* %2, i32 0, i32 2
  %30 = invoke dereferenceable(16) %"class.std::type_info"* @_ZNK5boost7variantIiJjcdfEE4typeEv(%"class.boost::variant"* %29)
          to label %31 unwind label %16

; <label>:31:                                     ; preds = %28
  %32 = call zeroext i1 @_ZNKSt9type_infoeqERKS_(%"class.std::type_info"* %30, %"class.std::type_info"* dereferenceable(16) bitcast (i8** @_ZTIc to %"class.std::type_info"*)) #3
  br i1 %32, label %33, label %36

; <label>:33:                                     ; preds = %31
  %34 = invoke dereferenceable(32) %"class.std::__cxx11::basic_string"* @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSEPKc(%"class.std::__cxx11::basic_string"* %0, i8* getelementptr inbounds ([5 x i8], [5 x i8]* @.str.8, i32 0, i32 0))
          to label %35 unwind label %16

; <label>:35:                                     ; preds = %33
  br label %36

; <label>:36:                                     ; preds = %35, %31
  %37 = getelementptr inbounds %class.NonDetLog, %class.NonDetLog* %2, i32 0, i32 2
  %38 = invoke dereferenceable(16) %"class.std::type_info"* @_ZNK5boost7variantIiJjcdfEE4typeEv(%"class.boost::variant"* %37)
          to label %39 unwind label %16

; <label>:39:                                     ; preds = %36
  %40 = call zeroext i1 @_ZNKSt9type_infoeqERKS_(%"class.std::type_info"* %38, %"class.std::type_info"* dereferenceable(16) bitcast (i8** @_ZTId to %"class.std::type_info"*)) #3
  br i1 %40, label %41, label %44

; <label>:41:                                     ; preds = %39
  %42 = invoke dereferenceable(32) %"class.std::__cxx11::basic_string"* @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSEPKc(%"class.std::__cxx11::basic_string"* %0, i8* getelementptr inbounds ([7 x i8], [7 x i8]* @.str.9, i32 0, i32 0))
          to label %43 unwind label %16

; <label>:43:                                     ; preds = %41
  br label %44

; <label>:44:                                     ; preds = %43, %39
  %45 = getelementptr inbounds %class.NonDetLog, %class.NonDetLog* %2, i32 0, i32 2
  %46 = invoke dereferenceable(16) %"class.std::type_info"* @_ZNK5boost7variantIiJjcdfEE4typeEv(%"class.boost::variant"* %45)
          to label %47 unwind label %16

; <label>:47:                                     ; preds = %44
  %48 = call zeroext i1 @_ZNKSt9type_infoeqERKS_(%"class.std::type_info"* %46, %"class.std::type_info"* dereferenceable(16) bitcast (i8** @_ZTIf to %"class.std::type_info"*)) #3
  br i1 %48, label %49, label %52

; <label>:49:                                     ; preds = %47
  %50 = invoke dereferenceable(32) %"class.std::__cxx11::basic_string"* @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSEPKc(%"class.std::__cxx11::basic_string"* %0, i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.str.10, i32 0, i32 0))
          to label %51 unwind label %16

; <label>:51:                                     ; preds = %49
  br label %52

; <label>:52:                                     ; preds = %51, %47
  store i1 true, i1* %5, align 1
  %53 = load i1, i1* %5, align 1
  br i1 %53, label %55, label %54

; <label>:54:                                     ; preds = %52
  call void @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEED1Ev(%"class.std::__cxx11::basic_string"* %0) #3
  br label %55

; <label>:55:                                     ; preds = %54, %52
  ret void

; <label>:56:                                     ; preds = %16
  %57 = load i8*, i8** %6, align 8
  %58 = load i32, i32* %7, align 4
  %59 = insertvalue { i8*, i32 } undef, i8* %57, 0
  %60 = insertvalue { i8*, i32 } %59, i32 %58, 1
  resume { i8*, i32 } %60
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN9NonDetLogC2ERKS_(%class.NonDetLog*, %class.NonDetLog* dereferenceable(56)) unnamed_addr #5 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %3 = alloca %class.NonDetLog*, align 8
  %4 = alloca %class.NonDetLog*, align 8
  %5 = alloca i8*
  %6 = alloca i32
  store %class.NonDetLog* %0, %class.NonDetLog** %3, align 8
  store %class.NonDetLog* %1, %class.NonDetLog** %4, align 8
  %7 = load %class.NonDetLog*, %class.NonDetLog** %3, align 8
  %8 = getelementptr inbounds %class.NonDetLog, %class.NonDetLog* %7, i32 0, i32 0
  %9 = load %class.NonDetLog*, %class.NonDetLog** %4, align 8
  %10 = getelementptr inbounds %class.NonDetLog, %class.NonDetLog* %9, i32 0, i32 0
  %11 = bitcast i32* %8 to i8*
  %12 = bitcast i32* %10 to i8*
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 8 %11, i8* align 8 %12, i64 8, i1 false)
  %13 = getelementptr inbounds %class.NonDetLog, %class.NonDetLog* %7, i32 0, i32 2
  %14 = load %class.NonDetLog*, %class.NonDetLog** %4, align 8
  %15 = getelementptr inbounds %class.NonDetLog, %class.NonDetLog* %14, i32 0, i32 2
  call void @_ZN5boost7variantIiJjcdfEEC2ERKS1_(%"class.boost::variant"* %13, %"class.boost::variant"* dereferenceable(16) %15)
  %16 = getelementptr inbounds %class.NonDetLog, %class.NonDetLog* %7, i32 0, i32 3
  %17 = load %class.NonDetLog*, %class.NonDetLog** %4, align 8
  %18 = getelementptr inbounds %class.NonDetLog, %class.NonDetLog* %17, i32 0, i32 3
  invoke void @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1ERKS4_(%"class.std::__cxx11::basic_string"* %16, %"class.std::__cxx11::basic_string"* dereferenceable(32) %18)
          to label %19 unwind label %20

; <label>:19:                                     ; preds = %2
  ret void

; <label>:20:                                     ; preds = %2
  %21 = landingpad { i8*, i32 }
          cleanup
  %22 = extractvalue { i8*, i32 } %21, 0
  store i8* %22, i8** %5, align 8
  %23 = extractvalue { i8*, i32 } %21, 1
  store i32 %23, i32* %6, align 4
  call void @_ZN5boost7variantIiJjcdfEED2Ev(%"class.boost::variant"* %13) #3
  br label %24

; <label>:24:                                     ; preds = %20
  %25 = load i8*, i8** %5, align 8
  %26 = load i32, i32* %6, align 4
  %27 = insertvalue { i8*, i32 } undef, i8* %25, 0
  %28 = insertvalue { i8*, i32 } %27, i32 %26, 1
  resume { i8*, i32 } %28
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(8) %"struct.std::_Rb_tree_iterator"* @_ZNSt17_Rb_tree_iteratorISt4pairIKi9NonDetLogEEppEv(%"struct.std::_Rb_tree_iterator"*) #4 comdat align 2 {
  %2 = alloca %"struct.std::_Rb_tree_iterator"*, align 8
  store %"struct.std::_Rb_tree_iterator"* %0, %"struct.std::_Rb_tree_iterator"** %2, align 8
  %3 = load %"struct.std::_Rb_tree_iterator"*, %"struct.std::_Rb_tree_iterator"** %2, align 8
  %4 = getelementptr inbounds %"struct.std::_Rb_tree_iterator", %"struct.std::_Rb_tree_iterator"* %3, i32 0, i32 0
  %5 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %4, align 8
  %6 = call %"struct.std::_Rb_tree_node_base"* @_ZSt18_Rb_tree_incrementPSt18_Rb_tree_node_base(%"struct.std::_Rb_tree_node_base"* %5) #18
  %7 = getelementptr inbounds %"struct.std::_Rb_tree_iterator", %"struct.std::_Rb_tree_iterator"* %3, i32 0, i32 0
  store %"struct.std::_Rb_tree_node_base"* %6, %"struct.std::_Rb_tree_node_base"** %7, align 8
  ret %"struct.std::_Rb_tree_iterator"* %3
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(8) %"struct.std::_List_iterator"* @_ZNSt14_List_iteratorISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEEppEv(%"struct.std::_List_iterator"*) #4 comdat align 2 {
  %2 = alloca %"struct.std::_List_iterator"*, align 8
  store %"struct.std::_List_iterator"* %0, %"struct.std::_List_iterator"** %2, align 8
  %3 = load %"struct.std::_List_iterator"*, %"struct.std::_List_iterator"** %2, align 8
  %4 = getelementptr inbounds %"struct.std::_List_iterator", %"struct.std::_List_iterator"* %3, i32 0, i32 0
  %5 = load %"struct.std::__detail::_List_node_base"*, %"struct.std::__detail::_List_node_base"** %4, align 8
  %6 = getelementptr inbounds %"struct.std::__detail::_List_node_base", %"struct.std::__detail::_List_node_base"* %5, i32 0, i32 0
  %7 = load %"struct.std::__detail::_List_node_base"*, %"struct.std::__detail::_List_node_base"** %6, align 8
  %8 = getelementptr inbounds %"struct.std::_List_iterator", %"struct.std::_List_iterator"* %3, i32 0, i32 0
  store %"struct.std::__detail::_List_node_base"* %7, %"struct.std::__detail::_List_node_base"** %8, align 8
  ret %"struct.std::_List_iterator"* %3
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(8) %"struct.std::_List_iterator"* @_ZNSt14_List_iteratorISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEEmmEv(%"struct.std::_List_iterator"*) #4 comdat align 2 {
  %2 = alloca %"struct.std::_List_iterator"*, align 8
  store %"struct.std::_List_iterator"* %0, %"struct.std::_List_iterator"** %2, align 8
  %3 = load %"struct.std::_List_iterator"*, %"struct.std::_List_iterator"** %2, align 8
  %4 = getelementptr inbounds %"struct.std::_List_iterator", %"struct.std::_List_iterator"* %3, i32 0, i32 0
  %5 = load %"struct.std::__detail::_List_node_base"*, %"struct.std::__detail::_List_node_base"** %4, align 8
  %6 = getelementptr inbounds %"struct.std::__detail::_List_node_base", %"struct.std::__detail::_List_node_base"* %5, i32 0, i32 1
  %7 = load %"struct.std::__detail::_List_node_base"*, %"struct.std::__detail::_List_node_base"** %6, align 8
  %8 = getelementptr inbounds %"struct.std::_List_iterator", %"struct.std::_List_iterator"* %3, i32 0, i32 0
  store %"struct.std::__detail::_List_node_base"* %7, %"struct.std::__detail::_List_node_base"** %8, align 8
  ret %"struct.std::_List_iterator"* %3
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local i64 @_ZNKSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE4sizeEv(%"class.std::_Rb_tree"*) #4 comdat align 2 {
  %2 = alloca %"class.std::_Rb_tree"*, align 8
  store %"class.std::_Rb_tree"* %0, %"class.std::_Rb_tree"** %2, align 8
  %3 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %2, align 8
  %4 = getelementptr inbounds %"class.std::_Rb_tree", %"class.std::_Rb_tree"* %3, i32 0, i32 0
  %5 = bitcast %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %4 to i8*
  %6 = getelementptr inbounds i8, i8* %5, i64 8
  %7 = bitcast i8* %6 to %"struct.std::_Rb_tree_header"*
  %8 = getelementptr inbounds %"struct.std::_Rb_tree_header", %"struct.std::_Rb_tree_header"* %7, i32 0, i32 1
  %9 = load i64, i64* %8, align 8
  ret i64 %9
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt14_List_iteratorISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEEC2EPNSt8__detail15_List_node_baseE(%"struct.std::_List_iterator"*, %"struct.std::__detail::_List_node_base"*) unnamed_addr #4 comdat align 2 {
  %3 = alloca %"struct.std::_List_iterator"*, align 8
  %4 = alloca %"struct.std::__detail::_List_node_base"*, align 8
  store %"struct.std::_List_iterator"* %0, %"struct.std::_List_iterator"** %3, align 8
  store %"struct.std::__detail::_List_node_base"* %1, %"struct.std::__detail::_List_node_base"** %4, align 8
  %5 = load %"struct.std::_List_iterator"*, %"struct.std::_List_iterator"** %3, align 8
  %6 = getelementptr inbounds %"struct.std::_List_iterator", %"struct.std::_List_iterator"* %5, i32 0, i32 0
  %7 = load %"struct.std::__detail::_List_node_base"*, %"struct.std::__detail::_List_node_base"** %4, align 8
  store %"struct.std::__detail::_List_node_base"* %7, %"struct.std::__detail::_List_node_base"** %6, align 8
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EEC2ERKS9_(%"class.std::_Rb_tree"*, %"class.std::_Rb_tree"* dereferenceable(48)) unnamed_addr #5 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %3 = alloca %"class.std::_Rb_tree"*, align 8
  %4 = alloca %"class.std::_Rb_tree"*, align 8
  %5 = alloca i8*
  %6 = alloca i32
  store %"class.std::_Rb_tree"* %0, %"class.std::_Rb_tree"** %3, align 8
  store %"class.std::_Rb_tree"* %1, %"class.std::_Rb_tree"** %4, align 8
  %7 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %3, align 8
  %8 = getelementptr inbounds %"class.std::_Rb_tree", %"class.std::_Rb_tree"* %7, i32 0, i32 0
  %9 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %4, align 8
  %10 = getelementptr inbounds %"class.std::_Rb_tree", %"class.std::_Rb_tree"* %9, i32 0, i32 0
  call void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE13_Rb_tree_implIS7_Lb1EEC2ERKSB_(%"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %8, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* dereferenceable(48) %10)
  %11 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %4, align 8
  %12 = call %"struct.std::_Rb_tree_node_base"* @_ZNKSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE7_M_rootEv(%"class.std::_Rb_tree"* %11) #3
  %13 = icmp ne %"struct.std::_Rb_tree_node_base"* %12, null
  br i1 %13, label %14, label %24

; <label>:14:                                     ; preds = %2
  %15 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %4, align 8
  %16 = invoke %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE7_M_copyERKS9_(%"class.std::_Rb_tree"* %7, %"class.std::_Rb_tree"* dereferenceable(48) %15)
          to label %17 unwind label %20

; <label>:17:                                     ; preds = %14
  %18 = bitcast %"struct.std::_Rb_tree_node"* %16 to %"struct.std::_Rb_tree_node_base"*
  %19 = call dereferenceable(8) %"struct.std::_Rb_tree_node_base"** @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE7_M_rootEv(%"class.std::_Rb_tree"* %7) #3
  store %"struct.std::_Rb_tree_node_base"* %18, %"struct.std::_Rb_tree_node_base"** %19, align 8
  br label %24

; <label>:20:                                     ; preds = %14
  %21 = landingpad { i8*, i32 }
          cleanup
  %22 = extractvalue { i8*, i32 } %21, 0
  store i8* %22, i8** %5, align 8
  %23 = extractvalue { i8*, i32 } %21, 1
  store i32 %23, i32* %6, align 4
  call void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE13_Rb_tree_implIS7_Lb1EED2Ev(%"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %8) #3
  br label %25

; <label>:24:                                     ; preds = %17, %2
  ret void

; <label>:25:                                     ; preds = %20
  %26 = load i8*, i8** %5, align 8
  %27 = load i32, i32* %6, align 4
  %28 = insertvalue { i8*, i32 } undef, i8* %26, 0
  %29 = insertvalue { i8*, i32 } %28, i32 %27, 1
  resume { i8*, i32 } %29
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE13_Rb_tree_implIS7_Lb1EEC2ERKSB_(%"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"*, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* dereferenceable(48)) unnamed_addr #5 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %3 = alloca %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"*, align 8
  %4 = alloca %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"*, align 8
  %5 = alloca %"class.std::allocator.3", align 1
  %6 = alloca i8*
  %7 = alloca i32
  store %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %0, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"** %3, align 8
  store %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %1, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"** %4, align 8
  %8 = load %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"*, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"** %3, align 8
  %9 = bitcast %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %8 to %"class.std::allocator.3"*
  %10 = load %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"*, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"** %4, align 8
  %11 = bitcast %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %10 to %"class.std::allocator.3"*
  call void @_ZN9__gnu_cxx14__alloc_traitsISaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEES6_E17_S_select_on_copyERKS7_(%"class.std::allocator.3"* sret %5, %"class.std::allocator.3"* dereferenceable(1) %11)
  call void @_ZNSaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEC2ERKS5_(%"class.std::allocator.3"* %9, %"class.std::allocator.3"* dereferenceable(1) %5) #3
  call void @_ZNSaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEED2Ev(%"class.std::allocator.3"* %5) #3
  %12 = bitcast %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %8 to %"struct.std::_Rb_tree_key_compare"*
  %13 = load %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"*, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"** %4, align 8
  %14 = bitcast %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %13 to %"struct.std::_Rb_tree_key_compare"*
  %15 = getelementptr inbounds %"struct.std::_Rb_tree_key_compare", %"struct.std::_Rb_tree_key_compare"* %14, i32 0, i32 0
  invoke void @_ZNSt20_Rb_tree_key_compareISt4lessIiEEC2ERKS1_(%"struct.std::_Rb_tree_key_compare"* %12, %"struct.std::less"* dereferenceable(1) %15)
          to label %16 unwind label %20

; <label>:16:                                     ; preds = %2
  %17 = bitcast %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %8 to i8*
  %18 = getelementptr inbounds i8, i8* %17, i64 8
  %19 = bitcast i8* %18 to %"struct.std::_Rb_tree_header"*
  call void @_ZNSt15_Rb_tree_headerC2Ev(%"struct.std::_Rb_tree_header"* %19) #3
  ret void

; <label>:20:                                     ; preds = %2
  %21 = landingpad { i8*, i32 }
          cleanup
  %22 = extractvalue { i8*, i32 } %21, 0
  store i8* %22, i8** %6, align 8
  %23 = extractvalue { i8*, i32 } %21, 1
  store i32 %23, i32* %7, align 4
  %24 = bitcast %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %8 to %"class.std::allocator.3"*
  call void @_ZNSaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEED2Ev(%"class.std::allocator.3"* %24) #3
  br label %25

; <label>:25:                                     ; preds = %20
  %26 = load i8*, i8** %6, align 8
  %27 = load i32, i32* %7, align 4
  %28 = insertvalue { i8*, i32 } undef, i8* %26, 0
  %29 = insertvalue { i8*, i32 } %28, i32 %27, 1
  resume { i8*, i32 } %29
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"struct.std::_Rb_tree_node_base"* @_ZNKSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE7_M_rootEv(%"class.std::_Rb_tree"*) #4 comdat align 2 {
  %2 = alloca %"class.std::_Rb_tree"*, align 8
  store %"class.std::_Rb_tree"* %0, %"class.std::_Rb_tree"** %2, align 8
  %3 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %2, align 8
  %4 = getelementptr inbounds %"class.std::_Rb_tree", %"class.std::_Rb_tree"* %3, i32 0, i32 0
  %5 = bitcast %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %4 to i8*
  %6 = getelementptr inbounds i8, i8* %5, i64 8
  %7 = bitcast i8* %6 to %"struct.std::_Rb_tree_header"*
  %8 = getelementptr inbounds %"struct.std::_Rb_tree_header", %"struct.std::_Rb_tree_header"* %7, i32 0, i32 0
  %9 = getelementptr inbounds %"struct.std::_Rb_tree_node_base", %"struct.std::_Rb_tree_node_base"* %8, i32 0, i32 1
  %10 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %9, align 8
  ret %"struct.std::_Rb_tree_node_base"* %10
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE7_M_copyERKS9_(%"class.std::_Rb_tree"*, %"class.std::_Rb_tree"* dereferenceable(48)) #5 comdat align 2 {
  %3 = alloca %"class.std::_Rb_tree"*, align 8
  %4 = alloca %"class.std::_Rb_tree"*, align 8
  %5 = alloca %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node", align 8
  store %"class.std::_Rb_tree"* %0, %"class.std::_Rb_tree"** %3, align 8
  store %"class.std::_Rb_tree"* %1, %"class.std::_Rb_tree"** %4, align 8
  %6 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %3, align 8
  call void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE11_Alloc_nodeC2ERS9_(%"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"* %5, %"class.std::_Rb_tree"* dereferenceable(48) %6)
  %7 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %4, align 8
  %8 = call %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE7_M_copyINS9_11_Alloc_nodeEEEPSt13_Rb_tree_nodeIS3_ERKS9_RT_(%"class.std::_Rb_tree"* %6, %"class.std::_Rb_tree"* dereferenceable(48) %7, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"* dereferenceable(8) %5)
  ret %"struct.std::_Rb_tree_node"* %8
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(8) %"struct.std::_Rb_tree_node_base"** @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE7_M_rootEv(%"class.std::_Rb_tree"*) #4 comdat align 2 {
  %2 = alloca %"class.std::_Rb_tree"*, align 8
  store %"class.std::_Rb_tree"* %0, %"class.std::_Rb_tree"** %2, align 8
  %3 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %2, align 8
  %4 = getelementptr inbounds %"class.std::_Rb_tree", %"class.std::_Rb_tree"* %3, i32 0, i32 0
  %5 = bitcast %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %4 to i8*
  %6 = getelementptr inbounds i8, i8* %5, i64 8
  %7 = bitcast i8* %6 to %"struct.std::_Rb_tree_header"*
  %8 = getelementptr inbounds %"struct.std::_Rb_tree_header", %"struct.std::_Rb_tree_header"* %7, i32 0, i32 0
  %9 = getelementptr inbounds %"struct.std::_Rb_tree_node_base", %"struct.std::_Rb_tree_node_base"* %8, i32 0, i32 1
  ret %"struct.std::_Rb_tree_node_base"** %9
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN9__gnu_cxx14__alloc_traitsISaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEES6_E17_S_select_on_copyERKS7_(%"class.std::allocator.3"* noalias sret, %"class.std::allocator.3"* dereferenceable(1)) #5 comdat align 2 {
  %3 = alloca %"class.std::allocator.3"*, align 8
  store %"class.std::allocator.3"* %1, %"class.std::allocator.3"** %3, align 8
  %4 = load %"class.std::allocator.3"*, %"class.std::allocator.3"** %3, align 8
  call void @_ZNSt16allocator_traitsISaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEE37select_on_container_copy_constructionERKS6_(%"class.std::allocator.3"* sret %0, %"class.std::allocator.3"* dereferenceable(1) %4)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEED2Ev(%"class.std::allocator.3"*) unnamed_addr #4 comdat align 2 {
  %2 = alloca %"class.std::allocator.3"*, align 8
  store %"class.std::allocator.3"* %0, %"class.std::allocator.3"** %2, align 8
  %3 = load %"class.std::allocator.3"*, %"class.std::allocator.3"** %2, align 8
  %4 = bitcast %"class.std::allocator.3"* %3 to %"class.__gnu_cxx::new_allocator.4"*
  call void @_ZN9__gnu_cxx13new_allocatorISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEED2Ev(%"class.__gnu_cxx::new_allocator.4"* %4) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt20_Rb_tree_key_compareISt4lessIiEEC2ERKS1_(%"struct.std::_Rb_tree_key_compare"*, %"struct.std::less"* dereferenceable(1)) unnamed_addr #4 comdat align 2 {
  %3 = alloca %"struct.std::_Rb_tree_key_compare"*, align 8
  %4 = alloca %"struct.std::less"*, align 8
  store %"struct.std::_Rb_tree_key_compare"* %0, %"struct.std::_Rb_tree_key_compare"** %3, align 8
  store %"struct.std::less"* %1, %"struct.std::less"** %4, align 8
  %5 = load %"struct.std::_Rb_tree_key_compare"*, %"struct.std::_Rb_tree_key_compare"** %3, align 8
  %6 = getelementptr inbounds %"struct.std::_Rb_tree_key_compare", %"struct.std::_Rb_tree_key_compare"* %5, i32 0, i32 0
  %7 = load %"struct.std::less"*, %"struct.std::less"** %4, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt15_Rb_tree_headerC2Ev(%"struct.std::_Rb_tree_header"*) unnamed_addr #4 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %2 = alloca %"struct.std::_Rb_tree_header"*, align 8
  store %"struct.std::_Rb_tree_header"* %0, %"struct.std::_Rb_tree_header"** %2, align 8
  %3 = load %"struct.std::_Rb_tree_header"*, %"struct.std::_Rb_tree_header"** %2, align 8
  %4 = getelementptr inbounds %"struct.std::_Rb_tree_header", %"struct.std::_Rb_tree_header"* %3, i32 0, i32 0
  %5 = getelementptr inbounds %"struct.std::_Rb_tree_header", %"struct.std::_Rb_tree_header"* %3, i32 0, i32 0
  %6 = getelementptr inbounds %"struct.std::_Rb_tree_node_base", %"struct.std::_Rb_tree_node_base"* %5, i32 0, i32 0
  store i32 0, i32* %6, align 8
  invoke void @_ZNSt15_Rb_tree_header8_M_resetEv(%"struct.std::_Rb_tree_header"* %3)
          to label %7 unwind label %8

; <label>:7:                                      ; preds = %1
  ret void

; <label>:8:                                      ; preds = %1
  %9 = landingpad { i8*, i32 }
          catch i8* null
  %10 = extractvalue { i8*, i32 } %9, 0
  call void @__clang_call_terminate(i8* %10) #16
  unreachable
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt16allocator_traitsISaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEE37select_on_container_copy_constructionERKS6_(%"class.std::allocator.3"* noalias sret, %"class.std::allocator.3"* dereferenceable(1)) #4 comdat align 2 {
  %3 = alloca %"class.std::allocator.3"*, align 8
  store %"class.std::allocator.3"* %1, %"class.std::allocator.3"** %3, align 8
  %4 = load %"class.std::allocator.3"*, %"class.std::allocator.3"** %3, align 8
  call void @_ZNSaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEC2ERKS5_(%"class.std::allocator.3"* %0, %"class.std::allocator.3"* dereferenceable(1) %4) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEC2ERKS5_(%"class.std::allocator.3"*, %"class.std::allocator.3"* dereferenceable(1)) unnamed_addr #4 comdat align 2 {
  %3 = alloca %"class.std::allocator.3"*, align 8
  %4 = alloca %"class.std::allocator.3"*, align 8
  store %"class.std::allocator.3"* %0, %"class.std::allocator.3"** %3, align 8
  store %"class.std::allocator.3"* %1, %"class.std::allocator.3"** %4, align 8
  %5 = load %"class.std::allocator.3"*, %"class.std::allocator.3"** %3, align 8
  %6 = bitcast %"class.std::allocator.3"* %5 to %"class.__gnu_cxx::new_allocator.4"*
  %7 = load %"class.std::allocator.3"*, %"class.std::allocator.3"** %4, align 8
  %8 = bitcast %"class.std::allocator.3"* %7 to %"class.__gnu_cxx::new_allocator.4"*
  call void @_ZN9__gnu_cxx13new_allocatorISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEC2ERKS7_(%"class.__gnu_cxx::new_allocator.4"* %6, %"class.__gnu_cxx::new_allocator.4"* dereferenceable(1) %8) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN9__gnu_cxx13new_allocatorISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEC2ERKS7_(%"class.__gnu_cxx::new_allocator.4"*, %"class.__gnu_cxx::new_allocator.4"* dereferenceable(1)) unnamed_addr #4 comdat align 2 {
  %3 = alloca %"class.__gnu_cxx::new_allocator.4"*, align 8
  %4 = alloca %"class.__gnu_cxx::new_allocator.4"*, align 8
  store %"class.__gnu_cxx::new_allocator.4"* %0, %"class.__gnu_cxx::new_allocator.4"** %3, align 8
  store %"class.__gnu_cxx::new_allocator.4"* %1, %"class.__gnu_cxx::new_allocator.4"** %4, align 8
  %5 = load %"class.__gnu_cxx::new_allocator.4"*, %"class.__gnu_cxx::new_allocator.4"** %3, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt15_Rb_tree_header8_M_resetEv(%"struct.std::_Rb_tree_header"*) #4 comdat align 2 {
  %2 = alloca %"struct.std::_Rb_tree_header"*, align 8
  store %"struct.std::_Rb_tree_header"* %0, %"struct.std::_Rb_tree_header"** %2, align 8
  %3 = load %"struct.std::_Rb_tree_header"*, %"struct.std::_Rb_tree_header"** %2, align 8
  %4 = getelementptr inbounds %"struct.std::_Rb_tree_header", %"struct.std::_Rb_tree_header"* %3, i32 0, i32 0
  %5 = getelementptr inbounds %"struct.std::_Rb_tree_node_base", %"struct.std::_Rb_tree_node_base"* %4, i32 0, i32 1
  store %"struct.std::_Rb_tree_node_base"* null, %"struct.std::_Rb_tree_node_base"** %5, align 8
  %6 = getelementptr inbounds %"struct.std::_Rb_tree_header", %"struct.std::_Rb_tree_header"* %3, i32 0, i32 0
  %7 = getelementptr inbounds %"struct.std::_Rb_tree_header", %"struct.std::_Rb_tree_header"* %3, i32 0, i32 0
  %8 = getelementptr inbounds %"struct.std::_Rb_tree_node_base", %"struct.std::_Rb_tree_node_base"* %7, i32 0, i32 2
  store %"struct.std::_Rb_tree_node_base"* %6, %"struct.std::_Rb_tree_node_base"** %8, align 8
  %9 = getelementptr inbounds %"struct.std::_Rb_tree_header", %"struct.std::_Rb_tree_header"* %3, i32 0, i32 0
  %10 = getelementptr inbounds %"struct.std::_Rb_tree_header", %"struct.std::_Rb_tree_header"* %3, i32 0, i32 0
  %11 = getelementptr inbounds %"struct.std::_Rb_tree_node_base", %"struct.std::_Rb_tree_node_base"* %10, i32 0, i32 3
  store %"struct.std::_Rb_tree_node_base"* %9, %"struct.std::_Rb_tree_node_base"** %11, align 8
  %12 = getelementptr inbounds %"struct.std::_Rb_tree_header", %"struct.std::_Rb_tree_header"* %3, i32 0, i32 1
  store i64 0, i64* %12, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE11_Alloc_nodeC2ERS9_(%"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"*, %"class.std::_Rb_tree"* dereferenceable(48)) unnamed_addr #4 comdat align 2 {
  %3 = alloca %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"*, align 8
  %4 = alloca %"class.std::_Rb_tree"*, align 8
  store %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"* %0, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"** %3, align 8
  store %"class.std::_Rb_tree"* %1, %"class.std::_Rb_tree"** %4, align 8
  %5 = load %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"*, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"** %3, align 8
  %6 = getelementptr inbounds %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node", %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"* %5, i32 0, i32 0
  %7 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %4, align 8
  store %"class.std::_Rb_tree"* %7, %"class.std::_Rb_tree"** %6, align 8
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE7_M_copyINS9_11_Alloc_nodeEEEPSt13_Rb_tree_nodeIS3_ERKS9_RT_(%"class.std::_Rb_tree"*, %"class.std::_Rb_tree"* dereferenceable(48), %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"* dereferenceable(8)) #5 comdat align 2 {
  %4 = alloca %"class.std::_Rb_tree"*, align 8
  %5 = alloca %"class.std::_Rb_tree"*, align 8
  %6 = alloca %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"*, align 8
  %7 = alloca %"struct.std::_Rb_tree_node"*, align 8
  store %"class.std::_Rb_tree"* %0, %"class.std::_Rb_tree"** %4, align 8
  store %"class.std::_Rb_tree"* %1, %"class.std::_Rb_tree"** %5, align 8
  store %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"* %2, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"** %6, align 8
  %8 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %4, align 8
  %9 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %5, align 8
  %10 = call %"struct.std::_Rb_tree_node"* @_ZNKSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE8_M_beginEv(%"class.std::_Rb_tree"* %9) #3
  %11 = call %"struct.std::_Rb_tree_node_base"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE6_M_endEv(%"class.std::_Rb_tree"* %8) #3
  %12 = load %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"*, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"** %6, align 8
  %13 = call %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE7_M_copyINS9_11_Alloc_nodeEEEPSt13_Rb_tree_nodeIS3_EPKSD_PSt18_Rb_tree_node_baseRT_(%"class.std::_Rb_tree"* %8, %"struct.std::_Rb_tree_node"* %10, %"struct.std::_Rb_tree_node_base"* %11, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"* dereferenceable(8) %12)
  store %"struct.std::_Rb_tree_node"* %13, %"struct.std::_Rb_tree_node"** %7, align 8
  %14 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %7, align 8
  %15 = bitcast %"struct.std::_Rb_tree_node"* %14 to %"struct.std::_Rb_tree_node_base"*
  %16 = call %"struct.std::_Rb_tree_node_base"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE10_S_minimumEPSt18_Rb_tree_node_base(%"struct.std::_Rb_tree_node_base"* %15) #3
  %17 = call dereferenceable(8) %"struct.std::_Rb_tree_node_base"** @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE11_M_leftmostEv(%"class.std::_Rb_tree"* %8) #3
  store %"struct.std::_Rb_tree_node_base"* %16, %"struct.std::_Rb_tree_node_base"** %17, align 8
  %18 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %7, align 8
  %19 = bitcast %"struct.std::_Rb_tree_node"* %18 to %"struct.std::_Rb_tree_node_base"*
  %20 = call %"struct.std::_Rb_tree_node_base"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE10_S_maximumEPSt18_Rb_tree_node_base(%"struct.std::_Rb_tree_node_base"* %19) #3
  %21 = call dereferenceable(8) %"struct.std::_Rb_tree_node_base"** @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE12_M_rightmostEv(%"class.std::_Rb_tree"* %8) #3
  store %"struct.std::_Rb_tree_node_base"* %20, %"struct.std::_Rb_tree_node_base"** %21, align 8
  %22 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %5, align 8
  %23 = getelementptr inbounds %"class.std::_Rb_tree", %"class.std::_Rb_tree"* %22, i32 0, i32 0
  %24 = bitcast %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %23 to i8*
  %25 = getelementptr inbounds i8, i8* %24, i64 8
  %26 = bitcast i8* %25 to %"struct.std::_Rb_tree_header"*
  %27 = getelementptr inbounds %"struct.std::_Rb_tree_header", %"struct.std::_Rb_tree_header"* %26, i32 0, i32 1
  %28 = load i64, i64* %27, align 8
  %29 = getelementptr inbounds %"class.std::_Rb_tree", %"class.std::_Rb_tree"* %8, i32 0, i32 0
  %30 = bitcast %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %29 to i8*
  %31 = getelementptr inbounds i8, i8* %30, i64 8
  %32 = bitcast i8* %31 to %"struct.std::_Rb_tree_header"*
  %33 = getelementptr inbounds %"struct.std::_Rb_tree_header", %"struct.std::_Rb_tree_header"* %32, i32 0, i32 1
  store i64 %28, i64* %33, align 8
  %34 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %7, align 8
  ret %"struct.std::_Rb_tree_node"* %34
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE7_M_copyINS9_11_Alloc_nodeEEEPSt13_Rb_tree_nodeIS3_EPKSD_PSt18_Rb_tree_node_baseRT_(%"class.std::_Rb_tree"*, %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"* dereferenceable(8)) #5 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %5 = alloca %"class.std::_Rb_tree"*, align 8
  %6 = alloca %"struct.std::_Rb_tree_node"*, align 8
  %7 = alloca %"struct.std::_Rb_tree_node_base"*, align 8
  %8 = alloca %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"*, align 8
  %9 = alloca %"struct.std::_Rb_tree_node"*, align 8
  %10 = alloca i8*
  %11 = alloca i32
  %12 = alloca %"struct.std::_Rb_tree_node"*, align 8
  store %"class.std::_Rb_tree"* %0, %"class.std::_Rb_tree"** %5, align 8
  store %"struct.std::_Rb_tree_node"* %1, %"struct.std::_Rb_tree_node"** %6, align 8
  store %"struct.std::_Rb_tree_node_base"* %2, %"struct.std::_Rb_tree_node_base"** %7, align 8
  store %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"* %3, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"** %8, align 8
  %13 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %5, align 8
  %14 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %6, align 8
  %15 = load %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"*, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"** %8, align 8
  %16 = call %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE13_M_clone_nodeINS9_11_Alloc_nodeEEEPSt13_Rb_tree_nodeIS3_EPKSD_RT_(%"class.std::_Rb_tree"* %13, %"struct.std::_Rb_tree_node"* %14, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"* dereferenceable(8) %15)
  store %"struct.std::_Rb_tree_node"* %16, %"struct.std::_Rb_tree_node"** %9, align 8
  %17 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %7, align 8
  %18 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %9, align 8
  %19 = bitcast %"struct.std::_Rb_tree_node"* %18 to %"struct.std::_Rb_tree_node_base"*
  %20 = getelementptr inbounds %"struct.std::_Rb_tree_node_base", %"struct.std::_Rb_tree_node_base"* %19, i32 0, i32 1
  store %"struct.std::_Rb_tree_node_base"* %17, %"struct.std::_Rb_tree_node_base"** %20, align 8
  %21 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %6, align 8
  %22 = bitcast %"struct.std::_Rb_tree_node"* %21 to %"struct.std::_Rb_tree_node_base"*
  %23 = getelementptr inbounds %"struct.std::_Rb_tree_node_base", %"struct.std::_Rb_tree_node_base"* %22, i32 0, i32 3
  %24 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %23, align 8
  %25 = icmp ne %"struct.std::_Rb_tree_node_base"* %24, null
  br i1 %25, label %26, label %48

; <label>:26:                                     ; preds = %4
  %27 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %6, align 8
  %28 = bitcast %"struct.std::_Rb_tree_node"* %27 to %"struct.std::_Rb_tree_node_base"*
  %29 = call %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE8_S_rightEPKSt18_Rb_tree_node_base(%"struct.std::_Rb_tree_node_base"* %28) #3
  %30 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %9, align 8
  %31 = bitcast %"struct.std::_Rb_tree_node"* %30 to %"struct.std::_Rb_tree_node_base"*
  %32 = load %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"*, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"** %8, align 8
  %33 = invoke %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE7_M_copyINS9_11_Alloc_nodeEEEPSt13_Rb_tree_nodeIS3_EPKSD_PSt18_Rb_tree_node_baseRT_(%"class.std::_Rb_tree"* %13, %"struct.std::_Rb_tree_node"* %29, %"struct.std::_Rb_tree_node_base"* %31, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"* dereferenceable(8) %32)
          to label %34 unwind label %39

; <label>:34:                                     ; preds = %26
  %35 = bitcast %"struct.std::_Rb_tree_node"* %33 to %"struct.std::_Rb_tree_node_base"*
  %36 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %9, align 8
  %37 = bitcast %"struct.std::_Rb_tree_node"* %36 to %"struct.std::_Rb_tree_node_base"*
  %38 = getelementptr inbounds %"struct.std::_Rb_tree_node_base", %"struct.std::_Rb_tree_node_base"* %37, i32 0, i32 3
  store %"struct.std::_Rb_tree_node_base"* %35, %"struct.std::_Rb_tree_node_base"** %38, align 8
  br label %48

; <label>:39:                                     ; preds = %75, %57, %26
  %40 = landingpad { i8*, i32 }
          catch i8* null
  %41 = extractvalue { i8*, i32 } %40, 0
  store i8* %41, i8** %10, align 8
  %42 = extractvalue { i8*, i32 } %40, 1
  store i32 %42, i32* %11, align 4
  br label %43

; <label>:43:                                     ; preds = %39
  %44 = load i8*, i8** %10, align 8
  %45 = call i8* @__cxa_begin_catch(i8* %44) #3
  %46 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %9, align 8
  invoke void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE8_M_eraseEPSt13_Rb_tree_nodeIS3_E(%"class.std::_Rb_tree"* %13, %"struct.std::_Rb_tree_node"* %46)
          to label %47 unwind label %95

; <label>:47:                                     ; preds = %43
  invoke void @__cxa_rethrow() #17
          to label %110 unwind label %95

; <label>:48:                                     ; preds = %34, %4
  %49 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %9, align 8
  %50 = bitcast %"struct.std::_Rb_tree_node"* %49 to %"struct.std::_Rb_tree_node_base"*
  store %"struct.std::_Rb_tree_node_base"* %50, %"struct.std::_Rb_tree_node_base"** %7, align 8
  %51 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %6, align 8
  %52 = bitcast %"struct.std::_Rb_tree_node"* %51 to %"struct.std::_Rb_tree_node_base"*
  %53 = call %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE7_S_leftEPKSt18_Rb_tree_node_base(%"struct.std::_Rb_tree_node_base"* %52) #3
  store %"struct.std::_Rb_tree_node"* %53, %"struct.std::_Rb_tree_node"** %6, align 8
  br label %54

; <label>:54:                                     ; preds = %88, %48
  %55 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %6, align 8
  %56 = icmp ne %"struct.std::_Rb_tree_node"* %55, null
  br i1 %56, label %57, label %94

; <label>:57:                                     ; preds = %54
  %58 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %6, align 8
  %59 = load %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"*, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"** %8, align 8
  %60 = invoke %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE13_M_clone_nodeINS9_11_Alloc_nodeEEEPSt13_Rb_tree_nodeIS3_EPKSD_RT_(%"class.std::_Rb_tree"* %13, %"struct.std::_Rb_tree_node"* %58, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"* dereferenceable(8) %59)
          to label %61 unwind label %39

; <label>:61:                                     ; preds = %57
  store %"struct.std::_Rb_tree_node"* %60, %"struct.std::_Rb_tree_node"** %12, align 8
  %62 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %12, align 8
  %63 = bitcast %"struct.std::_Rb_tree_node"* %62 to %"struct.std::_Rb_tree_node_base"*
  %64 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %7, align 8
  %65 = getelementptr inbounds %"struct.std::_Rb_tree_node_base", %"struct.std::_Rb_tree_node_base"* %64, i32 0, i32 2
  store %"struct.std::_Rb_tree_node_base"* %63, %"struct.std::_Rb_tree_node_base"** %65, align 8
  %66 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %7, align 8
  %67 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %12, align 8
  %68 = bitcast %"struct.std::_Rb_tree_node"* %67 to %"struct.std::_Rb_tree_node_base"*
  %69 = getelementptr inbounds %"struct.std::_Rb_tree_node_base", %"struct.std::_Rb_tree_node_base"* %68, i32 0, i32 1
  store %"struct.std::_Rb_tree_node_base"* %66, %"struct.std::_Rb_tree_node_base"** %69, align 8
  %70 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %6, align 8
  %71 = bitcast %"struct.std::_Rb_tree_node"* %70 to %"struct.std::_Rb_tree_node_base"*
  %72 = getelementptr inbounds %"struct.std::_Rb_tree_node_base", %"struct.std::_Rb_tree_node_base"* %71, i32 0, i32 3
  %73 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %72, align 8
  %74 = icmp ne %"struct.std::_Rb_tree_node_base"* %73, null
  br i1 %74, label %75, label %88

; <label>:75:                                     ; preds = %61
  %76 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %6, align 8
  %77 = bitcast %"struct.std::_Rb_tree_node"* %76 to %"struct.std::_Rb_tree_node_base"*
  %78 = call %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE8_S_rightEPKSt18_Rb_tree_node_base(%"struct.std::_Rb_tree_node_base"* %77) #3
  %79 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %12, align 8
  %80 = bitcast %"struct.std::_Rb_tree_node"* %79 to %"struct.std::_Rb_tree_node_base"*
  %81 = load %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"*, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"** %8, align 8
  %82 = invoke %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE7_M_copyINS9_11_Alloc_nodeEEEPSt13_Rb_tree_nodeIS3_EPKSD_PSt18_Rb_tree_node_baseRT_(%"class.std::_Rb_tree"* %13, %"struct.std::_Rb_tree_node"* %78, %"struct.std::_Rb_tree_node_base"* %80, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"* dereferenceable(8) %81)
          to label %83 unwind label %39

; <label>:83:                                     ; preds = %75
  %84 = bitcast %"struct.std::_Rb_tree_node"* %82 to %"struct.std::_Rb_tree_node_base"*
  %85 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %12, align 8
  %86 = bitcast %"struct.std::_Rb_tree_node"* %85 to %"struct.std::_Rb_tree_node_base"*
  %87 = getelementptr inbounds %"struct.std::_Rb_tree_node_base", %"struct.std::_Rb_tree_node_base"* %86, i32 0, i32 3
  store %"struct.std::_Rb_tree_node_base"* %84, %"struct.std::_Rb_tree_node_base"** %87, align 8
  br label %88

; <label>:88:                                     ; preds = %83, %61
  %89 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %12, align 8
  %90 = bitcast %"struct.std::_Rb_tree_node"* %89 to %"struct.std::_Rb_tree_node_base"*
  store %"struct.std::_Rb_tree_node_base"* %90, %"struct.std::_Rb_tree_node_base"** %7, align 8
  %91 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %6, align 8
  %92 = bitcast %"struct.std::_Rb_tree_node"* %91 to %"struct.std::_Rb_tree_node_base"*
  %93 = call %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE7_S_leftEPKSt18_Rb_tree_node_base(%"struct.std::_Rb_tree_node_base"* %92) #3
  store %"struct.std::_Rb_tree_node"* %93, %"struct.std::_Rb_tree_node"** %6, align 8
  br label %54

; <label>:94:                                     ; preds = %54
  br label %100

; <label>:95:                                     ; preds = %47, %43
  %96 = landingpad { i8*, i32 }
          cleanup
  %97 = extractvalue { i8*, i32 } %96, 0
  store i8* %97, i8** %10, align 8
  %98 = extractvalue { i8*, i32 } %96, 1
  store i32 %98, i32* %11, align 4
  invoke void @__cxa_end_catch()
          to label %99 unwind label %107

; <label>:99:                                     ; preds = %95
  br label %102

; <label>:100:                                    ; preds = %94
  %101 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %9, align 8
  ret %"struct.std::_Rb_tree_node"* %101

; <label>:102:                                    ; preds = %99
  %103 = load i8*, i8** %10, align 8
  %104 = load i32, i32* %11, align 4
  %105 = insertvalue { i8*, i32 } undef, i8* %103, 0
  %106 = insertvalue { i8*, i32 } %105, i32 %104, 1
  resume { i8*, i32 } %106

; <label>:107:                                    ; preds = %95
  %108 = landingpad { i8*, i32 }
          catch i8* null
  %109 = extractvalue { i8*, i32 } %108, 0
  call void @__clang_call_terminate(i8* %109) #16
  unreachable

; <label>:110:                                    ; preds = %47
  unreachable
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"struct.std::_Rb_tree_node"* @_ZNKSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE8_M_beginEv(%"class.std::_Rb_tree"*) #4 comdat align 2 {
  %2 = alloca %"class.std::_Rb_tree"*, align 8
  store %"class.std::_Rb_tree"* %0, %"class.std::_Rb_tree"** %2, align 8
  %3 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %2, align 8
  %4 = getelementptr inbounds %"class.std::_Rb_tree", %"class.std::_Rb_tree"* %3, i32 0, i32 0
  %5 = bitcast %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %4 to i8*
  %6 = getelementptr inbounds i8, i8* %5, i64 8
  %7 = bitcast i8* %6 to %"struct.std::_Rb_tree_header"*
  %8 = getelementptr inbounds %"struct.std::_Rb_tree_header", %"struct.std::_Rb_tree_header"* %7, i32 0, i32 0
  %9 = getelementptr inbounds %"struct.std::_Rb_tree_node_base", %"struct.std::_Rb_tree_node_base"* %8, i32 0, i32 1
  %10 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %9, align 8
  %11 = bitcast %"struct.std::_Rb_tree_node_base"* %10 to %"struct.std::_Rb_tree_node"*
  ret %"struct.std::_Rb_tree_node"* %11
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"struct.std::_Rb_tree_node_base"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE6_M_endEv(%"class.std::_Rb_tree"*) #4 comdat align 2 {
  %2 = alloca %"class.std::_Rb_tree"*, align 8
  store %"class.std::_Rb_tree"* %0, %"class.std::_Rb_tree"** %2, align 8
  %3 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %2, align 8
  %4 = getelementptr inbounds %"class.std::_Rb_tree", %"class.std::_Rb_tree"* %3, i32 0, i32 0
  %5 = bitcast %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %4 to i8*
  %6 = getelementptr inbounds i8, i8* %5, i64 8
  %7 = bitcast i8* %6 to %"struct.std::_Rb_tree_header"*
  %8 = getelementptr inbounds %"struct.std::_Rb_tree_header", %"struct.std::_Rb_tree_header"* %7, i32 0, i32 0
  ret %"struct.std::_Rb_tree_node_base"* %8
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"struct.std::_Rb_tree_node_base"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE10_S_minimumEPSt18_Rb_tree_node_base(%"struct.std::_Rb_tree_node_base"*) #4 comdat align 2 {
  %2 = alloca %"struct.std::_Rb_tree_node_base"*, align 8
  store %"struct.std::_Rb_tree_node_base"* %0, %"struct.std::_Rb_tree_node_base"** %2, align 8
  %3 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %2, align 8
  %4 = call %"struct.std::_Rb_tree_node_base"* @_ZNSt18_Rb_tree_node_base10_S_minimumEPS_(%"struct.std::_Rb_tree_node_base"* %3) #3
  ret %"struct.std::_Rb_tree_node_base"* %4
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(8) %"struct.std::_Rb_tree_node_base"** @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE11_M_leftmostEv(%"class.std::_Rb_tree"*) #4 comdat align 2 {
  %2 = alloca %"class.std::_Rb_tree"*, align 8
  store %"class.std::_Rb_tree"* %0, %"class.std::_Rb_tree"** %2, align 8
  %3 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %2, align 8
  %4 = getelementptr inbounds %"class.std::_Rb_tree", %"class.std::_Rb_tree"* %3, i32 0, i32 0
  %5 = bitcast %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %4 to i8*
  %6 = getelementptr inbounds i8, i8* %5, i64 8
  %7 = bitcast i8* %6 to %"struct.std::_Rb_tree_header"*
  %8 = getelementptr inbounds %"struct.std::_Rb_tree_header", %"struct.std::_Rb_tree_header"* %7, i32 0, i32 0
  %9 = getelementptr inbounds %"struct.std::_Rb_tree_node_base", %"struct.std::_Rb_tree_node_base"* %8, i32 0, i32 2
  ret %"struct.std::_Rb_tree_node_base"** %9
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"struct.std::_Rb_tree_node_base"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE10_S_maximumEPSt18_Rb_tree_node_base(%"struct.std::_Rb_tree_node_base"*) #4 comdat align 2 {
  %2 = alloca %"struct.std::_Rb_tree_node_base"*, align 8
  store %"struct.std::_Rb_tree_node_base"* %0, %"struct.std::_Rb_tree_node_base"** %2, align 8
  %3 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %2, align 8
  %4 = call %"struct.std::_Rb_tree_node_base"* @_ZNSt18_Rb_tree_node_base10_S_maximumEPS_(%"struct.std::_Rb_tree_node_base"* %3) #3
  ret %"struct.std::_Rb_tree_node_base"* %4
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(8) %"struct.std::_Rb_tree_node_base"** @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE12_M_rightmostEv(%"class.std::_Rb_tree"*) #4 comdat align 2 {
  %2 = alloca %"class.std::_Rb_tree"*, align 8
  store %"class.std::_Rb_tree"* %0, %"class.std::_Rb_tree"** %2, align 8
  %3 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %2, align 8
  %4 = getelementptr inbounds %"class.std::_Rb_tree", %"class.std::_Rb_tree"* %3, i32 0, i32 0
  %5 = bitcast %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %4 to i8*
  %6 = getelementptr inbounds i8, i8* %5, i64 8
  %7 = bitcast i8* %6 to %"struct.std::_Rb_tree_header"*
  %8 = getelementptr inbounds %"struct.std::_Rb_tree_header", %"struct.std::_Rb_tree_header"* %7, i32 0, i32 0
  %9 = getelementptr inbounds %"struct.std::_Rb_tree_node_base", %"struct.std::_Rb_tree_node_base"* %8, i32 0, i32 3
  ret %"struct.std::_Rb_tree_node_base"** %9
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE13_M_clone_nodeINS9_11_Alloc_nodeEEEPSt13_Rb_tree_nodeIS3_EPKSD_RT_(%"class.std::_Rb_tree"*, %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"* dereferenceable(8)) #5 comdat align 2 {
  %4 = alloca %"class.std::_Rb_tree"*, align 8
  %5 = alloca %"struct.std::_Rb_tree_node"*, align 8
  %6 = alloca %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"*, align 8
  %7 = alloca %"struct.std::_Rb_tree_node"*, align 8
  store %"class.std::_Rb_tree"* %0, %"class.std::_Rb_tree"** %4, align 8
  store %"struct.std::_Rb_tree_node"* %1, %"struct.std::_Rb_tree_node"** %5, align 8
  store %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"* %2, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"** %6, align 8
  %8 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %4, align 8
  %9 = load %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"*, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"** %6, align 8
  %10 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %5, align 8
  %11 = call %"struct.std::pair"* @_ZNKSt13_Rb_tree_nodeISt4pairIKi9NonDetLogEE9_M_valptrEv(%"struct.std::_Rb_tree_node"* %10)
  %12 = call %"struct.std::_Rb_tree_node"* @_ZNKSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE11_Alloc_nodeclIRKS3_EEPSt13_Rb_tree_nodeIS3_EOT_(%"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"* %9, %"struct.std::pair"* dereferenceable(64) %11)
  store %"struct.std::_Rb_tree_node"* %12, %"struct.std::_Rb_tree_node"** %7, align 8
  %13 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %5, align 8
  %14 = bitcast %"struct.std::_Rb_tree_node"* %13 to %"struct.std::_Rb_tree_node_base"*
  %15 = getelementptr inbounds %"struct.std::_Rb_tree_node_base", %"struct.std::_Rb_tree_node_base"* %14, i32 0, i32 0
  %16 = load i32, i32* %15, align 8
  %17 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %7, align 8
  %18 = bitcast %"struct.std::_Rb_tree_node"* %17 to %"struct.std::_Rb_tree_node_base"*
  %19 = getelementptr inbounds %"struct.std::_Rb_tree_node_base", %"struct.std::_Rb_tree_node_base"* %18, i32 0, i32 0
  store i32 %16, i32* %19, align 8
  %20 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %7, align 8
  %21 = bitcast %"struct.std::_Rb_tree_node"* %20 to %"struct.std::_Rb_tree_node_base"*
  %22 = getelementptr inbounds %"struct.std::_Rb_tree_node_base", %"struct.std::_Rb_tree_node_base"* %21, i32 0, i32 2
  store %"struct.std::_Rb_tree_node_base"* null, %"struct.std::_Rb_tree_node_base"** %22, align 8
  %23 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %7, align 8
  %24 = bitcast %"struct.std::_Rb_tree_node"* %23 to %"struct.std::_Rb_tree_node_base"*
  %25 = getelementptr inbounds %"struct.std::_Rb_tree_node_base", %"struct.std::_Rb_tree_node_base"* %24, i32 0, i32 3
  store %"struct.std::_Rb_tree_node_base"* null, %"struct.std::_Rb_tree_node_base"** %25, align 8
  %26 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %7, align 8
  ret %"struct.std::_Rb_tree_node"* %26
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE8_S_rightEPKSt18_Rb_tree_node_base(%"struct.std::_Rb_tree_node_base"*) #4 comdat align 2 {
  %2 = alloca %"struct.std::_Rb_tree_node_base"*, align 8
  store %"struct.std::_Rb_tree_node_base"* %0, %"struct.std::_Rb_tree_node_base"** %2, align 8
  %3 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %2, align 8
  %4 = getelementptr inbounds %"struct.std::_Rb_tree_node_base", %"struct.std::_Rb_tree_node_base"* %3, i32 0, i32 3
  %5 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %4, align 8
  %6 = bitcast %"struct.std::_Rb_tree_node_base"* %5 to %"struct.std::_Rb_tree_node"*
  ret %"struct.std::_Rb_tree_node"* %6
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE7_S_leftEPKSt18_Rb_tree_node_base(%"struct.std::_Rb_tree_node_base"*) #4 comdat align 2 {
  %2 = alloca %"struct.std::_Rb_tree_node_base"*, align 8
  store %"struct.std::_Rb_tree_node_base"* %0, %"struct.std::_Rb_tree_node_base"** %2, align 8
  %3 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %2, align 8
  %4 = getelementptr inbounds %"struct.std::_Rb_tree_node_base", %"struct.std::_Rb_tree_node_base"* %3, i32 0, i32 2
  %5 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %4, align 8
  %6 = bitcast %"struct.std::_Rb_tree_node_base"* %5 to %"struct.std::_Rb_tree_node"*
  ret %"struct.std::_Rb_tree_node"* %6
}

declare dso_local void @__cxa_rethrow()

declare dso_local void @__cxa_end_catch()

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local %"struct.std::_Rb_tree_node"* @_ZNKSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE11_Alloc_nodeclIRKS3_EEPSt13_Rb_tree_nodeIS3_EOT_(%"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"*, %"struct.std::pair"* dereferenceable(64)) #5 comdat align 2 {
  %3 = alloca %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"*, align 8
  %4 = alloca %"struct.std::pair"*, align 8
  store %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"* %0, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"** %3, align 8
  store %"struct.std::pair"* %1, %"struct.std::pair"** %4, align 8
  %5 = load %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"*, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"** %3, align 8
  %6 = getelementptr inbounds %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node", %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Alloc_node"* %5, i32 0, i32 0
  %7 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %6, align 8
  %8 = load %"struct.std::pair"*, %"struct.std::pair"** %4, align 8
  %9 = call dereferenceable(64) %"struct.std::pair"* @_ZSt7forwardIRKSt4pairIKi9NonDetLogEEOT_RNSt16remove_referenceIS6_E4typeE(%"struct.std::pair"* dereferenceable(64) %8) #3
  %10 = call %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE14_M_create_nodeIJRKS3_EEEPSt13_Rb_tree_nodeIS3_EDpOT_(%"class.std::_Rb_tree"* %7, %"struct.std::pair"* dereferenceable(64) %9)
  ret %"struct.std::_Rb_tree_node"* %10
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"struct.std::pair"* @_ZNKSt13_Rb_tree_nodeISt4pairIKi9NonDetLogEE9_M_valptrEv(%"struct.std::_Rb_tree_node"*) #4 comdat align 2 {
  %2 = alloca %"struct.std::_Rb_tree_node"*, align 8
  store %"struct.std::_Rb_tree_node"* %0, %"struct.std::_Rb_tree_node"** %2, align 8
  %3 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %2, align 8
  %4 = getelementptr inbounds %"struct.std::_Rb_tree_node", %"struct.std::_Rb_tree_node"* %3, i32 0, i32 1
  %5 = call %"struct.std::pair"* @_ZNK9__gnu_cxx16__aligned_membufISt4pairIKi9NonDetLogEE6_M_ptrEv(%"struct.__gnu_cxx::__aligned_membuf.6"* %4) #3
  ret %"struct.std::pair"* %5
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE14_M_create_nodeIJRKS3_EEEPSt13_Rb_tree_nodeIS3_EDpOT_(%"class.std::_Rb_tree"*, %"struct.std::pair"* dereferenceable(64)) #5 comdat align 2 {
  %3 = alloca %"class.std::_Rb_tree"*, align 8
  %4 = alloca %"struct.std::pair"*, align 8
  %5 = alloca %"struct.std::_Rb_tree_node"*, align 8
  store %"class.std::_Rb_tree"* %0, %"class.std::_Rb_tree"** %3, align 8
  store %"struct.std::pair"* %1, %"struct.std::pair"** %4, align 8
  %6 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %3, align 8
  %7 = call %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE11_M_get_nodeEv(%"class.std::_Rb_tree"* %6)
  store %"struct.std::_Rb_tree_node"* %7, %"struct.std::_Rb_tree_node"** %5, align 8
  %8 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %5, align 8
  %9 = load %"struct.std::pair"*, %"struct.std::pair"** %4, align 8
  %10 = call dereferenceable(64) %"struct.std::pair"* @_ZSt7forwardIRKSt4pairIKi9NonDetLogEEOT_RNSt16remove_referenceIS6_E4typeE(%"struct.std::pair"* dereferenceable(64) %9) #3
  call void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE17_M_construct_nodeIJRKS3_EEEvPSt13_Rb_tree_nodeIS3_EDpOT_(%"class.std::_Rb_tree"* %6, %"struct.std::_Rb_tree_node"* %8, %"struct.std::pair"* dereferenceable(64) %10)
  %11 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %5, align 8
  ret %"struct.std::_Rb_tree_node"* %11
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(64) %"struct.std::pair"* @_ZSt7forwardIRKSt4pairIKi9NonDetLogEEOT_RNSt16remove_referenceIS6_E4typeE(%"struct.std::pair"* dereferenceable(64)) #4 comdat {
  %2 = alloca %"struct.std::pair"*, align 8
  store %"struct.std::pair"* %0, %"struct.std::pair"** %2, align 8
  %3 = load %"struct.std::pair"*, %"struct.std::pair"** %2, align 8
  ret %"struct.std::pair"* %3
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE11_M_get_nodeEv(%"class.std::_Rb_tree"*) #5 comdat align 2 {
  %2 = alloca %"class.std::_Rb_tree"*, align 8
  store %"class.std::_Rb_tree"* %0, %"class.std::_Rb_tree"** %2, align 8
  %3 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %2, align 8
  %4 = call dereferenceable(1) %"class.std::allocator.3"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE21_M_get_Node_allocatorEv(%"class.std::_Rb_tree"* %3) #3
  %5 = call %"struct.std::_Rb_tree_node"* @_ZNSt16allocator_traitsISaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEE8allocateERS6_m(%"class.std::allocator.3"* dereferenceable(1) %4, i64 1)
  ret %"struct.std::_Rb_tree_node"* %5
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE17_M_construct_nodeIJRKS3_EEEvPSt13_Rb_tree_nodeIS3_EDpOT_(%"class.std::_Rb_tree"*, %"struct.std::_Rb_tree_node"*, %"struct.std::pair"* dereferenceable(64)) #5 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %4 = alloca %"class.std::_Rb_tree"*, align 8
  %5 = alloca %"struct.std::_Rb_tree_node"*, align 8
  %6 = alloca %"struct.std::pair"*, align 8
  %7 = alloca i8*
  %8 = alloca i32
  store %"class.std::_Rb_tree"* %0, %"class.std::_Rb_tree"** %4, align 8
  store %"struct.std::_Rb_tree_node"* %1, %"struct.std::_Rb_tree_node"** %5, align 8
  store %"struct.std::pair"* %2, %"struct.std::pair"** %6, align 8
  %9 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %4, align 8
  %10 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %5, align 8
  %11 = bitcast %"struct.std::_Rb_tree_node"* %10 to i8*
  %12 = bitcast i8* %11 to %"struct.std::_Rb_tree_node"*
  %13 = call dereferenceable(1) %"class.std::allocator.3"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE21_M_get_Node_allocatorEv(%"class.std::_Rb_tree"* %9) #3
  %14 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %5, align 8
  %15 = invoke %"struct.std::pair"* @_ZNSt13_Rb_tree_nodeISt4pairIKi9NonDetLogEE9_M_valptrEv(%"struct.std::_Rb_tree_node"* %14)
          to label %16 unwind label %20

; <label>:16:                                     ; preds = %3
  %17 = load %"struct.std::pair"*, %"struct.std::pair"** %6, align 8
  %18 = call dereferenceable(64) %"struct.std::pair"* @_ZSt7forwardIRKSt4pairIKi9NonDetLogEEOT_RNSt16remove_referenceIS6_E4typeE(%"struct.std::pair"* dereferenceable(64) %17) #3
  invoke void @_ZNSt16allocator_traitsISaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEE9constructIS4_JRKS4_EEEvRS6_PT_DpOT0_(%"class.std::allocator.3"* dereferenceable(1) %13, %"struct.std::pair"* %15, %"struct.std::pair"* dereferenceable(64) %18)
          to label %19 unwind label %20

; <label>:19:                                     ; preds = %16
  br label %34

; <label>:20:                                     ; preds = %16, %3
  %21 = landingpad { i8*, i32 }
          catch i8* null
  %22 = extractvalue { i8*, i32 } %21, 0
  store i8* %22, i8** %7, align 8
  %23 = extractvalue { i8*, i32 } %21, 1
  store i32 %23, i32* %8, align 4
  br label %24

; <label>:24:                                     ; preds = %20
  %25 = load i8*, i8** %7, align 8
  %26 = call i8* @__cxa_begin_catch(i8* %25) #3
  %27 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %5, align 8
  %28 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %5, align 8
  call void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE11_M_put_nodeEPSt13_Rb_tree_nodeIS3_E(%"class.std::_Rb_tree"* %9, %"struct.std::_Rb_tree_node"* %28) #3
  invoke void @__cxa_rethrow() #17
          to label %43 unwind label %29

; <label>:29:                                     ; preds = %24
  %30 = landingpad { i8*, i32 }
          cleanup
  %31 = extractvalue { i8*, i32 } %30, 0
  store i8* %31, i8** %7, align 8
  %32 = extractvalue { i8*, i32 } %30, 1
  store i32 %32, i32* %8, align 4
  invoke void @__cxa_end_catch()
          to label %33 unwind label %40

; <label>:33:                                     ; preds = %29
  br label %35

; <label>:34:                                     ; preds = %19
  ret void

; <label>:35:                                     ; preds = %33
  %36 = load i8*, i8** %7, align 8
  %37 = load i32, i32* %8, align 4
  %38 = insertvalue { i8*, i32 } undef, i8* %36, 0
  %39 = insertvalue { i8*, i32 } %38, i32 %37, 1
  resume { i8*, i32 } %39

; <label>:40:                                     ; preds = %29
  %41 = landingpad { i8*, i32 }
          catch i8* null
  %42 = extractvalue { i8*, i32 } %41, 0
  call void @__clang_call_terminate(i8* %42) #16
  unreachable

; <label>:43:                                     ; preds = %24
  unreachable
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local %"struct.std::_Rb_tree_node"* @_ZNSt16allocator_traitsISaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEE8allocateERS6_m(%"class.std::allocator.3"* dereferenceable(1), i64) #5 comdat align 2 {
  %3 = alloca %"class.std::allocator.3"*, align 8
  %4 = alloca i64, align 8
  store %"class.std::allocator.3"* %0, %"class.std::allocator.3"** %3, align 8
  store i64 %1, i64* %4, align 8
  %5 = load %"class.std::allocator.3"*, %"class.std::allocator.3"** %3, align 8
  %6 = bitcast %"class.std::allocator.3"* %5 to %"class.__gnu_cxx::new_allocator.4"*
  %7 = load i64, i64* %4, align 8
  %8 = call %"struct.std::_Rb_tree_node"* @_ZN9__gnu_cxx13new_allocatorISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEE8allocateEmPKv(%"class.__gnu_cxx::new_allocator.4"* %6, i64 %7, i8* null)
  ret %"struct.std::_Rb_tree_node"* %8
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local %"struct.std::_Rb_tree_node"* @_ZN9__gnu_cxx13new_allocatorISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEE8allocateEmPKv(%"class.__gnu_cxx::new_allocator.4"*, i64, i8*) #5 comdat align 2 {
  %4 = alloca %"class.__gnu_cxx::new_allocator.4"*, align 8
  %5 = alloca i64, align 8
  %6 = alloca i8*, align 8
  store %"class.__gnu_cxx::new_allocator.4"* %0, %"class.__gnu_cxx::new_allocator.4"** %4, align 8
  store i64 %1, i64* %5, align 8
  store i8* %2, i8** %6, align 8
  %7 = load %"class.__gnu_cxx::new_allocator.4"*, %"class.__gnu_cxx::new_allocator.4"** %4, align 8
  %8 = load i64, i64* %5, align 8
  %9 = call i64 @_ZNK9__gnu_cxx13new_allocatorISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEE8max_sizeEv(%"class.__gnu_cxx::new_allocator.4"* %7) #3
  %10 = icmp ugt i64 %8, %9
  br i1 %10, label %11, label %12

; <label>:11:                                     ; preds = %3
  call void @_ZSt17__throw_bad_allocv() #17
  unreachable

; <label>:12:                                     ; preds = %3
  %13 = load i64, i64* %5, align 8
  %14 = mul i64 %13, 96
  %15 = call i8* @_Znwm(i64 %14)
  %16 = bitcast i8* %15 to %"struct.std::_Rb_tree_node"*
  ret %"struct.std::_Rb_tree_node"* %16
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local i64 @_ZNK9__gnu_cxx13new_allocatorISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEE8max_sizeEv(%"class.__gnu_cxx::new_allocator.4"*) #4 comdat align 2 {
  %2 = alloca %"class.__gnu_cxx::new_allocator.4"*, align 8
  store %"class.__gnu_cxx::new_allocator.4"* %0, %"class.__gnu_cxx::new_allocator.4"** %2, align 8
  %3 = load %"class.__gnu_cxx::new_allocator.4"*, %"class.__gnu_cxx::new_allocator.4"** %2, align 8
  ret i64 96076792050570581
}

; Function Attrs: noreturn
declare dso_local void @_ZSt17__throw_bad_allocv() #11

; Function Attrs: nobuiltin
declare dso_local noalias i8* @_Znwm(i64) #12

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZNSt16allocator_traitsISaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEE9constructIS4_JRKS4_EEEvRS6_PT_DpOT0_(%"class.std::allocator.3"* dereferenceable(1), %"struct.std::pair"*, %"struct.std::pair"* dereferenceable(64)) #5 comdat align 2 {
  %4 = alloca %"class.std::allocator.3"*, align 8
  %5 = alloca %"struct.std::pair"*, align 8
  %6 = alloca %"struct.std::pair"*, align 8
  store %"class.std::allocator.3"* %0, %"class.std::allocator.3"** %4, align 8
  store %"struct.std::pair"* %1, %"struct.std::pair"** %5, align 8
  store %"struct.std::pair"* %2, %"struct.std::pair"** %6, align 8
  %7 = load %"class.std::allocator.3"*, %"class.std::allocator.3"** %4, align 8
  %8 = bitcast %"class.std::allocator.3"* %7 to %"class.__gnu_cxx::new_allocator.4"*
  %9 = load %"struct.std::pair"*, %"struct.std::pair"** %5, align 8
  %10 = load %"struct.std::pair"*, %"struct.std::pair"** %6, align 8
  %11 = call dereferenceable(64) %"struct.std::pair"* @_ZSt7forwardIRKSt4pairIKi9NonDetLogEEOT_RNSt16remove_referenceIS6_E4typeE(%"struct.std::pair"* dereferenceable(64) %10) #3
  call void @_ZN9__gnu_cxx13new_allocatorISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEE9constructIS5_JRKS5_EEEvPT_DpOT0_(%"class.__gnu_cxx::new_allocator.4"* %8, %"struct.std::pair"* %9, %"struct.std::pair"* dereferenceable(64) %11)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN9__gnu_cxx13new_allocatorISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEE9constructIS5_JRKS5_EEEvPT_DpOT0_(%"class.__gnu_cxx::new_allocator.4"*, %"struct.std::pair"*, %"struct.std::pair"* dereferenceable(64)) #5 comdat align 2 {
  %4 = alloca %"class.__gnu_cxx::new_allocator.4"*, align 8
  %5 = alloca %"struct.std::pair"*, align 8
  %6 = alloca %"struct.std::pair"*, align 8
  store %"class.__gnu_cxx::new_allocator.4"* %0, %"class.__gnu_cxx::new_allocator.4"** %4, align 8
  store %"struct.std::pair"* %1, %"struct.std::pair"** %5, align 8
  store %"struct.std::pair"* %2, %"struct.std::pair"** %6, align 8
  %7 = load %"class.__gnu_cxx::new_allocator.4"*, %"class.__gnu_cxx::new_allocator.4"** %4, align 8
  %8 = load %"struct.std::pair"*, %"struct.std::pair"** %5, align 8
  %9 = bitcast %"struct.std::pair"* %8 to i8*
  %10 = bitcast i8* %9 to %"struct.std::pair"*
  %11 = load %"struct.std::pair"*, %"struct.std::pair"** %6, align 8
  %12 = call dereferenceable(64) %"struct.std::pair"* @_ZSt7forwardIRKSt4pairIKi9NonDetLogEEOT_RNSt16remove_referenceIS6_E4typeE(%"struct.std::pair"* dereferenceable(64) %11) #3
  call void @_ZNSt4pairIKi9NonDetLogEC2ERKS2_(%"struct.std::pair"* %10, %"struct.std::pair"* dereferenceable(64) %12)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"struct.std::pair"* @_ZNK9__gnu_cxx16__aligned_membufISt4pairIKi9NonDetLogEE6_M_ptrEv(%"struct.__gnu_cxx::__aligned_membuf.6"*) #4 comdat align 2 {
  %2 = alloca %"struct.__gnu_cxx::__aligned_membuf.6"*, align 8
  store %"struct.__gnu_cxx::__aligned_membuf.6"* %0, %"struct.__gnu_cxx::__aligned_membuf.6"** %2, align 8
  %3 = load %"struct.__gnu_cxx::__aligned_membuf.6"*, %"struct.__gnu_cxx::__aligned_membuf.6"** %2, align 8
  %4 = call i8* @_ZNK9__gnu_cxx16__aligned_membufISt4pairIKi9NonDetLogEE7_M_addrEv(%"struct.__gnu_cxx::__aligned_membuf.6"* %3) #3
  %5 = bitcast i8* %4 to %"struct.std::pair"*
  ret %"struct.std::pair"* %5
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local i8* @_ZNK9__gnu_cxx16__aligned_membufISt4pairIKi9NonDetLogEE7_M_addrEv(%"struct.__gnu_cxx::__aligned_membuf.6"*) #4 comdat align 2 {
  %2 = alloca %"struct.__gnu_cxx::__aligned_membuf.6"*, align 8
  store %"struct.__gnu_cxx::__aligned_membuf.6"* %0, %"struct.__gnu_cxx::__aligned_membuf.6"** %2, align 8
  %3 = load %"struct.__gnu_cxx::__aligned_membuf.6"*, %"struct.__gnu_cxx::__aligned_membuf.6"** %2, align 8
  %4 = getelementptr inbounds %"struct.__gnu_cxx::__aligned_membuf.6", %"struct.__gnu_cxx::__aligned_membuf.6"* %3, i32 0, i32 0
  %5 = bitcast [64 x i8]* %4 to i8*
  ret i8* %5
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"struct.std::_Rb_tree_node_base"* @_ZNSt18_Rb_tree_node_base10_S_minimumEPS_(%"struct.std::_Rb_tree_node_base"*) #4 comdat align 2 {
  %2 = alloca %"struct.std::_Rb_tree_node_base"*, align 8
  store %"struct.std::_Rb_tree_node_base"* %0, %"struct.std::_Rb_tree_node_base"** %2, align 8
  br label %3

; <label>:3:                                      ; preds = %8, %1
  %4 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %2, align 8
  %5 = getelementptr inbounds %"struct.std::_Rb_tree_node_base", %"struct.std::_Rb_tree_node_base"* %4, i32 0, i32 2
  %6 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %5, align 8
  %7 = icmp ne %"struct.std::_Rb_tree_node_base"* %6, null
  br i1 %7, label %8, label %12

; <label>:8:                                      ; preds = %3
  %9 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %2, align 8
  %10 = getelementptr inbounds %"struct.std::_Rb_tree_node_base", %"struct.std::_Rb_tree_node_base"* %9, i32 0, i32 2
  %11 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %10, align 8
  store %"struct.std::_Rb_tree_node_base"* %11, %"struct.std::_Rb_tree_node_base"** %2, align 8
  br label %3

; <label>:12:                                     ; preds = %3
  %13 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %2, align 8
  ret %"struct.std::_Rb_tree_node_base"* %13
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"struct.std::_Rb_tree_node_base"* @_ZNSt18_Rb_tree_node_base10_S_maximumEPS_(%"struct.std::_Rb_tree_node_base"*) #4 comdat align 2 {
  %2 = alloca %"struct.std::_Rb_tree_node_base"*, align 8
  store %"struct.std::_Rb_tree_node_base"* %0, %"struct.std::_Rb_tree_node_base"** %2, align 8
  br label %3

; <label>:3:                                      ; preds = %8, %1
  %4 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %2, align 8
  %5 = getelementptr inbounds %"struct.std::_Rb_tree_node_base", %"struct.std::_Rb_tree_node_base"* %4, i32 0, i32 3
  %6 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %5, align 8
  %7 = icmp ne %"struct.std::_Rb_tree_node_base"* %6, null
  br i1 %7, label %8, label %12

; <label>:8:                                      ; preds = %3
  %9 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %2, align 8
  %10 = getelementptr inbounds %"struct.std::_Rb_tree_node_base", %"struct.std::_Rb_tree_node_base"* %9, i32 0, i32 3
  %11 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %10, align 8
  store %"struct.std::_Rb_tree_node_base"* %11, %"struct.std::_Rb_tree_node_base"** %2, align 8
  br label %3

; <label>:12:                                     ; preds = %3
  %13 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %2, align 8
  ret %"struct.std::_Rb_tree_node_base"* %13
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"struct.std::_Rb_tree_node_base"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE5beginEv(%"class.std::_Rb_tree"*) #4 comdat align 2 {
  %2 = alloca %"struct.std::_Rb_tree_iterator", align 8
  %3 = alloca %"class.std::_Rb_tree"*, align 8
  store %"class.std::_Rb_tree"* %0, %"class.std::_Rb_tree"** %3, align 8
  %4 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %3, align 8
  %5 = getelementptr inbounds %"class.std::_Rb_tree", %"class.std::_Rb_tree"* %4, i32 0, i32 0
  %6 = bitcast %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %5 to i8*
  %7 = getelementptr inbounds i8, i8* %6, i64 8
  %8 = bitcast i8* %7 to %"struct.std::_Rb_tree_header"*
  %9 = getelementptr inbounds %"struct.std::_Rb_tree_header", %"struct.std::_Rb_tree_header"* %8, i32 0, i32 0
  %10 = getelementptr inbounds %"struct.std::_Rb_tree_node_base", %"struct.std::_Rb_tree_node_base"* %9, i32 0, i32 2
  %11 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %10, align 8
  call void @_ZNSt17_Rb_tree_iteratorISt4pairIKi9NonDetLogEEC2EPSt18_Rb_tree_node_base(%"struct.std::_Rb_tree_iterator"* %2, %"struct.std::_Rb_tree_node_base"* %11) #3
  %12 = getelementptr inbounds %"struct.std::_Rb_tree_iterator", %"struct.std::_Rb_tree_iterator"* %2, i32 0, i32 0
  %13 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %12, align 8
  ret %"struct.std::_Rb_tree_node_base"* %13
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt17_Rb_tree_iteratorISt4pairIKi9NonDetLogEEC2EPSt18_Rb_tree_node_base(%"struct.std::_Rb_tree_iterator"*, %"struct.std::_Rb_tree_node_base"*) unnamed_addr #4 comdat align 2 {
  %3 = alloca %"struct.std::_Rb_tree_iterator"*, align 8
  %4 = alloca %"struct.std::_Rb_tree_node_base"*, align 8
  store %"struct.std::_Rb_tree_iterator"* %0, %"struct.std::_Rb_tree_iterator"** %3, align 8
  store %"struct.std::_Rb_tree_node_base"* %1, %"struct.std::_Rb_tree_node_base"** %4, align 8
  %5 = load %"struct.std::_Rb_tree_iterator"*, %"struct.std::_Rb_tree_iterator"** %3, align 8
  %6 = getelementptr inbounds %"struct.std::_Rb_tree_iterator", %"struct.std::_Rb_tree_iterator"* %5, i32 0, i32 0
  %7 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %4, align 8
  store %"struct.std::_Rb_tree_node_base"* %7, %"struct.std::_Rb_tree_node_base"** %6, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"struct.std::_Rb_tree_node_base"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE3endEv(%"class.std::_Rb_tree"*) #4 comdat align 2 {
  %2 = alloca %"struct.std::_Rb_tree_iterator", align 8
  %3 = alloca %"class.std::_Rb_tree"*, align 8
  store %"class.std::_Rb_tree"* %0, %"class.std::_Rb_tree"** %3, align 8
  %4 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %3, align 8
  %5 = getelementptr inbounds %"class.std::_Rb_tree", %"class.std::_Rb_tree"* %4, i32 0, i32 0
  %6 = bitcast %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %5 to i8*
  %7 = getelementptr inbounds i8, i8* %6, i64 8
  %8 = bitcast i8* %7 to %"struct.std::_Rb_tree_header"*
  %9 = getelementptr inbounds %"struct.std::_Rb_tree_header", %"struct.std::_Rb_tree_header"* %8, i32 0, i32 0
  call void @_ZNSt17_Rb_tree_iteratorISt4pairIKi9NonDetLogEEC2EPSt18_Rb_tree_node_base(%"struct.std::_Rb_tree_iterator"* %2, %"struct.std::_Rb_tree_node_base"* %9) #3
  %10 = getelementptr inbounds %"struct.std::_Rb_tree_iterator", %"struct.std::_Rb_tree_iterator"* %2, i32 0, i32 0
  %11 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %10, align 8
  ret %"struct.std::_Rb_tree_node_base"* %11
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant7printerISoEC2ERSo(%"class.boost::detail::variant::printer"*, %"class.std::basic_ostream"* dereferenceable(272)) unnamed_addr #4 comdat align 2 {
  %3 = alloca %"class.boost::detail::variant::printer"*, align 8
  %4 = alloca %"class.std::basic_ostream"*, align 8
  store %"class.boost::detail::variant::printer"* %0, %"class.boost::detail::variant::printer"** %3, align 8
  store %"class.std::basic_ostream"* %1, %"class.std::basic_ostream"** %4, align 8
  %5 = load %"class.boost::detail::variant::printer"*, %"class.boost::detail::variant::printer"** %3, align 8
  %6 = bitcast %"class.boost::detail::variant::printer"* %5 to %"class.boost::static_visitor"*
  %7 = getelementptr inbounds %"class.boost::detail::variant::printer", %"class.boost::detail::variant::printer"* %5, i32 0, i32 0
  %8 = load %"class.std::basic_ostream"*, %"class.std::basic_ostream"** %4, align 8
  store %"class.std::basic_ostream"* %8, %"class.std::basic_ostream"** %7, align 8
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZNKR5boost7variantIiJjcdfEE13apply_visitorINS_6detail7variant7printerISoEEEENT_11result_typeERS7_(%"class.boost::variant"*, %"class.boost::detail::variant::printer"* dereferenceable(8)) #5 comdat align 2 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca %"class.boost::detail::variant::invoke_visitor"*, align 8
  %6 = alloca i8*, align 8
  %7 = alloca %"struct.mpl_::int_"*, align 8
  %8 = alloca %"struct.boost::detail::variant::visitation_impl_step"*, align 8
  %9 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %10 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %11 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %12 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %13 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %14 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %15 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %16 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %17 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %18 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %19 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %20 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %21 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %22 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %23 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %24 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %25 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %26 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %27 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %28 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %29 = alloca %"struct.mpl_::bool_.7", align 1
  %30 = alloca %"struct.boost::integral_constant", align 1
  %31 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %32 = alloca i32, align 4
  %33 = alloca i32, align 4
  %34 = alloca %"class.boost::detail::variant::invoke_visitor"*, align 8
  %35 = alloca i8*, align 8
  %36 = alloca %"struct.mpl_::bool_", align 1
  %37 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %38 = alloca %"class.boost::variant"*, align 8
  %39 = alloca %"class.boost::detail::variant::invoke_visitor"*, align 8
  %40 = alloca %"class.boost::variant"*, align 8
  %41 = alloca %"class.boost::detail::variant::printer"*, align 8
  %42 = alloca %"class.boost::detail::variant::invoke_visitor", align 8
  store %"class.boost::variant"* %0, %"class.boost::variant"** %40, align 8
  store %"class.boost::detail::variant::printer"* %1, %"class.boost::detail::variant::printer"** %41, align 8
  %43 = load %"class.boost::variant"*, %"class.boost::variant"** %40, align 8
  %44 = load %"class.boost::detail::variant::printer"*, %"class.boost::detail::variant::printer"** %41, align 8
  call void @_ZN5boost6detail7variant14invoke_visitorINS1_7printerISoEELb0EEC2ERS4_(%"class.boost::detail::variant::invoke_visitor"* %42, %"class.boost::detail::variant::printer"* dereferenceable(8) %44) #3
  store %"class.boost::variant"* %43, %"class.boost::variant"** %38, align 8
  store %"class.boost::detail::variant::invoke_visitor"* %42, %"class.boost::detail::variant::invoke_visitor"** %39, align 8
  %45 = load %"class.boost::variant"*, %"class.boost::variant"** %38, align 8
  %46 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %45, i32 0, i32 0
  %47 = load i32, i32* %46, align 8
  %48 = call i32 @_ZNK5boost7variantIiJjcdfEE5whichEv(%"class.boost::variant"* %45) #3
  %49 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %39, align 8
  %50 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %45, i32 0, i32 2
  %51 = call i8* @_ZNK5boost15aligned_storageILm8ELm8EE7addressEv(%"class.boost::aligned_storage"* %50)
  store i32 %47, i32* %32, align 4
  store i32 %48, i32* %33, align 4
  store %"class.boost::detail::variant::invoke_visitor"* %49, %"class.boost::detail::variant::invoke_visitor"** %34, align 8
  store i8* %51, i8** %35, align 8
  %52 = load i32, i32* %32, align 4
  %53 = load i32, i32* %33, align 4
  %54 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %34, align 8
  %55 = load i8*, i8** %35, align 8
  store i32 %52, i32* %3, align 4
  store i32 %53, i32* %4, align 4
  store %"class.boost::detail::variant::invoke_visitor"* %54, %"class.boost::detail::variant::invoke_visitor"** %5, align 8
  store i8* %55, i8** %6, align 8
  store %"struct.mpl_::int_"* null, %"struct.mpl_::int_"** %7, align 8
  store %"struct.boost::detail::variant::visitation_impl_step"* null, %"struct.boost::detail::variant::visitation_impl_step"** %8, align 8
  %56 = load i32, i32* %4, align 4
  switch i32 %56, label %137 [
    i32 0, label %57
    i32 1, label %61
    i32 2, label %65
    i32 3, label %69
    i32 4, label %73
    i32 5, label %77
    i32 6, label %81
    i32 7, label %85
    i32 8, label %89
    i32 9, label %93
    i32 10, label %97
    i32 11, label %101
    i32 12, label %105
    i32 13, label %109
    i32 14, label %113
    i32 15, label %117
    i32 16, label %121
    i32 17, label %125
    i32 18, label %129
    i32 19, label %133
  ]

; <label>:57:                                     ; preds = %2
  %58 = load i32, i32* %3, align 4
  %59 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %5, align 8
  %60 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKviNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PT1_T2_i(i32 %58, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8) %59, i8* %60, i32* null, i32 1)
  br label %143

; <label>:61:                                     ; preds = %2
  %62 = load i32, i32* %3, align 4
  %63 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %5, align 8
  %64 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvjNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PT1_T2_i(i32 %62, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8) %63, i8* %64, i32* null, i32 1)
  br label %143

; <label>:65:                                     ; preds = %2
  %66 = load i32, i32* %3, align 4
  %67 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %5, align 8
  %68 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvcNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PT1_T2_i(i32 %66, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8) %67, i8* %68, i8* null, i32 1)
  br label %143

; <label>:69:                                     ; preds = %2
  %70 = load i32, i32* %3, align 4
  %71 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %5, align 8
  %72 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvdNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PT1_T2_i(i32 %70, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8) %71, i8* %72, double* null, i32 1)
  br label %143

; <label>:73:                                     ; preds = %2
  %74 = load i32, i32* %3, align 4
  %75 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %5, align 8
  %76 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvfNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PT1_T2_i(i32 %74, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8) %75, i8* %76, float* null, i32 1)
  br label %143

; <label>:77:                                     ; preds = %2
  %78 = load i32, i32* %3, align 4
  %79 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %5, align 8
  %80 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %78, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8) %79, i8* %80, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %143

; <label>:81:                                     ; preds = %2
  %82 = load i32, i32* %3, align 4
  %83 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %5, align 8
  %84 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %82, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8) %83, i8* %84, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %143

; <label>:85:                                     ; preds = %2
  %86 = load i32, i32* %3, align 4
  %87 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %5, align 8
  %88 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %86, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8) %87, i8* %88, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %143

; <label>:89:                                     ; preds = %2
  %90 = load i32, i32* %3, align 4
  %91 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %5, align 8
  %92 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %90, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8) %91, i8* %92, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %143

; <label>:93:                                     ; preds = %2
  %94 = load i32, i32* %3, align 4
  %95 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %5, align 8
  %96 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %94, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8) %95, i8* %96, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %143

; <label>:97:                                     ; preds = %2
  %98 = load i32, i32* %3, align 4
  %99 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %5, align 8
  %100 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %98, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8) %99, i8* %100, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %143

; <label>:101:                                    ; preds = %2
  %102 = load i32, i32* %3, align 4
  %103 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %5, align 8
  %104 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %102, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8) %103, i8* %104, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %143

; <label>:105:                                    ; preds = %2
  %106 = load i32, i32* %3, align 4
  %107 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %5, align 8
  %108 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %106, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8) %107, i8* %108, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %143

; <label>:109:                                    ; preds = %2
  %110 = load i32, i32* %3, align 4
  %111 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %5, align 8
  %112 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %110, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8) %111, i8* %112, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %143

; <label>:113:                                    ; preds = %2
  %114 = load i32, i32* %3, align 4
  %115 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %5, align 8
  %116 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %114, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8) %115, i8* %116, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %143

; <label>:117:                                    ; preds = %2
  %118 = load i32, i32* %3, align 4
  %119 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %5, align 8
  %120 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %118, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8) %119, i8* %120, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %143

; <label>:121:                                    ; preds = %2
  %122 = load i32, i32* %3, align 4
  %123 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %5, align 8
  %124 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %122, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8) %123, i8* %124, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %143

; <label>:125:                                    ; preds = %2
  %126 = load i32, i32* %3, align 4
  %127 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %5, align 8
  %128 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %126, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8) %127, i8* %128, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %143

; <label>:129:                                    ; preds = %2
  %130 = load i32, i32* %3, align 4
  %131 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %5, align 8
  %132 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %130, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8) %131, i8* %132, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %143

; <label>:133:                                    ; preds = %2
  %134 = load i32, i32* %3, align 4
  %135 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %5, align 8
  %136 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %134, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8) %135, i8* %136, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %143

; <label>:137:                                    ; preds = %2
  %138 = load i32, i32* %3, align 4
  %139 = load i32, i32* %4, align 4
  %140 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %5, align 8
  %141 = load i8*, i8** %6, align 8
  %142 = call dereferenceable(1) %"struct.mpl_::bool_.7"* @_ZNK5boost17integral_constantIbLb1EEcvRKN4mpl_5bool_ILb1EEEEv(%"struct.boost::integral_constant"* %30)
  call void @_ZN5boost6detail7variant15visitation_implIN4mpl_4int_ILi20EEENS1_20visitation_impl_stepINS_3mpl6l_iterINS7_5l_endEEESA_EENS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT1_11result_typeEiiRSL_T2_NS3_5bool_ILb1EEET3_PT_PT0_(i32 %138, i32 %139, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8) %140, i8* %141, %"struct.mpl_::int_.8"* null, %"struct.boost::detail::variant::visitation_impl_step.9"* null)
  br label %143

; <label>:143:                                    ; preds = %57, %61, %65, %69, %73, %77, %81, %85, %89, %93, %97, %101, %105, %109, %113, %117, %121, %125, %129, %133, %137
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant14invoke_visitorINS1_7printerISoEELb0EEC2ERS4_(%"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::printer"* dereferenceable(8)) unnamed_addr #4 comdat align 2 {
  %3 = alloca %"class.boost::detail::variant::invoke_visitor"*, align 8
  %4 = alloca %"class.boost::detail::variant::printer"*, align 8
  store %"class.boost::detail::variant::invoke_visitor"* %0, %"class.boost::detail::variant::invoke_visitor"** %3, align 8
  store %"class.boost::detail::variant::printer"* %1, %"class.boost::detail::variant::printer"** %4, align 8
  %5 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %3, align 8
  %6 = getelementptr inbounds %"class.boost::detail::variant::invoke_visitor", %"class.boost::detail::variant::invoke_visitor"* %5, i32 0, i32 0
  %7 = load %"class.boost::detail::variant::printer"*, %"class.boost::detail::variant::printer"** %4, align 8
  store %"class.boost::detail::variant::printer"* %7, %"class.boost::detail::variant::printer"** %6, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local i8* @_ZNK5boost15aligned_storageILm8ELm8EE7addressEv(%"class.boost::aligned_storage"*) #4 comdat align 2 {
  %2 = alloca %"class.boost::aligned_storage"*, align 8
  store %"class.boost::aligned_storage"* %0, %"class.boost::aligned_storage"** %2, align 8
  %3 = load %"class.boost::aligned_storage"*, %"class.boost::aligned_storage"** %2, align 8
  %4 = bitcast %"class.boost::aligned_storage"* %3 to %"struct.boost::detail::aligned_storage::aligned_storage_imp"*
  %5 = call i8* @_ZNK5boost6detail15aligned_storage19aligned_storage_impILm8ELm8EE7addressEv(%"struct.boost::detail::aligned_storage::aligned_storage_imp"* %4)
  ret i8* %5
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKviNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PT1_T2_i(i32, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8), i8*, i32*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::invoke_visitor"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca i32*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"class.boost::detail::variant::invoke_visitor"* %1, %"class.boost::detail::variant::invoke_visitor"** %8, align 8
  store i8* %2, i8** %9, align 8
  store i32* %3, i32** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load i32*, i32** %10, align 8
  call void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKviEENT_11result_typeEiRS9_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8) %14, i8* %15, i32* %16)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvjNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PT1_T2_i(i32, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8), i8*, i32*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::invoke_visitor"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca i32*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"class.boost::detail::variant::invoke_visitor"* %1, %"class.boost::detail::variant::invoke_visitor"** %8, align 8
  store i8* %2, i8** %9, align 8
  store i32* %3, i32** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load i32*, i32** %10, align 8
  call void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvjEENT_11result_typeEiRS9_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8) %14, i8* %15, i32* %16)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvcNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PT1_T2_i(i32, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8), i8*, i8*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::invoke_visitor"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca i8*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"class.boost::detail::variant::invoke_visitor"* %1, %"class.boost::detail::variant::invoke_visitor"** %8, align 8
  store i8* %2, i8** %9, align 8
  store i8* %3, i8** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load i8*, i8** %10, align 8
  call void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvcEENT_11result_typeEiRS9_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8) %14, i8* %15, i8* %16)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvdNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PT1_T2_i(i32, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8), i8*, double*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::invoke_visitor"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca double*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"class.boost::detail::variant::invoke_visitor"* %1, %"class.boost::detail::variant::invoke_visitor"** %8, align 8
  store i8* %2, i8** %9, align 8
  store double* %3, double** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load double*, double** %10, align 8
  call void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvdEENT_11result_typeEiRS9_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8) %14, i8* %15, double* %16)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvfNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PT1_T2_i(i32, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8), i8*, float*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::invoke_visitor"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca float*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"class.boost::detail::variant::invoke_visitor"* %1, %"class.boost::detail::variant::invoke_visitor"** %8, align 8
  store i8* %2, i8** %9, align 8
  store float* %3, float** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load float*, float** %10, align 8
  call void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvfEENT_11result_typeEiRS9_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8) %14, i8* %15, float* %16)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSC_T0_PNS1_22apply_visitor_unrolledET1_l(i32, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8), i8*, %"struct.boost::detail::variant::apply_visitor_unrolled"*, i64) #4 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::invoke_visitor"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca %"struct.boost::detail::variant::apply_visitor_unrolled"*, align 8
  %11 = alloca i64, align 8
  store i32 %0, i32* %7, align 4
  store %"class.boost::detail::variant::invoke_visitor"* %1, %"class.boost::detail::variant::invoke_visitor"** %8, align 8
  store i8* %2, i8** %9, align 8
  store %"struct.boost::detail::variant::apply_visitor_unrolled"* %3, %"struct.boost::detail::variant::apply_visitor_unrolled"** %10, align 8
  store i64 %4, i64* %11, align 8
  call void @_ZN5boost6detail7variant13forced_returnIvEET_v() #17
  unreachable
                                                  ; No predecessors!
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant15visitation_implIN4mpl_4int_ILi20EEENS1_20visitation_impl_stepINS_3mpl6l_iterINS7_5l_endEEESA_EENS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT1_11result_typeEiiRSL_T2_NS3_5bool_ILb1EEET3_PT_PT0_(i32, i32, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8), i8*, %"struct.mpl_::int_.8"*, %"struct.boost::detail::variant::visitation_impl_step.9"*) #4 comdat {
  %7 = alloca %"struct.mpl_::bool_.7", align 1
  %8 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca %"class.boost::detail::variant::invoke_visitor"*, align 8
  %12 = alloca i8*, align 8
  %13 = alloca %"struct.mpl_::int_.8"*, align 8
  %14 = alloca %"struct.boost::detail::variant::visitation_impl_step.9"*, align 8
  store i32 %0, i32* %9, align 4
  store i32 %1, i32* %10, align 4
  store %"class.boost::detail::variant::invoke_visitor"* %2, %"class.boost::detail::variant::invoke_visitor"** %11, align 8
  store i8* %3, i8** %12, align 8
  store %"struct.mpl_::int_.8"* %4, %"struct.mpl_::int_.8"** %13, align 8
  store %"struct.boost::detail::variant::visitation_impl_step.9"* %5, %"struct.boost::detail::variant::visitation_impl_step.9"** %14, align 8
  call void @_ZN5boost6detail7variant13forced_returnIvEET_v() #17
  unreachable
                                                  ; No predecessors!
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKviEENT_11result_typeEiRS9_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8), i8*, i32*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"class.boost::detail::variant::invoke_visitor"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca i32*, align 8
  store i32 %0, i32* %6, align 4
  store %"class.boost::detail::variant::invoke_visitor"* %1, %"class.boost::detail::variant::invoke_visitor"** %7, align 8
  store i8* %2, i8** %8, align 8
  store i32* %3, i32** %9, align 8
  %10 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(4) i32* @_ZN5boost6detail7variant12cast_storageIiEERKT_PKv(i8* %11)
  call void @_ZN5boost6detail7variant14invoke_visitorINS1_7printerISoEELb0EE14internal_visitIRKiEENS_12disable_if_cIXaaLb0Esr7is_sameIT_SA_EE5valueEvE4typeEOSA_i(%"class.boost::detail::variant::invoke_visitor"* %10, i32* dereferenceable(4) %12, i32 1)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant14invoke_visitorINS1_7printerISoEELb0EE14internal_visitIRKiEENS_12disable_if_cIXaaLb0Esr7is_sameIT_SA_EE5valueEvE4typeEOSA_i(%"class.boost::detail::variant::invoke_visitor"*, i32* dereferenceable(4), i32) #5 comdat align 2 {
  %4 = alloca %"class.boost::detail::variant::invoke_visitor"*, align 8
  %5 = alloca i32*, align 8
  %6 = alloca i32, align 4
  store %"class.boost::detail::variant::invoke_visitor"* %0, %"class.boost::detail::variant::invoke_visitor"** %4, align 8
  store i32* %1, i32** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %4, align 8
  %8 = getelementptr inbounds %"class.boost::detail::variant::invoke_visitor", %"class.boost::detail::variant::invoke_visitor"* %7, i32 0, i32 0
  %9 = load %"class.boost::detail::variant::printer"*, %"class.boost::detail::variant::printer"** %8, align 8
  %10 = load i32*, i32** %5, align 8
  call void @_ZNK5boost6detail7variant7printerISoEclIiEEvRKT_(%"class.boost::detail::variant::printer"* %9, i32* dereferenceable(4) %10)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(4) i32* @_ZN5boost6detail7variant12cast_storageIiEERKT_PKv(i8*) #4 comdat {
  %2 = alloca i8*, align 8
  store i8* %0, i8** %2, align 8
  %3 = load i8*, i8** %2, align 8
  %4 = bitcast i8* %3 to i32*
  ret i32* %4
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost6detail7variant7printerISoEclIiEEvRKT_(%"class.boost::detail::variant::printer"*, i32* dereferenceable(4)) #5 comdat align 2 {
  %3 = alloca %"class.boost::detail::variant::printer"*, align 8
  %4 = alloca i32*, align 8
  store %"class.boost::detail::variant::printer"* %0, %"class.boost::detail::variant::printer"** %3, align 8
  store i32* %1, i32** %4, align 8
  %5 = load %"class.boost::detail::variant::printer"*, %"class.boost::detail::variant::printer"** %3, align 8
  %6 = getelementptr inbounds %"class.boost::detail::variant::printer", %"class.boost::detail::variant::printer"* %5, i32 0, i32 0
  %7 = load %"class.std::basic_ostream"*, %"class.std::basic_ostream"** %6, align 8
  %8 = load i32*, i32** %4, align 8
  %9 = load i32, i32* %8, align 4
  %10 = call dereferenceable(272) %"class.std::basic_ostream"* @_ZNSolsEi(%"class.std::basic_ostream"* %7, i32 %9)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvjEENT_11result_typeEiRS9_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8), i8*, i32*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"class.boost::detail::variant::invoke_visitor"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca i32*, align 8
  store i32 %0, i32* %6, align 4
  store %"class.boost::detail::variant::invoke_visitor"* %1, %"class.boost::detail::variant::invoke_visitor"** %7, align 8
  store i8* %2, i8** %8, align 8
  store i32* %3, i32** %9, align 8
  %10 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(4) i32* @_ZN5boost6detail7variant12cast_storageIjEERKT_PKv(i8* %11)
  call void @_ZN5boost6detail7variant14invoke_visitorINS1_7printerISoEELb0EE14internal_visitIRKjEENS_12disable_if_cIXaaLb0Esr7is_sameIT_SA_EE5valueEvE4typeEOSA_i(%"class.boost::detail::variant::invoke_visitor"* %10, i32* dereferenceable(4) %12, i32 1)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant14invoke_visitorINS1_7printerISoEELb0EE14internal_visitIRKjEENS_12disable_if_cIXaaLb0Esr7is_sameIT_SA_EE5valueEvE4typeEOSA_i(%"class.boost::detail::variant::invoke_visitor"*, i32* dereferenceable(4), i32) #5 comdat align 2 {
  %4 = alloca %"class.boost::detail::variant::invoke_visitor"*, align 8
  %5 = alloca i32*, align 8
  %6 = alloca i32, align 4
  store %"class.boost::detail::variant::invoke_visitor"* %0, %"class.boost::detail::variant::invoke_visitor"** %4, align 8
  store i32* %1, i32** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %4, align 8
  %8 = getelementptr inbounds %"class.boost::detail::variant::invoke_visitor", %"class.boost::detail::variant::invoke_visitor"* %7, i32 0, i32 0
  %9 = load %"class.boost::detail::variant::printer"*, %"class.boost::detail::variant::printer"** %8, align 8
  %10 = load i32*, i32** %5, align 8
  call void @_ZNK5boost6detail7variant7printerISoEclIjEEvRKT_(%"class.boost::detail::variant::printer"* %9, i32* dereferenceable(4) %10)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(4) i32* @_ZN5boost6detail7variant12cast_storageIjEERKT_PKv(i8*) #4 comdat {
  %2 = alloca i8*, align 8
  store i8* %0, i8** %2, align 8
  %3 = load i8*, i8** %2, align 8
  %4 = bitcast i8* %3 to i32*
  ret i32* %4
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost6detail7variant7printerISoEclIjEEvRKT_(%"class.boost::detail::variant::printer"*, i32* dereferenceable(4)) #5 comdat align 2 {
  %3 = alloca %"class.boost::detail::variant::printer"*, align 8
  %4 = alloca i32*, align 8
  store %"class.boost::detail::variant::printer"* %0, %"class.boost::detail::variant::printer"** %3, align 8
  store i32* %1, i32** %4, align 8
  %5 = load %"class.boost::detail::variant::printer"*, %"class.boost::detail::variant::printer"** %3, align 8
  %6 = getelementptr inbounds %"class.boost::detail::variant::printer", %"class.boost::detail::variant::printer"* %5, i32 0, i32 0
  %7 = load %"class.std::basic_ostream"*, %"class.std::basic_ostream"** %6, align 8
  %8 = load i32*, i32** %4, align 8
  %9 = load i32, i32* %8, align 4
  %10 = call dereferenceable(272) %"class.std::basic_ostream"* @_ZNSolsEj(%"class.std::basic_ostream"* %7, i32 %9)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvcEENT_11result_typeEiRS9_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8), i8*, i8*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"class.boost::detail::variant::invoke_visitor"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca i8*, align 8
  store i32 %0, i32* %6, align 4
  store %"class.boost::detail::variant::invoke_visitor"* %1, %"class.boost::detail::variant::invoke_visitor"** %7, align 8
  store i8* %2, i8** %8, align 8
  store i8* %3, i8** %9, align 8
  %10 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(1) i8* @_ZN5boost6detail7variant12cast_storageIcEERKT_PKv(i8* %11)
  call void @_ZN5boost6detail7variant14invoke_visitorINS1_7printerISoEELb0EE14internal_visitIRKcEENS_12disable_if_cIXaaLb0Esr7is_sameIT_SA_EE5valueEvE4typeEOSA_i(%"class.boost::detail::variant::invoke_visitor"* %10, i8* dereferenceable(1) %12, i32 1)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant14invoke_visitorINS1_7printerISoEELb0EE14internal_visitIRKcEENS_12disable_if_cIXaaLb0Esr7is_sameIT_SA_EE5valueEvE4typeEOSA_i(%"class.boost::detail::variant::invoke_visitor"*, i8* dereferenceable(1), i32) #5 comdat align 2 {
  %4 = alloca %"class.boost::detail::variant::invoke_visitor"*, align 8
  %5 = alloca i8*, align 8
  %6 = alloca i32, align 4
  store %"class.boost::detail::variant::invoke_visitor"* %0, %"class.boost::detail::variant::invoke_visitor"** %4, align 8
  store i8* %1, i8** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %4, align 8
  %8 = getelementptr inbounds %"class.boost::detail::variant::invoke_visitor", %"class.boost::detail::variant::invoke_visitor"* %7, i32 0, i32 0
  %9 = load %"class.boost::detail::variant::printer"*, %"class.boost::detail::variant::printer"** %8, align 8
  %10 = load i8*, i8** %5, align 8
  call void @_ZNK5boost6detail7variant7printerISoEclIcEEvRKT_(%"class.boost::detail::variant::printer"* %9, i8* dereferenceable(1) %10)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(1) i8* @_ZN5boost6detail7variant12cast_storageIcEERKT_PKv(i8*) #4 comdat {
  %2 = alloca i8*, align 8
  store i8* %0, i8** %2, align 8
  %3 = load i8*, i8** %2, align 8
  ret i8* %3
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost6detail7variant7printerISoEclIcEEvRKT_(%"class.boost::detail::variant::printer"*, i8* dereferenceable(1)) #5 comdat align 2 {
  %3 = alloca %"class.boost::detail::variant::printer"*, align 8
  %4 = alloca i8*, align 8
  store %"class.boost::detail::variant::printer"* %0, %"class.boost::detail::variant::printer"** %3, align 8
  store i8* %1, i8** %4, align 8
  %5 = load %"class.boost::detail::variant::printer"*, %"class.boost::detail::variant::printer"** %3, align 8
  %6 = getelementptr inbounds %"class.boost::detail::variant::printer", %"class.boost::detail::variant::printer"* %5, i32 0, i32 0
  %7 = load %"class.std::basic_ostream"*, %"class.std::basic_ostream"** %6, align 8
  %8 = load i8*, i8** %4, align 8
  %9 = load i8, i8* %8, align 1
  %10 = call dereferenceable(272) %"class.std::basic_ostream"* @_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_c(%"class.std::basic_ostream"* dereferenceable(272) %7, i8 signext %9)
  ret void
}

declare dso_local dereferenceable(272) %"class.std::basic_ostream"* @_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_c(%"class.std::basic_ostream"* dereferenceable(272), i8 signext) #1

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvdEENT_11result_typeEiRS9_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8), i8*, double*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"class.boost::detail::variant::invoke_visitor"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca double*, align 8
  store i32 %0, i32* %6, align 4
  store %"class.boost::detail::variant::invoke_visitor"* %1, %"class.boost::detail::variant::invoke_visitor"** %7, align 8
  store i8* %2, i8** %8, align 8
  store double* %3, double** %9, align 8
  %10 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(8) double* @_ZN5boost6detail7variant12cast_storageIdEERKT_PKv(i8* %11)
  call void @_ZN5boost6detail7variant14invoke_visitorINS1_7printerISoEELb0EE14internal_visitIRKdEENS_12disable_if_cIXaaLb0Esr7is_sameIT_SA_EE5valueEvE4typeEOSA_i(%"class.boost::detail::variant::invoke_visitor"* %10, double* dereferenceable(8) %12, i32 1)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant14invoke_visitorINS1_7printerISoEELb0EE14internal_visitIRKdEENS_12disable_if_cIXaaLb0Esr7is_sameIT_SA_EE5valueEvE4typeEOSA_i(%"class.boost::detail::variant::invoke_visitor"*, double* dereferenceable(8), i32) #5 comdat align 2 {
  %4 = alloca %"class.boost::detail::variant::invoke_visitor"*, align 8
  %5 = alloca double*, align 8
  %6 = alloca i32, align 4
  store %"class.boost::detail::variant::invoke_visitor"* %0, %"class.boost::detail::variant::invoke_visitor"** %4, align 8
  store double* %1, double** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %4, align 8
  %8 = getelementptr inbounds %"class.boost::detail::variant::invoke_visitor", %"class.boost::detail::variant::invoke_visitor"* %7, i32 0, i32 0
  %9 = load %"class.boost::detail::variant::printer"*, %"class.boost::detail::variant::printer"** %8, align 8
  %10 = load double*, double** %5, align 8
  call void @_ZNK5boost6detail7variant7printerISoEclIdEEvRKT_(%"class.boost::detail::variant::printer"* %9, double* dereferenceable(8) %10)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(8) double* @_ZN5boost6detail7variant12cast_storageIdEERKT_PKv(i8*) #4 comdat {
  %2 = alloca i8*, align 8
  store i8* %0, i8** %2, align 8
  %3 = load i8*, i8** %2, align 8
  %4 = bitcast i8* %3 to double*
  ret double* %4
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost6detail7variant7printerISoEclIdEEvRKT_(%"class.boost::detail::variant::printer"*, double* dereferenceable(8)) #5 comdat align 2 {
  %3 = alloca %"class.boost::detail::variant::printer"*, align 8
  %4 = alloca double*, align 8
  store %"class.boost::detail::variant::printer"* %0, %"class.boost::detail::variant::printer"** %3, align 8
  store double* %1, double** %4, align 8
  %5 = load %"class.boost::detail::variant::printer"*, %"class.boost::detail::variant::printer"** %3, align 8
  %6 = getelementptr inbounds %"class.boost::detail::variant::printer", %"class.boost::detail::variant::printer"* %5, i32 0, i32 0
  %7 = load %"class.std::basic_ostream"*, %"class.std::basic_ostream"** %6, align 8
  %8 = load double*, double** %4, align 8
  %9 = load double, double* %8, align 8
  %10 = call dereferenceable(272) %"class.std::basic_ostream"* @_ZNSolsEd(%"class.std::basic_ostream"* %7, double %9)
  ret void
}

declare dso_local dereferenceable(272) %"class.std::basic_ostream"* @_ZNSolsEd(%"class.std::basic_ostream"*, double) #1

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_7printerISoEELb0EEEPKvfEENT_11result_typeEiRS9_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"class.boost::detail::variant::invoke_visitor"* dereferenceable(8), i8*, float*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"class.boost::detail::variant::invoke_visitor"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca float*, align 8
  store i32 %0, i32* %6, align 4
  store %"class.boost::detail::variant::invoke_visitor"* %1, %"class.boost::detail::variant::invoke_visitor"** %7, align 8
  store i8* %2, i8** %8, align 8
  store float* %3, float** %9, align 8
  %10 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(4) float* @_ZN5boost6detail7variant12cast_storageIfEERKT_PKv(i8* %11)
  call void @_ZN5boost6detail7variant14invoke_visitorINS1_7printerISoEELb0EE14internal_visitIRKfEENS_12disable_if_cIXaaLb0Esr7is_sameIT_SA_EE5valueEvE4typeEOSA_i(%"class.boost::detail::variant::invoke_visitor"* %10, float* dereferenceable(4) %12, i32 1)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant14invoke_visitorINS1_7printerISoEELb0EE14internal_visitIRKfEENS_12disable_if_cIXaaLb0Esr7is_sameIT_SA_EE5valueEvE4typeEOSA_i(%"class.boost::detail::variant::invoke_visitor"*, float* dereferenceable(4), i32) #5 comdat align 2 {
  %4 = alloca %"class.boost::detail::variant::invoke_visitor"*, align 8
  %5 = alloca float*, align 8
  %6 = alloca i32, align 4
  store %"class.boost::detail::variant::invoke_visitor"* %0, %"class.boost::detail::variant::invoke_visitor"** %4, align 8
  store float* %1, float** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"class.boost::detail::variant::invoke_visitor"*, %"class.boost::detail::variant::invoke_visitor"** %4, align 8
  %8 = getelementptr inbounds %"class.boost::detail::variant::invoke_visitor", %"class.boost::detail::variant::invoke_visitor"* %7, i32 0, i32 0
  %9 = load %"class.boost::detail::variant::printer"*, %"class.boost::detail::variant::printer"** %8, align 8
  %10 = load float*, float** %5, align 8
  call void @_ZNK5boost6detail7variant7printerISoEclIfEEvRKT_(%"class.boost::detail::variant::printer"* %9, float* dereferenceable(4) %10)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(4) float* @_ZN5boost6detail7variant12cast_storageIfEERKT_PKv(i8*) #4 comdat {
  %2 = alloca i8*, align 8
  store i8* %0, i8** %2, align 8
  %3 = load i8*, i8** %2, align 8
  %4 = bitcast i8* %3 to float*
  ret float* %4
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost6detail7variant7printerISoEclIfEEvRKT_(%"class.boost::detail::variant::printer"*, float* dereferenceable(4)) #5 comdat align 2 {
  %3 = alloca %"class.boost::detail::variant::printer"*, align 8
  %4 = alloca float*, align 8
  store %"class.boost::detail::variant::printer"* %0, %"class.boost::detail::variant::printer"** %3, align 8
  store float* %1, float** %4, align 8
  %5 = load %"class.boost::detail::variant::printer"*, %"class.boost::detail::variant::printer"** %3, align 8
  %6 = getelementptr inbounds %"class.boost::detail::variant::printer", %"class.boost::detail::variant::printer"* %5, i32 0, i32 0
  %7 = load %"class.std::basic_ostream"*, %"class.std::basic_ostream"** %6, align 8
  %8 = load float*, float** %4, align 8
  %9 = load float, float* %8, align 4
  %10 = call dereferenceable(272) %"class.std::basic_ostream"* @_ZNSolsEf(%"class.std::basic_ostream"* %7, float %9)
  ret void
}

declare dso_local dereferenceable(272) %"class.std::basic_ostream"* @_ZNSolsEf(%"class.std::basic_ostream"*, float) #1

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local dereferenceable(16) %"class.std::type_info"* @_ZNK5boost7variantIiJjcdfEE4typeEv(%"class.boost::variant"*) #5 comdat align 2 {
  %2 = alloca %"class.boost::variant"*, align 8
  %3 = alloca %"class.boost::detail::variant::reflect", align 1
  store %"class.boost::variant"* %0, %"class.boost::variant"** %2, align 8
  %4 = load %"class.boost::variant"*, %"class.boost::variant"** %2, align 8
  %5 = call dereferenceable(16) %"class.std::type_info"* @_ZNKR5boost7variantIiJjcdfEE13apply_visitorINS_6detail7variant7reflectEEENT_11result_typeERS6_(%"class.boost::variant"* %4, %"class.boost::detail::variant::reflect"* dereferenceable(1) %3)
  ret %"class.std::type_info"* %5
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local zeroext i1 @_ZNKSt9type_infoeqERKS_(%"class.std::type_info"*, %"class.std::type_info"* dereferenceable(16)) #4 comdat align 2 {
  %3 = alloca %"class.std::type_info"*, align 8
  %4 = alloca %"class.std::type_info"*, align 8
  store %"class.std::type_info"* %0, %"class.std::type_info"** %3, align 8
  store %"class.std::type_info"* %1, %"class.std::type_info"** %4, align 8
  %5 = load %"class.std::type_info"*, %"class.std::type_info"** %3, align 8
  %6 = getelementptr inbounds %"class.std::type_info", %"class.std::type_info"* %5, i32 0, i32 1
  %7 = load i8*, i8** %6, align 8
  %8 = load %"class.std::type_info"*, %"class.std::type_info"** %4, align 8
  %9 = getelementptr inbounds %"class.std::type_info", %"class.std::type_info"* %8, i32 0, i32 1
  %10 = load i8*, i8** %9, align 8
  %11 = icmp eq i8* %7, %10
  br i1 %11, label %29, label %12

; <label>:12:                                     ; preds = %2
  %13 = getelementptr inbounds %"class.std::type_info", %"class.std::type_info"* %5, i32 0, i32 1
  %14 = load i8*, i8** %13, align 8
  %15 = getelementptr inbounds i8, i8* %14, i64 0
  %16 = load i8, i8* %15, align 1
  %17 = sext i8 %16 to i32
  %18 = icmp ne i32 %17, 42
  br i1 %18, label %19, label %27

; <label>:19:                                     ; preds = %12
  %20 = getelementptr inbounds %"class.std::type_info", %"class.std::type_info"* %5, i32 0, i32 1
  %21 = load i8*, i8** %20, align 8
  %22 = load %"class.std::type_info"*, %"class.std::type_info"** %4, align 8
  %23 = getelementptr inbounds %"class.std::type_info", %"class.std::type_info"* %22, i32 0, i32 1
  %24 = load i8*, i8** %23, align 8
  %25 = call i32 @strcmp(i8* %21, i8* %24) #3
  %26 = icmp eq i32 %25, 0
  br label %27

; <label>:27:                                     ; preds = %19, %12
  %28 = phi i1 [ false, %12 ], [ %26, %19 ]
  br label %29

; <label>:29:                                     ; preds = %27, %2
  %30 = phi i1 [ true, %2 ], [ %28, %27 ]
  ret i1 %30
}

declare dso_local dereferenceable(32) %"class.std::__cxx11::basic_string"* @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSEPKc(%"class.std::__cxx11::basic_string"*, i8*) #1

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local dereferenceable(16) %"class.std::type_info"* @_ZNKR5boost7variantIiJjcdfEE13apply_visitorINS_6detail7variant7reflectEEENT_11result_typeERS6_(%"class.boost::variant"*, %"class.boost::detail::variant::reflect"* dereferenceable(1)) #5 comdat align 2 {
  %3 = alloca %"class.std::type_info"*, align 8
  %4 = alloca %"struct.mpl_::bool_", align 1
  %5 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::invoke_visitor.11"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca %"struct.mpl_::int_"*, align 8
  %11 = alloca %"struct.boost::detail::variant::visitation_impl_step"*, align 8
  %12 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %13 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %14 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %15 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %16 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %17 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %18 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %19 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %20 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %21 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %22 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %23 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %24 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %25 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %26 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %27 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %28 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %29 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %30 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %31 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %32 = alloca %"struct.mpl_::bool_.7", align 1
  %33 = alloca %"struct.boost::integral_constant", align 1
  %34 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %35 = alloca i32, align 4
  %36 = alloca i32, align 4
  %37 = alloca %"class.boost::detail::variant::invoke_visitor.11"*, align 8
  %38 = alloca i8*, align 8
  %39 = alloca %"struct.mpl_::bool_", align 1
  %40 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %41 = alloca %"class.boost::variant"*, align 8
  %42 = alloca %"class.boost::detail::variant::invoke_visitor.11"*, align 8
  %43 = alloca %"class.boost::variant"*, align 8
  %44 = alloca %"class.boost::detail::variant::reflect"*, align 8
  %45 = alloca %"class.boost::detail::variant::invoke_visitor.11", align 8
  store %"class.boost::variant"* %0, %"class.boost::variant"** %43, align 8
  store %"class.boost::detail::variant::reflect"* %1, %"class.boost::detail::variant::reflect"** %44, align 8
  %46 = load %"class.boost::variant"*, %"class.boost::variant"** %43, align 8
  %47 = load %"class.boost::detail::variant::reflect"*, %"class.boost::detail::variant::reflect"** %44, align 8
  call void @_ZN5boost6detail7variant14invoke_visitorINS1_7reflectELb0EEC2ERS3_(%"class.boost::detail::variant::invoke_visitor.11"* %45, %"class.boost::detail::variant::reflect"* dereferenceable(1) %47) #3
  store %"class.boost::variant"* %46, %"class.boost::variant"** %41, align 8
  store %"class.boost::detail::variant::invoke_visitor.11"* %45, %"class.boost::detail::variant::invoke_visitor.11"** %42, align 8
  %48 = load %"class.boost::variant"*, %"class.boost::variant"** %41, align 8
  %49 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %48, i32 0, i32 0
  %50 = load i32, i32* %49, align 8
  %51 = call i32 @_ZNK5boost7variantIiJjcdfEE5whichEv(%"class.boost::variant"* %48) #3
  %52 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %42, align 8
  %53 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %48, i32 0, i32 2
  %54 = call i8* @_ZNK5boost15aligned_storageILm8ELm8EE7addressEv(%"class.boost::aligned_storage"* %53)
  store i32 %50, i32* %35, align 4
  store i32 %51, i32* %36, align 4
  store %"class.boost::detail::variant::invoke_visitor.11"* %52, %"class.boost::detail::variant::invoke_visitor.11"** %37, align 8
  store i8* %54, i8** %38, align 8
  %55 = load i32, i32* %35, align 4
  %56 = load i32, i32* %36, align 4
  %57 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %37, align 8
  %58 = load i8*, i8** %38, align 8
  store i32 %55, i32* %6, align 4
  store i32 %56, i32* %7, align 4
  store %"class.boost::detail::variant::invoke_visitor.11"* %57, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  store i8* %58, i8** %9, align 8
  store %"struct.mpl_::int_"* null, %"struct.mpl_::int_"** %10, align 8
  store %"struct.boost::detail::variant::visitation_impl_step"* null, %"struct.boost::detail::variant::visitation_impl_step"** %11, align 8
  %59 = load i32, i32* %7, align 4
  switch i32 %59, label %160 [
    i32 0, label %60
    i32 1, label %65
    i32 2, label %70
    i32 3, label %75
    i32 4, label %80
    i32 5, label %85
    i32 6, label %90
    i32 7, label %95
    i32 8, label %100
    i32 9, label %105
    i32 10, label %110
    i32 11, label %115
    i32 12, label %120
    i32 13, label %125
    i32 14, label %130
    i32 15, label %135
    i32 16, label %140
    i32 17, label %145
    i32 18, label %150
    i32 19, label %155
  ]

; <label>:60:                                     ; preds = %2
  %61 = load i32, i32* %6, align 4
  %62 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  %63 = load i8*, i8** %9, align 8
  %64 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKviNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PT1_T2_i(i32 %61, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8) %62, i8* %63, i32* null, i32 1)
  store %"class.std::type_info"* %64, %"class.std::type_info"** %3, align 8
  br label %167

; <label>:65:                                     ; preds = %2
  %66 = load i32, i32* %6, align 4
  %67 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  %68 = load i8*, i8** %9, align 8
  %69 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKvjNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PT1_T2_i(i32 %66, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8) %67, i8* %68, i32* null, i32 1)
  store %"class.std::type_info"* %69, %"class.std::type_info"** %3, align 8
  br label %167

; <label>:70:                                     ; preds = %2
  %71 = load i32, i32* %6, align 4
  %72 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  %73 = load i8*, i8** %9, align 8
  %74 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKvcNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PT1_T2_i(i32 %71, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8) %72, i8* %73, i8* null, i32 1)
  store %"class.std::type_info"* %74, %"class.std::type_info"** %3, align 8
  br label %167

; <label>:75:                                     ; preds = %2
  %76 = load i32, i32* %6, align 4
  %77 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  %78 = load i8*, i8** %9, align 8
  %79 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKvdNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PT1_T2_i(i32 %76, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8) %77, i8* %78, double* null, i32 1)
  store %"class.std::type_info"* %79, %"class.std::type_info"** %3, align 8
  br label %167

; <label>:80:                                     ; preds = %2
  %81 = load i32, i32* %6, align 4
  %82 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  %83 = load i8*, i8** %9, align 8
  %84 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKvfNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PT1_T2_i(i32 %81, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8) %82, i8* %83, float* null, i32 1)
  store %"class.std::type_info"* %84, %"class.std::type_info"** %3, align 8
  br label %167

; <label>:85:                                     ; preds = %2
  %86 = load i32, i32* %6, align 4
  %87 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  %88 = load i8*, i8** %9, align 8
  %89 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %86, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8) %87, i8* %88, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  store %"class.std::type_info"* %89, %"class.std::type_info"** %3, align 8
  br label %167

; <label>:90:                                     ; preds = %2
  %91 = load i32, i32* %6, align 4
  %92 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  %93 = load i8*, i8** %9, align 8
  %94 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %91, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8) %92, i8* %93, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  store %"class.std::type_info"* %94, %"class.std::type_info"** %3, align 8
  br label %167

; <label>:95:                                     ; preds = %2
  %96 = load i32, i32* %6, align 4
  %97 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  %98 = load i8*, i8** %9, align 8
  %99 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %96, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8) %97, i8* %98, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  store %"class.std::type_info"* %99, %"class.std::type_info"** %3, align 8
  br label %167

; <label>:100:                                    ; preds = %2
  %101 = load i32, i32* %6, align 4
  %102 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  %103 = load i8*, i8** %9, align 8
  %104 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %101, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8) %102, i8* %103, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  store %"class.std::type_info"* %104, %"class.std::type_info"** %3, align 8
  br label %167

; <label>:105:                                    ; preds = %2
  %106 = load i32, i32* %6, align 4
  %107 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  %108 = load i8*, i8** %9, align 8
  %109 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %106, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8) %107, i8* %108, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  store %"class.std::type_info"* %109, %"class.std::type_info"** %3, align 8
  br label %167

; <label>:110:                                    ; preds = %2
  %111 = load i32, i32* %6, align 4
  %112 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  %113 = load i8*, i8** %9, align 8
  %114 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %111, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8) %112, i8* %113, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  store %"class.std::type_info"* %114, %"class.std::type_info"** %3, align 8
  br label %167

; <label>:115:                                    ; preds = %2
  %116 = load i32, i32* %6, align 4
  %117 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  %118 = load i8*, i8** %9, align 8
  %119 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %116, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8) %117, i8* %118, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  store %"class.std::type_info"* %119, %"class.std::type_info"** %3, align 8
  br label %167

; <label>:120:                                    ; preds = %2
  %121 = load i32, i32* %6, align 4
  %122 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  %123 = load i8*, i8** %9, align 8
  %124 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %121, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8) %122, i8* %123, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  store %"class.std::type_info"* %124, %"class.std::type_info"** %3, align 8
  br label %167

; <label>:125:                                    ; preds = %2
  %126 = load i32, i32* %6, align 4
  %127 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  %128 = load i8*, i8** %9, align 8
  %129 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %126, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8) %127, i8* %128, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  store %"class.std::type_info"* %129, %"class.std::type_info"** %3, align 8
  br label %167

; <label>:130:                                    ; preds = %2
  %131 = load i32, i32* %6, align 4
  %132 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  %133 = load i8*, i8** %9, align 8
  %134 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %131, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8) %132, i8* %133, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  store %"class.std::type_info"* %134, %"class.std::type_info"** %3, align 8
  br label %167

; <label>:135:                                    ; preds = %2
  %136 = load i32, i32* %6, align 4
  %137 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  %138 = load i8*, i8** %9, align 8
  %139 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %136, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8) %137, i8* %138, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  store %"class.std::type_info"* %139, %"class.std::type_info"** %3, align 8
  br label %167

; <label>:140:                                    ; preds = %2
  %141 = load i32, i32* %6, align 4
  %142 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  %143 = load i8*, i8** %9, align 8
  %144 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %141, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8) %142, i8* %143, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  store %"class.std::type_info"* %144, %"class.std::type_info"** %3, align 8
  br label %167

; <label>:145:                                    ; preds = %2
  %146 = load i32, i32* %6, align 4
  %147 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  %148 = load i8*, i8** %9, align 8
  %149 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %146, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8) %147, i8* %148, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  store %"class.std::type_info"* %149, %"class.std::type_info"** %3, align 8
  br label %167

; <label>:150:                                    ; preds = %2
  %151 = load i32, i32* %6, align 4
  %152 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  %153 = load i8*, i8** %9, align 8
  %154 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %151, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8) %152, i8* %153, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  store %"class.std::type_info"* %154, %"class.std::type_info"** %3, align 8
  br label %167

; <label>:155:                                    ; preds = %2
  %156 = load i32, i32* %6, align 4
  %157 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  %158 = load i8*, i8** %9, align 8
  %159 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %156, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8) %157, i8* %158, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  store %"class.std::type_info"* %159, %"class.std::type_info"** %3, align 8
  br label %167

; <label>:160:                                    ; preds = %2
  %161 = load i32, i32* %6, align 4
  %162 = load i32, i32* %7, align 4
  %163 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  %164 = load i8*, i8** %9, align 8
  %165 = call dereferenceable(1) %"struct.mpl_::bool_.7"* @_ZNK5boost17integral_constantIbLb1EEcvRKN4mpl_5bool_ILb1EEEEv(%"struct.boost::integral_constant"* %33)
  %166 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant15visitation_implIN4mpl_4int_ILi20EEENS1_20visitation_impl_stepINS_3mpl6l_iterINS7_5l_endEEESA_EENS1_14invoke_visitorINS1_7reflectELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT1_11result_typeEiiRSK_T2_NS3_5bool_ILb1EEET3_PT_PT0_(i32 %161, i32 %162, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8) %163, i8* %164, %"struct.mpl_::int_.8"* null, %"struct.boost::detail::variant::visitation_impl_step.9"* null)
  store %"class.std::type_info"* %166, %"class.std::type_info"** %3, align 8
  br label %167

; <label>:167:                                    ; preds = %60, %65, %70, %75, %80, %85, %90, %95, %100, %105, %110, %115, %120, %125, %130, %135, %140, %145, %150, %155, %160
  %168 = load %"class.std::type_info"*, %"class.std::type_info"** %3, align 8
  ret %"class.std::type_info"* %168
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant14invoke_visitorINS1_7reflectELb0EEC2ERS3_(%"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::reflect"* dereferenceable(1)) unnamed_addr #4 comdat align 2 {
  %3 = alloca %"class.boost::detail::variant::invoke_visitor.11"*, align 8
  %4 = alloca %"class.boost::detail::variant::reflect"*, align 8
  store %"class.boost::detail::variant::invoke_visitor.11"* %0, %"class.boost::detail::variant::invoke_visitor.11"** %3, align 8
  store %"class.boost::detail::variant::reflect"* %1, %"class.boost::detail::variant::reflect"** %4, align 8
  %5 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %3, align 8
  %6 = getelementptr inbounds %"class.boost::detail::variant::invoke_visitor.11", %"class.boost::detail::variant::invoke_visitor.11"* %5, i32 0, i32 0
  %7 = load %"class.boost::detail::variant::reflect"*, %"class.boost::detail::variant::reflect"** %4, align 8
  store %"class.boost::detail::variant::reflect"* %7, %"class.boost::detail::variant::reflect"** %6, align 8
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKviNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PT1_T2_i(i32, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8), i8*, i32*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::invoke_visitor.11"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca i32*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"class.boost::detail::variant::invoke_visitor.11"* %1, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  store i8* %2, i8** %9, align 8
  store i32* %3, i32** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load i32*, i32** %10, align 8
  %17 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_7reflectELb0EEEPKviEENT_11result_typeEiRS8_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8) %14, i8* %15, i32* %16)
  ret %"class.std::type_info"* %17
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKvjNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PT1_T2_i(i32, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8), i8*, i32*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::invoke_visitor.11"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca i32*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"class.boost::detail::variant::invoke_visitor.11"* %1, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  store i8* %2, i8** %9, align 8
  store i32* %3, i32** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load i32*, i32** %10, align 8
  %17 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_7reflectELb0EEEPKvjEENT_11result_typeEiRS8_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8) %14, i8* %15, i32* %16)
  ret %"class.std::type_info"* %17
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKvcNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PT1_T2_i(i32, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8), i8*, i8*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::invoke_visitor.11"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca i8*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"class.boost::detail::variant::invoke_visitor.11"* %1, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  store i8* %2, i8** %9, align 8
  store i8* %3, i8** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load i8*, i8** %10, align 8
  %17 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_7reflectELb0EEEPKvcEENT_11result_typeEiRS8_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8) %14, i8* %15, i8* %16)
  ret %"class.std::type_info"* %17
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKvdNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PT1_T2_i(i32, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8), i8*, double*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::invoke_visitor.11"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca double*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"class.boost::detail::variant::invoke_visitor.11"* %1, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  store i8* %2, i8** %9, align 8
  store double* %3, double** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load double*, double** %10, align 8
  %17 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_7reflectELb0EEEPKvdEENT_11result_typeEiRS8_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8) %14, i8* %15, double* %16)
  ret %"class.std::type_info"* %17
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKvfNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PT1_T2_i(i32, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8), i8*, float*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::invoke_visitor.11"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca float*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"class.boost::detail::variant::invoke_visitor.11"* %1, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  store i8* %2, i8** %9, align 8
  store float* %3, float** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load float*, float** %10, align 8
  %17 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_7reflectELb0EEEPKvfEENT_11result_typeEiRS8_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8) %14, i8* %15, float* %16)
  ret %"class.std::type_info"* %17
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_7reflectELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8), i8*, %"struct.boost::detail::variant::apply_visitor_unrolled"*, i64) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::invoke_visitor.11"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca %"struct.boost::detail::variant::apply_visitor_unrolled"*, align 8
  %11 = alloca i64, align 8
  store i32 %0, i32* %7, align 4
  store %"class.boost::detail::variant::invoke_visitor.11"* %1, %"class.boost::detail::variant::invoke_visitor.11"** %8, align 8
  store i8* %2, i8** %9, align 8
  store %"struct.boost::detail::variant::apply_visitor_unrolled"* %3, %"struct.boost::detail::variant::apply_visitor_unrolled"** %10, align 8
  store i64 %4, i64* %11, align 8
  %12 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant13forced_returnIRKSt9type_infoEET_v() #17
  unreachable
                                                  ; No predecessors!
  ret %"class.std::type_info"* undef
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant15visitation_implIN4mpl_4int_ILi20EEENS1_20visitation_impl_stepINS_3mpl6l_iterINS7_5l_endEEESA_EENS1_14invoke_visitorINS1_7reflectELb0EEEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT1_11result_typeEiiRSK_T2_NS3_5bool_ILb1EEET3_PT_PT0_(i32, i32, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8), i8*, %"struct.mpl_::int_.8"*, %"struct.boost::detail::variant::visitation_impl_step.9"*) #4 comdat {
  %7 = alloca %"struct.mpl_::bool_.7", align 1
  %8 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca %"class.boost::detail::variant::invoke_visitor.11"*, align 8
  %12 = alloca i8*, align 8
  %13 = alloca %"struct.mpl_::int_.8"*, align 8
  %14 = alloca %"struct.boost::detail::variant::visitation_impl_step.9"*, align 8
  store i32 %0, i32* %9, align 4
  store i32 %1, i32* %10, align 4
  store %"class.boost::detail::variant::invoke_visitor.11"* %2, %"class.boost::detail::variant::invoke_visitor.11"** %11, align 8
  store i8* %3, i8** %12, align 8
  store %"struct.mpl_::int_.8"* %4, %"struct.mpl_::int_.8"** %13, align 8
  store %"struct.boost::detail::variant::visitation_impl_step.9"* %5, %"struct.boost::detail::variant::visitation_impl_step.9"** %14, align 8
  %15 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant13forced_returnIRKSt9type_infoEET_v() #17
  unreachable
                                                  ; No predecessors!
  ret %"class.std::type_info"* undef
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_7reflectELb0EEEPKviEENT_11result_typeEiRS8_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8), i8*, i32*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"class.boost::detail::variant::invoke_visitor.11"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca i32*, align 8
  store i32 %0, i32* %6, align 4
  store %"class.boost::detail::variant::invoke_visitor.11"* %1, %"class.boost::detail::variant::invoke_visitor.11"** %7, align 8
  store i8* %2, i8** %8, align 8
  store i32* %3, i32** %9, align 8
  %10 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(4) i32* @_ZN5boost6detail7variant12cast_storageIiEERKT_PKv(i8* %11)
  %13 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant14invoke_visitorINS1_7reflectELb0EE14internal_visitIRKiEENS_12disable_if_cIXaaLb0Esr7is_sameIT_S9_EE5valueERKSt9type_infoE4typeEOS9_i(%"class.boost::detail::variant::invoke_visitor.11"* %10, i32* dereferenceable(4) %12, i32 1)
  ret %"class.std::type_info"* %13
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant14invoke_visitorINS1_7reflectELb0EE14internal_visitIRKiEENS_12disable_if_cIXaaLb0Esr7is_sameIT_S9_EE5valueERKSt9type_infoE4typeEOS9_i(%"class.boost::detail::variant::invoke_visitor.11"*, i32* dereferenceable(4), i32) #4 comdat align 2 {
  %4 = alloca %"class.boost::detail::variant::invoke_visitor.11"*, align 8
  %5 = alloca i32*, align 8
  %6 = alloca i32, align 4
  store %"class.boost::detail::variant::invoke_visitor.11"* %0, %"class.boost::detail::variant::invoke_visitor.11"** %4, align 8
  store i32* %1, i32** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %4, align 8
  %8 = getelementptr inbounds %"class.boost::detail::variant::invoke_visitor.11", %"class.boost::detail::variant::invoke_visitor.11"* %7, i32 0, i32 0
  %9 = load %"class.boost::detail::variant::reflect"*, %"class.boost::detail::variant::reflect"** %8, align 8
  %10 = load i32*, i32** %5, align 8
  %11 = call dereferenceable(16) %"class.std::type_info"* @_ZNK5boost6detail7variant7reflectclIiEERKSt9type_infoRKT_(%"class.boost::detail::variant::reflect"* %9, i32* dereferenceable(4) %10) #3
  ret %"class.std::type_info"* %11
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(16) %"class.std::type_info"* @_ZNK5boost6detail7variant7reflectclIiEERKSt9type_infoRKT_(%"class.boost::detail::variant::reflect"*, i32* dereferenceable(4)) #4 comdat align 2 {
  %3 = alloca %"class.boost::detail::variant::reflect"*, align 8
  %4 = alloca i32*, align 8
  %5 = alloca %"class.boost::typeindex::stl_type_index", align 8
  store %"class.boost::detail::variant::reflect"* %0, %"class.boost::detail::variant::reflect"** %3, align 8
  store i32* %1, i32** %4, align 8
  %6 = load %"class.boost::detail::variant::reflect"*, %"class.boost::detail::variant::reflect"** %3, align 8
  %7 = call %"class.std::type_info"* @_ZN5boost9typeindex7type_idIiEENS0_14stl_type_indexEv() #3
  %8 = getelementptr inbounds %"class.boost::typeindex::stl_type_index", %"class.boost::typeindex::stl_type_index"* %5, i32 0, i32 0
  store %"class.std::type_info"* %7, %"class.std::type_info"** %8, align 8
  %9 = call dereferenceable(16) %"class.std::type_info"* @_ZNK5boost9typeindex14stl_type_index9type_infoEv(%"class.boost::typeindex::stl_type_index"* %5) #3
  ret %"class.std::type_info"* %9
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"class.std::type_info"* @_ZN5boost9typeindex7type_idIiEENS0_14stl_type_indexEv() #4 comdat {
  %1 = alloca %"class.boost::typeindex::stl_type_index", align 8
  %2 = call %"class.std::type_info"* @_ZN5boost9typeindex14stl_type_index7type_idIiEES1_v() #3
  %3 = getelementptr inbounds %"class.boost::typeindex::stl_type_index", %"class.boost::typeindex::stl_type_index"* %1, i32 0, i32 0
  store %"class.std::type_info"* %2, %"class.std::type_info"** %3, align 8
  %4 = getelementptr inbounds %"class.boost::typeindex::stl_type_index", %"class.boost::typeindex::stl_type_index"* %1, i32 0, i32 0
  %5 = load %"class.std::type_info"*, %"class.std::type_info"** %4, align 8
  ret %"class.std::type_info"* %5
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(16) %"class.std::type_info"* @_ZNK5boost9typeindex14stl_type_index9type_infoEv(%"class.boost::typeindex::stl_type_index"*) #4 comdat align 2 {
  %2 = alloca %"class.boost::typeindex::stl_type_index"*, align 8
  store %"class.boost::typeindex::stl_type_index"* %0, %"class.boost::typeindex::stl_type_index"** %2, align 8
  %3 = load %"class.boost::typeindex::stl_type_index"*, %"class.boost::typeindex::stl_type_index"** %2, align 8
  %4 = getelementptr inbounds %"class.boost::typeindex::stl_type_index", %"class.boost::typeindex::stl_type_index"* %3, i32 0, i32 0
  %5 = load %"class.std::type_info"*, %"class.std::type_info"** %4, align 8
  ret %"class.std::type_info"* %5
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"class.std::type_info"* @_ZN5boost9typeindex14stl_type_index7type_idIiEES1_v() #4 comdat align 2 {
  %1 = alloca %"class.boost::typeindex::stl_type_index", align 8
  call void @_ZN5boost9typeindex14stl_type_indexC2ERKSt9type_info(%"class.boost::typeindex::stl_type_index"* %1, %"class.std::type_info"* dereferenceable(16) bitcast (i8** @_ZTIi to %"class.std::type_info"*)) #3
  %2 = getelementptr inbounds %"class.boost::typeindex::stl_type_index", %"class.boost::typeindex::stl_type_index"* %1, i32 0, i32 0
  %3 = load %"class.std::type_info"*, %"class.std::type_info"** %2, align 8
  ret %"class.std::type_info"* %3
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost9typeindex14stl_type_indexC2ERKSt9type_info(%"class.boost::typeindex::stl_type_index"*, %"class.std::type_info"* dereferenceable(16)) unnamed_addr #4 comdat align 2 {
  %3 = alloca %"class.boost::typeindex::stl_type_index"*, align 8
  %4 = alloca %"class.std::type_info"*, align 8
  store %"class.boost::typeindex::stl_type_index"* %0, %"class.boost::typeindex::stl_type_index"** %3, align 8
  store %"class.std::type_info"* %1, %"class.std::type_info"** %4, align 8
  %5 = load %"class.boost::typeindex::stl_type_index"*, %"class.boost::typeindex::stl_type_index"** %3, align 8
  %6 = bitcast %"class.boost::typeindex::stl_type_index"* %5 to %"class.boost::typeindex::type_index_facade"*
  %7 = getelementptr inbounds %"class.boost::typeindex::stl_type_index", %"class.boost::typeindex::stl_type_index"* %5, i32 0, i32 0
  %8 = load %"class.std::type_info"*, %"class.std::type_info"** %4, align 8
  store %"class.std::type_info"* %8, %"class.std::type_info"** %7, align 8
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_7reflectELb0EEEPKvjEENT_11result_typeEiRS8_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8), i8*, i32*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"class.boost::detail::variant::invoke_visitor.11"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca i32*, align 8
  store i32 %0, i32* %6, align 4
  store %"class.boost::detail::variant::invoke_visitor.11"* %1, %"class.boost::detail::variant::invoke_visitor.11"** %7, align 8
  store i8* %2, i8** %8, align 8
  store i32* %3, i32** %9, align 8
  %10 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(4) i32* @_ZN5boost6detail7variant12cast_storageIjEERKT_PKv(i8* %11)
  %13 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant14invoke_visitorINS1_7reflectELb0EE14internal_visitIRKjEENS_12disable_if_cIXaaLb0Esr7is_sameIT_S9_EE5valueERKSt9type_infoE4typeEOS9_i(%"class.boost::detail::variant::invoke_visitor.11"* %10, i32* dereferenceable(4) %12, i32 1)
  ret %"class.std::type_info"* %13
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant14invoke_visitorINS1_7reflectELb0EE14internal_visitIRKjEENS_12disable_if_cIXaaLb0Esr7is_sameIT_S9_EE5valueERKSt9type_infoE4typeEOS9_i(%"class.boost::detail::variant::invoke_visitor.11"*, i32* dereferenceable(4), i32) #4 comdat align 2 {
  %4 = alloca %"class.boost::detail::variant::invoke_visitor.11"*, align 8
  %5 = alloca i32*, align 8
  %6 = alloca i32, align 4
  store %"class.boost::detail::variant::invoke_visitor.11"* %0, %"class.boost::detail::variant::invoke_visitor.11"** %4, align 8
  store i32* %1, i32** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %4, align 8
  %8 = getelementptr inbounds %"class.boost::detail::variant::invoke_visitor.11", %"class.boost::detail::variant::invoke_visitor.11"* %7, i32 0, i32 0
  %9 = load %"class.boost::detail::variant::reflect"*, %"class.boost::detail::variant::reflect"** %8, align 8
  %10 = load i32*, i32** %5, align 8
  %11 = call dereferenceable(16) %"class.std::type_info"* @_ZNK5boost6detail7variant7reflectclIjEERKSt9type_infoRKT_(%"class.boost::detail::variant::reflect"* %9, i32* dereferenceable(4) %10) #3
  ret %"class.std::type_info"* %11
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(16) %"class.std::type_info"* @_ZNK5boost6detail7variant7reflectclIjEERKSt9type_infoRKT_(%"class.boost::detail::variant::reflect"*, i32* dereferenceable(4)) #4 comdat align 2 {
  %3 = alloca %"class.boost::detail::variant::reflect"*, align 8
  %4 = alloca i32*, align 8
  %5 = alloca %"class.boost::typeindex::stl_type_index", align 8
  store %"class.boost::detail::variant::reflect"* %0, %"class.boost::detail::variant::reflect"** %3, align 8
  store i32* %1, i32** %4, align 8
  %6 = load %"class.boost::detail::variant::reflect"*, %"class.boost::detail::variant::reflect"** %3, align 8
  %7 = call %"class.std::type_info"* @_ZN5boost9typeindex7type_idIjEENS0_14stl_type_indexEv() #3
  %8 = getelementptr inbounds %"class.boost::typeindex::stl_type_index", %"class.boost::typeindex::stl_type_index"* %5, i32 0, i32 0
  store %"class.std::type_info"* %7, %"class.std::type_info"** %8, align 8
  %9 = call dereferenceable(16) %"class.std::type_info"* @_ZNK5boost9typeindex14stl_type_index9type_infoEv(%"class.boost::typeindex::stl_type_index"* %5) #3
  ret %"class.std::type_info"* %9
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"class.std::type_info"* @_ZN5boost9typeindex7type_idIjEENS0_14stl_type_indexEv() #4 comdat {
  %1 = alloca %"class.boost::typeindex::stl_type_index", align 8
  %2 = call %"class.std::type_info"* @_ZN5boost9typeindex14stl_type_index7type_idIjEES1_v() #3
  %3 = getelementptr inbounds %"class.boost::typeindex::stl_type_index", %"class.boost::typeindex::stl_type_index"* %1, i32 0, i32 0
  store %"class.std::type_info"* %2, %"class.std::type_info"** %3, align 8
  %4 = getelementptr inbounds %"class.boost::typeindex::stl_type_index", %"class.boost::typeindex::stl_type_index"* %1, i32 0, i32 0
  %5 = load %"class.std::type_info"*, %"class.std::type_info"** %4, align 8
  ret %"class.std::type_info"* %5
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"class.std::type_info"* @_ZN5boost9typeindex14stl_type_index7type_idIjEES1_v() #4 comdat align 2 {
  %1 = alloca %"class.boost::typeindex::stl_type_index", align 8
  call void @_ZN5boost9typeindex14stl_type_indexC2ERKSt9type_info(%"class.boost::typeindex::stl_type_index"* %1, %"class.std::type_info"* dereferenceable(16) bitcast (i8** @_ZTIj to %"class.std::type_info"*)) #3
  %2 = getelementptr inbounds %"class.boost::typeindex::stl_type_index", %"class.boost::typeindex::stl_type_index"* %1, i32 0, i32 0
  %3 = load %"class.std::type_info"*, %"class.std::type_info"** %2, align 8
  ret %"class.std::type_info"* %3
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_7reflectELb0EEEPKvcEENT_11result_typeEiRS8_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8), i8*, i8*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"class.boost::detail::variant::invoke_visitor.11"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca i8*, align 8
  store i32 %0, i32* %6, align 4
  store %"class.boost::detail::variant::invoke_visitor.11"* %1, %"class.boost::detail::variant::invoke_visitor.11"** %7, align 8
  store i8* %2, i8** %8, align 8
  store i8* %3, i8** %9, align 8
  %10 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(1) i8* @_ZN5boost6detail7variant12cast_storageIcEERKT_PKv(i8* %11)
  %13 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant14invoke_visitorINS1_7reflectELb0EE14internal_visitIRKcEENS_12disable_if_cIXaaLb0Esr7is_sameIT_S9_EE5valueERKSt9type_infoE4typeEOS9_i(%"class.boost::detail::variant::invoke_visitor.11"* %10, i8* dereferenceable(1) %12, i32 1)
  ret %"class.std::type_info"* %13
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant14invoke_visitorINS1_7reflectELb0EE14internal_visitIRKcEENS_12disable_if_cIXaaLb0Esr7is_sameIT_S9_EE5valueERKSt9type_infoE4typeEOS9_i(%"class.boost::detail::variant::invoke_visitor.11"*, i8* dereferenceable(1), i32) #4 comdat align 2 {
  %4 = alloca %"class.boost::detail::variant::invoke_visitor.11"*, align 8
  %5 = alloca i8*, align 8
  %6 = alloca i32, align 4
  store %"class.boost::detail::variant::invoke_visitor.11"* %0, %"class.boost::detail::variant::invoke_visitor.11"** %4, align 8
  store i8* %1, i8** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %4, align 8
  %8 = getelementptr inbounds %"class.boost::detail::variant::invoke_visitor.11", %"class.boost::detail::variant::invoke_visitor.11"* %7, i32 0, i32 0
  %9 = load %"class.boost::detail::variant::reflect"*, %"class.boost::detail::variant::reflect"** %8, align 8
  %10 = load i8*, i8** %5, align 8
  %11 = call dereferenceable(16) %"class.std::type_info"* @_ZNK5boost6detail7variant7reflectclIcEERKSt9type_infoRKT_(%"class.boost::detail::variant::reflect"* %9, i8* dereferenceable(1) %10) #3
  ret %"class.std::type_info"* %11
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(16) %"class.std::type_info"* @_ZNK5boost6detail7variant7reflectclIcEERKSt9type_infoRKT_(%"class.boost::detail::variant::reflect"*, i8* dereferenceable(1)) #4 comdat align 2 {
  %3 = alloca %"class.boost::detail::variant::reflect"*, align 8
  %4 = alloca i8*, align 8
  %5 = alloca %"class.boost::typeindex::stl_type_index", align 8
  store %"class.boost::detail::variant::reflect"* %0, %"class.boost::detail::variant::reflect"** %3, align 8
  store i8* %1, i8** %4, align 8
  %6 = load %"class.boost::detail::variant::reflect"*, %"class.boost::detail::variant::reflect"** %3, align 8
  %7 = call %"class.std::type_info"* @_ZN5boost9typeindex7type_idIcEENS0_14stl_type_indexEv() #3
  %8 = getelementptr inbounds %"class.boost::typeindex::stl_type_index", %"class.boost::typeindex::stl_type_index"* %5, i32 0, i32 0
  store %"class.std::type_info"* %7, %"class.std::type_info"** %8, align 8
  %9 = call dereferenceable(16) %"class.std::type_info"* @_ZNK5boost9typeindex14stl_type_index9type_infoEv(%"class.boost::typeindex::stl_type_index"* %5) #3
  ret %"class.std::type_info"* %9
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"class.std::type_info"* @_ZN5boost9typeindex7type_idIcEENS0_14stl_type_indexEv() #4 comdat {
  %1 = alloca %"class.boost::typeindex::stl_type_index", align 8
  %2 = call %"class.std::type_info"* @_ZN5boost9typeindex14stl_type_index7type_idIcEES1_v() #3
  %3 = getelementptr inbounds %"class.boost::typeindex::stl_type_index", %"class.boost::typeindex::stl_type_index"* %1, i32 0, i32 0
  store %"class.std::type_info"* %2, %"class.std::type_info"** %3, align 8
  %4 = getelementptr inbounds %"class.boost::typeindex::stl_type_index", %"class.boost::typeindex::stl_type_index"* %1, i32 0, i32 0
  %5 = load %"class.std::type_info"*, %"class.std::type_info"** %4, align 8
  ret %"class.std::type_info"* %5
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"class.std::type_info"* @_ZN5boost9typeindex14stl_type_index7type_idIcEES1_v() #4 comdat align 2 {
  %1 = alloca %"class.boost::typeindex::stl_type_index", align 8
  call void @_ZN5boost9typeindex14stl_type_indexC2ERKSt9type_info(%"class.boost::typeindex::stl_type_index"* %1, %"class.std::type_info"* dereferenceable(16) bitcast (i8** @_ZTIc to %"class.std::type_info"*)) #3
  %2 = getelementptr inbounds %"class.boost::typeindex::stl_type_index", %"class.boost::typeindex::stl_type_index"* %1, i32 0, i32 0
  %3 = load %"class.std::type_info"*, %"class.std::type_info"** %2, align 8
  ret %"class.std::type_info"* %3
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_7reflectELb0EEEPKvdEENT_11result_typeEiRS8_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8), i8*, double*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"class.boost::detail::variant::invoke_visitor.11"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca double*, align 8
  store i32 %0, i32* %6, align 4
  store %"class.boost::detail::variant::invoke_visitor.11"* %1, %"class.boost::detail::variant::invoke_visitor.11"** %7, align 8
  store i8* %2, i8** %8, align 8
  store double* %3, double** %9, align 8
  %10 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(8) double* @_ZN5boost6detail7variant12cast_storageIdEERKT_PKv(i8* %11)
  %13 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant14invoke_visitorINS1_7reflectELb0EE14internal_visitIRKdEENS_12disable_if_cIXaaLb0Esr7is_sameIT_S9_EE5valueERKSt9type_infoE4typeEOS9_i(%"class.boost::detail::variant::invoke_visitor.11"* %10, double* dereferenceable(8) %12, i32 1)
  ret %"class.std::type_info"* %13
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant14invoke_visitorINS1_7reflectELb0EE14internal_visitIRKdEENS_12disable_if_cIXaaLb0Esr7is_sameIT_S9_EE5valueERKSt9type_infoE4typeEOS9_i(%"class.boost::detail::variant::invoke_visitor.11"*, double* dereferenceable(8), i32) #4 comdat align 2 {
  %4 = alloca %"class.boost::detail::variant::invoke_visitor.11"*, align 8
  %5 = alloca double*, align 8
  %6 = alloca i32, align 4
  store %"class.boost::detail::variant::invoke_visitor.11"* %0, %"class.boost::detail::variant::invoke_visitor.11"** %4, align 8
  store double* %1, double** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %4, align 8
  %8 = getelementptr inbounds %"class.boost::detail::variant::invoke_visitor.11", %"class.boost::detail::variant::invoke_visitor.11"* %7, i32 0, i32 0
  %9 = load %"class.boost::detail::variant::reflect"*, %"class.boost::detail::variant::reflect"** %8, align 8
  %10 = load double*, double** %5, align 8
  %11 = call dereferenceable(16) %"class.std::type_info"* @_ZNK5boost6detail7variant7reflectclIdEERKSt9type_infoRKT_(%"class.boost::detail::variant::reflect"* %9, double* dereferenceable(8) %10) #3
  ret %"class.std::type_info"* %11
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(16) %"class.std::type_info"* @_ZNK5boost6detail7variant7reflectclIdEERKSt9type_infoRKT_(%"class.boost::detail::variant::reflect"*, double* dereferenceable(8)) #4 comdat align 2 {
  %3 = alloca %"class.boost::detail::variant::reflect"*, align 8
  %4 = alloca double*, align 8
  %5 = alloca %"class.boost::typeindex::stl_type_index", align 8
  store %"class.boost::detail::variant::reflect"* %0, %"class.boost::detail::variant::reflect"** %3, align 8
  store double* %1, double** %4, align 8
  %6 = load %"class.boost::detail::variant::reflect"*, %"class.boost::detail::variant::reflect"** %3, align 8
  %7 = call %"class.std::type_info"* @_ZN5boost9typeindex7type_idIdEENS0_14stl_type_indexEv() #3
  %8 = getelementptr inbounds %"class.boost::typeindex::stl_type_index", %"class.boost::typeindex::stl_type_index"* %5, i32 0, i32 0
  store %"class.std::type_info"* %7, %"class.std::type_info"** %8, align 8
  %9 = call dereferenceable(16) %"class.std::type_info"* @_ZNK5boost9typeindex14stl_type_index9type_infoEv(%"class.boost::typeindex::stl_type_index"* %5) #3
  ret %"class.std::type_info"* %9
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"class.std::type_info"* @_ZN5boost9typeindex7type_idIdEENS0_14stl_type_indexEv() #4 comdat {
  %1 = alloca %"class.boost::typeindex::stl_type_index", align 8
  %2 = call %"class.std::type_info"* @_ZN5boost9typeindex14stl_type_index7type_idIdEES1_v() #3
  %3 = getelementptr inbounds %"class.boost::typeindex::stl_type_index", %"class.boost::typeindex::stl_type_index"* %1, i32 0, i32 0
  store %"class.std::type_info"* %2, %"class.std::type_info"** %3, align 8
  %4 = getelementptr inbounds %"class.boost::typeindex::stl_type_index", %"class.boost::typeindex::stl_type_index"* %1, i32 0, i32 0
  %5 = load %"class.std::type_info"*, %"class.std::type_info"** %4, align 8
  ret %"class.std::type_info"* %5
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"class.std::type_info"* @_ZN5boost9typeindex14stl_type_index7type_idIdEES1_v() #4 comdat align 2 {
  %1 = alloca %"class.boost::typeindex::stl_type_index", align 8
  call void @_ZN5boost9typeindex14stl_type_indexC2ERKSt9type_info(%"class.boost::typeindex::stl_type_index"* %1, %"class.std::type_info"* dereferenceable(16) bitcast (i8** @_ZTId to %"class.std::type_info"*)) #3
  %2 = getelementptr inbounds %"class.boost::typeindex::stl_type_index", %"class.boost::typeindex::stl_type_index"* %1, i32 0, i32 0
  %3 = load %"class.std::type_info"*, %"class.std::type_info"** %2, align 8
  ret %"class.std::type_info"* %3
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_7reflectELb0EEEPKvfEENT_11result_typeEiRS8_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"class.boost::detail::variant::invoke_visitor.11"* dereferenceable(8), i8*, float*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"class.boost::detail::variant::invoke_visitor.11"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca float*, align 8
  store i32 %0, i32* %6, align 4
  store %"class.boost::detail::variant::invoke_visitor.11"* %1, %"class.boost::detail::variant::invoke_visitor.11"** %7, align 8
  store i8* %2, i8** %8, align 8
  store float* %3, float** %9, align 8
  %10 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(4) float* @_ZN5boost6detail7variant12cast_storageIfEERKT_PKv(i8* %11)
  %13 = call dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant14invoke_visitorINS1_7reflectELb0EE14internal_visitIRKfEENS_12disable_if_cIXaaLb0Esr7is_sameIT_S9_EE5valueERKSt9type_infoE4typeEOS9_i(%"class.boost::detail::variant::invoke_visitor.11"* %10, float* dereferenceable(4) %12, i32 1)
  ret %"class.std::type_info"* %13
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant14invoke_visitorINS1_7reflectELb0EE14internal_visitIRKfEENS_12disable_if_cIXaaLb0Esr7is_sameIT_S9_EE5valueERKSt9type_infoE4typeEOS9_i(%"class.boost::detail::variant::invoke_visitor.11"*, float* dereferenceable(4), i32) #4 comdat align 2 {
  %4 = alloca %"class.boost::detail::variant::invoke_visitor.11"*, align 8
  %5 = alloca float*, align 8
  %6 = alloca i32, align 4
  store %"class.boost::detail::variant::invoke_visitor.11"* %0, %"class.boost::detail::variant::invoke_visitor.11"** %4, align 8
  store float* %1, float** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"class.boost::detail::variant::invoke_visitor.11"*, %"class.boost::detail::variant::invoke_visitor.11"** %4, align 8
  %8 = getelementptr inbounds %"class.boost::detail::variant::invoke_visitor.11", %"class.boost::detail::variant::invoke_visitor.11"* %7, i32 0, i32 0
  %9 = load %"class.boost::detail::variant::reflect"*, %"class.boost::detail::variant::reflect"** %8, align 8
  %10 = load float*, float** %5, align 8
  %11 = call dereferenceable(16) %"class.std::type_info"* @_ZNK5boost6detail7variant7reflectclIfEERKSt9type_infoRKT_(%"class.boost::detail::variant::reflect"* %9, float* dereferenceable(4) %10) #3
  ret %"class.std::type_info"* %11
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(16) %"class.std::type_info"* @_ZNK5boost6detail7variant7reflectclIfEERKSt9type_infoRKT_(%"class.boost::detail::variant::reflect"*, float* dereferenceable(4)) #4 comdat align 2 {
  %3 = alloca %"class.boost::detail::variant::reflect"*, align 8
  %4 = alloca float*, align 8
  %5 = alloca %"class.boost::typeindex::stl_type_index", align 8
  store %"class.boost::detail::variant::reflect"* %0, %"class.boost::detail::variant::reflect"** %3, align 8
  store float* %1, float** %4, align 8
  %6 = load %"class.boost::detail::variant::reflect"*, %"class.boost::detail::variant::reflect"** %3, align 8
  %7 = call %"class.std::type_info"* @_ZN5boost9typeindex7type_idIfEENS0_14stl_type_indexEv() #3
  %8 = getelementptr inbounds %"class.boost::typeindex::stl_type_index", %"class.boost::typeindex::stl_type_index"* %5, i32 0, i32 0
  store %"class.std::type_info"* %7, %"class.std::type_info"** %8, align 8
  %9 = call dereferenceable(16) %"class.std::type_info"* @_ZNK5boost9typeindex14stl_type_index9type_infoEv(%"class.boost::typeindex::stl_type_index"* %5) #3
  ret %"class.std::type_info"* %9
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"class.std::type_info"* @_ZN5boost9typeindex7type_idIfEENS0_14stl_type_indexEv() #4 comdat {
  %1 = alloca %"class.boost::typeindex::stl_type_index", align 8
  %2 = call %"class.std::type_info"* @_ZN5boost9typeindex14stl_type_index7type_idIfEES1_v() #3
  %3 = getelementptr inbounds %"class.boost::typeindex::stl_type_index", %"class.boost::typeindex::stl_type_index"* %1, i32 0, i32 0
  store %"class.std::type_info"* %2, %"class.std::type_info"** %3, align 8
  %4 = getelementptr inbounds %"class.boost::typeindex::stl_type_index", %"class.boost::typeindex::stl_type_index"* %1, i32 0, i32 0
  %5 = load %"class.std::type_info"*, %"class.std::type_info"** %4, align 8
  ret %"class.std::type_info"* %5
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"class.std::type_info"* @_ZN5boost9typeindex14stl_type_index7type_idIfEES1_v() #4 comdat align 2 {
  %1 = alloca %"class.boost::typeindex::stl_type_index", align 8
  call void @_ZN5boost9typeindex14stl_type_indexC2ERKSt9type_info(%"class.boost::typeindex::stl_type_index"* %1, %"class.std::type_info"* dereferenceable(16) bitcast (i8** @_ZTIf to %"class.std::type_info"*)) #3
  %2 = getelementptr inbounds %"class.boost::typeindex::stl_type_index", %"class.boost::typeindex::stl_type_index"* %1, i32 0, i32 0
  %3 = load %"class.std::type_info"*, %"class.std::type_info"** %2, align 8
  ret %"class.std::type_info"* %3
}

; Function Attrs: noinline noreturn nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(16) %"class.std::type_info"* @_ZN5boost6detail7variant13forced_returnIRKSt9type_infoEET_v() #8 comdat {
  %1 = alloca %"class.std::type_info"*, align 8
  %2 = alloca %"class.std::type_info"* ()*, align 8
  call void @__assert_fail(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.str.2, i32 0, i32 0), i8* getelementptr inbounds ([52 x i8], [52 x i8]* @.str.3, i32 0, i32 0), i32 38, i8* getelementptr inbounds ([71 x i8], [71 x i8]* @__PRETTY_FUNCTION__._ZN5boost6detail7variant13forced_returnIRKSt9type_infoEET_v, i32 0, i32 0)) #16
  unreachable
                                                  ; No predecessors!
  unreachable
}

; Function Attrs: nounwind
declare dso_local i32 @strcmp(i8*, i8*) #2

; Function Attrs: argmemonly nounwind
declare void @llvm.memcpy.p0i8.p0i8.i64(i8* nocapture writeonly, i8* nocapture readonly, i64, i1) #13

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost7variantIiJjcdfEEC2ERKS1_(%"class.boost::variant"*, %"class.boost::variant"* dereferenceable(16)) unnamed_addr #5 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca %"class.boost::detail::variant::copy_into"*, align 8
  %6 = alloca i8*, align 8
  %7 = alloca %"struct.mpl_::int_"*, align 8
  %8 = alloca %"struct.boost::detail::variant::visitation_impl_step"*, align 8
  %9 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %10 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %11 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %12 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %13 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %14 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %15 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %16 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %17 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %18 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %19 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %20 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %21 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %22 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %23 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %24 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %25 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %26 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %27 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %28 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %29 = alloca %"struct.mpl_::bool_.7", align 1
  %30 = alloca %"struct.boost::integral_constant", align 1
  %31 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %32 = alloca i32, align 4
  %33 = alloca i32, align 4
  %34 = alloca %"class.boost::detail::variant::copy_into"*, align 8
  %35 = alloca i8*, align 8
  %36 = alloca %"struct.mpl_::bool_", align 1
  %37 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %38 = alloca %"class.boost::variant"*, align 8
  %39 = alloca %"class.boost::detail::variant::copy_into"*, align 8
  %40 = alloca %"class.boost::variant"*, align 8
  %41 = alloca %"class.boost::variant"*, align 8
  %42 = alloca %"class.boost::detail::variant::copy_into", align 8
  %43 = alloca i8*
  %44 = alloca i32
  store %"class.boost::variant"* %0, %"class.boost::variant"** %40, align 8
  store %"class.boost::variant"* %1, %"class.boost::variant"** %41, align 8
  %45 = load %"class.boost::variant"*, %"class.boost::variant"** %40, align 8
  %46 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %45, i32 0, i32 2
  call void @_ZN5boost15aligned_storageILm8ELm8EEC2Ev(%"class.boost::aligned_storage"* %46)
  %47 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %45, i32 0, i32 2
  %48 = invoke i8* @_ZN5boost15aligned_storageILm8ELm8EE7addressEv(%"class.boost::aligned_storage"* %47)
          to label %49 unwind label %158

; <label>:49:                                     ; preds = %2
  call void @_ZN5boost6detail7variant9copy_intoC2EPv(%"class.boost::detail::variant::copy_into"* %42, i8* %48) #3
  %50 = load %"class.boost::variant"*, %"class.boost::variant"** %41, align 8
  store %"class.boost::variant"* %50, %"class.boost::variant"** %38, align 8
  store %"class.boost::detail::variant::copy_into"* %42, %"class.boost::detail::variant::copy_into"** %39, align 8
  %51 = load %"class.boost::variant"*, %"class.boost::variant"** %38, align 8
  %52 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %51, i32 0, i32 0
  %53 = load i32, i32* %52, align 8
  %54 = call i32 @_ZNK5boost7variantIiJjcdfEE5whichEv(%"class.boost::variant"* %51) #3
  %55 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %39, align 8
  %56 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %51, i32 0, i32 2
  %57 = call i8* @_ZNK5boost15aligned_storageILm8ELm8EE7addressEv(%"class.boost::aligned_storage"* %56)
  store i32 %53, i32* %32, align 4
  store i32 %54, i32* %33, align 4
  store %"class.boost::detail::variant::copy_into"* %55, %"class.boost::detail::variant::copy_into"** %34, align 8
  store i8* %57, i8** %35, align 8
  %58 = load i32, i32* %32, align 4
  %59 = load i32, i32* %33, align 4
  %60 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %34, align 8
  %61 = load i8*, i8** %35, align 8
  store i32 %58, i32* %3, align 4
  store i32 %59, i32* %4, align 4
  store %"class.boost::detail::variant::copy_into"* %60, %"class.boost::detail::variant::copy_into"** %5, align 8
  store i8* %61, i8** %6, align 8
  store %"struct.mpl_::int_"* null, %"struct.mpl_::int_"** %7, align 8
  store %"struct.boost::detail::variant::visitation_impl_step"* null, %"struct.boost::detail::variant::visitation_impl_step"** %8, align 8
  %62 = load i32, i32* %4, align 4
  switch i32 %62, label %148 [
    i32 0, label %63
    i32 1, label %68
    i32 2, label %73
    i32 3, label %78
    i32 4, label %83
    i32 5, label %88
    i32 6, label %92
    i32 7, label %96
    i32 8, label %100
    i32 9, label %104
    i32 10, label %108
    i32 11, label %112
    i32 12, label %116
    i32 13, label %120
    i32 14, label %124
    i32 15, label %128
    i32 16, label %132
    i32 17, label %136
    i32 18, label %140
    i32 19, label %144
  ]

; <label>:63:                                     ; preds = %49
  %64 = load i32, i32* %3, align 4
  %65 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %5, align 8
  %66 = load i8*, i8** %6, align 8
  invoke void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKviNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PT1_T2_i(i32 %64, %"class.boost::detail::variant::copy_into"* dereferenceable(8) %65, i8* %66, i32* null, i32 1)
          to label %67 unwind label %158

; <label>:67:                                     ; preds = %63
  br label %154

; <label>:68:                                     ; preds = %49
  %69 = load i32, i32* %3, align 4
  %70 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %5, align 8
  %71 = load i8*, i8** %6, align 8
  invoke void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKvjNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PT1_T2_i(i32 %69, %"class.boost::detail::variant::copy_into"* dereferenceable(8) %70, i8* %71, i32* null, i32 1)
          to label %72 unwind label %158

; <label>:72:                                     ; preds = %68
  br label %154

; <label>:73:                                     ; preds = %49
  %74 = load i32, i32* %3, align 4
  %75 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %5, align 8
  %76 = load i8*, i8** %6, align 8
  invoke void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKvcNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PT1_T2_i(i32 %74, %"class.boost::detail::variant::copy_into"* dereferenceable(8) %75, i8* %76, i8* null, i32 1)
          to label %77 unwind label %158

; <label>:77:                                     ; preds = %73
  br label %154

; <label>:78:                                     ; preds = %49
  %79 = load i32, i32* %3, align 4
  %80 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %5, align 8
  %81 = load i8*, i8** %6, align 8
  invoke void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKvdNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PT1_T2_i(i32 %79, %"class.boost::detail::variant::copy_into"* dereferenceable(8) %80, i8* %81, double* null, i32 1)
          to label %82 unwind label %158

; <label>:82:                                     ; preds = %78
  br label %154

; <label>:83:                                     ; preds = %49
  %84 = load i32, i32* %3, align 4
  %85 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %5, align 8
  %86 = load i8*, i8** %6, align 8
  invoke void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKvfNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PT1_T2_i(i32 %84, %"class.boost::detail::variant::copy_into"* dereferenceable(8) %85, i8* %86, float* null, i32 1)
          to label %87 unwind label %158

; <label>:87:                                     ; preds = %83
  br label %154

; <label>:88:                                     ; preds = %49
  %89 = load i32, i32* %3, align 4
  %90 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %5, align 8
  %91 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %89, %"class.boost::detail::variant::copy_into"* dereferenceable(8) %90, i8* %91, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %154

; <label>:92:                                     ; preds = %49
  %93 = load i32, i32* %3, align 4
  %94 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %5, align 8
  %95 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %93, %"class.boost::detail::variant::copy_into"* dereferenceable(8) %94, i8* %95, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %154

; <label>:96:                                     ; preds = %49
  %97 = load i32, i32* %3, align 4
  %98 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %5, align 8
  %99 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %97, %"class.boost::detail::variant::copy_into"* dereferenceable(8) %98, i8* %99, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %154

; <label>:100:                                    ; preds = %49
  %101 = load i32, i32* %3, align 4
  %102 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %5, align 8
  %103 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %101, %"class.boost::detail::variant::copy_into"* dereferenceable(8) %102, i8* %103, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %154

; <label>:104:                                    ; preds = %49
  %105 = load i32, i32* %3, align 4
  %106 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %5, align 8
  %107 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %105, %"class.boost::detail::variant::copy_into"* dereferenceable(8) %106, i8* %107, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %154

; <label>:108:                                    ; preds = %49
  %109 = load i32, i32* %3, align 4
  %110 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %5, align 8
  %111 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %109, %"class.boost::detail::variant::copy_into"* dereferenceable(8) %110, i8* %111, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %154

; <label>:112:                                    ; preds = %49
  %113 = load i32, i32* %3, align 4
  %114 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %5, align 8
  %115 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %113, %"class.boost::detail::variant::copy_into"* dereferenceable(8) %114, i8* %115, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %154

; <label>:116:                                    ; preds = %49
  %117 = load i32, i32* %3, align 4
  %118 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %5, align 8
  %119 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %117, %"class.boost::detail::variant::copy_into"* dereferenceable(8) %118, i8* %119, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %154

; <label>:120:                                    ; preds = %49
  %121 = load i32, i32* %3, align 4
  %122 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %5, align 8
  %123 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %121, %"class.boost::detail::variant::copy_into"* dereferenceable(8) %122, i8* %123, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %154

; <label>:124:                                    ; preds = %49
  %125 = load i32, i32* %3, align 4
  %126 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %5, align 8
  %127 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %125, %"class.boost::detail::variant::copy_into"* dereferenceable(8) %126, i8* %127, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %154

; <label>:128:                                    ; preds = %49
  %129 = load i32, i32* %3, align 4
  %130 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %5, align 8
  %131 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %129, %"class.boost::detail::variant::copy_into"* dereferenceable(8) %130, i8* %131, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %154

; <label>:132:                                    ; preds = %49
  %133 = load i32, i32* %3, align 4
  %134 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %5, align 8
  %135 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %133, %"class.boost::detail::variant::copy_into"* dereferenceable(8) %134, i8* %135, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %154

; <label>:136:                                    ; preds = %49
  %137 = load i32, i32* %3, align 4
  %138 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %5, align 8
  %139 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %137, %"class.boost::detail::variant::copy_into"* dereferenceable(8) %138, i8* %139, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %154

; <label>:140:                                    ; preds = %49
  %141 = load i32, i32* %3, align 4
  %142 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %5, align 8
  %143 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %141, %"class.boost::detail::variant::copy_into"* dereferenceable(8) %142, i8* %143, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %154

; <label>:144:                                    ; preds = %49
  %145 = load i32, i32* %3, align 4
  %146 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %5, align 8
  %147 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %145, %"class.boost::detail::variant::copy_into"* dereferenceable(8) %146, i8* %147, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %154

; <label>:148:                                    ; preds = %49
  %149 = load i32, i32* %3, align 4
  %150 = load i32, i32* %4, align 4
  %151 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %5, align 8
  %152 = load i8*, i8** %6, align 8
  %153 = call dereferenceable(1) %"struct.mpl_::bool_.7"* @_ZNK5boost17integral_constantIbLb1EEcvRKN4mpl_5bool_ILb1EEEEv(%"struct.boost::integral_constant"* %30)
  call void @_ZN5boost6detail7variant15visitation_implIN4mpl_4int_ILi20EEENS1_20visitation_impl_stepINS_3mpl6l_iterINS7_5l_endEEESA_EENS1_9copy_intoEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT1_11result_typeEiiRSI_T2_NS3_5bool_ILb1EEET3_PT_PT0_(i32 %149, i32 %150, %"class.boost::detail::variant::copy_into"* dereferenceable(8) %151, i8* %152, %"struct.mpl_::int_.8"* null, %"struct.boost::detail::variant::visitation_impl_step.9"* null)
  br label %154

; <label>:154:                                    ; preds = %67, %72, %77, %82, %87, %88, %92, %96, %100, %104, %108, %112, %116, %120, %124, %128, %132, %136, %140, %144, %148
  br label %155

; <label>:155:                                    ; preds = %154
  %156 = load %"class.boost::variant"*, %"class.boost::variant"** %41, align 8
  %157 = call i32 @_ZNK5boost7variantIiJjcdfEE5whichEv(%"class.boost::variant"* %156) #3
  call void @_ZN5boost7variantIiJjcdfEE14indicate_whichEi(%"class.boost::variant"* %45, i32 %157) #3
  ret void

; <label>:158:                                    ; preds = %83, %78, %73, %68, %63, %2
  %159 = landingpad { i8*, i32 }
          cleanup
  %160 = extractvalue { i8*, i32 } %159, 0
  store i8* %160, i8** %43, align 8
  %161 = extractvalue { i8*, i32 } %159, 1
  store i32 %161, i32* %44, align 4
  call void @_ZN5boost15aligned_storageILm8ELm8EED2Ev(%"class.boost::aligned_storage"* %46) #3
  br label %162

; <label>:162:                                    ; preds = %158
  %163 = load i8*, i8** %43, align 8
  %164 = load i32, i32* %44, align 4
  %165 = insertvalue { i8*, i32 } undef, i8* %163, 0
  %166 = insertvalue { i8*, i32 } %165, i32 %164, 1
  resume { i8*, i32 } %166
}

declare dso_local void @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1ERKS4_(%"class.std::__cxx11::basic_string"*, %"class.std::__cxx11::basic_string"* dereferenceable(32)) unnamed_addr #1

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant9copy_intoC2EPv(%"class.boost::detail::variant::copy_into"*, i8*) unnamed_addr #4 comdat align 2 {
  %3 = alloca %"class.boost::detail::variant::copy_into"*, align 8
  %4 = alloca i8*, align 8
  store %"class.boost::detail::variant::copy_into"* %0, %"class.boost::detail::variant::copy_into"** %3, align 8
  store i8* %1, i8** %4, align 8
  %5 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %3, align 8
  %6 = bitcast %"class.boost::detail::variant::copy_into"* %5 to %"class.boost::static_visitor"*
  %7 = getelementptr inbounds %"class.boost::detail::variant::copy_into", %"class.boost::detail::variant::copy_into"* %5, i32 0, i32 0
  %8 = load i8*, i8** %4, align 8
  store i8* %8, i8** %7, align 8
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKviNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PT1_T2_i(i32, %"class.boost::detail::variant::copy_into"* dereferenceable(8), i8*, i32*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::copy_into"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca i32*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"class.boost::detail::variant::copy_into"* %1, %"class.boost::detail::variant::copy_into"** %8, align 8
  store i8* %2, i8** %9, align 8
  store i32* %3, i32** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load i32*, i32** %10, align 8
  call void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9copy_intoEPKviEENT_11result_typeEiRS6_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"class.boost::detail::variant::copy_into"* dereferenceable(8) %14, i8* %15, i32* %16)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKvjNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PT1_T2_i(i32, %"class.boost::detail::variant::copy_into"* dereferenceable(8), i8*, i32*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::copy_into"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca i32*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"class.boost::detail::variant::copy_into"* %1, %"class.boost::detail::variant::copy_into"** %8, align 8
  store i8* %2, i8** %9, align 8
  store i32* %3, i32** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load i32*, i32** %10, align 8
  call void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9copy_intoEPKvjEENT_11result_typeEiRS6_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"class.boost::detail::variant::copy_into"* dereferenceable(8) %14, i8* %15, i32* %16)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKvcNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PT1_T2_i(i32, %"class.boost::detail::variant::copy_into"* dereferenceable(8), i8*, i8*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::copy_into"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca i8*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"class.boost::detail::variant::copy_into"* %1, %"class.boost::detail::variant::copy_into"** %8, align 8
  store i8* %2, i8** %9, align 8
  store i8* %3, i8** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load i8*, i8** %10, align 8
  call void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9copy_intoEPKvcEENT_11result_typeEiRS6_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"class.boost::detail::variant::copy_into"* dereferenceable(8) %14, i8* %15, i8* %16)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKvdNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PT1_T2_i(i32, %"class.boost::detail::variant::copy_into"* dereferenceable(8), i8*, double*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::copy_into"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca double*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"class.boost::detail::variant::copy_into"* %1, %"class.boost::detail::variant::copy_into"** %8, align 8
  store i8* %2, i8** %9, align 8
  store double* %3, double** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load double*, double** %10, align 8
  call void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9copy_intoEPKvdEENT_11result_typeEiRS6_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"class.boost::detail::variant::copy_into"* dereferenceable(8) %14, i8* %15, double* %16)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKvfNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PT1_T2_i(i32, %"class.boost::detail::variant::copy_into"* dereferenceable(8), i8*, float*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::copy_into"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca float*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"class.boost::detail::variant::copy_into"* %1, %"class.boost::detail::variant::copy_into"** %8, align 8
  store i8* %2, i8** %9, align 8
  store float* %3, float** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load float*, float** %10, align 8
  call void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9copy_intoEPKvfEENT_11result_typeEiRS6_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"class.boost::detail::variant::copy_into"* dereferenceable(8) %14, i8* %15, float* %16)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9copy_intoEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS9_T0_PNS1_22apply_visitor_unrolledET1_l(i32, %"class.boost::detail::variant::copy_into"* dereferenceable(8), i8*, %"struct.boost::detail::variant::apply_visitor_unrolled"*, i64) #4 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::copy_into"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca %"struct.boost::detail::variant::apply_visitor_unrolled"*, align 8
  %11 = alloca i64, align 8
  store i32 %0, i32* %7, align 4
  store %"class.boost::detail::variant::copy_into"* %1, %"class.boost::detail::variant::copy_into"** %8, align 8
  store i8* %2, i8** %9, align 8
  store %"struct.boost::detail::variant::apply_visitor_unrolled"* %3, %"struct.boost::detail::variant::apply_visitor_unrolled"** %10, align 8
  store i64 %4, i64* %11, align 8
  call void @_ZN5boost6detail7variant13forced_returnIvEET_v() #17
  unreachable
                                                  ; No predecessors!
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant15visitation_implIN4mpl_4int_ILi20EEENS1_20visitation_impl_stepINS_3mpl6l_iterINS7_5l_endEEESA_EENS1_9copy_intoEPKvNS_7variantIiJjcdfEE18has_fallback_type_EEENT1_11result_typeEiiRSI_T2_NS3_5bool_ILb1EEET3_PT_PT0_(i32, i32, %"class.boost::detail::variant::copy_into"* dereferenceable(8), i8*, %"struct.mpl_::int_.8"*, %"struct.boost::detail::variant::visitation_impl_step.9"*) #4 comdat {
  %7 = alloca %"struct.mpl_::bool_.7", align 1
  %8 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca %"class.boost::detail::variant::copy_into"*, align 8
  %12 = alloca i8*, align 8
  %13 = alloca %"struct.mpl_::int_.8"*, align 8
  %14 = alloca %"struct.boost::detail::variant::visitation_impl_step.9"*, align 8
  store i32 %0, i32* %9, align 4
  store i32 %1, i32* %10, align 4
  store %"class.boost::detail::variant::copy_into"* %2, %"class.boost::detail::variant::copy_into"** %11, align 8
  store i8* %3, i8** %12, align 8
  store %"struct.mpl_::int_.8"* %4, %"struct.mpl_::int_.8"** %13, align 8
  store %"struct.boost::detail::variant::visitation_impl_step.9"* %5, %"struct.boost::detail::variant::visitation_impl_step.9"** %14, align 8
  call void @_ZN5boost6detail7variant13forced_returnIvEET_v() #17
  unreachable
                                                  ; No predecessors!
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9copy_intoEPKviEENT_11result_typeEiRS6_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"class.boost::detail::variant::copy_into"* dereferenceable(8), i8*, i32*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"class.boost::detail::variant::copy_into"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca i32*, align 8
  store i32 %0, i32* %6, align 4
  store %"class.boost::detail::variant::copy_into"* %1, %"class.boost::detail::variant::copy_into"** %7, align 8
  store i8* %2, i8** %8, align 8
  store i32* %3, i32** %9, align 8
  %10 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(4) i32* @_ZN5boost6detail7variant12cast_storageIiEERKT_PKv(i8* %11)
  call void @_ZNK5boost6detail7variant9copy_into14internal_visitIiEEvRKT_i(%"class.boost::detail::variant::copy_into"* %10, i32* dereferenceable(4) %12, i32 1)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost6detail7variant9copy_into14internal_visitIiEEvRKT_i(%"class.boost::detail::variant::copy_into"*, i32* dereferenceable(4), i32) #4 comdat align 2 {
  %4 = alloca %"class.boost::detail::variant::copy_into"*, align 8
  %5 = alloca i32*, align 8
  %6 = alloca i32, align 4
  store %"class.boost::detail::variant::copy_into"* %0, %"class.boost::detail::variant::copy_into"** %4, align 8
  store i32* %1, i32** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %4, align 8
  %8 = getelementptr inbounds %"class.boost::detail::variant::copy_into", %"class.boost::detail::variant::copy_into"* %7, i32 0, i32 0
  %9 = load i8*, i8** %8, align 8
  %10 = bitcast i8* %9 to i32*
  %11 = load i32*, i32** %5, align 8
  %12 = load i32, i32* %11, align 4
  store i32 %12, i32* %10, align 4
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9copy_intoEPKvjEENT_11result_typeEiRS6_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"class.boost::detail::variant::copy_into"* dereferenceable(8), i8*, i32*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"class.boost::detail::variant::copy_into"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca i32*, align 8
  store i32 %0, i32* %6, align 4
  store %"class.boost::detail::variant::copy_into"* %1, %"class.boost::detail::variant::copy_into"** %7, align 8
  store i8* %2, i8** %8, align 8
  store i32* %3, i32** %9, align 8
  %10 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(4) i32* @_ZN5boost6detail7variant12cast_storageIjEERKT_PKv(i8* %11)
  call void @_ZNK5boost6detail7variant9copy_into14internal_visitIjEEvRKT_i(%"class.boost::detail::variant::copy_into"* %10, i32* dereferenceable(4) %12, i32 1)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost6detail7variant9copy_into14internal_visitIjEEvRKT_i(%"class.boost::detail::variant::copy_into"*, i32* dereferenceable(4), i32) #4 comdat align 2 {
  %4 = alloca %"class.boost::detail::variant::copy_into"*, align 8
  %5 = alloca i32*, align 8
  %6 = alloca i32, align 4
  store %"class.boost::detail::variant::copy_into"* %0, %"class.boost::detail::variant::copy_into"** %4, align 8
  store i32* %1, i32** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %4, align 8
  %8 = getelementptr inbounds %"class.boost::detail::variant::copy_into", %"class.boost::detail::variant::copy_into"* %7, i32 0, i32 0
  %9 = load i8*, i8** %8, align 8
  %10 = bitcast i8* %9 to i32*
  %11 = load i32*, i32** %5, align 8
  %12 = load i32, i32* %11, align 4
  store i32 %12, i32* %10, align 4
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9copy_intoEPKvcEENT_11result_typeEiRS6_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"class.boost::detail::variant::copy_into"* dereferenceable(8), i8*, i8*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"class.boost::detail::variant::copy_into"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca i8*, align 8
  store i32 %0, i32* %6, align 4
  store %"class.boost::detail::variant::copy_into"* %1, %"class.boost::detail::variant::copy_into"** %7, align 8
  store i8* %2, i8** %8, align 8
  store i8* %3, i8** %9, align 8
  %10 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(1) i8* @_ZN5boost6detail7variant12cast_storageIcEERKT_PKv(i8* %11)
  call void @_ZNK5boost6detail7variant9copy_into14internal_visitIcEEvRKT_i(%"class.boost::detail::variant::copy_into"* %10, i8* dereferenceable(1) %12, i32 1)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost6detail7variant9copy_into14internal_visitIcEEvRKT_i(%"class.boost::detail::variant::copy_into"*, i8* dereferenceable(1), i32) #4 comdat align 2 {
  %4 = alloca %"class.boost::detail::variant::copy_into"*, align 8
  %5 = alloca i8*, align 8
  %6 = alloca i32, align 4
  store %"class.boost::detail::variant::copy_into"* %0, %"class.boost::detail::variant::copy_into"** %4, align 8
  store i8* %1, i8** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %4, align 8
  %8 = getelementptr inbounds %"class.boost::detail::variant::copy_into", %"class.boost::detail::variant::copy_into"* %7, i32 0, i32 0
  %9 = load i8*, i8** %8, align 8
  %10 = load i8*, i8** %5, align 8
  %11 = load i8, i8* %10, align 1
  store i8 %11, i8* %9, align 1
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9copy_intoEPKvdEENT_11result_typeEiRS6_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"class.boost::detail::variant::copy_into"* dereferenceable(8), i8*, double*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"class.boost::detail::variant::copy_into"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca double*, align 8
  store i32 %0, i32* %6, align 4
  store %"class.boost::detail::variant::copy_into"* %1, %"class.boost::detail::variant::copy_into"** %7, align 8
  store i8* %2, i8** %8, align 8
  store double* %3, double** %9, align 8
  %10 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(8) double* @_ZN5boost6detail7variant12cast_storageIdEERKT_PKv(i8* %11)
  call void @_ZNK5boost6detail7variant9copy_into14internal_visitIdEEvRKT_i(%"class.boost::detail::variant::copy_into"* %10, double* dereferenceable(8) %12, i32 1)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost6detail7variant9copy_into14internal_visitIdEEvRKT_i(%"class.boost::detail::variant::copy_into"*, double* dereferenceable(8), i32) #4 comdat align 2 {
  %4 = alloca %"class.boost::detail::variant::copy_into"*, align 8
  %5 = alloca double*, align 8
  %6 = alloca i32, align 4
  store %"class.boost::detail::variant::copy_into"* %0, %"class.boost::detail::variant::copy_into"** %4, align 8
  store double* %1, double** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %4, align 8
  %8 = getelementptr inbounds %"class.boost::detail::variant::copy_into", %"class.boost::detail::variant::copy_into"* %7, i32 0, i32 0
  %9 = load i8*, i8** %8, align 8
  %10 = bitcast i8* %9 to double*
  %11 = load double*, double** %5, align 8
  %12 = load double, double* %11, align 8
  store double %12, double* %10, align 8
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9copy_intoEPKvfEENT_11result_typeEiRS6_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"class.boost::detail::variant::copy_into"* dereferenceable(8), i8*, float*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"class.boost::detail::variant::copy_into"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca float*, align 8
  store i32 %0, i32* %6, align 4
  store %"class.boost::detail::variant::copy_into"* %1, %"class.boost::detail::variant::copy_into"** %7, align 8
  store i8* %2, i8** %8, align 8
  store float* %3, float** %9, align 8
  %10 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(4) float* @_ZN5boost6detail7variant12cast_storageIfEERKT_PKv(i8* %11)
  call void @_ZNK5boost6detail7variant9copy_into14internal_visitIfEEvRKT_i(%"class.boost::detail::variant::copy_into"* %10, float* dereferenceable(4) %12, i32 1)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost6detail7variant9copy_into14internal_visitIfEEvRKT_i(%"class.boost::detail::variant::copy_into"*, float* dereferenceable(4), i32) #4 comdat align 2 {
  %4 = alloca %"class.boost::detail::variant::copy_into"*, align 8
  %5 = alloca float*, align 8
  %6 = alloca i32, align 4
  store %"class.boost::detail::variant::copy_into"* %0, %"class.boost::detail::variant::copy_into"** %4, align 8
  store float* %1, float** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"class.boost::detail::variant::copy_into"*, %"class.boost::detail::variant::copy_into"** %4, align 8
  %8 = getelementptr inbounds %"class.boost::detail::variant::copy_into", %"class.boost::detail::variant::copy_into"* %7, i32 0, i32 0
  %9 = load i8*, i8** %8, align 8
  %10 = bitcast i8* %9 to float*
  %11 = load float*, float** %5, align 8
  %12 = load float, float* %11, align 4
  store float %12, float* %10, align 4
  ret void
}

; Function Attrs: nounwind readonly
declare dso_local %"struct.std::_Rb_tree_node_base"* @_ZSt18_Rb_tree_incrementPSt18_Rb_tree_node_base(%"struct.std::_Rb_tree_node_base"*) #14

; Function Attrs: nounwind
declare dso_local void @_ZNSaIcEC1Ev(%"class.std::allocator"*) unnamed_addr #2

declare dso_local void @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1EPKcRKS3_(%"class.std::__cxx11::basic_string"*, i8*, %"class.std::allocator"* dereferenceable(1)) unnamed_addr #1

; Function Attrs: nounwind
declare dso_local void @_ZNSaIcED1Ev(%"class.std::allocator"*) unnamed_addr #2

declare dso_local dereferenceable(32) %"class.std::__cxx11::basic_string"* @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSERKS4_(%"class.std::__cxx11::basic_string"*, %"class.std::__cxx11::basic_string"* dereferenceable(32)) #1

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local dereferenceable(16) %"class.boost::variant"* @_ZN5boost7variantIiJjcdfEEaSIiEENS_9enable_ifINS_3mpl3or_INS_7is_sameIT_S1_EENS_6detail7variant29is_variant_constructible_fromIRKS7_NS4_6l_itemIN4mpl_5long_ILl5EEEiNSE_INSG_ILl4EEEjNSE_INSG_ILl3EEEcNSE_INSG_ILl2EEEdNSE_INSG_ILl1EEEfNS4_5l_endEEEEEEEEEEEEENSF_5bool_ILb0EEESU_SU_EERS1_E4typeESD_(%"class.boost::variant"*, i32* dereferenceable(4)) #5 comdat align 2 {
  %3 = alloca %"class.boost::variant"*, align 8
  %4 = alloca i32*, align 8
  store %"class.boost::variant"* %0, %"class.boost::variant"** %3, align 8
  store i32* %1, i32** %4, align 8
  %5 = load %"class.boost::variant"*, %"class.boost::variant"** %3, align 8
  %6 = load i32*, i32** %4, align 8
  call void @_ZN5boost7variantIiJjcdfEE6assignIiEEvRKT_(%"class.boost::variant"* %5, i32* dereferenceable(4) %6)
  ret %"class.boost::variant"* %5
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN9ContainerI9NonDetLogE24appendContainerNondetLogEiS0_(%class.Container*, i32, %class.NonDetLog*) #5 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %4 = alloca %class.Container*, align 8
  %5 = alloca i32, align 4
  %6 = alloca %"class.std::map", align 8
  %7 = alloca %"struct.std::pair.17", align 8
  %8 = alloca i8*
  %9 = alloca i32
  %10 = alloca %"struct.std::pair.14", align 8
  store %class.Container* %0, %class.Container** %4, align 8
  store i32 %1, i32* %5, align 4
  %11 = load %class.Container*, %class.Container** %4, align 8
  call void @_ZNSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS0_EEEC2Ev(%"class.std::map"* %6) #3
  invoke void @_ZNSt4pairIi9NonDetLogEC2IRiRS0_Lb1EEEOT_OT0_(%"struct.std::pair.17"* %7, i32* dereferenceable(4) %5, %class.NonDetLog* dereferenceable(56) %2)
          to label %12 unwind label %22

; <label>:12:                                     ; preds = %3
  %13 = invoke { %"struct.std::_Rb_tree_node_base"*, i8 } @_ZNSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS0_EEE6insertIS3_IiS0_EEENSt9enable_ifIXsr16is_constructibleIS5_T_EE5valueES3_ISt17_Rb_tree_iteratorIS5_EbEE4typeEOSB_(%"class.std::map"* %6, %"struct.std::pair.17"* dereferenceable(64) %7)
          to label %14 unwind label %26

; <label>:14:                                     ; preds = %12
  %15 = bitcast %"struct.std::pair.14"* %10 to { %"struct.std::_Rb_tree_node_base"*, i8 }*
  %16 = getelementptr inbounds { %"struct.std::_Rb_tree_node_base"*, i8 }, { %"struct.std::_Rb_tree_node_base"*, i8 }* %15, i32 0, i32 0
  %17 = extractvalue { %"struct.std::_Rb_tree_node_base"*, i8 } %13, 0
  store %"struct.std::_Rb_tree_node_base"* %17, %"struct.std::_Rb_tree_node_base"** %16, align 8
  %18 = getelementptr inbounds { %"struct.std::_Rb_tree_node_base"*, i8 }, { %"struct.std::_Rb_tree_node_base"*, i8 }* %15, i32 0, i32 1
  %19 = extractvalue { %"struct.std::_Rb_tree_node_base"*, i8 } %13, 1
  store i8 %19, i8* %18, align 8
  call void @_ZNSt4pairIi9NonDetLogED2Ev(%"struct.std::pair.17"* %7) #3
  %20 = getelementptr inbounds %class.Container, %class.Container* %11, i32 0, i32 0
  invoke void @_ZNSt7__cxx114listISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE9push_backERKS9_(%"class.std::__cxx11::list"* %20, %"class.std::map"* dereferenceable(48) %6)
          to label %21 unwind label %22

; <label>:21:                                     ; preds = %14
  call void @_ZNSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS0_EEED2Ev(%"class.std::map"* %6) #3
  ret void

; <label>:22:                                     ; preds = %14, %3
  %23 = landingpad { i8*, i32 }
          cleanup
  %24 = extractvalue { i8*, i32 } %23, 0
  store i8* %24, i8** %8, align 8
  %25 = extractvalue { i8*, i32 } %23, 1
  store i32 %25, i32* %9, align 4
  br label %30

; <label>:26:                                     ; preds = %12
  %27 = landingpad { i8*, i32 }
          cleanup
  %28 = extractvalue { i8*, i32 } %27, 0
  store i8* %28, i8** %8, align 8
  %29 = extractvalue { i8*, i32 } %27, 1
  store i32 %29, i32* %9, align 4
  call void @_ZNSt4pairIi9NonDetLogED2Ev(%"struct.std::pair.17"* %7) #3
  br label %30

; <label>:30:                                     ; preds = %26, %22
  call void @_ZNSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS0_EEED2Ev(%"class.std::map"* %6) #3
  br label %31

; <label>:31:                                     ; preds = %30
  %32 = load i8*, i8** %8, align 8
  %33 = load i32, i32* %9, align 4
  %34 = insertvalue { i8*, i32 } undef, i8* %32, 0
  %35 = insertvalue { i8*, i32 } %34, i32 %33, 1
  resume { i8*, i32 } %35
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost7variantIiJjcdfEE6assignIiEEvRKT_(%"class.boost::variant"*, i32* dereferenceable(4)) #5 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %3 = alloca %"class.boost::variant"*, align 8
  %4 = alloca i32*, align 8
  %5 = alloca %"class.boost::detail::variant::direct_assigner", align 8
  %6 = alloca %"class.boost::variant", align 8
  %7 = alloca i8*
  %8 = alloca i32
  store %"class.boost::variant"* %0, %"class.boost::variant"** %3, align 8
  store i32* %1, i32** %4, align 8
  %9 = load %"class.boost::variant"*, %"class.boost::variant"** %3, align 8
  %10 = load i32*, i32** %4, align 8
  call void @_ZN5boost6detail7variant15direct_assignerIiEC2ERKi(%"class.boost::detail::variant::direct_assigner"* %5, i32* dereferenceable(4) %10) #3
  %11 = call zeroext i1 @_ZNR5boost7variantIiJjcdfEE13apply_visitorINS_6detail7variant15direct_assignerIiEEEENT_11result_typeERS7_(%"class.boost::variant"* %9, %"class.boost::detail::variant::direct_assigner"* dereferenceable(8) %5)
  %12 = zext i1 %11 to i32
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %14, label %22

; <label>:14:                                     ; preds = %2
  %15 = load i32*, i32** %4, align 8
  call void @_ZN5boost7variantIiJjcdfEEC2IiEERKT_PNS_9enable_ifINS_3mpl3or_INS7_4and_INS7_4not_INS_7is_sameIS3_S1_EEEENS_6detail7variant29is_variant_constructible_fromIS5_NS7_6l_itemIN4mpl_5long_ILl5EEEiNSH_INSJ_ILl4EEEjNSH_INSJ_ILl3EEEcNSH_INSJ_ILl2EEEdNSH_INSJ_ILl1EEEfNS7_5l_endEEEEEEEEEEEEENSI_5bool_ILb1EEESX_SX_EENSB_IS3_NS_18recursive_variant_EEENSW_ILb0EEES11_S11_EEvE4typeE(%"class.boost::variant"* %6, i32* dereferenceable(4) %15, i8* null)
  %16 = call dereferenceable(16) %"class.boost::variant"* @_ZN5boost4moveIRNS_7variantIiJjcdfEEEEEONS_11move_detail16remove_referenceIT_E4typeEOS6_(%"class.boost::variant"* dereferenceable(16) %6) #3
  invoke void @_ZN5boost7variantIiJjcdfEE14variant_assignEOS1_(%"class.boost::variant"* %9, %"class.boost::variant"* dereferenceable(16) %16)
          to label %17 unwind label %18

; <label>:17:                                     ; preds = %14
  call void @_ZN5boost7variantIiJjcdfEED2Ev(%"class.boost::variant"* %6) #3
  br label %22

; <label>:18:                                     ; preds = %14
  %19 = landingpad { i8*, i32 }
          cleanup
  %20 = extractvalue { i8*, i32 } %19, 0
  store i8* %20, i8** %7, align 8
  %21 = extractvalue { i8*, i32 } %19, 1
  store i32 %21, i32* %8, align 4
  call void @_ZN5boost7variantIiJjcdfEED2Ev(%"class.boost::variant"* %6) #3
  br label %23

; <label>:22:                                     ; preds = %17, %2
  ret void

; <label>:23:                                     ; preds = %18
  %24 = load i8*, i8** %7, align 8
  %25 = load i32, i32* %8, align 4
  %26 = insertvalue { i8*, i32 } undef, i8* %24, 0
  %27 = insertvalue { i8*, i32 } %26, i32 %25, 1
  resume { i8*, i32 } %27
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant15direct_assignerIiEC2ERKi(%"class.boost::detail::variant::direct_assigner"*, i32* dereferenceable(4)) unnamed_addr #4 comdat align 2 {
  %3 = alloca %"class.boost::detail::variant::direct_assigner"*, align 8
  %4 = alloca i32*, align 8
  store %"class.boost::detail::variant::direct_assigner"* %0, %"class.boost::detail::variant::direct_assigner"** %3, align 8
  store i32* %1, i32** %4, align 8
  %5 = load %"class.boost::detail::variant::direct_assigner"*, %"class.boost::detail::variant::direct_assigner"** %3, align 8
  %6 = bitcast %"class.boost::detail::variant::direct_assigner"* %5 to %"class.boost::static_visitor.12"*
  %7 = getelementptr inbounds %"class.boost::detail::variant::direct_assigner", %"class.boost::detail::variant::direct_assigner"* %5, i32 0, i32 0
  %8 = load i32*, i32** %4, align 8
  store i32* %8, i32** %7, align 8
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local zeroext i1 @_ZNR5boost7variantIiJjcdfEE13apply_visitorINS_6detail7variant15direct_assignerIiEEEENT_11result_typeERS7_(%"class.boost::variant"*, %"class.boost::detail::variant::direct_assigner"* dereferenceable(8)) #5 comdat align 2 {
  %3 = alloca i1, align 1
  %4 = alloca %"struct.mpl_::bool_", align 1
  %5 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::invoke_visitor.13"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca %"struct.mpl_::int_"*, align 8
  %11 = alloca %"struct.boost::detail::variant::visitation_impl_step"*, align 8
  %12 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %13 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %14 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %15 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %16 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %17 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %18 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %19 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %20 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %21 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %22 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %23 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %24 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %25 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %26 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %27 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %28 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %29 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %30 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %31 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %32 = alloca %"struct.mpl_::bool_.7", align 1
  %33 = alloca %"struct.boost::integral_constant", align 1
  %34 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %35 = alloca i32, align 4
  %36 = alloca i32, align 4
  %37 = alloca %"class.boost::detail::variant::invoke_visitor.13"*, align 8
  %38 = alloca i8*, align 8
  %39 = alloca %"struct.mpl_::bool_", align 1
  %40 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %41 = alloca %"class.boost::variant"*, align 8
  %42 = alloca %"class.boost::detail::variant::invoke_visitor.13"*, align 8
  %43 = alloca %"class.boost::variant"*, align 8
  %44 = alloca %"class.boost::detail::variant::direct_assigner"*, align 8
  %45 = alloca %"class.boost::detail::variant::invoke_visitor.13", align 8
  store %"class.boost::variant"* %0, %"class.boost::variant"** %43, align 8
  store %"class.boost::detail::variant::direct_assigner"* %1, %"class.boost::detail::variant::direct_assigner"** %44, align 8
  %46 = load %"class.boost::variant"*, %"class.boost::variant"** %43, align 8
  %47 = load %"class.boost::detail::variant::direct_assigner"*, %"class.boost::detail::variant::direct_assigner"** %44, align 8
  call void @_ZN5boost6detail7variant14invoke_visitorINS1_15direct_assignerIiEELb0EEC2ERS4_(%"class.boost::detail::variant::invoke_visitor.13"* %45, %"class.boost::detail::variant::direct_assigner"* dereferenceable(8) %47) #3
  store %"class.boost::variant"* %46, %"class.boost::variant"** %41, align 8
  store %"class.boost::detail::variant::invoke_visitor.13"* %45, %"class.boost::detail::variant::invoke_visitor.13"** %42, align 8
  %48 = load %"class.boost::variant"*, %"class.boost::variant"** %41, align 8
  %49 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %48, i32 0, i32 0
  %50 = load i32, i32* %49, align 8
  %51 = call i32 @_ZNK5boost7variantIiJjcdfEE5whichEv(%"class.boost::variant"* %48) #3
  %52 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %42, align 8
  %53 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %48, i32 0, i32 2
  %54 = call i8* @_ZN5boost15aligned_storageILm8ELm8EE7addressEv(%"class.boost::aligned_storage"* %53)
  store i32 %50, i32* %35, align 4
  store i32 %51, i32* %36, align 4
  store %"class.boost::detail::variant::invoke_visitor.13"* %52, %"class.boost::detail::variant::invoke_visitor.13"** %37, align 8
  store i8* %54, i8** %38, align 8
  %55 = load i32, i32* %35, align 4
  %56 = load i32, i32* %36, align 4
  %57 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %37, align 8
  %58 = load i8*, i8** %38, align 8
  store i32 %55, i32* %6, align 4
  store i32 %56, i32* %7, align 4
  store %"class.boost::detail::variant::invoke_visitor.13"* %57, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  store i8* %58, i8** %9, align 8
  store %"struct.mpl_::int_"* null, %"struct.mpl_::int_"** %10, align 8
  store %"struct.boost::detail::variant::visitation_impl_step"* null, %"struct.boost::detail::variant::visitation_impl_step"** %11, align 8
  %59 = load i32, i32* %7, align 4
  switch i32 %59, label %160 [
    i32 0, label %60
    i32 1, label %65
    i32 2, label %70
    i32 3, label %75
    i32 4, label %80
    i32 5, label %85
    i32 6, label %90
    i32 7, label %95
    i32 8, label %100
    i32 9, label %105
    i32 10, label %110
    i32 11, label %115
    i32 12, label %120
    i32 13, label %125
    i32 14, label %130
    i32 15, label %135
    i32 16, label %140
    i32 17, label %145
    i32 18, label %150
    i32 19, label %155
  ]

; <label>:60:                                     ; preds = %2
  %61 = load i32, i32* %6, align 4
  %62 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  %63 = load i8*, i8** %9, align 8
  %64 = call zeroext i1 @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPviNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PT1_T2_i(i32 %61, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8) %62, i8* %63, i32* null, i32 1)
  store i1 %64, i1* %3, align 1
  br label %167

; <label>:65:                                     ; preds = %2
  %66 = load i32, i32* %6, align 4
  %67 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  %68 = load i8*, i8** %9, align 8
  %69 = call zeroext i1 @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvjNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PT1_T2_i(i32 %66, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8) %67, i8* %68, i32* null, i32 1)
  store i1 %69, i1* %3, align 1
  br label %167

; <label>:70:                                     ; preds = %2
  %71 = load i32, i32* %6, align 4
  %72 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  %73 = load i8*, i8** %9, align 8
  %74 = call zeroext i1 @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvcNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PT1_T2_i(i32 %71, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8) %72, i8* %73, i8* null, i32 1)
  store i1 %74, i1* %3, align 1
  br label %167

; <label>:75:                                     ; preds = %2
  %76 = load i32, i32* %6, align 4
  %77 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  %78 = load i8*, i8** %9, align 8
  %79 = call zeroext i1 @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvdNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PT1_T2_i(i32 %76, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8) %77, i8* %78, double* null, i32 1)
  store i1 %79, i1* %3, align 1
  br label %167

; <label>:80:                                     ; preds = %2
  %81 = load i32, i32* %6, align 4
  %82 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  %83 = load i8*, i8** %9, align 8
  %84 = call zeroext i1 @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvfNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PT1_T2_i(i32 %81, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8) %82, i8* %83, float* null, i32 1)
  store i1 %84, i1* %3, align 1
  br label %167

; <label>:85:                                     ; preds = %2
  %86 = load i32, i32* %6, align 4
  %87 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  %88 = load i8*, i8** %9, align 8
  %89 = call zeroext i1 @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %86, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8) %87, i8* %88, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  store i1 %89, i1* %3, align 1
  br label %167

; <label>:90:                                     ; preds = %2
  %91 = load i32, i32* %6, align 4
  %92 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  %93 = load i8*, i8** %9, align 8
  %94 = call zeroext i1 @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %91, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8) %92, i8* %93, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  store i1 %94, i1* %3, align 1
  br label %167

; <label>:95:                                     ; preds = %2
  %96 = load i32, i32* %6, align 4
  %97 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  %98 = load i8*, i8** %9, align 8
  %99 = call zeroext i1 @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %96, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8) %97, i8* %98, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  store i1 %99, i1* %3, align 1
  br label %167

; <label>:100:                                    ; preds = %2
  %101 = load i32, i32* %6, align 4
  %102 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  %103 = load i8*, i8** %9, align 8
  %104 = call zeroext i1 @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %101, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8) %102, i8* %103, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  store i1 %104, i1* %3, align 1
  br label %167

; <label>:105:                                    ; preds = %2
  %106 = load i32, i32* %6, align 4
  %107 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  %108 = load i8*, i8** %9, align 8
  %109 = call zeroext i1 @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %106, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8) %107, i8* %108, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  store i1 %109, i1* %3, align 1
  br label %167

; <label>:110:                                    ; preds = %2
  %111 = load i32, i32* %6, align 4
  %112 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  %113 = load i8*, i8** %9, align 8
  %114 = call zeroext i1 @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %111, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8) %112, i8* %113, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  store i1 %114, i1* %3, align 1
  br label %167

; <label>:115:                                    ; preds = %2
  %116 = load i32, i32* %6, align 4
  %117 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  %118 = load i8*, i8** %9, align 8
  %119 = call zeroext i1 @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %116, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8) %117, i8* %118, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  store i1 %119, i1* %3, align 1
  br label %167

; <label>:120:                                    ; preds = %2
  %121 = load i32, i32* %6, align 4
  %122 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  %123 = load i8*, i8** %9, align 8
  %124 = call zeroext i1 @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %121, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8) %122, i8* %123, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  store i1 %124, i1* %3, align 1
  br label %167

; <label>:125:                                    ; preds = %2
  %126 = load i32, i32* %6, align 4
  %127 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  %128 = load i8*, i8** %9, align 8
  %129 = call zeroext i1 @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %126, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8) %127, i8* %128, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  store i1 %129, i1* %3, align 1
  br label %167

; <label>:130:                                    ; preds = %2
  %131 = load i32, i32* %6, align 4
  %132 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  %133 = load i8*, i8** %9, align 8
  %134 = call zeroext i1 @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %131, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8) %132, i8* %133, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  store i1 %134, i1* %3, align 1
  br label %167

; <label>:135:                                    ; preds = %2
  %136 = load i32, i32* %6, align 4
  %137 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  %138 = load i8*, i8** %9, align 8
  %139 = call zeroext i1 @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %136, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8) %137, i8* %138, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  store i1 %139, i1* %3, align 1
  br label %167

; <label>:140:                                    ; preds = %2
  %141 = load i32, i32* %6, align 4
  %142 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  %143 = load i8*, i8** %9, align 8
  %144 = call zeroext i1 @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %141, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8) %142, i8* %143, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  store i1 %144, i1* %3, align 1
  br label %167

; <label>:145:                                    ; preds = %2
  %146 = load i32, i32* %6, align 4
  %147 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  %148 = load i8*, i8** %9, align 8
  %149 = call zeroext i1 @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %146, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8) %147, i8* %148, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  store i1 %149, i1* %3, align 1
  br label %167

; <label>:150:                                    ; preds = %2
  %151 = load i32, i32* %6, align 4
  %152 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  %153 = load i8*, i8** %9, align 8
  %154 = call zeroext i1 @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %151, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8) %152, i8* %153, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  store i1 %154, i1* %3, align 1
  br label %167

; <label>:155:                                    ; preds = %2
  %156 = load i32, i32* %6, align 4
  %157 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  %158 = load i8*, i8** %9, align 8
  %159 = call zeroext i1 @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %156, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8) %157, i8* %158, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  store i1 %159, i1* %3, align 1
  br label %167

; <label>:160:                                    ; preds = %2
  %161 = load i32, i32* %6, align 4
  %162 = load i32, i32* %7, align 4
  %163 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  %164 = load i8*, i8** %9, align 8
  %165 = call dereferenceable(1) %"struct.mpl_::bool_.7"* @_ZNK5boost17integral_constantIbLb1EEcvRKN4mpl_5bool_ILb1EEEEv(%"struct.boost::integral_constant"* %33)
  %166 = call zeroext i1 @_ZN5boost6detail7variant15visitation_implIN4mpl_4int_ILi20EEENS1_20visitation_impl_stepINS_3mpl6l_iterINS7_5l_endEEESA_EENS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT1_11result_typeEiiRSK_T2_NS3_5bool_ILb1EEET3_PT_PT0_(i32 %161, i32 %162, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8) %163, i8* %164, %"struct.mpl_::int_.8"* null, %"struct.boost::detail::variant::visitation_impl_step.9"* null)
  store i1 %166, i1* %3, align 1
  br label %167

; <label>:167:                                    ; preds = %60, %65, %70, %75, %80, %85, %90, %95, %100, %105, %110, %115, %120, %125, %130, %135, %140, %145, %150, %155, %160
  %168 = load i1, i1* %3, align 1
  ret i1 %168
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost7variantIiJjcdfEEC2IiEERKT_PNS_9enable_ifINS_3mpl3or_INS7_4and_INS7_4not_INS_7is_sameIS3_S1_EEEENS_6detail7variant29is_variant_constructible_fromIS5_NS7_6l_itemIN4mpl_5long_ILl5EEEiNSH_INSJ_ILl4EEEjNSH_INSJ_ILl3EEEcNSH_INSJ_ILl2EEEdNSH_INSJ_ILl1EEEfNS7_5l_endEEEEEEEEEEEEENSI_5bool_ILb1EEESX_SX_EENSB_IS3_NS_18recursive_variant_EEENSW_ILb0EEES11_S11_EEvE4typeE(%"class.boost::variant"*, i32* dereferenceable(4), i8*) unnamed_addr #5 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %4 = alloca %"class.boost::variant"*, align 8
  %5 = alloca i32*, align 8
  %6 = alloca i8*, align 8
  %7 = alloca %"struct.mpl_::bool_", align 1
  %8 = alloca i8*
  %9 = alloca i32
  store %"class.boost::variant"* %0, %"class.boost::variant"** %4, align 8
  store i32* %1, i32** %5, align 8
  store i8* %2, i8** %6, align 8
  %10 = load %"class.boost::variant"*, %"class.boost::variant"** %4, align 8
  %11 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %10, i32 0, i32 2
  call void @_ZN5boost15aligned_storageILm8ELm8EEC2Ev(%"class.boost::aligned_storage"* %11)
  %12 = load i32*, i32** %5, align 8
  invoke void @_ZN5boost7variantIiJjcdfEE17convert_constructIKiEEvRT_iN4mpl_5bool_ILb0EEE(%"class.boost::variant"* %10, i32* dereferenceable(4) %12, i32 1)
          to label %13 unwind label %14

; <label>:13:                                     ; preds = %3
  ret void

; <label>:14:                                     ; preds = %3
  %15 = landingpad { i8*, i32 }
          cleanup
  %16 = extractvalue { i8*, i32 } %15, 0
  store i8* %16, i8** %8, align 8
  %17 = extractvalue { i8*, i32 } %15, 1
  store i32 %17, i32* %9, align 4
  call void @_ZN5boost15aligned_storageILm8ELm8EED2Ev(%"class.boost::aligned_storage"* %11) #3
  br label %18

; <label>:18:                                     ; preds = %14
  %19 = load i8*, i8** %8, align 8
  %20 = load i32, i32* %9, align 4
  %21 = insertvalue { i8*, i32 } undef, i8* %19, 0
  %22 = insertvalue { i8*, i32 } %21, i32 %20, 1
  resume { i8*, i32 } %22
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost7variantIiJjcdfEE14variant_assignEOS1_(%"class.boost::variant"*, %"class.boost::variant"* dereferenceable(16)) #5 comdat align 2 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, align 8
  %6 = alloca i8*, align 8
  %7 = alloca %"struct.mpl_::int_"*, align 8
  %8 = alloca %"struct.boost::detail::variant::visitation_impl_step"*, align 8
  %9 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %10 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %11 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %12 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %13 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %14 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %15 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %16 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %17 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %18 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %19 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %20 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %21 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %22 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %23 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %24 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %25 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %26 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %27 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %28 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %29 = alloca %"struct.mpl_::bool_.7", align 1
  %30 = alloca %"struct.boost::integral_constant", align 1
  %31 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %32 = alloca i32, align 4
  %33 = alloca i32, align 4
  %34 = alloca %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, align 8
  %35 = alloca i8*, align 8
  %36 = alloca %"struct.mpl_::bool_", align 1
  %37 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %38 = alloca %"class.boost::variant"*, align 8
  %39 = alloca %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, align 8
  %40 = alloca i32, align 4
  %41 = alloca i32, align 4
  %42 = alloca %"struct.boost::detail::variant::move_storage"*, align 8
  %43 = alloca i8*, align 8
  %44 = alloca %"struct.mpl_::int_"*, align 8
  %45 = alloca %"struct.boost::detail::variant::visitation_impl_step"*, align 8
  %46 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %47 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %48 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %49 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %50 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %51 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %52 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %53 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %54 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %55 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %56 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %57 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %58 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %59 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %60 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %61 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %62 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %63 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %64 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %65 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %66 = alloca %"struct.mpl_::bool_.7", align 1
  %67 = alloca %"struct.boost::integral_constant", align 1
  %68 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %69 = alloca i32, align 4
  %70 = alloca i32, align 4
  %71 = alloca %"struct.boost::detail::variant::move_storage"*, align 8
  %72 = alloca i8*, align 8
  %73 = alloca %"struct.mpl_::bool_", align 1
  %74 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %75 = alloca %"class.boost::variant"*, align 8
  %76 = alloca %"struct.boost::detail::variant::move_storage"*, align 8
  %77 = alloca %"class.boost::variant"*, align 8
  %78 = alloca %"class.boost::variant"*, align 8
  %79 = alloca %"struct.boost::detail::variant::move_storage", align 8
  %80 = alloca %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner", align 8
  store %"class.boost::variant"* %0, %"class.boost::variant"** %77, align 8
  store %"class.boost::variant"* %1, %"class.boost::variant"** %78, align 8
  %81 = load %"class.boost::variant"*, %"class.boost::variant"** %77, align 8
  %82 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %81, i32 0, i32 0
  %83 = load i32, i32* %82, align 8
  %84 = load %"class.boost::variant"*, %"class.boost::variant"** %78, align 8
  %85 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %84, i32 0, i32 0
  %86 = load i32, i32* %85, align 8
  %87 = icmp eq i32 %83, %86
  br i1 %87, label %88, label %191

; <label>:88:                                     ; preds = %2
  %89 = load %"class.boost::variant"*, %"class.boost::variant"** %78, align 8
  %90 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %89, i32 0, i32 2
  %91 = call i8* @_ZN5boost15aligned_storageILm8ELm8EE7addressEv(%"class.boost::aligned_storage"* %90)
  call void @_ZN5boost6detail7variant12move_storageC2EPv(%"struct.boost::detail::variant::move_storage"* %79, i8* %91) #3
  store %"class.boost::variant"* %81, %"class.boost::variant"** %75, align 8
  store %"struct.boost::detail::variant::move_storage"* %79, %"struct.boost::detail::variant::move_storage"** %76, align 8
  %92 = load %"class.boost::variant"*, %"class.boost::variant"** %75, align 8
  %93 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %92, i32 0, i32 0
  %94 = load i32, i32* %93, align 8
  %95 = call i32 @_ZNK5boost7variantIiJjcdfEE5whichEv(%"class.boost::variant"* %92) #3
  %96 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %76, align 8
  %97 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %92, i32 0, i32 2
  %98 = call i8* @_ZN5boost15aligned_storageILm8ELm8EE7addressEv(%"class.boost::aligned_storage"* %97)
  store i32 %94, i32* %69, align 4
  store i32 %95, i32* %70, align 4
  store %"struct.boost::detail::variant::move_storage"* %96, %"struct.boost::detail::variant::move_storage"** %71, align 8
  store i8* %98, i8** %72, align 8
  %99 = load i32, i32* %69, align 4
  %100 = load i32, i32* %70, align 4
  %101 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %71, align 8
  %102 = load i8*, i8** %72, align 8
  store i32 %99, i32* %40, align 4
  store i32 %100, i32* %41, align 4
  store %"struct.boost::detail::variant::move_storage"* %101, %"struct.boost::detail::variant::move_storage"** %42, align 8
  store i8* %102, i8** %43, align 8
  store %"struct.mpl_::int_"* null, %"struct.mpl_::int_"** %44, align 8
  store %"struct.boost::detail::variant::visitation_impl_step"* null, %"struct.boost::detail::variant::visitation_impl_step"** %45, align 8
  %103 = load i32, i32* %41, align 4
  switch i32 %103, label %184 [
    i32 0, label %104
    i32 1, label %108
    i32 2, label %112
    i32 3, label %116
    i32 4, label %120
    i32 5, label %124
    i32 6, label %128
    i32 7, label %132
    i32 8, label %136
    i32 9, label %140
    i32 10, label %144
    i32 11, label %148
    i32 12, label %152
    i32 13, label %156
    i32 14, label %160
    i32 15, label %164
    i32 16, label %168
    i32 17, label %172
    i32 18, label %176
    i32 19, label %180
  ]

; <label>:104:                                    ; preds = %88
  %105 = load i32, i32* %40, align 4
  %106 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %42, align 8
  %107 = load i8*, i8** %43, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPviNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32 %105, %"struct.boost::detail::variant::move_storage"* dereferenceable(8) %106, i8* %107, i32* null, i32 1)
  br label %190

; <label>:108:                                    ; preds = %88
  %109 = load i32, i32* %40, align 4
  %110 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %42, align 8
  %111 = load i8*, i8** %43, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPvjNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32 %109, %"struct.boost::detail::variant::move_storage"* dereferenceable(8) %110, i8* %111, i32* null, i32 1)
  br label %190

; <label>:112:                                    ; preds = %88
  %113 = load i32, i32* %40, align 4
  %114 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %42, align 8
  %115 = load i8*, i8** %43, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPvcNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32 %113, %"struct.boost::detail::variant::move_storage"* dereferenceable(8) %114, i8* %115, i8* null, i32 1)
  br label %190

; <label>:116:                                    ; preds = %88
  %117 = load i32, i32* %40, align 4
  %118 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %42, align 8
  %119 = load i8*, i8** %43, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPvdNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32 %117, %"struct.boost::detail::variant::move_storage"* dereferenceable(8) %118, i8* %119, double* null, i32 1)
  br label %190

; <label>:120:                                    ; preds = %88
  %121 = load i32, i32* %40, align 4
  %122 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %42, align 8
  %123 = load i8*, i8** %43, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPvfNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32 %121, %"struct.boost::detail::variant::move_storage"* dereferenceable(8) %122, i8* %123, float* null, i32 1)
  br label %190

; <label>:124:                                    ; preds = %88
  %125 = load i32, i32* %40, align 4
  %126 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %42, align 8
  %127 = load i8*, i8** %43, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %125, %"struct.boost::detail::variant::move_storage"* dereferenceable(8) %126, i8* %127, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %190

; <label>:128:                                    ; preds = %88
  %129 = load i32, i32* %40, align 4
  %130 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %42, align 8
  %131 = load i8*, i8** %43, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %129, %"struct.boost::detail::variant::move_storage"* dereferenceable(8) %130, i8* %131, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %190

; <label>:132:                                    ; preds = %88
  %133 = load i32, i32* %40, align 4
  %134 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %42, align 8
  %135 = load i8*, i8** %43, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %133, %"struct.boost::detail::variant::move_storage"* dereferenceable(8) %134, i8* %135, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %190

; <label>:136:                                    ; preds = %88
  %137 = load i32, i32* %40, align 4
  %138 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %42, align 8
  %139 = load i8*, i8** %43, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %137, %"struct.boost::detail::variant::move_storage"* dereferenceable(8) %138, i8* %139, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %190

; <label>:140:                                    ; preds = %88
  %141 = load i32, i32* %40, align 4
  %142 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %42, align 8
  %143 = load i8*, i8** %43, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %141, %"struct.boost::detail::variant::move_storage"* dereferenceable(8) %142, i8* %143, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %190

; <label>:144:                                    ; preds = %88
  %145 = load i32, i32* %40, align 4
  %146 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %42, align 8
  %147 = load i8*, i8** %43, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %145, %"struct.boost::detail::variant::move_storage"* dereferenceable(8) %146, i8* %147, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %190

; <label>:148:                                    ; preds = %88
  %149 = load i32, i32* %40, align 4
  %150 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %42, align 8
  %151 = load i8*, i8** %43, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %149, %"struct.boost::detail::variant::move_storage"* dereferenceable(8) %150, i8* %151, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %190

; <label>:152:                                    ; preds = %88
  %153 = load i32, i32* %40, align 4
  %154 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %42, align 8
  %155 = load i8*, i8** %43, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %153, %"struct.boost::detail::variant::move_storage"* dereferenceable(8) %154, i8* %155, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %190

; <label>:156:                                    ; preds = %88
  %157 = load i32, i32* %40, align 4
  %158 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %42, align 8
  %159 = load i8*, i8** %43, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %157, %"struct.boost::detail::variant::move_storage"* dereferenceable(8) %158, i8* %159, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %190

; <label>:160:                                    ; preds = %88
  %161 = load i32, i32* %40, align 4
  %162 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %42, align 8
  %163 = load i8*, i8** %43, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %161, %"struct.boost::detail::variant::move_storage"* dereferenceable(8) %162, i8* %163, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %190

; <label>:164:                                    ; preds = %88
  %165 = load i32, i32* %40, align 4
  %166 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %42, align 8
  %167 = load i8*, i8** %43, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %165, %"struct.boost::detail::variant::move_storage"* dereferenceable(8) %166, i8* %167, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %190

; <label>:168:                                    ; preds = %88
  %169 = load i32, i32* %40, align 4
  %170 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %42, align 8
  %171 = load i8*, i8** %43, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %169, %"struct.boost::detail::variant::move_storage"* dereferenceable(8) %170, i8* %171, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %190

; <label>:172:                                    ; preds = %88
  %173 = load i32, i32* %40, align 4
  %174 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %42, align 8
  %175 = load i8*, i8** %43, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %173, %"struct.boost::detail::variant::move_storage"* dereferenceable(8) %174, i8* %175, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %190

; <label>:176:                                    ; preds = %88
  %177 = load i32, i32* %40, align 4
  %178 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %42, align 8
  %179 = load i8*, i8** %43, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %177, %"struct.boost::detail::variant::move_storage"* dereferenceable(8) %178, i8* %179, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %190

; <label>:180:                                    ; preds = %88
  %181 = load i32, i32* %40, align 4
  %182 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %42, align 8
  %183 = load i8*, i8** %43, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %181, %"struct.boost::detail::variant::move_storage"* dereferenceable(8) %182, i8* %183, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %190

; <label>:184:                                    ; preds = %88
  %185 = load i32, i32* %40, align 4
  %186 = load i32, i32* %41, align 4
  %187 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %42, align 8
  %188 = load i8*, i8** %43, align 8
  %189 = call dereferenceable(1) %"struct.mpl_::bool_.7"* @_ZNK5boost17integral_constantIbLb1EEcvRKN4mpl_5bool_ILb1EEEEv(%"struct.boost::integral_constant"* %67)
  call void @_ZN5boost6detail7variant15visitation_implIN4mpl_4int_ILi20EEENS1_20visitation_impl_stepINS_3mpl6l_iterINS7_5l_endEEESA_EENS1_12move_storageEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT1_11result_typeEiiRSH_T2_NS3_5bool_ILb1EEET3_PT_PT0_(i32 %185, i32 %186, %"struct.boost::detail::variant::move_storage"* dereferenceable(8) %187, i8* %188, %"struct.mpl_::int_.8"* null, %"struct.boost::detail::variant::visitation_impl_step.9"* null)
  br label %190

; <label>:190:                                    ; preds = %104, %108, %112, %116, %120, %124, %128, %132, %136, %140, %144, %148, %152, %156, %160, %164, %168, %172, %176, %180, %184
  br label %294

; <label>:191:                                    ; preds = %2
  %192 = load %"class.boost::variant"*, %"class.boost::variant"** %78, align 8
  %193 = call i32 @_ZNK5boost7variantIiJjcdfEE5whichEv(%"class.boost::variant"* %192) #3
  call void @_ZN5boost7variantIiJjcdfEE13move_assignerC2ERS1_i(%"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %80, %"class.boost::variant"* dereferenceable(16) %81, i32 %193) #3
  %194 = load %"class.boost::variant"*, %"class.boost::variant"** %78, align 8
  store %"class.boost::variant"* %194, %"class.boost::variant"** %38, align 8
  store %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %80, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %39, align 8
  %195 = load %"class.boost::variant"*, %"class.boost::variant"** %38, align 8
  %196 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %195, i32 0, i32 0
  %197 = load i32, i32* %196, align 8
  %198 = call i32 @_ZNK5boost7variantIiJjcdfEE5whichEv(%"class.boost::variant"* %195) #3
  %199 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %39, align 8
  %200 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %195, i32 0, i32 2
  %201 = call i8* @_ZN5boost15aligned_storageILm8ELm8EE7addressEv(%"class.boost::aligned_storage"* %200)
  store i32 %197, i32* %32, align 4
  store i32 %198, i32* %33, align 4
  store %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %199, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %34, align 8
  store i8* %201, i8** %35, align 8
  %202 = load i32, i32* %32, align 4
  %203 = load i32, i32* %33, align 4
  %204 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %34, align 8
  %205 = load i8*, i8** %35, align 8
  store i32 %202, i32* %3, align 4
  store i32 %203, i32* %4, align 4
  store %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %204, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %5, align 8
  store i8* %205, i8** %6, align 8
  store %"struct.mpl_::int_"* null, %"struct.mpl_::int_"** %7, align 8
  store %"struct.boost::detail::variant::visitation_impl_step"* null, %"struct.boost::detail::variant::visitation_impl_step"** %8, align 8
  %206 = load i32, i32* %4, align 4
  switch i32 %206, label %287 [
    i32 0, label %207
    i32 1, label %211
    i32 2, label %215
    i32 3, label %219
    i32 4, label %223
    i32 5, label %227
    i32 6, label %231
    i32 7, label %235
    i32 8, label %239
    i32 9, label %243
    i32 10, label %247
    i32 11, label %251
    i32 12, label %255
    i32 13, label %259
    i32 14, label %263
    i32 15, label %267
    i32 16, label %271
    i32 17, label %275
    i32 18, label %279
    i32 19, label %283
  ]

; <label>:207:                                    ; preds = %191
  %208 = load i32, i32* %3, align 4
  %209 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %5, align 8
  %210 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPviNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32 %208, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16) %209, i8* %210, i32* null, i32 1)
  br label %293

; <label>:211:                                    ; preds = %191
  %212 = load i32, i32* %3, align 4
  %213 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %5, align 8
  %214 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPvjNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32 %212, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16) %213, i8* %214, i32* null, i32 1)
  br label %293

; <label>:215:                                    ; preds = %191
  %216 = load i32, i32* %3, align 4
  %217 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %5, align 8
  %218 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPvcNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32 %216, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16) %217, i8* %218, i8* null, i32 1)
  br label %293

; <label>:219:                                    ; preds = %191
  %220 = load i32, i32* %3, align 4
  %221 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %5, align 8
  %222 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPvdNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32 %220, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16) %221, i8* %222, double* null, i32 1)
  br label %293

; <label>:223:                                    ; preds = %191
  %224 = load i32, i32* %3, align 4
  %225 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %5, align 8
  %226 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPvfNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32 %224, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16) %225, i8* %226, float* null, i32 1)
  br label %293

; <label>:227:                                    ; preds = %191
  %228 = load i32, i32* %3, align 4
  %229 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %5, align 8
  %230 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPvNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %228, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16) %229, i8* %230, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %293

; <label>:231:                                    ; preds = %191
  %232 = load i32, i32* %3, align 4
  %233 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %5, align 8
  %234 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPvNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %232, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16) %233, i8* %234, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %293

; <label>:235:                                    ; preds = %191
  %236 = load i32, i32* %3, align 4
  %237 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %5, align 8
  %238 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPvNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %236, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16) %237, i8* %238, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %293

; <label>:239:                                    ; preds = %191
  %240 = load i32, i32* %3, align 4
  %241 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %5, align 8
  %242 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPvNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %240, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16) %241, i8* %242, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %293

; <label>:243:                                    ; preds = %191
  %244 = load i32, i32* %3, align 4
  %245 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %5, align 8
  %246 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPvNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %244, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16) %245, i8* %246, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %293

; <label>:247:                                    ; preds = %191
  %248 = load i32, i32* %3, align 4
  %249 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %5, align 8
  %250 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPvNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %248, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16) %249, i8* %250, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %293

; <label>:251:                                    ; preds = %191
  %252 = load i32, i32* %3, align 4
  %253 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %5, align 8
  %254 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPvNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %252, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16) %253, i8* %254, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %293

; <label>:255:                                    ; preds = %191
  %256 = load i32, i32* %3, align 4
  %257 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %5, align 8
  %258 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPvNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %256, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16) %257, i8* %258, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %293

; <label>:259:                                    ; preds = %191
  %260 = load i32, i32* %3, align 4
  %261 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %5, align 8
  %262 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPvNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %260, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16) %261, i8* %262, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %293

; <label>:263:                                    ; preds = %191
  %264 = load i32, i32* %3, align 4
  %265 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %5, align 8
  %266 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPvNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %264, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16) %265, i8* %266, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %293

; <label>:267:                                    ; preds = %191
  %268 = load i32, i32* %3, align 4
  %269 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %5, align 8
  %270 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPvNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %268, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16) %269, i8* %270, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %293

; <label>:271:                                    ; preds = %191
  %272 = load i32, i32* %3, align 4
  %273 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %5, align 8
  %274 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPvNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %272, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16) %273, i8* %274, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %293

; <label>:275:                                    ; preds = %191
  %276 = load i32, i32* %3, align 4
  %277 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %5, align 8
  %278 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPvNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %276, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16) %277, i8* %278, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %293

; <label>:279:                                    ; preds = %191
  %280 = load i32, i32* %3, align 4
  %281 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %5, align 8
  %282 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPvNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %280, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16) %281, i8* %282, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %293

; <label>:283:                                    ; preds = %191
  %284 = load i32, i32* %3, align 4
  %285 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %5, align 8
  %286 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPvNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %284, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16) %285, i8* %286, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %293

; <label>:287:                                    ; preds = %191
  %288 = load i32, i32* %3, align 4
  %289 = load i32, i32* %4, align 4
  %290 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %5, align 8
  %291 = load i8*, i8** %6, align 8
  %292 = call dereferenceable(1) %"struct.mpl_::bool_.7"* @_ZNK5boost17integral_constantIbLb1EEcvRKN4mpl_5bool_ILb1EEEEv(%"struct.boost::integral_constant"* %30)
  call void @_ZN5boost6detail7variant15visitation_implIN4mpl_4int_ILi20EEENS1_20visitation_impl_stepINS_3mpl6l_iterINS7_5l_endEEESA_EENS_7variantIiJjcdfEE13move_assignerEPvNSD_18has_fallback_type_EEENT1_11result_typeEiiRSH_T2_NS3_5bool_ILb1EEET3_PT_PT0_(i32 %288, i32 %289, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16) %290, i8* %291, %"struct.mpl_::int_.8"* null, %"struct.boost::detail::variant::visitation_impl_step.9"* null)
  br label %293

; <label>:293:                                    ; preds = %207, %211, %215, %219, %223, %227, %231, %235, %239, %243, %247, %251, %255, %259, %263, %267, %271, %275, %279, %283, %287
  br label %294

; <label>:294:                                    ; preds = %293, %190
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(16) %"class.boost::variant"* @_ZN5boost4moveIRNS_7variantIiJjcdfEEEEEONS_11move_detail16remove_referenceIT_E4typeEOS6_(%"class.boost::variant"* dereferenceable(16)) #4 comdat {
  %2 = alloca %"class.boost::variant"*, align 8
  store %"class.boost::variant"* %0, %"class.boost::variant"** %2, align 8
  %3 = load %"class.boost::variant"*, %"class.boost::variant"** %2, align 8
  ret %"class.boost::variant"* %3
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant14invoke_visitorINS1_15direct_assignerIiEELb0EEC2ERS4_(%"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::direct_assigner"* dereferenceable(8)) unnamed_addr #4 comdat align 2 {
  %3 = alloca %"class.boost::detail::variant::invoke_visitor.13"*, align 8
  %4 = alloca %"class.boost::detail::variant::direct_assigner"*, align 8
  store %"class.boost::detail::variant::invoke_visitor.13"* %0, %"class.boost::detail::variant::invoke_visitor.13"** %3, align 8
  store %"class.boost::detail::variant::direct_assigner"* %1, %"class.boost::detail::variant::direct_assigner"** %4, align 8
  %5 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %3, align 8
  %6 = getelementptr inbounds %"class.boost::detail::variant::invoke_visitor.13", %"class.boost::detail::variant::invoke_visitor.13"* %5, i32 0, i32 0
  %7 = load %"class.boost::detail::variant::direct_assigner"*, %"class.boost::detail::variant::direct_assigner"** %4, align 8
  store %"class.boost::detail::variant::direct_assigner"* %7, %"class.boost::detail::variant::direct_assigner"** %6, align 8
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local zeroext i1 @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPviNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PT1_T2_i(i32, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8), i8*, i32*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::invoke_visitor.13"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca i32*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"class.boost::detail::variant::invoke_visitor.13"* %1, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  store i8* %2, i8** %9, align 8
  store i32* %3, i32** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load i32*, i32** %10, align 8
  %17 = call zeroext i1 @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPviEENT_11result_typeEiRS8_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8) %14, i8* %15, i32* %16)
  ret i1 %17
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local zeroext i1 @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvjNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PT1_T2_i(i32, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8), i8*, i32*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::invoke_visitor.13"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca i32*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"class.boost::detail::variant::invoke_visitor.13"* %1, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  store i8* %2, i8** %9, align 8
  store i32* %3, i32** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load i32*, i32** %10, align 8
  %17 = call zeroext i1 @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvjEENT_11result_typeEiRS8_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8) %14, i8* %15, i32* %16)
  ret i1 %17
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local zeroext i1 @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvcNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PT1_T2_i(i32, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8), i8*, i8*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::invoke_visitor.13"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca i8*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"class.boost::detail::variant::invoke_visitor.13"* %1, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  store i8* %2, i8** %9, align 8
  store i8* %3, i8** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load i8*, i8** %10, align 8
  %17 = call zeroext i1 @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvcEENT_11result_typeEiRS8_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8) %14, i8* %15, i8* %16)
  ret i1 %17
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local zeroext i1 @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvdNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PT1_T2_i(i32, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8), i8*, double*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::invoke_visitor.13"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca double*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"class.boost::detail::variant::invoke_visitor.13"* %1, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  store i8* %2, i8** %9, align 8
  store double* %3, double** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load double*, double** %10, align 8
  %17 = call zeroext i1 @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvdEENT_11result_typeEiRS8_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8) %14, i8* %15, double* %16)
  ret i1 %17
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local zeroext i1 @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvfNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PT1_T2_i(i32, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8), i8*, float*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::invoke_visitor.13"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca float*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"class.boost::detail::variant::invoke_visitor.13"* %1, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  store i8* %2, i8** %9, align 8
  store float* %3, float** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load float*, float** %10, align 8
  %17 = call zeroext i1 @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvfEENT_11result_typeEiRS8_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8) %14, i8* %15, float* %16)
  ret i1 %17
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local zeroext i1 @_ZN5boost6detail7variant22visitation_impl_invokeINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRSB_T0_PNS1_22apply_visitor_unrolledET1_l(i32, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8), i8*, %"struct.boost::detail::variant::apply_visitor_unrolled"*, i64) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::invoke_visitor.13"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca %"struct.boost::detail::variant::apply_visitor_unrolled"*, align 8
  %11 = alloca i64, align 8
  store i32 %0, i32* %7, align 4
  store %"class.boost::detail::variant::invoke_visitor.13"* %1, %"class.boost::detail::variant::invoke_visitor.13"** %8, align 8
  store i8* %2, i8** %9, align 8
  store %"struct.boost::detail::variant::apply_visitor_unrolled"* %3, %"struct.boost::detail::variant::apply_visitor_unrolled"** %10, align 8
  store i64 %4, i64* %11, align 8
  %12 = call zeroext i1 @_ZN5boost6detail7variant13forced_returnIbEET_v() #17
  unreachable
                                                  ; No predecessors!
  ret i1 undef
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local zeroext i1 @_ZN5boost6detail7variant15visitation_implIN4mpl_4int_ILi20EEENS1_20visitation_impl_stepINS_3mpl6l_iterINS7_5l_endEEESA_EENS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT1_11result_typeEiiRSK_T2_NS3_5bool_ILb1EEET3_PT_PT0_(i32, i32, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8), i8*, %"struct.mpl_::int_.8"*, %"struct.boost::detail::variant::visitation_impl_step.9"*) #4 comdat {
  %7 = alloca %"struct.mpl_::bool_.7", align 1
  %8 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca %"class.boost::detail::variant::invoke_visitor.13"*, align 8
  %12 = alloca i8*, align 8
  %13 = alloca %"struct.mpl_::int_.8"*, align 8
  %14 = alloca %"struct.boost::detail::variant::visitation_impl_step.9"*, align 8
  store i32 %0, i32* %9, align 4
  store i32 %1, i32* %10, align 4
  store %"class.boost::detail::variant::invoke_visitor.13"* %2, %"class.boost::detail::variant::invoke_visitor.13"** %11, align 8
  store i8* %3, i8** %12, align 8
  store %"struct.mpl_::int_.8"* %4, %"struct.mpl_::int_.8"** %13, align 8
  store %"struct.boost::detail::variant::visitation_impl_step.9"* %5, %"struct.boost::detail::variant::visitation_impl_step.9"** %14, align 8
  %15 = call zeroext i1 @_ZN5boost6detail7variant13forced_returnIbEET_v() #17
  unreachable
                                                  ; No predecessors!
  ret i1 undef
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local zeroext i1 @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPviEENT_11result_typeEiRS8_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8), i8*, i32*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"class.boost::detail::variant::invoke_visitor.13"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca i32*, align 8
  store i32 %0, i32* %6, align 4
  store %"class.boost::detail::variant::invoke_visitor.13"* %1, %"class.boost::detail::variant::invoke_visitor.13"** %7, align 8
  store i8* %2, i8** %8, align 8
  store i32* %3, i32** %9, align 8
  %10 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(4) i32* @_ZN5boost6detail7variant12cast_storageIiEERT_Pv(i8* %11)
  %13 = call zeroext i1 @_ZN5boost6detail7variant14invoke_visitorINS1_15direct_assignerIiEELb0EE14internal_visitIRiEENS_12disable_if_cIXaaLb0Esr7is_sameIT_S9_EE5valueEbE4typeEOS9_i(%"class.boost::detail::variant::invoke_visitor.13"* %10, i32* dereferenceable(4) %12, i32 1)
  ret i1 %13
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local zeroext i1 @_ZN5boost6detail7variant14invoke_visitorINS1_15direct_assignerIiEELb0EE14internal_visitIRiEENS_12disable_if_cIXaaLb0Esr7is_sameIT_S9_EE5valueEbE4typeEOS9_i(%"class.boost::detail::variant::invoke_visitor.13"*, i32* dereferenceable(4), i32) #5 comdat align 2 {
  %4 = alloca %"class.boost::detail::variant::invoke_visitor.13"*, align 8
  %5 = alloca i32*, align 8
  %6 = alloca i32, align 4
  store %"class.boost::detail::variant::invoke_visitor.13"* %0, %"class.boost::detail::variant::invoke_visitor.13"** %4, align 8
  store i32* %1, i32** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %4, align 8
  %8 = getelementptr inbounds %"class.boost::detail::variant::invoke_visitor.13", %"class.boost::detail::variant::invoke_visitor.13"* %7, i32 0, i32 0
  %9 = load %"class.boost::detail::variant::direct_assigner"*, %"class.boost::detail::variant::direct_assigner"** %8, align 8
  %10 = load i32*, i32** %5, align 8
  %11 = call zeroext i1 @_ZN5boost6detail7variant15direct_assignerIiEclERi(%"class.boost::detail::variant::direct_assigner"* %9, i32* dereferenceable(4) %10)
  ret i1 %11
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local zeroext i1 @_ZN5boost6detail7variant15direct_assignerIiEclERi(%"class.boost::detail::variant::direct_assigner"*, i32* dereferenceable(4)) #4 comdat align 2 {
  %3 = alloca %"class.boost::detail::variant::direct_assigner"*, align 8
  %4 = alloca i32*, align 8
  store %"class.boost::detail::variant::direct_assigner"* %0, %"class.boost::detail::variant::direct_assigner"** %3, align 8
  store i32* %1, i32** %4, align 8
  %5 = load %"class.boost::detail::variant::direct_assigner"*, %"class.boost::detail::variant::direct_assigner"** %3, align 8
  %6 = getelementptr inbounds %"class.boost::detail::variant::direct_assigner", %"class.boost::detail::variant::direct_assigner"* %5, i32 0, i32 0
  %7 = load i32*, i32** %6, align 8
  %8 = load i32, i32* %7, align 4
  %9 = load i32*, i32** %4, align 8
  store i32 %8, i32* %9, align 4
  ret i1 true
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local zeroext i1 @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvjEENT_11result_typeEiRS8_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8), i8*, i32*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"class.boost::detail::variant::invoke_visitor.13"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca i32*, align 8
  store i32 %0, i32* %6, align 4
  store %"class.boost::detail::variant::invoke_visitor.13"* %1, %"class.boost::detail::variant::invoke_visitor.13"** %7, align 8
  store i8* %2, i8** %8, align 8
  store i32* %3, i32** %9, align 8
  %10 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(4) i32* @_ZN5boost6detail7variant12cast_storageIjEERT_Pv(i8* %11)
  %13 = call zeroext i1 @_ZN5boost6detail7variant14invoke_visitorINS1_15direct_assignerIiEELb0EE14internal_visitIRjEENS_12disable_if_cIXaaLb0Esr7is_sameIT_S9_EE5valueEbE4typeEOS9_i(%"class.boost::detail::variant::invoke_visitor.13"* %10, i32* dereferenceable(4) %12, i32 1)
  ret i1 %13
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local zeroext i1 @_ZN5boost6detail7variant14invoke_visitorINS1_15direct_assignerIiEELb0EE14internal_visitIRjEENS_12disable_if_cIXaaLb0Esr7is_sameIT_S9_EE5valueEbE4typeEOS9_i(%"class.boost::detail::variant::invoke_visitor.13"*, i32* dereferenceable(4), i32) #4 comdat align 2 {
  %4 = alloca %"class.boost::detail::variant::invoke_visitor.13"*, align 8
  %5 = alloca i32*, align 8
  %6 = alloca i32, align 4
  store %"class.boost::detail::variant::invoke_visitor.13"* %0, %"class.boost::detail::variant::invoke_visitor.13"** %4, align 8
  store i32* %1, i32** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %4, align 8
  %8 = getelementptr inbounds %"class.boost::detail::variant::invoke_visitor.13", %"class.boost::detail::variant::invoke_visitor.13"* %7, i32 0, i32 0
  %9 = load %"class.boost::detail::variant::direct_assigner"*, %"class.boost::detail::variant::direct_assigner"** %8, align 8
  %10 = load i32*, i32** %5, align 8
  %11 = call zeroext i1 @_ZN5boost6detail7variant15direct_assignerIiEclIjEEbRT_(%"class.boost::detail::variant::direct_assigner"* %9, i32* dereferenceable(4) %10) #3
  ret i1 %11
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local zeroext i1 @_ZN5boost6detail7variant15direct_assignerIiEclIjEEbRT_(%"class.boost::detail::variant::direct_assigner"*, i32* dereferenceable(4)) #4 comdat align 2 {
  %3 = alloca %"class.boost::detail::variant::direct_assigner"*, align 8
  %4 = alloca i32*, align 8
  store %"class.boost::detail::variant::direct_assigner"* %0, %"class.boost::detail::variant::direct_assigner"** %3, align 8
  store i32* %1, i32** %4, align 8
  %5 = load %"class.boost::detail::variant::direct_assigner"*, %"class.boost::detail::variant::direct_assigner"** %3, align 8
  ret i1 false
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local zeroext i1 @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvcEENT_11result_typeEiRS8_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8), i8*, i8*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"class.boost::detail::variant::invoke_visitor.13"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca i8*, align 8
  store i32 %0, i32* %6, align 4
  store %"class.boost::detail::variant::invoke_visitor.13"* %1, %"class.boost::detail::variant::invoke_visitor.13"** %7, align 8
  store i8* %2, i8** %8, align 8
  store i8* %3, i8** %9, align 8
  %10 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(1) i8* @_ZN5boost6detail7variant12cast_storageIcEERT_Pv(i8* %11)
  %13 = call zeroext i1 @_ZN5boost6detail7variant14invoke_visitorINS1_15direct_assignerIiEELb0EE14internal_visitIRcEENS_12disable_if_cIXaaLb0Esr7is_sameIT_S9_EE5valueEbE4typeEOS9_i(%"class.boost::detail::variant::invoke_visitor.13"* %10, i8* dereferenceable(1) %12, i32 1)
  ret i1 %13
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local zeroext i1 @_ZN5boost6detail7variant14invoke_visitorINS1_15direct_assignerIiEELb0EE14internal_visitIRcEENS_12disable_if_cIXaaLb0Esr7is_sameIT_S9_EE5valueEbE4typeEOS9_i(%"class.boost::detail::variant::invoke_visitor.13"*, i8* dereferenceable(1), i32) #4 comdat align 2 {
  %4 = alloca %"class.boost::detail::variant::invoke_visitor.13"*, align 8
  %5 = alloca i8*, align 8
  %6 = alloca i32, align 4
  store %"class.boost::detail::variant::invoke_visitor.13"* %0, %"class.boost::detail::variant::invoke_visitor.13"** %4, align 8
  store i8* %1, i8** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %4, align 8
  %8 = getelementptr inbounds %"class.boost::detail::variant::invoke_visitor.13", %"class.boost::detail::variant::invoke_visitor.13"* %7, i32 0, i32 0
  %9 = load %"class.boost::detail::variant::direct_assigner"*, %"class.boost::detail::variant::direct_assigner"** %8, align 8
  %10 = load i8*, i8** %5, align 8
  %11 = call zeroext i1 @_ZN5boost6detail7variant15direct_assignerIiEclIcEEbRT_(%"class.boost::detail::variant::direct_assigner"* %9, i8* dereferenceable(1) %10) #3
  ret i1 %11
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local zeroext i1 @_ZN5boost6detail7variant15direct_assignerIiEclIcEEbRT_(%"class.boost::detail::variant::direct_assigner"*, i8* dereferenceable(1)) #4 comdat align 2 {
  %3 = alloca %"class.boost::detail::variant::direct_assigner"*, align 8
  %4 = alloca i8*, align 8
  store %"class.boost::detail::variant::direct_assigner"* %0, %"class.boost::detail::variant::direct_assigner"** %3, align 8
  store i8* %1, i8** %4, align 8
  %5 = load %"class.boost::detail::variant::direct_assigner"*, %"class.boost::detail::variant::direct_assigner"** %3, align 8
  ret i1 false
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local zeroext i1 @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvdEENT_11result_typeEiRS8_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8), i8*, double*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"class.boost::detail::variant::invoke_visitor.13"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca double*, align 8
  store i32 %0, i32* %6, align 4
  store %"class.boost::detail::variant::invoke_visitor.13"* %1, %"class.boost::detail::variant::invoke_visitor.13"** %7, align 8
  store i8* %2, i8** %8, align 8
  store double* %3, double** %9, align 8
  %10 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(8) double* @_ZN5boost6detail7variant12cast_storageIdEERT_Pv(i8* %11)
  %13 = call zeroext i1 @_ZN5boost6detail7variant14invoke_visitorINS1_15direct_assignerIiEELb0EE14internal_visitIRdEENS_12disable_if_cIXaaLb0Esr7is_sameIT_S9_EE5valueEbE4typeEOS9_i(%"class.boost::detail::variant::invoke_visitor.13"* %10, double* dereferenceable(8) %12, i32 1)
  ret i1 %13
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local zeroext i1 @_ZN5boost6detail7variant14invoke_visitorINS1_15direct_assignerIiEELb0EE14internal_visitIRdEENS_12disable_if_cIXaaLb0Esr7is_sameIT_S9_EE5valueEbE4typeEOS9_i(%"class.boost::detail::variant::invoke_visitor.13"*, double* dereferenceable(8), i32) #4 comdat align 2 {
  %4 = alloca %"class.boost::detail::variant::invoke_visitor.13"*, align 8
  %5 = alloca double*, align 8
  %6 = alloca i32, align 4
  store %"class.boost::detail::variant::invoke_visitor.13"* %0, %"class.boost::detail::variant::invoke_visitor.13"** %4, align 8
  store double* %1, double** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %4, align 8
  %8 = getelementptr inbounds %"class.boost::detail::variant::invoke_visitor.13", %"class.boost::detail::variant::invoke_visitor.13"* %7, i32 0, i32 0
  %9 = load %"class.boost::detail::variant::direct_assigner"*, %"class.boost::detail::variant::direct_assigner"** %8, align 8
  %10 = load double*, double** %5, align 8
  %11 = call zeroext i1 @_ZN5boost6detail7variant15direct_assignerIiEclIdEEbRT_(%"class.boost::detail::variant::direct_assigner"* %9, double* dereferenceable(8) %10) #3
  ret i1 %11
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local zeroext i1 @_ZN5boost6detail7variant15direct_assignerIiEclIdEEbRT_(%"class.boost::detail::variant::direct_assigner"*, double* dereferenceable(8)) #4 comdat align 2 {
  %3 = alloca %"class.boost::detail::variant::direct_assigner"*, align 8
  %4 = alloca double*, align 8
  store %"class.boost::detail::variant::direct_assigner"* %0, %"class.boost::detail::variant::direct_assigner"** %3, align 8
  store double* %1, double** %4, align 8
  %5 = load %"class.boost::detail::variant::direct_assigner"*, %"class.boost::detail::variant::direct_assigner"** %3, align 8
  ret i1 false
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local zeroext i1 @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_14invoke_visitorINS1_15direct_assignerIiEELb0EEEPvfEENT_11result_typeEiRS8_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"class.boost::detail::variant::invoke_visitor.13"* dereferenceable(8), i8*, float*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"class.boost::detail::variant::invoke_visitor.13"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca float*, align 8
  store i32 %0, i32* %6, align 4
  store %"class.boost::detail::variant::invoke_visitor.13"* %1, %"class.boost::detail::variant::invoke_visitor.13"** %7, align 8
  store i8* %2, i8** %8, align 8
  store float* %3, float** %9, align 8
  %10 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(4) float* @_ZN5boost6detail7variant12cast_storageIfEERT_Pv(i8* %11)
  %13 = call zeroext i1 @_ZN5boost6detail7variant14invoke_visitorINS1_15direct_assignerIiEELb0EE14internal_visitIRfEENS_12disable_if_cIXaaLb0Esr7is_sameIT_S9_EE5valueEbE4typeEOS9_i(%"class.boost::detail::variant::invoke_visitor.13"* %10, float* dereferenceable(4) %12, i32 1)
  ret i1 %13
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local zeroext i1 @_ZN5boost6detail7variant14invoke_visitorINS1_15direct_assignerIiEELb0EE14internal_visitIRfEENS_12disable_if_cIXaaLb0Esr7is_sameIT_S9_EE5valueEbE4typeEOS9_i(%"class.boost::detail::variant::invoke_visitor.13"*, float* dereferenceable(4), i32) #4 comdat align 2 {
  %4 = alloca %"class.boost::detail::variant::invoke_visitor.13"*, align 8
  %5 = alloca float*, align 8
  %6 = alloca i32, align 4
  store %"class.boost::detail::variant::invoke_visitor.13"* %0, %"class.boost::detail::variant::invoke_visitor.13"** %4, align 8
  store float* %1, float** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"class.boost::detail::variant::invoke_visitor.13"*, %"class.boost::detail::variant::invoke_visitor.13"** %4, align 8
  %8 = getelementptr inbounds %"class.boost::detail::variant::invoke_visitor.13", %"class.boost::detail::variant::invoke_visitor.13"* %7, i32 0, i32 0
  %9 = load %"class.boost::detail::variant::direct_assigner"*, %"class.boost::detail::variant::direct_assigner"** %8, align 8
  %10 = load float*, float** %5, align 8
  %11 = call zeroext i1 @_ZN5boost6detail7variant15direct_assignerIiEclIfEEbRT_(%"class.boost::detail::variant::direct_assigner"* %9, float* dereferenceable(4) %10) #3
  ret i1 %11
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local zeroext i1 @_ZN5boost6detail7variant15direct_assignerIiEclIfEEbRT_(%"class.boost::detail::variant::direct_assigner"*, float* dereferenceable(4)) #4 comdat align 2 {
  %3 = alloca %"class.boost::detail::variant::direct_assigner"*, align 8
  %4 = alloca float*, align 8
  store %"class.boost::detail::variant::direct_assigner"* %0, %"class.boost::detail::variant::direct_assigner"** %3, align 8
  store float* %1, float** %4, align 8
  %5 = load %"class.boost::detail::variant::direct_assigner"*, %"class.boost::detail::variant::direct_assigner"** %3, align 8
  ret i1 false
}

; Function Attrs: noinline noreturn nounwind optnone uwtable
define linkonce_odr dso_local zeroext i1 @_ZN5boost6detail7variant13forced_returnIbEET_v() #8 comdat {
  %1 = alloca i1, align 1
  %2 = alloca i1 ()*, align 8
  call void @__assert_fail(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.str.2, i32 0, i32 0), i8* getelementptr inbounds ([52 x i8], [52 x i8]* @.str.3, i32 0, i32 0), i32 38, i8* getelementptr inbounds ([53 x i8], [53 x i8]* @__PRETTY_FUNCTION__._ZN5boost6detail7variant13forced_returnIbEET_v, i32 0, i32 0)) #16
  unreachable
                                                  ; No predecessors!
  unreachable
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost7variantIiJjcdfEE17convert_constructIKiEEvRT_iN4mpl_5bool_ILb0EEE(%"class.boost::variant"*, i32* dereferenceable(4), i32) #5 comdat align 2 {
  %4 = alloca %"struct.mpl_::bool_", align 1
  %5 = alloca %"class.boost::variant"*, align 8
  %6 = alloca i32*, align 8
  %7 = alloca i32, align 4
  store %"class.boost::variant"* %0, %"class.boost::variant"** %5, align 8
  store i32* %1, i32** %6, align 8
  store i32 %2, i32* %7, align 4
  %8 = load %"class.boost::variant"*, %"class.boost::variant"** %5, align 8
  %9 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %8, i32 0, i32 2
  %10 = call i8* @_ZN5boost15aligned_storageILm8ELm8EE7addressEv(%"class.boost::aligned_storage"* %9)
  %11 = load i32*, i32** %6, align 8
  %12 = call i32 @_ZN5boost6detail7variant21make_initializer_node5applyINS_3mpl4pairINS1_16initializer_rootEN4mpl_4int_ILi0EEEEENS4_6l_iterINS4_5list5IijcdfEEEEE16initializer_node10initializeEPvRKi(i8* %10, i32* dereferenceable(4) %11)
  call void @_ZN5boost7variantIiJjcdfEE14indicate_whichEi(%"class.boost::variant"* %8, i32 %12) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local i32 @_ZN5boost6detail7variant21make_initializer_node5applyINS_3mpl4pairINS1_16initializer_rootEN4mpl_4int_ILi0EEEEENS4_6l_iterINS4_5list5IijcdfEEEEE16initializer_node10initializeEPvRKi(i8*, i32* dereferenceable(4)) #4 comdat align 2 {
  %3 = alloca i8*, align 8
  %4 = alloca i32*, align 8
  store i8* %0, i8** %3, align 8
  store i32* %1, i32** %4, align 8
  %5 = load i8*, i8** %3, align 8
  %6 = bitcast i8* %5 to i32*
  %7 = load i32*, i32** %4, align 8
  %8 = load i32, i32* %7, align 4
  store i32 %8, i32* %6, align 4
  ret i32 0
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant12move_storageC2EPv(%"struct.boost::detail::variant::move_storage"*, i8*) unnamed_addr #4 comdat align 2 {
  %3 = alloca %"struct.boost::detail::variant::move_storage"*, align 8
  %4 = alloca i8*, align 8
  store %"struct.boost::detail::variant::move_storage"* %0, %"struct.boost::detail::variant::move_storage"** %3, align 8
  store i8* %1, i8** %4, align 8
  %5 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %3, align 8
  %6 = bitcast %"struct.boost::detail::variant::move_storage"* %5 to %"class.boost::static_visitor"*
  %7 = getelementptr inbounds %"struct.boost::detail::variant::move_storage", %"struct.boost::detail::variant::move_storage"* %5, i32 0, i32 0
  %8 = load i8*, i8** %4, align 8
  store i8* %8, i8** %7, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost7variantIiJjcdfEE13move_assignerC2ERS1_i(%"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant"* dereferenceable(16), i32) unnamed_addr #4 comdat align 2 {
  %4 = alloca %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, align 8
  %5 = alloca %"class.boost::variant"*, align 8
  %6 = alloca i32, align 4
  store %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %0, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %4, align 8
  store %"class.boost::variant"* %1, %"class.boost::variant"** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %4, align 8
  %8 = bitcast %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %7 to %"class.boost::variant<int, unsigned int, char, double, float>::assigner"*
  %9 = load %"class.boost::variant"*, %"class.boost::variant"** %5, align 8
  %10 = load i32, i32* %6, align 4
  call void @_ZN5boost7variantIiJjcdfEE8assignerC2ERS1_i(%"class.boost::variant<int, unsigned int, char, double, float>::assigner"* %8, %"class.boost::variant"* dereferenceable(16) %9, i32 %10) #3
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPviNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32, %"struct.boost::detail::variant::move_storage"* dereferenceable(8), i8*, i32*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"struct.boost::detail::variant::move_storage"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca i32*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"struct.boost::detail::variant::move_storage"* %1, %"struct.boost::detail::variant::move_storage"** %8, align 8
  store i8* %2, i8** %9, align 8
  store i32* %3, i32** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load i32*, i32** %10, align 8
  call void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_12move_storageEPviEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"struct.boost::detail::variant::move_storage"* dereferenceable(8) %14, i8* %15, i32* %16)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPvjNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32, %"struct.boost::detail::variant::move_storage"* dereferenceable(8), i8*, i32*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"struct.boost::detail::variant::move_storage"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca i32*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"struct.boost::detail::variant::move_storage"* %1, %"struct.boost::detail::variant::move_storage"** %8, align 8
  store i8* %2, i8** %9, align 8
  store i32* %3, i32** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load i32*, i32** %10, align 8
  call void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_12move_storageEPvjEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"struct.boost::detail::variant::move_storage"* dereferenceable(8) %14, i8* %15, i32* %16)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPvcNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32, %"struct.boost::detail::variant::move_storage"* dereferenceable(8), i8*, i8*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"struct.boost::detail::variant::move_storage"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca i8*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"struct.boost::detail::variant::move_storage"* %1, %"struct.boost::detail::variant::move_storage"** %8, align 8
  store i8* %2, i8** %9, align 8
  store i8* %3, i8** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load i8*, i8** %10, align 8
  call void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_12move_storageEPvcEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"struct.boost::detail::variant::move_storage"* dereferenceable(8) %14, i8* %15, i8* %16)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPvdNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32, %"struct.boost::detail::variant::move_storage"* dereferenceable(8), i8*, double*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"struct.boost::detail::variant::move_storage"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca double*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"struct.boost::detail::variant::move_storage"* %1, %"struct.boost::detail::variant::move_storage"** %8, align 8
  store i8* %2, i8** %9, align 8
  store double* %3, double** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load double*, double** %10, align 8
  call void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_12move_storageEPvdEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"struct.boost::detail::variant::move_storage"* dereferenceable(8) %14, i8* %15, double* %16)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPvfNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32, %"struct.boost::detail::variant::move_storage"* dereferenceable(8), i8*, float*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"struct.boost::detail::variant::move_storage"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca float*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"struct.boost::detail::variant::move_storage"* %1, %"struct.boost::detail::variant::move_storage"** %8, align 8
  store i8* %2, i8** %9, align 8
  store float* %3, float** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load float*, float** %10, align 8
  call void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_12move_storageEPvfEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"struct.boost::detail::variant::move_storage"* dereferenceable(8) %14, i8* %15, float* %16)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_12move_storageEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32, %"struct.boost::detail::variant::move_storage"* dereferenceable(8), i8*, %"struct.boost::detail::variant::apply_visitor_unrolled"*, i64) #4 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"struct.boost::detail::variant::move_storage"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca %"struct.boost::detail::variant::apply_visitor_unrolled"*, align 8
  %11 = alloca i64, align 8
  store i32 %0, i32* %7, align 4
  store %"struct.boost::detail::variant::move_storage"* %1, %"struct.boost::detail::variant::move_storage"** %8, align 8
  store i8* %2, i8** %9, align 8
  store %"struct.boost::detail::variant::apply_visitor_unrolled"* %3, %"struct.boost::detail::variant::apply_visitor_unrolled"** %10, align 8
  store i64 %4, i64* %11, align 8
  call void @_ZN5boost6detail7variant13forced_returnIvEET_v() #17
  unreachable
                                                  ; No predecessors!
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant15visitation_implIN4mpl_4int_ILi20EEENS1_20visitation_impl_stepINS_3mpl6l_iterINS7_5l_endEEESA_EENS1_12move_storageEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT1_11result_typeEiiRSH_T2_NS3_5bool_ILb1EEET3_PT_PT0_(i32, i32, %"struct.boost::detail::variant::move_storage"* dereferenceable(8), i8*, %"struct.mpl_::int_.8"*, %"struct.boost::detail::variant::visitation_impl_step.9"*) #4 comdat {
  %7 = alloca %"struct.mpl_::bool_.7", align 1
  %8 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca %"struct.boost::detail::variant::move_storage"*, align 8
  %12 = alloca i8*, align 8
  %13 = alloca %"struct.mpl_::int_.8"*, align 8
  %14 = alloca %"struct.boost::detail::variant::visitation_impl_step.9"*, align 8
  store i32 %0, i32* %9, align 4
  store i32 %1, i32* %10, align 4
  store %"struct.boost::detail::variant::move_storage"* %2, %"struct.boost::detail::variant::move_storage"** %11, align 8
  store i8* %3, i8** %12, align 8
  store %"struct.mpl_::int_.8"* %4, %"struct.mpl_::int_.8"** %13, align 8
  store %"struct.boost::detail::variant::visitation_impl_step.9"* %5, %"struct.boost::detail::variant::visitation_impl_step.9"** %14, align 8
  call void @_ZN5boost6detail7variant13forced_returnIvEET_v() #17
  unreachable
                                                  ; No predecessors!
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_12move_storageEPviEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"struct.boost::detail::variant::move_storage"* dereferenceable(8), i8*, i32*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"struct.boost::detail::variant::move_storage"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca i32*, align 8
  store i32 %0, i32* %6, align 4
  store %"struct.boost::detail::variant::move_storage"* %1, %"struct.boost::detail::variant::move_storage"** %7, align 8
  store i8* %2, i8** %8, align 8
  store i32* %3, i32** %9, align 8
  %10 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(4) i32* @_ZN5boost6detail7variant12cast_storageIiEERT_Pv(i8* %11)
  call void @_ZNK5boost6detail7variant12move_storage14internal_visitIiEEvRT_i(%"struct.boost::detail::variant::move_storage"* %10, i32* dereferenceable(4) %12, i32 1)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost6detail7variant12move_storage14internal_visitIiEEvRT_i(%"struct.boost::detail::variant::move_storage"*, i32* dereferenceable(4), i32) #4 comdat align 2 {
  %4 = alloca %"struct.boost::detail::variant::move_storage"*, align 8
  %5 = alloca i32*, align 8
  %6 = alloca i32, align 4
  store %"struct.boost::detail::variant::move_storage"* %0, %"struct.boost::detail::variant::move_storage"** %4, align 8
  store i32* %1, i32** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %4, align 8
  %8 = getelementptr inbounds %"struct.boost::detail::variant::move_storage", %"struct.boost::detail::variant::move_storage"* %7, i32 0, i32 0
  %9 = load i8*, i8** %8, align 8
  %10 = bitcast i8* %9 to i32*
  %11 = call dereferenceable(4) i32* @_ZN5boost4moveIRiEEONS_11move_detail16remove_referenceIT_E4typeEOS4_(i32* dereferenceable(4) %10) #3
  %12 = load i32, i32* %11, align 4
  %13 = load i32*, i32** %5, align 8
  store i32 %12, i32* %13, align 4
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(4) i32* @_ZN5boost4moveIRiEEONS_11move_detail16remove_referenceIT_E4typeEOS4_(i32* dereferenceable(4)) #4 comdat {
  %2 = alloca i32*, align 8
  store i32* %0, i32** %2, align 8
  %3 = load i32*, i32** %2, align 8
  ret i32* %3
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_12move_storageEPvjEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"struct.boost::detail::variant::move_storage"* dereferenceable(8), i8*, i32*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"struct.boost::detail::variant::move_storage"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca i32*, align 8
  store i32 %0, i32* %6, align 4
  store %"struct.boost::detail::variant::move_storage"* %1, %"struct.boost::detail::variant::move_storage"** %7, align 8
  store i8* %2, i8** %8, align 8
  store i32* %3, i32** %9, align 8
  %10 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(4) i32* @_ZN5boost6detail7variant12cast_storageIjEERT_Pv(i8* %11)
  call void @_ZNK5boost6detail7variant12move_storage14internal_visitIjEEvRT_i(%"struct.boost::detail::variant::move_storage"* %10, i32* dereferenceable(4) %12, i32 1)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost6detail7variant12move_storage14internal_visitIjEEvRT_i(%"struct.boost::detail::variant::move_storage"*, i32* dereferenceable(4), i32) #4 comdat align 2 {
  %4 = alloca %"struct.boost::detail::variant::move_storage"*, align 8
  %5 = alloca i32*, align 8
  %6 = alloca i32, align 4
  store %"struct.boost::detail::variant::move_storage"* %0, %"struct.boost::detail::variant::move_storage"** %4, align 8
  store i32* %1, i32** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %4, align 8
  %8 = getelementptr inbounds %"struct.boost::detail::variant::move_storage", %"struct.boost::detail::variant::move_storage"* %7, i32 0, i32 0
  %9 = load i8*, i8** %8, align 8
  %10 = bitcast i8* %9 to i32*
  %11 = call dereferenceable(4) i32* @_ZN5boost4moveIRjEEONS_11move_detail16remove_referenceIT_E4typeEOS4_(i32* dereferenceable(4) %10) #3
  %12 = load i32, i32* %11, align 4
  %13 = load i32*, i32** %5, align 8
  store i32 %12, i32* %13, align 4
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(4) i32* @_ZN5boost4moveIRjEEONS_11move_detail16remove_referenceIT_E4typeEOS4_(i32* dereferenceable(4)) #4 comdat {
  %2 = alloca i32*, align 8
  store i32* %0, i32** %2, align 8
  %3 = load i32*, i32** %2, align 8
  ret i32* %3
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_12move_storageEPvcEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"struct.boost::detail::variant::move_storage"* dereferenceable(8), i8*, i8*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"struct.boost::detail::variant::move_storage"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca i8*, align 8
  store i32 %0, i32* %6, align 4
  store %"struct.boost::detail::variant::move_storage"* %1, %"struct.boost::detail::variant::move_storage"** %7, align 8
  store i8* %2, i8** %8, align 8
  store i8* %3, i8** %9, align 8
  %10 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(1) i8* @_ZN5boost6detail7variant12cast_storageIcEERT_Pv(i8* %11)
  call void @_ZNK5boost6detail7variant12move_storage14internal_visitIcEEvRT_i(%"struct.boost::detail::variant::move_storage"* %10, i8* dereferenceable(1) %12, i32 1)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost6detail7variant12move_storage14internal_visitIcEEvRT_i(%"struct.boost::detail::variant::move_storage"*, i8* dereferenceable(1), i32) #4 comdat align 2 {
  %4 = alloca %"struct.boost::detail::variant::move_storage"*, align 8
  %5 = alloca i8*, align 8
  %6 = alloca i32, align 4
  store %"struct.boost::detail::variant::move_storage"* %0, %"struct.boost::detail::variant::move_storage"** %4, align 8
  store i8* %1, i8** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %4, align 8
  %8 = getelementptr inbounds %"struct.boost::detail::variant::move_storage", %"struct.boost::detail::variant::move_storage"* %7, i32 0, i32 0
  %9 = load i8*, i8** %8, align 8
  %10 = call dereferenceable(1) i8* @_ZN5boost4moveIRcEEONS_11move_detail16remove_referenceIT_E4typeEOS4_(i8* dereferenceable(1) %9) #3
  %11 = load i8, i8* %10, align 1
  %12 = load i8*, i8** %5, align 8
  store i8 %11, i8* %12, align 1
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(1) i8* @_ZN5boost4moveIRcEEONS_11move_detail16remove_referenceIT_E4typeEOS4_(i8* dereferenceable(1)) #4 comdat {
  %2 = alloca i8*, align 8
  store i8* %0, i8** %2, align 8
  %3 = load i8*, i8** %2, align 8
  ret i8* %3
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_12move_storageEPvdEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"struct.boost::detail::variant::move_storage"* dereferenceable(8), i8*, double*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"struct.boost::detail::variant::move_storage"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca double*, align 8
  store i32 %0, i32* %6, align 4
  store %"struct.boost::detail::variant::move_storage"* %1, %"struct.boost::detail::variant::move_storage"** %7, align 8
  store i8* %2, i8** %8, align 8
  store double* %3, double** %9, align 8
  %10 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(8) double* @_ZN5boost6detail7variant12cast_storageIdEERT_Pv(i8* %11)
  call void @_ZNK5boost6detail7variant12move_storage14internal_visitIdEEvRT_i(%"struct.boost::detail::variant::move_storage"* %10, double* dereferenceable(8) %12, i32 1)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost6detail7variant12move_storage14internal_visitIdEEvRT_i(%"struct.boost::detail::variant::move_storage"*, double* dereferenceable(8), i32) #4 comdat align 2 {
  %4 = alloca %"struct.boost::detail::variant::move_storage"*, align 8
  %5 = alloca double*, align 8
  %6 = alloca i32, align 4
  store %"struct.boost::detail::variant::move_storage"* %0, %"struct.boost::detail::variant::move_storage"** %4, align 8
  store double* %1, double** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %4, align 8
  %8 = getelementptr inbounds %"struct.boost::detail::variant::move_storage", %"struct.boost::detail::variant::move_storage"* %7, i32 0, i32 0
  %9 = load i8*, i8** %8, align 8
  %10 = bitcast i8* %9 to double*
  %11 = call dereferenceable(8) double* @_ZN5boost4moveIRdEEONS_11move_detail16remove_referenceIT_E4typeEOS4_(double* dereferenceable(8) %10) #3
  %12 = load double, double* %11, align 8
  %13 = load double*, double** %5, align 8
  store double %12, double* %13, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(8) double* @_ZN5boost4moveIRdEEONS_11move_detail16remove_referenceIT_E4typeEOS4_(double* dereferenceable(8)) #4 comdat {
  %2 = alloca double*, align 8
  store double* %0, double** %2, align 8
  %3 = load double*, double** %2, align 8
  ret double* %3
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_12move_storageEPvfEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"struct.boost::detail::variant::move_storage"* dereferenceable(8), i8*, float*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"struct.boost::detail::variant::move_storage"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca float*, align 8
  store i32 %0, i32* %6, align 4
  store %"struct.boost::detail::variant::move_storage"* %1, %"struct.boost::detail::variant::move_storage"** %7, align 8
  store i8* %2, i8** %8, align 8
  store float* %3, float** %9, align 8
  %10 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(4) float* @_ZN5boost6detail7variant12cast_storageIfEERT_Pv(i8* %11)
  call void @_ZNK5boost6detail7variant12move_storage14internal_visitIfEEvRT_i(%"struct.boost::detail::variant::move_storage"* %10, float* dereferenceable(4) %12, i32 1)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost6detail7variant12move_storage14internal_visitIfEEvRT_i(%"struct.boost::detail::variant::move_storage"*, float* dereferenceable(4), i32) #4 comdat align 2 {
  %4 = alloca %"struct.boost::detail::variant::move_storage"*, align 8
  %5 = alloca float*, align 8
  %6 = alloca i32, align 4
  store %"struct.boost::detail::variant::move_storage"* %0, %"struct.boost::detail::variant::move_storage"** %4, align 8
  store float* %1, float** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"struct.boost::detail::variant::move_storage"*, %"struct.boost::detail::variant::move_storage"** %4, align 8
  %8 = getelementptr inbounds %"struct.boost::detail::variant::move_storage", %"struct.boost::detail::variant::move_storage"* %7, i32 0, i32 0
  %9 = load i8*, i8** %8, align 8
  %10 = bitcast i8* %9 to float*
  %11 = call dereferenceable(4) float* @_ZN5boost4moveIRfEEONS_11move_detail16remove_referenceIT_E4typeEOS4_(float* dereferenceable(4) %10) #3
  %12 = load float, float* %11, align 4
  %13 = load float*, float** %5, align 8
  store float %12, float* %13, align 4
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(4) float* @_ZN5boost4moveIRfEEONS_11move_detail16remove_referenceIT_E4typeEOS4_(float* dereferenceable(4)) #4 comdat {
  %2 = alloca float*, align 8
  store float* %0, float** %2, align 8
  %3 = load float*, float** %2, align 8
  ret float* %3
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost7variantIiJjcdfEE8assignerC2ERS1_i(%"class.boost::variant<int, unsigned int, char, double, float>::assigner"*, %"class.boost::variant"* dereferenceable(16), i32) unnamed_addr #4 comdat align 2 {
  %4 = alloca %"class.boost::variant<int, unsigned int, char, double, float>::assigner"*, align 8
  %5 = alloca %"class.boost::variant"*, align 8
  %6 = alloca i32, align 4
  store %"class.boost::variant<int, unsigned int, char, double, float>::assigner"* %0, %"class.boost::variant<int, unsigned int, char, double, float>::assigner"** %4, align 8
  store %"class.boost::variant"* %1, %"class.boost::variant"** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"class.boost::variant<int, unsigned int, char, double, float>::assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::assigner"** %4, align 8
  %8 = bitcast %"class.boost::variant<int, unsigned int, char, double, float>::assigner"* %7 to %"class.boost::static_visitor"*
  %9 = getelementptr inbounds %"class.boost::variant<int, unsigned int, char, double, float>::assigner", %"class.boost::variant<int, unsigned int, char, double, float>::assigner"* %7, i32 0, i32 0
  %10 = load %"class.boost::variant"*, %"class.boost::variant"** %5, align 8
  store %"class.boost::variant"* %10, %"class.boost::variant"** %9, align 8
  %11 = getelementptr inbounds %"class.boost::variant<int, unsigned int, char, double, float>::assigner", %"class.boost::variant<int, unsigned int, char, double, float>::assigner"* %7, i32 0, i32 1
  %12 = load i32, i32* %6, align 4
  store i32 %12, i32* %11, align 8
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPviNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16), i8*, i32*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca i32*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %1, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %8, align 8
  store i8* %2, i8** %9, align 8
  store i32* %3, i32** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load i32*, i32** %10, align 8
  call void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS_7variantIiJjcdfEE13move_assignerEPviEENT_11result_typeEiRS7_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16) %14, i8* %15, i32* %16)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPvjNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16), i8*, i32*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca i32*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %1, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %8, align 8
  store i8* %2, i8** %9, align 8
  store i32* %3, i32** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load i32*, i32** %10, align 8
  call void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS_7variantIiJjcdfEE13move_assignerEPvjEENT_11result_typeEiRS7_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16) %14, i8* %15, i32* %16)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPvcNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16), i8*, i8*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca i8*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %1, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %8, align 8
  store i8* %2, i8** %9, align 8
  store i8* %3, i8** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load i8*, i8** %10, align 8
  call void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS_7variantIiJjcdfEE13move_assignerEPvcEENT_11result_typeEiRS7_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16) %14, i8* %15, i8* %16)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPvdNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16), i8*, double*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca double*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %1, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %8, align 8
  store i8* %2, i8** %9, align 8
  store double* %3, double** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load double*, double** %10, align 8
  call void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS_7variantIiJjcdfEE13move_assignerEPvdEENT_11result_typeEiRS7_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16) %14, i8* %15, double* %16)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPvfNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16), i8*, float*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca float*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %1, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %8, align 8
  store i8* %2, i8** %9, align 8
  store float* %3, float** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load float*, float** %10, align 8
  call void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS_7variantIiJjcdfEE13move_assignerEPvfEENT_11result_typeEiRS7_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16) %14, i8* %15, float* %16)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS_7variantIiJjcdfEE13move_assignerEPvNS4_18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16), i8*, %"struct.boost::detail::variant::apply_visitor_unrolled"*, i64) #4 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca %"struct.boost::detail::variant::apply_visitor_unrolled"*, align 8
  %11 = alloca i64, align 8
  store i32 %0, i32* %7, align 4
  store %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %1, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %8, align 8
  store i8* %2, i8** %9, align 8
  store %"struct.boost::detail::variant::apply_visitor_unrolled"* %3, %"struct.boost::detail::variant::apply_visitor_unrolled"** %10, align 8
  store i64 %4, i64* %11, align 8
  call void @_ZN5boost6detail7variant13forced_returnIvEET_v() #17
  unreachable
                                                  ; No predecessors!
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant15visitation_implIN4mpl_4int_ILi20EEENS1_20visitation_impl_stepINS_3mpl6l_iterINS7_5l_endEEESA_EENS_7variantIiJjcdfEE13move_assignerEPvNSD_18has_fallback_type_EEENT1_11result_typeEiiRSH_T2_NS3_5bool_ILb1EEET3_PT_PT0_(i32, i32, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16), i8*, %"struct.mpl_::int_.8"*, %"struct.boost::detail::variant::visitation_impl_step.9"*) #4 comdat {
  %7 = alloca %"struct.mpl_::bool_.7", align 1
  %8 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, align 8
  %12 = alloca i8*, align 8
  %13 = alloca %"struct.mpl_::int_.8"*, align 8
  %14 = alloca %"struct.boost::detail::variant::visitation_impl_step.9"*, align 8
  store i32 %0, i32* %9, align 4
  store i32 %1, i32* %10, align 4
  store %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %2, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %11, align 8
  store i8* %3, i8** %12, align 8
  store %"struct.mpl_::int_.8"* %4, %"struct.mpl_::int_.8"** %13, align 8
  store %"struct.boost::detail::variant::visitation_impl_step.9"* %5, %"struct.boost::detail::variant::visitation_impl_step.9"** %14, align 8
  call void @_ZN5boost6detail7variant13forced_returnIvEET_v() #17
  unreachable
                                                  ; No predecessors!
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS_7variantIiJjcdfEE13move_assignerEPviEENT_11result_typeEiRS7_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16), i8*, i32*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca i32*, align 8
  store i32 %0, i32* %6, align 4
  store %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %1, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %7, align 8
  store i8* %2, i8** %8, align 8
  store i32* %3, i32** %9, align 8
  %10 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(4) i32* @_ZN5boost6detail7variant12cast_storageIiEERT_Pv(i8* %11)
  call void @_ZNK5boost7variantIiJjcdfEE13move_assigner14internal_visitIiEEvRT_i(%"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %10, i32* dereferenceable(4) %12, i32 1)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost7variantIiJjcdfEE13move_assigner14internal_visitIiEEvRT_i(%"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, i32* dereferenceable(4), i32) #4 comdat align 2 {
  %4 = alloca %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, align 8
  %5 = alloca i32*, align 8
  %6 = alloca i32, align 4
  %7 = alloca %"struct.mpl_::bool_.7", align 1
  %8 = alloca %"struct.mpl_::bool_.7", align 1
  %9 = alloca %"struct.boost::integral_constant", align 1
  %10 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  store %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %0, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %4, align 8
  store i32* %1, i32** %5, align 8
  store i32 %2, i32* %6, align 4
  %11 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %4, align 8
  %12 = load i32*, i32** %5, align 8
  %13 = call dereferenceable(1) %"struct.mpl_::bool_.7"* @_ZNK5boost17integral_constantIbLb1EEcvRKN4mpl_5bool_ILb1EEEEv(%"struct.boost::integral_constant"* %9)
  call void @_ZNK5boost7variantIiJjcdfEE13move_assigner11assign_implIiN4mpl_5bool_ILb1EEENS1_18has_fallback_type_EEEvRT_T0_S6_T1_(%"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %11, i32* dereferenceable(4) %12) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost7variantIiJjcdfEE13move_assigner11assign_implIiN4mpl_5bool_ILb1EEENS1_18has_fallback_type_EEEvRT_T0_S6_T1_(%"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, i32* dereferenceable(4)) #4 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %3 = alloca %"struct.mpl_::bool_.7", align 1
  %4 = alloca %"struct.mpl_::bool_.7", align 1
  %5 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %6 = alloca %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, align 8
  %7 = alloca i32*, align 8
  store %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %0, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %6, align 8
  store i32* %1, i32** %7, align 8
  %8 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %6, align 8
  %9 = bitcast %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %8 to %"class.boost::variant<int, unsigned int, char, double, float>::assigner"*
  %10 = getelementptr inbounds %"class.boost::variant<int, unsigned int, char, double, float>::assigner", %"class.boost::variant<int, unsigned int, char, double, float>::assigner"* %9, i32 0, i32 0
  %11 = load %"class.boost::variant"*, %"class.boost::variant"** %10, align 8
  call void @_ZN5boost7variantIiJjcdfEE15destroy_contentEv(%"class.boost::variant"* %11) #3
  %12 = bitcast %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %8 to %"class.boost::variant<int, unsigned int, char, double, float>::assigner"*
  %13 = getelementptr inbounds %"class.boost::variant<int, unsigned int, char, double, float>::assigner", %"class.boost::variant<int, unsigned int, char, double, float>::assigner"* %12, i32 0, i32 0
  %14 = load %"class.boost::variant"*, %"class.boost::variant"** %13, align 8
  %15 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %14, i32 0, i32 2
  %16 = invoke i8* @_ZN5boost15aligned_storageILm8ELm8EE7addressEv(%"class.boost::aligned_storage"* %15)
          to label %17 unwind label %28

; <label>:17:                                     ; preds = %2
  %18 = bitcast i8* %16 to i32*
  %19 = load i32*, i32** %7, align 8
  %20 = call dereferenceable(4) i32* @_ZN5boost4moveIRiEEONS_11move_detail16remove_referenceIT_E4typeEOS4_(i32* dereferenceable(4) %19) #3
  %21 = load i32, i32* %20, align 4
  store i32 %21, i32* %18, align 4
  %22 = bitcast %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %8 to %"class.boost::variant<int, unsigned int, char, double, float>::assigner"*
  %23 = getelementptr inbounds %"class.boost::variant<int, unsigned int, char, double, float>::assigner", %"class.boost::variant<int, unsigned int, char, double, float>::assigner"* %22, i32 0, i32 0
  %24 = load %"class.boost::variant"*, %"class.boost::variant"** %23, align 8
  %25 = bitcast %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %8 to %"class.boost::variant<int, unsigned int, char, double, float>::assigner"*
  %26 = getelementptr inbounds %"class.boost::variant<int, unsigned int, char, double, float>::assigner", %"class.boost::variant<int, unsigned int, char, double, float>::assigner"* %25, i32 0, i32 1
  %27 = load i32, i32* %26, align 8
  call void @_ZN5boost7variantIiJjcdfEE14indicate_whichEi(%"class.boost::variant"* %24, i32 %27) #3
  ret void

; <label>:28:                                     ; preds = %2
  %29 = landingpad { i8*, i32 }
          catch i8* null
  %30 = extractvalue { i8*, i32 } %29, 0
  call void @__clang_call_terminate(i8* %30) #16
  unreachable
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS_7variantIiJjcdfEE13move_assignerEPvjEENT_11result_typeEiRS7_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16), i8*, i32*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca i32*, align 8
  store i32 %0, i32* %6, align 4
  store %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %1, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %7, align 8
  store i8* %2, i8** %8, align 8
  store i32* %3, i32** %9, align 8
  %10 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(4) i32* @_ZN5boost6detail7variant12cast_storageIjEERT_Pv(i8* %11)
  call void @_ZNK5boost7variantIiJjcdfEE13move_assigner14internal_visitIjEEvRT_i(%"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %10, i32* dereferenceable(4) %12, i32 1)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost7variantIiJjcdfEE13move_assigner14internal_visitIjEEvRT_i(%"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, i32* dereferenceable(4), i32) #4 comdat align 2 {
  %4 = alloca %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, align 8
  %5 = alloca i32*, align 8
  %6 = alloca i32, align 4
  %7 = alloca %"struct.mpl_::bool_.7", align 1
  %8 = alloca %"struct.mpl_::bool_.7", align 1
  %9 = alloca %"struct.boost::integral_constant", align 1
  %10 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  store %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %0, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %4, align 8
  store i32* %1, i32** %5, align 8
  store i32 %2, i32* %6, align 4
  %11 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %4, align 8
  %12 = load i32*, i32** %5, align 8
  %13 = call dereferenceable(1) %"struct.mpl_::bool_.7"* @_ZNK5boost17integral_constantIbLb1EEcvRKN4mpl_5bool_ILb1EEEEv(%"struct.boost::integral_constant"* %9)
  call void @_ZNK5boost7variantIiJjcdfEE13move_assigner11assign_implIjN4mpl_5bool_ILb1EEENS1_18has_fallback_type_EEEvRT_T0_S6_T1_(%"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %11, i32* dereferenceable(4) %12) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost7variantIiJjcdfEE13move_assigner11assign_implIjN4mpl_5bool_ILb1EEENS1_18has_fallback_type_EEEvRT_T0_S6_T1_(%"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, i32* dereferenceable(4)) #4 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %3 = alloca %"struct.mpl_::bool_.7", align 1
  %4 = alloca %"struct.mpl_::bool_.7", align 1
  %5 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %6 = alloca %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, align 8
  %7 = alloca i32*, align 8
  store %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %0, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %6, align 8
  store i32* %1, i32** %7, align 8
  %8 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %6, align 8
  %9 = bitcast %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %8 to %"class.boost::variant<int, unsigned int, char, double, float>::assigner"*
  %10 = getelementptr inbounds %"class.boost::variant<int, unsigned int, char, double, float>::assigner", %"class.boost::variant<int, unsigned int, char, double, float>::assigner"* %9, i32 0, i32 0
  %11 = load %"class.boost::variant"*, %"class.boost::variant"** %10, align 8
  call void @_ZN5boost7variantIiJjcdfEE15destroy_contentEv(%"class.boost::variant"* %11) #3
  %12 = bitcast %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %8 to %"class.boost::variant<int, unsigned int, char, double, float>::assigner"*
  %13 = getelementptr inbounds %"class.boost::variant<int, unsigned int, char, double, float>::assigner", %"class.boost::variant<int, unsigned int, char, double, float>::assigner"* %12, i32 0, i32 0
  %14 = load %"class.boost::variant"*, %"class.boost::variant"** %13, align 8
  %15 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %14, i32 0, i32 2
  %16 = invoke i8* @_ZN5boost15aligned_storageILm8ELm8EE7addressEv(%"class.boost::aligned_storage"* %15)
          to label %17 unwind label %28

; <label>:17:                                     ; preds = %2
  %18 = bitcast i8* %16 to i32*
  %19 = load i32*, i32** %7, align 8
  %20 = call dereferenceable(4) i32* @_ZN5boost4moveIRjEEONS_11move_detail16remove_referenceIT_E4typeEOS4_(i32* dereferenceable(4) %19) #3
  %21 = load i32, i32* %20, align 4
  store i32 %21, i32* %18, align 4
  %22 = bitcast %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %8 to %"class.boost::variant<int, unsigned int, char, double, float>::assigner"*
  %23 = getelementptr inbounds %"class.boost::variant<int, unsigned int, char, double, float>::assigner", %"class.boost::variant<int, unsigned int, char, double, float>::assigner"* %22, i32 0, i32 0
  %24 = load %"class.boost::variant"*, %"class.boost::variant"** %23, align 8
  %25 = bitcast %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %8 to %"class.boost::variant<int, unsigned int, char, double, float>::assigner"*
  %26 = getelementptr inbounds %"class.boost::variant<int, unsigned int, char, double, float>::assigner", %"class.boost::variant<int, unsigned int, char, double, float>::assigner"* %25, i32 0, i32 1
  %27 = load i32, i32* %26, align 8
  call void @_ZN5boost7variantIiJjcdfEE14indicate_whichEi(%"class.boost::variant"* %24, i32 %27) #3
  ret void

; <label>:28:                                     ; preds = %2
  %29 = landingpad { i8*, i32 }
          catch i8* null
  %30 = extractvalue { i8*, i32 } %29, 0
  call void @__clang_call_terminate(i8* %30) #16
  unreachable
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS_7variantIiJjcdfEE13move_assignerEPvcEENT_11result_typeEiRS7_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16), i8*, i8*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca i8*, align 8
  store i32 %0, i32* %6, align 4
  store %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %1, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %7, align 8
  store i8* %2, i8** %8, align 8
  store i8* %3, i8** %9, align 8
  %10 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(1) i8* @_ZN5boost6detail7variant12cast_storageIcEERT_Pv(i8* %11)
  call void @_ZNK5boost7variantIiJjcdfEE13move_assigner14internal_visitIcEEvRT_i(%"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %10, i8* dereferenceable(1) %12, i32 1)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost7variantIiJjcdfEE13move_assigner14internal_visitIcEEvRT_i(%"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, i8* dereferenceable(1), i32) #4 comdat align 2 {
  %4 = alloca %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, align 8
  %5 = alloca i8*, align 8
  %6 = alloca i32, align 4
  %7 = alloca %"struct.mpl_::bool_.7", align 1
  %8 = alloca %"struct.mpl_::bool_.7", align 1
  %9 = alloca %"struct.boost::integral_constant", align 1
  %10 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  store %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %0, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %4, align 8
  store i8* %1, i8** %5, align 8
  store i32 %2, i32* %6, align 4
  %11 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %4, align 8
  %12 = load i8*, i8** %5, align 8
  %13 = call dereferenceable(1) %"struct.mpl_::bool_.7"* @_ZNK5boost17integral_constantIbLb1EEcvRKN4mpl_5bool_ILb1EEEEv(%"struct.boost::integral_constant"* %9)
  call void @_ZNK5boost7variantIiJjcdfEE13move_assigner11assign_implIcN4mpl_5bool_ILb1EEENS1_18has_fallback_type_EEEvRT_T0_S6_T1_(%"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %11, i8* dereferenceable(1) %12) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost7variantIiJjcdfEE13move_assigner11assign_implIcN4mpl_5bool_ILb1EEENS1_18has_fallback_type_EEEvRT_T0_S6_T1_(%"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, i8* dereferenceable(1)) #4 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %3 = alloca %"struct.mpl_::bool_.7", align 1
  %4 = alloca %"struct.mpl_::bool_.7", align 1
  %5 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %6 = alloca %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, align 8
  %7 = alloca i8*, align 8
  store %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %0, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %6, align 8
  store i8* %1, i8** %7, align 8
  %8 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %6, align 8
  %9 = bitcast %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %8 to %"class.boost::variant<int, unsigned int, char, double, float>::assigner"*
  %10 = getelementptr inbounds %"class.boost::variant<int, unsigned int, char, double, float>::assigner", %"class.boost::variant<int, unsigned int, char, double, float>::assigner"* %9, i32 0, i32 0
  %11 = load %"class.boost::variant"*, %"class.boost::variant"** %10, align 8
  call void @_ZN5boost7variantIiJjcdfEE15destroy_contentEv(%"class.boost::variant"* %11) #3
  %12 = bitcast %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %8 to %"class.boost::variant<int, unsigned int, char, double, float>::assigner"*
  %13 = getelementptr inbounds %"class.boost::variant<int, unsigned int, char, double, float>::assigner", %"class.boost::variant<int, unsigned int, char, double, float>::assigner"* %12, i32 0, i32 0
  %14 = load %"class.boost::variant"*, %"class.boost::variant"** %13, align 8
  %15 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %14, i32 0, i32 2
  %16 = invoke i8* @_ZN5boost15aligned_storageILm8ELm8EE7addressEv(%"class.boost::aligned_storage"* %15)
          to label %17 unwind label %27

; <label>:17:                                     ; preds = %2
  %18 = load i8*, i8** %7, align 8
  %19 = call dereferenceable(1) i8* @_ZN5boost4moveIRcEEONS_11move_detail16remove_referenceIT_E4typeEOS4_(i8* dereferenceable(1) %18) #3
  %20 = load i8, i8* %19, align 1
  store i8 %20, i8* %16, align 1
  %21 = bitcast %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %8 to %"class.boost::variant<int, unsigned int, char, double, float>::assigner"*
  %22 = getelementptr inbounds %"class.boost::variant<int, unsigned int, char, double, float>::assigner", %"class.boost::variant<int, unsigned int, char, double, float>::assigner"* %21, i32 0, i32 0
  %23 = load %"class.boost::variant"*, %"class.boost::variant"** %22, align 8
  %24 = bitcast %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %8 to %"class.boost::variant<int, unsigned int, char, double, float>::assigner"*
  %25 = getelementptr inbounds %"class.boost::variant<int, unsigned int, char, double, float>::assigner", %"class.boost::variant<int, unsigned int, char, double, float>::assigner"* %24, i32 0, i32 1
  %26 = load i32, i32* %25, align 8
  call void @_ZN5boost7variantIiJjcdfEE14indicate_whichEi(%"class.boost::variant"* %23, i32 %26) #3
  ret void

; <label>:27:                                     ; preds = %2
  %28 = landingpad { i8*, i32 }
          catch i8* null
  %29 = extractvalue { i8*, i32 } %28, 0
  call void @__clang_call_terminate(i8* %29) #16
  unreachable
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS_7variantIiJjcdfEE13move_assignerEPvdEENT_11result_typeEiRS7_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16), i8*, double*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca double*, align 8
  store i32 %0, i32* %6, align 4
  store %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %1, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %7, align 8
  store i8* %2, i8** %8, align 8
  store double* %3, double** %9, align 8
  %10 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(8) double* @_ZN5boost6detail7variant12cast_storageIdEERT_Pv(i8* %11)
  call void @_ZNK5boost7variantIiJjcdfEE13move_assigner14internal_visitIdEEvRT_i(%"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %10, double* dereferenceable(8) %12, i32 1)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost7variantIiJjcdfEE13move_assigner14internal_visitIdEEvRT_i(%"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, double* dereferenceable(8), i32) #4 comdat align 2 {
  %4 = alloca %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, align 8
  %5 = alloca double*, align 8
  %6 = alloca i32, align 4
  %7 = alloca %"struct.mpl_::bool_.7", align 1
  %8 = alloca %"struct.mpl_::bool_.7", align 1
  %9 = alloca %"struct.boost::integral_constant", align 1
  %10 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  store %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %0, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %4, align 8
  store double* %1, double** %5, align 8
  store i32 %2, i32* %6, align 4
  %11 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %4, align 8
  %12 = load double*, double** %5, align 8
  %13 = call dereferenceable(1) %"struct.mpl_::bool_.7"* @_ZNK5boost17integral_constantIbLb1EEcvRKN4mpl_5bool_ILb1EEEEv(%"struct.boost::integral_constant"* %9)
  call void @_ZNK5boost7variantIiJjcdfEE13move_assigner11assign_implIdN4mpl_5bool_ILb1EEENS1_18has_fallback_type_EEEvRT_T0_S6_T1_(%"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %11, double* dereferenceable(8) %12) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost7variantIiJjcdfEE13move_assigner11assign_implIdN4mpl_5bool_ILb1EEENS1_18has_fallback_type_EEEvRT_T0_S6_T1_(%"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, double* dereferenceable(8)) #4 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %3 = alloca %"struct.mpl_::bool_.7", align 1
  %4 = alloca %"struct.mpl_::bool_.7", align 1
  %5 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %6 = alloca %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, align 8
  %7 = alloca double*, align 8
  store %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %0, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %6, align 8
  store double* %1, double** %7, align 8
  %8 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %6, align 8
  %9 = bitcast %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %8 to %"class.boost::variant<int, unsigned int, char, double, float>::assigner"*
  %10 = getelementptr inbounds %"class.boost::variant<int, unsigned int, char, double, float>::assigner", %"class.boost::variant<int, unsigned int, char, double, float>::assigner"* %9, i32 0, i32 0
  %11 = load %"class.boost::variant"*, %"class.boost::variant"** %10, align 8
  call void @_ZN5boost7variantIiJjcdfEE15destroy_contentEv(%"class.boost::variant"* %11) #3
  %12 = bitcast %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %8 to %"class.boost::variant<int, unsigned int, char, double, float>::assigner"*
  %13 = getelementptr inbounds %"class.boost::variant<int, unsigned int, char, double, float>::assigner", %"class.boost::variant<int, unsigned int, char, double, float>::assigner"* %12, i32 0, i32 0
  %14 = load %"class.boost::variant"*, %"class.boost::variant"** %13, align 8
  %15 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %14, i32 0, i32 2
  %16 = invoke i8* @_ZN5boost15aligned_storageILm8ELm8EE7addressEv(%"class.boost::aligned_storage"* %15)
          to label %17 unwind label %28

; <label>:17:                                     ; preds = %2
  %18 = bitcast i8* %16 to double*
  %19 = load double*, double** %7, align 8
  %20 = call dereferenceable(8) double* @_ZN5boost4moveIRdEEONS_11move_detail16remove_referenceIT_E4typeEOS4_(double* dereferenceable(8) %19) #3
  %21 = load double, double* %20, align 8
  store double %21, double* %18, align 8
  %22 = bitcast %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %8 to %"class.boost::variant<int, unsigned int, char, double, float>::assigner"*
  %23 = getelementptr inbounds %"class.boost::variant<int, unsigned int, char, double, float>::assigner", %"class.boost::variant<int, unsigned int, char, double, float>::assigner"* %22, i32 0, i32 0
  %24 = load %"class.boost::variant"*, %"class.boost::variant"** %23, align 8
  %25 = bitcast %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %8 to %"class.boost::variant<int, unsigned int, char, double, float>::assigner"*
  %26 = getelementptr inbounds %"class.boost::variant<int, unsigned int, char, double, float>::assigner", %"class.boost::variant<int, unsigned int, char, double, float>::assigner"* %25, i32 0, i32 1
  %27 = load i32, i32* %26, align 8
  call void @_ZN5boost7variantIiJjcdfEE14indicate_whichEi(%"class.boost::variant"* %24, i32 %27) #3
  ret void

; <label>:28:                                     ; preds = %2
  %29 = landingpad { i8*, i32 }
          catch i8* null
  %30 = extractvalue { i8*, i32 } %29, 0
  call void @__clang_call_terminate(i8* %30) #16
  unreachable
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS_7variantIiJjcdfEE13move_assignerEPvfEENT_11result_typeEiRS7_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* dereferenceable(16), i8*, float*) #5 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca float*, align 8
  store i32 %0, i32* %6, align 4
  store %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %1, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %7, align 8
  store i8* %2, i8** %8, align 8
  store float* %3, float** %9, align 8
  %10 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(4) float* @_ZN5boost6detail7variant12cast_storageIfEERT_Pv(i8* %11)
  call void @_ZNK5boost7variantIiJjcdfEE13move_assigner14internal_visitIfEEvRT_i(%"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %10, float* dereferenceable(4) %12, i32 1)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost7variantIiJjcdfEE13move_assigner14internal_visitIfEEvRT_i(%"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, float* dereferenceable(4), i32) #4 comdat align 2 {
  %4 = alloca %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, align 8
  %5 = alloca float*, align 8
  %6 = alloca i32, align 4
  %7 = alloca %"struct.mpl_::bool_.7", align 1
  %8 = alloca %"struct.mpl_::bool_.7", align 1
  %9 = alloca %"struct.boost::integral_constant", align 1
  %10 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  store %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %0, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %4, align 8
  store float* %1, float** %5, align 8
  store i32 %2, i32* %6, align 4
  %11 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %4, align 8
  %12 = load float*, float** %5, align 8
  %13 = call dereferenceable(1) %"struct.mpl_::bool_.7"* @_ZNK5boost17integral_constantIbLb1EEcvRKN4mpl_5bool_ILb1EEEEv(%"struct.boost::integral_constant"* %9)
  call void @_ZNK5boost7variantIiJjcdfEE13move_assigner11assign_implIfN4mpl_5bool_ILb1EEENS1_18has_fallback_type_EEEvRT_T0_S6_T1_(%"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %11, float* dereferenceable(4) %12) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost7variantIiJjcdfEE13move_assigner11assign_implIfN4mpl_5bool_ILb1EEENS1_18has_fallback_type_EEEvRT_T0_S6_T1_(%"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, float* dereferenceable(4)) #4 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %3 = alloca %"struct.mpl_::bool_.7", align 1
  %4 = alloca %"struct.mpl_::bool_.7", align 1
  %5 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %6 = alloca %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, align 8
  %7 = alloca float*, align 8
  store %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %0, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %6, align 8
  store float* %1, float** %7, align 8
  %8 = load %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"*, %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"** %6, align 8
  %9 = bitcast %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %8 to %"class.boost::variant<int, unsigned int, char, double, float>::assigner"*
  %10 = getelementptr inbounds %"class.boost::variant<int, unsigned int, char, double, float>::assigner", %"class.boost::variant<int, unsigned int, char, double, float>::assigner"* %9, i32 0, i32 0
  %11 = load %"class.boost::variant"*, %"class.boost::variant"** %10, align 8
  call void @_ZN5boost7variantIiJjcdfEE15destroy_contentEv(%"class.boost::variant"* %11) #3
  %12 = bitcast %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %8 to %"class.boost::variant<int, unsigned int, char, double, float>::assigner"*
  %13 = getelementptr inbounds %"class.boost::variant<int, unsigned int, char, double, float>::assigner", %"class.boost::variant<int, unsigned int, char, double, float>::assigner"* %12, i32 0, i32 0
  %14 = load %"class.boost::variant"*, %"class.boost::variant"** %13, align 8
  %15 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %14, i32 0, i32 2
  %16 = invoke i8* @_ZN5boost15aligned_storageILm8ELm8EE7addressEv(%"class.boost::aligned_storage"* %15)
          to label %17 unwind label %28

; <label>:17:                                     ; preds = %2
  %18 = bitcast i8* %16 to float*
  %19 = load float*, float** %7, align 8
  %20 = call dereferenceable(4) float* @_ZN5boost4moveIRfEEONS_11move_detail16remove_referenceIT_E4typeEOS4_(float* dereferenceable(4) %19) #3
  %21 = load float, float* %20, align 4
  store float %21, float* %18, align 4
  %22 = bitcast %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %8 to %"class.boost::variant<int, unsigned int, char, double, float>::assigner"*
  %23 = getelementptr inbounds %"class.boost::variant<int, unsigned int, char, double, float>::assigner", %"class.boost::variant<int, unsigned int, char, double, float>::assigner"* %22, i32 0, i32 0
  %24 = load %"class.boost::variant"*, %"class.boost::variant"** %23, align 8
  %25 = bitcast %"class.boost::variant<int, unsigned int, char, double, float>::move_assigner"* %8 to %"class.boost::variant<int, unsigned int, char, double, float>::assigner"*
  %26 = getelementptr inbounds %"class.boost::variant<int, unsigned int, char, double, float>::assigner", %"class.boost::variant<int, unsigned int, char, double, float>::assigner"* %25, i32 0, i32 1
  %27 = load i32, i32* %26, align 8
  call void @_ZN5boost7variantIiJjcdfEE14indicate_whichEi(%"class.boost::variant"* %24, i32 %27) #3
  ret void

; <label>:28:                                     ; preds = %2
  %29 = landingpad { i8*, i32 }
          catch i8* null
  %30 = extractvalue { i8*, i32 } %29, 0
  call void @__clang_call_terminate(i8* %30) #16
  unreachable
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS0_EEEC2Ev(%"class.std::map"*) unnamed_addr #4 comdat align 2 {
  %2 = alloca %"class.std::map"*, align 8
  store %"class.std::map"* %0, %"class.std::map"** %2, align 8
  %3 = load %"class.std::map"*, %"class.std::map"** %2, align 8
  %4 = getelementptr inbounds %"class.std::map", %"class.std::map"* %3, i32 0, i32 0
  call void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EEC2Ev(%"class.std::_Rb_tree"* %4) #3
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local { %"struct.std::_Rb_tree_node_base"*, i8 } @_ZNSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS0_EEE6insertIS3_IiS0_EEENSt9enable_ifIXsr16is_constructibleIS5_T_EE5valueES3_ISt17_Rb_tree_iteratorIS5_EbEE4typeEOSB_(%"class.std::map"*, %"struct.std::pair.17"* dereferenceable(64)) #5 comdat align 2 {
  %3 = alloca %"struct.std::pair.14", align 8
  %4 = alloca %"class.std::map"*, align 8
  %5 = alloca %"struct.std::pair.17"*, align 8
  store %"class.std::map"* %0, %"class.std::map"** %4, align 8
  store %"struct.std::pair.17"* %1, %"struct.std::pair.17"** %5, align 8
  %6 = load %"class.std::map"*, %"class.std::map"** %4, align 8
  %7 = getelementptr inbounds %"class.std::map", %"class.std::map"* %6, i32 0, i32 0
  %8 = load %"struct.std::pair.17"*, %"struct.std::pair.17"** %5, align 8
  %9 = call dereferenceable(64) %"struct.std::pair.17"* @_ZSt7forwardISt4pairIi9NonDetLogEEOT_RNSt16remove_referenceIS3_E4typeE(%"struct.std::pair.17"* dereferenceable(64) %8) #3
  %10 = call { %"struct.std::_Rb_tree_node_base"*, i8 } @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE17_M_emplace_uniqueIJS0_IiS2_EEEES0_ISt17_Rb_tree_iteratorIS3_EbEDpOT_(%"class.std::_Rb_tree"* %7, %"struct.std::pair.17"* dereferenceable(64) %9)
  %11 = bitcast %"struct.std::pair.14"* %3 to { %"struct.std::_Rb_tree_node_base"*, i8 }*
  %12 = getelementptr inbounds { %"struct.std::_Rb_tree_node_base"*, i8 }, { %"struct.std::_Rb_tree_node_base"*, i8 }* %11, i32 0, i32 0
  %13 = extractvalue { %"struct.std::_Rb_tree_node_base"*, i8 } %10, 0
  store %"struct.std::_Rb_tree_node_base"* %13, %"struct.std::_Rb_tree_node_base"** %12, align 8
  %14 = getelementptr inbounds { %"struct.std::_Rb_tree_node_base"*, i8 }, { %"struct.std::_Rb_tree_node_base"*, i8 }* %11, i32 0, i32 1
  %15 = extractvalue { %"struct.std::_Rb_tree_node_base"*, i8 } %10, 1
  store i8 %15, i8* %14, align 8
  %16 = bitcast %"struct.std::pair.14"* %3 to { %"struct.std::_Rb_tree_node_base"*, i8 }*
  %17 = load { %"struct.std::_Rb_tree_node_base"*, i8 }, { %"struct.std::_Rb_tree_node_base"*, i8 }* %16, align 8
  ret { %"struct.std::_Rb_tree_node_base"*, i8 } %17
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZNSt4pairIi9NonDetLogEC2IRiRS0_Lb1EEEOT_OT0_(%"struct.std::pair.17"*, i32* dereferenceable(4), %class.NonDetLog* dereferenceable(56)) unnamed_addr #5 comdat align 2 {
  %4 = alloca %"struct.std::pair.17"*, align 8
  %5 = alloca i32*, align 8
  %6 = alloca %class.NonDetLog*, align 8
  store %"struct.std::pair.17"* %0, %"struct.std::pair.17"** %4, align 8
  store i32* %1, i32** %5, align 8
  store %class.NonDetLog* %2, %class.NonDetLog** %6, align 8
  %7 = load %"struct.std::pair.17"*, %"struct.std::pair.17"** %4, align 8
  %8 = bitcast %"struct.std::pair.17"* %7 to %"class.std::__pair_base.18"*
  %9 = getelementptr inbounds %"struct.std::pair.17", %"struct.std::pair.17"* %7, i32 0, i32 0
  %10 = load i32*, i32** %5, align 8
  %11 = call dereferenceable(4) i32* @_ZSt7forwardIRiEOT_RNSt16remove_referenceIS1_E4typeE(i32* dereferenceable(4) %10) #3
  %12 = load i32, i32* %11, align 4
  store i32 %12, i32* %9, align 8
  %13 = getelementptr inbounds %"struct.std::pair.17", %"struct.std::pair.17"* %7, i32 0, i32 1
  %14 = load %class.NonDetLog*, %class.NonDetLog** %6, align 8
  %15 = call dereferenceable(56) %class.NonDetLog* @_ZSt7forwardIR9NonDetLogEOT_RNSt16remove_referenceIS2_E4typeE(%class.NonDetLog* dereferenceable(56) %14) #3
  call void @_ZN9NonDetLogC2ERKS_(%class.NonDetLog* %13, %class.NonDetLog* dereferenceable(56) %15)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt4pairIi9NonDetLogED2Ev(%"struct.std::pair.17"*) unnamed_addr #4 comdat align 2 {
  %2 = alloca %"struct.std::pair.17"*, align 8
  store %"struct.std::pair.17"* %0, %"struct.std::pair.17"** %2, align 8
  %3 = load %"struct.std::pair.17"*, %"struct.std::pair.17"** %2, align 8
  %4 = getelementptr inbounds %"struct.std::pair.17", %"struct.std::pair.17"* %3, i32 0, i32 1
  call void @_ZN9NonDetLogD2Ev(%class.NonDetLog* %4) #3
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZNSt7__cxx114listISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE9push_backERKS9_(%"class.std::__cxx11::list"*, %"class.std::map"* dereferenceable(48)) #5 comdat align 2 {
  %3 = alloca %"class.std::__cxx11::list"*, align 8
  %4 = alloca %"class.std::map"*, align 8
  %5 = alloca %"struct.std::_List_iterator", align 8
  store %"class.std::__cxx11::list"* %0, %"class.std::__cxx11::list"** %3, align 8
  store %"class.std::map"* %1, %"class.std::map"** %4, align 8
  %6 = load %"class.std::__cxx11::list"*, %"class.std::__cxx11::list"** %3, align 8
  %7 = call %"struct.std::__detail::_List_node_base"* @_ZNSt7__cxx114listISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE3endEv(%"class.std::__cxx11::list"* %6) #3
  %8 = getelementptr inbounds %"struct.std::_List_iterator", %"struct.std::_List_iterator"* %5, i32 0, i32 0
  store %"struct.std::__detail::_List_node_base"* %7, %"struct.std::__detail::_List_node_base"** %8, align 8
  %9 = load %"class.std::map"*, %"class.std::map"** %4, align 8
  %10 = getelementptr inbounds %"struct.std::_List_iterator", %"struct.std::_List_iterator"* %5, i32 0, i32 0
  %11 = load %"struct.std::__detail::_List_node_base"*, %"struct.std::__detail::_List_node_base"** %10, align 8
  call void @_ZNSt7__cxx114listISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE9_M_insertIJRKS9_EEEvSt14_List_iteratorIS9_EDpOT_(%"class.std::__cxx11::list"* %6, %"struct.std::__detail::_List_node_base"* %11, %"class.std::map"* dereferenceable(48) %9)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EEC2Ev(%"class.std::_Rb_tree"*) unnamed_addr #4 comdat align 2 {
  %2 = alloca %"class.std::_Rb_tree"*, align 8
  store %"class.std::_Rb_tree"* %0, %"class.std::_Rb_tree"** %2, align 8
  %3 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %2, align 8
  %4 = getelementptr inbounds %"class.std::_Rb_tree", %"class.std::_Rb_tree"* %3, i32 0, i32 0
  call void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE13_Rb_tree_implIS7_Lb1EEC2Ev(%"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %4) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE13_Rb_tree_implIS7_Lb1EEC2Ev(%"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"*) unnamed_addr #4 comdat align 2 {
  %2 = alloca %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"*, align 8
  store %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %0, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"** %2, align 8
  %3 = load %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"*, %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"** %2, align 8
  %4 = bitcast %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %3 to %"class.std::allocator.3"*
  call void @_ZNSaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEC2Ev(%"class.std::allocator.3"* %4) #3
  %5 = bitcast %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %3 to %"struct.std::_Rb_tree_key_compare"*
  call void @_ZNSt20_Rb_tree_key_compareISt4lessIiEEC2Ev(%"struct.std::_Rb_tree_key_compare"* %5) #3
  %6 = bitcast %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %3 to i8*
  %7 = getelementptr inbounds i8, i8* %6, i64 8
  %8 = bitcast i8* %7 to %"struct.std::_Rb_tree_header"*
  call void @_ZNSt15_Rb_tree_headerC2Ev(%"struct.std::_Rb_tree_header"* %8) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEC2Ev(%"class.std::allocator.3"*) unnamed_addr #4 comdat align 2 {
  %2 = alloca %"class.std::allocator.3"*, align 8
  store %"class.std::allocator.3"* %0, %"class.std::allocator.3"** %2, align 8
  %3 = load %"class.std::allocator.3"*, %"class.std::allocator.3"** %2, align 8
  %4 = bitcast %"class.std::allocator.3"* %3 to %"class.__gnu_cxx::new_allocator.4"*
  call void @_ZN9__gnu_cxx13new_allocatorISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEC2Ev(%"class.__gnu_cxx::new_allocator.4"* %4) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt20_Rb_tree_key_compareISt4lessIiEEC2Ev(%"struct.std::_Rb_tree_key_compare"*) unnamed_addr #4 comdat align 2 {
  %2 = alloca %"struct.std::_Rb_tree_key_compare"*, align 8
  store %"struct.std::_Rb_tree_key_compare"* %0, %"struct.std::_Rb_tree_key_compare"** %2, align 8
  %3 = load %"struct.std::_Rb_tree_key_compare"*, %"struct.std::_Rb_tree_key_compare"** %2, align 8
  %4 = getelementptr inbounds %"struct.std::_Rb_tree_key_compare", %"struct.std::_Rb_tree_key_compare"* %3, i32 0, i32 0
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN9__gnu_cxx13new_allocatorISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEC2Ev(%"class.__gnu_cxx::new_allocator.4"*) unnamed_addr #4 comdat align 2 {
  %2 = alloca %"class.__gnu_cxx::new_allocator.4"*, align 8
  store %"class.__gnu_cxx::new_allocator.4"* %0, %"class.__gnu_cxx::new_allocator.4"** %2, align 8
  %3 = load %"class.__gnu_cxx::new_allocator.4"*, %"class.__gnu_cxx::new_allocator.4"** %2, align 8
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local { %"struct.std::_Rb_tree_node_base"*, i8 } @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE17_M_emplace_uniqueIJS0_IiS2_EEEES0_ISt17_Rb_tree_iteratorIS3_EbEDpOT_(%"class.std::_Rb_tree"*, %"struct.std::pair.17"* dereferenceable(64)) #5 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %3 = alloca %"struct.std::pair.14", align 8
  %4 = alloca %"class.std::_Rb_tree"*, align 8
  %5 = alloca %"struct.std::pair.17"*, align 8
  %6 = alloca %"struct.std::_Rb_tree_node"*, align 8
  %7 = alloca %"struct.std::pair.20", align 8
  %8 = alloca i8*
  %9 = alloca i32
  %10 = alloca %"struct.std::_Rb_tree_iterator", align 8
  %11 = alloca i8, align 1
  %12 = alloca %"struct.std::_Rb_tree_iterator", align 8
  %13 = alloca i8, align 1
  store %"class.std::_Rb_tree"* %0, %"class.std::_Rb_tree"** %4, align 8
  store %"struct.std::pair.17"* %1, %"struct.std::pair.17"** %5, align 8
  %14 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %4, align 8
  %15 = load %"struct.std::pair.17"*, %"struct.std::pair.17"** %5, align 8
  %16 = call dereferenceable(64) %"struct.std::pair.17"* @_ZSt7forwardISt4pairIi9NonDetLogEEOT_RNSt16remove_referenceIS3_E4typeE(%"struct.std::pair.17"* dereferenceable(64) %15) #3
  %17 = call %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE14_M_create_nodeIJS0_IiS2_EEEEPSt13_Rb_tree_nodeIS3_EDpOT_(%"class.std::_Rb_tree"* %14, %"struct.std::pair.17"* dereferenceable(64) %16)
  store %"struct.std::_Rb_tree_node"* %17, %"struct.std::_Rb_tree_node"** %6, align 8
  %18 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %6, align 8
  %19 = invoke dereferenceable(4) i32* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE6_S_keyEPKSt13_Rb_tree_nodeIS3_E(%"struct.std::_Rb_tree_node"* %18)
          to label %20 unwind label %41

; <label>:20:                                     ; preds = %2
  %21 = invoke { %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"* } @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE24_M_get_insert_unique_posERS1_(%"class.std::_Rb_tree"* %14, i32* dereferenceable(4) %19)
          to label %22 unwind label %41

; <label>:22:                                     ; preds = %20
  %23 = bitcast %"struct.std::pair.20"* %7 to { %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"* }*
  %24 = getelementptr inbounds { %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"* }, { %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"* }* %23, i32 0, i32 0
  %25 = extractvalue { %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"* } %21, 0
  store %"struct.std::_Rb_tree_node_base"* %25, %"struct.std::_Rb_tree_node_base"** %24, align 8
  %26 = getelementptr inbounds { %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"* }, { %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"* }* %23, i32 0, i32 1
  %27 = extractvalue { %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"* } %21, 1
  store %"struct.std::_Rb_tree_node_base"* %27, %"struct.std::_Rb_tree_node_base"** %26, align 8
  %28 = getelementptr inbounds %"struct.std::pair.20", %"struct.std::pair.20"* %7, i32 0, i32 1
  %29 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %28, align 8
  %30 = icmp ne %"struct.std::_Rb_tree_node_base"* %29, null
  br i1 %30, label %31, label %49

; <label>:31:                                     ; preds = %22
  %32 = getelementptr inbounds %"struct.std::pair.20", %"struct.std::pair.20"* %7, i32 0, i32 0
  %33 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %32, align 8
  %34 = getelementptr inbounds %"struct.std::pair.20", %"struct.std::pair.20"* %7, i32 0, i32 1
  %35 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %34, align 8
  %36 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %6, align 8
  %37 = invoke %"struct.std::_Rb_tree_node_base"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE14_M_insert_nodeEPSt18_Rb_tree_node_baseSB_PSt13_Rb_tree_nodeIS3_E(%"class.std::_Rb_tree"* %14, %"struct.std::_Rb_tree_node_base"* %33, %"struct.std::_Rb_tree_node_base"* %35, %"struct.std::_Rb_tree_node"* %36)
          to label %38 unwind label %41

; <label>:38:                                     ; preds = %31
  %39 = getelementptr inbounds %"struct.std::_Rb_tree_iterator", %"struct.std::_Rb_tree_iterator"* %10, i32 0, i32 0
  store %"struct.std::_Rb_tree_node_base"* %37, %"struct.std::_Rb_tree_node_base"** %39, align 8
  store i8 1, i8* %11, align 1
  invoke void @_ZNSt4pairISt17_Rb_tree_iteratorIS_IKi9NonDetLogEEbEC2IS4_bLb1EEEOT_OT0_(%"struct.std::pair.14"* %3, %"struct.std::_Rb_tree_iterator"* dereferenceable(8) %10, i8* dereferenceable(1) %11)
          to label %40 unwind label %41

; <label>:40:                                     ; preds = %38
  br label %60

; <label>:41:                                     ; preds = %49, %38, %31, %20, %2
  %42 = landingpad { i8*, i32 }
          catch i8* null
  %43 = extractvalue { i8*, i32 } %42, 0
  store i8* %43, i8** %8, align 8
  %44 = extractvalue { i8*, i32 } %42, 1
  store i32 %44, i32* %9, align 4
  br label %45

; <label>:45:                                     ; preds = %41
  %46 = load i8*, i8** %8, align 8
  %47 = call i8* @__cxa_begin_catch(i8* %46) #3
  %48 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %6, align 8
  call void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE12_M_drop_nodeEPSt13_Rb_tree_nodeIS3_E(%"class.std::_Rb_tree"* %14, %"struct.std::_Rb_tree_node"* %48) #3
  invoke void @__cxa_rethrow() #17
          to label %71 unwind label %54

; <label>:49:                                     ; preds = %22
  %50 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %6, align 8
  call void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE12_M_drop_nodeEPSt13_Rb_tree_nodeIS3_E(%"class.std::_Rb_tree"* %14, %"struct.std::_Rb_tree_node"* %50) #3
  %51 = getelementptr inbounds %"struct.std::pair.20", %"struct.std::pair.20"* %7, i32 0, i32 0
  %52 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %51, align 8
  call void @_ZNSt17_Rb_tree_iteratorISt4pairIKi9NonDetLogEEC2EPSt18_Rb_tree_node_base(%"struct.std::_Rb_tree_iterator"* %12, %"struct.std::_Rb_tree_node_base"* %52) #3
  store i8 0, i8* %13, align 1
  invoke void @_ZNSt4pairISt17_Rb_tree_iteratorIS_IKi9NonDetLogEEbEC2IS4_bLb1EEEOT_OT0_(%"struct.std::pair.14"* %3, %"struct.std::_Rb_tree_iterator"* dereferenceable(8) %12, i8* dereferenceable(1) %13)
          to label %53 unwind label %41

; <label>:53:                                     ; preds = %49
  br label %60

; <label>:54:                                     ; preds = %45
  %55 = landingpad { i8*, i32 }
          cleanup
  %56 = extractvalue { i8*, i32 } %55, 0
  store i8* %56, i8** %8, align 8
  %57 = extractvalue { i8*, i32 } %55, 1
  store i32 %57, i32* %9, align 4
  invoke void @__cxa_end_catch()
          to label %58 unwind label %68

; <label>:58:                                     ; preds = %54
  br label %63
                                                  ; No predecessors!
  call void @llvm.trap()
  unreachable

; <label>:60:                                     ; preds = %53, %40
  %61 = bitcast %"struct.std::pair.14"* %3 to { %"struct.std::_Rb_tree_node_base"*, i8 }*
  %62 = load { %"struct.std::_Rb_tree_node_base"*, i8 }, { %"struct.std::_Rb_tree_node_base"*, i8 }* %61, align 8
  ret { %"struct.std::_Rb_tree_node_base"*, i8 } %62

; <label>:63:                                     ; preds = %58
  %64 = load i8*, i8** %8, align 8
  %65 = load i32, i32* %9, align 4
  %66 = insertvalue { i8*, i32 } undef, i8* %64, 0
  %67 = insertvalue { i8*, i32 } %66, i32 %65, 1
  resume { i8*, i32 } %67

; <label>:68:                                     ; preds = %54
  %69 = landingpad { i8*, i32 }
          catch i8* null
  %70 = extractvalue { i8*, i32 } %69, 0
  call void @__clang_call_terminate(i8* %70) #16
  unreachable

; <label>:71:                                     ; preds = %45
  unreachable
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(64) %"struct.std::pair.17"* @_ZSt7forwardISt4pairIi9NonDetLogEEOT_RNSt16remove_referenceIS3_E4typeE(%"struct.std::pair.17"* dereferenceable(64)) #4 comdat {
  %2 = alloca %"struct.std::pair.17"*, align 8
  store %"struct.std::pair.17"* %0, %"struct.std::pair.17"** %2, align 8
  %3 = load %"struct.std::pair.17"*, %"struct.std::pair.17"** %2, align 8
  ret %"struct.std::pair.17"* %3
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE14_M_create_nodeIJS0_IiS2_EEEEPSt13_Rb_tree_nodeIS3_EDpOT_(%"class.std::_Rb_tree"*, %"struct.std::pair.17"* dereferenceable(64)) #5 comdat align 2 {
  %3 = alloca %"class.std::_Rb_tree"*, align 8
  %4 = alloca %"struct.std::pair.17"*, align 8
  %5 = alloca %"struct.std::_Rb_tree_node"*, align 8
  store %"class.std::_Rb_tree"* %0, %"class.std::_Rb_tree"** %3, align 8
  store %"struct.std::pair.17"* %1, %"struct.std::pair.17"** %4, align 8
  %6 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %3, align 8
  %7 = call %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE11_M_get_nodeEv(%"class.std::_Rb_tree"* %6)
  store %"struct.std::_Rb_tree_node"* %7, %"struct.std::_Rb_tree_node"** %5, align 8
  %8 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %5, align 8
  %9 = load %"struct.std::pair.17"*, %"struct.std::pair.17"** %4, align 8
  %10 = call dereferenceable(64) %"struct.std::pair.17"* @_ZSt7forwardISt4pairIi9NonDetLogEEOT_RNSt16remove_referenceIS3_E4typeE(%"struct.std::pair.17"* dereferenceable(64) %9) #3
  call void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE17_M_construct_nodeIJS0_IiS2_EEEEvPSt13_Rb_tree_nodeIS3_EDpOT_(%"class.std::_Rb_tree"* %6, %"struct.std::_Rb_tree_node"* %8, %"struct.std::pair.17"* dereferenceable(64) %10)
  %11 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %5, align 8
  ret %"struct.std::_Rb_tree_node"* %11
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local { %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"* } @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE24_M_get_insert_unique_posERS1_(%"class.std::_Rb_tree"*, i32* dereferenceable(4)) #5 comdat align 2 {
  %3 = alloca %"struct.std::pair.20", align 8
  %4 = alloca %"class.std::_Rb_tree"*, align 8
  %5 = alloca i32*, align 8
  %6 = alloca %"struct.std::_Rb_tree_node"*, align 8
  %7 = alloca %"struct.std::_Rb_tree_node_base"*, align 8
  %8 = alloca i8, align 1
  %9 = alloca %"struct.std::_Rb_tree_iterator", align 8
  %10 = alloca %"struct.std::_Rb_tree_iterator", align 8
  %11 = alloca %"struct.std::_Rb_tree_node_base"*, align 8
  store %"class.std::_Rb_tree"* %0, %"class.std::_Rb_tree"** %4, align 8
  store i32* %1, i32** %5, align 8
  %12 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %4, align 8
  %13 = call %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE8_M_beginEv(%"class.std::_Rb_tree"* %12) #3
  store %"struct.std::_Rb_tree_node"* %13, %"struct.std::_Rb_tree_node"** %6, align 8
  %14 = call %"struct.std::_Rb_tree_node_base"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE6_M_endEv(%"class.std::_Rb_tree"* %12) #3
  store %"struct.std::_Rb_tree_node_base"* %14, %"struct.std::_Rb_tree_node_base"** %7, align 8
  store i8 1, i8* %8, align 1
  br label %15

; <label>:15:                                     ; preds = %39, %2
  %16 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %6, align 8
  %17 = icmp ne %"struct.std::_Rb_tree_node"* %16, null
  br i1 %17, label %18, label %41

; <label>:18:                                     ; preds = %15
  %19 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %6, align 8
  %20 = bitcast %"struct.std::_Rb_tree_node"* %19 to %"struct.std::_Rb_tree_node_base"*
  store %"struct.std::_Rb_tree_node_base"* %20, %"struct.std::_Rb_tree_node_base"** %7, align 8
  %21 = getelementptr inbounds %"class.std::_Rb_tree", %"class.std::_Rb_tree"* %12, i32 0, i32 0
  %22 = bitcast %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %21 to %"struct.std::_Rb_tree_key_compare"*
  %23 = getelementptr inbounds %"struct.std::_Rb_tree_key_compare", %"struct.std::_Rb_tree_key_compare"* %22, i32 0, i32 0
  %24 = load i32*, i32** %5, align 8
  %25 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %6, align 8
  %26 = call dereferenceable(4) i32* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE6_S_keyEPKSt13_Rb_tree_nodeIS3_E(%"struct.std::_Rb_tree_node"* %25)
  %27 = call zeroext i1 @_ZNKSt4lessIiEclERKiS2_(%"struct.std::less"* %23, i32* dereferenceable(4) %24, i32* dereferenceable(4) %26)
  %28 = zext i1 %27 to i8
  store i8 %28, i8* %8, align 1
  %29 = load i8, i8* %8, align 1
  %30 = trunc i8 %29 to i1
  br i1 %30, label %31, label %35

; <label>:31:                                     ; preds = %18
  %32 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %6, align 8
  %33 = bitcast %"struct.std::_Rb_tree_node"* %32 to %"struct.std::_Rb_tree_node_base"*
  %34 = call %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE7_S_leftEPSt18_Rb_tree_node_base(%"struct.std::_Rb_tree_node_base"* %33) #3
  br label %39

; <label>:35:                                     ; preds = %18
  %36 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %6, align 8
  %37 = bitcast %"struct.std::_Rb_tree_node"* %36 to %"struct.std::_Rb_tree_node_base"*
  %38 = call %"struct.std::_Rb_tree_node"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE8_S_rightEPSt18_Rb_tree_node_base(%"struct.std::_Rb_tree_node_base"* %37) #3
  br label %39

; <label>:39:                                     ; preds = %35, %31
  %40 = phi %"struct.std::_Rb_tree_node"* [ %34, %31 ], [ %38, %35 ]
  store %"struct.std::_Rb_tree_node"* %40, %"struct.std::_Rb_tree_node"** %6, align 8
  br label %15

; <label>:41:                                     ; preds = %15
  %42 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %7, align 8
  call void @_ZNSt17_Rb_tree_iteratorISt4pairIKi9NonDetLogEEC2EPSt18_Rb_tree_node_base(%"struct.std::_Rb_tree_iterator"* %9, %"struct.std::_Rb_tree_node_base"* %42) #3
  %43 = load i8, i8* %8, align 1
  %44 = trunc i8 %43 to i1
  br i1 %44, label %45, label %53

; <label>:45:                                     ; preds = %41
  %46 = call %"struct.std::_Rb_tree_node_base"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE5beginEv(%"class.std::_Rb_tree"* %12) #3
  %47 = getelementptr inbounds %"struct.std::_Rb_tree_iterator", %"struct.std::_Rb_tree_iterator"* %10, i32 0, i32 0
  store %"struct.std::_Rb_tree_node_base"* %46, %"struct.std::_Rb_tree_node_base"** %47, align 8
  %48 = call zeroext i1 @_ZSteqRKSt17_Rb_tree_iteratorISt4pairIKi9NonDetLogEES6_(%"struct.std::_Rb_tree_iterator"* dereferenceable(8) %9, %"struct.std::_Rb_tree_iterator"* dereferenceable(8) %10) #3
  br i1 %48, label %49, label %50

; <label>:49:                                     ; preds = %45
  call void @_ZNSt4pairIPSt18_Rb_tree_node_baseS1_EC2IRPSt13_Rb_tree_nodeIS_IKi9NonDetLogEERS1_Lb1EEEOT_OT0_(%"struct.std::pair.20"* %3, %"struct.std::_Rb_tree_node"** dereferenceable(8) %6, %"struct.std::_Rb_tree_node_base"** dereferenceable(8) %7)
  br label %65

; <label>:50:                                     ; preds = %45
  %51 = call dereferenceable(8) %"struct.std::_Rb_tree_iterator"* @_ZNSt17_Rb_tree_iteratorISt4pairIKi9NonDetLogEEmmEv(%"struct.std::_Rb_tree_iterator"* %9) #3
  br label %52

; <label>:52:                                     ; preds = %50
  br label %53

; <label>:53:                                     ; preds = %52, %41
  %54 = getelementptr inbounds %"class.std::_Rb_tree", %"class.std::_Rb_tree"* %12, i32 0, i32 0
  %55 = bitcast %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %54 to %"struct.std::_Rb_tree_key_compare"*
  %56 = getelementptr inbounds %"struct.std::_Rb_tree_key_compare", %"struct.std::_Rb_tree_key_compare"* %55, i32 0, i32 0
  %57 = getelementptr inbounds %"struct.std::_Rb_tree_iterator", %"struct.std::_Rb_tree_iterator"* %9, i32 0, i32 0
  %58 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %57, align 8
  %59 = call dereferenceable(4) i32* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE6_S_keyEPKSt18_Rb_tree_node_base(%"struct.std::_Rb_tree_node_base"* %58)
  %60 = load i32*, i32** %5, align 8
  %61 = call zeroext i1 @_ZNKSt4lessIiEclERKiS2_(%"struct.std::less"* %56, i32* dereferenceable(4) %59, i32* dereferenceable(4) %60)
  br i1 %61, label %62, label %63

; <label>:62:                                     ; preds = %53
  call void @_ZNSt4pairIPSt18_Rb_tree_node_baseS1_EC2IRPSt13_Rb_tree_nodeIS_IKi9NonDetLogEERS1_Lb1EEEOT_OT0_(%"struct.std::pair.20"* %3, %"struct.std::_Rb_tree_node"** dereferenceable(8) %6, %"struct.std::_Rb_tree_node_base"** dereferenceable(8) %7)
  br label %65

; <label>:63:                                     ; preds = %53
  %64 = getelementptr inbounds %"struct.std::_Rb_tree_iterator", %"struct.std::_Rb_tree_iterator"* %9, i32 0, i32 0
  store %"struct.std::_Rb_tree_node_base"* null, %"struct.std::_Rb_tree_node_base"** %11, align 8
  call void @_ZNSt4pairIPSt18_Rb_tree_node_baseS1_EC2IRS1_Lb1EEEOT_RKS1_(%"struct.std::pair.20"* %3, %"struct.std::_Rb_tree_node_base"** dereferenceable(8) %64, %"struct.std::_Rb_tree_node_base"** dereferenceable(8) %11)
  br label %65

; <label>:65:                                     ; preds = %63, %62, %49
  %66 = bitcast %"struct.std::pair.20"* %3 to { %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"* }*
  %67 = load { %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"* }, { %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"* }* %66, align 8
  ret { %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"* } %67
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local dereferenceable(4) i32* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE6_S_keyEPKSt13_Rb_tree_nodeIS3_E(%"struct.std::_Rb_tree_node"*) #5 comdat align 2 {
  %2 = alloca %"struct.std::_Rb_tree_node"*, align 8
  %3 = alloca %"struct.std::_Select1st", align 1
  store %"struct.std::_Rb_tree_node"* %0, %"struct.std::_Rb_tree_node"** %2, align 8
  %4 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %2, align 8
  %5 = call %"struct.std::pair"* @_ZNKSt13_Rb_tree_nodeISt4pairIKi9NonDetLogEE9_M_valptrEv(%"struct.std::_Rb_tree_node"* %4)
  %6 = call dereferenceable(4) i32* @_ZNKSt10_Select1stISt4pairIKi9NonDetLogEEclERKS3_(%"struct.std::_Select1st"* %3, %"struct.std::pair"* dereferenceable(64) %5)
  ret i32* %6
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local %"struct.std::_Rb_tree_node_base"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE14_M_insert_nodeEPSt18_Rb_tree_node_baseSB_PSt13_Rb_tree_nodeIS3_E(%"class.std::_Rb_tree"*, %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node"*) #5 comdat align 2 {
  %5 = alloca %"struct.std::_Rb_tree_iterator", align 8
  %6 = alloca %"class.std::_Rb_tree"*, align 8
  %7 = alloca %"struct.std::_Rb_tree_node_base"*, align 8
  %8 = alloca %"struct.std::_Rb_tree_node_base"*, align 8
  %9 = alloca %"struct.std::_Rb_tree_node"*, align 8
  %10 = alloca i8, align 1
  store %"class.std::_Rb_tree"* %0, %"class.std::_Rb_tree"** %6, align 8
  store %"struct.std::_Rb_tree_node_base"* %1, %"struct.std::_Rb_tree_node_base"** %7, align 8
  store %"struct.std::_Rb_tree_node_base"* %2, %"struct.std::_Rb_tree_node_base"** %8, align 8
  store %"struct.std::_Rb_tree_node"* %3, %"struct.std::_Rb_tree_node"** %9, align 8
  %11 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %6, align 8
  %12 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %7, align 8
  %13 = icmp ne %"struct.std::_Rb_tree_node_base"* %12, null
  br i1 %13, label %27, label %14

; <label>:14:                                     ; preds = %4
  %15 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %8, align 8
  %16 = call %"struct.std::_Rb_tree_node_base"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE6_M_endEv(%"class.std::_Rb_tree"* %11) #3
  %17 = icmp eq %"struct.std::_Rb_tree_node_base"* %15, %16
  br i1 %17, label %27, label %18

; <label>:18:                                     ; preds = %14
  %19 = getelementptr inbounds %"class.std::_Rb_tree", %"class.std::_Rb_tree"* %11, i32 0, i32 0
  %20 = bitcast %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %19 to %"struct.std::_Rb_tree_key_compare"*
  %21 = getelementptr inbounds %"struct.std::_Rb_tree_key_compare", %"struct.std::_Rb_tree_key_compare"* %20, i32 0, i32 0
  %22 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %9, align 8
  %23 = call dereferenceable(4) i32* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE6_S_keyEPKSt13_Rb_tree_nodeIS3_E(%"struct.std::_Rb_tree_node"* %22)
  %24 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %8, align 8
  %25 = call dereferenceable(4) i32* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE6_S_keyEPKSt18_Rb_tree_node_base(%"struct.std::_Rb_tree_node_base"* %24)
  %26 = call zeroext i1 @_ZNKSt4lessIiEclERKiS2_(%"struct.std::less"* %21, i32* dereferenceable(4) %23, i32* dereferenceable(4) %25)
  br label %27

; <label>:27:                                     ; preds = %18, %14, %4
  %28 = phi i1 [ true, %14 ], [ true, %4 ], [ %26, %18 ]
  %29 = zext i1 %28 to i8
  store i8 %29, i8* %10, align 1
  %30 = load i8, i8* %10, align 1
  %31 = trunc i8 %30 to i1
  %32 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %9, align 8
  %33 = bitcast %"struct.std::_Rb_tree_node"* %32 to %"struct.std::_Rb_tree_node_base"*
  %34 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %8, align 8
  %35 = getelementptr inbounds %"class.std::_Rb_tree", %"class.std::_Rb_tree"* %11, i32 0, i32 0
  %36 = bitcast %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %35 to i8*
  %37 = getelementptr inbounds i8, i8* %36, i64 8
  %38 = bitcast i8* %37 to %"struct.std::_Rb_tree_header"*
  %39 = getelementptr inbounds %"struct.std::_Rb_tree_header", %"struct.std::_Rb_tree_header"* %38, i32 0, i32 0
  call void @_ZSt29_Rb_tree_insert_and_rebalancebPSt18_Rb_tree_node_baseS0_RS_(i1 zeroext %31, %"struct.std::_Rb_tree_node_base"* %33, %"struct.std::_Rb_tree_node_base"* %34, %"struct.std::_Rb_tree_node_base"* dereferenceable(32) %39) #3
  %40 = getelementptr inbounds %"class.std::_Rb_tree", %"class.std::_Rb_tree"* %11, i32 0, i32 0
  %41 = bitcast %"struct.std::_Rb_tree<int, std::pair<const int, NonDetLog>, std::_Select1st<std::pair<const int, NonDetLog> >, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >::_Rb_tree_impl"* %40 to i8*
  %42 = getelementptr inbounds i8, i8* %41, i64 8
  %43 = bitcast i8* %42 to %"struct.std::_Rb_tree_header"*
  %44 = getelementptr inbounds %"struct.std::_Rb_tree_header", %"struct.std::_Rb_tree_header"* %43, i32 0, i32 1
  %45 = load i64, i64* %44, align 8
  %46 = add i64 %45, 1
  store i64 %46, i64* %44, align 8
  %47 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %9, align 8
  %48 = bitcast %"struct.std::_Rb_tree_node"* %47 to %"struct.std::_Rb_tree_node_base"*
  call void @_ZNSt17_Rb_tree_iteratorISt4pairIKi9NonDetLogEEC2EPSt18_Rb_tree_node_base(%"struct.std::_Rb_tree_iterator"* %5, %"struct.std::_Rb_tree_node_base"* %48) #3
  %49 = getelementptr inbounds %"struct.std::_Rb_tree_iterator", %"struct.std::_Rb_tree_iterator"* %5, i32 0, i32 0
  %50 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %49, align 8
  ret %"struct.std::_Rb_tree_node_base"* %50
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt4pairISt17_Rb_tree_iteratorIS_IKi9NonDetLogEEbEC2IS4_bLb1EEEOT_OT0_(%"struct.std::pair.14"*, %"struct.std::_Rb_tree_iterator"* dereferenceable(8), i8* dereferenceable(1)) unnamed_addr #4 comdat align 2 {
  %4 = alloca %"struct.std::pair.14"*, align 8
  %5 = alloca %"struct.std::_Rb_tree_iterator"*, align 8
  %6 = alloca i8*, align 8
  store %"struct.std::pair.14"* %0, %"struct.std::pair.14"** %4, align 8
  store %"struct.std::_Rb_tree_iterator"* %1, %"struct.std::_Rb_tree_iterator"** %5, align 8
  store i8* %2, i8** %6, align 8
  %7 = load %"struct.std::pair.14"*, %"struct.std::pair.14"** %4, align 8
  %8 = bitcast %"struct.std::pair.14"* %7 to %"class.std::__pair_base.15"*
  %9 = getelementptr inbounds %"struct.std::pair.14", %"struct.std::pair.14"* %7, i32 0, i32 0
  %10 = load %"struct.std::_Rb_tree_iterator"*, %"struct.std::_Rb_tree_iterator"** %5, align 8
  %11 = call dereferenceable(8) %"struct.std::_Rb_tree_iterator"* @_ZSt7forwardISt17_Rb_tree_iteratorISt4pairIKi9NonDetLogEEEOT_RNSt16remove_referenceIS6_E4typeE(%"struct.std::_Rb_tree_iterator"* dereferenceable(8) %10) #3
  %12 = bitcast %"struct.std::_Rb_tree_iterator"* %9 to i8*
  %13 = bitcast %"struct.std::_Rb_tree_iterator"* %11 to i8*
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 8 %12, i8* align 8 %13, i64 8, i1 false)
  %14 = getelementptr inbounds %"struct.std::pair.14", %"struct.std::pair.14"* %7, i32 0, i32 1
  %15 = load i8*, i8** %6, align 8
  %16 = call dereferenceable(1) i8* @_ZSt7forwardIbEOT_RNSt16remove_referenceIS0_E4typeE(i8* dereferenceable(1) %15) #3
  %17 = load i8, i8* %16, align 1
  %18 = trunc i8 %17 to i1
  %19 = zext i1 %18 to i8
  store i8 %19, i8* %14, align 8
  ret void
}

; Function Attrs: cold noreturn nounwind
declare void @llvm.trap() #15

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE17_M_construct_nodeIJS0_IiS2_EEEEvPSt13_Rb_tree_nodeIS3_EDpOT_(%"class.std::_Rb_tree"*, %"struct.std::_Rb_tree_node"*, %"struct.std::pair.17"* dereferenceable(64)) #5 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %4 = alloca %"class.std::_Rb_tree"*, align 8
  %5 = alloca %"struct.std::_Rb_tree_node"*, align 8
  %6 = alloca %"struct.std::pair.17"*, align 8
  %7 = alloca i8*
  %8 = alloca i32
  store %"class.std::_Rb_tree"* %0, %"class.std::_Rb_tree"** %4, align 8
  store %"struct.std::_Rb_tree_node"* %1, %"struct.std::_Rb_tree_node"** %5, align 8
  store %"struct.std::pair.17"* %2, %"struct.std::pair.17"** %6, align 8
  %9 = load %"class.std::_Rb_tree"*, %"class.std::_Rb_tree"** %4, align 8
  %10 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %5, align 8
  %11 = bitcast %"struct.std::_Rb_tree_node"* %10 to i8*
  %12 = bitcast i8* %11 to %"struct.std::_Rb_tree_node"*
  %13 = call dereferenceable(1) %"class.std::allocator.3"* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE21_M_get_Node_allocatorEv(%"class.std::_Rb_tree"* %9) #3
  %14 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %5, align 8
  %15 = invoke %"struct.std::pair"* @_ZNSt13_Rb_tree_nodeISt4pairIKi9NonDetLogEE9_M_valptrEv(%"struct.std::_Rb_tree_node"* %14)
          to label %16 unwind label %20

; <label>:16:                                     ; preds = %3
  %17 = load %"struct.std::pair.17"*, %"struct.std::pair.17"** %6, align 8
  %18 = call dereferenceable(64) %"struct.std::pair.17"* @_ZSt7forwardISt4pairIi9NonDetLogEEOT_RNSt16remove_referenceIS3_E4typeE(%"struct.std::pair.17"* dereferenceable(64) %17) #3
  invoke void @_ZNSt16allocator_traitsISaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEE9constructIS4_JS1_IiS3_EEEEvRS6_PT_DpOT0_(%"class.std::allocator.3"* dereferenceable(1) %13, %"struct.std::pair"* %15, %"struct.std::pair.17"* dereferenceable(64) %18)
          to label %19 unwind label %20

; <label>:19:                                     ; preds = %16
  br label %34

; <label>:20:                                     ; preds = %16, %3
  %21 = landingpad { i8*, i32 }
          catch i8* null
  %22 = extractvalue { i8*, i32 } %21, 0
  store i8* %22, i8** %7, align 8
  %23 = extractvalue { i8*, i32 } %21, 1
  store i32 %23, i32* %8, align 4
  br label %24

; <label>:24:                                     ; preds = %20
  %25 = load i8*, i8** %7, align 8
  %26 = call i8* @__cxa_begin_catch(i8* %25) #3
  %27 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %5, align 8
  %28 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %5, align 8
  call void @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE11_M_put_nodeEPSt13_Rb_tree_nodeIS3_E(%"class.std::_Rb_tree"* %9, %"struct.std::_Rb_tree_node"* %28) #3
  invoke void @__cxa_rethrow() #17
          to label %43 unwind label %29

; <label>:29:                                     ; preds = %24
  %30 = landingpad { i8*, i32 }
          cleanup
  %31 = extractvalue { i8*, i32 } %30, 0
  store i8* %31, i8** %7, align 8
  %32 = extractvalue { i8*, i32 } %30, 1
  store i32 %32, i32* %8, align 4
  invoke void @__cxa_end_catch()
          to label %33 unwind label %40

; <label>:33:                                     ; preds = %29
  br label %35

; <label>:34:                                     ; preds = %19
  ret void

; <label>:35:                                     ; preds = %33
  %36 = load i8*, i8** %7, align 8
  %37 = load i32, i32* %8, align 4
  %38 = insertvalue { i8*, i32 } undef, i8* %36, 0
  %39 = insertvalue { i8*, i32 } %38, i32 %37, 1
  resume { i8*, i32 } %39

; <label>:40:                                     ; preds = %29
  %41 = landingpad { i8*, i32 }
          catch i8* null
  %42 = extractvalue { i8*, i32 } %41, 0
  call void @__clang_call_terminate(i8* %42) #16
  unreachable

; <label>:43:                                     ; preds = %24
  unreachable
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZNSt16allocator_traitsISaISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEE9constructIS4_JS1_IiS3_EEEEvRS6_PT_DpOT0_(%"class.std::allocator.3"* dereferenceable(1), %"struct.std::pair"*, %"struct.std::pair.17"* dereferenceable(64)) #5 comdat align 2 {
  %4 = alloca %"class.std::allocator.3"*, align 8
  %5 = alloca %"struct.std::pair"*, align 8
  %6 = alloca %"struct.std::pair.17"*, align 8
  store %"class.std::allocator.3"* %0, %"class.std::allocator.3"** %4, align 8
  store %"struct.std::pair"* %1, %"struct.std::pair"** %5, align 8
  store %"struct.std::pair.17"* %2, %"struct.std::pair.17"** %6, align 8
  %7 = load %"class.std::allocator.3"*, %"class.std::allocator.3"** %4, align 8
  %8 = bitcast %"class.std::allocator.3"* %7 to %"class.__gnu_cxx::new_allocator.4"*
  %9 = load %"struct.std::pair"*, %"struct.std::pair"** %5, align 8
  %10 = load %"struct.std::pair.17"*, %"struct.std::pair.17"** %6, align 8
  %11 = call dereferenceable(64) %"struct.std::pair.17"* @_ZSt7forwardISt4pairIi9NonDetLogEEOT_RNSt16remove_referenceIS3_E4typeE(%"struct.std::pair.17"* dereferenceable(64) %10) #3
  call void @_ZN9__gnu_cxx13new_allocatorISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEE9constructIS5_JS2_IiS4_EEEEvPT_DpOT0_(%"class.__gnu_cxx::new_allocator.4"* %8, %"struct.std::pair"* %9, %"struct.std::pair.17"* dereferenceable(64) %11)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN9__gnu_cxx13new_allocatorISt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEE9constructIS5_JS2_IiS4_EEEEvPT_DpOT0_(%"class.__gnu_cxx::new_allocator.4"*, %"struct.std::pair"*, %"struct.std::pair.17"* dereferenceable(64)) #5 comdat align 2 {
  %4 = alloca %"class.__gnu_cxx::new_allocator.4"*, align 8
  %5 = alloca %"struct.std::pair"*, align 8
  %6 = alloca %"struct.std::pair.17"*, align 8
  store %"class.__gnu_cxx::new_allocator.4"* %0, %"class.__gnu_cxx::new_allocator.4"** %4, align 8
  store %"struct.std::pair"* %1, %"struct.std::pair"** %5, align 8
  store %"struct.std::pair.17"* %2, %"struct.std::pair.17"** %6, align 8
  %7 = load %"class.__gnu_cxx::new_allocator.4"*, %"class.__gnu_cxx::new_allocator.4"** %4, align 8
  %8 = load %"struct.std::pair"*, %"struct.std::pair"** %5, align 8
  %9 = bitcast %"struct.std::pair"* %8 to i8*
  %10 = bitcast i8* %9 to %"struct.std::pair"*
  %11 = load %"struct.std::pair.17"*, %"struct.std::pair.17"** %6, align 8
  %12 = call dereferenceable(64) %"struct.std::pair.17"* @_ZSt7forwardISt4pairIi9NonDetLogEEOT_RNSt16remove_referenceIS3_E4typeE(%"struct.std::pair.17"* dereferenceable(64) %11) #3
  call void @_ZNSt4pairIKi9NonDetLogEC2IiS1_Lb1EEEOS_IT_T0_E(%"struct.std::pair"* %10, %"struct.std::pair.17"* dereferenceable(64) %12)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt4pairIKi9NonDetLogEC2IiS1_Lb1EEEOS_IT_T0_E(%"struct.std::pair"*, %"struct.std::pair.17"* dereferenceable(64)) unnamed_addr #4 comdat align 2 {
  %3 = alloca %"struct.std::pair"*, align 8
  %4 = alloca %"struct.std::pair.17"*, align 8
  store %"struct.std::pair"* %0, %"struct.std::pair"** %3, align 8
  store %"struct.std::pair.17"* %1, %"struct.std::pair.17"** %4, align 8
  %5 = load %"struct.std::pair"*, %"struct.std::pair"** %3, align 8
  %6 = bitcast %"struct.std::pair"* %5 to %"class.std::__pair_base"*
  %7 = getelementptr inbounds %"struct.std::pair", %"struct.std::pair"* %5, i32 0, i32 0
  %8 = load %"struct.std::pair.17"*, %"struct.std::pair.17"** %4, align 8
  %9 = getelementptr inbounds %"struct.std::pair.17", %"struct.std::pair.17"* %8, i32 0, i32 0
  %10 = call dereferenceable(4) i32* @_ZSt7forwardIiEOT_RNSt16remove_referenceIS0_E4typeE(i32* dereferenceable(4) %9) #3
  %11 = load i32, i32* %10, align 4
  store i32 %11, i32* %7, align 8
  %12 = getelementptr inbounds %"struct.std::pair", %"struct.std::pair"* %5, i32 0, i32 1
  %13 = load %"struct.std::pair.17"*, %"struct.std::pair.17"** %4, align 8
  %14 = getelementptr inbounds %"struct.std::pair.17", %"struct.std::pair.17"* %13, i32 0, i32 1
  %15 = call dereferenceable(56) %class.NonDetLog* @_ZSt7forwardI9NonDetLogEOT_RNSt16remove_referenceIS1_E4typeE(%class.NonDetLog* dereferenceable(56) %14) #3
  call void @_ZN9NonDetLogC2EOS_(%class.NonDetLog* %12, %class.NonDetLog* dereferenceable(56) %15) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(4) i32* @_ZSt7forwardIiEOT_RNSt16remove_referenceIS0_E4typeE(i32* dereferenceable(4)) #4 comdat {
  %2 = alloca i32*, align 8
  store i32* %0, i32** %2, align 8
  %3 = load i32*, i32** %2, align 8
  ret i32* %3
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(56) %class.NonDetLog* @_ZSt7forwardI9NonDetLogEOT_RNSt16remove_referenceIS1_E4typeE(%class.NonDetLog* dereferenceable(56)) #4 comdat {
  %2 = alloca %class.NonDetLog*, align 8
  store %class.NonDetLog* %0, %class.NonDetLog** %2, align 8
  %3 = load %class.NonDetLog*, %class.NonDetLog** %2, align 8
  ret %class.NonDetLog* %3
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN9NonDetLogC2EOS_(%class.NonDetLog*, %class.NonDetLog* dereferenceable(56)) unnamed_addr #4 comdat align 2 {
  %3 = alloca %class.NonDetLog*, align 8
  %4 = alloca %class.NonDetLog*, align 8
  store %class.NonDetLog* %0, %class.NonDetLog** %3, align 8
  store %class.NonDetLog* %1, %class.NonDetLog** %4, align 8
  %5 = load %class.NonDetLog*, %class.NonDetLog** %3, align 8
  %6 = getelementptr inbounds %class.NonDetLog, %class.NonDetLog* %5, i32 0, i32 0
  %7 = load %class.NonDetLog*, %class.NonDetLog** %4, align 8
  %8 = getelementptr inbounds %class.NonDetLog, %class.NonDetLog* %7, i32 0, i32 0
  %9 = bitcast i32* %6 to i8*
  %10 = bitcast i32* %8 to i8*
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 8 %9, i8* align 8 %10, i64 8, i1 false)
  %11 = getelementptr inbounds %class.NonDetLog, %class.NonDetLog* %5, i32 0, i32 2
  %12 = load %class.NonDetLog*, %class.NonDetLog** %4, align 8
  %13 = getelementptr inbounds %class.NonDetLog, %class.NonDetLog* %12, i32 0, i32 2
  call void @_ZN5boost7variantIiJjcdfEEC2EOS1_(%"class.boost::variant"* %11, %"class.boost::variant"* dereferenceable(16) %13) #3
  %14 = getelementptr inbounds %class.NonDetLog, %class.NonDetLog* %5, i32 0, i32 3
  %15 = load %class.NonDetLog*, %class.NonDetLog** %4, align 8
  %16 = getelementptr inbounds %class.NonDetLog, %class.NonDetLog* %15, i32 0, i32 3
  call void @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1EOS4_(%"class.std::__cxx11::basic_string"* %14, %"class.std::__cxx11::basic_string"* dereferenceable(32) %16) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost7variantIiJjcdfEEC2EOS1_(%"class.boost::variant"*, %"class.boost::variant"* dereferenceable(16)) unnamed_addr #4 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca %"class.boost::detail::variant::move_into"*, align 8
  %6 = alloca i8*, align 8
  %7 = alloca %"struct.mpl_::int_"*, align 8
  %8 = alloca %"struct.boost::detail::variant::visitation_impl_step"*, align 8
  %9 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %10 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %11 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %12 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %13 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %14 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %15 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %16 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %17 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %18 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %19 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %20 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %21 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %22 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %23 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %24 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %25 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %26 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %27 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %28 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %29 = alloca %"struct.mpl_::bool_.7", align 1
  %30 = alloca %"struct.boost::integral_constant", align 1
  %31 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %32 = alloca i32, align 4
  %33 = alloca i32, align 4
  %34 = alloca %"class.boost::detail::variant::move_into"*, align 8
  %35 = alloca i8*, align 8
  %36 = alloca %"struct.mpl_::bool_", align 1
  %37 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %38 = alloca %"class.boost::variant"*, align 8
  %39 = alloca %"class.boost::detail::variant::move_into"*, align 8
  %40 = alloca %"class.boost::variant"*, align 8
  %41 = alloca %"class.boost::variant"*, align 8
  %42 = alloca %"class.boost::detail::variant::move_into", align 8
  %43 = alloca i8*
  %44 = alloca i32
  store %"class.boost::variant"* %0, %"class.boost::variant"** %40, align 8
  store %"class.boost::variant"* %1, %"class.boost::variant"** %41, align 8
  %45 = load %"class.boost::variant"*, %"class.boost::variant"** %40, align 8
  %46 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %45, i32 0, i32 2
  invoke void @_ZN5boost15aligned_storageILm8ELm8EEC2Ev(%"class.boost::aligned_storage"* %46)
          to label %47 unwind label %164

; <label>:47:                                     ; preds = %2
  %48 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %45, i32 0, i32 2
  %49 = invoke i8* @_ZN5boost15aligned_storageILm8ELm8EE7addressEv(%"class.boost::aligned_storage"* %48)
          to label %50 unwind label %160

; <label>:50:                                     ; preds = %47
  call void @_ZN5boost6detail7variant9move_intoC2EPv(%"class.boost::detail::variant::move_into"* %42, i8* %49) #3
  %51 = load %"class.boost::variant"*, %"class.boost::variant"** %41, align 8
  store %"class.boost::variant"* %51, %"class.boost::variant"** %38, align 8
  store %"class.boost::detail::variant::move_into"* %42, %"class.boost::detail::variant::move_into"** %39, align 8
  %52 = load %"class.boost::variant"*, %"class.boost::variant"** %38, align 8
  %53 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %52, i32 0, i32 0
  %54 = load i32, i32* %53, align 8
  %55 = call i32 @_ZNK5boost7variantIiJjcdfEE5whichEv(%"class.boost::variant"* %52) #3
  %56 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %39, align 8
  %57 = getelementptr inbounds %"class.boost::variant", %"class.boost::variant"* %52, i32 0, i32 2
  %58 = invoke i8* @_ZN5boost15aligned_storageILm8ELm8EE7addressEv(%"class.boost::aligned_storage"* %57)
          to label %59 unwind label %160

; <label>:59:                                     ; preds = %50
  store i32 %54, i32* %32, align 4
  store i32 %55, i32* %33, align 4
  store %"class.boost::detail::variant::move_into"* %56, %"class.boost::detail::variant::move_into"** %34, align 8
  store i8* %58, i8** %35, align 8
  %60 = load i32, i32* %32, align 4
  %61 = load i32, i32* %33, align 4
  %62 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %34, align 8
  %63 = load i8*, i8** %35, align 8
  store i32 %60, i32* %3, align 4
  store i32 %61, i32* %4, align 4
  store %"class.boost::detail::variant::move_into"* %62, %"class.boost::detail::variant::move_into"** %5, align 8
  store i8* %63, i8** %6, align 8
  store %"struct.mpl_::int_"* null, %"struct.mpl_::int_"** %7, align 8
  store %"struct.boost::detail::variant::visitation_impl_step"* null, %"struct.boost::detail::variant::visitation_impl_step"** %8, align 8
  %64 = load i32, i32* %4, align 4
  switch i32 %64, label %150 [
    i32 0, label %65
    i32 1, label %70
    i32 2, label %75
    i32 3, label %80
    i32 4, label %85
    i32 5, label %90
    i32 6, label %94
    i32 7, label %98
    i32 8, label %102
    i32 9, label %106
    i32 10, label %110
    i32 11, label %114
    i32 12, label %118
    i32 13, label %122
    i32 14, label %126
    i32 15, label %130
    i32 16, label %134
    i32 17, label %138
    i32 18, label %142
    i32 19, label %146
  ]

; <label>:65:                                     ; preds = %59
  %66 = load i32, i32* %3, align 4
  %67 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %5, align 8
  %68 = load i8*, i8** %6, align 8
  invoke void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPviNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32 %66, %"class.boost::detail::variant::move_into"* dereferenceable(8) %67, i8* %68, i32* null, i32 1)
          to label %69 unwind label %160

; <label>:69:                                     ; preds = %65
  br label %156

; <label>:70:                                     ; preds = %59
  %71 = load i32, i32* %3, align 4
  %72 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %5, align 8
  %73 = load i8*, i8** %6, align 8
  invoke void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPvjNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32 %71, %"class.boost::detail::variant::move_into"* dereferenceable(8) %72, i8* %73, i32* null, i32 1)
          to label %74 unwind label %160

; <label>:74:                                     ; preds = %70
  br label %156

; <label>:75:                                     ; preds = %59
  %76 = load i32, i32* %3, align 4
  %77 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %5, align 8
  %78 = load i8*, i8** %6, align 8
  invoke void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPvcNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32 %76, %"class.boost::detail::variant::move_into"* dereferenceable(8) %77, i8* %78, i8* null, i32 1)
          to label %79 unwind label %160

; <label>:79:                                     ; preds = %75
  br label %156

; <label>:80:                                     ; preds = %59
  %81 = load i32, i32* %3, align 4
  %82 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %5, align 8
  %83 = load i8*, i8** %6, align 8
  invoke void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPvdNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32 %81, %"class.boost::detail::variant::move_into"* dereferenceable(8) %82, i8* %83, double* null, i32 1)
          to label %84 unwind label %160

; <label>:84:                                     ; preds = %80
  br label %156

; <label>:85:                                     ; preds = %59
  %86 = load i32, i32* %3, align 4
  %87 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %5, align 8
  %88 = load i8*, i8** %6, align 8
  invoke void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPvfNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32 %86, %"class.boost::detail::variant::move_into"* dereferenceable(8) %87, i8* %88, float* null, i32 1)
          to label %89 unwind label %160

; <label>:89:                                     ; preds = %85
  br label %156

; <label>:90:                                     ; preds = %59
  %91 = load i32, i32* %3, align 4
  %92 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %5, align 8
  %93 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %91, %"class.boost::detail::variant::move_into"* dereferenceable(8) %92, i8* %93, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %156

; <label>:94:                                     ; preds = %59
  %95 = load i32, i32* %3, align 4
  %96 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %5, align 8
  %97 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %95, %"class.boost::detail::variant::move_into"* dereferenceable(8) %96, i8* %97, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %156

; <label>:98:                                     ; preds = %59
  %99 = load i32, i32* %3, align 4
  %100 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %5, align 8
  %101 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %99, %"class.boost::detail::variant::move_into"* dereferenceable(8) %100, i8* %101, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %156

; <label>:102:                                    ; preds = %59
  %103 = load i32, i32* %3, align 4
  %104 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %5, align 8
  %105 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %103, %"class.boost::detail::variant::move_into"* dereferenceable(8) %104, i8* %105, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %156

; <label>:106:                                    ; preds = %59
  %107 = load i32, i32* %3, align 4
  %108 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %5, align 8
  %109 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %107, %"class.boost::detail::variant::move_into"* dereferenceable(8) %108, i8* %109, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %156

; <label>:110:                                    ; preds = %59
  %111 = load i32, i32* %3, align 4
  %112 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %5, align 8
  %113 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %111, %"class.boost::detail::variant::move_into"* dereferenceable(8) %112, i8* %113, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %156

; <label>:114:                                    ; preds = %59
  %115 = load i32, i32* %3, align 4
  %116 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %5, align 8
  %117 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %115, %"class.boost::detail::variant::move_into"* dereferenceable(8) %116, i8* %117, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %156

; <label>:118:                                    ; preds = %59
  %119 = load i32, i32* %3, align 4
  %120 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %5, align 8
  %121 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %119, %"class.boost::detail::variant::move_into"* dereferenceable(8) %120, i8* %121, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %156

; <label>:122:                                    ; preds = %59
  %123 = load i32, i32* %3, align 4
  %124 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %5, align 8
  %125 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %123, %"class.boost::detail::variant::move_into"* dereferenceable(8) %124, i8* %125, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %156

; <label>:126:                                    ; preds = %59
  %127 = load i32, i32* %3, align 4
  %128 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %5, align 8
  %129 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %127, %"class.boost::detail::variant::move_into"* dereferenceable(8) %128, i8* %129, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %156

; <label>:130:                                    ; preds = %59
  %131 = load i32, i32* %3, align 4
  %132 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %5, align 8
  %133 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %131, %"class.boost::detail::variant::move_into"* dereferenceable(8) %132, i8* %133, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %156

; <label>:134:                                    ; preds = %59
  %135 = load i32, i32* %3, align 4
  %136 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %5, align 8
  %137 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %135, %"class.boost::detail::variant::move_into"* dereferenceable(8) %136, i8* %137, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %156

; <label>:138:                                    ; preds = %59
  %139 = load i32, i32* %3, align 4
  %140 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %5, align 8
  %141 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %139, %"class.boost::detail::variant::move_into"* dereferenceable(8) %140, i8* %141, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %156

; <label>:142:                                    ; preds = %59
  %143 = load i32, i32* %3, align 4
  %144 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %5, align 8
  %145 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %143, %"class.boost::detail::variant::move_into"* dereferenceable(8) %144, i8* %145, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %156

; <label>:146:                                    ; preds = %59
  %147 = load i32, i32* %3, align 4
  %148 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %5, align 8
  %149 = load i8*, i8** %6, align 8
  call void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32 %147, %"class.boost::detail::variant::move_into"* dereferenceable(8) %148, i8* %149, %"struct.boost::detail::variant::apply_visitor_unrolled"* null, i64 1)
  br label %156

; <label>:150:                                    ; preds = %59
  %151 = load i32, i32* %3, align 4
  %152 = load i32, i32* %4, align 4
  %153 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %5, align 8
  %154 = load i8*, i8** %6, align 8
  %155 = call dereferenceable(1) %"struct.mpl_::bool_.7"* @_ZNK5boost17integral_constantIbLb1EEcvRKN4mpl_5bool_ILb1EEEEv(%"struct.boost::integral_constant"* %30)
  call void @_ZN5boost6detail7variant15visitation_implIN4mpl_4int_ILi20EEENS1_20visitation_impl_stepINS_3mpl6l_iterINS7_5l_endEEESA_EENS1_9move_intoEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT1_11result_typeEiiRSH_T2_NS3_5bool_ILb1EEET3_PT_PT0_(i32 %151, i32 %152, %"class.boost::detail::variant::move_into"* dereferenceable(8) %153, i8* %154, %"struct.mpl_::int_.8"* null, %"struct.boost::detail::variant::visitation_impl_step.9"* null)
  br label %156

; <label>:156:                                    ; preds = %69, %74, %79, %84, %89, %90, %94, %98, %102, %106, %110, %114, %118, %122, %126, %130, %134, %138, %142, %146, %150
  br label %157

; <label>:157:                                    ; preds = %156
  %158 = load %"class.boost::variant"*, %"class.boost::variant"** %41, align 8
  %159 = call i32 @_ZNK5boost7variantIiJjcdfEE5whichEv(%"class.boost::variant"* %158) #3
  call void @_ZN5boost7variantIiJjcdfEE14indicate_whichEi(%"class.boost::variant"* %45, i32 %159) #3
  ret void

; <label>:160:                                    ; preds = %85, %80, %75, %70, %65, %50, %47
  %161 = landingpad { i8*, i32 }
          catch i8* null
  %162 = extractvalue { i8*, i32 } %161, 0
  store i8* %162, i8** %43, align 8
  %163 = extractvalue { i8*, i32 } %161, 1
  store i32 %163, i32* %44, align 4
  call void @_ZN5boost15aligned_storageILm8ELm8EED2Ev(%"class.boost::aligned_storage"* %46) #3
  br label %167

; <label>:164:                                    ; preds = %2
  %165 = landingpad { i8*, i32 }
          catch i8* null
  %166 = extractvalue { i8*, i32 } %165, 0
  call void @__clang_call_terminate(i8* %166) #16
  unreachable

; <label>:167:                                    ; preds = %160
  %168 = load i8*, i8** %43, align 8
  call void @__clang_call_terminate(i8* %168) #16
  unreachable
}

; Function Attrs: nounwind
declare dso_local void @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1EOS4_(%"class.std::__cxx11::basic_string"*, %"class.std::__cxx11::basic_string"* dereferenceable(32)) unnamed_addr #2

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant9move_intoC2EPv(%"class.boost::detail::variant::move_into"*, i8*) unnamed_addr #4 comdat align 2 {
  %3 = alloca %"class.boost::detail::variant::move_into"*, align 8
  %4 = alloca i8*, align 8
  store %"class.boost::detail::variant::move_into"* %0, %"class.boost::detail::variant::move_into"** %3, align 8
  store i8* %1, i8** %4, align 8
  %5 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %3, align 8
  %6 = bitcast %"class.boost::detail::variant::move_into"* %5 to %"class.boost::static_visitor"*
  %7 = getelementptr inbounds %"class.boost::detail::variant::move_into", %"class.boost::detail::variant::move_into"* %5, i32 0, i32 0
  %8 = load i8*, i8** %4, align 8
  store i8* %8, i8** %7, align 8
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPviNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32, %"class.boost::detail::variant::move_into"* dereferenceable(8), i8*, i32*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::move_into"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca i32*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"class.boost::detail::variant::move_into"* %1, %"class.boost::detail::variant::move_into"** %8, align 8
  store i8* %2, i8** %9, align 8
  store i32* %3, i32** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load i32*, i32** %10, align 8
  call void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9move_intoEPviEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"class.boost::detail::variant::move_into"* dereferenceable(8) %14, i8* %15, i32* %16)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPvjNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32, %"class.boost::detail::variant::move_into"* dereferenceable(8), i8*, i32*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::move_into"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca i32*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"class.boost::detail::variant::move_into"* %1, %"class.boost::detail::variant::move_into"** %8, align 8
  store i8* %2, i8** %9, align 8
  store i32* %3, i32** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load i32*, i32** %10, align 8
  call void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9move_intoEPvjEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"class.boost::detail::variant::move_into"* dereferenceable(8) %14, i8* %15, i32* %16)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPvcNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32, %"class.boost::detail::variant::move_into"* dereferenceable(8), i8*, i8*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::move_into"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca i8*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"class.boost::detail::variant::move_into"* %1, %"class.boost::detail::variant::move_into"** %8, align 8
  store i8* %2, i8** %9, align 8
  store i8* %3, i8** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load i8*, i8** %10, align 8
  call void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9move_intoEPvcEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"class.boost::detail::variant::move_into"* dereferenceable(8) %14, i8* %15, i8* %16)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPvdNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32, %"class.boost::detail::variant::move_into"* dereferenceable(8), i8*, double*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::move_into"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca double*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"class.boost::detail::variant::move_into"* %1, %"class.boost::detail::variant::move_into"** %8, align 8
  store i8* %2, i8** %9, align 8
  store double* %3, double** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load double*, double** %10, align 8
  call void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9move_intoEPvdEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"class.boost::detail::variant::move_into"* dereferenceable(8) %14, i8* %15, double* %16)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPvfNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PT1_T2_i(i32, %"class.boost::detail::variant::move_into"* dereferenceable(8), i8*, float*, i32) #5 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::move_into"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca float*, align 8
  %11 = alloca i32, align 4
  %12 = alloca %"struct.mpl_::bool_.7", align 1
  store i32 %0, i32* %7, align 4
  store %"class.boost::detail::variant::move_into"* %1, %"class.boost::detail::variant::move_into"** %8, align 8
  store i8* %2, i8** %9, align 8
  store float* %3, float** %10, align 8
  store i32 %4, i32* %11, align 4
  %13 = load i32, i32* %7, align 4
  %14 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %8, align 8
  %15 = load i8*, i8** %9, align 8
  %16 = load float*, float** %10, align 8
  call void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9move_intoEPvfEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE(i32 %13, %"class.boost::detail::variant::move_into"* dereferenceable(8) %14, i8* %15, float* %16)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant22visitation_impl_invokeINS1_9move_intoEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT_11result_typeEiRS8_T0_PNS1_22apply_visitor_unrolledET1_l(i32, %"class.boost::detail::variant::move_into"* dereferenceable(8), i8*, %"struct.boost::detail::variant::apply_visitor_unrolled"*, i64) #4 comdat {
  %6 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %7 = alloca i32, align 4
  %8 = alloca %"class.boost::detail::variant::move_into"*, align 8
  %9 = alloca i8*, align 8
  %10 = alloca %"struct.boost::detail::variant::apply_visitor_unrolled"*, align 8
  %11 = alloca i64, align 8
  store i32 %0, i32* %7, align 4
  store %"class.boost::detail::variant::move_into"* %1, %"class.boost::detail::variant::move_into"** %8, align 8
  store i8* %2, i8** %9, align 8
  store %"struct.boost::detail::variant::apply_visitor_unrolled"* %3, %"struct.boost::detail::variant::apply_visitor_unrolled"** %10, align 8
  store i64 %4, i64* %11, align 8
  call void @_ZN5boost6detail7variant13forced_returnIvEET_v() #17
  unreachable
                                                  ; No predecessors!
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant15visitation_implIN4mpl_4int_ILi20EEENS1_20visitation_impl_stepINS_3mpl6l_iterINS7_5l_endEEESA_EENS1_9move_intoEPvNS_7variantIiJjcdfEE18has_fallback_type_EEENT1_11result_typeEiiRSH_T2_NS3_5bool_ILb1EEET3_PT_PT0_(i32, i32, %"class.boost::detail::variant::move_into"* dereferenceable(8), i8*, %"struct.mpl_::int_.8"*, %"struct.boost::detail::variant::visitation_impl_step.9"*) #4 comdat {
  %7 = alloca %"struct.mpl_::bool_.7", align 1
  %8 = alloca %"struct.boost::variant<int, unsigned int, char, double, float>::has_fallback_type_", align 1
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca %"class.boost::detail::variant::move_into"*, align 8
  %12 = alloca i8*, align 8
  %13 = alloca %"struct.mpl_::int_.8"*, align 8
  %14 = alloca %"struct.boost::detail::variant::visitation_impl_step.9"*, align 8
  store i32 %0, i32* %9, align 4
  store i32 %1, i32* %10, align 4
  store %"class.boost::detail::variant::move_into"* %2, %"class.boost::detail::variant::move_into"** %11, align 8
  store i8* %3, i8** %12, align 8
  store %"struct.mpl_::int_.8"* %4, %"struct.mpl_::int_.8"** %13, align 8
  store %"struct.boost::detail::variant::visitation_impl_step.9"* %5, %"struct.boost::detail::variant::visitation_impl_step.9"** %14, align 8
  call void @_ZN5boost6detail7variant13forced_returnIvEET_v() #17
  unreachable
                                                  ; No predecessors!
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9move_intoEPviEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"class.boost::detail::variant::move_into"* dereferenceable(8), i8*, i32*) #4 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"class.boost::detail::variant::move_into"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca i32*, align 8
  store i32 %0, i32* %6, align 4
  store %"class.boost::detail::variant::move_into"* %1, %"class.boost::detail::variant::move_into"** %7, align 8
  store i8* %2, i8** %8, align 8
  store i32* %3, i32** %9, align 8
  %10 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(4) i32* @_ZN5boost6detail7variant12cast_storageIiEERT_Pv(i8* %11)
  call void @_ZNK5boost6detail7variant9move_into14internal_visitIiEEvRT_i(%"class.boost::detail::variant::move_into"* %10, i32* dereferenceable(4) %12, i32 1) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost6detail7variant9move_into14internal_visitIiEEvRT_i(%"class.boost::detail::variant::move_into"*, i32* dereferenceable(4), i32) #4 comdat align 2 {
  %4 = alloca %"class.boost::detail::variant::move_into"*, align 8
  %5 = alloca i32*, align 8
  %6 = alloca i32, align 4
  store %"class.boost::detail::variant::move_into"* %0, %"class.boost::detail::variant::move_into"** %4, align 8
  store i32* %1, i32** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %4, align 8
  %8 = getelementptr inbounds %"class.boost::detail::variant::move_into", %"class.boost::detail::variant::move_into"* %7, i32 0, i32 0
  %9 = load i8*, i8** %8, align 8
  %10 = bitcast i8* %9 to i32*
  %11 = load i32*, i32** %5, align 8
  %12 = call dereferenceable(4) i32* @_ZN5boost4moveIRiEEONS_11move_detail16remove_referenceIT_E4typeEOS4_(i32* dereferenceable(4) %11) #3
  %13 = load i32, i32* %12, align 4
  store i32 %13, i32* %10, align 4
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9move_intoEPvjEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"class.boost::detail::variant::move_into"* dereferenceable(8), i8*, i32*) #4 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"class.boost::detail::variant::move_into"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca i32*, align 8
  store i32 %0, i32* %6, align 4
  store %"class.boost::detail::variant::move_into"* %1, %"class.boost::detail::variant::move_into"** %7, align 8
  store i8* %2, i8** %8, align 8
  store i32* %3, i32** %9, align 8
  %10 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(4) i32* @_ZN5boost6detail7variant12cast_storageIjEERT_Pv(i8* %11)
  call void @_ZNK5boost6detail7variant9move_into14internal_visitIjEEvRT_i(%"class.boost::detail::variant::move_into"* %10, i32* dereferenceable(4) %12, i32 1) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost6detail7variant9move_into14internal_visitIjEEvRT_i(%"class.boost::detail::variant::move_into"*, i32* dereferenceable(4), i32) #4 comdat align 2 {
  %4 = alloca %"class.boost::detail::variant::move_into"*, align 8
  %5 = alloca i32*, align 8
  %6 = alloca i32, align 4
  store %"class.boost::detail::variant::move_into"* %0, %"class.boost::detail::variant::move_into"** %4, align 8
  store i32* %1, i32** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %4, align 8
  %8 = getelementptr inbounds %"class.boost::detail::variant::move_into", %"class.boost::detail::variant::move_into"* %7, i32 0, i32 0
  %9 = load i8*, i8** %8, align 8
  %10 = bitcast i8* %9 to i32*
  %11 = load i32*, i32** %5, align 8
  %12 = call dereferenceable(4) i32* @_ZN5boost4moveIRjEEONS_11move_detail16remove_referenceIT_E4typeEOS4_(i32* dereferenceable(4) %11) #3
  %13 = load i32, i32* %12, align 4
  store i32 %13, i32* %10, align 4
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9move_intoEPvcEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"class.boost::detail::variant::move_into"* dereferenceable(8), i8*, i8*) #4 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"class.boost::detail::variant::move_into"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca i8*, align 8
  store i32 %0, i32* %6, align 4
  store %"class.boost::detail::variant::move_into"* %1, %"class.boost::detail::variant::move_into"** %7, align 8
  store i8* %2, i8** %8, align 8
  store i8* %3, i8** %9, align 8
  %10 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(1) i8* @_ZN5boost6detail7variant12cast_storageIcEERT_Pv(i8* %11)
  call void @_ZNK5boost6detail7variant9move_into14internal_visitIcEEvRT_i(%"class.boost::detail::variant::move_into"* %10, i8* dereferenceable(1) %12, i32 1) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost6detail7variant9move_into14internal_visitIcEEvRT_i(%"class.boost::detail::variant::move_into"*, i8* dereferenceable(1), i32) #4 comdat align 2 {
  %4 = alloca %"class.boost::detail::variant::move_into"*, align 8
  %5 = alloca i8*, align 8
  %6 = alloca i32, align 4
  store %"class.boost::detail::variant::move_into"* %0, %"class.boost::detail::variant::move_into"** %4, align 8
  store i8* %1, i8** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %4, align 8
  %8 = getelementptr inbounds %"class.boost::detail::variant::move_into", %"class.boost::detail::variant::move_into"* %7, i32 0, i32 0
  %9 = load i8*, i8** %8, align 8
  %10 = load i8*, i8** %5, align 8
  %11 = call dereferenceable(1) i8* @_ZN5boost4moveIRcEEONS_11move_detail16remove_referenceIT_E4typeEOS4_(i8* dereferenceable(1) %10) #3
  %12 = load i8, i8* %11, align 1
  store i8 %12, i8* %9, align 1
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9move_intoEPvdEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"class.boost::detail::variant::move_into"* dereferenceable(8), i8*, double*) #4 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"class.boost::detail::variant::move_into"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca double*, align 8
  store i32 %0, i32* %6, align 4
  store %"class.boost::detail::variant::move_into"* %1, %"class.boost::detail::variant::move_into"** %7, align 8
  store i8* %2, i8** %8, align 8
  store double* %3, double** %9, align 8
  %10 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(8) double* @_ZN5boost6detail7variant12cast_storageIdEERT_Pv(i8* %11)
  call void @_ZNK5boost6detail7variant9move_into14internal_visitIdEEvRT_i(%"class.boost::detail::variant::move_into"* %10, double* dereferenceable(8) %12, i32 1) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost6detail7variant9move_into14internal_visitIdEEvRT_i(%"class.boost::detail::variant::move_into"*, double* dereferenceable(8), i32) #4 comdat align 2 {
  %4 = alloca %"class.boost::detail::variant::move_into"*, align 8
  %5 = alloca double*, align 8
  %6 = alloca i32, align 4
  store %"class.boost::detail::variant::move_into"* %0, %"class.boost::detail::variant::move_into"** %4, align 8
  store double* %1, double** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %4, align 8
  %8 = getelementptr inbounds %"class.boost::detail::variant::move_into", %"class.boost::detail::variant::move_into"* %7, i32 0, i32 0
  %9 = load i8*, i8** %8, align 8
  %10 = bitcast i8* %9 to double*
  %11 = load double*, double** %5, align 8
  %12 = call dereferenceable(8) double* @_ZN5boost4moveIRdEEONS_11move_detail16remove_referenceIT_E4typeEOS4_(double* dereferenceable(8) %11) #3
  %13 = load double, double* %12, align 8
  store double %13, double* %10, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN5boost6detail7variant27visitation_impl_invoke_implINS1_9move_intoEPvfEENT_11result_typeEiRS5_T0_PT1_N4mpl_5bool_ILb1EEE(i32, %"class.boost::detail::variant::move_into"* dereferenceable(8), i8*, float*) #4 comdat {
  %5 = alloca %"struct.mpl_::bool_.7", align 1
  %6 = alloca i32, align 4
  %7 = alloca %"class.boost::detail::variant::move_into"*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca float*, align 8
  store i32 %0, i32* %6, align 4
  store %"class.boost::detail::variant::move_into"* %1, %"class.boost::detail::variant::move_into"** %7, align 8
  store i8* %2, i8** %8, align 8
  store float* %3, float** %9, align 8
  %10 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %7, align 8
  %11 = load i8*, i8** %8, align 8
  %12 = call dereferenceable(4) float* @_ZN5boost6detail7variant12cast_storageIfEERT_Pv(i8* %11)
  call void @_ZNK5boost6detail7variant9move_into14internal_visitIfEEvRT_i(%"class.boost::detail::variant::move_into"* %10, float* dereferenceable(4) %12, i32 1) #3
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNK5boost6detail7variant9move_into14internal_visitIfEEvRT_i(%"class.boost::detail::variant::move_into"*, float* dereferenceable(4), i32) #4 comdat align 2 {
  %4 = alloca %"class.boost::detail::variant::move_into"*, align 8
  %5 = alloca float*, align 8
  %6 = alloca i32, align 4
  store %"class.boost::detail::variant::move_into"* %0, %"class.boost::detail::variant::move_into"** %4, align 8
  store float* %1, float** %5, align 8
  store i32 %2, i32* %6, align 4
  %7 = load %"class.boost::detail::variant::move_into"*, %"class.boost::detail::variant::move_into"** %4, align 8
  %8 = getelementptr inbounds %"class.boost::detail::variant::move_into", %"class.boost::detail::variant::move_into"* %7, i32 0, i32 0
  %9 = load i8*, i8** %8, align 8
  %10 = bitcast i8* %9 to float*
  %11 = load float*, float** %5, align 8
  %12 = call dereferenceable(4) float* @_ZN5boost4moveIRfEEONS_11move_detail16remove_referenceIT_E4typeEOS4_(float* dereferenceable(4) %11) #3
  %13 = load float, float* %12, align 4
  store float %13, float* %10, align 4
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local zeroext i1 @_ZNKSt4lessIiEclERKiS2_(%"struct.std::less"*, i32* dereferenceable(4), i32* dereferenceable(4)) #4 comdat align 2 {
  %4 = alloca %"struct.std::less"*, align 8
  %5 = alloca i32*, align 8
  %6 = alloca i32*, align 8
  store %"struct.std::less"* %0, %"struct.std::less"** %4, align 8
  store i32* %1, i32** %5, align 8
  store i32* %2, i32** %6, align 8
  %7 = load %"struct.std::less"*, %"struct.std::less"** %4, align 8
  %8 = load i32*, i32** %5, align 8
  %9 = load i32, i32* %8, align 4
  %10 = load i32*, i32** %6, align 8
  %11 = load i32, i32* %10, align 4
  %12 = icmp slt i32 %9, %11
  ret i1 %12
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local zeroext i1 @_ZSteqRKSt17_Rb_tree_iteratorISt4pairIKi9NonDetLogEES6_(%"struct.std::_Rb_tree_iterator"* dereferenceable(8), %"struct.std::_Rb_tree_iterator"* dereferenceable(8)) #4 comdat {
  %3 = alloca %"struct.std::_Rb_tree_iterator"*, align 8
  %4 = alloca %"struct.std::_Rb_tree_iterator"*, align 8
  store %"struct.std::_Rb_tree_iterator"* %0, %"struct.std::_Rb_tree_iterator"** %3, align 8
  store %"struct.std::_Rb_tree_iterator"* %1, %"struct.std::_Rb_tree_iterator"** %4, align 8
  %5 = load %"struct.std::_Rb_tree_iterator"*, %"struct.std::_Rb_tree_iterator"** %3, align 8
  %6 = getelementptr inbounds %"struct.std::_Rb_tree_iterator", %"struct.std::_Rb_tree_iterator"* %5, i32 0, i32 0
  %7 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %6, align 8
  %8 = load %"struct.std::_Rb_tree_iterator"*, %"struct.std::_Rb_tree_iterator"** %4, align 8
  %9 = getelementptr inbounds %"struct.std::_Rb_tree_iterator", %"struct.std::_Rb_tree_iterator"* %8, i32 0, i32 0
  %10 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %9, align 8
  %11 = icmp eq %"struct.std::_Rb_tree_node_base"* %7, %10
  ret i1 %11
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt4pairIPSt18_Rb_tree_node_baseS1_EC2IRPSt13_Rb_tree_nodeIS_IKi9NonDetLogEERS1_Lb1EEEOT_OT0_(%"struct.std::pair.20"*, %"struct.std::_Rb_tree_node"** dereferenceable(8), %"struct.std::_Rb_tree_node_base"** dereferenceable(8)) unnamed_addr #4 comdat align 2 {
  %4 = alloca %"struct.std::pair.20"*, align 8
  %5 = alloca %"struct.std::_Rb_tree_node"**, align 8
  %6 = alloca %"struct.std::_Rb_tree_node_base"**, align 8
  store %"struct.std::pair.20"* %0, %"struct.std::pair.20"** %4, align 8
  store %"struct.std::_Rb_tree_node"** %1, %"struct.std::_Rb_tree_node"*** %5, align 8
  store %"struct.std::_Rb_tree_node_base"** %2, %"struct.std::_Rb_tree_node_base"*** %6, align 8
  %7 = load %"struct.std::pair.20"*, %"struct.std::pair.20"** %4, align 8
  %8 = bitcast %"struct.std::pair.20"* %7 to %"class.std::__pair_base.21"*
  %9 = getelementptr inbounds %"struct.std::pair.20", %"struct.std::pair.20"* %7, i32 0, i32 0
  %10 = load %"struct.std::_Rb_tree_node"**, %"struct.std::_Rb_tree_node"*** %5, align 8
  %11 = call dereferenceable(8) %"struct.std::_Rb_tree_node"** @_ZSt7forwardIRPSt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEOT_RNSt16remove_referenceIS8_E4typeE(%"struct.std::_Rb_tree_node"** dereferenceable(8) %10) #3
  %12 = load %"struct.std::_Rb_tree_node"*, %"struct.std::_Rb_tree_node"** %11, align 8
  %13 = bitcast %"struct.std::_Rb_tree_node"* %12 to %"struct.std::_Rb_tree_node_base"*
  store %"struct.std::_Rb_tree_node_base"* %13, %"struct.std::_Rb_tree_node_base"** %9, align 8
  %14 = getelementptr inbounds %"struct.std::pair.20", %"struct.std::pair.20"* %7, i32 0, i32 1
  %15 = load %"struct.std::_Rb_tree_node_base"**, %"struct.std::_Rb_tree_node_base"*** %6, align 8
  %16 = call dereferenceable(8) %"struct.std::_Rb_tree_node_base"** @_ZSt7forwardIRPSt18_Rb_tree_node_baseEOT_RNSt16remove_referenceIS3_E4typeE(%"struct.std::_Rb_tree_node_base"** dereferenceable(8) %15) #3
  %17 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %16, align 8
  store %"struct.std::_Rb_tree_node_base"* %17, %"struct.std::_Rb_tree_node_base"** %14, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(8) %"struct.std::_Rb_tree_iterator"* @_ZNSt17_Rb_tree_iteratorISt4pairIKi9NonDetLogEEmmEv(%"struct.std::_Rb_tree_iterator"*) #4 comdat align 2 {
  %2 = alloca %"struct.std::_Rb_tree_iterator"*, align 8
  store %"struct.std::_Rb_tree_iterator"* %0, %"struct.std::_Rb_tree_iterator"** %2, align 8
  %3 = load %"struct.std::_Rb_tree_iterator"*, %"struct.std::_Rb_tree_iterator"** %2, align 8
  %4 = getelementptr inbounds %"struct.std::_Rb_tree_iterator", %"struct.std::_Rb_tree_iterator"* %3, i32 0, i32 0
  %5 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %4, align 8
  %6 = call %"struct.std::_Rb_tree_node_base"* @_ZSt18_Rb_tree_decrementPSt18_Rb_tree_node_base(%"struct.std::_Rb_tree_node_base"* %5) #18
  %7 = getelementptr inbounds %"struct.std::_Rb_tree_iterator", %"struct.std::_Rb_tree_iterator"* %3, i32 0, i32 0
  store %"struct.std::_Rb_tree_node_base"* %6, %"struct.std::_Rb_tree_node_base"** %7, align 8
  ret %"struct.std::_Rb_tree_iterator"* %3
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local dereferenceable(4) i32* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE6_S_keyEPKSt18_Rb_tree_node_base(%"struct.std::_Rb_tree_node_base"*) #5 comdat align 2 {
  %2 = alloca %"struct.std::_Rb_tree_node_base"*, align 8
  store %"struct.std::_Rb_tree_node_base"* %0, %"struct.std::_Rb_tree_node_base"** %2, align 8
  %3 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %2, align 8
  %4 = bitcast %"struct.std::_Rb_tree_node_base"* %3 to %"struct.std::_Rb_tree_node"*
  %5 = call dereferenceable(4) i32* @_ZNSt8_Rb_treeIiSt4pairIKi9NonDetLogESt10_Select1stIS3_ESt4lessIiESaIS3_EE6_S_keyEPKSt13_Rb_tree_nodeIS3_E(%"struct.std::_Rb_tree_node"* %4)
  ret i32* %5
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt4pairIPSt18_Rb_tree_node_baseS1_EC2IRS1_Lb1EEEOT_RKS1_(%"struct.std::pair.20"*, %"struct.std::_Rb_tree_node_base"** dereferenceable(8), %"struct.std::_Rb_tree_node_base"** dereferenceable(8)) unnamed_addr #4 comdat align 2 {
  %4 = alloca %"struct.std::pair.20"*, align 8
  %5 = alloca %"struct.std::_Rb_tree_node_base"**, align 8
  %6 = alloca %"struct.std::_Rb_tree_node_base"**, align 8
  store %"struct.std::pair.20"* %0, %"struct.std::pair.20"** %4, align 8
  store %"struct.std::_Rb_tree_node_base"** %1, %"struct.std::_Rb_tree_node_base"*** %5, align 8
  store %"struct.std::_Rb_tree_node_base"** %2, %"struct.std::_Rb_tree_node_base"*** %6, align 8
  %7 = load %"struct.std::pair.20"*, %"struct.std::pair.20"** %4, align 8
  %8 = bitcast %"struct.std::pair.20"* %7 to %"class.std::__pair_base.21"*
  %9 = getelementptr inbounds %"struct.std::pair.20", %"struct.std::pair.20"* %7, i32 0, i32 0
  %10 = load %"struct.std::_Rb_tree_node_base"**, %"struct.std::_Rb_tree_node_base"*** %5, align 8
  %11 = call dereferenceable(8) %"struct.std::_Rb_tree_node_base"** @_ZSt7forwardIRPSt18_Rb_tree_node_baseEOT_RNSt16remove_referenceIS3_E4typeE(%"struct.std::_Rb_tree_node_base"** dereferenceable(8) %10) #3
  %12 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %11, align 8
  store %"struct.std::_Rb_tree_node_base"* %12, %"struct.std::_Rb_tree_node_base"** %9, align 8
  %13 = getelementptr inbounds %"struct.std::pair.20", %"struct.std::pair.20"* %7, i32 0, i32 1
  %14 = load %"struct.std::_Rb_tree_node_base"**, %"struct.std::_Rb_tree_node_base"*** %6, align 8
  %15 = load %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"** %14, align 8
  store %"struct.std::_Rb_tree_node_base"* %15, %"struct.std::_Rb_tree_node_base"** %13, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(8) %"struct.std::_Rb_tree_node"** @_ZSt7forwardIRPSt13_Rb_tree_nodeISt4pairIKi9NonDetLogEEEOT_RNSt16remove_referenceIS8_E4typeE(%"struct.std::_Rb_tree_node"** dereferenceable(8)) #4 comdat {
  %2 = alloca %"struct.std::_Rb_tree_node"**, align 8
  store %"struct.std::_Rb_tree_node"** %0, %"struct.std::_Rb_tree_node"*** %2, align 8
  %3 = load %"struct.std::_Rb_tree_node"**, %"struct.std::_Rb_tree_node"*** %2, align 8
  ret %"struct.std::_Rb_tree_node"** %3
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(8) %"struct.std::_Rb_tree_node_base"** @_ZSt7forwardIRPSt18_Rb_tree_node_baseEOT_RNSt16remove_referenceIS3_E4typeE(%"struct.std::_Rb_tree_node_base"** dereferenceable(8)) #4 comdat {
  %2 = alloca %"struct.std::_Rb_tree_node_base"**, align 8
  store %"struct.std::_Rb_tree_node_base"** %0, %"struct.std::_Rb_tree_node_base"*** %2, align 8
  %3 = load %"struct.std::_Rb_tree_node_base"**, %"struct.std::_Rb_tree_node_base"*** %2, align 8
  ret %"struct.std::_Rb_tree_node_base"** %3
}

; Function Attrs: nounwind readonly
declare dso_local %"struct.std::_Rb_tree_node_base"* @_ZSt18_Rb_tree_decrementPSt18_Rb_tree_node_base(%"struct.std::_Rb_tree_node_base"*) #14

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(4) i32* @_ZNKSt10_Select1stISt4pairIKi9NonDetLogEEclERKS3_(%"struct.std::_Select1st"*, %"struct.std::pair"* dereferenceable(64)) #4 comdat align 2 {
  %3 = alloca %"struct.std::_Select1st"*, align 8
  %4 = alloca %"struct.std::pair"*, align 8
  store %"struct.std::_Select1st"* %0, %"struct.std::_Select1st"** %3, align 8
  store %"struct.std::pair"* %1, %"struct.std::pair"** %4, align 8
  %5 = load %"struct.std::_Select1st"*, %"struct.std::_Select1st"** %3, align 8
  %6 = load %"struct.std::pair"*, %"struct.std::pair"** %4, align 8
  %7 = getelementptr inbounds %"struct.std::pair", %"struct.std::pair"* %6, i32 0, i32 0
  ret i32* %7
}

; Function Attrs: nounwind
declare dso_local void @_ZSt29_Rb_tree_insert_and_rebalancebPSt18_Rb_tree_node_baseS0_RS_(i1 zeroext, %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"*, %"struct.std::_Rb_tree_node_base"* dereferenceable(32)) #2

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(8) %"struct.std::_Rb_tree_iterator"* @_ZSt7forwardISt17_Rb_tree_iteratorISt4pairIKi9NonDetLogEEEOT_RNSt16remove_referenceIS6_E4typeE(%"struct.std::_Rb_tree_iterator"* dereferenceable(8)) #4 comdat {
  %2 = alloca %"struct.std::_Rb_tree_iterator"*, align 8
  store %"struct.std::_Rb_tree_iterator"* %0, %"struct.std::_Rb_tree_iterator"** %2, align 8
  %3 = load %"struct.std::_Rb_tree_iterator"*, %"struct.std::_Rb_tree_iterator"** %2, align 8
  ret %"struct.std::_Rb_tree_iterator"* %3
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(1) i8* @_ZSt7forwardIbEOT_RNSt16remove_referenceIS0_E4typeE(i8* dereferenceable(1)) #4 comdat {
  %2 = alloca i8*, align 8
  store i8* %0, i8** %2, align 8
  %3 = load i8*, i8** %2, align 8
  ret i8* %3
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(4) i32* @_ZSt7forwardIRiEOT_RNSt16remove_referenceIS1_E4typeE(i32* dereferenceable(4)) #4 comdat {
  %2 = alloca i32*, align 8
  store i32* %0, i32** %2, align 8
  %3 = load i32*, i32** %2, align 8
  ret i32* %3
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(56) %class.NonDetLog* @_ZSt7forwardIR9NonDetLogEOT_RNSt16remove_referenceIS2_E4typeE(%class.NonDetLog* dereferenceable(56)) #4 comdat {
  %2 = alloca %class.NonDetLog*, align 8
  store %class.NonDetLog* %0, %class.NonDetLog** %2, align 8
  %3 = load %class.NonDetLog*, %class.NonDetLog** %2, align 8
  ret %class.NonDetLog* %3
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZNSt7__cxx114listISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE9_M_insertIJRKS9_EEEvSt14_List_iteratorIS9_EDpOT_(%"class.std::__cxx11::list"*, %"struct.std::__detail::_List_node_base"*, %"class.std::map"* dereferenceable(48)) #5 comdat align 2 {
  %4 = alloca %"struct.std::_List_iterator", align 8
  %5 = alloca %"class.std::__cxx11::list"*, align 8
  %6 = alloca %"class.std::map"*, align 8
  %7 = alloca %"struct.std::_List_node"*, align 8
  %8 = getelementptr inbounds %"struct.std::_List_iterator", %"struct.std::_List_iterator"* %4, i32 0, i32 0
  store %"struct.std::__detail::_List_node_base"* %1, %"struct.std::__detail::_List_node_base"** %8, align 8
  store %"class.std::__cxx11::list"* %0, %"class.std::__cxx11::list"** %5, align 8
  store %"class.std::map"* %2, %"class.std::map"** %6, align 8
  %9 = load %"class.std::__cxx11::list"*, %"class.std::__cxx11::list"** %5, align 8
  %10 = load %"class.std::map"*, %"class.std::map"** %6, align 8
  %11 = call dereferenceable(48) %"class.std::map"* @_ZSt7forwardIRKSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEEOT_RNSt16remove_referenceISB_E4typeE(%"class.std::map"* dereferenceable(48) %10) #3
  %12 = call %"struct.std::_List_node"* @_ZNSt7__cxx114listISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE14_M_create_nodeIJRKS9_EEEPSt10_List_nodeIS9_EDpOT_(%"class.std::__cxx11::list"* %9, %"class.std::map"* dereferenceable(48) %11)
  store %"struct.std::_List_node"* %12, %"struct.std::_List_node"** %7, align 8
  %13 = load %"struct.std::_List_node"*, %"struct.std::_List_node"** %7, align 8
  %14 = bitcast %"struct.std::_List_node"* %13 to %"struct.std::__detail::_List_node_base"*
  %15 = getelementptr inbounds %"struct.std::_List_iterator", %"struct.std::_List_iterator"* %4, i32 0, i32 0
  %16 = load %"struct.std::__detail::_List_node_base"*, %"struct.std::__detail::_List_node_base"** %15, align 8
  call void @_ZNSt8__detail15_List_node_base7_M_hookEPS0_(%"struct.std::__detail::_List_node_base"* %14, %"struct.std::__detail::_List_node_base"* %16) #3
  %17 = bitcast %"class.std::__cxx11::list"* %9 to %"class.std::__cxx11::_List_base"*
  call void @_ZNSt7__cxx1110_List_baseISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE11_M_inc_sizeEm(%"class.std::__cxx11::_List_base"* %17, i64 1)
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local %"struct.std::_List_node"* @_ZNSt7__cxx114listISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE14_M_create_nodeIJRKS9_EEEPSt10_List_nodeIS9_EDpOT_(%"class.std::__cxx11::list"*, %"class.std::map"* dereferenceable(48)) #5 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %3 = alloca %"class.std::__cxx11::list"*, align 8
  %4 = alloca %"class.std::map"*, align 8
  %5 = alloca %"struct.std::_List_node"*, align 8
  %6 = alloca %"class.std::allocator.0"*, align 8
  %7 = alloca %"struct.std::__allocated_ptr", align 8
  %8 = alloca i8*
  %9 = alloca i32
  store %"class.std::__cxx11::list"* %0, %"class.std::__cxx11::list"** %3, align 8
  store %"class.std::map"* %1, %"class.std::map"** %4, align 8
  %10 = load %"class.std::__cxx11::list"*, %"class.std::__cxx11::list"** %3, align 8
  %11 = bitcast %"class.std::__cxx11::list"* %10 to %"class.std::__cxx11::_List_base"*
  %12 = call %"struct.std::_List_node"* @_ZNSt7__cxx1110_List_baseISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE11_M_get_nodeEv(%"class.std::__cxx11::_List_base"* %11)
  store %"struct.std::_List_node"* %12, %"struct.std::_List_node"** %5, align 8
  %13 = bitcast %"class.std::__cxx11::list"* %10 to %"class.std::__cxx11::_List_base"*
  %14 = call dereferenceable(1) %"class.std::allocator.0"* @_ZNSt7__cxx1110_List_baseISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE21_M_get_Node_allocatorEv(%"class.std::__cxx11::_List_base"* %13) #3
  store %"class.std::allocator.0"* %14, %"class.std::allocator.0"** %6, align 8
  %15 = load %"class.std::allocator.0"*, %"class.std::allocator.0"** %6, align 8
  %16 = load %"struct.std::_List_node"*, %"struct.std::_List_node"** %5, align 8
  call void @_ZNSt15__allocated_ptrISaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEEEEC2ERSB_PSA_(%"struct.std::__allocated_ptr"* %7, %"class.std::allocator.0"* dereferenceable(1) %15, %"struct.std::_List_node"* %16) #3
  %17 = load %"class.std::allocator.0"*, %"class.std::allocator.0"** %6, align 8
  %18 = load %"struct.std::_List_node"*, %"struct.std::_List_node"** %5, align 8
  %19 = invoke %"class.std::map"* @_ZNSt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEE9_M_valptrEv(%"struct.std::_List_node"* %18)
          to label %20 unwind label %26

; <label>:20:                                     ; preds = %2
  %21 = load %"class.std::map"*, %"class.std::map"** %4, align 8
  %22 = call dereferenceable(48) %"class.std::map"* @_ZSt7forwardIRKSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEEOT_RNSt16remove_referenceISB_E4typeE(%"class.std::map"* dereferenceable(48) %21) #3
  invoke void @_ZNSt16allocator_traitsISaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEEEE9constructIS9_JRKS9_EEEvRSB_PT_DpOT0_(%"class.std::allocator.0"* dereferenceable(1) %17, %"class.std::map"* %19, %"class.std::map"* dereferenceable(48) %22)
          to label %23 unwind label %26

; <label>:23:                                     ; preds = %20
  %24 = call dereferenceable(16) %"struct.std::__allocated_ptr"* @_ZNSt15__allocated_ptrISaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEEEEaSEDn(%"struct.std::__allocated_ptr"* %7, i8* null) #3
  %25 = load %"struct.std::_List_node"*, %"struct.std::_List_node"** %5, align 8
  call void @_ZNSt15__allocated_ptrISaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEEEED2Ev(%"struct.std::__allocated_ptr"* %7) #3
  ret %"struct.std::_List_node"* %25

; <label>:26:                                     ; preds = %20, %2
  %27 = landingpad { i8*, i32 }
          cleanup
  %28 = extractvalue { i8*, i32 } %27, 0
  store i8* %28, i8** %8, align 8
  %29 = extractvalue { i8*, i32 } %27, 1
  store i32 %29, i32* %9, align 4
  call void @_ZNSt15__allocated_ptrISaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEEEED2Ev(%"struct.std::__allocated_ptr"* %7) #3
  br label %30

; <label>:30:                                     ; preds = %26
  %31 = load i8*, i8** %8, align 8
  %32 = load i32, i32* %9, align 4
  %33 = insertvalue { i8*, i32 } undef, i8* %31, 0
  %34 = insertvalue { i8*, i32 } %33, i32 %32, 1
  resume { i8*, i32 } %34
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(48) %"class.std::map"* @_ZSt7forwardIRKSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEEOT_RNSt16remove_referenceISB_E4typeE(%"class.std::map"* dereferenceable(48)) #4 comdat {
  %2 = alloca %"class.std::map"*, align 8
  store %"class.std::map"* %0, %"class.std::map"** %2, align 8
  %3 = load %"class.std::map"*, %"class.std::map"** %2, align 8
  ret %"class.std::map"* %3
}

; Function Attrs: nounwind
declare dso_local void @_ZNSt8__detail15_List_node_base7_M_hookEPS0_(%"struct.std::__detail::_List_node_base"*, %"struct.std::__detail::_List_node_base"*) #2

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt7__cxx1110_List_baseISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE11_M_inc_sizeEm(%"class.std::__cxx11::_List_base"*, i64) #4 comdat align 2 {
  %3 = alloca %"class.std::__cxx11::_List_base"*, align 8
  %4 = alloca i64, align 8
  store %"class.std::__cxx11::_List_base"* %0, %"class.std::__cxx11::_List_base"** %3, align 8
  store i64 %1, i64* %4, align 8
  %5 = load %"class.std::__cxx11::_List_base"*, %"class.std::__cxx11::_List_base"** %3, align 8
  %6 = load i64, i64* %4, align 8
  %7 = getelementptr inbounds %"class.std::__cxx11::_List_base", %"class.std::__cxx11::_List_base"* %5, i32 0, i32 0
  %8 = getelementptr inbounds %"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl", %"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl"* %7, i32 0, i32 0
  %9 = getelementptr inbounds %"struct.std::__detail::_List_node_header", %"struct.std::__detail::_List_node_header"* %8, i32 0, i32 1
  %10 = load i64, i64* %9, align 8
  %11 = add i64 %10, %6
  store i64 %11, i64* %9, align 8
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local %"struct.std::_List_node"* @_ZNSt7__cxx1110_List_baseISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEESaIS9_EE11_M_get_nodeEv(%"class.std::__cxx11::_List_base"*) #5 comdat align 2 {
  %2 = alloca %"class.std::__cxx11::_List_base"*, align 8
  store %"class.std::__cxx11::_List_base"* %0, %"class.std::__cxx11::_List_base"** %2, align 8
  %3 = load %"class.std::__cxx11::_List_base"*, %"class.std::__cxx11::_List_base"** %2, align 8
  %4 = getelementptr inbounds %"class.std::__cxx11::_List_base", %"class.std::__cxx11::_List_base"* %3, i32 0, i32 0
  %5 = bitcast %"struct.std::__cxx11::_List_base<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > >, std::allocator<std::map<int, NonDetLog, std::less<int>, std::allocator<std::pair<const int, NonDetLog> > > > >::_List_impl"* %4 to %"class.std::allocator.0"*
  %6 = call %"struct.std::_List_node"* @_ZNSt16allocator_traitsISaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEEEE8allocateERSB_m(%"class.std::allocator.0"* dereferenceable(1) %5, i64 1)
  ret %"struct.std::_List_node"* %6
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt15__allocated_ptrISaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEEEEC2ERSB_PSA_(%"struct.std::__allocated_ptr"*, %"class.std::allocator.0"* dereferenceable(1), %"struct.std::_List_node"*) unnamed_addr #4 comdat align 2 {
  %4 = alloca %"struct.std::__allocated_ptr"*, align 8
  %5 = alloca %"class.std::allocator.0"*, align 8
  %6 = alloca %"struct.std::_List_node"*, align 8
  store %"struct.std::__allocated_ptr"* %0, %"struct.std::__allocated_ptr"** %4, align 8
  store %"class.std::allocator.0"* %1, %"class.std::allocator.0"** %5, align 8
  store %"struct.std::_List_node"* %2, %"struct.std::_List_node"** %6, align 8
  %7 = load %"struct.std::__allocated_ptr"*, %"struct.std::__allocated_ptr"** %4, align 8
  %8 = getelementptr inbounds %"struct.std::__allocated_ptr", %"struct.std::__allocated_ptr"* %7, i32 0, i32 0
  %9 = load %"class.std::allocator.0"*, %"class.std::allocator.0"** %5, align 8
  %10 = call %"class.std::allocator.0"* @_ZSt11__addressofISaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEEEEPT_RSC_(%"class.std::allocator.0"* dereferenceable(1) %9) #3
  store %"class.std::allocator.0"* %10, %"class.std::allocator.0"** %8, align 8
  %11 = getelementptr inbounds %"struct.std::__allocated_ptr", %"struct.std::__allocated_ptr"* %7, i32 0, i32 1
  %12 = load %"struct.std::_List_node"*, %"struct.std::_List_node"** %6, align 8
  store %"struct.std::_List_node"* %12, %"struct.std::_List_node"** %11, align 8
  ret void
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZNSt16allocator_traitsISaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEEEE9constructIS9_JRKS9_EEEvRSB_PT_DpOT0_(%"class.std::allocator.0"* dereferenceable(1), %"class.std::map"*, %"class.std::map"* dereferenceable(48)) #5 comdat align 2 {
  %4 = alloca %"class.std::allocator.0"*, align 8
  %5 = alloca %"class.std::map"*, align 8
  %6 = alloca %"class.std::map"*, align 8
  store %"class.std::allocator.0"* %0, %"class.std::allocator.0"** %4, align 8
  store %"class.std::map"* %1, %"class.std::map"** %5, align 8
  store %"class.std::map"* %2, %"class.std::map"** %6, align 8
  %7 = load %"class.std::allocator.0"*, %"class.std::allocator.0"** %4, align 8
  %8 = bitcast %"class.std::allocator.0"* %7 to %"class.__gnu_cxx::new_allocator.1"*
  %9 = load %"class.std::map"*, %"class.std::map"** %5, align 8
  %10 = load %"class.std::map"*, %"class.std::map"** %6, align 8
  %11 = call dereferenceable(48) %"class.std::map"* @_ZSt7forwardIRKSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEEOT_RNSt16remove_referenceISB_E4typeE(%"class.std::map"* dereferenceable(48) %10) #3
  call void @_ZN9__gnu_cxx13new_allocatorISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS3_EEEEE9constructISA_JRKSA_EEEvPT_DpOT0_(%"class.__gnu_cxx::new_allocator.1"* %8, %"class.std::map"* %9, %"class.std::map"* dereferenceable(48) %11)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local dereferenceable(16) %"struct.std::__allocated_ptr"* @_ZNSt15__allocated_ptrISaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEEEEaSEDn(%"struct.std::__allocated_ptr"*, i8*) #4 comdat align 2 {
  %3 = alloca %"struct.std::__allocated_ptr"*, align 8
  %4 = alloca i8*, align 8
  store %"struct.std::__allocated_ptr"* %0, %"struct.std::__allocated_ptr"** %3, align 8
  store i8* %1, i8** %4, align 8
  %5 = load %"struct.std::__allocated_ptr"*, %"struct.std::__allocated_ptr"** %3, align 8
  %6 = getelementptr inbounds %"struct.std::__allocated_ptr", %"struct.std::__allocated_ptr"* %5, i32 0, i32 1
  store %"struct.std::_List_node"* null, %"struct.std::_List_node"** %6, align 8
  ret %"struct.std::__allocated_ptr"* %5
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZNSt15__allocated_ptrISaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEEEED2Ev(%"struct.std::__allocated_ptr"*) unnamed_addr #4 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %2 = alloca %"struct.std::__allocated_ptr"*, align 8
  store %"struct.std::__allocated_ptr"* %0, %"struct.std::__allocated_ptr"** %2, align 8
  %3 = load %"struct.std::__allocated_ptr"*, %"struct.std::__allocated_ptr"** %2, align 8
  %4 = getelementptr inbounds %"struct.std::__allocated_ptr", %"struct.std::__allocated_ptr"* %3, i32 0, i32 1
  %5 = load %"struct.std::_List_node"*, %"struct.std::_List_node"** %4, align 8
  %6 = icmp ne %"struct.std::_List_node"* %5, null
  br i1 %6, label %7, label %13

; <label>:7:                                      ; preds = %1
  %8 = getelementptr inbounds %"struct.std::__allocated_ptr", %"struct.std::__allocated_ptr"* %3, i32 0, i32 0
  %9 = load %"class.std::allocator.0"*, %"class.std::allocator.0"** %8, align 8
  %10 = getelementptr inbounds %"struct.std::__allocated_ptr", %"struct.std::__allocated_ptr"* %3, i32 0, i32 1
  %11 = load %"struct.std::_List_node"*, %"struct.std::_List_node"** %10, align 8
  invoke void @_ZNSt16allocator_traitsISaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEEEE10deallocateERSB_PSA_m(%"class.std::allocator.0"* dereferenceable(1) %9, %"struct.std::_List_node"* %11, i64 1)
          to label %12 unwind label %14

; <label>:12:                                     ; preds = %7
  br label %13

; <label>:13:                                     ; preds = %12, %1
  ret void

; <label>:14:                                     ; preds = %7
  %15 = landingpad { i8*, i32 }
          catch i8* null
  %16 = extractvalue { i8*, i32 } %15, 0
  call void @__clang_call_terminate(i8* %16) #16
  unreachable
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local %"struct.std::_List_node"* @_ZNSt16allocator_traitsISaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEEEE8allocateERSB_m(%"class.std::allocator.0"* dereferenceable(1), i64) #5 comdat align 2 {
  %3 = alloca %"class.std::allocator.0"*, align 8
  %4 = alloca i64, align 8
  store %"class.std::allocator.0"* %0, %"class.std::allocator.0"** %3, align 8
  store i64 %1, i64* %4, align 8
  %5 = load %"class.std::allocator.0"*, %"class.std::allocator.0"** %3, align 8
  %6 = bitcast %"class.std::allocator.0"* %5 to %"class.__gnu_cxx::new_allocator.1"*
  %7 = load i64, i64* %4, align 8
  %8 = call %"struct.std::_List_node"* @_ZN9__gnu_cxx13new_allocatorISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS3_EEEEE8allocateEmPKv(%"class.__gnu_cxx::new_allocator.1"* %6, i64 %7, i8* null)
  ret %"struct.std::_List_node"* %8
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local %"struct.std::_List_node"* @_ZN9__gnu_cxx13new_allocatorISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS3_EEEEE8allocateEmPKv(%"class.__gnu_cxx::new_allocator.1"*, i64, i8*) #5 comdat align 2 {
  %4 = alloca %"class.__gnu_cxx::new_allocator.1"*, align 8
  %5 = alloca i64, align 8
  %6 = alloca i8*, align 8
  store %"class.__gnu_cxx::new_allocator.1"* %0, %"class.__gnu_cxx::new_allocator.1"** %4, align 8
  store i64 %1, i64* %5, align 8
  store i8* %2, i8** %6, align 8
  %7 = load %"class.__gnu_cxx::new_allocator.1"*, %"class.__gnu_cxx::new_allocator.1"** %4, align 8
  %8 = load i64, i64* %5, align 8
  %9 = call i64 @_ZNK9__gnu_cxx13new_allocatorISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS3_EEEEE8max_sizeEv(%"class.__gnu_cxx::new_allocator.1"* %7) #3
  %10 = icmp ugt i64 %8, %9
  br i1 %10, label %11, label %12

; <label>:11:                                     ; preds = %3
  call void @_ZSt17__throw_bad_allocv() #17
  unreachable

; <label>:12:                                     ; preds = %3
  %13 = load i64, i64* %5, align 8
  %14 = mul i64 %13, 64
  %15 = call i8* @_Znwm(i64 %14)
  %16 = bitcast i8* %15 to %"struct.std::_List_node"*
  ret %"struct.std::_List_node"* %16
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local i64 @_ZNK9__gnu_cxx13new_allocatorISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS3_EEEEE8max_sizeEv(%"class.__gnu_cxx::new_allocator.1"*) #4 comdat align 2 {
  %2 = alloca %"class.__gnu_cxx::new_allocator.1"*, align 8
  store %"class.__gnu_cxx::new_allocator.1"* %0, %"class.__gnu_cxx::new_allocator.1"** %2, align 8
  %3 = load %"class.__gnu_cxx::new_allocator.1"*, %"class.__gnu_cxx::new_allocator.1"** %2, align 8
  ret i64 144115188075855871
}

; Function Attrs: noinline nounwind optnone uwtable
define linkonce_odr dso_local %"class.std::allocator.0"* @_ZSt11__addressofISaISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS2_EEEEEEPT_RSC_(%"class.std::allocator.0"* dereferenceable(1)) #4 comdat {
  %2 = alloca %"class.std::allocator.0"*, align 8
  store %"class.std::allocator.0"* %0, %"class.std::allocator.0"** %2, align 8
  %3 = load %"class.std::allocator.0"*, %"class.std::allocator.0"** %2, align 8
  ret %"class.std::allocator.0"* %3
}

; Function Attrs: noinline optnone uwtable
define linkonce_odr dso_local void @_ZN9__gnu_cxx13new_allocatorISt10_List_nodeISt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS3_EEEEE9constructISA_JRKSA_EEEvPT_DpOT0_(%"class.__gnu_cxx::new_allocator.1"*, %"class.std::map"*, %"class.std::map"* dereferenceable(48)) #5 comdat align 2 {
  %4 = alloca %"class.__gnu_cxx::new_allocator.1"*, align 8
  %5 = alloca %"class.std::map"*, align 8
  %6 = alloca %"class.std::map"*, align 8
  store %"class.__gnu_cxx::new_allocator.1"* %0, %"class.__gnu_cxx::new_allocator.1"** %4, align 8
  store %"class.std::map"* %1, %"class.std::map"** %5, align 8
  store %"class.std::map"* %2, %"class.std::map"** %6, align 8
  %7 = load %"class.__gnu_cxx::new_allocator.1"*, %"class.__gnu_cxx::new_allocator.1"** %4, align 8
  %8 = load %"class.std::map"*, %"class.std::map"** %5, align 8
  %9 = bitcast %"class.std::map"* %8 to i8*
  %10 = bitcast i8* %9 to %"class.std::map"*
  %11 = load %"class.std::map"*, %"class.std::map"** %6, align 8
  %12 = call dereferenceable(48) %"class.std::map"* @_ZSt7forwardIRKSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS1_EEEEOT_RNSt16remove_referenceISB_E4typeE(%"class.std::map"* dereferenceable(48) %11) #3
  call void @_ZNSt3mapIi9NonDetLogSt4lessIiESaISt4pairIKiS0_EEEC2ERKS7_(%"class.std::map"* %10, %"class.std::map"* dereferenceable(48) %12)
  ret void
}

; Function Attrs: noinline uwtable
define internal void @_GLOBAL__sub_I_callerlibtest.cpp() #0 section ".text.startup" {
  call void @__cxx_global_var_init()
  call void @__cxx_global_var_init.1()
  ret void
}

attributes #0 = { noinline uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #3 = { nounwind }
attributes #4 = { noinline nounwind optnone uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #5 = { noinline optnone uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #6 = { noinline norecurse optnone uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #7 = { noinline noreturn nounwind }
attributes #8 = { noinline noreturn nounwind optnone uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #9 = { noreturn nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #10 = { nobuiltin nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #11 = { noreturn "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #12 = { nobuiltin "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #13 = { argmemonly nounwind }
attributes #14 = { nounwind readonly "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #15 = { cold noreturn nounwind }
attributes #16 = { noreturn nounwind }
attributes #17 = { noreturn }
attributes #18 = { nounwind readonly }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{!"clang version 8.0.1-9 (tags/RELEASE_801/final)"}
