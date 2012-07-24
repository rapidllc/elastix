/*======================================================================

  This file is part of the elastix software.

  Copyright (c) University Medical Center Utrecht. All rights reserved.
  See src/CopyrightElastix.txt or http://elastix.isi.uu.nl/legal.php for
  details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE. See the above copyright notices for more information.

======================================================================*/

// OpenCL implementation of itk::BSplineTransform

//------------------------------------------------------------------------------
#ifdef DIM_1
bool inside_valid_region_1d(const float ind,
                            __constant GPUImageBase1D *coefficients_image)
{
  uint grid_size = coefficients_image->Size;
  float index = ind;
  const float min_limit = 0.5 * (float)(GPUBSplineTransformOrder - 1);
  bool inside = true;
  float max_limit = (float)(grid_size) - 0.5
    * (float)(GPUBSplineTransformOrder - 1) - 1.0;
  // originally if( index[j] == max_limit ) has been changed to
  if( math_abs( index - max_limit ) < 1e-6 )
  {
    index -= 1e-6;
  }
  else if( index >= max_limit )
  {
    inside = false;
  }
  else if( index < min_limit )
  {
    inside = false;
  }
  return inside;
}
#endif // DIM_1

//------------------------------------------------------------------------------
#ifdef DIM_2
bool inside_valid_region_2d(const float2 ind,
                            __constant GPUImageBase2D *coefficients_image)
{
  uint grid_size[2];
  float index[2];
  index[0] = ind.x;
  index[1] = ind.y;
  grid_size[0] = coefficients_image->Size.x;
  grid_size[1] = coefficients_image->Size.y;
  const float min_limit = 0.5 * (float)(GPUBSplineTransformOrder - 1);
  bool inside = true;
  for(uint j = 0; j < 2; j++)
  {
    float max_limit = (float)(grid_size[j]) - 0.5
      * (float)(GPUBSplineTransformOrder - 1) - 1.0;
    // originally if( index[j] == max_limit ) has been changed to
    if( math_abs( index[j] - max_limit ) < 1e-6 )
    {
      index[j] -= 1e-6;
    }
    else if( index[j] >= max_limit )
    {
      inside = false;
      break;
    }
    else if( index[j] < min_limit )
    {
      inside = false;
      break;
    }
  }
  return inside;
}
#endif // DIM_2

//------------------------------------------------------------------------------
#ifdef DIM_3
bool inside_valid_region_3d(const float3 ind,
                            __constant GPUImageBase3D *coefficients_image)
{
  uint grid_size[3];
  float index[3];
  index[0] = ind.x;
  index[1] = ind.y;
  index[2] = ind.z;
  grid_size[0] = coefficients_image->Size.x;
  grid_size[1] = coefficients_image->Size.y;
  grid_size[2] = coefficients_image->Size.z;
  const float min_limit = 0.5 * (float)(GPUBSplineTransformOrder - 1);
  bool inside = true;
  for(uint j = 0; j < 3; j++)
  {
    float max_limit = (float)(grid_size[j]) - 0.5
      * (float)(GPUBSplineTransformOrder - 1) - 1.0;
    // originally if( index[j] == max_limit ) has been changed to
    if( math_abs( index[j] - max_limit ) < 1e-6 )
    {
      index[j] -= 1e-6;
    }
    else if( index[j] >= max_limit )
    {
      inside = false;
      break;
    }
    else if( index[j] < min_limit )
    {
      inside = false;
      break;
    }
  }
  return inside;
}
#endif // DIM_3

//------------------------------------------------------------------------------
float kernel_evaluate(float u)
{
  // third order spline.
  float absValue = math_abs(u);
  float sqrValue = u*u;

  if ( absValue < 1.0 )
  {
    return ( 4.0 - 6.0 * sqrValue + 3.0 * sqrValue * absValue ) / 6.0;
  }
  else if ( absValue < 2.0 )
  {
    return ( 8.0 - 12 * absValue + 6.0 * sqrValue
      - sqrValue * absValue ) / 6.0;
  }
  else
  {
    return 0.0;
  }
}

//------------------------------------------------------------------------------
#ifdef DIM_1
long evaluate_1d(const float ind, float* weights)
{
  long start_index;
  float index = ind;

  // define offset_to_index_table
  ulong offset_to_index_table[GPUBSplineTransformNumberOfWeights];
  uint support_size = GPUBSplineTransformOrder + 1;
  for(uint i = 0; i < support_size; i++)
  {
    offset_to_index_table[i] = i;
  }

  // find the starting index of the support region
  start_index = (long)(floor(index - (float)(GPUBSplineTransformOrder - 1) / 2.0));

  // compute the weights
  float weights1D[GPUBSplineTransformOrder+1];
  float x = index - (float)(start_index);
  for (uint k = 0; k <= GPUBSplineTransformOrder; k++)
  {
    weights1D[k] = kernel_evaluate(x);
    x -= 1.0;
  }

  for (uint k = 0; k < GPUBSplineTransformNumberOfWeights; k++)
  {
    weights[k] = 1.0;
    weights[k] *= weights1D[offset_to_index_table[k]];
  }

  // return start index
  return start_index;
}
#endif // DIM_1

