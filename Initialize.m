function [DSError] = Initialize()

global System;
global LogicalLink;

CR = char(10);

DSError.ErrorCode   = 0;
DSError.ErrorString = '';

try
    disp('Creating a COM Automation server for ControlDeskNG');
    System = actxserver('ControlDeskNG.MC3System', '127.0.0.1');
    if(isempty(System))
        DSError.ErrorCode   = 1;
        DSError.ErrorString = 'Cannot get COM object from ''ControlDeskNG.MC3System''';
        return;
    end;
    
    pause(0.1);
    
    % get name of the available projects
    DbProjectDescriptions = System.DbProjectDescriptions;
    NumProjects = double(DbProjectDescriptions.count);
    if(NumProjects < 1)
        DSError.ErrorCode   = 1;
        DSError.ErrorString = 'Cannot get Project from ControlDeskNG';
        return;
    end;
    
    disp([CR, 'Available projects:', CR]);
    
    for CountProjects = 0 : (NumProjects - 1)
        ActDbProjectDescription = DbProjectDescriptions.GetItemByIndex(CountProjects);
        ActProjectName = ActDbProjectDescription.ShortName;
        disp(sprintf('\t%d. - %s', CountProjects + 1, ActProjectName));
    end;
    
    ChosenProject = 0;
    disp(CR);
    while(ChosenProject < 1 | ChosenProject > NumProjects)
        UserInput = input('Please choose a project by number: ');
        if(isnumeric(UserInput))
            ChosenProject = UserInput;
        else
            UserInput = 0;
        end;
    end;
    
    % select chosen project
    DbProjectDescription = DbProjectDescriptions.GetItemByIndex(UserInput - 1);
    ProjectName = DbProjectDescription.ShortName;
    Project = System.SelectProjectByName(ProjectName);
    if(isempty(Project))
        DSError.ErrorCode   = 1;
        DSError.ErrorString = sprintf('Cannot select project ''%s'' in ControlDeskNG', ProjectName);
        return;
    else
        disp([CR, 'Project ''', ProjectName, ''' was selected!', CR]);
    end;

    DbLocation = System.ActiveProject.DbProject.DbModuleLocations.GetItemByIndex(0);
    VehicleInformation = System.ActiveProject.DbProject.DbVehicleInformations.GetItemByIndex(0);

    UsedDbLogicalLink = VehicleInformation.DbLogicalLinks.GetItemByIndex(0); 
    UsedDbBinary = UsedDbLogicalLink.DbLocation.DbBinaries.GetItemByIndex(0);

    % create runtime logical link
    LogicalLink = System.ActiveProject.LogicalLinks.AddByNames(UsedDbLogicalLink.ShortName, UsedDbBinary.ShortName);
    
    % prepare online calibration
%     LogicalLink.ConnectToModule(constants.eLT_UPLOAD);
    
    % Activate work page, otherwise calibration will be denied:
    LogicalLink.MemoryPage = 1;
    if(isempty(LogicalLink))
        DSError.ErrorCode   = 1;
        DSError.ErrorString = 'Cannot get ''LogicalLink'' from project';
        return;
    end;
catch
    DSError.ErrorString = lasterr;
end;
