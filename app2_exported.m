classdef app2_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                      matlab.ui.Figure
        GridLayout                    matlab.ui.container.GridLayout
        LeftPanel                     matlab.ui.container.Panel
        RunButton                     matlab.ui.control.Button
        FrquenceEditFieldLabel        matlab.ui.control.Label
        FrquenceEditField             matlab.ui.control.NumericEditField
        TypedesollicitationDropDownLabel  matlab.ui.control.Label
        TypedesollicitationDropDown   matlab.ui.control.DropDown
        AmplitudeaEditFieldLabel      matlab.ui.control.Label
        AmplitudeaEditField           matlab.ui.control.NumericEditField
        Button                        matlab.ui.control.Button
        SlectionnerlesfichiersLabel   matlab.ui.control.Label
        Label                         matlab.ui.control.Label
        RightPanel                    matlab.ui.container.Panel
        TabGroup                      matlab.ui.container.TabGroup
        VrificationfichiersTab        matlab.ui.container.Tab
        UITable2                      matlab.ui.control.Table
        ValiderlesdonnesButton        matlab.ui.control.Button
        GraphTab                      matlab.ui.container.Tab
        PressrunwhenyouarereadyLabel  matlab.ui.control.Label
        DataTab                       matlab.ui.container.Tab
        UITable                       matlab.ui.control.Table
        NomdefichierDropDownLabel     matlab.ui.control.Label
        NomdefichierDropDown          matlab.ui.control.DropDown
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end

      properties (Access = private)
        % Declare properties of the PatientsDisplay class.
        Data;
        Time;
        Epsilon;
        SigX;
        SigY;
        SigZ;
        nbFile;
        orderfile = {};
        Temperature;
        SigmaA;
        Delta;
        G;E;M;K;
        prim;sec;
        
      end
      
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, loadfilefunc)
            
        end

        % Button pushed function: RunButton
        function RunButtonPushed(app, event)
            Amplitude=app.AmplitudeaEditField.Value;        % on récupère la fréquence et l'amplitude insérées par l'utilisateur
            Frequancy=app.FrquenceEditField.Value;
            
            app.PressrunwhenyouarereadyLabel.Visible = 'off';        
             k = app.Epsilon(1,1);
                i=2;
                while app.Epsilon(i,1)~=k
                    i=i+1;
                end
                app.Label.Text = num2str(i);                                              
            for j=1:app.nbFile
                                                                      
                 [xData, yData] = prepareCurveData( app.Time(:,j)*10^-15, app.SigX(:,j)*10^9 );      %prépare le fit des données de sigmaX
             
                
                 T = 2*(app.Time(i,j)-app.Time(1,j))*10^-15; 
                 w=(2*pi)/T;
                ttt= ['a*sin(' num2str(w) '*x+b)+c'];
                %ttt= ['a+b*sin(' num2str(w) '*x+c)'];
                 f1 = fittype(ttt);
                 x = app.Time(:,j)*10^-15;
                 y = app.SigX(:,j)*10^9;
                  p = max(app.SigX(:,j))*10^9;
                 [ff1, ~] = fit(xData,yData,f1,'StartPoint',[p,(asin(app.SigX(1,1)/p)-w*500*10^-15),app.SigX(1,j)*10^9]);
                 %[ff1, ~] = fit(x,y,f1,'StartPoint',[app.SigX(1,j)*10^9,app.SigX(round(i/2),j)*10^9,abs((asin(app.SigX(1,1)/p)-w*500*10^-15))]);
                 c=coeffvalues(ff1);
                 app.SigmaA(j)=c(1);
                 app.Delta(j)=c(2);

                    
                                
            end
            
                switch app.TypedesollicitationDropDown.Value
               
                    case 'Constant Volume'
                        app.prim = (app.SigmaA./(2*Amplitude)).*cos(app.Delta);
                        app.sec = (app.SigmaA./(2*Amplitude)).*sin(app.Delta);
                        %s = stackedplot(app.GraphTab,app.Temperature,[app.Gprim app.Gsec app.Delta]);
                    case 'Uniaxial'
                        app.prim = (app.SigmaA./(Amplitude)).*cos(app.Delta);
                        app.sec = (app.SigmaA./(Amplitude)).*sin(app.Delta);
                        %s = stackedplot(app.GraphTab,app.Temperature,[app.Eprim.' app.Esec.' app.Delta.']);
                    case 'Longitudinal'
                        app.prim = (app.SigmaA./(Amplitude)).*cos(app.Delta);
                        app.sec = (app.SigmaA./(Amplitude)).*sin(app.Delta);
                        %s = stackedplot(app.GraphTab,app.Temperature,[app.Mprim.' app.Msec.' app.Delta.']);
                    case 'Isostatic'
                        app.prim = (app.SigmaA./(3*Amplitude)).*cos(app.Delta);
                        app.sec = (app.SigmaA./(3*Amplitude)).*sin(app.Delta);
                        %s = stackedplot(app.GraphTab,app.Temperature,[app.Kprim.' app.Ksec.' app.Delta.']);
                end
            
             stackedplot(app.GraphTab,app.Temperature,[app.prim.' app.sec.' app.Delta.' ]);
 
                 
 
             
 
             
            
            
        end

        % Button pushed function: Button
        function ButtonPushed(app, event)
            switch app.TypedesollicitationDropDown.Value
                case 'Constant Volume'
                    ext = '*.*00K-bis';
                case 'Uniaxial'
                    ext = '*.*00K-ter';
                case 'Longitudinal'
                    ext = '*.*00K';
                case 'Isostatic'
                    ext = '*.*00K-qua';
            end
                    
            
            
            %% Display uigetfile dialog
            [f, p] = uigetfile(ext,'Select file(s)',"MultiSelect","on");
            
            if isvector(f)
                app.nbFile = length(f);
            else 
                app.nbFile = 1;
            end
            
            for k=1:app.nbFile
                
                if (ischar(p)) && app.nbFile ~= 1
                    fname = [p char(f(k))];
                elseif (ischar(p)) && app.nbFile == 1
                    fname = [p f];
                end
            
                drawnow;
                figure(app.UIFigure)
            
                try
                    data=dlmread(fname,'%f %f %f %f %f',1,0);
                catch ME
                    % If problem reading image, display error message
                    uialert(app.UIFigure, ME.message, 'File Error');
                    return;
                end  
                                
                app.Time(:,k) = data(:,1);
                app.Epsilon(:,k) = data(:,2);
                app.SigX(:,k) = data(:,3);
                app.SigY(:,k) = data(:,4);
                app.SigZ(:,k) = data(:,5);
                
                
                app.orderfile = cat(2,app.orderfile,char(f(k)));
                newitems = cat(2,app.NomdefichierDropDown.Items,char(f(k)));
                app.NomdefichierDropDown.Items = (newitems);
              
                
            end
            app.Data = table(app.Time(:,1),app.Epsilon(:,1),app.SigX(:,1),app.SigY(:,1),app.SigZ(:,1));
            app.UITable.Data = app.Data;
            vars = {'Ndf','Temp'};
            for l=1:15
                app.Temperature(l,1)=100*l;
            end
            app.UITable2.Data = table(app.orderfile.',app.Temperature(:,1),'VariableNames',vars);
            % Make sure user didn't cancel uigetfile dialog
            
            
            
             %Store the data in a table and display it in one of the App's tabs.
            
                          

             app.SlectionnerlesfichiersLabel.Text = "folder :" + p;
        end

        % Value changed function: NomdefichierDropDown
        function NomdefichierDropDownValueChanged(app, event)
            value = app.NomdefichierDropDown.Value;
            for k=1:app.nbFile
                if strcmp(value,app.orderfile{k})
                    app.Data = table(app.Time(:,k),app.Epsilon(:,k),app.SigX(:,k),app.SigY(:,k),app.SigZ(:,k));
                    app.UITable.Data = app.Data;
                    return;
                end
            end
        end

        % Button pushed function: ValiderlesdonnesButton
        function ValiderlesdonnesButtonPushed(app, event)
            app.RunButton.Enable = 'on';
            app.ValiderlesdonnesButton.FontColor = [0 1 0];
            app.ValiderlesdonnesButton.Enable = 'off';
            set(app.TabGroup, 'SelectedTab',app.GraphTab);
           
            app.Temperature = app.UITable2.Data.Temp;
        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.UIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {567, 567};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {260, '1x'};
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 863 567];
            app.UIFigure.Name = 'UI Figure';
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {260, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create RunButton
            app.RunButton = uibutton(app.LeftPanel, 'push');
            app.RunButton.ButtonPushedFcn = createCallbackFcn(app, @RunButtonPushed, true);
            app.RunButton.Enable = 'off';
            app.RunButton.Position = [89 124 100 22];
            app.RunButton.Text = 'Run';

            % Create FrquenceEditFieldLabel
            app.FrquenceEditFieldLabel = uilabel(app.LeftPanel);
            app.FrquenceEditFieldLabel.HorizontalAlignment = 'right';
            app.FrquenceEditFieldLabel.Position = [34 328 93 22];
            app.FrquenceEditFieldLabel.Text = 'Fréquence : ÿ =';

            % Create FrquenceEditField
            app.FrquenceEditField = uieditfield(app.LeftPanel, 'numeric');
            app.FrquenceEditField.Position = [142 328 100 22];

            % Create TypedesollicitationDropDownLabel
            app.TypedesollicitationDropDownLabel = uilabel(app.LeftPanel);
            app.TypedesollicitationDropDownLabel.HorizontalAlignment = 'right';
            app.TypedesollicitationDropDownLabel.Position = [27 501 110 22];
            app.TypedesollicitationDropDownLabel.Text = 'Type de sollicitation';

            % Create TypedesollicitationDropDown
            app.TypedesollicitationDropDown = uidropdown(app.LeftPanel);
            app.TypedesollicitationDropDown.Items = {'Constant Volume', 'Uniaxial', 'Longitudinal', 'Isostatic'};
            app.TypedesollicitationDropDown.Position = [152 501 100 22];
            app.TypedesollicitationDropDown.Value = 'Constant Volume';

            % Create AmplitudeaEditFieldLabel
            app.AmplitudeaEditFieldLabel = uilabel(app.LeftPanel);
            app.AmplitudeaEditFieldLabel.HorizontalAlignment = 'right';
            app.AmplitudeaEditFieldLabel.Position = [36 369 91 22];
            app.AmplitudeaEditFieldLabel.Text = 'Amplitude : ÿa =';

            % Create AmplitudeaEditField
            app.AmplitudeaEditField = uieditfield(app.LeftPanel, 'numeric');
            app.AmplitudeaEditField.Position = [142 369 100 22];

            % Create Button
            app.Button = uibutton(app.LeftPanel, 'push');
            app.Button.ButtonPushedFcn = createCallbackFcn(app, @ButtonPushed, true);
            app.Button.Position = [213 458 29 22];
            app.Button.Text = '...';

            % Create SlectionnerlesfichiersLabel
            app.SlectionnerlesfichiersLabel = uilabel(app.LeftPanel);
            app.SlectionnerlesfichiersLabel.Position = [36 445 156 48];
            app.SlectionnerlesfichiersLabel.Text = 'Sélectionner les fichiers';

            % Create Label
            app.Label = uilabel(app.LeftPanel);
            app.Label.Position = [114 213 35 22];

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;

            % Create TabGroup
            app.TabGroup = uitabgroup(app.RightPanel);
            app.TabGroup.Position = [6 6 591 555];

            % Create VrificationfichiersTab
            app.VrificationfichiersTab = uitab(app.TabGroup);
            app.VrificationfichiersTab.Title = 'Vérification fichiers';

            % Create UITable2
            app.UITable2 = uitable(app.VrificationfichiersTab);
            app.UITable2.ColumnName = {'Nom de fichier'; 'Temperature'};
            app.UITable2.RowName = {};
            app.UITable2.ColumnEditable = [false true];
            app.UITable2.Position = [2 1 589 496];

            % Create ValiderlesdonnesButton
            app.ValiderlesdonnesButton = uibutton(app.VrificationfichiersTab, 'push');
            app.ValiderlesdonnesButton.ButtonPushedFcn = createCallbackFcn(app, @ValiderlesdonnesButtonPushed, true);
            app.ValiderlesdonnesButton.BackgroundColor = [0.9412 0.9412 0.9412];
            app.ValiderlesdonnesButton.FontColor = [1 0 0];
            app.ValiderlesdonnesButton.Position = [461 502 127 22];
            app.ValiderlesdonnesButton.Text = 'Valider les données';

            % Create GraphTab
            app.GraphTab = uitab(app.TabGroup);
            app.GraphTab.Title = 'Graph';

            % Create PressrunwhenyouarereadyLabel
            app.PressrunwhenyouarereadyLabel = uilabel(app.GraphTab);
            app.PressrunwhenyouarereadyLabel.Position = [213 256 166 45];
            app.PressrunwhenyouarereadyLabel.Text = 'Press run when you are ready';

            % Create DataTab
            app.DataTab = uitab(app.TabGroup);
            app.DataTab.Title = 'Data';

            % Create UITable
            app.UITable = uitable(app.DataTab);
            app.UITable.ColumnName = {'Time'; 'Epsilon'; 'SigX'; 'SigY'; 'SigZ'};
            app.UITable.RowName = {};
            app.UITable.Position = [0 1 590 486];

            % Create NomdefichierDropDownLabel
            app.NomdefichierDropDownLabel = uilabel(app.DataTab);
            app.NomdefichierDropDownLabel.HorizontalAlignment = 'right';
            app.NomdefichierDropDownLabel.Position = [14 495 83 22];
            app.NomdefichierDropDownLabel.Text = 'Nom de fichier';

            % Create NomdefichierDropDown
            app.NomdefichierDropDown = uidropdown(app.DataTab);
            app.NomdefichierDropDown.Items = {};
            app.NomdefichierDropDown.ValueChangedFcn = createCallbackFcn(app, @NomdefichierDropDownValueChanged, true);
            app.NomdefichierDropDown.Position = [144 495 177 22];
            app.NomdefichierDropDown.Value = {};

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = app2_exported(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end