function SIM_GUI_Scrollable


    close all; clc;

    fig = figure('Name', 'SIM Reconstruction Framework', ...
                 'NumberTitle', 'off', ...
                 'Position', [100, 100, 1400, 800], ...
                 'Color', [0.96 0.96 0.96], ...
                 'Resize', 'on', ...
                 'Units', 'normalized', ...
                 'SizeChangedFcn', @figResized);

    appdata = struct();
    appdata.fig = fig;
    appdata.original_image = [];
    appdata.processed_image = [];
    appdata.current_transform = 'Pattern';
    appdata.transform_params = initializeParameters();
    appdata.axes_handles = struct();
    appdata.controls = struct();

    % -------- Left scrollable wrapper --------
    wrapper_norm_pos = [0.01 0.01 0.25 0.98];
    panel_controls_wrapper = uipanel('Parent', fig, ...
                                     'Title', '', ...
                                     'Units', 'normalized', ...
                                     'Position', wrapper_norm_pos, ...
                                     'BackgroundColor', [0.9 0.92 0.96], ...
                                     'BorderType', 'none', ...
                                     'Scrollable', 'on');

    inner_width_px  = 340;
    inner_height_px = 1200;
    panel_controls = uipanel('Parent', panel_controls_wrapper, ...
                             'Title', 'SIM Controls', ...
                             'Units', 'pixels', ...
                             'Position', [0 0 inner_width_px inner_height_px], ...
                             'BackgroundColor', [0.92 0.94 0.98], ...
                             'BorderType', 'line');

    appdata.panel_controls_wrapper = panel_controls_wrapper;
    appdata.panel_controls = panel_controls;

    % -------- Right display panel --------
    panel_display = uipanel('Parent', fig, ...
                            'Title', '', ...
                            'Units', 'normalized', ...
                            'Position', [0.27 0.01 0.72 0.98], ...
                            'BackgroundColor', [1 1 1]);

    % -------- Stack sections top-down --------
    current_y = 0.98;
    spacing   = 0.02;

    section_height = 0.08;
    current_y = current_y - section_height;
    appdata = createFileSection(panel_controls, appdata, [0.05, current_y, 0.90, section_height], fig);

    section_height = 0.06;
    current_y = current_y - section_height - spacing;
    appdata = createTransformSection(panel_controls, appdata, [0.05, current_y, 0.90, section_height], fig);

    section_height = 0.30;
    current_y = current_y - section_height - spacing;
    appdata = createPatternControlsSection(panel_controls, appdata, [0.05, current_y, 0.90, section_height], fig);

    section_height = 0.10;
    current_y = current_y - section_height - spacing;
    
    createActionButtonsSection(panel_controls, [0.05, current_y, 0.90, section_height], fig);

    section_height = 0.12;
    current_y = current_y - section_height - spacing; 
    
    appdata = createStatusSection(panel_controls, appdata, [0.05, current_y, 0.90, section_height]);

    appdata = createDisplaySection(panel_display, appdata);

    set(fig, 'UserData', appdata);
    updateStatus(appdata, 'Ready - Load image to begin');
    adjustInnerPanelWidth(appdata);
end

% -------------------------------------------------------------------------
%  Figure resize handler
% -------------------------------------------------------------------------
function figResized(src, ~)
    appdata = get(src, 'UserData');
    if isempty(appdata), return; end
    adjustInnerPanelWidth(appdata);
end

function adjustInnerPanelWidth(appdata)
    try
        wrapper = appdata.panel_controls_wrapper;
        inner   = appdata.panel_controls;
        oldUnits = get(wrapper, 'Units');
        set(wrapper, 'Units', 'pixels');
        wrapperPos = get(wrapper, 'Position');
        set(wrapper, 'Units', oldUnits);

        margin   = 12;
        newWidth = max(300, wrapperPos(3) - margin);
        innerPos = get(inner, 'Position');
        innerPos(3) = newWidth;
        set(inner, 'Position', innerPos);
    catch
        
    end
end

% -------------------------------------------------------------------------
%  UI section creators
% -------------------------------------------------------------------------
function appdata = createFileSection(parent, appdata, position, fig)
    panel_file = uipanel('Parent', parent, 'Title', 'File', ...
                         'Units', 'normalized', 'Position', position, ...
                         'BackgroundColor', [0.95 0.96 0.98], 'FontSize', 10);

    btn_w = 0.45; btn_h = 0.48;
    uicontrol('Parent', panel_file, 'Style', 'pushbutton', 'String', 'Load Image', ...
             'Units', 'normalized', 'Position', [0.03 0.50 btn_w btn_h], ...
             'FontSize', 10, 'BackgroundColor', [0.2 0.6 1], ...
             'ForegroundColor', 'white', 'Callback', {@loadImageCallback, fig});

    uicontrol('Parent', panel_file, 'Style', 'pushbutton', 'String', 'Save Result', ...
             'Units', 'normalized', 'Position', [0.52 0.50 btn_w btn_h], ...
             'FontSize', 10, 'BackgroundColor', [0.1 0.8 0.1], ...
             'ForegroundColor', 'white', 'Callback', {@saveResultsCallback, fig});

    appdata.controls.filename_display = uicontrol('Parent', panel_file, 'Style', 'text', ...
        'String', 'No image loaded', 'Units', 'normalized', ...
        'Position', [0.03 0.10 0.65 0.30], 'BackgroundColor', [0.98 0.98 0.98], ...
        'ForegroundColor', [0.2 0.2 0.2], 'FontSize', 9, 'HorizontalAlignment', 'left');

    appdata.controls.image_info = uicontrol('Parent', panel_file, 'Style', 'text', ...
        'String', 'Size: N/A', 'Units', 'normalized', ...
        'Position', [0.70 0.10 0.27 0.30], 'BackgroundColor', [0.95 0.97 1.0], ...
        'ForegroundColor', [0.2 0.2 0.2], 'FontSize', 9, 'HorizontalAlignment', 'center');
