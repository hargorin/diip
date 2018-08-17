# Distributed FPGA for enhanced Image Processing

![](https://i.imgur.com/bDxWlX4.png "")

Bachelor Thesis at FHNW by Noah Hütter and Jan Stocker

## Build Status [![pipeline status](https://gitlab.fhnw.ch/noah.huetter/diip/badges/doc/pipeline.svg)](https://gitlab.fhnw.ch/noah.huetter/diip/commits/doc_noah)

| Part          | Download     |
| ------------- |:-------------|
| Project Report| [PDF](https://gitlab.fhnw.ch/noah.huetter/diip/-/jobs/artifacts/master/raw/doc/report/p6_diip_huetter_stocker.pdf?job=doc) |
| diip java cc  | [.jar](https://gitlab.fhnw.ch/noah.huetter/diip/-/jobs/artifacts/master/raw/sw/diip_java_cc/target/diip_java_cc-0.0.1-SNAPSHOT-jar-with-dependencies.jar?job=java) |

## Folder Structure
```
.
├── doc             # Documentation
│   ├── report      # Project report
│   └── poster      # Poster for exhibition
├── fpga            # FPGA code
│   ├── hls         # Vivado High Level Synthesis code
│   └── hlx         # Vivado HLx code
└── sw              # Computer software
```


## Documentation

### Build instructions

```bash
sudo apt install -y -qq texlive-full build-essential
sudo apt install -y -qq biber
cd doc/report
make
```

## CI Build
Setup a docker vivado image according to [https://github.com/noah95/vivado-docker](https://github.com/noah95/vivado-docker)
Create the runner using
```
sudo gitlab-runner register --docker-pull-policy never
```
to prevent gitlab-runner to pull from docker hub and use the local image instead.
