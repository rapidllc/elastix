add_executable(ElastixLibGTest
  ElastixLibGTest.cxx
)

target_link_libraries( ElastixLibGTest
  GTest::GTest
  GTest::Main
  elastix
  ${ITK_LIBRARIES}
)

if( ELASTIX_USE_OPENCL )
  target_link_libraries( ElastixLibGTest elxOpenCL )
endif()

add_test(NAME ElastixLibGTest_test COMMAND ElastixLibGTest)