end

function appdata = createTransformSection(parent, appdata, position, fig)
    panel_transform = uipanel('Parent', parent, 'Title', '', ...
                              'Units', 'normalized', 'Position', position, ...
                              'BackgroundColor', [0.95 0.96 0.98], 'BorderType', 'none');

    uicontrol('Parent', panel_transform, 'Style', 'text', 'String', 'Transform Type:', ...
             'Units', 'normalized', 'Position', [0.02 0.20 0.40 0.65], 'FontSize', 10, ...
             'BackgroundColor', [0.95 0.96 0.98], 'ForegroundColor', [0.1 0.1 0.3], ...
             'HorizontalAlignment', 'left');

    transform_list = {'Pattern', 'Fourier Transform', 'SIM Reconstruction', 'Widefield', 'Enhanced SIM'};
    appdata.controls.transform_selector = uicontrol('Parent', panel_transform, 'Style', 'popupmenu', ...
                                                   'String', transform_list, 'Units', 'normalized', ...
                                                   'Position', [0.45 0.12 0.52 0.75], 'FontSize', 9, ...
                                                   'BackgroundColor', 'white', 'ForegroundColor', [0.1 0.1 0.1], ...
                                                   'Value', 1, 'Callback', {@selectTransformCallback, fig});
end

function appdata = createPatternControlsSection(parent, appdata, position, fig)
    panel_pattern = uipanel('Parent', parent, 'Title', 'Parameters', ...
                            'Units', 'normalized', 'Position', position, ...
                            'BackgroundColor', [0.95 0.96 0.98], 'FontSize', 10);

    row_h  = 0.12;
    slider_h = 0.06;
    row_sp = 0.02;
    start_y = 0.85;
    col1 = 0.03; col1w = 0.40;
    col2 = 0.46; col2w = 0.51;

    % --- Orientation ---
    y = start_y;
    uicontrol('Parent', panel_pattern, 'Style', 'text', 'String', 'Orientation:', ...
             'Units', 'normalized', 'Position', [col1 y col1w row_h], 'FontSize', 9, ...
             'BackgroundColor', [0.95 0.96 0.98], 'HorizontalAlignment', 'left');
    appdata.controls.orientation_display = uicontrol('Parent', panel_pattern, 'Style', 'text', ...
                 'String', '0°', 'Units', 'normalized', 'Position', [col1+0.32 y+0.02 0.10 row_h-0.04], ...
                 'BackgroundColor', [0.95 0.96 0.98], 'FontSize', 9, 'FontWeight', 'bold');
    appdata.controls.orientation_slider = uicontrol('Parent', panel_pattern, 'Style', 'slider', ...
                 'Units', 'normalized', 'Position', [col2 y+0.03 col2w slider_h], ...
                 'Min', 0, 'Max', 360, 'Value', 0, 'SliderStep', [1/360 10/360], ...
                 'Callback', {@updateOrientationCallback, fig});

    % --- Phase ---
    y = y - row_h - row_sp;
    uicontrol('Parent', panel_pattern, 'Style', 'text', 'String', 'Phase:', ...
             'Units', 'normalized', 'Position', [col1 y col1w row_h], 'FontSize', 9, ...
             'BackgroundColor', [0.95 0.96 0.98], 'HorizontalAlignment', 'left');
    appdata.controls.phase_display = uicontrol('Parent', panel_pattern, 'Style', 'text', ...
                 'String', '0°', 'Units', 'normalized', 'Position', [col1+0.32 y+0.02 0.10 row_h-0.04], ...
                 'BackgroundColor', [0.95 0.96 0.98], 'FontSize', 9, 'FontWeight', 'bold');
    appdata.controls.phase_slider = uicontrol('Parent', panel_pattern, 'Style', 'slider', ...
                 'Units', 'normalized', 'Position', [col2 y+0.03 col2w slider_h], ...
                 'Min', 0, 'Max', 360, 'Value', 0, 'SliderStep', [1/360 10/360], ...
                 'Callback', {@updatePhaseCallback, fig});

    % --- Frequency ---
    y = y - row_h - row_sp;
    uicontrol('Parent', panel_pattern, 'Style', 'text', 'String', 'Frequency:', ...
             'Units', 'normalized', 'Position', [col1 y col1w row_h], 'FontSize', 9, ...
             'BackgroundColor', [0.95 0.96 0.98], 'HorizontalAlignment', 'left');
    appdata.controls.freq_display = uicontrol('Parent', panel_pattern, 'Style', 'text', ...
                 'String', '0.40', 'Units', 'normalized', 'Position', [col1+0.32 y+0.02 0.10 row_h-0.04], ...
                 'BackgroundColor', [0.95 0.96 0.98], 'FontSize', 9, 'FontWeight', 'bold');
    appdata.controls.freq_slider = uicontrol('Parent', panel_pattern, 'Style', 'slider', ...
                 'Units', 'normalized', 'Position', [col2 y+0.03 col2w slider_h], ...
                 'Min', 0.1, 'Max', 0.9, 'Value', 0.4, 'SliderStep', [0.01 0.1], ...
                 'Callback', {@updateFrequencyCallback, fig});

    % --- Modulation ---
    y = y - row_h - row_sp;
    uicontrol('Parent', panel_pattern, 'Style', 'text', 'String', 'Modulation:', ...
             'Units', 'normalized', 'Position', [col1 y col1w row_h], 'FontSize', 9, ...
             'BackgroundColor', [0.95 0.96 0.98], 'HorizontalAlignment', 'left');
    appdata.controls.mod_display = uicontrol('Parent', panel_pattern, 'Style', 'text', ...
                 'String', '0.50', 'Units', 'normalized', 'Position', [col1+0.32 y+0.02 0.10 row_h-0.04], ...
                 'BackgroundColor', [0.95 0.96 0.98], 'FontSize', 9, 'FontWeight', 'bold');
    appdata.controls.mod_slider = uicontrol('Parent', panel_pattern, 'Style', 'slider', ...
                 'Units', 'normalized', 'Position', [col2 y+0.03 col2w slider_h], ...
                 'Min', 0.1, 'Max', 0.9, 'Value', 0.5, 'SliderStep', [0.01 0.1], ...
                 'Callback', {@updateModulationCallback, fig});

    % --- Noise Level ---
    y = y - row_h - row_sp;
    uicontrol('Parent', panel_pattern, 'Style', 'text', 'String', 'Noise Level:', ...
             'Units', 'normalized', 'Position', [col1 y col1w row_h], 'FontSize', 9, ...
             'BackgroundColor', [0.95 0.96 0.98], 'HorizontalAlignment', 'left');
    appdata.controls.noise_display = uicontrol('Parent', panel_pattern, 'Style', 'text', ...
                 'String', '0.05', 'Units', 'normalized', 'Position', [col1+0.32 y+0.02 0.10 row_h-0.04], ...
                 'BackgroundColor', [0.95 0.96 0.98], 'FontSize', 9, 'FontWeight', 'bold');
    appdata.controls.noise_slider = uicontrol('Parent', panel_pattern, 'Style', 'slider', ...
                 'Units', 'normalized', 'Position', [col2 y+0.03 col2w slider_h], ...
                 'Min', -2, 'Max', 2, 'Value', 0.05, 'SliderStep', [0.005 0.05], ...
                 'Callback', {@updateNoiseCallback, fig});

    % --- Reset ---
    y = y - row_h - row_sp;
    uicontrol('Parent', panel_pattern, 'Style', 'pushbutton', 'String', 'Reset All Parameters', ...
             'Units', 'normalized', 'Position', [0.03 y 0.94 0.12], 'FontSize', 9, ...
             'BackgroundColor', [0.8 0.8 1.0], 'Callback', {@resetParametersCallback, fig});
