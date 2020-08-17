FROM herberthb/llvm-docker-dev:v8
LABEL maintainer=<herberthb12@gmail.com>

RUN apt update
RUN apt install -y build-essential cmake 
RUN apt install -y git
RUN apt install -y libboost-all-dev

WORKDIR /