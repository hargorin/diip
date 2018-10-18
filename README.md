# Distributed FPGA for enhanced Image Processing

![](https://i.imgur.com/bDxWlX4.png "")

Bachelor Thesis at FHNW by Noah Hütter and Jan Stocker

## Build products

| Part          | Download     |
| ------------- |:-------------|
| Project Report| [PDF](https://github-production-release-asset-2e65be.s3.amazonaws.com/150583109/3eed1700-d2e1-11e8-827f-e9a0311d2bfb?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIWNJYAX4CSVEH53A%2F20181018%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20181018T122248Z&X-Amz-Expires=300&X-Amz-Signature=bf5ce5b13e4288e80cfa0de1ab44613d480c4d3d6360658b1415faeabf93d5ad&X-Amz-SignedHeaders=host&actor_id=3391933&response-content-disposition=attachment%3B%20filename%3Dp6_diip_huetter_stocker.pdf&response-content-type=application%2Foctet-stream) |
| diip java cc  | .jar |

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