end


function createActionButtonsSection(parent, position, fig)
    panel_actions = uipanel('Parent', parent, 'Title', 'Actions', ...
                            'Units', 'normalized', 'Position', position, ...
                            'BackgroundColor', [0.95 0.96 0.98], 'FontSize', 10);

    bw = 0.22; bh = 0.68; sp = 0.02; x0 = 0.03;

    uicontrol('Parent', panel_actions, 'Style', 'pushbutton', 'String', {'Pattern';'Gallery'}, ...
             'Units', 'normalized', 'Position', [x0 0.18 bw bh], 'FontSize', 9, ...
             'BackgroundColor', [0.4 0.7 1.0], 'ForegroundColor', 'white', ...
             'Callback', {@showAllPatternsCallback, fig});

    uicontrol('Parent', panel_actions, 'Style', 'pushbutton', 'String', {'Batch';'Process'}, ...
             'Units', 'normalized', 'Position', [x0+bw+sp 0.18 bw bh], 'FontSize', 9, ...
             'BackgroundColor', [0.2 0.8 0.4], 'ForegroundColor', 'white', ...
             'Callback', {@batchProcessCallback, fig});

    uicontrol('Parent', panel_actions, 'Style', 'pushbutton', 'String', {'Noise';'Analysis'}, ...
             'Units', 'normalized', 'Position', [x0+2*(bw+sp) 0.18 bw bh], 'FontSize', 9, ...
             'BackgroundColor', [1.0 0.6 0.2], 'ForegroundColor', 'white', ...
             'Callback', {@noiseAnalysisCallback, fig});

    uicontrol('Parent', panel_actions, 'Style', 'pushbutton', 'String', {'Compare';'Results'}, ...
             'Units', 'normalized', 'Position', [x0+3*(bw+sp) 0.18 bw bh], 'FontSize', 9, ...
             'BackgroundColor', [0.8 0.4 1.0], 'ForegroundColor', 'white', ...
             'Callback', {@compareResultsCallback, fig});
