function wallis_filter()
    %*******************************************************************************************************
    %# read image
    %I = imread('room.jpg');
    O=imread('mountain_small.tif');
    W=imread('mountain_small.tif');
    E=imread('mountain_small.tif');
    
    %[O,map1]=imread('room.jpg');
    %O = rgb2gray( [O,map1]);
    %[W,map2]=imread('room.jpg');
    %W = rgb2gray( [W,map2]);

    
    %*******************************************************************************************************
    %# setup GUI
    hFig = figure('menu','none');
    set(hFig, 'NumberTitle', 'off', ...
        'Name', 'Wallis Filter', ...
        'Position', [300 300 1600 1200]);

    % slider: contrast
    sld_c = uicontrol('Parent',hFig, 'Style','slider', 'Value',0, 'Min',0,...
                    'Max',1, 'SliderStep',[0.01 1], ...
                    'Position',[750 5 300 20], 'Callback',@slider_event); 
    txt_c = uicontrol('Style','text', 'Position',[890 28 30 15], 'String','0');
    uicontrol('Style','text', 'Position',[820 28 70 15], 'String','Contrast:');
    
    % slider: brightness
    sld_b = uicontrol('Parent',hFig, 'Style','slider', 'Value',0, 'Min',0,...
                'Max',1, 'SliderStep',[0.01 1], ...
                'Position',[1075 5 300 20], 'Callback',@slider_event); 
    txt_b = uicontrol('Style','text', 'Position',[1215 28 30 15], 'String','0');
    uicontrol('Style','text', 'Position',[1140 28 75 15], 'String','Brightness:');
    
    % Textbox: Mean
    uicontrol('Style','text', 'Position',[550 28 100 15], 'String','Global Mean:');
    tb_mean = uicontrol('Style','edit', 'Position',[650 28 40 15], 'String','127', 'Callback',@tb_event);
    
    % Textbox: STD
    uicontrol('Style','text', 'Position',[550 5 100 15], 'String','Global STD:');
    tb_std = uicontrol('Style','edit', 'Position',[650 5 40 15], 'String','60', 'Callback',@tb_event);
    
    % Textbox: WIN_SIZE
    uicontrol('Style','text', 'Position',[375 5 100 15], 'String','WIN_SIZE:');
    tb_win = uicontrol('Style','edit', 'Position',[475 5 40 15], 'String','21', 'Callback',@tb_event);
    
    hFig.Visible = 'on';
    
    
    %*******************************************************************************************************
    %# show image and histograms
    subplot(2,2,1)
    imshow(O)
    title('Original')

    subplot(2,2,2)
    imhist(O);
    title('Histogram: Original')

    subplot(2,2,3)
    imshow(W)
    title('Wallis Filter')

    subplot(2,2,4)
    imhist(W);
    title('Histogram: Wallis Filter')
    
    
    [n_mean, n_std] = cal_mean_std(O);
    
      
    %*******************************************************************************************************
    %# Slider Event
    function slider_event(source, eventdata)
         value_sld = get(source,'Value');
         value_sld = round(value_sld, 2, 'significant'); 
         
         if sld_c == source
            set(txt_c, 'String',num2str(value_sld))     %# update text
         elseif sld_b == source
             set(txt_b, 'String',num2str(value_sld))    %# update text
         end
         
         cal_wallis(n_mean, n_std);
    end

    %# Textbox Event
    function tb_event(source, eventdata)  
         if tb_mean == source
             cal_wallis(n_mean, n_std);
         elseif tb_std == source
             cal_wallis(n_mean, n_std);
         elseif tb_win == source
             [n_mean, n_std] = cal_mean_std(O);
             cal_wallis(n_mean, n_std);
         end
    end

    %# Wallis Filter calculation
    function cal_wallis(n_mean, n_std)
        g_mean = str2num(get(tb_mean,'String'));
        g_std = str2num(get(tb_std,'String'));
        b = str2num(get(txt_b,'String'));
        c = str2num(get(txt_c,'String'));
        
        [rows cols]=size(O);
        
        for x = 1:rows
            for y = 1:cols
                dbg = (((double(O(x,y)) - n_mean(x,y)) * c*g_std^2) / (c*n_std(x,y)^2+(1-c)*g_std^2));
                pix = dbg + (b*g_mean + ((1-b)*n_mean(x,y)));
                
                if pix >= 255
                    W(x,y) = 255;
                elseif pix <= 0
                    W(x,y) = 0;
                else
                    W(x,y) = pix;
                end
            end
        end
        
        % Accuracy
        for x = 1:rows
            for y = 1:cols
                dbg = floor(((double(O(x,y)) - n_mean(x,y)) * c*g_std^2)) / floor(c*n_std(x,y)^2+(1-c)*g_std^2);
                pix = dbg + (b*g_mean + ((1-b)*n_mean(x,y)));
                
                if pix >= 255
                    E(x,y) = 255;
                elseif pix <= 0
                    E(x,y) = 0;
                else
                    E(x,y) = round(pix);
                end
            end
        end
        
        err = immse(W, E)
        
        % Refresh Plots
        subplot(2,2,3);
        imshow(W);
        title('Wallis Filter');

        subplot(2,2,4);
        imhist(W);
        title('Histogram: Wallis Filter'); 
    end

    %# Calculate: Mean & Standard Deviation
    function [mean, std] = cal_mean_std(img)
        WIN_SIZE = str2num(get(tb_win,'String'));
        
        mean = nlfilter(img,[WIN_SIZE WIN_SIZE],'mean2');
        std = nlfilter(img,[WIN_SIZE WIN_SIZE],'std2');       
    end
      
end
