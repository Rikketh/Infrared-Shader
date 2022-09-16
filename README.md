<div align="center">
<h3 align="center">Stencil-managed Mesh-driven Infrared Shader System</h3>

  <p align="center">
    A layer of infrared surface shaders intended to mimic the near-IR surface appearance when used with light amplification equipment
  </p>
</div>

## About

This project is a set of two shaders that are meant to work in tandem to achieve an effect of a near-infrared wavelength IFF equipment seen through light amplification equipment. While it does so, it only outputs a monochromatic HDR value to your screen. This means you still have to implement a clipspace/post-processing effect to mimic the NVG looks.


### Dependencies

* none lmao


### Prerequisites

 * Install VRCSDK3 for Avatars


### Installation

1. Download the `.shader` files
2. Import them into your project, anywhere




## Usage

Before you start using the shaders, you have to set your project up in a specific order.

The general concept behind this shader is the heavy reliance on stencil buffers as well as Z offsets to eradicate Z-fighting.

### Preparing your mesh

It isn't strictly necessary to have meshes that share vertex positions with their original BRDF variants, but it's the easiest way of going about it. If you already have IR patches or IR beacons, you might just duplicate glowing/reflective pieces.

Normally, you'd only want the faces that are front-facing, so in the case of IR patches being modelled as full cubes, you only need the faces on one side.

So, begin by duplicating all the IR-treated meshes, and move them to a separate (skinned?) object. Join all of them into one object, assign a new material to all of the faces in the set, and re-unwrap the meshes to minimise the waste of texels.

### Setting up the materials

Import your mesh into unity. Create two new materials:

1. The "reveal" material that's acts as a mask that reveals all IR meshes; make sure to set the intended stencil reference value
2. The "IR" material that goes onto the IR mesh you've unwrapped and created in the previous step.

The IR material is the harder one. Let's overview the settings for it:

1. `Tint` is a multiplicative RGBA of your output. While you have the ability to change the output colour with this parameter, it's main use is backwards compatibility with various unity components that alter `_Color` property of the referenced materials.
2. `IR Mask` also called IRD (Infra Red Definition map), refer to its set-up in the following section
3. `Glow factor` multiplies the value of IRD's luminance value by itself, allowing you to branch into HDR pixel values.
4. `Scan speed` controls how fast the TSU will offset the sampled point (Z & W are unused for the time being). Sampling begins at (0,0), being lower left corner of your texture, and depending on the sign value of your speed advanced up (positive X) and right (positive Y), or down (negative X) and left (negative Y). You can therefore set up speeds in such a way that allows you to have an elaborate pattern spanning two dimensions.
5. `Opacity factor` is a simple multiplicator of your alpha that can be easily referenced in animation clips (unlike fixed4).
6. `Stencil Reference Value` is the value that makes the magic possible. As long as it matches the Read shader's SRV, the mesh would be drawn when Read stencil mask covers the Write's pixels.
7. `Multiplicative Strobe Composition` switches the shader's colour calculation for strobe fragments to multiply the colour rather than add it, making it possible to reach the darker colours rather than overblow into HDR values.

### Creating the IRD map

IRD map contains four linear values for the shade to use. The channel mapping is as follows:  
* `Red` contains linear luminosity  
* `Green` contains linear X+Y strobe patterns controlled by advancing the sampler point over _Time.y (by default the whole texture gets sampled in 1 Hz)  
* `Blue` contains a linear strobe influence map
* `Alpha` contains opacity map

So, in order to create a correct texture, you either have to set up your input channels (Substance Painter/Blender) to use linear colour space, or set your colour profile (Photoshop/Gimp/Krita etc.) to negate sRGB correction.

Paint your red channel the same way you'd paint an emission map. In essence, it's a constant glow value that is either added to the flicker colour, or is multiplied by it.

Green channel contains what essentially is a 2D array of time-aligned pixels. Depending on how fast the scan speed is, the sampler will report various pixels depending on the time value. If you can think in two dimensions, you can paint the picture right away, otherwise the best practice is to have a double-lobe axis-aligned gradient in different spots. If it helps, you can imagine it being a play head on your player/animation timeline for X and Y axis.

Blue channel can be handled the same way you'd handle a metalness map: ideally it's a B&W map, but you can have shades of gray controlling how much of the strobe effect will be contributed to the pixel. It's used as the factor of the `lerp` function.

Alpha channel is your typical opacity channel. You can use it in your transparency composition (particles is a common use example).

You can take a look at an [example IRD map here](./examples/example_ird.png).




## Contact

Lars Sørensen - [@alareis_vrc](https://twitter.com/alareis_vrc) - [alareis](https://vrchat.com/home/user/usr_e3283b19-0468-479f-82de-0907c41920b0) - [VRChat-specific discord server](https://discord.gg/invite/hfdHnWVcbh)

Project Link: [https://github.com/Rikketh/Infrared-Shader](https://github.com/Rikketh/Infrared-Shader)