//------------------------------------------------------------------------------
#ifdef DIM_2
long2 evaluate_2d(const float2 ind, float* weights)
{
  long start_index[2];
  float index[2];
  index[0] = ind.x;
  index[1] = ind.y;

  // define offset_to_index_table
  ulong offset_to_index_table[GPUBSplineTransformNumberOfWeights][2];
  uint support_size = GPUBSplineTransformOrder + 1;
  ulong counter = 0;
  for(uint j = 0; j < support_size; j++)
  {
    for(uint i = 0; i < support_size; i++)
    {
      offset_to_index_table[counter][0] = i;
      offset_to_index_table[counter][1] = j;
      ++counter;
    }
  }

  // find the starting index of the support region
  for (uint j = 0; j < 2; j++)
  {
    start_index[j] = (long)(floor(index[j] - (float)(GPUBSplineTransformOrder - 1) / 2.0));
  }

  // compute the weights
  float weights1D[2][GPUBSplineTransformOrder+1];
  for (uint j = 0; j < 2; j++)
  {
    float x = index[j] - (float)(start_index[j]);

    for (uint k = 0; k <= GPUBSplineTransformOrder; k++)
    {
      weights1D[j][k] = kernel_evaluate(x);
      x -= 1.0;
    }
  }

  for (uint k = 0; k < GPUBSplineTransformNumberOfWeights; k++)
  {
    weights[k] = 1.0;
    for (uint j = 0; j < 2; j++)
    {
      weights[k] *= weights1D[j][offset_to_index_table[k][j]];
    }
  }

  // return start index
  long2 startindex;
  startindex.x = start_index[0];
  startindex.y = start_index[1];

  return startindex;
}
#endif // DIM_2

//------------------------------------------------------------------------------
#ifdef DIM_3
long3 evaluate_3d(const float3 ind, float* weights)
{
  long start_index[3];
  float index[3];
  index[0] = ind.x;
  index[1] = ind.y;
  index[2] = ind.z;

  // define offset_to_index_table
  ulong offset_to_index_table[GPUBSplineTransformNumberOfWeights][3];
  uint support_size = GPUBSplineTransformOrder + 1;
  ulong counter = 0;
  for(uint k = 0; k < support_size; k++)
  {
    for(uint j = 0; j < support_size; j++)
    {
      for(uint i = 0; i < support_size; i++)
      {
        offset_to_index_table[counter][0] = i;
        offset_to_index_table[counter][1] = j;
        offset_to_index_table[counter][2] = k;
        ++counter;
      }
    }
  }

  // find the starting index of the support region
  for (uint j = 0; j < 3; j++)
  {
    start_index[j] = (long)(floor(index[j] - (float)(GPUBSplineTransformOrder - 1) / 2.0));
  }

  // compute the weights
  float weights1D[3][GPUBSplineTransformOrder+1];
  for (uint j = 0; j < 3; j++)
  {
    float x = index[j] - (float)(start_index[j]);

    for (uint k = 0; k <= GPUBSplineTransformOrder; k++)
    {
      weights1D[j][k] = kernel_evaluate(x);
      x -= 1.0;
    }
  }

  for (uint k = 0; k < GPUBSplineTransformNumberOfWeights; k++)
  {
    weights[k] = 1.0;
    for (uint j = 0; j < 3; j++)
    {
      weights[k] *= weights1D[j][offset_to_index_table[k][j]];
    }
  }

  // return start index
  long3 startindex;
  startindex.x = start_index[0];
  startindex.y = start_index[1];
  startindex.z = start_index[2];

  return startindex;
}
#endif // DIM_3

#ifdef DIM_1
//------------------------------------------------------------------------------
float transform_point_1d(const float point,
                         __constant GPUMatrixOffsetTransformBase1D* transform_base)
{
  float tpoint;
  return tpoint;
}

//------------------------------------------------------------------------------
float bspline_transform_point_1d(const float point,
                                 __global const INTERPOLATOR_PRECISION_TYPE* coefficients,
                                 __constant GPUImageBase1D *coefficients_image)
{
  float tpoint = 0;
  float index;
  transform_physical_point_to_continuous_index_1d(point, &index, coefficients_image);

  bool inside = inside_valid_region_1d( index, coefficients_image );
  if( !inside )
  {
    tpoint = point;
    return tpoint;
  }

  // evaluate
  float weights[GPUBSplineTransformNumberOfWeights];
  long support_index = evaluate_1d(index, weights);
  uint support_size = (uint)(GPUBSplineTransformOrder + 1);
  uint support_region = support_index + support_size;

  // multiply weight with coefficient
  ulong counter = 0;
  for(uint i=(uint)(support_index); i<support_region; i++)
  {
    if(i < coefficients_image->Size)
    {
      uint gidx = i;

      float c = coefficients[gidx];
      tpoint += (float)(weights[counter] * c);

      ++counter;
    }
  }

  tpoint += point;

  return tpoint;
}
#endif // DIM_1