end


function appdata = createStatusSection(parent, appdata, position)
    panel_status = uipanel('Parent', parent, 'Title', 'Status & Metrics', ...
                          'Units', 'normalized', 'Position', position, ...
                          'BackgroundColor', [0.95 0.96 0.98]);

    uicontrol('Parent', panel_status, 'Style', 'text', 'String', 'Status:', ...
             'Units', 'normalized', 'Position', [0.03 0.72 0.18 0.20], 'FontSize', 9, ...
             'BackgroundColor', [0.95 0.96 0.98], 'HorizontalAlignment', 'left');
    appdata.controls.status_display = uicontrol('Parent', panel_status, 'Style', 'text', ...
        'String', 'Ready', 'Units', 'normalized', 'Position', [0.22 0.72 0.75 0.20], ...
        'BackgroundColor', [0.98 0.98 1.0], 'FontSize', 9, 'HorizontalAlignment', 'left');

    uicontrol('Parent', panel_status, 'Style', 'text', 'String', 'PSNR:', ...
             'Units', 'normalized', 'Position', [0.03 0.40 0.12 0.18], 'FontSize', 9, ...
             'BackgroundColor', [0.95 0.96 0.98], 'HorizontalAlignment', 'left');
    appdata.controls.psnr_display = uicontrol('Parent', panel_status, 'Style', 'text', ...
        'String', '-- dB', 'Units', 'normalized', 'Position', [0.16 0.40 0.36 0.18], ...
        'BackgroundColor', [0.95 0.98 0.95], 'FontSize', 9, 'HorizontalAlignment', 'left');

    uicontrol('Parent', panel_status, 'Style', 'text', 'String', 'SSIM:', ...
             'Units', 'normalized', 'Position', [0.55 0.40 0.12 0.18], 'FontSize', 9, ...
             'BackgroundColor', [0.95 0.96 0.98], 'HorizontalAlignment', 'left');
    appdata.controls.ssim_display = uicontrol('Parent', panel_status, 'Style', 'text', ...
        'String', '--', 'Units', 'normalized', 'Position', [0.68 0.40 0.29 0.18], ...
        'BackgroundColor', [0.95 0.98 0.95], 'FontSize', 9, 'HorizontalAlignment', 'left');

    uicontrol('Parent', panel_status, 'Style', 'text', 'String', 'Time:', ...
             'Units', 'normalized', 'Position', [0.03 0.08 0.12 0.18], 'FontSize', 9, ...
             'BackgroundColor', [0.95 0.96 0.98], 'HorizontalAlignment', 'left');
    appdata.controls.time_display = uicontrol('Parent', panel_status, 'Style', 'text', ...
        'String', '-- ms', 'Units', 'normalized', 'Position', [0.16 0.08 0.36 0.18], ...
        'BackgroundColor', [0.95 0.98 0.98], 'FontSize', 9, 'HorizontalAlignment', 'left');
end

% -------------------------------------------------------------------------
%  Display axes
% -------------------------------------------------------------------------
function appdata = createDisplaySection(parent, appdata)
    appdata.axes_handles.original = axes('Parent', parent, 'Units', 'normalized', ...
                                        'Position', [0.04 0.55 0.44 0.40], 'Box', 'on');
    axis(appdata.axes_handles.original, 'image', 'off');

    appdata.axes_handles.processed = axes('Parent', parent, 'Units', 'normalized', ...
                                         'Position', [0.52 0.55 0.44 0.40], 'Box', 'on');
    axis(appdata.axes_handles.processed, 'image', 'off');

    appdata.axes_handles.fourier = axes('Parent', parent, 'Units', 'normalized', ...
                                       'Position', [0.04 0.08 0.44 0.40], 'Box', 'on');
    axis(appdata.axes_handles.fourier, 'image', 'off');

    appdata.axes_handles.difference = axes('Parent', parent, 'Units', 'normalized', ...
                                          'Position', [0.52 0.08 0.44 0.40], 'Box', 'on');
    axis(appdata.axes_handles.difference, 'image', 'off');

    placeholder = zeros(256, 256);
    imshow(placeholder, 'Parent', appdata.axes_handles.original);
    imshow(placeholder, 'Parent', appdata.axes_handles.processed);
    imshow(placeholder, 'Parent', appdata.axes_handles.fourier);
    imshow(placeholder, 'Parent', appdata.axes_handles.difference);

    appdata.controls.label_original = uicontrol('Parent', parent, 'Style', 'text', ...
        'String', 'Original Image', 'Units', 'normalized', 'Position', [0.04 0.51 0.44 0.035], ...
        'BackgroundColor', get(parent,'BackgroundColor'), 'HorizontalAlignment', 'left', 'FontSize', 10);

    appdata.controls.label_processed = uicontrol('Parent', parent, 'Style', 'text', ...
        'String', 'Processed Result', 'Units', 'normalized', 'Position', [0.52 0.51 0.44 0.035], ...
        'BackgroundColor', get(parent,'BackgroundColor'), 'HorizontalAlignment', 'left', 'FontSize', 10);

    appdata.controls.label_fourier = uicontrol('Parent', parent, 'Style', 'text', ...
        'String', 'Fourier Spectrum', 'Units', 'normalized', 'Position', [0.04 0.045 0.44 0.035], ...
        'BackgroundColor', get(parent,'BackgroundColor'), 'HorizontalAlignment', 'left', 'FontSize', 10);

    appdata.controls.label_difference = uicontrol('Parent', parent, 'Style', 'text', ...
        'String', 'Difference Map', 'Units', 'normalized', 'Position', [0.52 0.045 0.44 0.035], ...
        'BackgroundColor', get(parent,'BackgroundColor'), 'HorizontalAlignment', 'left', 'FontSize', 10);
