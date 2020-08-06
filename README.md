# Map2Check-Library
C++ library to support Map2Check Tool. 

## To build:
```Console
$ mkdir build
$ cp build
$ cmake .. -DCMAKE_INSTALL_PREFIX=../release-library/
$ make
$ make install
```

## Data Storage

### NonDetLog: Save the data about nondet functions call.

#### **Old Model**: Step -> NonDetLog(v1..v5)

```C
map2check_nondet_type(
    unsigned line, unsigned scope, int value, const char *function_name
)

NONDET_CALL new_nondet_call(
    enum NONDET_TYPE type, unsigned line,
    unsigned scope, void *value, const char *function_name, unsigned step
)
```

#### **New Model**

In this new data model, we aims to create a model object for each data structure that need a storage, e.g., NonDetLog that has all data about nondet call functions. In this sense, we have a Container object that handle with the storage for each data structure using STL.

- Container Object:
```json
{
    "Container" : {        
        "object_model"  : {
            "in"    : "template <typename T> obj",
            "out-k" : "for each obj k of type T in {nondetlog} we have a list<map<unsigned, T>>", 
        },
        "append_obj"    : void,
        "sizefof_obj"   : {
            "in" : void,
            "out": unsigned
        },
    }
}
```
,
- NonDetLog Object:
```json
{
    "NonDetLog" : {        
        "line"          : unsigned,
        "scope"         : unsigned,
        "value"         : template <typename T>,
        "function_name" : const char *
    }
}
```

```C++

// Object
In : NonDetLog nondet_obj;
Out: 1 => {} 

/** Data structure, where n is the number of the step, and {} is NonDetLog * object from that step **/
In : list<map<unsigned, NonDetLog>> nondet_obj_list;
Out: N => [1 : {}, ... n : {}] 

```

a = int obj
b = float obj


list_container = {a, b}





