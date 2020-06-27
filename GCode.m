function [printend]=GCode(var1, var2, var3, var4, var5, var6, var7, var8, var9, var10, var11, var12, var13, var14, var15, var16, var17)
%-----------------------------------------------------------
% script to calculate GCode Points for first welding pass 
% User input comes from user interface
% 1) feed rate
% 2) overlap
% 3) tape width
% 4) tape thickness (z coordinate)
% 5) layers
% 6) substrate length (x direction) 
% 7) substrate width (y direction)
% 8) part height
% 9) work offsets for x, y, z coordinate 
%NOTE: THIS CODE ASSUMES THAT THE POINT OF REFERENCE IS THE LEFT CORNER OF
%THE TAPE. Refer to the ReadMe.doc for further explanation. 


%----------------------------------------------------------
%open .txt file 
%----------------------------------------------------------
fileID = fopen('GCode.txt', 'w');
formatspec1 = '%s\r\n';
formatspec3 = ';%s\r\n'; 
c=date;
c=sprintf(formatspec3, c); 
fprintf(fileID, formatspec1, ';G-Code File');       %program name 
fprintf(fileID,'%s', c);                            %program generation date
c = newline;
fprintf(fileID, formatspec1, ';this file was created using MATLAB and user input');

%-------------------------------------------------------
%intialize variables passed 
%-------------------------------------------------------
y_int=0; 
feed_rate = var1;             %feed rate in in/min
tapewidth = var2;             %tape width is 1in.
ylength = var4;               %length of part in y direction
overlap = var5;               %ovelap between tape passes
xlength = var3;               %length of part in x direction
tapeThick = var6;             %tape thickness, z height before compression
partHeight = var7;            %part height, used to generate layer iterations 
compfac = var8;               %compression factor from spring force 
layerset = var9;              %number of layers
offx = num2str(var10);                 %x offset
offy = num2str(var11);                 %y offset
offz = num2str(var12);                 %z offset
lower_rate = num2str(var13);           %lower tool rate 
safe_trav= num2str(var14);             %safe travel tool rate 
off_spring = var15;                    %spring offset value
safe_height = num2str(var16);          %safe height value
x_stag = num2str(var17);            %stagger point

%-------------------------------------------------------
%Calculations
%-------------------------------------------------------
machinePrint = true;          %conditional for generating new z point
layercount = 0;               %layer counter to track sets 
layertotal = 0;               %track layers
ypt = y_int;                                        %set ypt to initial 
tapewidth_new = tapewidth-overlap;                  %new "effective" tape width 
tapeThick_new = tapeThick*compfac;                  %new tapeThickness from compression factor
z_start =tapeThick_new-off_spring;                  %starting z height
z_pt = z_start;                                     %assign zpt to equa z_start
stopgen = ylength/(tapewidth_new);                  %generate stopping point for indexing
subrec = ceil(stopgen);                             %display recommended substrate length (for overlhang issues) 
stopgen = stopgen+1;                                %add one because matlab indexes from 1 and not 0 

%-----------------------------------------------------------------
%print substrate length and width recommendations
%-----------------------------------------------------------------
subrec = strcat(';Recommended substrate width is: ', num2str(subrec), 'in.');
fprintf(fileID, formatspec1, subrec);           %print
subrec = xlength+1;                             %substrate x length with a factor of 1in added for safety
subrec = strcat(';Recommended substrate length is: ', num2str(subrec), 'in.'); 
fprintf(fileID, formatspec1, subrec);           %print

%-----------------------------------------------------------------
%print part height warning
%-----------------------------------------------------------------
if rem(partHeight,tapeThick_new) ~=0
    partHeight = partHeight+1; 
    layers = ceil(partHeight/tapeThick_new);     %get how many layers in the part height
    warn = ';!WARNING! Part Height and Tape Thickness do not divide evenly';
    fprintf(fileID, formatspec1, warn); 
    warn1 = strcat(';Part will be printed:', num2str(partHeight), 'inches high.');
    fprintf(fileID, formatspec1, warn1); 
else 
    layers = partHeight/tapeThick_new;    %don't round up if part height and tapethickness divide evenly 
end

fprintf(fileID, formatspec1, [';--------------------------------------------------',c]);

%-------------------------------------------------------
%printing tool offset
%-------------------------------------------------------
offx = strcat(' X', offx); 
offy = strcat(' Y', offy); 
offz = strcat(' Z', offz); 
A = ['G01', offx, offy, ' G54', offz, ' G43', ' H10'];     %tool offset line
fprintf(fileID, formatspec1, A);                           %print  