end

% -------------------------------------------------------------------------
%  Callbacks
% -------------------------------------------------------------------------
function loadImageCallback(~, ~, fig)
    appdata = get(fig, 'UserData');
    updateStatus(appdata, 'Loading image...');
    [filename, pathname] = uigetfile( ...
        {'*.tif;*.tiff;*.png;*.jpg;*.jpeg;*.bmp','Image Files'}, 'Select an image');
    if isequal(filename, 0)
        updateStatus(appdata, 'Load cancelled');
        return;
    end
    try
        img = imread(fullfile(pathname, filename));
        if size(img, 3) == 3, img = rgb2gray(img); end
        appdata.original_image  = im2double(img);
        appdata.processed_image = [];   

        imshow(appdata.original_image, 'Parent', appdata.axes_handles.original);
        set(appdata.controls.label_original, 'String', sprintf('Original: %s   (%d×%d)', ...
            filename, size(appdata.original_image,2), size(appdata.original_image,1)));
        set(appdata.controls.filename_display, 'String', sprintf('Loaded: %s', filename));
        set(appdata.controls.image_info, 'String', ...
            sprintf('%d×%d', size(appdata.original_image,2), size(appdata.original_image,1)));
       
        set(appdata.controls.psnr_display, 'String', '-- dB');
        set(appdata.controls.ssim_display, 'String', '--');
        set(appdata.controls.time_display, 'String', '-- ms');

        set(fig, 'UserData', appdata);
        applyCurrentTransform(fig);     
        updateStatus(appdata, sprintf('Loaded: %s', filename));
    catch ME
        errordlg(sprintf('Error loading image: %s', ME.message), 'Load Error');
        updateStatus(appdata, 'Load failed');
    end
end

function selectTransformCallback(src, ~, fig)
    appdata = get(fig, 'UserData');
    list = get(src, 'String');
    appdata.current_transform = list{get(src, 'Value')};
    set(fig, 'UserData', appdata);
    if ~isempty(appdata.original_image)
        updateStatus(appdata, sprintf('Applying %s...', appdata.current_transform));
        applyCurrentTransform(fig);     
    end
end

function updateOrientationCallback(src, ~, fig)
    appdata = get(fig, 'UserData');
    val = round(get(src, 'Value'));
    appdata.transform_params.orientation_deg = val;
    set(appdata.controls.orientation_display, 'String', sprintf('%d°', val));
    set(fig, 'UserData', appdata);
    if ~isempty(appdata.original_image), applyCurrentTransform(fig); end
end

function updatePhaseCallback(src, ~, fig)
    appdata = get(fig, 'UserData');
    val = round(get(src, 'Value'));
    appdata.transform_params.phase_deg = val;
    set(appdata.controls.phase_display, 'String', sprintf('%d°', val));
    set(fig, 'UserData', appdata);
    if ~isempty(appdata.original_image), applyCurrentTransform(fig); end
end

function updateFrequencyCallback(src, ~, fig)
    appdata = get(fig, 'UserData');
    appdata.transform_params.frequency = get(src, 'Value');
    set(appdata.controls.freq_display, 'String', sprintf('%.2f', appdata.transform_params.frequency));
    set(fig, 'UserData', appdata);
    if ~isempty(appdata.original_image), applyCurrentTransform(fig); end
end

function updateModulationCallback(src, ~, fig)
    appdata = get(fig, 'UserData');
    appdata.transform_params.modulation = get(src, 'Value');
    set(appdata.controls.mod_display, 'String', sprintf('%.2f', appdata.transform_params.modulation));
    set(fig, 'UserData', appdata);
    if ~isempty(appdata.original_image), applyCurrentTransform(fig); end
end

function updateNoiseCallback(src, ~, fig)
    appdata = get(fig, 'UserData');
    val = get(src, 'Value');
    appdata.transform_params.noise_level = val;
    set(appdata.controls.noise_display, 'String', sprintf('%+.2f', val));
    set(fig, 'UserData', appdata);
    if ~isempty(appdata.original_image), applyCurrentTransform(fig); end
