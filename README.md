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

<!-- Using https://mermaidjs.github.io/mermaid-live-editor -->

## Map2Check flow with the library

[![](https://mermaid.ink/img/eyJjb2RlIjoiZ3JhcGggTFIgICAgIFxuICAgIEFbQyBDb2RlXTo6OnNvbWVjbGFzcyAtLT4gQihDbGFuZylcbiAgICBzdWJncmFwaCBMTFZNIGJ1aWxkICAgIFxuICAgIEIgLS0-IENbQml0Y29kZS5iY10gICAgXG4gICAgZW5kXG4gICAgc3ViZ3JhcGggTWFwMkNoZWNrIFBBU1MgQ29kZSBUcmFuc2Zvcm1hdGlvblxuICAgIEMgLS0-IEMxKENoZWNrIENvZGUgUHJvZmlsZSlcbiAgICBDMSAtLT4gQzIoR2VuZXJhdGUgTWljcm8tY29kZSlcbiAgICBDMSAtLT4gQzMoQ29kZSBJbnN0cnVtZW50YXRpb24pXG4gICAgZW5kXG4gICAgc3ViZ3JhcGggRXhlY3V0aW9uIEFuYWx5c2lzXG4gICAgRChsaWJtYXAyY2hlY2suYSkgLS0-IEMyXG4gICAgRCAtLT4gQzMgICAgICAgIFxuICAgIEMyIC0tPkZbTmV3IEJpdGNvZGUuYmNdXG4gICAgQzMgLS0-RltOZXcgQml0Y29kZS5iY11cbiAgICBGLS0-RjEoRnV6emVyIFJ1bilcbiAgICBGMS0tPkZcbiAgICBGLS0-RjIoS0xFRSBSdW4pICBcbiAgICBGMi0tPkYgIFxuICAgIGVuZFxuICAgIHN1YmdyYXBoIFJlc3VsdCBBbmFseXNpc1xuICAgIEYtLT5HKENoZWNrIFByb3BlcnR5IExvZylcbiAgICBHLS0-RzF7Q2hlY2sgUmVzdWx0fVxuICAgIEcxLS0-RzJbVFJVRV06Ojpzb21lY2xhc3NcbiAgICBHMS0tPkczW0ZBTFNFXTo6OnNvbWVjbGFzc1xuICAgIEcxLS0-RzRbVU5LTk9XTl06Ojpzb21lY2xhc3NcbiAgICBlbmQgIFxuXG4gICAgY2xhc3NEZWYgc29tZWNsYXNzIGZpbGw6I2Y5Njtcblx0XHRcdFx0XHQiLCJtZXJtYWlkIjp7InRoZW1lIjoiZGVmYXVsdCJ9LCJ1cGRhdGVFZGl0b3IiOmZhbHNlfQ)](https://mermaid-js.github.io/mermaid-live-editor/#/edit/eyJjb2RlIjoiZ3JhcGggTFIgICAgIFxuICAgIEFbQyBDb2RlXTo6OnNvbWVjbGFzcyAtLT4gQihDbGFuZylcbiAgICBzdWJncmFwaCBMTFZNIGJ1aWxkICAgIFxuICAgIEIgLS0-IENbQml0Y29kZS5iY10gICAgXG4gICAgZW5kXG4gICAgc3ViZ3JhcGggTWFwMkNoZWNrIFBBU1MgQ29kZSBUcmFuc2Zvcm1hdGlvblxuICAgIEMgLS0-IEMxKENoZWNrIENvZGUgUHJvZmlsZSlcbiAgICBDMSAtLT4gQzIoR2VuZXJhdGUgTWljcm8tY29kZSlcbiAgICBDMSAtLT4gQzMoQ29kZSBJbnN0cnVtZW50YXRpb24pXG4gICAgZW5kXG4gICAgc3ViZ3JhcGggRXhlY3V0aW9uIEFuYWx5c2lzXG4gICAgRChsaWJtYXAyY2hlY2suYSkgLS0-IEMyXG4gICAgRCAtLT4gQzMgICAgICAgIFxuICAgIEMyIC0tPkZbTmV3IEJpdGNvZGUuYmNdXG4gICAgQzMgLS0-RltOZXcgQml0Y29kZS5iY11cbiAgICBGLS0-RjEoRnV6emVyIFJ1bilcbiAgICBGMS0tPkZcbiAgICBGLS0-RjIoS0xFRSBSdW4pICBcbiAgICBGMi0tPkYgIFxuICAgIGVuZFxuICAgIHN1YmdyYXBoIFJlc3VsdCBBbmFseXNpc1xuICAgIEYtLT5HKENoZWNrIFByb3BlcnR5IExvZylcbiAgICBHLS0-RzF7Q2hlY2sgUmVzdWx0fVxuICAgIEcxLS0-RzJbVFJVRV06Ojpzb21lY2xhc3NcbiAgICBHMS0tPkczW0ZBTFNFXTo6OnNvbWVjbGFzc1xuICAgIEcxLS0-RzRbVU5LTk9XTl06Ojpzb21lY2xhc3NcbiAgICBlbmQgIFxuXG4gICAgY2xhc3NEZWYgc29tZWNsYXNzIGZpbGw6I2Y5Njtcblx0XHRcdFx0XHQiLCJtZXJtYWlkIjp7InRoZW1lIjoiZGVmYXVsdCJ9LCJ1cGRhdGVFZGl0b3IiOmZhbHNlfQ)

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

```C++

// Object
In : NonDetLog nondet_obj;
Out: 1 => {} 

/** Data structure, where n is the number of the step, and {} is NonDetLog * object from that step **/
In : list<map<unsigned, NonDetLog>> nondet_obj_list;
Out: N => [1 : {}, ... n : {}] 

```


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

- AllocationLog Object:

This object contains all methods that are used for the AllocationLog which is a structure that contains all memory operations.   

```json
{
    "AllocationLog" : {        
        "address"                   : long,
        "size_to_destiny"           : int,  
        "is_free"                   : bool,
        "valid_allocation_log()"    : bool,
        ""

    }
}
```


How is the modeled the return from container?
In the a assert function or the end of program analyzed a JSON string is returned with all data collected in the execution analysis.