#ifdef DIM_2
//------------------------------------------------------------------------------
// purposely not implemented. Supporting OpenCL compilation.
float2 transform_point_2d(const float2 point,
                          __constant GPUMatrixOffsetTransformBase2D* transform_base)
{
  float2 tpoint;
  return tpoint;
}

//------------------------------------------------------------------------------
float2 bspline_transform_point_2d(const float2 point,
                                  __global const INTERPOLATOR_PRECISION_TYPE* coefficients0,
                                  __constant GPUImageBase2D *coefficients_image0,
                                  __global const INTERPOLATOR_PRECISION_TYPE* coefficients1,
                                  __constant GPUImageBase2D *coefficients_image1)
{
  float2 tpoint = (float2)(0,0);
  float2 index;
  transform_physical_point_to_continuous_index_2d(point, &index, coefficients_image0);

  bool inside = inside_valid_region_2d( index, coefficients_image0 );
  if( !inside )
  {
    tpoint = point;
    return tpoint;
  }

  // evaluate
  float weights[GPUBSplineTransformNumberOfWeights];
  long2 support_index = evaluate_2d(index, weights);
  uint support_size = (uint)(GPUBSplineTransformOrder + 1);
  uint2 support_region;
  support_region.x = support_index.x + support_size;
  support_region.y = support_index.y + support_size;

  // multiply weight with coefficient
  ulong counter = 0;
  for(uint j=(uint)(support_index.y); j<support_region.y; j++)
  {
    for(uint i=(uint)(support_index.x); i<support_region.x; i++)
    {
      if(i < coefficients_image0->Size.x && j < coefficients_image0->Size.y)
      {
        uint gidx = coefficients_image0->Size.x * j + i;
        // uint gidx = mad( j, coefficients_image0->Size.x, i );

        float c0 = coefficients0[gidx];
        float c1 = coefficients1[gidx];

        tpoint.x += (float)(weights[counter] * c0);
        tpoint.y += (float)(weights[counter] * c1);

        // #ifdef special
        //tpoint.y = mad( c1, weights[counter], tpoint.y );

        ++counter;
      }
    }
  }

  tpoint += point;

  return tpoint;
}
#endif // DIM_2

#ifdef DIM_3
//------------------------------------------------------------------------------
// purposely not implemented. Supporting OpenCL compilation.
float3 transform_point_3d(const float3 point,
                          __constant GPUMatrixOffsetTransformBase3D* transform_base)
{
  float3 tpoint;
  return tpoint;
}

//------------------------------------------------------------------------------
float3 bspline_transform_point_3d(const float3 point,
                                  __global const INTERPOLATOR_PRECISION_TYPE* coefficients0,
                                  __constant GPUImageBase3D *coefficients_image0,
                                  __global const INTERPOLATOR_PRECISION_TYPE* coefficients1,
                                  __constant GPUImageBase3D *coefficients_image1,
                                  __global const INTERPOLATOR_PRECISION_TYPE* coefficients2,
                                  __constant GPUImageBase3D *coefficients_image2)
{
  float3 tpoint = (float3)(0,0,0);
  float3 index;
  transform_physical_point_to_continuous_index_3d(point, &index, coefficients_image0);

  bool inside = inside_valid_region_3d( index, coefficients_image0 );
  if( !inside )
  {
    tpoint = point;
    return tpoint;
  }

  // evaluate
  float weights[GPUBSplineTransformNumberOfWeights];
  long3 support_index = evaluate_3d(index, weights);
  uint support_size = (uint)(GPUBSplineTransformOrder + 1);
  uint3 support_region;
  support_region.x = support_index.x + support_size;
  support_region.y = support_index.y + support_size;
  support_region.z = support_index.z + support_size;

  // multiply weight with coefficient
  ulong counter = 0;
  for(uint k=(uint)(support_index.z); k<support_region.z; k++)
  {
    for(uint j=(uint)(support_index.y); j<support_region.y; j++)
    {
      for(uint i=(uint)(support_index.x); i<support_region.x; i++)
      {
        /* NOTE: More than three-level nested conditional statements (e.g.,
        if A && B && C..) invalidates command queue during kernel
        execution on Apple OpenCL 1.0 (such Macbook Pro with NVIDIA 9600M
        GT). Therefore, we flattened conditional statements. */
        bool is_valid = true;
        if(i >= coefficients_image0->Size.x) is_valid = false;
        if(j >= coefficients_image0->Size.y) is_valid = false;
        if(k >= coefficients_image0->Size.z) is_valid = false;

        if( is_valid )
        {
          uint gidx = coefficients_image0->Size.x *(k * coefficients_image0->Size.y + j) + i;

          float c0 = coefficients0[gidx];
          float c1 = coefficients1[gidx];
          float c2 = coefficients2[gidx];

          tpoint.x += (float)(weights[counter] * c0);
          tpoint.y += (float)(weights[counter] * c1);
          tpoint.z += (float)(weights[counter] * c2);

          ++counter;
        }
      }
    }
  }

  tpoint += point;

  return tpoint;
}
#endif // DIM_3