%-----------------------------------------------------------------
%print first few lines of movement, MCode Relays, and initializes more things
%-----------------------------------------------------------------
formatspec2 = '%s %s %s';
Frate = strcat(' F', num2str(feed_rate), '.');    %feedrate string
F_lower = strcat(' F', num2str(lower_rate), '.'); %lower feedrate string
F_safe = strcat(' F', safe_trav, '.');            %safe travel feed rate
X_zero= 'X0. ';                                %x home coordinate
Z_safe = strcat('Z', safe_height, '.');        %safe height coordinate
z_start = strcat('Z', num2str(z_start), '.');     %z starting point
y_pt=strcat(' Y', num2str(ypt), '.');          %y pt string
A=[X_zero, y_pt, Frate];                       %x and y zero point
fprintf(fileID, formatspec1, A);               %print
x_pt=strcat('X', num2str(xlength), '.');       %variable for part length
fprintf(fileID, formatspec1, 'M22 ;turning on stepper motor'); 
A =[z_start, F_lower, c];                           %lower tool head
fprintf(fileID, formatspec2, A);                 %print
fprintf(fileID, formatspec1, 'M21 ;turning on sonotrode');
A=[x_pt, y_pt, Frate, c];                       %move down x length
fprintf(fileID, formatspec2, A);                %print
fprintf(fileID, formatspec1, 'M23 ;turning on brake');
fprintf(fileID, formatspec1, 'M24 ;turning on pneumatic cutter');
%-----initialize counters-----------------
i=1;                                           %odd even counter
j=1;                                          %od even counter for stagger
%----being point generation algorithm-----
while machinePrint == true 
for index = 1:stopgen
   if rem(i,2)~=0
        A = [Z_safe, F_safe];     
        fprintf(fileID, formatspec1, A);
        ypt = ypt + (tapewidth-overlap); 
        if rem(j,2)~=0
            y_pt = strcat('Y', num2str(ypt));
            A =[X_zero, y_pt, Frate];
            fprintf(fileID, formatspec1, A);
            j=j+1;
        else 
            y_pt = strcat('Y', num2str(ypt), '.'); 
            x_pt = strcat('X', x_stag, '.');
            A = [x_pt, y_pt, Frate];
            fprintf(fileID, formatspec1, A); 
            j=j+1;
        end 
        i=i+1; 
   else
        y_pt = strcat(' Y', num2str(ypt), '.'); 
        x_pt=strcat('X', num2str(xlength), '.');
        zpt=strcat('Z', num2str(z_pt), '.');
        fprintf(fileID, formatspec1, 'M22 ;turning on stepper motor'); 
        A = [zpt, F_lower];
        fprintf(fileID, formatspec1, A);
        fprintf(fileID, formatspec1, 'M21 ;turning on sonotrode');
        A =[x_pt, y_pt, Frate];
        fprintf(fileID, formatspec1, A); 
        fprintf(fileID, formatspec1, 'M23 ;turning on brake');
        fprintf(fileID, formatspec1, 'M24 ;turning on pneumatic cutter');
        i=i+1;
    end 
end  
layer_complete = ';layer complete, raising tool part';
ypt=y_int;                                         %reset y
A = [layer_complete, c]; 
fprintf(fileID, formatspec1, A); 

if layercount == layerset
    stop = ';Machine is pausing for user to eliminate flaps';
    A = [stop, c];
    fprintf(fileID, formatspec2, A);
    prompt = ';Press cycle start to continue program once excess flaps are removed';
    A = [prompt, c];
    fprintf(fileID, formatspec2, A); 
    fprintf(fileID, formatspec1, 'M00');           %stop program 
    layercount =0; 
end 

if  layertotal == layers
    machinePrint = false;
    stop = ';End Code Generation'; 
    A = [stop, c]; 
    fprintf(fileID, formatspec1, A); 
elseif z_pt >= partHeight
    machinePrint = false;
    stop = ';End Code Generation'; 
    A = [stop, c]; 
    fprintf(fileID, formatspec1, A); 
end      
%update variables 
z_pt = z_pt+tapeThick_new;                         %update height
layercount = layercount+1;                         %update how many layers
layertotal = layertotal+1;                          
end 
printend = 1; 
fclose(fileID);
%-----end algorithm----- 
end