end

function resetParametersCallback(~, ~, fig)
    appdata = get(fig, 'UserData');
    updateStatus(appdata, 'Resetting parameters...');
    appdata.transform_params = initializeParameters();

    set(appdata.controls.orientation_slider,  'Value', 0);
    set(appdata.controls.orientation_display, 'String', '0°');
    set(appdata.controls.phase_slider,        'Value', 0);
    set(appdata.controls.phase_display,       'String', '0°');
    set(appdata.controls.freq_slider,         'Value', 0.4);
    set(appdata.controls.freq_display,        'String', '0.40');
    set(appdata.controls.mod_slider,          'Value', 0.5);
    set(appdata.controls.mod_display,         'String', '0.50');
    set(appdata.controls.noise_slider,        'Value', 0.05);
    set(appdata.controls.noise_display,       'String', '0.05');

    set(fig, 'UserData', appdata);
    if ~isempty(appdata.original_image), applyCurrentTransform(fig); end  
    updateStatus(appdata, 'Parameters reset');
end

function saveResultsCallback(~, ~, fig)
    appdata = get(fig, 'UserData');
    if isempty(appdata.processed_image)
        errordlg('No processed image to save.', 'Save Error'); return;
    end
    default_name = 'sim_result.png';
    fname_str = get(appdata.controls.filename_display, 'String');
    if ~isempty(fname_str)
        [~, name] = fileparts(strrep(fname_str, 'Loaded: ', ''));
        default_name = sprintf('%s_%s.png', name, appdata.current_transform);
    end
    [filename, pathname] = uiputfile({'*.png';'*.tif';'*.jpg';'*.mat'}, ...
        'Save Processed Image', default_name);
    if isequal(filename, 0), return; end

    fullpath = fullfile(pathname, filename);
    [~, ~, ext] = fileparts(filename);
    if strcmpi(ext, '.mat')
        save(fullpath, 'appdata');
    else
        try
            imwrite(im2uint8(mat2gray(appdata.processed_image)), fullpath);
        catch
            imwrite(appdata.processed_image, fullpath);
        end
    end
    updateStatus(appdata, sprintf('Saved: %s', filename));
end

function showAllPatternsCallback(~, ~, fig)
    appdata = get(fig, 'UserData');
    if isempty(appdata.original_image)
        errordlg('Please load an image first.', 'No Image'); return;
    end
    figure('Name','SIM Pattern Gallery','NumberTitle','off','Position',[200 200 1200 800]);
    patterns = [0,0; 0,120; 0,240; 60,0; 60,120; 60,240; 120,0; 120,120; 120,240];
    for i = 1:size(patterns,1)
        subplot(3,3,i);
        p = generatePatternImage(appdata.original_image, patterns(i,1), ...
                                 appdata.transform_params, patterns(i,2));
        imshow(p);
        title(sprintf('Ori=%d°  Phase=%d°', patterns(i,1), patterns(i,2)));
    end
end

function batchProcessCallback(~, ~, fig)
    appdata = get(fig, 'UserData');
    if isempty(appdata.original_image)
        errordlg('Please load an image first.', 'No Image'); return;
    end
    updateStatus(appdata, 'Running batch processing...');
    figure('Name','Batch Processing - Noise Level Analysis','NumberTitle','off','Position',[150 150 1200 700]);
    noise_levels = [-2 -1 -0.5 -0.2 0 0.2 0.5 1 2];
    for i = 1:length(noise_levels)
        subplot(3,3,i);
        temp = appdata.transform_params;
        temp.noise_level = noise_levels(i);
        result = applyWidefield(appdata.original_image, temp);
        imshow(result);
        if noise_levels(i) < 0
            title(sprintf('Noise: %.1f (Reduction)', noise_levels(i)));
        elseif noise_levels(i) > 0
            title(sprintf('Noise: +%.1f (Addition)', noise_levels(i)));
        else
            title('Noise: 0.0');
        end
        [psnrv, ssimv] = calculateQualityMetrics(appdata.original_image, result);
        xlabel(sprintf('PSNR: %.1f dB\nSSIM: %.3f', psnrv, ssimv), 'FontSize', 8);
    end
    updateStatus(appdata, 'Batch processing completed');
end

function noiseAnalysisCallback(~, ~, fig)
    appdata = get(fig, 'UserData');
    if isempty(appdata.original_image)
        errordlg('Please load an image first.', 'No Image'); return;
    end
    updateStatus(appdata, 'Analyzing noise...');
    figure('Name','Noise Analysis','NumberTitle','off','Position',[200 200 1000 600]);
    noise_levels = [-1 -0.5 0 0.5 1];
    for i = 1:length(noise_levels)
        subplot(2,3,i);
        temp = appdata.transform_params;
        temp.noise_level = noise_levels(i);
        result = applyWidefield(appdata.original_image, temp);
        if noise_levels(i) == 0
            noise_img = zeros(size(result));
        else
            noise_img = result - appdata.original_image;
        end
        imagesc(noise_img); colormap('gray'); colorbar;
        ns = std(noise_img(:));
        if noise_levels(i) < 0
            title(sprintf('Noise: %.1f\nσ=%.4f', noise_levels(i), ns));
        elseif noise_levels(i) > 0
            title(sprintf('Noise: +%.1f\nσ=%.4f', noise_levels(i), ns));
        else
            title(sprintf('Original\nσ=%.4f', ns));
        end
        axis image;
    end
    
    subplot(2,3,6);
    temp = appdata.transform_params;
    temp.noise_level = 2;
    noisy_image = applyWidefield(appdata.original_image, temp);
    noise = noisy_image - appdata.original_image;
    histogram(noise(:), 50);   
    xlabel('Noise Amplitude'); ylabel('Frequency');
    title('Noise Distribution'); grid on;
    updateStatus(appdata, 'Noise analysis completed');
