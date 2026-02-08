# TODO: test suite
#
# TODO: add methods for `Base.dataids`
#
# TODO: add methods for single-argument `Base.getindex`, if beneficial
#
# TODO: add methods for two-argument `Base.getindex` where the second argument is a `Colon`, if beneficial
#
# TODO: add methods for `Base.copy`, if beneficial
#
# TODO: add methods for destructuring interface (`Base.rest`), if beneficial
#
# TODO: add methods for destructuring interface (`Base.split_rest`), if beneficial
#
# TODO: add methods for destructuring interface (`Base.indexed_iterate`), if beneficial
#
# TODO: add methods for five-argument `Base.copyto!`, if beneficial
#
# TODO: add methods for two-argument `Base.copyto!`, if beneficial
#
# TODO: add methods for `Base.copy!`, if beneficial
#
# TODO: implement the Collects.jl interface: add methods for `function (::Collect)(::Type{V}, ::Any) where {V<:NonResizableVector}`
#
# TODO: implement the dense array interface/the strided array interface
module NonResizableVectors
    module ShowSplatted
        export show_splatted
        function print_comma_blank(io::IO)
            print(io, ',')
            print(io, ' ')
        end
        function show_splatted(io::IO, iterator)
            ei1 = Iterators.peel(iterator)
            if ei1 === nothing
                return  # `iterator` is empty, return without printing anything
            end
            (e1, i1) = ei1
            show(io, e1)
            ei2 = Iterators.peel(i1)
            if ei2 === nothing
                return  # `iterator` had only a single element, we already printed it, return now
            end
            (e2, i2) = ei2
            print_comma_blank(io)
            show(io, e2)
            for e ∈ i2
                print_comma_blank(io)
                show(io, e)
            end
        end
    end
    module LightBoundsErrors
        using ..ShowSplatted
        export LightBoundsError, throw_lightboundserror, checkbounds_lightboundserror
        mutable struct LightBoundsError <: Exception
            const collection_type::DataType
            const collection_axes::Tuple
            const requested_indices::Tuple
            function LightBoundsError(; collection_type::DataType, collection_axes::Tuple, requested_indices::Tuple)
                @inline new(collection_type, collection_axes, requested_indices)
            end
        end
        function Base.showerror(io::IO, ex::LightBoundsError)
            show(io, typeof(ex))
            print(io, ": out-of-bounds indexing: `collection[")
            show_splatted(io, ex.requested_indices)
            print(io, "]`, where `typeof(collection) == ")
            show(io, ex.collection_type)
            print(io, "` and `axes(collection) == ")
            show(io, ex.collection_axes)
            print(io, '`')
            nothing
        end
        function throw_lightboundserror(x, requested_indices)
            @inline let
                collection_type = typeof(x)
                collection_axes = axes(x)
                ex = LightBoundsError(; collection_type, collection_axes, requested_indices)
                throw(ex)
            end
        end
        function checkbounds_lightboundserror_impl(checkbounds::C, x, requested_indices...) where {C}
            @inline let
                is_inbounds = checkbounds(Bool, x, requested_indices...)
                if !is_inbounds
                    throw_lightboundserror(x, requested_indices)
                end
                nothing
            end
        end
        function checkbounds_lightboundserror(x, requested_indices...)
            @inline checkbounds_lightboundserror_impl(checkbounds, x, requested_indices...)
        end
    end
    module CheckboundsOneBased
        using ..LightBoundsErrors
        export checkbounds_one_based
        function in_one_to(x::Int, m::Int)
            @inline let
                a = unsigned(x - one(x))
                b = unsigned(m)
                a < b
            end
        end
        function checkbounds_one_based(::Type{Bool}, x::AbstractVector, index::Int)
            @inline let
                len = length(x)
                in_one_to(index, len)
            end
        end
    end
    module Miscellaneous
        export vector_supertype, memory_type
        const vector_supertype = AbstractVector  # TODO: consider switching to `DenseVector`
        function memory_type(::Val{isatomic}, ::Type{T}, ::Val{addrspace}) where {isatomic, T, addrspace}
            @inline GenericMemory{isatomic::Symbol, T, addrspace::Core.AddrSpace}
        end
    end
    module GenericMemoryVectors
        using ..Miscellaneous
        export GenericMemoryVector, MemoryVector
        struct GenericMemoryVector{isatomic, T, addrspace} <: vector_supertype{T}
            memory::GenericMemory{isatomic, T, addrspace}
            function GenericMemoryVector{isatomic, T, addrspace}(::UndefInitializer, n::Int) where {isatomic, T, addrspace}
                @inline let
                    mt = memory_type(Val(isatomic), T, Val(addrspace))
                    memory = mt(undef, n)
                    new(memory)
                end
            end
        end
        const MemoryVector = GenericMemoryVector{:not_atomic, T, Core.CPU} where {T}
        function Base.size(x::MemoryVector)
            @inline size(x.memory)
        end
        Base.@propagate_inbounds function Base.getindex(x::MemoryVector, index::Int)
            @inline let
                @boundscheck checkbounds(x, index)
                @inbounds x.memory[index]
            end
        end
        Base.@propagate_inbounds function Base.setindex!(x::MemoryVector, element, index::Int)
            @inline let
                @boundscheck checkbounds(x, index)
                @inbounds x.memory[index] = element
                x
            end
        end
        Base.@propagate_inbounds function Base.isassigned(x::MemoryVector, index::Int)
            @inline isassigned(x.memory, index)::Bool
        end
    end
    module GenericMemoryRefVectors
        using ..Miscellaneous
        export
            GenericMemoryRefVectorImm, GenericMemoryRefVectorMut, GenericMemoryRefVector,
            MemoryRefVectorImm, MemoryRefVectorMut, MemoryRefVector
        struct GenericMemoryRefVectorImm{isatomic, T, addrspace} <: vector_supertype{T}
            memory_ref::GenericMemoryRef{isatomic, T, addrspace}
            function GenericMemoryRefVectorImm{isatomic, T, addrspace}(::UndefInitializer, n::Int) where {isatomic, T, addrspace}
                @inline let
                    mt = memory_type(Val(isatomic), T, Val(addrspace))
                    memory = mt(undef, n)
                    memory_ref = memoryref(memory)
                    new(memory_ref)
                end
            end
        end
        mutable struct GenericMemoryRefVectorMut{isatomic, T, addrspace} <: vector_supertype{T}
            const memory_ref::GenericMemoryRef{isatomic, T, addrspace}
            function GenericMemoryRefVectorMut{isatomic, T, addrspace}(::UndefInitializer, n::Int) where {isatomic, T, addrspace}
                @inline let
                    mt = memory_type(Val(isatomic), T, Val(addrspace))
                    memory = mt(undef, n)
                    memory_ref = memoryref(memory)
                    new(memory_ref)
                end
            end
        end
        const GenericMemoryRefVector = Union{GenericMemoryRefVectorImm{isatomic, T, addrspace}, GenericMemoryRefVectorMut{isatomic, T, addrspace}} where {isatomic, T, addrspace}
        const MemoryRefVector = GenericMemoryRefVector{:not_atomic, T, Core.CPU} where {T}
        const MemoryRefVectorImm = GenericMemoryRefVectorImm{:not_atomic, T, Core.CPU} where {T}
        const MemoryRefVectorMut = GenericMemoryRefVectorMut{:not_atomic, T, Core.CPU} where {T}
        struct MemoryOffsetException <: Exception
            offset::Int
            function MemoryOffsetException(offset::Int)
                @inline new(offset)
            end
        end
        function memory_index(r)  # compat wrapper
            @inline let
                @static if hasproperty(Base, :memoryindex)
                    Base.memoryindex(r)
                else
                    Base.memoryrefoffset(r)  # for older versions of Julia, fall back to the non-public functionality
                end
            end
        end
        function validated_memory_ref(x::GenericMemoryRefVector)
            @inline let
                memory_ref = x.memory_ref
                offset_into_memory = memory_index(memory_ref)
                if offset_into_memory !== 1
                    throw(MemoryOffsetException(offset_into_memory))
                end
                memory_ref
            end
        end
        function Base.size(x::MemoryRefVector)
            @inline let
                memory_ref = validated_memory_ref(x)
                size(memory_ref.mem)
            end
        end
        Base.@propagate_inbounds function Base.getindex(x::MemoryRefVector, index::Int)
            @inline let
                @boundscheck checkbounds(x, index)
                memory_ref = validated_memory_ref(x)
                memory_ref_with_offset = @inbounds memoryref(memory_ref, index)
                memory_ref_with_offset[]
            end
        end
        Base.@propagate_inbounds function Base.setindex!(x::MemoryRefVector, element, index::Int)
            @inline let
                @boundscheck checkbounds(x, index)
                memory_ref = validated_memory_ref(x)
                memory_ref_with_offset = @inbounds memoryref(memory_ref, index)
                memory_ref_with_offset[] = element
                x
            end
        end
        Base.@propagate_inbounds function Base.isassigned(x::MemoryRefVector, index::Int)
            @inline let
                if !checkbounds(Bool, x, index)
                    return false
                end
                memory_ref = validated_memory_ref(x)
                memory_ref_with_offset = @inbounds memoryref(memory_ref, index)
                isassigned(memory_ref_with_offset)::Bool
            end
        end
    end
    using .LightBoundsErrors, .CheckboundsOneBased, .GenericMemoryVectors, .GenericMemoryRefVectors
    export
        MemoryVector, MemoryRefVectorImm, MemoryRefVectorMut
    const NonResizableVector = Union{MemoryVector{T}, MemoryRefVector{T}} where {T}
    function Base.IndexStyle(::Type{<:NonResizableVector})
        @inline IndexLinear()
    end
    function Base.checkbounds(::Type{Bool}, x::NonResizableVector, index::Int)
        @inline checkbounds_one_based(Bool, x, index)
    end
    function Base.checkbounds(x::NonResizableVector, indices...)
        @inline checkbounds_lightboundserror(x, indices...)
    end
    function Base.iterate(x::NonResizableVector, index)
        @inline let
            index = index::Int
            if checkbounds(Bool, x, index)
                ((@inbounds x[index]), index + 1)
            else
                nothing
            end
        end
    end
end
