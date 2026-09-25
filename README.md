# About
A zig native library for the Apache Arrow format.  
This is mostly a for fun project with the hopes of creating a data exploring application in the future.  

# Current state
The priority is to implement the arrays.
This will be followed by the IPC implementation to verify array accuracy.
Finally, the compute kernels will be implemented.

# TODO
## Arrays
    - Create bitmap struct in utils *** Next item
    - Retrieve function **
    - Append function **
    - Remove function **
    - Streaming function **

### Remaining Arrays
    - Binary View ***
    - Null array ***
    - Dictionary ***
    - List ***
    - Object ***

### Primitives
    - Add Primitive 128 

### Binary
    - Create u64 offset variant

### BinaryView
    - Potential bug if source len is > 64kb

## IPC
    - Create IPC streaming ***
### I/O
    - Create DuckDB interface **

## Manipulation
    - Add compute kernels *


