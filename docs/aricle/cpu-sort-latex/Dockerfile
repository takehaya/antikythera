FROM debian@sha256:7ff6ba31527b9e336162fa061746c366c4b2032f4d2cff2078bea43f78efe3f8
LABEL task="cpu-report-latex-v7"
COPY install-tex.sh /tmp/install-tex.sh
RUN sh /tmp/install-tex.sh
WORKDIR /work
ENV HOME=/tmp
CMD ["python3", "build.py"]
