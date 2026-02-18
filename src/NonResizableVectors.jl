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
        function Base.parent(x::MemoryVector)
            x.memory
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
        function Base.parent(x::MemoryRefVector)
            parent(x.memory_ref)
        end
    end
    using .GenericMemoryVectors, .GenericMemoryRefVectors
    using LightBoundsErrors: checkbounds_lightboundserror
    export
        MemoryVector, MemoryRefVectorImm, MemoryRefVectorMut
    const NonResizableVector = Union{MemoryVector{T}, MemoryRefVector{T}} where {T}
    function Base.IndexStyle(::Type{<:NonResizableVector})
        @inline IndexLinear()
    end
    function Base.checkbounds(x::NonResizableVector, indices...)
        @inline checkbounds_lightboundserror(x, indices...)
    end
    function Base.iterate(x::NonResizableVector, index = 1)
        @inline let
            index = index::Int
            if checkbounds(Bool, x, index)
                ((@inbounds x[index]), index + 1)
            else
                nothing
            end
        end
    end
    if isdefined(Base, :dataids)  # not public: https://github.com/JuliaLang/julia/issues/51753
        function Base.dataids(x::NonResizableVector)
            Base.dataids(parent(x))  # forward to `dataids(::Memory)`
        end
    end
end
