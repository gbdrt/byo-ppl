FROM ocaml/opam:ubuntu-20.04-ocaml-4.13

RUN sudo apt-get -y update && \
    sudo apt-get -y install \
      m4 wget unzip aspcud libshp-dev libplplot-dev gfortran pkg-config git \
      libopenblas-dev liblapacke-dev time python3.9 python3.9-dev python3-pip \
      libcairo2-dev libzmq3-dev libgmp3-dev

USER root

RUN deluser opam

ARG NB_USER=jovyan
ARG NB_UID=1000
ENV USER ${NB_USER}
ENV NB_UID ${NB_UID}
ENV HOME /home/${NB_USER}

RUN sudo adduser --disabled-password \
    --gecos "Default user" \
    --uid ${NB_UID} \
    ${NB_USER}

RUN chown -R ${NB_UID} ${HOME}

USER ${NB_USER}

WORKDIR ${HOME}

ENV PATH="$HOME/.local/bin:$PATH"
ENV SHELL=/bin/bash

RUN pip -q install pip --upgrade && \
    pip install --no-cache jupyterlab

RUN opam init -y --disable-sandboxing --comp 4.13.1 

RUN opam install -y dune owl zelus && \
    opam pin -y -k git https://github.com/akabe/ocaml-jupyter

RUN opam exec -- ocaml-jupyter-opam-genspec && \
    jupyter kernelspec install --user --name ocaml-jupyter "$(opam var share)/jupyter"

RUN echo ". ${HOME}/.opam/opam-init/init.sh > /dev/null 2> /dev/null || true" >> ${HOME}/.bashrc

COPY . ${HOME}
