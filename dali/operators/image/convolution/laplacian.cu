// Copyright (c) 2022, NVIDIA CORPORATION & AFFILIATES. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <memory>
#include <vector>

#include "dali/core/static_switch.h"
#include "dali/operators/image/convolution/laplacian.h"
#include "dali/operators/image/convolution/laplacian_gpu.h"
#include "dali/pipeline/operator/common.h"


namespace dali {
namespace laplacian {

extern template op_impl_uptr GetLaplacianGpuImpl<uint8_t, uint8_t>(const OpSpec*,
                                                                   const DimDesc& dim_desc);
extern template op_impl_uptr GetLaplacianGpuImpl<float, uint8_t>(const OpSpec*,
                                                                 const DimDesc& dim_desc);

extern template op_impl_uptr GetLaplacianGpuImpl<int8_t, int8_t>(const OpSpec*,
                                                                 const DimDesc& dim_desc);
extern template op_impl_uptr GetLaplacianGpuImpl<float, int8_t>(const OpSpec*,
                                                                const DimDesc& dim_desc);

extern template op_impl_uptr GetLaplacianGpuImpl<uint16_t, uint16_t>(const OpSpec*,
                                                                     const DimDesc& dim_desc);
extern template op_impl_uptr GetLaplacianGpuImpl<float, uint16_t>(const OpSpec*,
                                                                  const DimDesc& dim_desc);

extern template op_impl_uptr GetLaplacianGpuImpl<int16_t, int16_t>(const OpSpec*,
                                                                   const DimDesc& dim_desc);
extern template op_impl_uptr GetLaplacianGpuImpl<float, int16_t>(const OpSpec*,
                                                                 const DimDesc& dim_desc);

extern template op_impl_uptr GetLaplacianGpuImpl<uint32_t, uint32_t>(const OpSpec*,
                                                                     const DimDesc& dim_desc);
extern template op_impl_uptr GetLaplacianGpuImpl<float, uint32_t>(const OpSpec*,
                                                                  const DimDesc& dim_desc);

extern template op_impl_uptr GetLaplacianGpuImpl<int32_t, int32_t>(const OpSpec*,
                                                                   const DimDesc& dim_desc);
extern template op_impl_uptr GetLaplacianGpuImpl<float, int32_t>(const OpSpec*,
                                                                 const DimDesc& dim_desc);

extern template op_impl_uptr GetLaplacianGpuImpl<uint64_t, uint64_t>(const OpSpec*,
                                                                     const DimDesc& dim_desc);
extern template op_impl_uptr GetLaplacianGpuImpl<float, uint64_t>(const OpSpec*,
                                                                  const DimDesc& dim_desc);

extern template op_impl_uptr GetLaplacianGpuImpl<int64_t, int64_t>(const OpSpec*,
                                                                   const DimDesc& dim_desc);
extern template op_impl_uptr GetLaplacianGpuImpl<float, int64_t>(const OpSpec*,
                                                                 const DimDesc& dim_desc);

extern template op_impl_uptr GetLaplacianGpuImpl<float, float>(const OpSpec*,
                                                               const DimDesc& dim_desc);

}  // namespace laplacian

template <>
bool Laplacian<GPUBackend>::SetupImpl(std::vector<OutputDesc>& output_desc,
                                      const workspace_t<GPUBackend>& ws) {
  const auto& input = ws.template Input<GPUBackend>(0);
  auto layout = input.GetLayout();
  auto dim_desc = ParseAndValidateDim(input.shape().sample_dim(), layout);
  auto dtype = dtype_ == DALI_NO_TYPE ? input.type() : dtype_;
  DALI_ENFORCE(dtype == input.type() || dtype == DALI_FLOAT,
               "Output data type must be same as input, FLOAT or skipped (defaults to input type)");

  if (!impl_ || impl_in_dtype_ != input.type() || impl_dim_desc_ != dim_desc) {
    impl_in_dtype_ = input.type();
    impl_dim_desc_ = dim_desc;

    TYPE_SWITCH(input.type(), type2id, In, LAPLACIAN_GPU_SUPPORTED_TYPES, (
      if (dtype == input.type()) {
        impl_ = laplacian::GetLaplacianGpuImpl<In, In>(&spec_, dim_desc);
      } else {
        impl_ = laplacian::GetLaplacianGpuImpl<float, In>(&spec_, dim_desc);
      }
    ), DALI_FAIL(make_string("Unsupported data type: ", input.type())));  // NOLINT
  }

  return impl_->SetupImpl(output_desc, ws);
}

template <>
void Laplacian<GPUBackend>::RunImpl(workspace_t<GPUBackend>& ws) {
  impl_->RunImpl(ws);
}

DALI_REGISTER_OPERATOR(Laplacian, Laplacian<GPUBackend>, GPU);

}  // namespace dali
