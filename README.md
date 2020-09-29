# Map2Check-Library
C++ library to support Map2Check Tool.

[![License](https://img.shields.io/badge/license-GPL--3-lighgreen)](../master/LICENSE)
[![Build Status](https://travis-ci.org/hbgit/map2check-library.svg?branch=master)](https://travis-ci.org/hbgit/map2check-library)
[![codecov](https://codecov.io/gh/hbgit/map2check-library/branch/master/graph/badge.svg)](https://codecov.io/gh/hbgit/map2check-library)



<!-- Using https://mermaidjs.github.io/mermaid-live-editor -->

## Map2Check flow with the library

[![](https://mermaid.ink/img/eyJjb2RlIjoiZ3JhcGggTFIgICAgIFxuICAgIEFbQyBDb2RlXTo6OnNvbWVjbGFzcyAtLT4gQihDbGFuZylcbiAgICBzdWJncmFwaCBMTFZNIGJ1aWxkICAgIFxuICAgIEIgLS0-IENbQml0Y29kZS5iY10gICAgXG4gICAgZW5kXG4gICAgc3ViZ3JhcGggTWFwMkNoZWNrIFBBU1MgQ29kZSBUcmFuc2Zvcm1hdGlvblxuICAgIEMgLS0-IEMxKENoZWNrIENvZGUgUHJvZmlsZSlcbiAgICBDMSAtLT4gQzIoR2VuZXJhdGUgTWljcm8tY29kZSlcbiAgICBDMSAtLT4gQzMoQ29kZSBJbnN0cnVtZW50YXRpb24pXG4gICAgZW5kXG4gICAgc3ViZ3JhcGggRXhlY3V0aW9uIEFuYWx5c2lzXG4gICAgRChsaWJtYXAyY2hlY2suYSkgLS0-IEMyXG4gICAgRCAtLT4gQzMgICAgICAgIFxuICAgIEMyIC0tPkZbTmV3IEJpdGNvZGUuYmNdXG4gICAgQzMgLS0-RltOZXcgQml0Y29kZS5iY11cbiAgICBGLS0-RjEoRnV6emVyIFJ1bilcbiAgICBGMS0tPkZcbiAgICBGLS0-RjIoS0xFRSBSdW4pICBcbiAgICBGMi0tPkYgIFxuICAgIGVuZFxuICAgIHN1YmdyYXBoIFJlc3VsdCBBbmFseXNpc1xuICAgIEYtLT5HKENoZWNrIFByb3BlcnR5IExvZylcbiAgICBHLS0-RzF7Q2hlY2sgUmVzdWx0fVxuICAgIEcxLS0-RzJbVFJVRV06Ojpzb21lY2xhc3NcbiAgICBHMS0tPkczW0ZBTFNFXTo6OnNvbWVjbGFzc1xuICAgIEcxLS0-RzRbVU5LTk9XTl06Ojpzb21lY2xhc3NcbiAgICBlbmQgIFxuXG4gICAgY2xhc3NEZWYgc29tZWNsYXNzIGZpbGw6I2Y5Njtcblx0XHRcdFx0XHQiLCJtZXJtYWlkIjp7InRoZW1lIjoiZGVmYXVsdCJ9LCJ1cGRhdGVFZGl0b3IiOmZhbHNlfQ)](https://mermaid-js.github.io/mermaid-live-editor/#/edit/eyJjb2RlIjoiZ3JhcGggTFIgICAgIFxuICAgIEFbQyBDb2RlXTo6OnNvbWVjbGFzcyAtLT4gQihDbGFuZylcbiAgICBzdWJncmFwaCBMTFZNIGJ1aWxkICAgIFxuICAgIEIgLS0-IENbQml0Y29kZS5iY10gICAgXG4gICAgZW5kXG4gICAgc3ViZ3JhcGggTWFwMkNoZWNrIFBBU1MgQ29kZSBUcmFuc2Zvcm1hdGlvblxuICAgIEMgLS0-IEMxKENoZWNrIENvZGUgUHJvZmlsZSlcbiAgICBDMSAtLT4gQzIoR2VuZXJhdGUgTWljcm8tY29kZSlcbiAgICBDMSAtLT4gQzMoQ29kZSBJbnN0cnVtZW50YXRpb24pXG4gICAgZW5kXG4gICAgc3ViZ3JhcGggRXhlY3V0aW9uIEFuYWx5c2lzXG4gICAgRChsaWJtYXAyY2hlY2suYSkgLS0-IEMyXG4gICAgRCAtLT4gQzMgICAgICAgIFxuICAgIEMyIC0tPkZbTmV3IEJpdGNvZGUuYmNdXG4gICAgQzMgLS0-RltOZXcgQml0Y29kZS5iY11cbiAgICBGLS0-RjEoRnV6emVyIFJ1bilcbiAgICBGMS0tPkZcbiAgICBGLS0-RjIoS0xFRSBSdW4pICBcbiAgICBGMi0tPkYgIFxuICAgIGVuZFxuICAgIHN1YmdyYXBoIFJlc3VsdCBBbmFseXNpc1xuICAgIEYtLT5HKENoZWNrIFByb3BlcnR5IExvZylcbiAgICBHLS0-RzF7Q2hlY2sgUmVzdWx0fVxuICAgIEcxLS0-RzJbVFJVRV06Ojpzb21lY2xhc3NcbiAgICBHMS0tPkczW0ZBTFNFXTo6OnNvbWVjbGFzc1xuICAgIEcxLS0-RzRbVU5LTk9XTl06Ojpzb21lY2xhc3NcbiAgICBlbmQgIFxuXG4gICAgY2xhc3NEZWYgc29tZWNsYXNzIGZpbGw6I2Y5Njtcblx0XHRcdFx0XHQiLCJtZXJtYWlkIjp7InRoZW1lIjoiZGVmYXVsdCJ9LCJ1cGRhdGVFZGl0b3IiOmZhbHNlfQ)


## To build the map2check-library

You can use the [build.sh](build.sh) script:

```Console
$ ./build.sh --debug
```

## **New Model and Library Flow**

In this new data model, we aims to create a model object for each data structure that need a data storage, e.g., NonDetLog that has all data about nondet call functions. In this sense, we have a Container object that handle with the storage for each data structure using STL.

<center>
<img src="./docs/imgs/class-diagram.png">
</center>


## Files Type

### Caller

- The files are simple C++ file (not modelling as class), its goal is to be adopted as wrapper to call the library features using extern "C". This way, the focus is keep simple to be integrated with LLVM-link or adopted as an API in C source code.

### Analysis Mode

- The files that modelling and performing the verification condition to be adopted by Map2Check tool, such as: overflow, memory safety, and reachability error.

### Container

- The files the modelling the data storage, different from the old library, we do not adopt temporary files, and all data gathered are shown in the end of the program analysis.

### NonDetGen

- The files that modelling and performing the generation of nondeterministic values, called by __VERIFIER_nondet_* function in Map2Check tool. The tools supported by the library are KLEE and LibFuzzer.


## How is the output from container execution?

After the verification condition from map2check-library to be validate using KLEE or LibFuzzer a JSON (specification RFC 8259) string is shown with all data collected in the execution analysis, as following:

```json
{
  "Output": {
    "Result"     : "string",
    "LineNumber" : "unsigned",
    "Property"   : ["TRUE", "FALSE", "UNKWNON"],
    "Container_NonDetLog": [
      {
        "step"         : "01",
        "line"         : "unsigned",
        "scope"        : "unsigned",
        "value"        : "typename T",
        "function_name": "const char *"
      }
    ],
    "Container_AllocationLog": [
      {
        "step"           : "01",
        "address"        : "long",
        "size_to_destiny": "int"
      }
    ]
  }
}
```













