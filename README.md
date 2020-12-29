## UCSD CSE 168x, Computer Graphics II
### Ray Tracing and Path Tracing with NVIDIA OptiX
<img src="Scenes/images/dragon_1.png" width="240" align="right" vspace = "25">

#### 12/27/2020 ray-tracer-0.1
- Implemented simple ray tracer with NVIDIA OptiX
- See INSTALL-LINUX/WIN.txt for compile instructions
- Tested version:  
Windows 10: CUDA 10, OptiX 6.5;
Ubuntu 20.04: CUDA 10.2, OptiX 6.5
- Used native GeometryTriangles and self-defined Sphere for geometry primitives
- Blinn–Phong shading model, recursive trace for mirror reflection  

&nbsp; 
&nbsp; 
&nbsp;


<img src="Scenes/images/dragon_2.png" width="250" align="right" vspace = "50">

#### 12/29/2020 path-tracer-light
- Solve render equation for direct area lighting
- Modified Phong BRDF
- Monte Carlo integration with stratified sampling