end

function compareResultsCallback(~, ~, fig)
    appdata = get(fig, 'UserData');
    if isempty(appdata.original_image)
        errordlg('Please load an image first.', 'No Image'); return;
    end
    
    if isempty(appdata.processed_image)
        errordlg('Please apply a transform first before comparing.', 'No Result'); return;
    end
    updateStatus(appdata, 'Comparing transforms...');
    figure('Name','Transform Comparison','NumberTitle','off','Position',[150 150 1200 600]);
    transforms = {'Original','Pattern','Widefield','SIM Reconstruction','Enhanced SIM','Difference'};
    for i = 1:length(transforms)
        subplot(2,3,i);
        switch transforms{i}
            case 'Original'
                result = appdata.original_image;
            case 'Pattern'
                result = generatePatternImage(appdata.original_image, ...
                    appdata.transform_params.orientation_deg, appdata.transform_params, ...
                    appdata.transform_params.phase_deg);
            case 'Widefield'
                result = applyWidefield(appdata.original_image, appdata.transform_params);
            case 'SIM Reconstruction'
                result = applySIMReconstruction(appdata.original_image, appdata.transform_params);
            case 'Enhanced SIM'
                result = applyEnhancedSIM(appdata.original_image, appdata.transform_params);
            case 'Difference'
                result = abs(appdata.processed_image - appdata.original_image);
        end
        imshow(result);
        title(transforms{i});
        if i > 1 && ~strcmp(transforms{i}, 'Difference')
            [psnrv, ssimv] = calculateQualityMetrics(appdata.original_image, result);
            xlabel(sprintf('PSNR: %.1f dB\nSSIM: %.3f', psnrv, ssimv), 'FontSize', 8);
        end
    end
    updateStatus(appdata, 'Comparison completed');
end

% -------------------------------------------------------------------------
%  Core transform dispatcher
% -------------------------------------------------------------------------

function applyCurrentTransform(fig)
    appdata = get(fig, 'UserData');      
    try
        if isempty(appdata.original_image), return; end
        tic;
        result = applySelectedTransform(appdata.original_image, ...
                                        appdata.current_transform, ...
                                        appdata.transform_params);

        imshow(result, 'Parent', appdata.axes_handles.processed);

        F    = fftshift(fft2(result));
        Fmag = log(abs(F) + 1);
        imshow(Fmag, [], 'Parent', appdata.axes_handles.fourier);

        diffimg = abs(result - appdata.original_image);
        imshow(diffimg, [], 'Parent', appdata.axes_handles.difference);

        set(appdata.controls.label_processed, 'String', ...
            sprintf('Processed: %s', appdata.current_transform));
        set(appdata.controls.label_fourier, 'String', ...
            sprintf('Fourier Spectrum    Ori=%d°  Phase=%d°  Freq=%.2f', ...
            appdata.transform_params.orientation_deg, ...
            appdata.transform_params.phase_deg, ...
            appdata.transform_params.frequency));

        [psnrv, ssimv] = calculateQualityMetrics(appdata.original_image, result);
        set(appdata.controls.label_difference, 'String', ...
            sprintf('Difference Map    PSNR=%.1f dB  SSIM=%.3f', psnrv, ssimv));
        set(appdata.controls.psnr_display, 'String', sprintf('%.1f dB', psnrv));
        set(appdata.controls.ssim_display, 'String', sprintf('%.3f', ssimv));

        appdata.processed_image = result;
        set(fig, 'UserData', appdata);

        elapsed = toc * 1000;
        set(appdata.controls.time_display, 'String', sprintf('%.0f ms', elapsed));
        updateStatus(appdata, sprintf('%s applied', appdata.current_transform));

        drawnow('limitrate');   
    catch ME
        errordlg(sprintf('Error applying transform: %s', ME.message), 'Transform Error');
        updateStatus(appdata, 'Transform failed');
    end
end

function updateStatus(appdata, message)
    if isfield(appdata, 'controls') && isfield(appdata.controls, 'status_display')
        set(appdata.controls.status_display, 'String', message);
    end
    drawnow;
end

% -------------------------------------------------------------------------
%  Image processing helpers
% -------------------------------------------------------------------------
function params = initializeParameters()
    params = struct('frequency', 0.4, 'modulation', 0.5, 'noise_level', 0.05, ...
                   'orientation_deg', 0, 'phase_deg', 0);
