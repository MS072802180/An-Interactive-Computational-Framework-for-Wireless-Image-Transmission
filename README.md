OVERVIEW
--------
SIM_GUI_Scrollable is a MATLAB graphical user interface for exploring and
evaluating Structured Illumination Microscopy (SIM) image processing pipelines.
It allows users to load grayscale (or auto-converted RGB) microscopy images,
apply a selection of SIM-related transforms with adjustable parameters, and
inspect the results through four synchronized display panels alongside quality
metrics (PSNR, SSIM, processing time).
 
 
REQUIREMENTS
------------
  - MATLAB R2016b or later (uipanel 'Scrollable' property requires R2018b+)
  - Image Processing Toolbox (required for: psnr, ssim, medfilt2, imgaussfilt,
    imbilatfilt, imguidedfilter, imadjust, stretchlim, im2double, imshow)
 
  Optional but recommended:
  - A display resolution of at least 1400 x 800 pixels for the default layout.
 
 
GETTING STARTED
---------------
1. Place SIM_GUI_Scrollable_revised.m anywhere on your MATLAB path.
2. In the MATLAB Command Window, type:
 
       SIM_GUI_Scrollable
 
3. The GUI window will open. Click "Load Image" to select a supported image
   file and begin processing.
 
 
SUPPORTED IMAGE FORMATS
-----------------------
  TIFF (.tif, .tiff), PNG (.png), JPEG (.jpg, .jpeg), BMP (.bmp)
 
  RGB images are automatically converted to grayscale on load.
  All images are internally normalised to the [0, 1] floating-point range.
 
 
INTERFACE LAYOUT
----------------
Left panel (scrollable):
  +- File -------------------------------------------------------+
  |  Load Image   |   Save Result                                 |
  |  Filename display                    |  Image size            |
  +--------------------------------------------------------------+
  +- Transform Type ---------------------------------------------+
  |  Drop-down selector for the active transform                  |
  +--------------------------------------------------------------+
  +- Parameters ------------------------------------------------+
  |  Orientation   [slider  0 - 360 deg]                          |
  |  Phase         [slider  0 - 360 deg]                          |
  |  Frequency     [slider  0.1 - 0.9]                            |
  |  Modulation    [slider  0.1 - 0.9]                            |
  |  Noise Level   [slider  -2.0 - +2.0]                          |
  |  [ Reset All Parameters ]                                     |
  +--------------------------------------------------------------+
  +- Actions ---------------------------------------------------+
  |  Pattern Gallery  |  Batch Process                            |
  |  Noise Analysis   |  Compare Results                          |
  +--------------------------------------------------------------+
  +- Status & Metrics ------------------------------------------+
  |  Status message                                               |
  |  PSNR (dB)        |   SSIM                                    |
  |  Processing time (ms)                                         |
  +--------------------------------------------------------------+
 
Right panel (four axes):
  +------------------+------------------+
  |  Original Image  |  Processed Result |
  +------------------+------------------+
  |  Fourier Spectrum|  Difference Map   |
  +------------------+------------------+
 
 
TRANSFORM MODES
---------------
Pattern
  Multiplies the input image by a sinusoidal illumination pattern.
  The pattern orientation, phase, frequency, and modulation depth are all
  controlled by the parameter sliders.
 
Fourier Transform
  Displays the log-magnitude of the 2-D FFT of the input image.
  Useful for inspecting spatial frequency content. Parameter sliders have
  no effect in this mode.
 
Widefield
  Simulates conventional widefield imaging by convolving the input with a
  Gaussian PSF whose width is derived from the Frequency slider.
  Positive Noise Level adds Gaussian noise; negative values apply
  progressive denoising (median -> Gaussian -> bilateral filter).
 
SIM Reconstruction
  Simulates a standard 3-orientation / 3-phase SIM acquisition and
  reconstruction by averaging nine widefield-convolved pattern images.
  Result approximates the incoherent sum across all illumination angles.
 
Enhanced SIM
  Extends SIM Reconstruction with Wiener deconvolution applied to the
  averaged stack. The noise regularisation parameter is derived from the
  Noise Level slider. Contrast is auto-stretched with imadjust.
 
 
PARAMETER REFERENCE
-------------------
  Orientation (deg)  Pattern grating angle relative to horizontal. 0-360.
  Phase (deg)        Lateral shift of the illumination grating. 0-360.
  Frequency          Spatial frequency of the illumination pattern in
                     normalised units (cycles/pixel). Range: 0.1-0.9.
                     Lower values produce a coarser pattern and wider PSF.
  Modulation         Contrast depth of the sinusoidal pattern (0 = no
                     pattern, 1 = full contrast). Range: 0.1-0.9.
  Noise Level        > 0 : adds zero-mean Gaussian noise scaled by this
                           value (used as standard deviation).
                     = 0 : no noise modification.
                     < 0 : applies denoising whose strength scales with
                           the absolute value.
 
 
ACTION BUTTONS
--------------
Pattern Gallery
  Opens a separate figure showing a 3x3 grid of pattern images across
  three orientations (0, 60, 120 deg) and three phases (0, 120, 240 deg)
  using the current Frequency and Modulation settings.
 
Batch Process
  Runs Widefield processing across nine fixed noise levels
  (-2, -1, -0.5, -0.2, 0, +0.2, +0.5, +1, +2) and displays PSNR/SSIM
  for each in a grid figure.
 
Noise Analysis
  Displays noise residual maps (result minus original) at five noise
  levels, plus a histogram of the noise distribution at level +2.
 
Compare Results
  Renders all five transforms side-by-side in a single figure alongside
  the current difference map. Requires that at least one transform has
  been applied first.
 
 
SAVING RESULTS
--------------
Click "Save Result" to export the currently displayed processed image.
Supported output formats: PNG, TIFF, JPEG, MAT.
 
For MAT export the full appdata workspace struct is saved, which includes
the original image, processed image, and all parameter values.
 
Default filename is auto-generated as:  <source_name>_<transform>.png
 
 
QUALITY METRICS
---------------
PSNR (Peak Signal-to-Noise Ratio)
  Computed via MATLAB's built-in psnr(). Higher values indicate the
  processed image is closer to the original. Displayed in decibels (dB).
 
SSIM (Structural Similarity Index)
  Computed via MATLAB's built-in ssim(). Range 0-1; values closer to 1
  indicate greater structural similarity to the original image.
 
Both metrics compare the processed result against the loaded original and
update automatically whenever a transform is applied. If the Image
Processing Toolbox is unavailable, both display as '--'.
 
 
KNOWN LIMITATIONS
-----------------
  - The scrollable left panel requires MATLAB R2018b or later. On earlier
    releases, remove the 'Scrollable','on' property from the
    panel_controls_wrapper uipanel call.
  - SIM Reconstruction and Enhanced SIM are computationally intensive on
    large images (>1024x1024) because they run nine convolutions per call.
    Consider downsampling test images during parameter exploration.
  - The Wiener deconvolution in Enhanced SIM uses a simplified scalar NSR
    estimate and is intended for demonstration, not quantitative analysis.
  - imbilatfilt and imguidedfilter require the Image Processing Toolbox.
 
 
FILE STRUCTURE
--------------
  SIM_GUI_Scrollable_revised.m   Main entry point and full application.
                                 Single-file; no external dependencies
                                 beyond MATLAB and the Image Processing
                                 Toolbox.
