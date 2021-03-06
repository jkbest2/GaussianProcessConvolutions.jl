__precompile__(true)

module GaussianProcessConvolutions

using Base
using Distributions
using PDMats

import PDMats: dim

export
    # Convolution Kernels
    AbstractConvolutionKernel,
    SquaredExponentialKernel,
    # Basic type
    GaussianProcessConvolution,
    GaussianProcessSample,
    # Methods
    dim,		    # get dimensionality of process or kernel
    conv_wt,	    # Get convolution weights for a new location
    knot_wt,        # Return matrix of conv weights for new locations
    nknot,	        # Return number of knots
    predict        # Give value of GP at new locations

# include convolution kernels
include("ConvolutionKernels.jl")

#----------------------------------------------------------------------------
# Basic type
immutable GaussianProcessConvolution
    knot_locs::Array
    knot_values::Array
    dim::Integer
    nknot::Integer
    GaussianProcessConvolution(knot_locs::Array, knot_values::Vector) =
      new(knot_locs,
          knot_values,
          size(knot_locs, 2),
          size(knot_locs, 1))
    GaussianProcessConvolution(knot_locs::Array, dist::UnivariateDistribution) =
      new(knot_locs,
          rand(dist, size(knot_locs, 1)),
          size(knot_locs, 2),
          size(knot_locs, 1))
    GaussianProcessConvolution(knot_locs::Array) =
      GaussianProcessConvolution(knot_locs, Normal(0, 1))
end

knot_locs(GPC::GaussianProcessConvolution) = GPC.knot_locs
knot_values(GPC::GaussianProcessConvolution) = GPC.knot_values
nknot(GPC::GaussianProcessConvolution) = GPC.nknot
dim(GPC::GaussianProcessConvolution) = GPC.dim

#------------------------------------------------------------------------------
# Putting them together
function predict(GPC::GaussianProcessConvolution,
                 kern::AbstractConvolutionKernel,
                 new_loc::Array)

    nnew = size(new_loc, 1)
    new_val = zeros(nnew)

    for l in 1:nnew
      d = GPC.knot_locs' .- new_loc'[:, l]
      new_val[l] = dot(conv_wt(kern, d), GPC.knot_values)
    end
    new_val
end

function predict(GPC::GaussianProcessConvolution,
                 knot_wt::Array)
    knot_wt * GPC.knot_values
end

"""
    knot_wt(GPC::GaussianProcessConvolution,
            kern::AbstractConvolutionKernel,
            new_locs::Array{Float64})

Calculate knot weight matrix for set of new locations. Returns one row per
new location, one column per knot location, so knot_wt * knot_val gives the
value of the process at new locations.
"""
function knot_wt(gpc::GaussianProcessConvolution,
                 kern::AbstractConvolutionKernel,
                 new_locs::Array{Float64})
    nloc = size(new_locs, 1)
    k_wt = Array{Float64, 2}(nloc, nknot(gpc))

    for l in 1:nloc
        k_wt[l, :] = conv_wt(kern, knot_locs(gpc)' .- new_locs[l, :])'
    end
    k_wt
end

function knot_wt(knot_locs::Array{Float64},
                 kern::AbstractConvolutionKernel,
                 new_locs::Array{Float64})
    nloc = size(new_locs, 1)
    nknot = size(knot_locs, 1)
    k_wt = Array{Float64, 2}(nloc, nknot)

    for l in 1:nloc
        k_wt[l, :] = conv_wt(kern, knot_locs' .- new_locs[l, :])'
    end
    k_wt
end

# Include efficient sample storage type
include("sampling.jl")

end  # module