end

function [psnr_val, ssim_val] = calculateQualityMetrics(original, processed)
    try
        psnr_val = psnr(processed, original);
        ssim_val = ssim(processed, original);
    catch
        psnr_val = NaN;
        ssim_val = NaN;
    end
end

function result = applySelectedTransform(img, transform_name, params)
    switch transform_name
        case 'Pattern'
            result = generatePatternImage(img, params.orientation_deg, params, params.phase_deg);
        case 'Fourier Transform'
            result = applyFourierTransform(img);
        case 'Widefield'
            result = applyWidefield(img, params);
        case 'SIM Reconstruction'
            result = applySIMReconstruction(img, params);
        case 'Enhanced SIM'
            result = applyEnhancedSIM(img, params);
        otherwise
            error('Unknown transform: %s', transform_name);
    end
end

function result = applyFourierTransform(img)
    F      = fftshift(fft2(img));
    result = mat2gray(log(abs(F) + 1));
end

function result = applyWidefield(img, params)
    psf    = generatePSF(params);
    result = conv2(img, psf, 'same');
    if params.noise_level > 0
        result = result + params.noise_level * randn(size(result));
    elseif params.noise_level < 0
        fs = abs(params.noise_level);
        if fs < 0.5
            result = medfilt2(result, [3 3]);
        elseif fs < 1.0
            result = imgaussfilt(result, 0.5);
            result = medfilt2(result, [3 3]);
        else
            
            result = imbilatfilt(result, fs * 0.1);   
        end
    end
    result = mat2gray(result);
end

function result = applySIMReconstruction(img, params)
    [nx, ny]     = size(img);
    orientations = [0, 60, 120] * pi/180;
    phases       = [0, 2*pi/3, 4*pi/3];
    nOri         = length(orientations);
    nPhs         = length(phases);

    
    accum = zeros(nx, ny);
    for ii = 1:nOri
        for jj = 1:nPhs
            pat   = generatePattern(nx, ny, orientations(ii), phases(jj), params);
            accum = accum + applyWidefield(img .* pat, params);
        end
    end
    result = mat2gray(accum / (nOri * nPhs));
end

function result = applyEnhancedSIM(img, params)
    [nx, ny]     = size(img);
    orientations = [0, 60, 120] * pi/180;
    phases       = [0, 2*pi/3, 4*pi/3];
    nOri         = length(orientations);
    nPhs         = length(phases);

    
    accum = zeros(nx, ny);
    for o = 1:nOri
        for p = 1:nPhs
            pat      = generatePattern(nx, ny, orientations(o), phases(p), params);
            observed = conv2(img .* pat, generatePSF(params), 'same');
            if params.noise_level > 0
                observed = observed + params.noise_level * randn(size(observed));
            else
                observed = applyNoiseReduction(observed, abs(params.noise_level));
            end
            accum = accum + observed;
        end
    end
    res    = accum / (nOri * nPhs);
    res    = wienerDeconvolution(res, generatePSF(params), max(0.001, abs(params.noise_level)));
    result = imadjust(mat2gray(res), stretchlim(res, 0.01), []);
end

function result = generatePatternImage(img, angle_deg, params, phase_deg)
    if nargin < 4, phase_deg = params.phase_deg; end
    [nx, ny]   = size(img);
    angle_rad  = angle_deg * pi/180;
    phase_rad  = phase_deg * pi/180;
    pat        = generatePattern(nx, ny, angle_rad, phase_rad, params);
    result     = mat2gray(img .* pat);
end

function pattern = generatePattern(nx, ny, orientation, phase, params)
    [X, Y] = meshgrid(1:ny, 1:nx);
    X = X - ny/2;  Y = Y - nx/2;
    k  = 2*pi * params.frequency;
    kx = k * cos(orientation);
    ky = k * sin(orientation);
    pattern = 1 + params.modulation * cos(kx*X + ky*Y + phase);
end

function psf = generatePSF(params)
    
    psf_size = max(3, min(21, round(10 / params.frequency)));
    if mod(psf_size, 2) == 0, psf_size = psf_size + 1; end
    [x, y] = meshgrid(-(psf_size-1)/2 : (psf_size-1)/2);
    sigma   = 1.5 / params.frequency;
    psf     = exp(-(x.^2 + y.^2) / (2*sigma^2));
    psf     = psf / sum(psf(:));
end

function deconv = wienerDeconvolution(img, psf, noise_var)
    img_f = fft2(img);
    psf_f = fft2(psf, size(img,1), size(img,2));
   
    NSR   = noise_var / (var(img(:)) + eps);   
    W     = conj(psf_f) ./ (abs(psf_f).^2 + NSR);
    deconv = real(ifft2(img_f .* W));
    deconv = mat2gray(deconv);
end

function out = applyNoiseReduction(img, fs)
    if fs < 0.3
        out = medfilt2(img, [3 3]);
    elseif fs < 0.7
        out = imgaussfilt(img, 0.5);
    elseif fs < 1.5
        
        out = imbilatfilt(img, fs * 0.05);   
    else
        out = imguidedfilter(img);
    end
end
