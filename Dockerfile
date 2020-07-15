FROM samhorvath/itk-base:latest
MAINTAINER Sam Horvath <sam.horvath@kitware.com>

COPY . /elastix
RUN mkdir /elastix-rel

WORKDIR /elastix-rel
RUN cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DITK_DIR=/ITK-build \
  /elastix

RUN make

RUN pip install ctk-cli

WORKDIR /elastix/DockerPythonCLI

ENTRYPOINT ["python", "./cli_list.py"]